import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/memory.dart';
import '../models/user.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // User Authentication
  Future<User?> signUp(String email, String password, String displayName) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = User(
        id: credential.user!.uid,
        email: email,
        displayName: displayName,
      );

      await _firestore.collection('users').doc(user.id).set(user.toMap());
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc =
          await _firestore.collection('users').doc(credential.user!.uid).get();
      return User.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Memory CRUD Operations
  Future<void> createMemory(Memory memory) async {
    await _firestore.collection('memories').doc(memory.id).set(memory.toMap());
  }

  Future<Memory?> getMemory(String memoryId) async {
    final doc = await _firestore.collection('memories').doc(memoryId).get();
    if (!doc.exists) return null;
    return Memory.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<List<Memory>> getUserMemories(String userId) async {
    final query = await _firestore
        .collection('memories')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();

    return query.docs
        .map((doc) => Memory.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Stream<List<Memory>> getUserMemoriesStream(String userId) {
    return _firestore
        .collection('memories')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((query) => query.docs
            .map((doc) => Memory.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> updateMemory(Memory memory) async {
    final updated = memory.copyWith(updatedAt: DateTime.now());
    await _firestore
        .collection('memories')
        .doc(memory.id)
        .update(updated.toMap());
  }

  Future<void> deleteMemory(String memoryId) async {
    await _firestore.collection('memories').doc(memoryId).delete();
  }

  Future<void> toggleFavorite(String memoryId, bool isFavorite) async {
    await _firestore
        .collection('memories')
        .doc(memoryId)
        .update({'isFavorite': isFavorite});
  }

  // File Upload
  Future<String> uploadImage(String filePath, String userId) async {
    try {
      final file = _storage.ref().child('memories/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.putFile(File(filePath));
      return await file.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadAudio(String filePath, String userId) async {
    try {
      final file = _storage.ref().child('audio/$userId/${DateTime.now().millisecondsSinceEpoch}.m4a');
      await file.putFile(File(filePath));
      return await file.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }
}

import 'dart:io';
