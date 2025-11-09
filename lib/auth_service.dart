import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/patient.dart';
import 'models/doctor.dart';
import 'models/caregiver.dart';
import 'models/admin.dart';

class AuthService {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  auth.User? get currentUser => _firebaseAuth.currentUser;
  Stream<auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // ──────────────────────────────────────────────
  // UNIFIED EMAIL SIGN IN (for Patient & Caregiver)
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Firebase Auth
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      // Check if user is a Patient
      final patientDoc = await Patient.collection.doc(uid).get();
      if (patientDoc.exists) {
        final data = patientDoc.data() as Map<String, dynamic>;
        return {
          'success': true,
          'userId': uid,
          'userData': data,
          'role': 'Patient',
          'message': 'Patient login successful'
        };
      }

      // Check if user is a Caregiver
      final caregiverDoc = await Caregiver.collection.doc(uid).get();
      if (caregiverDoc.exists) {
        final data = caregiverDoc.data() as Map<String, dynamic>;
        
        if (data['isActive'] == false) {
          await _firebaseAuth.signOut();
          return {'success': false, 'error': 'Account is deactivated'};
        }

        await Caregiver.collection.doc(uid)
            .update({'lastLogin': FieldValue.serverTimestamp()});

        return {
          'success': true,
          'userId': uid,
          'userData': data,
          'role': 'Caregiver',
          'message': 'Caregiver login successful'
        };
      }

      // If user exists in Firebase Auth but not in our collections
      await _firebaseAuth.signOut();
      return {'success': false, 'error': 'User data not found in database'};

    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // PATIENT SIGN UP
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> signUpPatient({
    required String email,
    required String phone,
    required String password,
    String? fullName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final patient = Patient(
        id: credential.user!.uid,
        email: email.trim(),
        phone: phone.trim(),
        password: password,
        fullName: fullName,
      );

      final data = patient.toMap()..['email_lower'] = email.trim().toLowerCase();
      await Patient.collection.doc(patient.id).set(data);

      if (fullName != null && fullName.isNotEmpty) {
        await credential.user!.updateDisplayName(fullName);
      }

      return {'success': true, 'userId': patient.id, 'message': 'Patient account created successfully'};
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  Future<Map<String, dynamic>> signInPatient({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final doc = await Patient.collection.doc(credential.user!.uid).get();
      if (!doc.exists) {
        await _firebaseAuth.signOut();
        return {'success': false, 'error': 'Patient data not found'};
      }

      final data = doc.data()!;
      return {'success': true, 'userId': credential.user!.uid, 'userData': data, 'role': 'Patient', 'message': 'Login successful'};
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // DOCTOR SIGN UP
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> signUpDoctor({
    required String doctorId,
    required String username,
    required String password,
    String? fullName,
  }) async {
    try {
      final doctorIdLower = doctorId.trim().toLowerCase();
      final usernameLower = username.trim().toLowerCase();

      final existingDoctor = await Doctor.collection
          .where('doctorId', isEqualTo: doctorIdLower)
          .limit(1)
          .get();
      if (existingDoctor.docs.isNotEmpty) {
        return {'success': false, 'error': 'Doctor ID already exists'};
      }

      final existingUsername = await Doctor.collection
          .where('username', isEqualTo: usernameLower)
          .limit(1)
          .get();
      if (existingUsername.docs.isNotEmpty) {
        return {'success': false, 'error': 'Username already taken'};
      }

      final tempEmail = '$doctorIdLower@carelink.temp';
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: tempEmail,
        password: password,
      );

      final doctor = Doctor(
        id: credential.user!.uid,
        doctorId: doctorId.trim(),
        username: username.trim(),
        password: password,
        fullName: fullName,
      );

      final data = doctor.toMap()
        ..['doctorId'] = doctorIdLower
        ..['username'] = usernameLower;

      await Doctor.collection.doc(doctor.id).set(data);

      if (fullName != null && fullName.isNotEmpty) {
        await credential.user!.updateDisplayName(fullName);
      }

      return {'success': true, 'userId': doctor.id, 'message': 'Doctor account created successfully'};
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  Future<Map<String, dynamic>> signInDoctor({
    required String identifier,
    required String password,
  }) async {
    try {
      QuerySnapshot query = await Doctor.collection
          .where('doctorId', isEqualTo: identifier.trim().toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        query = await Doctor.collection
            .where('username', isEqualTo: identifier.trim().toLowerCase())
            .limit(1)
            .get();
      }

      if (query.docs.isEmpty) {
        return {'success': false, 'error': 'Invalid doctor ID or username'};
      }

      final data = query.docs.first.data() as Map<String, dynamic>;
      final tempEmail = '${data['doctorId']}@carelink.temp';

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: tempEmail,
        password: password,
      );

      if (data['isActive'] == false) {
        await _firebaseAuth.signOut();
        return {'success': false, 'error': 'Account is deactivated'};
      }

      await Doctor.collection.doc(credential.user!.uid)
          .update({'lastLogin': FieldValue.serverTimestamp()});

      return {'success': true, 'userId': credential.user!.uid, 'userData': data, 'role': 'Doctor', 'message': 'Login successful'};
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // CAREGIVER SIGN UP
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> signUpCaregiver({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async {
    try {
      final usernameLower = username.trim().toLowerCase();
      final existing = await Caregiver.collection
          .where('username', isEqualTo: usernameLower)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return {'success': false, 'error': 'Username already taken'};
      }

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final caregiver = Caregiver(
        id: credential.user!.uid,
        email: email.trim(),
        username: username.trim(),
        password: password,
        fullName: fullName,
      );

      final data = caregiver.toMap()
        ..['email_lower'] = email.trim().toLowerCase()
        ..['username'] = usernameLower;

      await Caregiver.collection.doc(caregiver.id).set(data);

      if (fullName != null && fullName.isNotEmpty) {
        await credential.user!.updateDisplayName(fullName);
      }

      return {'success': true, 'userId': caregiver.id, 'message': 'Caregiver account created successfully'};
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  Future<Map<String, dynamic>> signInCaregiver({
    required String username,
    required String password,
  }) async {
    try {
      final query = await Caregiver.collection
          .where('username', isEqualTo: username.trim().toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return {'success': false, 'error': 'Invalid username'};
      }

      final data = query.docs.first.data() as Map<String, dynamic>;
      final email = data['email'];

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (data['isActive'] == false) {
        await _firebaseAuth.signOut();
        return {'success': false, 'error': 'Account is deactivated'};
      }

      await Caregiver.collection.doc(credential.user!.uid)
          .update({'lastLogin': FieldValue.serverTimestamp()});

      return {'success': true, 'userId': credential.user!.uid, 'userData': data, 'role': 'Caregiver', 'message': 'Login successful'};
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // ADMIN SIGN UP / SIGN IN
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> signUpAdmin({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final usernameLower = username.trim().toLowerCase();
      final existing = await Admin.collection
          .where('username', isEqualTo: usernameLower)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return {'success': false, 'error': 'Username already taken'};
      }

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final admin = Admin(
        id: credential.user!.uid,
        username: username.trim(),
        email: email.trim(),
        password: password,
        fullName: fullName,
      );

      final data = admin.toMap()
        ..['email_lower'] = email.trim().toLowerCase()
        ..['username'] = usernameLower;

      await Admin.collection.doc(admin.id).set(data);

      if (fullName != null && fullName.isNotEmpty) {
        await credential.user!.updateDisplayName(fullName);
      }

      return {'success': true, 'userId': admin.id, 'message': 'Admin account created successfully'};
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> signInAdmin({
    required String username,
    required String password,
  }) async {
    try {
      final query = await Admin.collection
          .where('username', isEqualTo: username.trim().toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return {'success': false, 'error': 'Invalid username'};
      }

      final data = query.docs.first.data() as Map<String, dynamic>;
      final email = data['email'];

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (data['isActive'] == false) {
        await _firebaseAuth.signOut();
        return {'success': false, 'error': 'Account is deactivated'};
      }

      await Admin.collection.doc(credential.user!.uid)
          .update({'lastLogin': FieldValue.serverTimestamp()});

      return {'success': true, 'userId': credential.user!.uid, 'userData': data, 'role': 'Admin', 'message': 'Login successful'};
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // COMMON METHODS
  // ──────────────────────────────────────────────
  Future<void> signOut() async => await _firebaseAuth.signOut();

  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return {'success': true, 'message': 'Password reset email sent'};
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    }
  }

  String _getAuthErrorMessage(auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password too weak.';
      case 'email-already-in-use':
        return 'Email already registered.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-not-found':
        return 'User not found.';
      case 'wrong-password':
        return 'Wrong password.';
      default:
        return 'Auth error: ${e.message}';
    }
  }
}