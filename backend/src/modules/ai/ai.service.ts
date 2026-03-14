import { config } from '../../config/env';
import type { Express } from 'express';
import fs from 'fs/promises';
import path from 'path';
import crypto from 'crypto';
import { CaseState, UserRole } from '@prisma/client';
import { prisma } from '../../prisma/client';

interface ChatSource {
  source: string;
  score: number;
  id?: string;
}

interface SectionKnowledge {
  sectionId: string;
  codeType: 'ipc' | 'bns';
  title?: string;
  description?: string;
  punishment?: string;
  bailable?: boolean;
  cognizable?: boolean;
  category?: string;
}

interface SuggestedSection {
  section: string;
  number: string;
  title: string;
  confidence: number;
  codeType: 'IPC' | 'BNS';
  explanation?: string;
}

export class AIService {
  baseUrl: string;
  ollamaUrl: string;
  ollamaModel: string;

  constructor() {
    this.baseUrl = config.aiPocUrl;
    this.ollamaUrl = process.env.OLLAMA_URL || 'http://localhost:11434';
    this.ollamaModel = process.env.OLLAMA_MODEL || 'llama3.1:8b';
  }

  private getOutputDir(): string {
    // backend runs from /backend; ai-poc lives at ../ai-poc/storage/output/ai_extractions
    return path.resolve(process.cwd(), '../ai-poc/storage/output/ai_extractions');
  }

  private extractFirReferences(query: string): string[] {
    return Array.from(query.matchAll(/\b\d{1,4}\/\d{2,4}\b/g)).map((match) => match[0]);
  }

  private extractSectionReferences(query: string): Array<{ sectionId: string; codeType: 'ipc' | 'bns' }> {
    const refs: Array<{ sectionId: string; codeType: 'ipc' | 'bns' }> = [];
    const normalized = query.trim();
    const explicitMatches = query.matchAll(/\b(ipc|bns)\s*(?:section\s*)?(\d{1,4})\b/gi);

    for (const match of explicitMatches) {
      refs.push({
        codeType: match[1].toLowerCase() as 'ipc' | 'bns',
        sectionId: match[2],
      });
    }

    if (refs.length === 0) {
      const genericMatch = query.match(/section\s+(\d{1,4})\b/i);
      if (genericMatch) {
        refs.push({ sectionId: genericMatch[1], codeType: 'ipc' });
      }
    }

    if (refs.length === 0) {
      const bareNumberMatch = normalized.match(/^(\d{1,4})$/);
      if (bareNumberMatch) {
        refs.push({ sectionId: bareNumberMatch[1], codeType: 'ipc' });
      }
    }

    return refs;
  }

  private containsNarrativeFacts(query: string): boolean {
    const normalized = query.trim().toLowerCase();
    if (normalized.split(/\s+/).length < 5) return false;
    return /(murder|killed|kill|theft|stole|rape|assault|hurt|cheat|fraud|plan|conspiracy|attack|robbery|kidnap)/i.test(normalized);
  }

  private formatCaseState(state?: CaseState | null): string {
    return String(state || CaseState.FIR_REGISTERED).replace(/_/g, ' ');
  }

  private isGreeting(query: string): boolean {
    const normalized = query.trim().toLowerCase();
    return ['hi', 'hello', 'hey', 'namaste', 'good morning', 'good evening'].includes(normalized);
  }

  private isDirectSectionLookup(query: string): boolean {
    const normalized = query.trim().toLowerCase();
    return [
      /^\d{1,4}$/,
      /^(?:ipc|bns)\s*(?:section\s*)?\d{1,4}$/,
      /^section\s+\d{1,4}$/,
      /^what\s+is\s+(?:ipc|bns)?\s*(?:section\s*)?\d{1,4}\??$/,
      /^tell\s+me\s+about\s+(?:ipc|bns)?\s*(?:section\s*)?\d{1,4}\??$/,
    ].some((pattern) => pattern.test(normalized));
  }

  private async fetchSectionKnowledge(query: string): Promise<SectionKnowledge[]> {
    const references = this.extractSectionReferences(query);
    if (references.length === 0) return [];

    const results: Array<SectionKnowledge | null> = await Promise.all(
      references.map(async (ref) => {
        const ctrl = new AbortController();
        const t = setTimeout(() => ctrl.abort(), 8000);
        try {
          const response = await fetch(
            `${this.baseUrl}/api/ai/section-details/${encodeURIComponent(ref.sectionId)}?code_type=${ref.codeType}`,
            { signal: ctrl.signal }
          );
          clearTimeout(t);
          if (!response.ok) return null;
          const body = await response.json();
          if (body?.success === false || !body?.data) return null;
          const data = body?.data || body;
          return {
            sectionId: ref.sectionId,
            codeType: ref.codeType,
            title: data?.title,
            description: data?.description,
            punishment: data?.punishment,
            bailable: data?.bailable,
            cognizable: data?.cognizable,
            category: data?.category,
          } satisfies SectionKnowledge;
        } catch {
          clearTimeout(t);
          return null;
        }
      })
    );

    return results.filter((item): item is SectionKnowledge => item !== null);
  }

  private fallbackSuggestSections(query: string): SuggestedSection[] {
    const normalized = query.toLowerCase();
    const suggestions: SuggestedSection[] = [];

    const push = (section: string, number: string, title: string, confidence: number, explanation: string, codeType: 'IPC' | 'BNS' = 'IPC') => {
      suggestions.push({ section, number, title, confidence, explanation, codeType });
    };

    if (/(murder|killed|kill)/i.test(normalized)) {
      push('IPC 302', '302', 'Murder', 0.92, 'Narrative suggests unlawful killing');
      push('BNS 103', '103', 'Murder', 0.9, 'BNS equivalent for murder', 'BNS');
    }

    if (/(attempt to kill|attempted to kill|attempt murder)/i.test(normalized)) {
      push('IPC 307', '307', 'Attempt to Murder', 0.88, 'Narrative suggests attempted killing');
      push('BNS 105', '105', 'Attempt to Murder', 0.86, 'BNS equivalent for attempt to murder', 'BNS');
    }

    if (/(plan|conspiracy|included these people|with others|together)/i.test(normalized)) {
      push('IPC 120B', '120B', 'Criminal Conspiracy', 0.84, 'Narrative suggests coordinated planning by multiple persons');
    }

    if (/(theft|stole|stolen|robbed|robbery)/i.test(normalized)) {
      push('IPC 379', '379', 'Punishment for Theft', 0.83, 'Narrative suggests dishonest taking of movable property');
    }

    if (/(hurt|injured|assault|beaten)/i.test(normalized)) {
      push('IPC 323', '323', 'Causing Hurt', 0.78, 'Narrative suggests bodily harm');
    }

    return suggestions.slice(0, 5);
  }

  private async fetchSuggestedSections(query: string): Promise<SuggestedSection[]> {
    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), 8000);
    try {
      const form = new URLSearchParams();
      form.append('case_description', query);
      form.append('top_k', '5');
      form.append('code_type', 'both');

      const response = await fetch(`${this.baseUrl}/api/ai/suggest-sections`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        signal: ctrl.signal,
        body: form.toString(),
      });

      clearTimeout(t);
      if (!response.ok) return this.fallbackSuggestSections(query);
      const body = await response.json();
      if (body?.success === false || !Array.isArray(body?.data?.suggestions)) {
        return this.fallbackSuggestSections(query);
      }

      const mapped = body.data.suggestions.map((item: any) => ({
        section: String(item.section || ''),
        number: String(item.number || ''),
        title: String(item.title || ''),
        confidence: Number(item.confidence || 0),
        codeType: String(item.code_type || 'IPC').toUpperCase() === 'BNS' ? 'BNS' : 'IPC',
        explanation: typeof item.explanation === 'string' ? item.explanation : undefined,
      })) as SuggestedSection[];

      return mapped.filter((item) => item.section && item.title).slice(0, 5);
    } catch {
      clearTimeout(t);
      return this.fallbackSuggestSections(query);
    }
  }

  private async getRelevantCasesForChat(userId: string, userRole: UserRole, organizationId: string, query: string) {
    const firRefs = this.extractFirReferences(query);
    const sectionRefs = this.extractSectionReferences(query);

    const accessWhere = userRole === UserRole.POLICE
      ? {
          OR: [
            { assignments: { some: { assignedTo: userId, unassignedAt: null } } },
            { fir: { policeStationId: organizationId } },
          ],
        }
      : userRole === UserRole.SHO
        ? { fir: { policeStationId: organizationId } }
        : userRole === UserRole.COURT_CLERK || userRole === UserRole.JUDGE
          ? { courtSubmissions: { some: { courtId: organizationId } } }
          : {};

    const queryFilters: any[] = [];
    if (firRefs.length > 0) {
      queryFilters.push({
        OR: firRefs.map((firNumber) => ({
          fir: { firNumber: { contains: firNumber } },
        })),
      });
    }

    if (sectionRefs.length > 0) {
      queryFilters.push({
        OR: sectionRefs.map((ref) => ({
          fir: { sectionsApplied: { contains: ref.sectionId } },
        })),
      });
    }

    const where = queryFilters.length > 0 ? { AND: [accessWhere, ...queryFilters] } : accessWhere;

    return prisma.case.findMany({
      where,
      take: 5,
      orderBy: { createdAt: 'desc' },
      include: {
        fir: { include: { policeStation: true } },
        state: true,
        accused: true,
        evidence: true,
        witnesses: true,
        documents: true,
      },
    });
  }

  private buildCaseContextSummary(cases: any[]): { text: string; sources: ChatSource[] } {
    const sources: ChatSource[] = [];
    const lines = cases.map((caseItem) => {
      const firNumber = caseItem?.fir?.firNumber || caseItem.id;
      const sections = caseItem?.fir?.sectionsApplied || 'Not recorded';
      const currentState = this.formatCaseState(caseItem?.state?.currentState);
      const arrestedCount = Array.isArray(caseItem?.accused)
        ? caseItem.accused.filter((accused: any) => accused.status === 'ARRESTED').length
        : 0;
      const evidenceCount = Array.isArray(caseItem?.evidence) ? caseItem.evidence.length : 0;
      const witnessCount = Array.isArray(caseItem?.witnesses) ? caseItem.witnesses.length : 0;
      const documentCount = Array.isArray(caseItem?.documents) ? caseItem.documents.length : 0;

      sources.push({ source: `FIR ${firNumber}`, score: 1, id: caseItem.id });

      return [
        `Case ID: ${caseItem.id}`,
        `FIR Number: ${firNumber}`,
        `Police Station: ${caseItem?.fir?.policeStation?.name || 'Unknown'}`,
        `Current State: ${currentState}`,
        `Sections Applied: ${sections}`,
        `Arrested Accused Count: ${arrestedCount}`,
        `Evidence Count: ${evidenceCount}`,
        `Witness Count: ${witnessCount}`,
        `Document Count: ${documentCount}`,
      ].join('\n');
    });

    return { text: lines.join('\n\n---\n\n'), sources };
  }

  private buildRuleBasedChatAnswer(query: string, cases: any[], sectionKnowledge: SectionKnowledge[], suggestedSections: SuggestedSection[]): string {
    const lowerQuery = query.toLowerCase();
    const sectionRefs = this.extractSectionReferences(query);

    if (sectionRefs.length > 0 && sectionKnowledge.length === 0) {
      const first = sectionRefs[0];
      return `I could not find details for ${first.codeType.toUpperCase()} section ${first.sectionId}. Check whether the section number is correct, or specify if you want IPC or BNS.`;
    }

    if ((lowerQuery.includes('arrest') || lowerQuery.includes('arrested')) && lowerQuery.match(/section|ipc|bns/)) {
      if (cases.length === 0) {
        return 'I could not find a matching accessible case. If you mention the FIR number, I can check its applied sections.';
      }

      const lines = cases.map((caseItem) => {
        const firNumber = caseItem?.fir?.firNumber || caseItem.id;
        const sections = caseItem?.fir?.sectionsApplied || 'not recorded';
        const arrestedCount = Array.isArray(caseItem?.accused)
          ? caseItem.accused.filter((accused: any) => accused.status === 'ARRESTED').length
          : 0;

        return `FIR ${firNumber} is currently recorded under ${sections}. ${arrestedCount > 0 ? `${arrestedCount} accused are marked as arrested.` : 'No accused are marked as arrested in the current record.'}`;
      });

      return `${lines.join(' ')} Note: your database stores FIR sections applied, not a separate arrest-section field.`;
    }

    if (sectionKnowledge.length > 0) {
      const item = sectionKnowledge[0];
      return `${item.codeType.toUpperCase()} Section ${item.sectionId} is ${item.title || 'a legal provision'}. ${item.description || ''} Punishment: ${item.punishment || 'not available'}. Bailable: ${item.bailable ? 'Yes' : 'No'}. Cognizable: ${item.cognizable ? 'Yes' : 'No'}.`;
    }

    if (suggestedSections.length > 0) {
      const top = suggestedSections.slice(0, 3).map((item) => `${item.section} (${item.title})`).join(', ');
      const reasons = suggestedSections.slice(0, 2).map((item) => item.explanation).filter(Boolean).join(' ');
      return `Based on the story, the most relevant sections appear to be ${top}.${reasons ? ` ${reasons}` : ''} This is a suggestion, not final legal advice, so an officer should confirm the exact sections from full facts.`;
    }

    if (cases.length > 0) {
      const first = cases[0];
      return `The most relevant accessible case is FIR ${first?.fir?.firNumber || first.id}, currently in ${this.formatCaseState(first?.state?.currentState)}, with sections ${first?.fir?.sectionsApplied || 'not recorded'}. Ask for FIR number, section details, arrest status, evidence, or next action for a more specific answer.`;
    }

    return 'I could not find matching case context. Ask with an FIR number, case section, or specific arrest question.';
  }

  private async askOllama(prompt: string, model?: string): Promise<string | null> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 15000); // 15-second hard timeout
    try {
      const response = await fetch(`${this.ollamaUrl}/api/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body: JSON.stringify({
          model: model || this.ollamaModel,
          prompt,
          stream: false,
        }),
      });

      clearTimeout(timer);
      if (!response.ok) return null;
      const body = await response.json();
      return typeof body?.response === 'string' ? body.response.trim() : null;
    } catch {
      clearTimeout(timer);
      return null;
    }
  }

  async groundedLegalChat(payload: { q: string; k?: number; model?: string; userId: string; userRole: UserRole; organizationId: string }): Promise<any> {
    if (this.isGreeting(payload.q)) {
      return {
        success: true,
        answer: 'Hello. I am your Legal Co-Pilot. Ask about FIR sections, arrest status, IPC/BNS section meaning, evidence gaps, or mention a specific FIR number.',
        sources: [],
        debug: {
          model: payload.model || this.ollamaModel,
          usedOllama: false,
        },
      };
    }

    const sectionRefs = this.extractSectionReferences(payload.q);
    const directSectionLookup = this.isDirectSectionLookup(payload.q);
    const isNarrative = this.containsNarrativeFacts(payload.q) && sectionRefs.length === 0;

    // Run DB lookup and section knowledge fetch in parallel to save time
    const [cases, sectionKnowledge] = await Promise.all([
      this.getRelevantCasesForChat(payload.userId, payload.userRole, payload.organizationId, payload.q),
      this.fetchSectionKnowledge(payload.q),
    ]);
    const suggestedSections = isNarrative ? await this.fetchSuggestedSections(payload.q) : [];
    const caseContext = this.buildCaseContextSummary(cases);

    const sectionContext = sectionKnowledge.length > 0
      ? sectionKnowledge.map((item) => [
          `${item.codeType.toUpperCase()} Section ${item.sectionId}`,
          `Title: ${item.title || 'Unknown'}`,
          `Description: ${item.description || 'Not available'}`,
          `Punishment: ${item.punishment || 'Not available'}`,
          `Bailable: ${item.bailable ? 'Yes' : 'No'}`,
          `Cognizable: ${item.cognizable ? 'Yes' : 'No'}`,
        ].join('\n')).join('\n\n')
      : 'No direct section details matched from the question.';

    const fallbackAnswer = this.buildRuleBasedChatAnswer(payload.q, cases, sectionKnowledge, suggestedSections);

    if (directSectionLookup) {
      return {
        success: true,
        answer: fallbackAnswer,
        sources: sectionKnowledge.map((item) => ({
          source: `${item.codeType.toUpperCase()} Section ${item.sectionId}`,
          score: 0.95,
          id: `${item.codeType}-${item.sectionId}`,
        })),
        debug: {
          model: payload.model || this.ollamaModel,
          usedOllama: false,
        },
      };
    }

    if (sectionRefs.length > 0 && sectionKnowledge.length === 0) {
      return {
        success: true,
        answer: fallbackAnswer,
        sources: [],
        debug: {
          model: payload.model || this.ollamaModel,
          usedOllama: false,
        },
      };
    }

    const prompt = [
      'You are NyayaSankalan Legal Co-Pilot for police and court workflow.',
      'Answer only from the context provided below. Do not invent case facts.',
      'If arrest-section is asked, explain that the system stores FIR sections applied and accused status, not a dedicated arrest-section field.',
      'Prefer direct, practical answers for a police officer.',
      'Keep the answer under 140 words unless the question requires more detail.',
      '',
      `User Role: ${payload.userRole}`,
      `Question: ${payload.q}`,
      '',
      'Relevant Case Context:',
      caseContext.text || 'No matching accessible cases found.',
      '',
      'Relevant Section Knowledge:',
      sectionContext,
      '',
      'Suggested Sections From Narrative:',
      suggestedSections.length > 0
        ? suggestedSections.map((item) => `${item.section} - ${item.title} (confidence ${Math.round(item.confidence * 100)}%)${item.explanation ? `: ${item.explanation}` : ''}`).join('\n')
        : 'No narrative-based section suggestions.',
      '',
      'If context is insufficient, say what is missing clearly.',
    ].join('\n');

    const ollamaAnswer = await this.askOllama(prompt, payload.model);

    return {
      success: true,
      answer: ollamaAnswer || fallbackAnswer,
      sources: [
        ...caseContext.sources,
        ...sectionKnowledge.map((item) => ({
          source: `${item.codeType.toUpperCase()} Section ${item.sectionId}`,
          score: 0.95,
          id: `${item.codeType}-${item.sectionId}`,
        })),
        ...suggestedSections.map((item) => ({
          source: item.section,
          score: item.confidence,
          id: `${item.codeType}-${item.number}`,
        })),
      ],
      debug: {
        model: payload.model || this.ollamaModel,
        usedOllama: Boolean(ollamaAnswer),
      },
    };
  }

  /**
   * Health check for AI PoC service availability
   * Returns true if service is reachable, false otherwise
   */
  async healthCheck(): Promise<boolean> {
    try {
      const res = await fetch(`${this.baseUrl}/health`, { method: 'GET' });
      return res.ok;
    } catch {
      return false;
    }
  }

  async indexAll(): Promise<any> {
    const res = await fetch(`${this.baseUrl}/index`, { method: 'POST' });
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    return res.json();
  }

  async indexDocument(extractionId: string): Promise<any> {
    const res = await fetch(`${this.baseUrl}/index/doc/${extractionId}`, { method: 'POST' });
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    return res.json();
  }

  async search(query: string, k = 5): Promise<any> {
    const params = new URLSearchParams({ q: query, k: String(k) });
    const res = await fetch(`${this.baseUrl}/search?${params.toString()}`);
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    return res.json();
  }

  async ocrExtract(file: Express.Multer.File): Promise<any> {
    const form = new FormData();
    const blob = new Blob([new Uint8Array(file.buffer)], { type: file.mimetype });
    form.append('file', blob, file.originalname);

    const res = await fetch(`${this.baseUrl}/ocr-extract`, {
      method: 'POST',
      body: form,
    });
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    const data = await res.json();

    // ai-poc returns extractionId and entities, but extracted text is stored in JSON
    // Fetch the full extraction to get the extracted text
    if (data.data?.extractionId) {
      const extractionId = data.data.extractionId;
      const extractRes = await fetch(`${this.baseUrl}/extractions/${extractionId}`);
      if (extractRes.ok) {
        const extraction = await extractRes.json();
        // Merge the extracted text from the stored extraction
        if (extraction.data?.extractedText) {
          data.data.extractedText = extraction.data.extractedText;
          data.data.redactedText = extraction.data.redactedText;
        }
      }
    }

    return data;
  }

  async generateDraft(payload: { caseId?: string; documentType: string; context?: string }): Promise<any> {
    // ai-poc /generate-draft expects form data with 'text' and optionally 'model'
    // Construct a simple prompt from context or use a default
    const promptText = payload.context || `Generate a ${payload.documentType} document`;

    const formData = new URLSearchParams();
    formData.append('text', promptText);
    formData.append('model', 'flan-t5-small');

    const res = await fetch(`${this.baseUrl}/generate-draft`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: formData.toString(),
    });
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    return res.json();
  }

  async writeFirExtraction(payload: {
    caseId: string;
    firNumber: string;
    sectionsApplied: string;
    incidentDate: Date | string;
    policeStationName?: string;
  }): Promise<string> {
    const extractionId = crypto.randomUUID();
    const outputDir = this.getOutputDir();

    // Ensure directory exists and is writable
    try {
      await fs.mkdir(outputDir, { recursive: true });
      await fs.access(outputDir, fs.constants.W_OK);
    } catch (err) {
      throw new Error(`AI storage directory not accessible: ${outputDir}`);
    }

    const incidentDateStr = payload.incidentDate instanceof Date
      ? payload.incidentDate.toISOString().split('T')[0]
      : payload.incidentDate;

    const extractedText = [
      `FIR Number: ${payload.firNumber}`,
      `Sections: ${payload.sectionsApplied}`,
      `Incident Date: ${incidentDateStr}`,
      payload.policeStationName ? `Police Station: ${payload.policeStationName}` : '',
    ]
      .filter(Boolean)
      .join('\n');

    const extraction = {
      id: extractionId,
      caseId: payload.caseId,
      sourceFile: 'fir-generated',
      extractedText,
      redactedText: extractedText,
      entities: {},
      confidence: 1.0,
      createdAt: new Date().toISOString(),
    };

    const outPath = path.join(outputDir, `${extractionId}.json`);
    await fs.writeFile(outPath, JSON.stringify(extraction, null, 2), 'utf-8');

    return extractionId;
  }

  async indexFirExtraction(payload: {
    caseId: string;
    firNumber: string;
    sectionsApplied: string;
    incidentDate: Date | string;
    policeStationName?: string;
  }): Promise<void> {
    const extractionId = await this.writeFirExtraction(payload);
    // Rebuild/upsert index with this extraction; swallow errors to avoid impacting main flow
    try {
      await this.indexDocument(extractionId);
    } catch (err) {
      console.error('AI indexing skipped for FIR extraction', err);
    }
  }

  async chat(payload: { q: string; k?: number; model?: string }): Promise<any> {
    const formData = new FormData();
    formData.append('q', payload.q);
    if (payload.k) formData.append('k', payload.k.toString());
    if (payload.model) formData.append('model', payload.model);

    try {
      const response = await fetch(`${this.baseUrl}/chat`, {
        method: 'POST',
        body: formData,
      });
      if (!response.ok) throw new Error(`AI Chat Error: ${response.status}`);
      return response.json();
    } catch (error) {
      console.error('AI Chat Error:', error);
      throw error;
    }
  }
}
