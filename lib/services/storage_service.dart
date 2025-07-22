// lib/services/storage_service.dart
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // This import is now required and used

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // This method for personal documents was correct and remains.
  Future<String?> uploadDriverDocument({
    required String uid,
    required ImageSource source,
    required String docType,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image == null) return null;

      File file = File(image.path);
      String filePath = 'users/$uid/documents/$docType.jpg';
      Reference ref = _storage.ref().child(filePath);

      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('documents')
          .doc(docType)
          .set({
        'name': docType,
        'url': downloadUrl,
        'uploadedAt': Timestamp.now(),
      });

      return downloadUrl;
    } catch (e) {
      print('Failed to upload document: $e');
      return null;
    }
  }

  // --- THIS METHOD WAS MISSING ---
  /// Gets a real-time stream of the driver's personal uploaded documents.
  Stream<QuerySnapshot> getDriverDocuments(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('documents')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  // --- THIS METHOD WAS MISSING ---
  /// Uploads a receipt image for a specific transaction and updates the transaction.
  /// Returns the download URL.
  Future<String?> uploadExpenseReceipt({
    required String uid,
    required String transactionId,
    required File imageFile,
  }) async {
    try {
      String filePath = 'users/$uid/receipts/$transactionId.jpg';
      Reference ref = _storage.ref().child(filePath);

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update the transaction document with the receipt URL
      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .update({'receiptUrl': downloadUrl});

      return downloadUrl;
    } catch (e) {
      print('Failed to upload receipt: $e');
      return null;
    }
  }
}