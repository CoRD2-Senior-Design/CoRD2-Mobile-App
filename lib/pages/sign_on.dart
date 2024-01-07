import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignOnPage extends StatefulWidget {
  const SignOnPage({super.key});

  @override
  State<SignOnPage> createState() => _SignOnPageState();
}

class _SignOnPageState extends State<SignOnPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false;
  bool _login = true;
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();
  TextEditingController displayNameController = TextEditingController();
  String _error = "";

  final int darkBlue = 0xff5f79BA;
  final int lightBlue = 0xffD0DCF4;
  final int blurple = 0xff20297A;
  final TextStyle whiteText = const TextStyle(color: Colors.white);

  @override
  void initState() {
    super.initState();
    // Update the stored user
    _googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) => handleGoogleUser(account));

    // Attempt to log in a previously authorized user
    _googleSignIn.signInSilently();
  }

  // Handle the Google Authorization Flow
  void handleGoogleUser(GoogleSignInAccount? account) async {
    // In mobile, being authenticated means being authorized...
    bool isAuthorized = account != null;
    if (isAuthorized) {
      DocumentSnapshot doc = await users.doc(account?.id).get();
      // Found a user account
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      } else {
        // Need to create a new account
        users
            .doc(account.id)
            .set({
              'name': account.displayName,
              'email': account.email,
              'events': [],
              'chats': []
            })
            .then((value) => print("Successfully added user!"))
            .catchError((err) => print("Failed to add user $err"));
      }
    }
    setState(() {
      _currentUser = account;
      _isAuthorized = isAuthorized;
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Future<void> signOut() => _googleSignIn.disconnect();

  void handleRegister() async {
    setState(() {
      _error = "";
    });
    if (passController.text != confirmPassController.text) {
      setState(() {
        _error = "Passwords don't match";
      });
    }
    if (passController.text.isEmpty || displayNameController.text.isEmpty ||
        emailController.text.isEmpty || confirmPassController.text.isEmpty) {
      setState(() {
        _error = "Please fill out all fields";
      });
    }
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text, password: passController.text
      );
      users
          .doc(userCredential.user?.uid)
          .set({
        'name': displayNameController.text,
        'email': userCredential.user?.email,
        'events': [],
        'chats': []
      })
        .then((value) => print("Successfully added user!"))
        .catchError((err) => print("Failed to add user $err"));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        setState(() {
          _error = "Password is too weak";
        });
      } else if (e.code == 'email-already-in-use') {
        setState(() {
          _error = "This email is already in use";
        });
      }
    } catch (e) {
      print(e);
    }
  }

  // Creates a button on the login screen
  FractionallySizedBox createButton(String text, onPressed) {
    return FractionallySizedBox(
      widthFactor: 0.8,
      child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
              backgroundColor: Color(blurple),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)))),
          child: Text(text, style: whiteText)),
    );
  }

  void switchPage() {
    emailController.clear();
    displayNameController.clear();
    passController.clear();
    confirmPassController.clear();
    setState(() {
      _login = !_login;
      _error = "";
    });
  }

  List<Widget> registerPage() {
    return [
      Container(
        margin: const EdgeInsets.symmetric(vertical: 15.0),
        child: Text("Create Account",
            style: TextStyle(color: Color(blurple), fontSize: 25.0)),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: TextField(
          controller: emailController,
          style: const TextStyle(color: Colors.white, height: 1.0),
          decoration: InputDecoration(
              isDense: true,
              hintStyle: const TextStyle(color: Colors.white),
              fillColor: Color(darkBlue),
              filled: true,
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
              hintText: "Email"),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: TextField(
          controller: displayNameController,
          style: const TextStyle(color: Colors.white, height: 0.6),
          decoration: InputDecoration(
            hintStyle: const TextStyle(color: Colors.white),
            fillColor: Color(darkBlue),
            filled: true,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
            hintText: "Display Name"),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: TextField(
          controller: passController,
          obscureText: true,
          style: const TextStyle(color: Colors.white, height: 1.0),
          decoration: InputDecoration(
            isDense: true,
            hintStyle: const TextStyle(color: Colors.white),
            fillColor: Color(darkBlue),
            filled: true,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
            hintText: "Password",
          ),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: TextField(
          controller: confirmPassController,
          obscureText: true,
          style: const TextStyle(color: Colors.white, height: 1.0),
          decoration: InputDecoration(
            isDense: true,
            hintStyle: const TextStyle(color: Colors.white),
            fillColor: Color(darkBlue),
            filled: true,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
            hintText: "Confirm Password",
          ),
        ),
      ),
      Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          child: createButton("Register", () => handleRegister())),
      Text(_error, style: const TextStyle(color: Colors.red)),
      const Text("Already have an account?"),
      GestureDetector(
          child: const Text("Login",
              style: TextStyle(decoration: TextDecoration.underline)),
          onTap: () {
            switchPage();
          }),
    ];
  }

  List<Widget> loginPage() {
    return [
      Container(
        margin: const EdgeInsets.symmetric(vertical: 15.0),
        child: Text("Login", style: TextStyle(color: Color(blurple), fontSize: 25.0)),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: TextField(
          controller: emailController,
          style: const TextStyle(color: Colors.white, height: 1.0),
          decoration: InputDecoration(
            isDense: true,
            hintStyle: const TextStyle(color: Colors.white),
            fillColor: Color(darkBlue),
            filled: true,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
            hintText: "Email"),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: TextField(
          controller: passController,
          obscureText: true,
          style: const TextStyle(color: Colors.white, height: 1.0),
          decoration: InputDecoration(
            isDense: true,
            hintStyle: const TextStyle(color: Colors.white),
            fillColor: Color(darkBlue),
            filled: true,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
            hintText: "Password",
          ),
        ),
      ),
      GestureDetector(
        child: const Text("Forgot Password?",
            style: TextStyle(decoration: TextDecoration.underline)),
        onTap: () {
          //TODO: Implement forgot password
        }
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: createButton("Login", () => ()),
      ),
      GestureDetector(
        child: const Text("Create a new account",
            style: TextStyle(decoration: TextDecoration.underline)),
        onTap: () {
          switchPage();
        }
      ),
      Container(
        margin: EdgeInsets.symmetric(vertical: 10.0),
        child: SignInButton(Buttons.Google, onPressed: signInWithGoogle),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          color: Color(lightBlue),
          child: Center(
            child: SingleChildScrollView(
              child: Card(
                margin: const EdgeInsets.fromLTRB(50, 75, 50, 75),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: _login ? loginPage() : registerPage()),
                )
              ),
            ),
          ),
        ));
  }
}
