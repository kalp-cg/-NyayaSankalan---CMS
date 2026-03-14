import React, { useEffect, useState } from 'react';
import { Card } from '../ui/Card';
import { Button } from '../ui/Button';
import { Badge } from '../ui/Badge';
import { caseApi } from '../../api';
import type { CaseCopilotBrief } from '../../types/api.types';

interface Props {
  caseId?: string;
}

export const CaseCopilotBriefCard: React.FC<Props> = ({ caseId }) => {
  const [brief, setBrief] = useState<CaseCopilotBrief | null>(null);
  const [loading, setLoading] = useState(false);

  const fetchBrief = async () => {
    if (!caseId) return;
    try {
      setLoading(true);
      const data = await caseApi.getCopilotBrief(caseId);
      setBrief(data);
    } catch {
      setBrief({
        summary: 'Copilot brief is currently unavailable for this case.',
        keyRisks: [],
        nextActions: [],
        missingItems: [],
        confidence: 0,
        source: 'fallback',
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBrief();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [caseId]);

  if (!caseId) {
    return (
      <Card title="AI Case Copilot">
        <p className="text-sm text-gray-600">Assign or open a case to see AI guidance.</p>
      </Card>
    );
  }

  return (
    <Card title="AI Case Copilot">
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Badge variant={brief?.source === 'ai' ? 'success' : 'warning'}>
              {brief?.source === 'ai' ? 'AI' : 'Fallback'}
            </Badge>
            <span className="text-xs text-gray-500">
              Confidence: {Math.round((brief?.confidence || 0) * 100)}%
            </span>
          </div>
          <Button variant="secondary" size="sm" onClick={fetchBrief} isLoading={loading}>
            Refresh
          </Button>
        </div>

        <div className="bg-blue-50 border border-blue-100 rounded-lg p-3">
          <p className="text-sm text-gray-800">{brief?.summary || 'Generating case summary...'}</p>
        </div>

        <div>
          <p className="text-sm font-semibold text-gray-800 mb-1">Next Actions</p>
          <ul className="list-disc pl-5 space-y-1 text-sm text-gray-700">
            {(brief?.nextActions || []).slice(0, 3).map((item, idx) => (
              <li key={`next-${idx}`}>{item}</li>
            ))}
            {(!brief?.nextActions || brief.nextActions.length === 0) && <li>No suggested actions yet.</li>}
          </ul>
        </div>

        <div>
          <p className="text-sm font-semibold text-gray-800 mb-1">Risk Flags</p>
          <ul className="list-disc pl-5 space-y-1 text-sm text-gray-700">
            {(brief?.keyRisks || []).slice(0, 3).map((item, idx) => (
              <li key={`risk-${idx}`}>{item}</li>
            ))}
            {(!brief?.keyRisks || brief.keyRisks.length === 0) && <li>No immediate risks flagged.</li>}
          </ul>
        </div>
      </div>
    </Card>
  );
};
