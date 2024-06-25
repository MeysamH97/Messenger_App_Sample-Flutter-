import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:infinity_messenger/core/constants.dart';
import 'package:infinity_messenger/widgets/base_widget.dart';
import 'package:infinity_messenger/widgets/custom_text_filed.dart';
import 'package:infinity_messenger/screens/chat.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class CreatNewGroup extends StatefulWidget {
  const CreatNewGroup({super.key});

  @override
  State<CreatNewGroup> createState() => _CreatNewGroupState();
}

class _CreatNewGroupState extends State<CreatNewGroup> {
  FirebaseAuth auth = FirebaseAuth.instance;
  final storage = FirebaseStorage.instance;
  CollectionReference groupsRef =
      FirebaseFirestore.instance.collection('Groups');
  CollectionReference usersRef = FirebaseFirestore.instance.collection('Users');

  bool loading = false;
  bool emptyName = false;
  bool emptyMembers = false;

  List<DocumentReference> memberList = [];

  File imagePicked = File('-1');
  TextEditingController groupNameController = TextEditingController();
  TextEditingController groupBioController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    memberList.add(usersRef.doc(auth.currentUser!.uid));
  }

  selectMember(bool selected, DocumentReference member) {
    setState(() {
      if (selected) {
        memberList.add(member);
      } //
      else {
        memberList.remove(member);
      }
    });
  }

  creatNewGroup() async {
    if (groupNameController.text.isEmpty) {
      setState(() {
        emptyName = true;
      });
    } else {
      if (memberList.length < 2) {
        setState(() {
          emptyMembers = true;
        });
      } else {
        setState(() {
          loading = true;
        });
        Map<String, dynamic> newGroup = {};
        newGroup['id'] = '';
        newGroup['groupName'] = groupNameController.text;
        newGroup['bio'] = groupBioController.text;
        newGroup['type'] = 'groupChat';
        newGroup['owner'] = usersRef.doc(auth.currentUser!.uid);
        newGroup['admins'] = [usersRef.doc(auth.currentUser!.uid)];
        newGroup['chatImageAddress'] = '';
        newGroup['isTyping'] = [];
        newGroup['lastMessage'] = null;
        newGroup['lastMessageTime'] = DateTime.now();
        newGroup['members'] = memberList;
        newGroup['chatRef'] = null;
        DocumentReference id = await groupsRef.add(newGroup);
        id.update({'id':id.id, 'chatRef': id});
        if (imagePicked.path != '-1') {
          String imageUrl = await uploadImage(id.id);
          if (imageUrl != 'Error') {
            id.update({'chatImageAddress': imageUrl});
          }
        }
        for (var item in memberList) {
          await item
              .collection('groups')
              .doc(id.id)
              .set({'groupName': groupNameController.text, 'chatRef': id});
        }
        setState(() {
          loading = false;
        });
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatScreen(chatRef : id),));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: loading,
      progressIndicator: const Center(
        child: CircularProgressIndicator(),
      ),
      child: BaseWidget(
        appBar: AppBar(
          title: const Text('Creat new group'),
          actions: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.25),
              ),
              child: IconButton(
                highlightColor: Colors.green.withOpacity(0.5),
                splashRadius: 1,
                onPressed: () => creatNewGroup(),
                icon: const Icon(Icons.check, size: 30),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.background,
                        radius: 60,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: imagePicked.path == '-1'
                              ? const SizedBox()
                              : Image.file(
                                  imagePicked,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                    Container(
                      height: 120,
                      width: 120,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context)
                            .colorScheme
                            .onBackground
                            .withOpacity(0.25),
                      ),
                      child: GestureDetector(
                        child: Icon(
                          Iconsax.camera,
                          size: 50,
                          color: Colors.blue[600],
                        ),
                        onTap: () {
                          pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: CustomTextField(
                    controller: groupNameController,
                    hint: 'Group Name',
                    fillColor: emptyName
                        ? Colors.red[400]!.withOpacity(0.2)
                        : null,
                    onChanged: (value) => setState(() {
                      emptyName = false;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: CustomTextField(
                              controller: groupBioController,
                              hint: 'Group Bio')),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Text(
                        'Members  ',
                        style: myTextStyle(context, 16, 'bold', 1),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      const Expanded(child: Divider()),
                      const SizedBox(
                        width: 10,
                      ),
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: emptyMembers ? Colors.red[400]!.withOpacity(0.5):Colors.blue[600]!.withOpacity(0.5),
                        child: Text(
                          memberList.length.toString(),
                          style: myTextStyle(context, 14, 'bold', 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: usersRef
                        .doc(auth.currentUser!.uid)
                        .collection('contacts')
                        .orderBy('contactName')
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data!.docs.isNotEmpty) {
                          return Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                return StreamBuilder(
                                  stream: usersRef
                                      .doc(snapshot.data!.docs[index].id)
                                      .snapshots(),
                                  builder: (context,
                                      AsyncSnapshot<DocumentSnapshot>
                                          userSnapshot) {
                                    if (!userSnapshot.hasData) {
                                      return const SizedBox();
                                    }
                                    Map<String, dynamic> user =
                                        userSnapshot.data!.data()
                                            as Map<String, dynamic>;
                                    String lastSeen = getLastSeen(
                                      user['isActive'],
                                      user['lastSeen'].toDate(),
                                    );
                                    return Visibility(
                                      visible:
                                          user['id'] != auth.currentUser!.uid,
                                      child: CheckboxListTile(
                                        activeColor: Colors.blue[600],
                                        secondary: Stack(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .background,
                                              radius: 30,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                                child:
                                                    user['imageAddress'] != ''
                                                        ? FadeInImage(
                                                            placeholder:
                                                                const AssetImage(
                                                                    'assets/images/defaultUser.jpg'),
                                                            image: NetworkImage(
                                                                user['imageAddress'] ??
                                                                    ''),
                                                            width: 60,
                                                            height: 60,
                                                            fit: BoxFit.cover,
                                                          )
                                                        : Image.asset(
                                                            'assets/images/defaultUser.jpg',
                                                            fit: BoxFit.cover,
                                                          ),
                                              ),
                                            ),
                                            Visibility(
                                              visible: user['isActive'],
                                              child: Positioned(
                                                right: 5,
                                                bottom: 0,
                                                child: Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onBackground,
                                                      width: 1,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        title: Text(
                                          user['fullName'],
                                          style: myTextStyle(
                                              context, 18, 'bold', 1),
                                        ),
                                        subtitle: Text(
                                          lastSeen,
                                          style: lastSeen == 'Online'
                                              ? TextStyle(
                                                  fontFamily: myFontFamily,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.blue,
                                                )
                                              : myTextStyle(
                                                  context, 12, 'normal', 1),
                                        ),
                                        onChanged: (bool? value) {
                                          setState(() {
                                            emptyMembers = false;
                                          });
                                          selectMember(
                                              value!, usersRef.doc(user['id']));
                                        },
                                        value: memberList
                                            .contains(usersRef.doc(user['id'])),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        } else {
                          // Display a message if there are no contacts
                          return Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Have no contacts yet',
                                  style: myTextStyle(context, 30, 'bold', 1),
                                ),
                              ],
                            ),
                          );
                        }
                      } else {
                        // Display a loading indicator if there's no data
                        return showLoading(context);
                      }
                    },
                  )
                ],
              ),
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
              toolbarColor: Theme.of(context).colorScheme.onBackground,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          iosUiSettings: const IOSUiSettings(
            title: 'Cropper',
          ));
      if (croppedFile != null) {
        setState(() {
          imagePicked = croppedFile;
        });
      } else {
        setState(() {
          imagePicked = File('-1');
        });
      }
    }
  }

  Future<String> uploadImage(String id) async {
    try {
      String path = imagePicked.path.split('/').last;
      TaskSnapshot snapshot = await storage
          .ref()
          .child('GroupChats/$id/GroupImage/$path')
          .putFile(imagePicked);
      String url = await snapshot.ref.getDownloadURL();
      return url;
    } catch (e) {
      return 'Error';
    }
  }
}
