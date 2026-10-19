import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_deck/models/admin_user_model.dart';

void main() {
  group('AdminUserModel Active-State & Authorization Parsing Tests', () {
    test('Preserves explicitly active admin (isActive: true)', () {
      final model = AdminUserModel.fromMap({
        'email': 'admin@studydeck.edu',
        'role': 'admin',
        'isActive': true,
        'displayName': 'Super Admin',
      }, uid: 'admin_123');

      expect(model.uid, 'admin_123');
      expect(model.email, 'admin@studydeck.edu');
      expect(model.role, 'admin');
      expect(model.isActive, isTrue);
      expect(model.isAdmin, isTrue);
      expect(model.displayName, 'Super Admin');
    });

    test('Preserves explicitly inactive admin (isActive: false)', () {
      final model = AdminUserModel.fromMap({
        'email': 'deactivated@studydeck.edu',
        'role': 'admin',
        'isActive': false,
      }, uid: 'admin_deactivated');

      expect(model.isActive, isFalse);
      expect(model.isAdmin, isFalse);
    });

    test('Fails closed when isActive is missing from document data', () {
      final model = AdminUserModel.fromMap({
        'email': 'legacy_user@studydeck.edu',
        'role': 'admin',
      }, uid: 'admin_missing_active');

      // Must fail closed to false to align with Firestore security rules
      expect(model.isActive, isFalse);
      expect(model.isAdmin, isFalse);
    });

    test('Fails closed when isActive is null', () {
      final model = AdminUserModel.fromMap({
        'email': 'null_active@studydeck.edu',
        'role': 'admin',
        'isActive': null,
      }, uid: 'admin_null_active');

      expect(model.isActive, isFalse);
      expect(model.isAdmin, isFalse);
    });

    test('Fails closed when isActive has invalid types (string, integer, object)', () {
      // String 'true'
      final stringActive = AdminUserModel.fromMap({
        'email': 'str@studydeck.edu',
        'role': 'admin',
        'isActive': 'true',
      }, uid: 'str_1');
      expect(stringActive.isActive, isFalse);
      expect(stringActive.isAdmin, isFalse);

      // Integer 1
      final intActive = AdminUserModel.fromMap({
        'email': 'int@studydeck.edu',
        'role': 'admin',
        'isActive': 1,
      }, uid: 'int_1');
      expect(intActive.isActive, isFalse);
      expect(intActive.isAdmin, isFalse);

      // List or map
      final mapActive = AdminUserModel.fromMap({
        'email': 'map@studydeck.edu',
        'role': 'admin',
        'isActive': {'active': true},
      }, uid: 'map_1');
      expect(mapActive.isActive, isFalse);
      expect(mapActive.isAdmin, isFalse);
    });

    test('Preserves role checks (non-admin role with isActive: true is not admin)', () {
      final student = AdminUserModel.fromMap({
        'email': 'student@studydeck.edu',
        'role': 'student',
        'isActive': true,
      }, uid: 'student_1');

      expect(student.isActive, isTrue);
      expect(student.isAdmin, isFalse);
    });

    test('Default constructor also fails closed (isActive defaults to false)', () {
      const model = AdminUserModel(
        uid: 'new_uid',
        email: 'test@studydeck.edu',
        role: 'admin',
      );

      expect(model.isActive, isFalse);
      expect(model.isAdmin, isFalse);
    });

    test('Serializes to map properly with Timestamp', () {
      final now = DateTime(2026, 1, 15);
      final model = AdminUserModel(
        uid: 'u1',
        email: 'u1@studydeck.edu',
        role: 'admin',
        isActive: true,
        displayName: 'Admin User',
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['email'], 'u1@studydeck.edu');
      expect(map['role'], 'admin');
      expect(map['isActive'], isTrue);
      expect(map['displayName'], 'Admin User');
      expect(map['createdAt'], isA<Timestamp>());
    });
  });
}
