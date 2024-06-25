import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:infinity_messenger/core/constants.dart';
import 'package:infinity_messenger/models/user_model.dart';
import 'package:infinity_messenger/screens/private_chat.dart';
import 'package:infinity_messenger/widgets/base_widget.dart';

class ContactProfileScreen extends StatefulWidget {
  const ContactProfileScreen({super.key, required this.userRef});

  final DocumentReference userRef;

  @override
  State<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends State<ContactProfileScreen> {
  FirebaseAuth auth = FirebaseAuth.instance;

  CollectionReference usersRef = FirebaseFirestore.instance.collection('Users');

  bool isContact = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: widget.userRef.snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          UserModel user = UserModel.getFromDocument(snapshot.data!);
        return BaseWidget(
          appBar: AppBar(
            title: Text(
              'User Profile',
              style: myTextStyle(context, 20, 'bold', 1),
            ),
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
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
                                backgroundColor:
                                    Theme.of(context).colorScheme.background,
                                radius: 80,
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(80),
                                    child: user.imageAddress != ''
                                        ? FadeInImage(
                                            placeholder: const AssetImage(
                                                'assets/images/defaultUser.jpg'),
                                            image: NetworkImage(
                                              user.imageAddress!,
                                            ),
                                            width: 160,
                                            height: 160,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            'assets/images/defaultUser.jpg',
                                            fit: BoxFit.cover,
                                          )),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          user.fullName ?? '',
                          style: myTextStyle(context, 22, 'bold', 1),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.grammerly,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Bio',
                        style: myTextStyle(context, 14, 'bold', 0.5),
                      ),
                      const Expanded(
                        child: Divider(),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Material(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PrivateChatScreen(
                                  otherUserRef: widget.userRef,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withOpacity(0.80),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Icon(
                              Iconsax.message,
                              color: Theme.of(context).colorScheme.background,
                              size: 35,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
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
                      const Expanded(
                        child: Divider(),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[500],
                      radius: 30,
                      child: const Icon(
                        Iconsax.status,
                        size: 35,
                        color: Colors.black,
                      ),
                    ),
                    title: Text(
                      'Status',
                      style: myTextStyle(context, 16, 'bold', 1),
                    ),
                    subtitle: Text(
                      getLastSeen(user.isActive,
                          user.lastSeen!.toDate()),
                      style: myTextStyle(context, 12, 'bold', 0.75),
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
                    title: Text(
                      'Username',
                      style: myTextStyle(context, 16, 'bold', 1),
                    ),
                    subtitle: Text(
                      user.username != null
                          ? '@ ${user.username}'
                          : '',
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
                      isContact? user.email ?? '' : '*************',
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
                      isContact? user.phoneNumber: '*************',
                      style: myTextStyle(context, 12, 'bold', 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}

class ProfileImage extends StatelessWidget {
  const ProfileImage({super.key, required this.imageAddress});

  final String imageAddress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Iconsax.arrow_left),
        ),
      ),
      body: Hero(
        tag: 'profile',
        child: Center(
          child: Image.network(imageAddress),
        ),
      ),
    );
  }
}
