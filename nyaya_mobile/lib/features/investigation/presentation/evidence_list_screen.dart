import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/types/models.dart';
import '../../../core/types/enums.dart';

class EvidenceListScreen extends ConsumerStatefulWidget {
  final String caseId;

  const EvidenceListScreen({super.key, required this.caseId});

  @override
  ConsumerState<EvidenceListScreen> createState() => _EvidenceListScreenState();
}

class _EvidenceListScreenState extends ConsumerState<EvidenceListScreen> {
  List<Evidence> _evidence = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvidence();
  }

  Future<void> _loadEvidence() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get(
        '/cases/${widget.caseId}/evidence',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        setState(() {
          _evidence = data.map((e) => Evidence.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load evidence: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evidence')),
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
                    onPressed: _loadEvidence,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _evidence.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text('No evidence uploaded yet'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEvidenceDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Evidence'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _evidence.length,
              itemBuilder: (context, index) {
                final evidence = _evidence[index];
                return _buildEvidenceCard(evidence);
              },
            ),
      floatingActionButton: _evidence.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddEvidenceDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Evidence'),
            ),
    );
  }

  Widget _buildEvidenceCard(Evidence evidence) {
    IconData iconData;
    Color color;

    switch (evidence.category) {
      case EvidenceCategory.photo:
        iconData = Icons.image;
        color = Colors.blue;
        break;
      case EvidenceCategory.report:
        iconData = Icons.description;
        color = Colors.green;
        break;
      case EvidenceCategory.forensic:
        iconData = Icons.science;
        color = Colors.purple;
        break;
      case EvidenceCategory.statement:
        iconData = Icons.record_voice_over;
        color = Colors.orange;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewEvidence(evidence),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(iconData, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evidence.fileName ??
                          'Evidence #${evidence.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      evidence.category.name,
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Uploaded by ${evidence.user?.name ?? 'Unknown'}',
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

  void _viewEvidence(Evidence evidence) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
                  title: const Text('Evidence Details'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        // TODO: Share evidence
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () {
                        // TODO: Download evidence
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
                        // Preview
                        Container(
                          width: double.infinity,
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.image, size: 64),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Details
                        _buildDetailRow('Category', evidence.category.name),
                        _buildDetailRow(
                          'File Name',
                          evidence.fileName ?? 'N/A',
                        ),
                        _buildDetailRow(
                          'MIME Type',
                          evidence.mimeType ?? 'N/A',
                        ),
                        _buildDetailRow(
                          'Uploaded By',
                          evidence.user?.name ?? 'Unknown',
                        ),
                        _buildDetailRow(
                          'Uploaded At',
                          _formatDate(evidence.uploadedAt),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEvidenceDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Add Evidence',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement camera
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement gallery picker
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Upload File'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement file picker
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic),
                title: const Text('Record Audio Statement'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement audio recording
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
