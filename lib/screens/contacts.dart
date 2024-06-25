import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:iconsax/iconsax.dart';
import 'package:infinity_messenger/core/constants.dart';
import 'package:infinity_messenger/models/user_model.dart';
import 'package:infinity_messenger/screens/creat_new_group.dart';
import 'package:infinity_messenger/screens/private_chat.dart';
import 'package:infinity_messenger/widgets/base_widget.dart';
import 'package:infinity_messenger/widgets/custom_button.dart';
import 'package:infinity_messenger/widgets/custom_text_filed.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with TickerProviderStateMixin {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  late CollectionReference usersRef;

  late AnimationController animationController;
  late Animation<double> animation;
  ScrollController scrollController = ScrollController();

  TextEditingController searchControl = TextEditingController();
  TextEditingController addContactNameController = TextEditingController();
  TextEditingController addContactPhoneNumberController =
      TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    usersRef = fireStore.collection('Users');

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    animation =
        CurvedAnimation(parent: animationController, curve: Curves.linear);

    animationController.forward();

    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection ==
          ScrollDirection.forward ||
          scrollController.position.userScrollDirection ==
              ScrollDirection.forward) {
        animationController.forward();
      }
      else{
        animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseWidget(
      appBar: AppBar(
        title: Text(
          'Contacts',
          style: myTextStyle(context, 20, 'bold', 1),
        ),
      ),
      floatingActionButtonAnimation: animation,
      floatingActionButton: () {
        creatNewContact();
      },
      floatingActionButtonIcon: Iconsax.add,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ListTile(
            leading: Icon(Iconsax.add,color: Colors.blue[600],size: 35,),
            title: Text(
              'Creat new group',
              style: myTextStyle(context, 18, 'bold', 1).copyWith(color: Colors.blue[600]),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatNewGroup(),
                ),
              );
            },
          ),
          const SizedBox(
            height: 10,
          ),
          CustomTextField(
            controller: searchControl,
            hint: 'Search',
            prefixIcon: const Icon(
              Iconsax.search_normal,
            ),
          ),
          const SizedBox(
            height: 10,
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
                      controller: scrollController,
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
                            UserModel contact = UserModel.getFromDocument(userSnapshot.data!);
                            String lastSeen = getLastSeen(
                              contact.isActive,
                              contact.lastSeen!.toDate(),
                            );
                            return Visibility(
                              visible: contact.id != auth.currentUser!.uid,
                              child: ListTile(
                                leading: Stack(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        border: Border.all(width: 1,
                                          color: contact.isActive ? Colors.blue : Colors.red,),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: CircleAvatar(
                                        backgroundColor: themeColor(context),
                                        radius: 30,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(30),
                                          child: contact.imageAddress != ''
                                              ? FadeInImage(
                                                  placeholder: const AssetImage(
                                                      'assets/images/defaultUser.jpg'),
                                                  image: NetworkImage(
                                                    contact.imageAddress ?? ''),
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
                                      visible: contact.isActive,
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
                                    contact.fullName ?? '',
                                  style: myTextStyle(context, 18, 'bold', 1),
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PrivateChatScreen(
                                        otherUserRef: usersRef.doc(contact.id),
                                      ),
                                    ),
                                  );
                                },
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
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Tap',
                              style: myTextStyle(context, 16, 'normal', 0.5),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Icon(
                              Iconsax.add,
                              size: 20,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(
                              'to add a contact',
                              style: myTextStyle(context, 16, 'normal', 0.5),
                            )
                          ],
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
          ),
        ],
      ),
    );
  }

  void creatNewContact() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Theme.of(context).colorScheme.background.withOpacity(0.90),
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add new contact',
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
                  backgroundColor: Theme.of(context).colorScheme.onBackground,
                  radius: 30,
                  child: Icon(
                    Iconsax.user,
                    size: 35,
                    color: Theme.of(context).colorScheme.background,
                  ),
                ),
                title: CustomTextField(
                  controller: addContactNameController,
                  hint: 'Name',
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
                  controller: addContactPhoneNumberController,
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
                    text: 'Add',
                    onTap: () async {
                      await addToContacts();
                      addContactNameController.clear();
                      addContactPhoneNumberController.clear();
                      Navigator.pop(context);
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

  addToContacts() {
    usersRef
        .where('phoneNumber', isEqualTo: addContactPhoneNumberController.text)
        .get()
        .then(
      (QuerySnapshot querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          String userId = querySnapshot.docs.first.id;
          DocumentReference contactRef = usersRef.doc(userId);
          usersRef
              .doc(auth.currentUser!.uid)
              .collection('contacts')
              .doc(userId)
              .set({
            'contactRef': contactRef,
            'contactName': addContactNameController.text
          }).then(
            (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                  content: Text('Contact added successfully.'),
                ),
              );
            },
          ).catchError(
            (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  content: Text('Error adding contact: $error'),
                ),
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
              content: Text('User not found with this phone number.'),
            ),
          );
        }
      },
    );
  }
}
