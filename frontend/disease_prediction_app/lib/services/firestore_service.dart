import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/prediction_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save a prediction
  Future<void> savePrediction({
    required List<String> symptoms,
    required String predictedDisease,
    required double confidence,
    required List<Map<String, dynamic>> top3,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final prediction = PredictionRecord(
      id: '',
      userId: user.uid,
      symptoms: symptoms,
      predictedDisease: predictedDisease,
      confidence: confidence,
      top3: top3,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('predictions')
        .add(prediction.toMap());
  }

  // Get user's prediction history
  Stream<List<PredictionRecord>> getPredictionHistory() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('predictions')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PredictionRecord.fromFirestore(doc))
            .toList());
  }

  // Delete a prediction
  Future<void> deletePrediction(String predictionId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('predictions')
        .doc(predictionId)
        .delete();
  }

  // Clear all history
  Future<void> clearHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    final predictions = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('predictions')
        .get();

    for (var doc in predictions.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
