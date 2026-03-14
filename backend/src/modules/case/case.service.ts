import { prisma } from '../../prisma/client';
import { ApiError } from '../../utils/ApiError';
import { CaseState } from '@prisma/client';

export interface CaseCopilotBrief {
  summary: string;
  keyRisks: string[];
  nextActions: string[];
  missingItems: string[];
  confidence: number;
  source: 'ai' | 'fallback';
}

interface OllamaResponse {
  response?: string;
}

export class CaseService {
  private readonly ollamaUrl = process.env.OLLAMA_URL || 'http://localhost:11434';
  private readonly ollamaModel = process.env.OLLAMA_MODEL || 'llama3.1:8b';

  private buildFallbackBrief(caseRecord: any): CaseCopilotBrief {
    const currentState = String(caseRecord?.state?.currentState || CaseState.FIR_REGISTERED);
    const evidenceCount = Array.isArray(caseRecord?.evidence) ? caseRecord.evidence.length : 0;
    const witnessCount = Array.isArray(caseRecord?.witnesses) ? caseRecord.witnesses.length : 0;
    const accusedCount = Array.isArray(caseRecord?.accused) ? caseRecord.accused.length : 0;
    const documentCount = Array.isArray(caseRecord?.documents) ? caseRecord.documents.length : 0;

    const missingItems: string[] = [];
    const nextActions: string[] = [];
    const keyRisks: string[] = [];

    if (evidenceCount === 0) missingItems.push('No evidence uploaded yet');
    if (witnessCount === 0) missingItems.push('No witness records added yet');
    if (documentCount === 0) missingItems.push('No investigation documents attached');

    if (currentState === CaseState.CASE_ASSIGNED || currentState === CaseState.UNDER_INVESTIGATION) {
      nextActions.push('Complete pending evidence and witness collection');
      nextActions.push('Review section applicability before preparing final documents');
    }

    if (currentState === CaseState.INVESTIGATION_COMPLETED) {
      nextActions.push('Prepare and review charge sheet or closure report');
      nextActions.push('Submit case package to court after SHO review');
    }

    if (currentState === CaseState.SUBMITTED_TO_COURT || currentState === CaseState.COURT_ACCEPTED) {
      nextActions.push('Track court action updates and compliance timelines');
      nextActions.push('Ensure all supporting documents are available to court');
    }

    if (evidenceCount < 2 && currentState === CaseState.UNDER_INVESTIGATION) {
      keyRisks.push('Limited evidence depth may weaken prosecution readiness');
    }

    if (witnessCount === 0 && currentState !== CaseState.FIR_REGISTERED) {
      keyRisks.push('No witness documentation recorded for current stage');
    }

    return {
      summary: `Case is currently in ${currentState.replace(/_/g, ' ')} with ${evidenceCount} evidence items, ${witnessCount} witnesses, and ${accusedCount} accused records.`,
      keyRisks: keyRisks.length > 0 ? keyRisks : ['No critical risk flagged by fallback rules'],
      nextActions: nextActions.length > 0 ? nextActions : ['Continue case progression as per current workflow'],
      missingItems,
      confidence: 0.62,
      source: 'fallback',
    };
  }

  private sanitizeAndParseOllamaJson(rawText: string): CaseCopilotBrief | null {
    const match = rawText.match(/\{[\s\S]*\}/);
    if (!match) return null;

    try {
      const parsed = JSON.parse(match[0]) as Partial<CaseCopilotBrief>;
      if (!parsed.summary || typeof parsed.summary !== 'string') return null;

      const toStringArray = (value: unknown): string[] => {
        if (!Array.isArray(value)) return [];
        return value.map((item) => String(item)).filter(Boolean);
      };

      let confidence = Number(parsed.confidence ?? 0.7);
      if (Number.isNaN(confidence)) confidence = 0.7;
      confidence = Math.max(0, Math.min(1, confidence));

      return {
        summary: parsed.summary,
        keyRisks: toStringArray(parsed.keyRisks),
        nextActions: toStringArray(parsed.nextActions),
        missingItems: toStringArray(parsed.missingItems),
        confidence,
        source: 'ai',
      };
    } catch {
      return null;
    }
  }

  private async generateOllamaBrief(caseRecord: any): Promise<CaseCopilotBrief | null> {
    const caseSnapshot = {
      caseId: caseRecord.id,
      currentState: caseRecord?.state?.currentState || CaseState.FIR_REGISTERED,
      firNumber: caseRecord?.fir?.firNumber || null,
      sectionsApplied: caseRecord?.fir?.sectionsApplied || null,
      policeStation: caseRecord?.fir?.policeStation?.name || null,
      counts: {
        evidence: Array.isArray(caseRecord?.evidence) ? caseRecord.evidence.length : 0,
        witnesses: Array.isArray(caseRecord?.witnesses) ? caseRecord.witnesses.length : 0,
        accused: Array.isArray(caseRecord?.accused) ? caseRecord.accused.length : 0,
        documents: Array.isArray(caseRecord?.documents) ? caseRecord.documents.length : 0,
      },
      recentStateChanges: Array.isArray(caseRecord?.stateHistory)
        ? caseRecord.stateHistory.slice(0, 5).map((item: any) => ({
            fromState: item.fromState,
            toState: item.toState,
            reason: item.changeReason,
            changedAt: item.changedAt,
          }))
        : [],
    };

    const prompt = [
      'You are a legal case copilot for Indian criminal workflow support.',
      'Analyze the case snapshot and return ONLY valid JSON with this exact schema:',
      '{"summary":"string","keyRisks":["string"],"nextActions":["string"],"missingItems":["string"],"confidence":0.0}',
      'Rules:',
      '- summary must be <= 80 words',
      '- provide 2-4 keyRisks and 2-4 nextActions',
      '- be concise and practical for police/court workflow',
      '- confidence must be between 0 and 1',
      'Case Snapshot:',
      JSON.stringify(caseSnapshot),
    ].join('\n');

    const response = await fetch(`${this.ollamaUrl}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: this.ollamaModel,
        prompt,
        stream: false,
      }),
    });

    if (!response.ok) {
      return null;
    }

    const body = (await response.json()) as OllamaResponse;
    const raw = typeof body.response === 'string' ? body.response : '';
    if (!raw.trim()) return null;
    return this.sanitizeAndParseOllamaJson(raw);
  }

  async getCaseCopilotBrief(caseId: string, userRole: string, organizationId: string | null) {
    const caseRecord = await this.getCaseById(caseId, userRole, organizationId);
    const fallback = this.buildFallbackBrief(caseRecord);

    try {
      const aiBrief = await this.generateOllamaBrief(caseRecord);
      if (aiBrief) return aiBrief;
      return fallback;
    } catch {
      return fallback;
    }
  }

  /**
   * Get case by ID
   */
  async getCaseById(caseId: string, userRole: string, organizationId: string | null) {
    const caseRecord = await prisma.case.findUnique({
      where: { id: caseId },
      include: {
        fir: {
          include: {
            policeStation: true,
          },
        },
        state: true,
        stateHistory: {
          orderBy: { changedAt: 'desc' },
          take: 10,
        },
        assignments: {
          include: {
            assignedUser: {
              select: { id: true, name: true, email: true },
            },
          },
          orderBy: { assignedAt: 'desc' },
        },
        accused: true,
        evidence: true,
        witnesses: true,
        documents: true,
        courtSubmissions: {
          include: { court: true },
          orderBy: { submittedAt: 'desc' },
        },
      },
    });

    if (!caseRecord) {
      throw ApiError.notFound('Case not found');
    }

    // Access control
    if ((userRole === 'POLICE' || userRole === 'SHO') && 
        caseRecord.fir.policeStationId !== organizationId) {
      throw ApiError.forbidden('Access denied');
    }

    if ((userRole === 'COURT_CLERK' || userRole === 'JUDGE') && organizationId) {
      const hasCourtAccess = caseRecord.courtSubmissions.some(
        (submission) => submission.courtId === organizationId
      );

      if (!hasCourtAccess) {
        throw ApiError.forbidden('Access denied');
      }
    }

    return caseRecord;
  }

  /**
   * Get cases assigned to a specific officer (for POLICE role)
   */
  async getMyCases(userId: string, page: number = 1, limit: number = 20) {
    const skip = (page - 1) * limit;

    console.log('=== getMyCases Service Debug ===');
    console.log('Looking for assignments where assignedTo =', userId);

    // First, let's check what assignments exist for this user
    const debugAssignments = await prisma.caseAssignment.findMany({
      where: { assignedTo: userId },
      select: { id: true, caseId: true, assignedTo: true, unassignedAt: true },
    });
    console.log('All assignments for user:', JSON.stringify(debugAssignments, null, 2));

    // Find cases where this officer has an active assignment
    const [cases, total] = await Promise.all([
      prisma.case.findMany({
        where: {
          assignments: {
            some: {
              assignedTo: userId,
              unassignedAt: null, // Only active assignments
            },
          },
        },
        include: {
          fir: {
            include: { policeStation: true },
          },
          state: true,
          assignments: {
            where: { unassignedAt: null },
            include: {
              assignedUser: {
                select: { id: true, name: true },
              },
            },
          },
        },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.case.count({
        where: {
          assignments: {
            some: {
              assignedTo: userId,
              unassignedAt: null,
            },
          },
        },
      }),
    ]);

    return {
      cases,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * List all cases for police station (for SHO/COURT roles)
   */
  async getCases(organizationId: string, userRole: string, page: number = 1, limit: number = 20) {
    const skip = (page - 1) * limit;

    const where = userRole === 'POLICE' || userRole === 'SHO'
      ? { fir: { policeStationId: organizationId } }
      : userRole === 'COURT_CLERK' || userRole === 'JUDGE'
        ? { courtSubmissions: { some: { courtId: organizationId } } }
        : {};

    const [cases, total] = await Promise.all([
      prisma.case.findMany({
        where,
        include: {
          fir: {
            include: { policeStation: true },
          },
          state: true,
          assignments: {
            where: { unassignedAt: null },
            include: {
              assignedUser: {
                select: { id: true, name: true },
              },
            },
          },
        },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.case.count({ where }),
    ]);

    return {
      cases,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Assign case to officer
   */
  async assignCase(
    caseId: string,
    assignedTo: string,
    assignmentReason: string,
    assignedBy: string,
    policeStationId: string
  ) {
    const caseRecord = await prisma.case.findUnique({
      where: { id: caseId },
      include: { fir: true },
    });

    if (!caseRecord) {
      throw ApiError.notFound('Case not found');
    }

    if (caseRecord.fir.policeStationId !== policeStationId) {
      throw ApiError.forbidden('Access denied');
    }

    const result = await prisma.$transaction(async (tx) => {
      // Unassign previous
      await tx.caseAssignment.updateMany({
        where: { caseId, unassignedAt: null },
        data: { unassignedAt: new Date() },
      });

      // Create new assignment
      const assignment = await tx.caseAssignment.create({
        data: {
          caseId,
          assignedTo,
          assignedBy,
          assignmentReason,
        },
        include: {
          assignedUser: {
            select: { id: true, name: true, email: true },
          },
        },
      });

      // Update case state
      await tx.currentCaseState.update({
        where: { caseId },
        data: { currentState: CaseState.CASE_ASSIGNED },
      });

      // Audit log
      await tx.auditLog.create({
        data: {
          userId: assignedBy,
          action: 'CASE_ASSIGNED',
          entity: 'CASE',
          entityId: caseId,
        },
      });

      return assignment;
    });

    return result;
  }

  /**
   * Update case state
   */
  async updateCaseState(
    caseId: string,
    newState: CaseState,
    changeReason: string,
    userId: string,
    policeStationId: string
  ) {
    const caseRecord = await prisma.case.findUnique({
      where: { id: caseId },
      include: { fir: true, state: true },
    });

    if (!caseRecord) {
      throw ApiError.notFound('Case not found');
    }

    if (caseRecord.fir.policeStationId !== policeStationId) {
      throw ApiError.forbidden('Access denied');
    }

    const currentState = caseRecord.state?.currentState || CaseState.FIR_REGISTERED;

    const result = await prisma.$transaction(async (tx) => {
      // Record history
      await tx.caseStateHistory.create({
        data: {
          caseId,
          fromState: currentState,
          toState: newState,
          changedBy: userId,
          changeReason,
        },
      });

      // Update current state
      await tx.currentCaseState.upsert({
        where: { caseId },
        update: { currentState: newState },
        create: { caseId, currentState: newState },
      });

      // Audit log
      await tx.auditLog.create({
        data: {
          userId,
          action: 'STATE_CHANGED',
          entity: 'CASE',
          entityId: caseId,
        },
      });

      return { caseId, previousState: currentState, newState };
    });

    return result;
  }

  /**
   * Complete investigation - Police marks case as investigation complete
   */
  async completeInvestigation(caseId: string, userId: string, policeStationId: string) {
    const caseRecord = await prisma.case.findUnique({
      where: { id: caseId },
      include: {
        fir: true,
        state: true,
        assignments: {
          where: { unassignedAt: null },
        },
      },
    });

    if (!caseRecord) {
      throw ApiError.notFound('Case not found');
    }

    if (caseRecord.fir.policeStationId !== policeStationId) {
      throw ApiError.forbidden('Access denied');
    }

    // Check if user is assigned to this case
    const isAssigned = caseRecord.assignments.some(a => a.assignedTo === userId);
    if (!isAssigned) {
      throw ApiError.forbidden('You are not assigned to this case');
    }

    const currentState = caseRecord.state?.currentState || CaseState.FIR_REGISTERED;

    // Only allow from CASE_ASSIGNED or UNDER_INVESTIGATION
    if (currentState !== CaseState.CASE_ASSIGNED && currentState !== CaseState.UNDER_INVESTIGATION) {
      throw ApiError.badRequest(`Cannot complete investigation from state: ${currentState}`);
    }

    const newState = CaseState.INVESTIGATION_COMPLETED;

    const result = await prisma.$transaction(async (tx) => {
      // Record history
      await tx.caseStateHistory.create({
        data: {
          caseId,
          fromState: currentState,
          toState: newState,
          changedBy: userId,
          changeReason: 'Investigation marked as complete by investigating officer',
        },
      });

      // Update current state
      await tx.currentCaseState.update({
        where: { caseId },
        data: { currentState: newState },
      });

      // Audit log
      await tx.auditLog.create({
        data: {
          userId,
          action: 'INVESTIGATION_COMPLETED',
          entity: 'CASE',
          entityId: caseId,
        },
      });

      return { caseId, previousState: currentState, newState };
    });

    return result;
  }
}
