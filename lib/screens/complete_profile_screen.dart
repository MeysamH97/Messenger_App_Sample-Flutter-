import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:infinity_messenger/core/constants.dart';
import 'package:infinity_messenger/widgets/base_widget.dart';
import 'package:infinity_messenger/widgets/custom_button.dart';
import 'package:infinity_messenger/widgets/custom_text_filed.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {

  FirebaseAuth auth = FirebaseAuth.instance;
  CollectionReference usersRef = FirebaseFirestore.instance.collection('Users');
  CollectionReference userNamesRef = FirebaseFirestore.instance.collection('Usernames');

  TextEditingController fullNameController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  bool continueButtonActive = false;

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
                          if (
                          fullNameController.text.isNotEmpty &&
                          emailController.text.isNotEmpty &&
                          userNameController.text.isNotEmpty
                          ) {
                            continueButtonActive = true;
                          } else {
                            continueButtonActive = false;
                          }
                        },
                        controller: fullNameController,
                        hint: 'Full name',
                      ),
                      const SizedBox(height: 10,),
                      CustomTextField(
                        onChanged: (value) {
                          setState(() {});
                          if (
                          fullNameController.text.isNotEmpty &&
                              emailController.text.isNotEmpty &&
                              userNameController.text.isNotEmpty
                          ) {
                            continueButtonActive = true;
                          } else {
                            continueButtonActive = false;
                          }
                        },
                        controller: userNameController,
                        hint: 'Username',
                      ),
                      const SizedBox(height: 10,),
                      CustomTextField(
                        onChanged: (value) {
                          setState(() {});
                          if (
                          fullNameController.text.isNotEmpty &&
                              emailController.text.isNotEmpty &&
                              userNameController.text.isNotEmpty
                          ) {
                            continueButtonActive = true;
                          } else {
                            continueButtonActive = false;
                          }
                        },
                        controller: emailController,
                        hint: 'Email',
                      ),
                      const SizedBox(height: 10,),
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
                              continueButtonActive ? {
                              saveData(),
                            }: null;
                            },
                            text: 'Continue',
                            valueForChange: continueButtonActive,
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

  void saveData() async {
    setState(() {
      loading = true;
    });
    auth.currentUser!.updateDisplayName(fullNameController.text);
    usersRef.doc(auth.currentUser!.uid).update({'fullName': fullNameController.text});
    usersRef.doc(auth.currentUser!.uid).update({'email': emailController.text});
    bool uniqueUsername = !(await isUsernameUnique(userNameController.text));
    if(uniqueUsername){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[600]!.withOpacity(0.5),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          duration: const Duration(seconds: 3),
          content: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color:Colors.transparent,
            ),
            child:  Text(
              'This Username is exist. Please try another one',
              style: myTextStyle(context, 16,'bold',1),
            ),
          ),
        ),
      );
    }else{
      changeUsername();
    }
    navigate('HomeScreen');
  }

  changeUsername(){
    usersRef.doc(auth.currentUser!.uid).update({'username': userNameController.text});
    if(userNameController.text.isNotEmpty){
      userNamesRef.add(userNameController.text);
    }
  }

  Future<bool> isUsernameUnique(String username) async {
    QuerySnapshot querySnapshot = await userNamesRef.where(
        FieldPath.documentId, isEqualTo: username).get();

    return querySnapshot.docs.isEmpty;
  }

  void navigate(String page) {
    setState(() {
      loading = false;
    });
    kNavigator(context, page);
  }
}


