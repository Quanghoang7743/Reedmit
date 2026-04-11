import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<void> register({
    required String username,
    required String password,
    required String phoneNumber,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final normalizedPhone = phoneNumber.trim();

    if (normalizedUsername.isEmpty) {
      throw const FormatException('Vui lòng nhập username.');
    }

    final duplicate = await _users
        .where('usernameLower', isEqualTo: normalizedUsername)
        .limit(1)
        .get();

    if (duplicate.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'username-already-in-use',
        message: 'Username đã tồn tại, vui lòng chọn tên khác.',
      );
    }

    final safe = normalizedUsername.replaceAll(RegExp(r'[^a-z0-9._-]'), '');
    if (safe.isEmpty) {
      throw const FormatException('Username chỉ nên gồm chữ và số.');
    }

    final email =
        '${safe}_${DateTime.now().millisecondsSinceEpoch}@reedemit.app';
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    await _users.doc(uid).set({
      'uid': uid,
      'username': username.trim(),
      'usernameLower': normalizedUsername,
      'phoneNumber': normalizedPhone,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> login({
    required String username,
    required String password,
    required String phoneNumber,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final normalizedPhone = phoneNumber.trim();

    final query = await _users
        .where('usernameLower', isEqualTo: normalizedUsername)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Không tìm thấy tài khoản với username này.',
      );
    }

    final userData = query.docs.first.data();
    final phone = (userData['phoneNumber'] ?? '') as String;
    final email = (userData['email'] ?? '') as String;

    if (phone != normalizedPhone) {
      throw FirebaseAuthException(
        code: 'phone-mismatch',
        message: 'Số điện thoại không khớp với tài khoản.',
      );
    }

    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();
}
