import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:infinity_messenger/core/constants.dart';
import 'package:infinity_messenger/screens/receive_code.dart';
import 'package:infinity_messenger/widgets/base_widget.dart';
import 'package:infinity_messenger/widgets/custom_button.dart';
import 'package:infinity_messenger/widgets/custom_text_filed.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  FirebaseAuth auth = FirebaseAuth.instance;
  TextEditingController usernameController = TextEditingController();
  bool signInButtonActive = false;

  bool loading = false;

  late Size size;

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return ModalProgressHUD(
      inAsyncCall: loading,
      color: Theme.of(context).colorScheme.onBackground,
      opacity: 0.3,
      progressIndicator: showLoading(context),
      child: BaseWidget(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: size.height * 0.1,
            ),
            Image.asset(
              'assets/images/Logo.png',
              width: 400,
              height: 150,
            ),
            const SizedBox(
              height: 100,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomTextField(
                      onChanged: (value) {
                        setState(() {});
                        if (usernameController.text.length >= 12 ){
                          signInButtonActive = true;
                        } else {
                          signInButtonActive = false;
                        }
                      },
                      controller: usernameController,
                      hint: 'Username, Email or Phone Number',
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.3),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        CustomButton(
                          onTap: () {
                            signInButtonActive ? signIn() : null;
                          },
                          text: 'Sign In',
                          valueForChange: signInButtonActive,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        RichText(
                          text: TextSpan(
                            text: 'Forget your password?',
                            style: myTextStyle(context, 14, 'bold', 1),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }

  signIn() async {
    setState(() {
      loading = true;
    });
    await auth.verifyPhoneNumber(
      phoneNumber: usernameController.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print('Error');
        print(e.code);
        if (e.code == 'invalid-phone-number') {
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          loading = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiveCodeScreen(
              verificationId: verificationId,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }
}
