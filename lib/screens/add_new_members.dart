import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:infinity_messenger/core/constants.dart';
import 'package:infinity_messenger/models/user_model.dart';
import 'package:infinity_messenger/widgets/custom_button.dart';

class AddNewMembers extends StatefulWidget {
  const AddNewMembers(
      {super.key,
      required this.chatId,
      required this.chatName,
      required this.members,
      required this.chatRef});

  final DocumentReference chatRef;
  final String chatId;
  final String chatName;
  final List members;

  @override
  State<AddNewMembers> createState() => _AddNewMembersState();
}

class _AddNewMembersState extends State<AddNewMembers> {
  FirebaseAuth auth = FirebaseAuth.instance;
  CollectionReference usersRef = FirebaseFirestore.instance.collection('Users');
  CollectionReference groupsRef =
      FirebaseFirestore.instance.collection('Groups');

  ScrollController addMembersScroll = ScrollController();
  bool emptyMembers = false;
  List<DocumentReference> memberList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeColor(context).withOpacity(0.90),
      appBar: AppBar(
        title: Text(
          'Add new member',
          style: myTextStyle(context, 20, 'bold', 1),
        ),
      ),
      body: Column(
        children: [
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
                      controller: addMembersScroll,
                      physics: const BouncingScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        return StreamBuilder(
                          stream: usersRef
                              .doc(snapshot.data!.docs[index].id)
                              .snapshots(),
                          builder: (context,
                              AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                            if (!userSnapshot.hasData) {
                              return const SizedBox();
                            }
                            UserModel user =
                                UserModel.getFromDocument(userSnapshot.data!);
                            String lastSeen = getLastSeen(
                              user.isActive,
                              user.lastSeen!.toDate(),
                            );
                            bool isExist = false;
                            if (widget.members
                                .contains(usersRef.doc(user.id))) {
                              isExist = true;
                            }
                            return Visibility(
                              visible: user.id != auth.currentUser!.uid,
                              child: Column(
                                children: [
                                  CheckboxListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          20), // Determine the curvature of edges
                                    ),
                                    tileColor: isExist
                                        ? Colors.green[600]!.withOpacity(0.2)
                                        : null,
                                    activeColor: isExist
                                        ? Colors.green[600]
                                        : Colors.blue[600],
                                    secondary: Stack(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            border: Border.all(width: 1,
                                              color: user.isActive ? Colors.blue : Colors.red,),
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          child: CircleAvatar(
                                            backgroundColor: themeColor(context),
                                            radius: 30,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(30),
                                              child: user.imageAddress != ''
                                                  ? FadeInImage(
                                                      placeholder: const AssetImage(
                                                          'assets/images/defaultUser.jpg'),
                                                      image: NetworkImage(
                                                          user.imageAddress ?? ''),
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
                                        ),
                                        Visibility(
                                          visible: user.isActive,
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
                                    title: Text(
                                      user.fullName ?? '',
                                      style: myTextStyle(context, 16, 'bold', 1),
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
                                    onChanged: (bool? value) {
                                      if (!isExist) {
                                        setState(() {
                                          emptyMembers = false;
                                        });
                                        selectMember(value!, usersRef.doc(user.id));
                                      }
                                    },
                                    value: isExist
                                        ? true
                                        : memberList
                                            .contains(usersRef.doc(user.id)),
                                  ),
                                  const SizedBox(height: 3,),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                } else {
                  // Display a message if there are no contacts
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Have no contacts yet',
                        style: myTextStyle(context, 26, 'bold', 1),
                      ),
                    ],
                  );
                }
              } else {
                // Display a loading indicator if there's no data
                return showLoading(context);
              }
            },
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
                width: MediaQuery.of(context).size.width / 2 - 20,
                fontSize: 16,
                text: 'Cancel',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(
                width: 10,
              ),
              CustomButton(
                width: MediaQuery.of(context).size.width / 2 - 20,
                buttonColor: (memberList.isNotEmpty) ?Colors.green[400] : Colors.grey ,
                fontSize: 16,
                text: 'Add Members',
                onTap: (memberList.isNotEmpty) ? () async {

                    Navigator.pop(context);
                    for(var item in memberList){
                      await addMember(
                          widget.chatId, widget.chatName, item, widget.members);

                  }
                } : null,
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
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

  addMember(String chatId, String chatName, DocumentReference<Object?> user,
      List members) async {
    List newMembers = members;
    newMembers.add(user);
    await user
        .collection('groups')
        .doc(chatId)
        .set({'groupName': chatName, 'chatRef': widget.chatRef});
    await widget.chatRef.update({'members': newMembers});
  }
}
