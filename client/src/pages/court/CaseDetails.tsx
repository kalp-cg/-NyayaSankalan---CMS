import React, { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import toast from 'react-hot-toast';
import { Header } from '../../components/layout/Header';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { Badge } from '../../components/ui/Badge';
import { Input } from '../../components/ui/Input';
import { Loader } from '../../components/common/Loader';
import { ErrorMessage } from '../../components/common/ErrorMessage';
import { EmptyState } from '../../components/common/EmptyState';
import { CaseTimeline } from '../../components/case/CaseTimeline';
import { ClosureReportButton } from '../../components/case/ClosureReportButton';
import { caseApi, courtApi } from '../../api';
import type { Case, CourtAction } from '../../types/api.types';
import { CaseState } from '../../types/api.types';
import { getCaseStateBadgeVariant, getCaseStateLabel, canIntakeCase } from '../../utils/caseState';

export const CourtCaseDetails: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const [caseData, setCaseData] = useState<Case | null>(null);
  const [courtActions, setCourtActions] = useState<CourtAction[]>([]);
  const [acknowledgementNumber, setAcknowledgementNumber] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isIntaking, setIsIntaking] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (id) {
      fetchData();
    }
  }, [id]);

  const fetchData = async () => {
    try {
      setIsLoading(true);
      setError(null);
      const [caseDetails, actions] = await Promise.all([
        caseApi.getCaseById(id!),
        courtApi.getCourtActions(id!).catch(() => []),
      ]);
      setCaseData(caseDetails);
      setCourtActions(actions);
    } catch (err: any) {
      setError(err.response?.data?.message || err.message || 'Failed to load data');
    } finally {
      setIsLoading(false);
    }
  };

  const handleIntakeCase = async () => {
    try {
      setIsIntaking(true);
      await courtApi.intakeCase(id!, {
        acknowledgementNumber: acknowledgementNumber || undefined,
      });
      toast.success('Case accepted successfully');
      fetchData(); // Refresh data
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Failed to accept case');
    } finally {
      setIsIntaking(false);
    }
  };

  if (isLoading) return <Loader />;
  if (error) return <ErrorMessage message={error} retry={fetchData} />;
  if (!caseData) return <ErrorMessage message="Case not found" />;

  const fir = caseData.fir;
  const currentState = caseData.state?.currentState || 'UNKNOWN';
  const canIntake = canIntakeCase(currentState);

  return (
    <>
      <Header
        title={`Case: ${fir?.firNumber || caseData.id.slice(0, 8)}`}
        subtitle={`Status: ${getCaseStateLabel(currentState)}`}
      />

      <div className="space-y-6">
        {/* Case Overview */}
        <Card title="Case Information">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <div>
              <p className="text-sm text-gray-500">FIR Number</p>
              <p className="font-semibold text-lg">{fir?.firNumber || 'N/A'}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Case State</p>
              <Badge variant={getCaseStateBadgeVariant(currentState)}>
                {getCaseStateLabel(currentState)}
              </Badge>
            </div>
            <div>
              <p className="text-sm text-gray-500">Received On</p>
              <p className="font-semibold">
                {new Date(caseData.createdAt).toLocaleDateString('en-IN')}
              </p>
            </div>
          </div>
        </Card>

        {/* Closure Report - Only for ARCHIVED cases */}
        {currentState === CaseState.ARCHIVED && (
          <ClosureReportButton caseId={id!} isArchived={true} />
        )}

        {/* FIR Details */}
        {fir && (
          <Card title="FIR Details">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-500">Sections Applied</p>
                <p className="font-semibold">{fir.sectionsApplied}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">Incident Date</p>
                <p className="font-semibold">
                  {new Date(fir.incidentDate).toLocaleString('en-IN')}
                </p>
              </div>
              {fir.policeStation && (
                <div className="md:col-span-2">
                  <p className="text-sm text-gray-500">From Police Station</p>
                  <p className="font-semibold">
                    {fir.policeStation.name}, {fir.policeStation.district}
                  </p>
                </div>
              )}
            </div>
          </Card>
        )}

        {/* Investigation Summary */}
        <Card title="Case Summary">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
            <div className="p-4 bg-blue-50 rounded-lg">
              <p className="text-2xl font-bold text-blue-600">
                {caseData.evidence?.length || 0}
              </p>
              <p className="text-sm text-gray-600">Evidence Items</p>
            </div>
            <div className="p-4 bg-green-50 rounded-lg">
              <p className="text-2xl font-bold text-green-600">
                {caseData.witnesses?.length || 0}
              </p>
              <p className="text-sm text-gray-600">Witnesses</p>
            </div>
            <div className="p-4 bg-orange-50 rounded-lg">
              <p className="text-2xl font-bold text-orange-600">
                {caseData.accused?.length || 0}
              </p>
              <p className="text-sm text-gray-600">Accused</p>
            </div>
            <div className="p-4 bg-purple-50 rounded-lg">
              <p className="text-2xl font-bold text-purple-600">
                {caseData.documents?.length || 0}
              </p>
              <p className="text-sm text-gray-600">Documents</p>
            </div>
          </div>
        </Card>

        {/* Intake Action */}
        {canIntake && (
          <Card title="Accept Case (Court Intake)">
            <div className="space-y-4">
              <p className="text-gray-600">
                Accept this case to proceed with court proceedings. Optionally provide
                an acknowledgement number for tracking.
              </p>
              <Input
                label="Acknowledgement Number (Optional)"
                placeholder="e.g., ACK-2024-001"
                value={acknowledgementNumber}
                onChange={(e) => setAcknowledgementNumber(e.target.value)}
              />
              <Button
                variant="primary"
                onClick={handleIntakeCase}
                isLoading={isIntaking}
              >
                Accept Case
              </Button>
            </div>
          </Card>
        )}

        {/* Already Accepted */}
        {currentState === CaseState.COURT_ACCEPTED && (
          <Card>
            <div className="bg-green-50 border border-green-200 rounded-lg p-4 text-center">
              <p className="text-green-800 font-medium text-lg">
                ✓ Case Accepted by Court
              </p>
              <p className="text-green-600 mt-1">
                Case is ready for court proceedings
              </p>
            </div>
          </Card>
        )}

        {/* Court Actions */}
        <Card title="Court Actions">
          {courtActions.length === 0 ? (
            <EmptyState
              title="No Court Actions Yet"
              message="Court actions (hearings, orders) will appear here"
            />
          ) : (
            <div className="space-y-3">
              {courtActions.map((action) => (
                <div
                  key={action.id}
                  className="p-4 border rounded-lg bg-gray-50"
                >
                  <div className="flex justify-between items-start">
                    <div>
                      <p className="font-medium">{action.actionType.replace(/_/g, ' ')}</p>
                      <p className="text-sm text-gray-600 mt-1">
                        {new Date(action.actionDate).toLocaleString('en-IN')}
                      </p>
                    </div>
                    <Badge variant="info">{action.actionType}</Badge>
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>

        {/* Case Timeline */}
        <Card title="Case Timeline">
          <CaseTimeline caseId={id!} />
        </Card>

        {/* Back Button */}
        <div className="flex gap-4">
          <Link to="/court/incoming-cases">
            <Button variant="secondary">← Back to Incoming Cases</Button>
          </Link>
          <Link to="/court/dashboard">
            <Button variant="secondary">← Dashboard</Button>
          </Link>
        </div>
      </div>
    </>
  );
};
