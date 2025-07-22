// lib/screens/driver/tabs/driver_documents_tab.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logistic_app/services/auth_service.dart';
import '../../../services/storage_service.dart';
// You might need a URL launcher to open the documents
// import 'package:url_launcher/url_launcher.dart';

class DriverDocumentsTab extends StatefulWidget {
  const DriverDocumentsTab({super.key});

  @override
  State<DriverDocumentsTab> createState() => _DriverDocumentsTabState();
}

class _DriverDocumentsTabState extends State<DriverDocumentsTab> {
  final StorageService _storageService = StorageService();
  final String? uid = AuthService().currentUser?.uid;
  bool _isUploading = false;

  Future<void> _showUploadOptions() async {
    final docType = await _showDocTypeDialog();
    if (docType == null || docType.isEmpty) return; // User cancelled

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Library'),
              onTap: () {
                Navigator.of(context).pop();
                _uploadDocument(ImageSource.gallery, docType);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _uploadDocument(ImageSource.camera, docType);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showDocTypeDialog() {
    final docTypeController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Document Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pre-defined options
            DropdownButtonFormField<String>(
              items: ['Driving License', 'Aadhar Card', 'Vehicle RC', 'Vehicle Insurance', 'Other']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => docTypeController.text = val ?? '',
              decoration: const InputDecoration(labelText: 'Common Documents'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: docTypeController,
              decoration: const InputDecoration(labelText: 'Or enter custom name'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(docTypeController.text), child: const Text('Next')),
        ],
      ),
    );
  }

  Future<void> _uploadDocument(ImageSource source, String docType) async {
    if (uid == null) return;
    setState(() => _isUploading = true);

    final downloadUrl = await _storageService.uploadDriverDocument(
      uid: uid!,
      source: source,
      docType: docType,
    );

    if (mounted) {
      setState(() => _isUploading = false);
      if (downloadUrl != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded successfully!'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed. Please try again.'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const Center(child: Text("User not logged in."));

    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _storageService.getDriverDocuments(uid!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Error fetching documents."));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No documents uploaded yet."));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined, color: Colors.blueAccent),
                      title: Text(doc['name'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: const Text('Tap to view'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Use url_launcher to open doc['url']
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening document... ${doc['url']} ')));
                      },
                    ),
                  );
                },
              );
            },
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text("Uploading...", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _showUploadOptions,
        label: const Text('Upload Document'),
        icon: const Icon(Icons.upload_file),
      ),
    );
  }
}