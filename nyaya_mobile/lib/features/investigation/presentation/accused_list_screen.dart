import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/types/models.dart';
import '../../../core/types/enums.dart';

class AccusedListScreen extends ConsumerStatefulWidget {
  final String caseId;

  const AccusedListScreen({super.key, required this.caseId});

  @override
  ConsumerState<AccusedListScreen> createState() => _AccusedListScreenState();
}

class _AccusedListScreenState extends ConsumerState<AccusedListScreen> {
  List<Accused> _accused = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccused();
  }

  Future<void> _loadAccused() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get(
        '/cases/${widget.caseId}/accused',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        setState(() {
          _accused = data.map((a) => Accused.fromJson(a)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load accused: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accused Persons')),
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
                    onPressed: _loadAccused,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _accused.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 64,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text('No accused persons added yet'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddAccusedDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Accused'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _accused.length,
              itemBuilder: (context, index) {
                final accused = _accused[index];
                return _buildAccusedCard(accused);
              },
            ),
      floatingActionButton: _accused.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddAccusedDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Accused'),
            ),
    );
  }

  Widget _buildAccusedCard(Accused accused) {
    Color statusColor;
    IconData statusIcon;

    switch (accused.status) {
      case AccusedStatus.arrested:
        statusColor = Colors.red;
        statusIcon = Icons.lock;
        break;
      case AccusedStatus.onBail:
        statusColor = Colors.orange;
        statusIcon = Icons.lock_open;
        break;
      case AccusedStatus.absconding:
        statusColor = Colors.grey;
        statusIcon = Icons.person_off;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAccusedDetails(accused),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accused.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(accused.status.name),
                      backgroundColor: statusColor.withOpacity(0.1),
                      labelStyle: TextStyle(color: statusColor, fontSize: 12),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    if (accused.bailRecords != null &&
                        accused.bailRecords!.isNotEmpty)
                      Text(
                        '${accused.bailRecords!.length} bail record(s)',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
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

  void _showAccusedDetails(Accused accused) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                AppBar(
                  title: const Text('Accused Details'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditAccusedDialog(accused);
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                accused.status,
                              ).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getStatusIcon(accused.status),
                              size: 40,
                              color: _getStatusColor(accused.status),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildDetailRow('Name', accused.name),
                        _buildDetailRow('Status', accused.status.name),
                        if (accused.bailRecords != null &&
                            accused.bailRecords!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Bail Records',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ...accused.bailRecords!.map(
                            (bail) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(bail.bailType.name),
                                subtitle: Text('Status: ${bail.status.name}'),
                                trailing: bail.status == BailStatus.granted
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                    : const Icon(Icons.pending),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showAddBailDialog(accused);
                          },
                          icon: const Icon(Icons.gavel),
                          label: const Text('Add Bail Application'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AccusedStatus status) {
    switch (status) {
      case AccusedStatus.arrested:
        return Colors.red;
      case AccusedStatus.onBail:
        return Colors.orange;
      case AccusedStatus.absconding:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(AccusedStatus status) {
    switch (status) {
      case AccusedStatus.arrested:
        return Icons.lock;
      case AccusedStatus.onBail:
        return Icons.lock_open;
      case AccusedStatus.absconding:
        return Icons.person_off;
    }
  }

  void _showAddAccusedDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Accused'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name *',
            hintText: 'Enter accused name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name is required')),
                );
                return;
              }

              Navigator.pop(context);
              await _addAccused(name: nameController.text);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditAccusedDialog(Accused accused) {
    // TODO: Implement edit
  }

  void _showAddBailDialog(Accused accused) {
    // TODO: Implement bail application
  }

  Future<void> _addAccused({required String name}) async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.post(
        '/cases/${widget.caseId}/accused',
        data: {'name': name, 'status': 'ARRESTED'},
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Accused added successfully')),
          );
          _loadAccused();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add accused: $e')));
      }
    }
  }
}
