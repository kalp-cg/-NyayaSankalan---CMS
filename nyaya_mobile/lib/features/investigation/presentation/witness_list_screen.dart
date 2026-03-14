import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/types/models.dart';

class WitnessListScreen extends ConsumerStatefulWidget {
  final String caseId;

  const WitnessListScreen({super.key, required this.caseId});

  @override
  ConsumerState<WitnessListScreen> createState() => _WitnessListScreenState();
}

class _WitnessListScreenState extends ConsumerState<WitnessListScreen> {
  List<Witness> _witnesses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWitnesses();
  }

  Future<void> _loadWitnesses() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get(
        '/cases/${widget.caseId}/witnesses',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        setState(() {
          _witnesses = data.map((w) => Witness.fromJson(w)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load witnesses: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Witnesses')),
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
                    onPressed: _loadWitnesses,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _witnesses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text('No witnesses added yet'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddWitnessDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Witness'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _witnesses.length,
              itemBuilder: (context, index) {
                final witness = _witnesses[index];
                return _buildWitnessCard(witness);
              },
            ),
      floatingActionButton: _witnesses.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddWitnessDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Witness'),
            ),
    );
  }

  Widget _buildWitnessCard(Witness witness) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showWitnessDetails(witness),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      witness.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (witness.contact != null)
                      Text(
                        witness.contact!,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    if (witness.statementFileUrl != null)
                      Chip(
                        label: const Text('Statement Recorded'),
                        backgroundColor: Colors.green[100],
                        labelStyle: TextStyle(color: Colors.green[800]),
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

  void _showWitnessDetails(Witness witness) {
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
                  title: const Text('Witness Details'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditWitnessDialog(witness);
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
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildDetailRow('Name', witness.name),
                        if (witness.contact != null)
                          _buildDetailRow('Contact', witness.contact!),
                        if (witness.address != null)
                          _buildDetailRow('Address', witness.address!),
                        if (witness.statementFileUrl != null) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: View statement
                            },
                            icon: const Icon(Icons.description),
                            label: const Text('View Statement'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showRecordStatementDialog(witness);
                            },
                            icon: const Icon(Icons.mic),
                            label: const Text('Record Statement'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ],
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

  void _showAddWitnessDialog() {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Witness'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'Enter witness name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  hintText: 'Enter contact number',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter address',
                ),
                maxLines: 2,
              ),
            ],
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
              await _addWitness(
                name: nameController.text,
                contact: contactController.text.isEmpty
                    ? null
                    : contactController.text,
                address: addressController.text.isEmpty
                    ? null
                    : addressController.text,
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditWitnessDialog(Witness witness) {
    // TODO: Implement edit
  }

  void _showRecordStatementDialog(Witness witness) {
    // TODO: Implement statement recording
  }

  Future<void> _addWitness({
    required String name,
    String? contact,
    String? address,
  }) async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.post(
        '/cases/${widget.caseId}/witnesses',
        data: {'name': name, 'contact': contact, 'address': address},
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Witness added successfully')),
          );
          _loadWitnesses();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add witness: $e')));
      }
    }
  }
}
