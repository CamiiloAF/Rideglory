// ignore_for_file: use_build_context_synchronously

import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rideglory/shared/extensions/widget_extensions.dart';

import '../../../../shared/routes/app_router.dart';

@RoutePage()
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(appStrings.loginWelcome),
              const SizedBox(height: 34),
              MaterialButton(
                key: widget.key,
                height: 36.0,
                elevation: 2,
                padding: const EdgeInsets.all(0),
                color: const Color(0xFFFFFFFF),
                onPressed: () async {
                  final userCredentials = await signInWithGoogle();
                  if (userCredentials?.user != null) {
                    if (userCredentials?.additionalUserInfo?.isNewUser ??
                        false) {
                      context.router.replace(const SignUpRoute());
                    } else {
                      context.router.replace(const HomeRoute());
                    }
                  }
                },
                splashColor: Colors.white30,
                highlightColor: Colors.white30,
                shape: ButtonTheme.of(context).shape,
                child: Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 0.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: const Image(
                            image: AssetImage(
                              'assets/logos/google_light.png',
                            ),
                            height: 36.0,
                          ),
                        ),
                      ),
                      Text(
                        appStrings.signInWithGoogle,
                        style: const TextStyle(
                          color: Color.fromRGBO(0, 0, 0, 0.54),
                          fontSize: 14,
                          backgroundColor: Color.fromRGBO(0, 0, 0, 0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    UserCredential? userCredential;

    final GoogleSignIn googleSignIn = GoogleSignIn();

    final googleSignInAccount = await googleSignIn.signIn();

    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      try {
        userCredential = await auth.signInWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          _showSnackBar(
              'The account already exists with a different credential');
        } else if (e.code == 'invalid-credential') {
          _showSnackBar(
              'Error occurred while accessing credentials. Try again.');
        }
      } catch (e) {
        _showSnackBar('Error occurred using Google Sign In. Try again.');
      }

      return userCredential;
    }
    return null;
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
