import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/types/models.dart';

class FIRDetailScreen extends ConsumerStatefulWidget {
  final String firId;

  const FIRDetailScreen({super.key, required this.firId});

  @override
  ConsumerState<FIRDetailScreen> createState() => _FIRDetailScreenState();
}

class _FIRDetailScreenState extends ConsumerState<FIRDetailScreen> {
  FIR? _fir;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFIR();
  }

  Future<void> _loadFIR() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/firs/${widget.firId}');

      if (response.statusCode == 200) {
        setState(() {
          _fir = FIR.fromJson(response.data['data']);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load FIR: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FIR Details'),
        actions: [
          if (_fir?.case_ != null)
            TextButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/case/${_fir!.case_!.id}'),
              icon: const Icon(Icons.gavel),
              label: const Text('View Case'),
            ),
        ],
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
                    onPressed: _loadFIR,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FIR Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.description,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _fir?.firNumber ?? 'Unknown',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Source: ${_fir?.firSource.name ?? 'Unknown'}',
                                      style: TextStyle(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Sections Applied
                          _buildInfoRow(
                            'Sections Applied',
                            _fir?.sectionsApplied ?? 'N/A',
                            Icons.gavel,
                          ),
                          const SizedBox(height: 12),

                          // Incident Date
                          _buildInfoRow(
                            'Incident Date',
                            _formatDate(_fir?.incidentDate),
                            Icons.calendar_today,
                          ),
                          const SizedBox(height: 12),

                          // Registered By
                          _buildInfoRow(
                            'Registered By',
                            _fir?.user?.name ?? 'Unknown',
                            Icons.person,
                          ),
                          const SizedBox(height: 12),

                          // Police Station
                          _buildInfoRow(
                            'Police Station',
                            _fir?.policeStation?.name ?? 'Unknown',
                            Icons.local_police,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // FIR Document
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FIR Document',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          if (_fir?.firDocumentUrl != null)
                            ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Open document viewer
                              },
                              icon: const Icon(Icons.visibility),
                              label: const Text('View Document'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.error_outline),
                                  SizedBox(width: 8),
                                  Text('No document available'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Associated Case
                  if (_fir?.case_ != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Associated Case',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.folder),
                              title: Text(
                                'Case #${_fir!.case_!.id.substring(0, 8)}',
                              ),
                              subtitle: Text(
                                'Status: ${_fir!.case_!.state?.currentState.name ?? 'Unknown'}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/case/${_fir!.case_!.id}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Create Case Button
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No Case Created',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This FIR has not been converted to a case yet.',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showCreateCaseDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Create Case'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCreateCaseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Case from FIR'),
        content: const Text(
          'This will create a new case from this FIR. The case will be assigned to you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _createCase();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createCase() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.post(
        '/cases',
        data: {'firId': widget.firId},
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Case created successfully')),
          );
          _loadFIR(); // Reload to show the new case
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create case: $e')));
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
