import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:infinity_messenger/core/constants.dart';
import 'package:infinity_messenger/widgets/base_widget.dart';
import 'package:infinity_messenger/widgets/custom_button.dart';
import 'package:infinity_messenger/widgets/custom_text_filed.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class ReceiveCodeScreen extends StatefulWidget {
  const ReceiveCodeScreen({
    super.key,
    required this.verificationId,
  });

  final String verificationId;

  @override
  State<ReceiveCodeScreen> createState() => _ReceiveCodeScreenState();
}

class _ReceiveCodeScreenState extends State<ReceiveCodeScreen> {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  late CollectionReference usersRef;

  TextEditingController codeController = TextEditingController();
  bool continueButtonActive = false;

  bool loading = false;

  late Size size;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    usersRef = fireStore.collection('Users');
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return ModalProgressHUD(
      inAsyncCall: loading,
      color: Theme.of(context).colorScheme.onBackground,
      opacity: 0.3,
      progressIndicator: showLoading(context),
      child: BaseWidget(
        child: SizedBox(
          height: size.height,
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
                          if (codeController.text.length >= 6) {
                            continueButtonActive = true;
                          } else {
                            continueButtonActive = false;
                          }
                        },
                        controller: codeController,
                        hint: 'Code ( XXXXXX )',
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
                              continueButtonActive ? (confirmCode(),) : null;
                            },
                            text: 'Continue',
                            valueForChange: continueButtonActive,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          RichText(
                            text: TextSpan(
                              text: 'Resend Code?',
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
      ),
    );
  }

  confirmCode() async {
    setState(() {
      loading = true;
    });
    String smsCode = codeController.text;

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId, smsCode: smsCode);

    await auth.signInWithCredential(credential);

    QuerySnapshot searchUser = await usersRef
        .where('id', isEqualTo: auth.currentUser!.uid)
        .limit(1)
        .get();

    if (searchUser.docs.isEmpty) {
      Map<String, dynamic> user = {};
      user['id'] = auth.currentUser!.uid;
      user['fullName'] = '';
      user['bio'] = '';
      user['username'] = '';
      user['phoneNumber'] = auth.currentUser!.phoneNumber;
      user['email'] = '';
      user['imageAddress'] = '';
      user['lastSeen'] = auth.currentUser!.metadata.lastSignInTime;
      user['isActive'] = true;
      user['darkMode'] = true;
      user['showPublicChat'] = true;
      await usersRef.doc(auth.currentUser!.uid).set(user);
      navigate('CompleteProfileScreen');
    } else {
      await usersRef
          .doc(auth.currentUser!.uid)
          .update({'lastSeen': DateTime.now(), 'isActive': true});
      navigate('HomeScreen');
    }
  }

  void navigate(String page) {
    setState(() {
      loading = false;
    });
    Navigator.pop(context);
    kNavigator(context, page);
  }
}
