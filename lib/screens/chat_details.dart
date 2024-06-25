import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:infinity_messenger/core/constants.dart';
import 'package:infinity_messenger/models/chat_model.dart';
import 'package:infinity_messenger/models/user_model.dart';
import 'package:infinity_messenger/screens/add_new_members.dart';
import 'package:infinity_messenger/screens/contact_profile.dart';
import 'package:infinity_messenger/screens/profile.dart';
import 'package:infinity_messenger/widgets/base_widget.dart';
import 'package:infinity_messenger/widgets/custom_button.dart';
import 'package:infinity_messenger/widgets/custom_text_filed.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class ChatDetails extends StatefulWidget {
  const ChatDetails({super.key, required this.chatRef});

  final DocumentReference chatRef;

  @override
  State<ChatDetails> createState() => _ChatDetailsState();
}

class _ChatDetailsState extends State<ChatDetails> {
  FirebaseAuth auth = FirebaseAuth.instance;
  final storage = FirebaseStorage.instance;
  CollectionReference usersRef = FirebaseFirestore.instance.collection('Users');
  CollectionReference groupsRef =
      FirebaseFirestore.instance.collection('Groups');

  File imagePicked = File('-1');
  ChatModel? chatData;
  bool isAdmin = false;
  bool isOwner = false;
  bool isEditingBio = false;
  bool loading = false;

  TextEditingController editBioController = TextEditingController();
  ScrollController membersScroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: loading,
      color: onThemeColor(context),
      opacity: 0.3,
      progressIndicator: showLoading(context),
      child: BaseWidget(
        appBar: AppBar(
          title: Row(
            children: [
              Text(
                'Group Info',
                style: myTextStyle(context, 20, 'bold', 1),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Iconsax.menu),
            ),
          ],
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: widget.chatRef.snapshots(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> chatSnapshot) {
            if (!chatSnapshot.hasData) {
              return const SizedBox();
            }
            ChatModel chat = ChatModel.getFromDocument(chatSnapshot.data!);
            chatData = chat;
            if (chat.owner == usersRef.doc(auth.currentUser!.uid)) {
              isOwner = true;
            }
            if (chat.admins!.contains(
              usersRef.doc(auth.currentUser!.uid),
            )) {
              isAdmin = true;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children:[
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(width: 1),
                            borderRadius: BorderRadius.circular(50),
                            color: onThemeColor(context).withOpacity(0.5),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () {
                              chat.chatImageAddress != ''
                                  ? Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileImage(
                                    imageAddress: chat.chatImageAddress!,
                                  ),
                                ),
                              )
                                  : null;
                            },
                            child: Hero(
                              tag: 'groupImage',
                              child: CircleAvatar(
                                backgroundColor:
                                onThemeColor(context).withOpacity(0.5),
                                radius: 50,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(80),
                                  child: chatData!.chatImageAddress != ''
                                      ? FadeInImage(
                                    placeholder: const AssetImage(
                                        'assets/images/defaultUser.jpg'),
                                    image: NetworkImage(
                                      chatData!.chatImageAddress!,
                                    ),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                      : Text(
                                    chatData!.groupName!
                                        .toUpperCase()
                                        .substring(0, 1),
                                    style: myTextStyle(context, 28, 'bold', 1)
                                        .copyWith(color: themeColor(context)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        isAdmin? Positioned(
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
                        ) : const SizedBox(),
                      ]
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chatData!.groupName ?? '',
                          style: myTextStyle(context, 20, 'bold', 1),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          '${chatData!.members!.length.toString()} Members',
                          style: myTextStyle(context, 14, 'normal', 0.75),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    const Icon(Iconsax.grammerly),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Bio',
                      style: myTextStyle(context, 16, 'bold', 0.5),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Expanded(child: Divider()),
                    isAdmin?
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
                              editBioController.text = chatData!.bio ??'';
                              isEditingBio = true;
                            });
                          },
                        ):const SizedBox(),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                isEditingBio? Row(children: [
                  Expanded(child: CustomTextField(controller: editBioController, hint:'Group Bio')),
                ],):
                Row(
                  children: [
                    const SizedBox(
                      width: 30,
                    ),
                    Text(
                      chat.bio ?? '\n\n',
                      style: myTextStyle(context, 14, 'bold', 0.75),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    const Icon(Iconsax.user),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Members',
                      style: myTextStyle(context, 16, 'bold', 0.5),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    const Expanded(child: Divider()),
                    const SizedBox(
                      width: 10,
                    ),
                    Visibility(
                      visible: isAdmin,
                      child: InkWell(
                        highlightColor: Colors.blue,
                        overlayColor: const MaterialStatePropertyAll(Colors.blue),
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AddNewMembers(
                                      chatId: chat.id,
                                      chatName: chat.groupName!,
                                      members: chat.members!,
                                      chatRef: widget.chatRef),),);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20)),
                          child: const Row(
                            children: [
                              Text('Add'),
                              SizedBox(
                                width: 5,
                              ),
                              Icon(Iconsax.user_add),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    controller: membersScroll,
                    itemCount: chat.members!.length,
                    itemBuilder: (context, index) {
                      return StreamBuilder<DocumentSnapshot>(
                        stream: chat.members![index].snapshots(),
                        builder: (context,
                            AsyncSnapshot<DocumentSnapshot> memberSnapshot) {
                          if (!memberSnapshot.hasData) {
                            return const SizedBox();
                          }
                          UserModel member =
                              UserModel.getFromDocument(memberSnapshot.data!);
                          String lastSeen = getLastSeen(
                            member.isActive,
                            member.lastSeen!.toDate(),
                          );
                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  20), // Determine the curvature of edges
                            ),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundColor: themeColor(context),
                                  radius: 30,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: member.imageAddress != ''
                                        ? FadeInImage(
                                            placeholder: const AssetImage(
                                                'assets/images/defaultUser.jpg'),
                                            image: NetworkImage(
                                                member.imageAddress ?? ''),
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
                                  visible: member.isActive,
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
                                          color: onThemeColor(context),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Text(
                                  member.fullName!,
                                  style: myTextStyle(context, 18, 'bold', 1),
                                ),
                                Visibility(
                                  visible: chat.admins!
                                      .contains(usersRef.doc(member.id)),
                                  child: Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Spacer(),
                                        Text(
                                          chat.owner == usersRef.doc(member.id) ? 'Owner' : 'Admin',
                                          style:
                                              myTextStyle(context, 12, 'bold', 1)
                                                  .copyWith(color: Colors.blue),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
                                  : myTextStyle(context, 12, 'normal', 1),
                            ),
                            onTap: () {
                              isAdmin
                                  ? showAdminDialog(
                                      chat.id,
                                      usersRef.doc(member.id),
                                      chat.members!,
                                      chat.admins!,chat.owner!)
                                  : Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ContactProfileScreen(
                                          userRef: usersRef.doc(member.id),
                                        ),
                                      ),
                                    );
                            },
                          );
                        },
                      );
                    },
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  showAdminDialog(String chatId, DocumentReference<Object?> user, List members,
      List admins , DocumentReference owner) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeColor(context).withOpacity(0.85),
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                if(user == usersRef.doc(auth.currentUser!.uid)){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Profile(),
                    ),
                  );
                }else{
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ContactProfileScreen(
                        userRef: user,
                      ),
                    ),
                  );
                }
              },
              label: Text('View Profile',
                  style: myTextStyle(context, 14, 'bold', 1)),
              icon: const Icon(
                Iconsax.user,
                size: 30,
              ),
            ),
            Visibility(
              visible: (user != owner && usersRef.doc(auth.currentUser!.uid) != user) ,
              child: admins.contains(user) ?
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  removeAdmin(chatId, admins, user);
                },
                label: Text(
                  'Remove from admins',
                  style: myTextStyle(context, 14, 'bold', 1)
                      .copyWith(color: Colors.red),
                ),
                icon: const Icon(
                  Iconsax.user_remove,
                  size: 30,
                  color: Colors.red,
                ),
              )
                  :TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  addAdmin(chatId, admins, user);
                },
                label: Text(
                  'Promote as admin',
                  style: myTextStyle(context, 14, 'bold', 1)
                      .copyWith(color: Colors.green),
                ),
                icon: const Icon(
                  Iconsax.user_add,
                  size: 30,
                  color: Colors.green,
                ),
              ),
            ),
            Visibility(
              visible: (user != owner &&  usersRef.doc(auth.currentUser!.uid) != user),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  removeMemberDialog(chatId, user, members);
                },
                label: Text(
                  'Remove User',
                  style: myTextStyle(context, 14, 'bold', 1)
                      .copyWith(color: Colors.red),
                ),
                icon: const Icon(
                  Iconsax.user_remove,
                  size: 30,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  addAdmin(String chatId, List admins, DocumentReference user) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeColor(context).withOpacity(0.90),
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        title: const SizedBox(
          height: 10,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add this user to admins?',
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
                  buttonColor: Colors.green[400],
                  fontSize: 14,
                  text: 'Add',
                  onTap: () async {
                    List newAdmins = admins;
                  newAdmins.add(user);
                    Navigator.pop(context);
                  await widget.chatRef.update({'admins': newAdmins});
                  setState(() {

                  });
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
    );
  }

  removeAdmin(String chatId, List admins, DocumentReference user) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeColor(context).withOpacity(0.90),
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        title: const SizedBox(
          height: 10,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Remove this user from admins?',
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
                  text: 'remove',
                  onTap: () async {
                    List newAdmins = admins;
                    newAdmins.remove(user);
                    Navigator.pop(context);
                    await widget.chatRef.update({'admins': newAdmins});
                    setState(() {
                    });
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
    );
  }

  void removeMemberDialog(
      String chatId, DocumentReference<Object?> user, List members) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeColor(context).withOpacity(0.90),
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        title: const SizedBox(
          height: 10,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want remove this user?',
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
                  text: 'remove',
                  onTap: () async {
                    await removeMember(chatId, user, members);
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
    );
  }

  removeMember(
      String chatId, DocumentReference<Object?> user, List members) async {
    List newMembers = members;
    newMembers.remove(user);
    Navigator.pop(context);
    await user.collection('groups').doc(chatId).delete();
    await widget.chatRef.update({'members': newMembers});
    setState(() {
    });
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
          chatData!.chatImageAddress = imageUrl;
        });
        await widget.chatRef
            .update({'chatImageAddress': imageUrl});
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
          .child('Groups/${chatData!.id}/Profile/$path')
          .putFile(imagePicked);
      String url = await snapshot.ref.getDownloadURL();
      setState(() {
        loading = false;
      });
      return url;
    } catch (e) {
      setState(() {
        loading = false;
      });
      return '';
    }
  }

  editBio(){
    setState(() {
      chatData!.bio = editBioController.text;
    });
    widget.chatRef
        .update({'bio': chatData!.bio});
  }
}
