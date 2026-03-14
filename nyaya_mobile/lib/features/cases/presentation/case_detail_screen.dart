import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/types/models.dart';
import '../../../core/types/enums.dart';

class CaseDetailScreen extends ConsumerStatefulWidget {
  final String caseId;

  const CaseDetailScreen({super.key, required this.caseId});

  @override
  ConsumerState<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends ConsumerState<CaseDetailScreen>
    with SingleTickerProviderStateMixin {
  Case? _case;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadCase();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCase() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/cases/${widget.caseId}');

      if (response.statusCode == 200) {
        setState(() {
          _case = Case.fromJson(response.data['data']);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load case: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Details'),
        bottom: _isLoading
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(icon: Icon(Icons.info), text: 'Overview'),
                  Tab(icon: Icon(Icons.search), text: 'Investigation'),
                  Tab(icon: Icon(Icons.people), text: 'Parties'),
                  Tab(icon: Icon(Icons.description), text: 'Documents'),
                  Tab(icon: Icon(Icons.gavel), text: 'Court'),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCase,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildInvestigationTab(),
                _buildPartiesTab(),
                _buildDocumentsTab(),
                _buildCourtTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCaseActions(context),
        icon: const Icon(Icons.more_vert),
        label: const Text('Actions'),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_case == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Case Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Case #${_case!.id.substring(0, 8)}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      _buildStatusChip(_case!.state?.currentState),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_case!.fir != null) ...[
                    Text(
                      'FIR: ${_case!.fir!.firNumber}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sections: ${_case!.fir!.sectionsApplied}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Timeline
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Case Timeline',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (_case!.stateHistory != null)
                    ..._case!.stateHistory!.map(
                      (history) => _buildTimelineItem(history),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(CaseState? state) {
    Color color;
    String label;

    switch (state) {
      case CaseState.firRegistered:
        color = Colors.blue;
        label = 'FIR Registered';
        break;
      case CaseState.underInvestigation:
        color = Colors.orange;
        label = 'Under Investigation';
        break;
      case CaseState.submittedToCourt:
        color = Colors.purple;
        label = 'Submitted to Court';
        break;
      case CaseState.trialOngoing:
        color = Colors.indigo;
        label = 'Trial Ongoing';
        break;
      case CaseState.disposed:
        color = Colors.green;
        label = 'Disposed';
        break;
      default:
        color = Colors.grey;
        label = state?.name ?? 'Unknown';
    }

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  Widget _buildTimelineItem(CaseStateHistory history) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${history.fromState.name} → ${history.toState.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(history.changeReason),
                const SizedBox(height: 4),
                Text(
                  _formatDate(history.changedAt),
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestigationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Evidence Section
          _buildSectionCard(
            'Evidence',
            _case?.evidence?.length ?? 0,
            Icons.folder_open,
            () =>
                Navigator.pushNamed(context, '/case/${widget.caseId}/evidence'),
          ),
          const SizedBox(height: 12),

          // Investigation Events
          _buildSectionCard(
            'Investigation Events',
            _case?.investigationEvents?.length ?? 0,
            Icons.event_note,
            () => Navigator.pushNamed(context, '/case/${widget.caseId}/events'),
          ),
        ],
      ),
    );
  }

  Widget _buildPartiesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Witnesses
          _buildSectionCard(
            'Witnesses',
            _case?.witnesses?.length ?? 0,
            Icons.people_outline,
            () => Navigator.pushNamed(
              context,
              '/case/${widget.caseId}/witnesses',
            ),
          ),
          const SizedBox(height: 12),

          // Accused
          _buildSectionCard(
            'Accused Persons',
            _case?.accused?.length ?? 0,
            Icons.person_outline,
            () =>
                Navigator.pushNamed(context, '/case/${widget.caseId}/accused'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Documents List
          if (_case?.documents != null)
            ..._case!.documents!.map(
              (doc) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(doc.documentType.name),
                  subtitle: Text('Version ${doc.version} • ${doc.status.name}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/case/${widget.caseId}/documents/${doc.id}',
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Add Document Button
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              '/case/${widget.caseId}/documents/create',
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Document'),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Court Submissions
          if (_case?.courtSubmissions != null)
            ..._case!.courtSubmissions!.map(
              (submission) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.gavel),
                  title: Text('Submission #${submission.submissionVersion}'),
                  subtitle: Text('Status: ${submission.status.name}'),
                  trailing: submission.acknowledgement != null
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.pending),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Court Actions
          if (_case?.courtActions != null)
            ..._case!.courtActions!.map(
              (action) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.gavel_outlined),
                  title: Text(action.actionType.name),
                  subtitle: Text(_formatDate(action.actionDate)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    int count,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '$count items',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _showCaseActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Update Status'),
              onTap: () {
                Navigator.pop(context);
                _showUpdateStatusDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_ind),
              title: const Text('Assign Case'),
              onTap: () {
                Navigator.pop(context);
                _showAssignCaseDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Submit to Court'),
              onTap: () {
                Navigator.pop(context);
                _showSubmitToCourtDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Case'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStatusDialog() {
    // TODO: Implement status update
  }

  void _showAssignCaseDialog() {
    // TODO: Implement case assignment
  }

  void _showSubmitToCourtDialog() {
    // TODO: Implement court submission
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
