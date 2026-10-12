import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _googleInitialized = false;

  Future<void> _initializeGoogleSignIn() async {
    if (_googleInitialized) return;

    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  // Current logged-in user
  User? get currentUser => _auth.currentUser;

  // Listen to login/logout changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Create a new account
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Sign in using email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Sign in using Google
  Future<UserCredential> signInWithGoogle() async {
    await _initializeGoogleSignIn();
    // Initialize Google Sign In once
    await GoogleSignIn.instance.initialize();

    // Open the Google account selection flow
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance
        .authenticate();

    // Get the Google ID token
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    // Create Firebase credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase
    return await _auth.signInWithCredential(credential);
  }

  // Sign out
  Future<void> signOut() async {
    await _initializeGoogleSignIn();
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
