import 'package:cloud_firestore/cloud_firestore.dart';

class PredictionRecord {
  final String id;
  final String userId;
  final List<String> symptoms;
  final String predictedDisease;
  final double confidence;
  final List<Map<String, dynamic>> top3;
  final DateTime createdAt;

  PredictionRecord({
    required this.id,
    required this.userId,
    required this.symptoms,
    required this.predictedDisease,
    required this.confidence,
    required this.top3,
    required this.createdAt,
  });

  factory PredictionRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PredictionRecord(
      id: doc.id,
      userId: data['userId'] ?? '',
      symptoms: List<String>.from(data['symptoms'] ?? []),
      predictedDisease: data['predictedDisease'] ?? '',
      confidence: (data['confidence'] ?? 0.0).toDouble(),
      top3: List<Map<String, dynamic>>.from(data['top3'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'symptoms': symptoms,
      'predictedDisease': predictedDisease,
      'confidence': confidence,
      'top3': top3,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
