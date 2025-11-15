import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'models/patient.dart';
import 'models/doctor.dart';
import 'models/caregiver.dart';
import 'models/admin.dart';

class AuthService {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;

  // Admin verification key (stored securely in environment or secure storage)
  static const String ADMIN_VERIFICATION_KEY = String.fromEnvironment(
    'ADMIN_KEY',
    defaultValue: 'CARELINK_ADMIN_2025', // Change this to your secure key
  );

  AuthService() {
    if (kIsWeb) {
      _googleSignIn = GoogleSignIn(
        clientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
        scopes: [
          'email',
          'profile',
          'https://www.googleapis.com/auth/calendar.events',
        ],
      );
    } else {
      _googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
          'https://www.googleapis.com/auth/calendar.events',
        ],
      );
    }
  }

  auth.User? get currentUser => _firebaseAuth.currentUser;
  Stream<auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // ──────────────────────────────────────────────
  // ADMIN VERIFICATION
  // ──────────────────────────────────────────────
  Future<bool> verifyAdminKey(String key) async {
    return key == ADMIN_VERIFICATION_KEY;
  }

  Future<bool> adminExists() async {
    final query = await Admin.collection.limit(1).get();
    return query.docs.isNotEmpty;
  }

  // ──────────────────────────────────────────────
  // GOOGLE SIGN IN
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return {'success': false, 'error': 'Sign in cancelled'};
      final googleAuth = await googleUser.authentication;
      final credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;
      final email = userCredential.user!.email!;
      
      // Check Patient
      final patientDoc = await Patient.collection.doc(uid).get();
      if (patientDoc.exists) {
        final data = patientDoc.data() as Map<String, dynamic>;
        return {'success': true, 'userId': uid, 'userData': data, 'role': 'Patient'};
      }
      
      // Check Caregiver
      final caregiverDoc = await Caregiver.collection.doc(uid).get();
      if (caregiverDoc.exists) {
        final data = caregiverDoc.data() as Map<String, dynamic>;
        if (data['isActive'] == false) {
          await _firebaseAuth.signOut();
          await _googleSignIn.signOut();
          return {'success': false, 'error': 'Account is deactivated'};
        }
        await Caregiver.collection.doc(uid).update({'lastLogin': FieldValue.serverTimestamp()});
        return {'success': true, 'userId': uid, 'userData': data, 'role': 'Caregiver'};
      }
      
      return {
        'success': false,
        'error': 'account_not_found',
        'userId': uid,
        'email': email,
        'displayName': userCredential.user!.displayName,
        'photoUrl': userCredential.user!.photoURL,
      };
    } on auth.FirebaseAuthException catch (e) {
      await _googleSignIn.signOut();
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      await _googleSignIn.signOut();
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // CREATE ACCOUNT AFTER GOOGLE SIGN IN
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> createGoogleAccount({
    required String uid,
    required String email,
    required String role,
    String? displayName,
    String? photoUrl,
    String? phone,
  }) async {
    try {
      if (role == 'Patient') {
        final patient = Patient(id: uid, email: email, phone: phone ?? '', password: '', fullName: displayName);
        final data = patient.toMap()
          ..['email_lower'] = email.toLowerCase()
          ..['signInMethod'] = 'google'
          ..['photoUrl'] = photoUrl;
        await Patient.collection.doc(uid).set(data);
        return {'success': true, 'userId': uid, 'userData': data, 'role': 'Patient'};
      }
      if (role == 'Caregiver') {
        String username = email.split('@')[0].toLowerCase();
        int counter = 1;
        String finalUsername = username;
        while (true) {
          final existing = await Caregiver.collection.where('username', isEqualTo: finalUsername).limit(1).get();
          if (existing.docs.isEmpty) break;
          finalUsername = '$username$counter';
          counter++;
        }
        final caregiver = Caregiver(id: uid, email: email, username: finalUsername, password: '', fullName: displayName);
        final data = caregiver.toMap()
          ..['email_lower'] = email.toLowerCase()
          ..['username'] = finalUsername
          ..['signInMethod'] = 'google'
          ..['photoUrl'] = photoUrl;
        await Caregiver.collection.doc(uid).set(data);
        return {'success': true, 'userId': uid, 'userData': data, 'role': 'Caregiver'};
      }
      return {'success': false, 'error': 'Invalid role'};
    } catch (e) {
      return {'success': false, 'error': 'Failed to create account: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // EMAIL SIGN IN
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> signInWithEmail({required String email, required String password}) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(email: email.trim(), password: password);
      final uid = credential.user!.uid;
      
      // Check Patient
      final patientDoc = await Patient.collection.doc(uid).get();
      if (patientDoc.exists) {
        final data = patientDoc.data() as Map<String, dynamic>;
        return {'success': true, 'userId': uid, 'userData': data, 'role': 'Patient'};
      }
      
      // Check Doctor
      final doctorDoc = await Doctor.collection.doc(uid).get();
      if (doctorDoc.exists) {
        final data = doctorDoc.data() as Map<String, dynamic>;
        if (data['isActive'] == false) {
          await _firebaseAuth.signOut();
          return {'success': false, 'error': 'Account is deactivated'};
        }
        await Doctor.collection.doc(uid).update({'lastLogin': FieldValue.serverTimestamp()});
        return {'success': true, 'userId': uid, 'userData': data, 'role': 'Doctor'};
      }
      
      // Check Caregiver
      final caregiverDoc = await Caregiver.collection.doc(uid).get();
      if (caregiverDoc.exists) {
        final data = caregiverDoc.data() as Map<String, dynamic>;
        if (data['isActive'] == false) {
          await _firebaseAuth.signOut();
          return {'success': false, 'error': 'Account is deactivated'};
        }
        await Caregiver.collection.doc(uid).update({'lastLogin': FieldValue.serverTimestamp()});
        return {'success': true, 'userId': uid, 'userData': data, 'role': 'Caregiver'};
      }
      
      // Check Admin
      final adminDoc = await Admin.collection.doc(uid).get();
      if (adminDoc.exists) {
        final data = adminDoc.data() as Map<String, dynamic>;
        if (data['isActive'] == false) {
          await _firebaseAuth.signOut();
          return {'success': false, 'error': 'Account is deactivated'};
        }
        await Admin.collection.doc(uid).update({'lastLogin': FieldValue.serverTimestamp()});
        return {'success': true, 'userId': uid, 'userData': data, 'role': 'Admin'};
      }
      
      await _firebaseAuth.signOut();
      return {'success': false, 'error': 'User data not found in database'};
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // PATIENT SIGN UP / SIGN IN
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> signUpPatient({required String email, required String phone, required String password, String? fullName}) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final patient = Patient(id: credential.user!.uid, email: email.trim(), phone: phone.trim(), password: password, fullName: fullName);
      final data = patient.toMap()..['email_lower'] = email.trim().toLowerCase();
      await Patient.collection.doc(patient.id).set(data);
      if (fullName != null && fullName.isNotEmpty) await credential.user!.updateDisplayName(fullName);
      return {'success': true, 'userId': patient.id};
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  Future<Map<String, dynamic>> signInPatient({required String email, required String password}) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(email: email.trim(), password: password);
      final doc = await Patient.collection.doc(credential.user!.uid).get();
      if (!doc.exists) {
        await _firebaseAuth.signOut();
        return {'success': false, 'error': 'Patient data not found'};
      }
      final data = doc.data()!;
      return {'success': true, 'userId': credential.user!.uid, 'userData': data, 'role': 'Patient'};
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // DOCTOR SIGN UP / SIGN IN (EMAIL-BASED)
  // ──────────────────────────────────────────────
  
  /// Admin creates doctor account with email, username, and password
  Future<Map<String, dynamic>> createDoctorAccount({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async {
    try {
      final usernameLower = username.trim().toLowerCase();
      
      // Check if username already exists
      final existingUsername = await Doctor.collection
          .where('username', isEqualTo: usernameLower)
          .limit(1)
          .get();
      if (existingUsername.docs.isNotEmpty) {
        return {'success': false, 'error': 'Username already taken'};
      }

      // Check if email already exists
      final existingEmail = await Doctor.collection
          .where('email_lower', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      if (existingEmail.docs.isNotEmpty) {
        return {'success': false, 'error': 'Email already registered'};
      }

      // Create Firebase Auth account
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Generate unique doctorId (you can customize this format)
      final doctorId = 'DOC${DateTime.now().millisecondsSinceEpoch}';

      // Create Doctor document in Firestore
      final doctor = Doctor(
        id: credential.user!.uid,
        doctorId: doctorId,
        username: username.trim(),
        email: email.trim(),
        password: password,
        fullName: fullName,
      );

      final data = doctor.toMap()
        ..['email_lower'] = email.trim().toLowerCase()
        ..['username'] = usernameLower;

      await Doctor.collection.doc(doctor.id).set(data);

      if (fullName != null && fullName.isNotEmpty) {
        await credential.user!.updateDisplayName(fullName);
      }

      return {
        'success': true,
        'userId': doctor.id,
        'doctorId': doctorId,
        'message': 'Doctor account created successfully'
      };
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  /// Doctor signs in with email and password
  Future<Map<String, dynamic>> signInDoctor({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with email and password
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Get doctor document
      final doctorDoc = await Doctor.collection.doc(credential.user!.uid).get();

      if (!doctorDoc.exists) {
        await _firebaseAuth.signOut();
        return {'success': false, 'error': 'Doctor account not found'};
      }

      final data = doctorDoc.data() as Map<String, dynamic>;

      // Check if account is active
      if (data['isActive'] == false) {
        await _firebaseAuth.signOut();
        return {'success': false, 'error': 'Account is deactivated'};
      }

      // Update last login
      await Doctor.collection.doc(credential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp()
      });

      return {
        'success': true,
        'userId': credential.user!.uid,
        'userData': data,
        'role': 'Doctor'
      };
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // CAREGIVER SIGN UP / SIGN IN
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> signUpCaregiver({required String email, required String username, required String password, String? fullName}) async {
    try {
      final usernameLower = username.trim().toLowerCase();
      final existing = await Caregiver.collection.where('username', isEqualTo: usernameLower).limit(1).get();
      if (existing.docs.isNotEmpty) return {'success': false, 'error': 'Username already taken'};
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final caregiver = Caregiver(id: credential.user!.uid, email: email.trim(), username: username.trim(), password: password, fullName: fullName);
      final data = caregiver.toMap()..['email_lower'] = email.trim().toLowerCase()..['username'] = usernameLower;
      await Caregiver.collection.doc(caregiver.id).set(data);
      if (fullName != null && fullName.isNotEmpty) await credential.user!.updateDisplayName(fullName);
      return {'success': true, 'userId': caregiver.id};
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  Future<Map<String, dynamic>> signInCaregiver({required String username, required String password}) async {
    try {
      final query = await Caregiver.collection.where('username', isEqualTo: username.trim().toLowerCase()).limit(1).get();
      if (query.docs.isEmpty) return {'success': false, 'error': 'Invalid username'};
      final data = query.docs.first.data() as Map<String, dynamic>;
      final email = data['email'];
      final credential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      if (data['isActive'] == false) {
        await _firebaseAuth.signOut();
        return {'success': false, 'error': 'Account is deactivated'};
      }
      await Caregiver.collection.doc(credential.user!.uid).update({'lastLogin': FieldValue.serverTimestamp()});
      return {'success': true, 'userId': credential.user!.uid, 'userData': data, 'role': 'Caregiver'};
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // ADMIN SIGN UP / SIGN IN (ONE-TIME ONLY)
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> signUpAdmin({
    required String username,
    required String email,
    required String password,
    required String verificationKey,
    String? fullName,
  }) async {
    try {
      // Check if admin already exists
      if (await adminExists()) {
        return {'success': false, 'error': 'Admin account already exists'};
      }

      // Verify admin key
      if (!await verifyAdminKey(verificationKey)) {
        return {'success': false, 'error': 'Invalid admin verification key'};
      }

      final usernameLower = username.trim().toLowerCase();
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(email: email.trim(), password: password);
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
      return {'success': true, 'userId': admin.id};
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  Future<Map<String, dynamic>> signInAdmin({required String username, required String password}) async {
    try {
      final query = await Admin.collection.where('username', isEqualTo: username.trim().toLowerCase()).limit(1).get();
      if (query.docs.isEmpty) return {'success': false, 'error': 'Invalid username'};
      final data = query.docs.first.data() as Map<String, dynamic>;
      final email = data['email'];
      final credential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      if (data['isActive'] == false) {
        await _firebaseAuth.signOut();
        return {'success': false, 'error': 'Account is deactivated'};
      }
      await Admin.collection.doc(credential.user!.uid).update({'lastLogin': FieldValue.serverTimestamp()});
      return {'success': true, 'userId': credential.user!.uid, 'userData': data, 'role': 'Admin'};
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthErrorMessage(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  // ──────────────────────────────────────────────
  // GOOGLE MEET LINK CREATOR
  // ──────────────────────────────────────────────
  Future<String?> createGoogleMeetLink({
    required DateTime startTime,
    required int durationMinutes,
    required String summary,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        debugPrint('❌ No Firebase user logged in');
        return null;
      }

      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      if (googleUser == null) {
        debugPrint('🔄 Silent sign-in failed, requesting user sign-in...');
        googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          debugPrint('❌ User cancelled Google Sign-In');
          return null;
        }
      }

      debugPrint('✅ Google user signed in: ${googleUser.email}');

      final authHeaders = await googleUser.authHeaders;
      final client = _AuthenticatedClient(http.Client(), authHeaders);
      final calendarApi = calendar.CalendarApi(client);

      final startTimeUtc = startTime.toUtc();
      final endTimeUtc = startTimeUtc.add(Duration(minutes: durationMinutes));
      
      debugPrint('📝 Creating calendar event...');
      debugPrint('   Summary: $summary');
      debugPrint('   Start: $startTimeUtc');
      debugPrint('   End: $endTimeUtc');

      final event = calendar.Event()
        ..summary = summary
        ..start = (calendar.EventDateTime()
          ..dateTime = startTimeUtc
          ..timeZone = 'UTC')
        ..end = (calendar.EventDateTime()
          ..dateTime = endTimeUtc
          ..timeZone = 'UTC')
        ..conferenceData = (calendar.ConferenceData()
          ..createRequest = (calendar.CreateConferenceRequest()
            ..requestId = DateTime.now().millisecondsSinceEpoch.toString()
            ..conferenceSolutionKey = (calendar.ConferenceSolutionKey()..type = 'hangoutsMeet')));

      final createdEvent = await calendarApi.events.insert(
        event,
        'primary',
        conferenceDataVersion: 1,
      );

      if (createdEvent.hangoutLink != null) {
        debugPrint('✅ Google Meet link created: ${createdEvent.hangoutLink}');
        return createdEvent.hangoutLink;
      } else {
        debugPrint('⚠️ Event created but no Meet link returned');
        return null;
      }
    } on calendar.DetailedApiRequestError catch (e) {
      debugPrint('❌ Google Calendar API Error:');
      debugPrint('   Status: ${e.status}');
      debugPrint('   Message: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Meet creation error: $e');
      debugPrint('   Error type: ${e.runtimeType}');
      return null;
    }
  }

  // ──────────────────────────────────────────────
  // COMMON METHODS
  // ──────────────────────────────────────────────
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

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
      case 'weak-password': return 'Password too weak.';
      case 'email-already-in-use': return 'Email already registered.';
      case 'invalid-email': return 'Invalid email format.';
      case 'user-not-found': return 'User not found.';
      case 'wrong-password': return 'Wrong password.';
      default: return 'Auth error: ${e.message}';
    }
  }
}

// Authenticated HTTP client
class _AuthenticatedClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _headers;
  _AuthenticatedClient(this._inner, this._headers);
  
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request..headers.addAll(_headers));
  }
}