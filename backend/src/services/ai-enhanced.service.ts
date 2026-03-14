import { config } from '../config/env';

export class AIEnhancedService {
  private baseUrl: string;

  private readonly defaultSections = [
    { value: '302', label: 'IPC 302 - Murder', section: 'IPC 302', title: 'Murder', code: 'ipc' as const },
    { value: '304', label: 'IPC 304 - Culpable Homicide', section: 'IPC 304', title: 'Culpable Homicide Not Amounting to Murder', code: 'ipc' as const },
    { value: '307', label: 'IPC 307 - Attempt to Murder', section: 'IPC 307', title: 'Attempt to Murder', code: 'ipc' as const },
    { value: '323', label: 'IPC 323 - Causing Hurt', section: 'IPC 323', title: 'Causing Hurt', code: 'ipc' as const },
    { value: '325', label: 'IPC 325 - Grievous Hurt', section: 'IPC 325', title: 'Voluntarily Causing Grievous Hurt', code: 'ipc' as const },
    { value: '376', label: 'IPC 376 - Rape', section: 'IPC 376', title: 'Rape', code: 'ipc' as const },
    { value: '380', label: 'IPC 380 - Theft', section: 'IPC 380', title: 'Theft', code: 'ipc' as const },
    { value: '420', label: 'IPC 420 - Cheating', section: 'IPC 420', title: 'Cheating and Dishonestly Inducing Delivery', code: 'ipc' as const },
    { value: '103', label: 'BNS 103 - Murder', section: 'BNS 103', title: 'Murder', code: 'bns' as const },
    { value: '104', label: 'BNS 104 - Culpable Homicide', section: 'BNS 104', title: 'Culpable Homicide Not Amounting to Murder', code: 'bns' as const },
    { value: '105', label: 'BNS 105 - Attempt to Murder', section: 'BNS 105', title: 'Attempt to Murder', code: 'bns' as const },
    { value: '69', label: 'BNS 69 - Rape', section: 'BNS 69', title: 'Rape', code: 'bns' as const },
  ];

  constructor() {
    this.baseUrl = config.aiPocUrl || 'http://localhost:8000';
  }

  private getFallbackSections(codeType: string) {
    if (codeType === 'ipc' || codeType === 'bns') {
      return this.defaultSections.filter((item) => item.code === codeType);
    }
    return this.defaultSections;
  }

  async extractLegalEntities(text: string): Promise<any> {
    const form = new URLSearchParams();
    form.append('text', text);
    const res = await fetch(`${this.baseUrl}/api/ai/legal-ner`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: form.toString(),
    });
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    return res.json();
  }

  async suggestSections(caseDescription: string, topK = 5, codeType = 'both'): Promise<any> {
    const form = new URLSearchParams();
    form.append('case_description', caseDescription);
    form.append('top_k', String(topK));
    form.append('code_type', codeType);
    const res = await fetch(`${this.baseUrl}/api/ai/suggest-sections`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: form.toString(),
    });
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    return res.json();
  }

  async findPrecedents(query: string, topK = 5, section?: string): Promise<any> {
    const form = new URLSearchParams();
    form.append('query', query);
    form.append('top_k', String(topK));
    if (section) form.append('section', section);
    const res = await fetch(`${this.baseUrl}/api/ai/find-precedents`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: form.toString(),
    });
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    return res.json();
  }

  async suggestKeywords(text: string, maxItems = 8): Promise<any> {
    const form = new URLSearchParams();
    form.append('text', text);
    form.append('max_items', String(maxItems));
    const res = await fetch(`${this.baseUrl}/api/ai/suggest-keywords`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: form.toString(),
    });
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    return res.json();
  }

  async generateDocument(documentType: string, caseData: any): Promise<any> {
    const form = new URLSearchParams();
    form.append('document_type', documentType);
    form.append('case_data', JSON.stringify(caseData));
    const res = await fetch(`${this.baseUrl}/api/ai/generate-document`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: form.toString(),
    });
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    return res.json();
  }

  async multilingualOCR(file: Express.Multer.File, language?: string, autoDetect = true): Promise<any> {
    const blob = new Blob([file.buffer], { type: file.mimetype });
    const form = new FormData();
    form.append('file', blob, file.originalname);
    if (language) form.append('language', language);
    form.append('auto_detect', String(autoDetect));
    const res = await fetch(`${this.baseUrl}/api/ai/multilingual-ocr`, {
      method: 'POST',
      body: form,
    });
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    return res.json();
  }

  async advancedSearch(query: string, topK = 5, useReranking = false): Promise<any> {
    const form = new URLSearchParams();
    form.append('query', query);
    form.append('top_k', String(topK));
    form.append('use_reranking', String(useReranking));
    const res = await fetch(`${this.baseUrl}/api/ai/advanced-search`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: form.toString(),
    });
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    return res.json();
  }

  async stats(): Promise<any> {
    const res = await fetch(`${this.baseUrl}/api/ai/stats`);
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    return res.json();
  }

  async templates(): Promise<any> {
    const res = await fetch(`${this.baseUrl}/api/ai/templates`);
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    return res.json();
  }

  async sectionDetails(sectionNumber: string, codeType = 'ipc'): Promise<any> {
    const res = await fetch(`${this.baseUrl}/api/ai/section-details/${encodeURIComponent(sectionNumber)}?code_type=${encodeURIComponent(codeType)}`);
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    return res.json();
  }

  async precedentsBySection(section: string, topK = 10): Promise<any> {
    const res = await fetch(`${this.baseUrl}/api/ai/precedents/section/${encodeURIComponent(section)}?top_k=${encodeURIComponent(String(topK))}`);
    if (!res.ok) throw new Error(`AI service error: ${res.status}`);
    return res.json();
  }

  async getSectionsList(codeType = 'both'): Promise<any> {
    try {
      const res = await fetch(`${this.baseUrl}/api/ai/sections-list?code_type=${encodeURIComponent(codeType)}`);
      if (!res.ok) {
        return {
          success: true,
          sections: this.getFallbackSections(codeType),
          fallback: true,
          error: `AI service error: ${res.status}`,
        };
      }
      return res.json();
    } catch (error: any) {
      return {
        success: true,
        sections: this.getFallbackSections(codeType),
        fallback: true,
        error: error?.message || 'AI service unavailable',
      };
    }
  }
}
