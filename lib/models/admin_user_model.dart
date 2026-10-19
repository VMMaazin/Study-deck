import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an authorized administrative user profile stored in Firestore `users/{uid}`.
class AdminUserModel {
  const AdminUserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.isActive = false,
    this.displayName,
    this.createdAt,
  });

  final String uid;
  final String email;
  final String role;
  final bool isActive;
  final String? displayName;
  final DateTime? createdAt;

  bool get isAdmin => role.toLowerCase() == 'admin' && isActive;

  factory AdminUserModel.fromMap(
    Map<String, dynamic> data, {
    required String uid,
  }) {
    final rawIsActive = data['isActive'];
    final bool parsedIsActive = rawIsActive is bool ? rawIsActive : false;
    final createdTimestamp = data['createdAt'];
    DateTime? parsedCreatedAt;
    if (createdTimestamp is Timestamp) {
      parsedCreatedAt = createdTimestamp.toDate();
    } else if (createdTimestamp is DateTime) {
      parsedCreatedAt = createdTimestamp;
    }

    return AdminUserModel(
      uid: uid,
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? '',
      isActive: parsedIsActive,
      displayName: data['displayName'] as String?,
      createdAt: parsedCreatedAt,
    );
  }

  factory AdminUserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return AdminUserModel.fromMap(doc.data() ?? {}, uid: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'isActive': isActive,
      'displayName': displayName,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
