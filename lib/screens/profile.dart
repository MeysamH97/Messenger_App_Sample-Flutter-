import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:infinity_messenger/core/constants.dart';
import 'package:infinity_messenger/models/user_model.dart';
import 'package:infinity_messenger/screens/contact_profile.dart';
import 'package:infinity_messenger/screens/sign_in.dart';
import 'package:infinity_messenger/widgets/base_widget.dart';
import 'package:infinity_messenger/widgets/custom_button.dart';
import 'package:infinity_messenger/widgets/custom_text_filed.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  FirebaseAuth auth = FirebaseAuth.instance;
  final storage = FirebaseStorage.instance;
  CollectionReference usersRef = FirebaseFirestore.instance.collection('Users');
  CollectionReference userNamesRef = FirebaseFirestore.instance.collection('Usernames');

  UserModel? me;

  bool loading = false;
  bool isEditingBio = false;


  File imagePicked = File('-1');
  TextEditingController editUsernameController = TextEditingController();
  TextEditingController editNameController = TextEditingController();
  TextEditingController editEmailController = TextEditingController();
  TextEditingController editPhoneNumberController = TextEditingController();
  TextEditingController editBioController = TextEditingController();

  TextEditingController codeController = TextEditingController();
  String myVerificationId = '-1';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: loading,
      color: onThemeColor(context),
      opacity: 0.3,
      progressIndicator: showLoading(context),
      child: StreamBuilder(
          stream: usersRef
              .doc(auth.currentUser!.uid)
              .snapshots(),
          builder: (context,
              AsyncSnapshot<
                  DocumentSnapshot>
              userSnapshot) {
            if (!userSnapshot.hasData) {
              return const SizedBox();
            }
            UserModel user =
            UserModel.getFromDocument(
                userSnapshot.data!);
            me = user;
          return BaseWidget(
            appBar: AppBar(
              title: Text(
                'My Account',
                style: myTextStyle(context, 20, 'bold', 1),
              ),
            ),
            child:SizedBox(
              height: MediaQuery.of(context).size.height,
              child: SingleChildScrollView(
                child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      border: Border.all(width: 2,
                                          color: user.isActive ? Colors.blue : Colors.red,),
                                      borderRadius: BorderRadius.circular(80),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(80),
                                      onTap: () {
                                        user.imageAddress != ''
                                            ? Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProfileImage(
                                              imageAddress: user.imageAddress!,
                                            ),
                                          ),
                                        )
                                            : null;
                                      },
                                      child: Hero(
                                        tag: 'profile',
                                        child: CircleAvatar(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .background,
                                          radius: 80,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(80),
                                            child: imagePicked.path == '-1'
                                                ? user.imageAddress != null
                                                    ? FadeInImage(
                                                        placeholder: const AssetImage(
                                                            'assets/images/defaultUser.jpg'),
                                                        image: NetworkImage(
                                                          user.imageAddress!,
                                                        ),
                                                        width: 160,
                                                        height: 160,
                                                        fit: BoxFit.cover)
                                                    : Image.asset(
                                                        'assets/images/defaultUser.jpg',
                                                        fit: BoxFit.cover,
                                                      )
                                                : Image.file(
                                                    imagePicked,
                                                    width: 160,
                                                    height: 160,
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: onThemeColor(context)
                                            .withOpacity(0.75),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          Iconsax.camera,
                                          color: themeColor(context),
                                        ),
                                        onPressed: () {
                                          selectImageOnTap();
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Expanded(
                                child:
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.fullName ?? '',
                                        style: myTextStyle(context, 22, 'bold', 1),
                                      ),
                                      const SizedBox(height: 10,),
                                      TextButton.icon(
                                        label: Text(
                                          'Edit Profile',
                                          style: myTextStyle(context, 14, 'bold', 0.5),
                                        ),
                                        icon: const Icon(Iconsax.edit),
                                        onPressed: () {
                                          editProfileOnTap(user);
                                        },
                                      ),
                                    ],
                                  ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Icon(Iconsax.grammerly),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Bio',
                                style: myTextStyle(context, 14, 'bold', 0.5),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              const Expanded(child: Divider()),
                              isEditingBio?
                              IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () {
                                  setState(() {
                                    isEditingBio = false;
                                    editBio();
                                  });
                                },
                              ):IconButton(
                                icon: const Icon(Iconsax.edit),
                                onPressed: () {
                                  setState(() {
                                    editBioController.text = user.bio ??'';
                                    isEditingBio = true;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          isEditingBio? Row(children: [
                            Expanded(child: CustomTextField(controller: editBioController, hint:'Your Bio')),
                          ],):Row(
                            children: [
                              const SizedBox(
                                width: 30,
                              ),
                              Text(
                                user.bio ?? '\n\n',
                                style: myTextStyle(context, 14, 'bold', 0.75),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              const Icon(
                                Iconsax.user,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Profile',
                                style: myTextStyle(context, 14, 'bold', 0.5),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.red[300],
                              radius: 30,
                              child: const Icon(
                                Iconsax.personalcard,
                                size: 35,
                                color: Colors.black,
                              ),
                            ),
                            title: Text(
                              'Username',
                              style: myTextStyle(context, 16, 'bold', 1),
                            ),
                            subtitle: Text(
                              user.username != null ? '@ ${user.username}' : '',
                              style: myTextStyle(context, 12, 'bold', 0.75),
                            ),
                          ),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[300],
                              radius: 30,
                              child: const Icon(
                                Icons.mail_outline_sharp,
                                size: 35,
                                color: Colors.black,
                              ),
                            ),
                            title: Text(
                              'Email',
                              style: myTextStyle(context, 16, 'bold', 1),
                            ),
                            subtitle: Text(
                              user.email ?? '',
                              style: myTextStyle(context, 12, 'bold', 0.75),
                            ),
                          ),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[300],
                              radius: 30,
                              child: const Icon(
                                Iconsax.call,
                                size: 35,
                                color: Colors.black,
                              ),
                            ),
                            title: Text(
                              'Phone Number',
                              style: myTextStyle(context, 16, 'bold', 1),
                            ),
                            subtitle: Text(
                              user.phoneNumber,
                              style: myTextStyle(context, 12, 'bold', 0.75),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Icon(
                                Iconsax.setting,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Settings',
                                style: myTextStyle(context, 14, 'bold', 0.5),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor:Colors.blue.withOpacity(0.25),
                              radius: 30,
                              child: Icon(
                               user.darkMode? Iconsax.moon5 : Iconsax.sun_15,
                                size: 35,
                                color: Colors.amber,
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Dark Mode',
                                  style: myTextStyle(context, 16, 'bold', 1),
                                ),
                                const Spacer(),
                                Switch(value: user.darkMode, onChanged: (value) async{
                                  setState(() {
                                    user.darkMode = !user.darkMode;
                                  });
                                  await usersRef.doc(auth.currentUser!.uid).update(
                                      {'darkMode': user.darkMode});
                                },)
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor:user.showPublicChat ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                              radius: 30,
                              child: const Icon(Icons.group,
                                size: 35,
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Show Public Chat Room',
                                  style: myTextStyle(context, 16, 'bold', 1),
                                ),
                                const Spacer(),
                                Switch(value: user.showPublicChat, onChanged: (value) async{
                                  setState(() {
                                    user.showPublicChat = !user.showPublicChat;
                                  });
                                  await usersRef.doc(auth.currentUser!.uid).update(
                                      {'showPublicChat': user.showPublicChat});
                                },)
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          ListTile(
                            onTap: () {
                              logout();
                            },
                            leading: CircleAvatar(
                              backgroundColor: Colors.red[100],
                              radius: 30,
                              child: const Icon(
                                Iconsax.logout_1,
                                size: 35,
                                color: Colors.red,
                              ),
                            ),
                            title: Text(
                              'Log Out',
                              style: TextStyle(
                                  fontFamily: myFontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        }
      ),
    );
  }

  editBio(){
    setState(() {
      me!.bio = editBioController.text;
    });
    usersRef
        .doc(auth.currentUser!.uid)
        .update({'bio': me!.bio});
  }

  editProfileOnTap(UserModel me) {
    editNameController.text = me.fullName ?? '';
    editUsernameController.text = me.username ?? '';
    editEmailController.text = me.email ?? '';
    editPhoneNumberController.text = me.phoneNumber;
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            themeColor(context).withOpacity(0.90),
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Change Profile information',
              style: myTextStyle(context, 16, 'bold', 1),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.close,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: onThemeColor(context),
                  radius: 30,
                  child: Icon(
                    Iconsax.user,
                    size: 35,
                    color: themeColor(context),
                  ),
                ),
                title: CustomTextField(
                  controller: editNameController,
                  hint: 'Name',
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red[300],
                  radius: 30,
                  child: const Icon(
                    Iconsax.personalcard,
                    size: 35,
                    color: Colors.black,
                  ),
                ),
                title: CustomTextField(
                  maxLines: 1,
                  controller: editUsernameController,
                  hint: 'Username',
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[300],
                  radius: 30,
                  child: const Icon(
                    Icons.mail_outline,
                    size: 35,
                    color: Colors.black,
                  ),
                ),
                title: CustomTextField(
                  maxLines: 1,
                  controller: editEmailController,
                  hint: 'Email',
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[300],
                  radius: 30,
                  child: const Icon(
                    Iconsax.call,
                    size: 35,
                    color: Colors.black,
                  ),
                ),
                title: CustomTextField(
                  maxLines: 1,
                  controller: editPhoneNumberController,
                  hint: 'Phone Number',
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const Divider(),
              const SizedBox(
                height: 5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    width: MediaQuery.sizeOf(context).width / 2 - 70,
                    buttonColor: Colors.red[400],
                    fontSize: 14,
                    text: 'Cancel',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  CustomButton(
                    width: MediaQuery.sizeOf(context).width / 2 - 70,
                    buttonColor: Colors.green,
                    fontSize: 14,
                    text: 'Save Changes',
                    onTap: () {
                      editProfile();
                    },
                  ),
                ],
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

  void editProfile() async {
    setState(() {
      me!.fullName = editNameController.text;
      me!.email = editEmailController.text;
    });
   bool uniqueUsername = !(await isUsernameUnique(editUsernameController.text));
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

    if (editPhoneNumberController.text != auth.currentUser!.phoneNumber) {
      changePhoneNumber();
    }
    updateUserInDataBase();
    Navigator.pop(context);
  }

  Future<bool> isUsernameUnique(String username) async {
    QuerySnapshot querySnapshot = await userNamesRef.where(
        FieldPath.documentId, isEqualTo: username).get();

    return querySnapshot.docs.isEmpty;
  }

  changeUsername(){
    me!.username = editUsernameController.text;
    usersRef
        .doc(auth.currentUser!.uid)
        .update({'username': me!.username});
  }

  changePhoneNumber() async {
    setState(() {
      loading = true;
    });
    await auth.verifyPhoneNumber(
      phoneNumber: editPhoneNumberController.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {},
      codeSent: (String verificationId, int? resendToken) {
        myVerificationId = verificationId;
        setState(() {
          loading = false;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
    confirmCodeDialog();
  }

  confirmCodeDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            themeColor(context).withOpacity(0.90),
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.yellow[300],
                radius: 30,
                child: const Icon(
                  Iconsax.code,
                  size: 35,
                  color: Colors.black,
                ),
              ),
              title: Row(
                children: [
                  SizedBox(
                    height: 60,
                    width: 200,
                    child: CustomTextField(
                      maxLines: 1,
                      controller: codeController,
                      hint: 'Code ( XXXXXX )',
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  CustomButton(
                    width: 85,
                    text: 'Continue',
                    fontSize: 12,
                    textColor: Colors.black,
                    buttonColor: Colors.green[300],
                    onTap: () async {
                      setState(() {
                        loading = true;
                      });
                      String smsCode = codeController.text;

                      // Create a PhoneAuthCredential with the code
                      PhoneAuthCredential credential =
                          PhoneAuthProvider.credential(
                              verificationId: myVerificationId,
                              smsCode: smsCode);

                      await auth.currentUser!.updatePhoneNumber(credential);
                      setState(() {
                        loading = false;
                        usersRef.doc(auth.currentUser!.uid).update(
                            {'phoneNumber': editPhoneNumberController.text});
                        myVerificationId = '-1';
                        Navigator.pop(context);
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void updateUserInDataBase() async {
    await auth.currentUser!.updateDisplayName(me!.fullName);
    usersRef
        .doc(auth.currentUser!.uid)
        .update({'fullName': me!.fullName});
    usersRef
        .doc(auth.currentUser!.uid)
        .update({'email': me!.email});
  }

  selectImageOnTap() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            themeColor(context).withOpacity(0.85),
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Image From :',
              style: myTextStyle(context, 16, 'bold', 1),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.close,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              onTap: () {
                pickImage(ImageSource.camera);
              },
              title: const Text('Camera'),
              leading: const Icon(Iconsax.camera),
            ),
            const Divider(),
            ListTile(
              onTap: () {
                pickImage(ImageSource.gallery);
              },
              title: const Text('Gallery'),
              leading: const Icon(Iconsax.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      Navigator.pop(context);
      setState(() {
        imagePicked = File(image.path);
      });
      File? croppedFile = await ImageCropper().cropImage(
          sourcePath: imagePicked.path,
          aspectRatioPresets: Platform.isAndroid
              ? [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ]
              : [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio5x3,
            CropAspectRatioPreset.ratio5x4,
            CropAspectRatioPreset.ratio7x5,
            CropAspectRatioPreset.ratio16x9
          ],
          androidUiSettings: AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: onThemeColor(context),
              toolbarWidgetColor: themeColor(context),
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          iosUiSettings: const IOSUiSettings(
            title: 'Cropper',
          ));
      if (croppedFile != null) {
        imagePicked = croppedFile;

        String imageUrl = await uploadImage();
        setState(() {
          me!.imageAddress = imageUrl;
        });
        await auth.currentUser!.updatePhotoURL(imageUrl);
        await usersRef
            .doc(auth.currentUser!.uid)
            .update({'imageAddress': imageUrl});
      }
    }else {
      setState(() {
        imagePicked = File('-1');
      });
    }
  }

  Future<String> uploadImage() async {
    setState(() {
      loading = true;
    });
    try {
      String path = imagePicked.path.split('/').last;
      TaskSnapshot snapshot = await storage
          .ref()
          .child('Users/${auth.currentUser?.uid}/Profile/$path')
          .putFile(imagePicked);
      String url = await snapshot.ref.getDownloadURL();
      auth.currentUser!.updatePhotoURL(url);
      setState(() {
        loading = false;
      });
      return url;
    } catch (e) {
      setState(() {
        loading = false;
      });
      return auth.currentUser!.photoURL!;
    }
  }

  void logout() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            themeColor(context).withOpacity(0.90),
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        title: const SizedBox(
          height: 10,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want log out?',
                style: myTextStyle(context, 16, 'bold', 1),
              ),
              const SizedBox(
                height: 10,
              ),
              const Divider(),
              const SizedBox(
                height: 5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    width: MediaQuery.sizeOf(context).width / 2 - 70,
                    fontSize: 14,
                    text: 'Cancel',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  CustomButton(
                    width: MediaQuery.sizeOf(context).width / 2 - 70,
                    buttonColor: Colors.red[400],
                    fontSize: 14,
                    text: 'Log Out',
                    onTap: () async {
                      await usersRef.doc(auth.currentUser!.uid).update(
                          {'isActive': false, 'lastSeen': DateTime.now()});
                      await auth.signOut();
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignInScreen(),
                          ),
                          (route) => false);
                    },
                  ),
                ],
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
}
