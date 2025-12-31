import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Header } from '../../components/layout/Header';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { Badge } from '../../components/ui/Badge';
import { Loader } from '../../components/common/Loader';
import { ErrorMessage } from '../../components/common/ErrorMessage';
import { caseApi } from '../../api';
import type { Case } from '../../types/api.types';
import { CaseState } from '../../types/api.types';
import { getCaseStateBadgeVariant, getCaseStateLabel } from '../../utils/caseState';

export const PoliceDashboard: React.FC = () => {
  const [cases, setCases] = useState<Case[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchMyCases();
  }, []);

  const fetchMyCases = async () => {
    try {
      setIsLoading(true);
      setError(null);
      const data = await caseApi.getMyCases();
      setCases(data);
    } catch (err: any) {
      setError(err.response?.data?.message || err.message || 'Failed to load cases');
    } finally {
      setIsLoading(false);
    }
  };

  if (isLoading) return <Loader />;
  if (error) return <ErrorMessage message={error} retry={fetchMyCases} />;

  // Calculate stats
  const totalCases = cases.length;
  const underInvestigation = cases.filter(
    c => c.state?.currentState === CaseState.UNDER_INVESTIGATION
  ).length;
  const submittedToCourt = cases.filter(
    c => c.state?.currentState === CaseState.SUBMITTED_TO_COURT ||
         c.state?.currentState === CaseState.COURT_ACCEPTED
  ).length;

  return (
    <>
      <Header
        title="Police Dashboard"
        subtitle="Manage FIRs and investigations"
        action={
          <Link to="/police/create-fir">
            <Button variant="primary">+ Create FIR</Button>
          </Link>
        }
      />

      {/* Stats Cards */}
      <div className="stats-grid">
        <div className="dashboard-stat-card">
          <div className="dashboard-stat-number" style={{ color: '#1B4F72' }}>{totalCases}</div>
          <div className="dashboard-stat-label">Total Cases</div>
        </div>
        <div className="dashboard-stat-card">
          <div className="dashboard-stat-number" style={{ color: '#FF8C00' }}>{underInvestigation}</div>
          <div className="dashboard-stat-label">Under Investigation</div>
        </div>
        <div className="dashboard-stat-card">
          <div className="dashboard-stat-number" style={{ color: '#006400' }}>{submittedToCourt}</div>
          <div className="dashboard-stat-label">In Court</div>
        </div>
      </div>

      {/* Recent Cases */}
      <Card title="My Assigned Cases">
        {cases.length === 0 ? (
          <div className="text-center py-8">
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 max-w-md mx-auto">
              <p className="text-blue-800 font-medium text-lg mb-2">
                No Cases Assigned Yet
              </p>
              <p className="text-blue-600 text-sm mb-4">
                Cases you create will appear here once the SHO assigns them to you for investigation.
              </p>
              <p className="text-gray-500 text-xs">
                💡 Tip: After creating an FIR, ask your SHO to assign the case to you.
              </p>
            </div>
            <div className="mt-6">
              <Link to="/police/create-fir">
                <Button variant="primary">+ Create New FIR</Button>
              </Link>
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            {cases.slice(0, 5).map((c) => {
              const state = c.state?.currentState || 'UNKNOWN';
              const firNumber = c.fir?.firNumber || c.id.slice(0, 8);
              
              return (
                <Link
                  key={c.id}
                  to={`/police/cases/${c.id}`}
                  className="case-list-item block"
                >
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <h3 className="case-list-title">FIR: {firNumber}</h3>
                      <p className="text-sm text-gray-700 mt-1">
                        {c.fir?.sectionsApplied || 'No sections specified'}
                      </p>
                      <div className="case-list-meta">
                        <span className="case-list-meta-item">📅 {new Date(c.createdAt).toLocaleDateString()}</span>
                        {c.fir?.policeStation && (
                          <span className="case-list-meta-item">🏢 {c.fir.policeStation.name}</span>
                        )}
                      </div>
                    </div>
                    <Badge variant={getCaseStateBadgeVariant(state)}>
                      {getCaseStateLabel(state)}
                    </Badge>
                  </div>
                </Link>
              );
            })}
            
            {cases.length > 5 && (
              <Link 
                to="/police/my-cases" 
                className="block text-center text-blue-600 hover:underline mt-4 py-2"
              >
                View All {cases.length} Cases →
              </Link>
            )}
          </div>
        )}
      </Card>
    </>
  );
};
