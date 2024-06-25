import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:iconsax/iconsax.dart';
import 'package:infinity_messenger/core/constants.dart';
import 'package:infinity_messenger/models/chat_model.dart';
import 'package:infinity_messenger/models/message_model.dart';
import 'package:infinity_messenger/models/private_chat_model.dart';
import 'package:infinity_messenger/models/user_model.dart';
import 'package:infinity_messenger/screens/chat.dart';
import 'package:infinity_messenger/screens/private_chat.dart';
import 'package:infinity_messenger/widgets/base_widget.dart';
import 'package:infinity_messenger/widgets/custom_text_filed.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  late CollectionReference usersRef;
  late CollectionReference privateChatsRef;
  late CollectionReference groupsRef;

  late CollectionReference publicChatRef;
  late AnimationController animationController;
  late Animation<double> animation;

  ScrollController scrollController = ScrollController();
  TextEditingController searchControl = TextEditingController();

  ChatModel? publicChat;
  List chats = [];

  @override
  void initState() {
    super.initState();
    usersRef = fireStore.collection('Users');
    publicChatRef = fireStore.collection('publicChat');
    privateChatsRef = usersRef.doc(auth.currentUser!.uid).collection('chats');
    groupsRef = fireStore.collection('Groups');
    usersRef
        .doc(auth.currentUser!.uid)
        .update({'isActive': true, 'lastSeen': DateTime.now()});

    // sortChatsByLastMessageTime(chats);

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
      } else {
        animationController.reverse();
      }
    });
  }

  // Timestamp? getLastMessageTime(DocumentReference chatRef) {
  //   // Fetch the document referenced by chatRef to get the "lastMessageTime" field
  //   // Implement this function based on your Firestore structure
  //   // Return the Timestamp or null if the field is not available
  // }
  //
  // void sortChatsByLastMessageTime(List<DocumentReference> chats) {
  //   chats.sort((ref1, ref2) {
  //     Timestamp? time1 = getLastMessageTime(ref1);
  //     Timestamp? time2 = getLastMessageTime(ref2);
  //
  //     if (time1 != null && time2 != null) {
  //       return time2.compareTo(time1);
  //     } else {
  //       return 0;
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        usersRef
            .doc(auth.currentUser!.uid)
            .update({'isActive': false, 'lastSeen': DateTime.now()});
      },
      child: StreamBuilder(
          stream: usersRef.doc(auth.currentUser!.uid).snapshots(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
            if (!userSnapshot.hasData) {
              return const SizedBox();
            }
            UserModel me = UserModel.getFromDocument(userSnapshot.data!);
            return BaseWidget(
              appBar: AppBar(
                toolbarHeight: 75,
                leading: null,
                title: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 1,
                          color: me.isActive ? Colors.blue : Colors.red,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          kNavigator(context, 'Profile');
                        },
                        child: CircleAvatar(
                          backgroundColor: themeColor(context),
                          radius: 30,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: me.imageAddress != null
                                ? FadeInImage(
                                    placeholder: const AssetImage(
                                        'assets/images/defaultUser.jpg'),
                                    image: NetworkImage(me.imageAddress ?? ''),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover)
                                : Image.asset(
                                    'assets/images/defaultUser.jpg',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Chat',
                      style: myTextStyle(context, 20, 'bold', 1),
                    ),
                  ],
                ),
                actions: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.05),
                    ),
                    child: IconButton(
                      splashRadius: 1,
                      onPressed: () {},
                      icon: const Icon(
                        Iconsax.camera,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: onThemeColor(context).withOpacity(0.05),
                    ),
                    child: IconButton(
                      splashRadius: 1,
                      onPressed: () {
                        kNavigator(context, 'Contacts');
                      },
                      icon: const Icon(
                        Iconsax.user_add,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  )
                ],
              ),
              floatingActionButton: () {
                kNavigator(context, 'Contacts');
              },
              floatingActionButtonAnimation: animation,
              floatingActionButtonIcon: Iconsax.message,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
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
                  me.showPublicChat
                      ? StreamBuilder(
                          stream: publicChatRef.doc('publicChat').snapshots(),
                          builder: (context,
                              AsyncSnapshot<DocumentSnapshot>
                                  publicChatSnapshot) {
                            if (!publicChatSnapshot.hasData) {
                              return const SizedBox();
                            }
                            publicChat = ChatModel.getFromDocument(
                                publicChatSnapshot.data!);
                            return OpenContainer(
                              closedColor: themeColor(context),
                              openColor: themeColor(context),
                              useRootNavigator: true,
                              transitionDuration:
                                  const Duration(milliseconds: 200),
                              closedBuilder: (context, action) => ListTile(
                                tileColor:
                                    onThemeColor(context).withOpacity(0.02),
                                leading: CircleAvatar(
                                  radius: 30,
                                  child: publicChat!.chatImageAddress != ''
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          child: Image.network(
                                            publicChat!.chatImageAddress!,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Text(
                                          publicChat!.groupName!
                                              .toUpperCase()
                                              .substring(0, 1),
                                          style: myTextStyle(
                                              context, 20, 'bold', 1),
                                        ),
                                ),
                                title: Row(
                                  children: [
                                    const Icon(Icons.group),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: Text(
                                        publicChat!.groupName!,
                                        style:
                                            myTextStyle(context, 18, 'bold', 1),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${publicChat!.lastMessageTime!.toDate().hour.toString().padLeft(2, '0')}:${publicChat!.lastMessageTime!.toDate().minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                          color: onThemeColor(context)
                                              .withOpacity(0.6),
                                          fontSize: 11,
                                          fontFamily: myFontFamily,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                subtitle: publicChat!.lastMessage != null
                                    ? StreamBuilder<DocumentSnapshot>(
                                        stream: publicChat!.lastMessage!
                                            .snapshots(),
                                        builder: (context,
                                            AsyncSnapshot<DocumentSnapshot>
                                                messageSnapshot) {
                                          if (!messageSnapshot.hasData) {
                                            return const SizedBox();
                                          }
                                          Map<String, dynamic> messageData =
                                              messageSnapshot.data!.data()
                                                  as Map<String, dynamic>;

                                          return StreamBuilder<
                                              DocumentSnapshot>(
                                            stream: messageData['Sender']
                                                .snapshots(),
                                            builder: (context,
                                                AsyncSnapshot<DocumentSnapshot>
                                                    userSnapshot) {
                                              if (!userSnapshot.hasData) {
                                                return const SizedBox();
                                              }
                                              Map<String, dynamic> senderData =
                                                  userSnapshot.data!.data()
                                                      as Map<String, dynamic>;
                                              return publicChat!
                                                      .isTyping!.isEmpty
                                                  ? Row(
                                                      children: [
                                                        Text(
                                                          '${senderData['fullName']}: ',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                myFontFamily,
                                                            color: Colors
                                                                .blueAccent,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            '${messageData['text']}',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  myFontFamily,
                                                              color: onThemeColor(
                                                                      context)
                                                                  .withOpacity(
                                                                      0.7),
                                                              fontSize: 12,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : publicChat!.isTyping!
                                                              .length ==
                                                          1
                                                      ? Row(
                                                          children: [
                                                            Text(
                                                              '${publicChat!.isTyping!.first['fullName']} ',
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    myFontFamily,
                                                                color: Colors
                                                                    .blueAccent,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                'is typing...',
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      myFontFamily,
                                                                  color: onThemeColor(
                                                                          context)
                                                                      .withOpacity(
                                                                          0.7),
                                                                  fontSize: 11,
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      : Row(
                                                          children: [
                                                            Text(
                                                              '${publicChat!.isTyping!.last['fullName']} and ${(publicChat!.isTyping!.length - 1).toString()} other people ',
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    myFontFamily,
                                                                color: Colors
                                                                    .blueAccent,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                'are typing...',
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      myFontFamily,
                                                                  color: onThemeColor(
                                                                          context)
                                                                      .withOpacity(
                                                                          0.7),
                                                                  fontSize: 11,
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                            },
                                          );
                                        },
                                      )
                                    : Text(
                                        'No messages yet',
                                        style: TextStyle(
                                          fontFamily: myFontFamily,
                                          color: onThemeColor(context)
                                              .withOpacity(0.5),
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
                              openBuilder: (context, action) => ChatScreen(
                                chatRef: publicChatRef.doc('publicChat'),
                              ),
                            );
                          })
                      : const SizedBox(),
                  const SizedBox(
                    height: 3,
                  ),
                  StreamBuilder<QuerySnapshot>(
                                      stream: usersRef
                    .doc(auth.currentUser!.uid)
                    .collection('chats')
                    .snapshots(),
                                      builder: (context,
                    AsyncSnapshot<QuerySnapshot> userPrivateChatsSnapshot) {
                  if (!userPrivateChatsSnapshot.hasData) {
                    return const SizedBox();
                  }
                  for (var item in userPrivateChatsSnapshot.data!.docs) {
                    if (!chats.contains(privateChatsRef.doc(item.id))) {
                      chats.add(privateChatsRef.doc(item.id));
                    }
                  }
                  return StreamBuilder<QuerySnapshot>(
                      stream: usersRef
                          .doc(auth.currentUser!.uid)
                          .collection('groups')
                          .snapshots(),
                      builder: (context,
                          AsyncSnapshot<QuerySnapshot> userGroupsSnapshot) {
                        if (!userGroupsSnapshot.hasData) {
                          return const SizedBox();
                        }
                        for (var item in userGroupsSnapshot.data!.docs) {
                          if (!chats.contains(groupsRef.doc(item.id))) {
                            chats.add(groupsRef.doc(item.id));
                          }
                        }
                        return Expanded(
                            child: ListView.builder(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: chats.length,
                          itemBuilder: (context, index) {
                            return StreamBuilder(
                              stream: chats[index].snapshots(),
                              builder: (context,
                                  AsyncSnapshot<DocumentSnapshot>
                                  chatSnapshot) {
                                if (!chatSnapshot.hasData) {
                                  return const SizedBox();
                                }
                                Map<String, dynamic> data = chatSnapshot.data!.data() as Map<String, dynamic>;
                                if (data['type'] == 'privateChat') {
                                  PrivateChatModel chat = PrivateChatModel.getFromDocument(chatSnapshot.data!);
                                  return StreamBuilder(
                                    stream: usersRef
                                        .doc(chats[index].id)
                                        .snapshots(),
                                    builder: (context,
                                        AsyncSnapshot<DocumentSnapshot>
                                        userSnapshot) {
                                      if (!userSnapshot.hasData) {
                                        return const SizedBox();
                                      }
                                      UserModel chatUser =
                                      UserModel.getFromDocument(
                                          userSnapshot.data!);
                                      return Column(
                                        children: [
                                          OpenContainer(
                                            closedColor: themeColor(context),
                                            openColor: themeColor(context),
                                            useRootNavigator: true,
                                            transitionDuration: const Duration(
                                                milliseconds: 200),
                                            closedBuilder: (context, action) =>
                                                ListTile(
                                                  tileColor: onThemeColor(context)
                                                      .withOpacity(0.02),
                                                  horizontalTitleGap: 20,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(
                                                        10), // Determine the curvature of edges
                                                  ),
                                                  leading: Stack(
                                                    children: [
                                                      Container(
                                                        width: 60,
                                                        height: 60,
                                                        decoration: BoxDecoration(
                                                          border: Border.all(
                                                            width: 1,
                                                            color: chatUser.isActive
                                                                ? Colors.blue
                                                                : Colors.red,
                                                          ),
                                                          borderRadius:
                                                          BorderRadius.circular(
                                                              30),
                                                        ),
                                                        child: CircleAvatar(
                                                          backgroundColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .background,
                                                          radius: 30,
                                                          child: ClipRRect(
                                                            borderRadius:
                                                            BorderRadius
                                                                .circular(30),
                                                            child:
                                                            chatUser.imageAddress !=
                                                                ''
                                                                ? FadeInImage(
                                                              placeholder:
                                                              const AssetImage(
                                                                  'assets/images/defaultUser.jpg'),
                                                              image: NetworkImage(
                                                                  chatUser.imageAddress ??
                                                                      ''),
                                                              width: 60,
                                                              height: 60,
                                                              fit: BoxFit
                                                                  .cover,
                                                            )
                                                                : Image.asset(
                                                              'assets/images/defaultUser.jpg',
                                                              fit: BoxFit
                                                                  .cover,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Visibility(
                                                        visible: chatUser.isActive,
                                                        child: Positioned(
                                                          right: 5,
                                                          bottom: 0,
                                                          child: Container(
                                                            width: 12,
                                                            height: 12,
                                                            decoration:
                                                            BoxDecoration(
                                                              color: Colors.blue,
                                                              shape:
                                                              BoxShape.circle,
                                                              border: Border.all(
                                                                color: Theme.of(
                                                                    context)
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
                                                  title: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          chatUser.fullName!,
                                                          style: myTextStyle(
                                                              context, 18, 'bold', 1),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${chat.lastMessageTime!.toDate().hour.toString().padLeft(2, '0')}:${chat.lastMessageTime!.toDate().minute.toString().padLeft(2, '0')}',
                                                        style: TextStyle(
                                                            color: onThemeColor(context)
                                                                .withOpacity(0.6),
                                                            fontSize: 11,
                                                            fontFamily: myFontFamily,
                                                            fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                  subtitle: chat.lastMessage != null ?
                                                  StreamBuilder<
                                                      DocumentSnapshot>(
                                                    stream: chat.lastMessage!
                                                        .snapshots(),
                                                    builder: (context,
                                                        AsyncSnapshot<
                                                            DocumentSnapshot>
                                                        lastMessageSnapshot) {
                                                      if (!lastMessageSnapshot
                                                          .hasData) {
                                                        return const SizedBox();
                                                      }
                                                      MessageModel lastMessage =
                                                      MessageModel
                                                          .getFromDocument(
                                                          lastMessageSnapshot
                                                              .data!);

                                                      return StreamBuilder<
                                                          DocumentSnapshot>(
                                                        stream: lastMessage.sender!
                                                            .snapshots(),
                                                        builder: (context,
                                                            AsyncSnapshot<
                                                                DocumentSnapshot>
                                                            senderSnapshot) {
                                                          if (!senderSnapshot
                                                              .hasData) {
                                                            return const SizedBox();
                                                          }
                                                          UserModel sender =
                                                          UserModel
                                                              .getFromDocument(
                                                              senderSnapshot
                                                                  .data!);
                                                          return !chat.isTyping!
                                                              ? Row(
                                                            children: [
                                                              Text(
                                                                '${sender.fullName}: ',
                                                                style:
                                                                TextStyle(
                                                                  fontFamily:
                                                                  myFontFamily,
                                                                  color: Colors
                                                                      .blueAccent,
                                                                  fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                                  fontSize:
                                                                  14,
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  lastMessage
                                                                      .text!,
                                                                  style:
                                                                  TextStyle(
                                                                    fontFamily:
                                                                    myFontFamily,
                                                                    color: onThemeColor(
                                                                        context)
                                                                        .withOpacity(
                                                                        0.7),
                                                                    fontSize:
                                                                    12,
                                                                  ),
                                                                  overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          )
                                                              : Row(
                                                            children: [
                                                              Text(
                                                                chatUser
                                                                    .fullName!,
                                                                style:
                                                                TextStyle(
                                                                  fontFamily:
                                                                  myFontFamily,
                                                                  color: Colors
                                                                      .blueAccent,
                                                                  fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                                  fontSize:
                                                                  12,
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  ' is typing...',
                                                                  style:
                                                                  TextStyle(
                                                                    fontFamily:
                                                                    myFontFamily,
                                                                    color: onThemeColor(
                                                                        context)
                                                                        .withOpacity(
                                                                        0.7),
                                                                    fontSize:
                                                                    11,
                                                                  ),
                                                                  overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    },
                                                  )
                                                      : Text(
                                                    'No messages',
                                                    style: TextStyle(
                                                      fontFamily: myFontFamily,
                                                      color: onThemeColor(context)
                                                          .withOpacity(0.5),
                                                      fontSize: 14,
                                                    ),
                                                    overflow:
                                                    TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            openBuilder: (context, action) =>
                                                PrivateChatScreen(
                                                  otherUserRef: chat.chatRef!,
                                                ),
                                          ),
                                          const SizedBox(
                                            height: 3,
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                                else {
                                  ChatModel chat = ChatModel.getFromDocument(chatSnapshot.data!);
                                  return Column(
                                    children: [
                                      OpenContainer(
                                        closedColor: themeColor(context),
                                        openColor: themeColor(context),
                                        useRootNavigator: true,
                                        transitionDuration:
                                        const Duration(milliseconds: 200),
                                        closedBuilder: (context, action) =>
                                            ListTile(
                                              tileColor: onThemeColor(context)
                                                  .withOpacity(0.02),
                                              leading: CircleAvatar(
                                                radius: 30,
                                                child: chat.chatImageAddress != ''
                                                    ? ClipRRect(
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      30),
                                                  child: Image.network(
                                                    chat.chatImageAddress!,
                                                    width: 60,
                                                    height: 60,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                                    : Text(
                                                  chat.groupName!
                                                      .toUpperCase()
                                                      .substring(0, 1),
                                                  style: myTextStyle(
                                                      context, 20, 'bold', 1),
                                                ),
                                              ),
                                              title: Row(
                                                children: [
                                                  const Icon(Icons.group),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      chat.groupName!,
                                                      style: myTextStyle(
                                                          context, 18, 'bold', 1),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${chat.lastMessageTime!.toDate().hour.toString().padLeft(2, '0')}:${chat.lastMessageTime!.toDate().minute.toString().padLeft(2, '0')}',
                                                    style: TextStyle(
                                                        color: onThemeColor(context)
                                                            .withOpacity(0.6),
                                                        fontSize: 11,
                                                        fontFamily: myFontFamily,
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                              subtitle: chat.lastMessage != null
                                                  ? StreamBuilder<DocumentSnapshot>(
                                                stream: chat.lastMessage!
                                                    .snapshots(),
                                                builder: (context,
                                                    AsyncSnapshot<
                                                        DocumentSnapshot>
                                                    lastMessageSnapshot) {
                                                  if (!lastMessageSnapshot
                                                      .hasData) {
                                                    return const SizedBox();
                                                  }
                                                  MessageModel lastMessage =
                                                  MessageModel
                                                      .getFromDocument(
                                                      lastMessageSnapshot
                                                          .data!);

                                                  return StreamBuilder<
                                                      DocumentSnapshot>(
                                                    stream: lastMessage
                                                        .sender!
                                                        .snapshots(),
                                                    builder: (context,
                                                        AsyncSnapshot<
                                                            DocumentSnapshot>
                                                        userSnapshot) {
                                                      if (!userSnapshot
                                                          .hasData) {
                                                        return const SizedBox();
                                                      }
                                                      UserModel sender =
                                                      UserModel
                                                          .getFromDocument(
                                                          userSnapshot
                                                              .data!);
                                                      return chat.isTyping!
                                                          .isEmpty
                                                          ? Row(
                                                        children: [
                                                          Text(
                                                            '${sender.fullName}: ',
                                                            style:
                                                            TextStyle(
                                                              fontFamily:
                                                              myFontFamily,
                                                              color: Colors
                                                                  .blueAccent,
                                                              fontWeight:
                                                              FontWeight
                                                                  .bold,
                                                              fontSize:
                                                              14,
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              lastMessage
                                                                  .text!,
                                                              style:
                                                              TextStyle(
                                                                fontFamily:
                                                                myFontFamily,
                                                                color: onThemeColor(context)
                                                                    .withOpacity(0.7),
                                                                fontSize:
                                                                12,
                                                              ),
                                                              overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                          : chat.isTyping!
                                                          .length ==
                                                          1
                                                          ? Row(
                                                        children: [
                                                          Text(
                                                            '${chat.isTyping!.first['fullName']} ',
                                                            style:
                                                            TextStyle(
                                                              fontFamily:
                                                              myFontFamily,
                                                              color:
                                                              Colors.blueAccent,
                                                              fontWeight:
                                                              FontWeight.bold,
                                                              fontSize:
                                                              12,
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child:
                                                            Text(
                                                              'is typing...',
                                                              style:
                                                              TextStyle(
                                                                fontFamily:
                                                                myFontFamily,
                                                                color:
                                                                onThemeColor(context).withOpacity(0.7),
                                                                fontSize:
                                                                11,
                                                              ),
                                                              overflow:
                                                              TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                          : Row(
                                                        children: [
                                                          Text(
                                                            '${chat.isTyping!.last['fullName']} and ${(chat.isTyping!.length - 1).toString()} other people ',
                                                            style:
                                                            TextStyle(
                                                              fontFamily:
                                                              myFontFamily,
                                                              color:
                                                              Colors.blueAccent,
                                                              fontWeight:
                                                              FontWeight.bold,
                                                              fontSize:
                                                              12,
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child:
                                                            Text(
                                                              'are typing...',
                                                              style:
                                                              TextStyle(
                                                                fontFamily:
                                                                myFontFamily,
                                                                color:
                                                                onThemeColor(context).withOpacity(0.7),
                                                                fontSize:
                                                                11,
                                                              ),
                                                              overflow:
                                                              TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                              )
                                                  : Text(
                                                'No messages',
                                                style: TextStyle(
                                                  fontFamily: myFontFamily,
                                                  color: onThemeColor(context)
                                                      .withOpacity(0.5),
                                                  fontSize: 14,
                                                ),
                                                overflow:
                                                TextOverflow.ellipsis,
                                              ),
                                            ),
                                        openBuilder: (context, action) =>
                                            ChatScreen(
                                              chatRef: chat.chatRef!,
                                            ),
                                      ),
                                      const SizedBox(
                                        height: 3,
                                      ),
                                    ],
                                  );
                                }

                            },);


                          },
                        ));
                      });
                                      },
                                    )

                  //
                  //
                  //
                  //
                  //                 // if (chats.isNotEmpty) {
                  //                 //   chats.sort((a, b) => b.lastMessageTime
                  //                 //       .compareTo(a.lastMessageTime));
                  //
                  //
                  //                 return Expanded(
                  //                   child: ListView.builder(
                  //                     controller: scrollController,
                  //                     physics: const BouncingScrollPhysics(),
                  //                     itemCount: chats.length,
                  //                     itemBuilder: (context, index) {
                  //                       if (chats[index].type ==
                  //                           'privateChat') {
                  //                         PrivateChatModel chat = chats[index];
                  //                         return StreamBuilder(
                  //                           stream: usersRef
                  //                               .doc(chats[index].id)
                  //                               .snapshots(),
                  //                           builder: (context,
                  //                               AsyncSnapshot<DocumentSnapshot>
                  //                               userSnapshot) {
                  //                             if (!userSnapshot.hasData) {
                  //                               return const SizedBox();
                  //                             }
                  //                             UserModel chatUser =
                  //                             UserModel.getFromDocument(
                  //                                 userSnapshot.data!);
                  //                             return Column(
                  //                               children: [
                  //                                 OpenContainer(
                  //                                   closedColor:
                  //                                   themeColor(context),
                  //                                   openColor:
                  //                                   themeColor(context),
                  //                                   useRootNavigator: true,
                  //                                   transitionDuration:
                  //                                   const Duration(
                  //                                       milliseconds: 200),
                  //                                   closedBuilder:
                  //                                       (context, action) =>
                  //                                       ListTile(
                  //                                         tileColor: onThemeColor(
                  //                                             context)
                  //                                             .withOpacity(0.02),
                  //                                         horizontalTitleGap: 20,
                  //                                         shape:
                  //                                         RoundedRectangleBorder(
                  //                                           borderRadius:
                  //                                           BorderRadius.circular(
                  //                                               10), // Determine the curvature of edges
                  //                                         ),
                  //                                         leading: Stack(
                  //                                           children: [
                  //                                             Container(
                  //                                               width: 60,
                  //                                               height: 60,
                  //                                               decoration: BoxDecoration(
                  //                                                 border: Border.all(width: 1,
                  //                                                   color: chatUser.isActive ? Colors.blue : Colors.red,),
                  //                                                 borderRadius: BorderRadius.circular(30),
                  //                                               ),
                  //                                               child: CircleAvatar(
                  //                                                 backgroundColor:
                  //                                                 Theme.of(
                  //                                                     context)
                  //                                                     .colorScheme
                  //                                                     .background,
                  //                                                 radius: 30,
                  //                                                 child: ClipRRect(
                  //                                                   borderRadius:
                  //                                                   BorderRadius
                  //                                                       .circular(
                  //                                                       30),
                  //                                                   child: chatUser
                  //                                                       .imageAddress !=
                  //                                                       ''
                  //                                                       ? FadeInImage(
                  //                                                     placeholder:
                  //                                                     const AssetImage(
                  //                                                         'assets/images/defaultUser.jpg'),
                  //                                                     image: NetworkImage(
                  //                                                         chatUser.imageAddress ??
                  //                                                             ''),
                  //                                                     width: 60,
                  //                                                     height:
                  //                                                     60,
                  //                                                     fit: BoxFit
                  //                                                         .cover,
                  //                                                   )
                  //                                                       : Image.asset(
                  //                                                     'assets/images/defaultUser.jpg',
                  //                                                     fit: BoxFit
                  //                                                         .cover,
                  //                                                   ),
                  //                                                 ),
                  //                                               ),
                  //                                             ),
                  //                                             Visibility(
                  //                                               visible: chatUser
                  //                                                   .isActive,
                  //                                               child: Positioned(
                  //                                                 right: 5,
                  //                                                 bottom: 0,
                  //                                                 child: Container(
                  //                                                   width: 12,
                  //                                                   height: 12,
                  //                                                   decoration:
                  //                                                   BoxDecoration(
                  //                                                     color: Colors
                  //                                                         .blue,
                  //                                                     shape: BoxShape
                  //                                                         .circle,
                  //                                                     border: Border
                  //                                                         .all(
                  //                                                       color: Theme.of(
                  //                                                           context)
                  //                                                           .colorScheme
                  //                                                           .onBackground,
                  //                                                       width: 1,
                  //                                                     ),
                  //                                                   ),
                  //                                                 ),
                  //                                               ),
                  //                                             ),
                  //                                           ],
                  //                                         ),
                  //                                         title: Text(
                  //                                           chatUser.fullName!,
                  //                                           style: myTextStyle(
                  //                                               context,
                  //                                               18,
                  //                                               'bold',
                  //                                               1),
                  //                                         ),
                  //                                         subtitle: StreamBuilder<
                  //                                             DocumentSnapshot>(
                  //                                           stream: chat
                  //                                               .lastMessage!
                  //                                               .snapshots(),
                  //                                           builder: (context,
                  //                                               AsyncSnapshot<
                  //                                                   DocumentSnapshot>
                  //                                               lastMessageSnapshot) {
                  //                                             if (!lastMessageSnapshot
                  //                                                 .hasData) {
                  //                                               return const SizedBox();
                  //                                             }
                  //                                             MessageModel
                  //                                             lastMessage =
                  //                                             MessageModel
                  //                                                 .getFromDocument(
                  //                                                 lastMessageSnapshot
                  //                                                     .data!);
                  //
                  //                                             return StreamBuilder<
                  //                                                 DocumentSnapshot>(
                  //                                               stream: lastMessage
                  //                                                   .sender!
                  //                                                   .snapshots(),
                  //                                               builder: (context,
                  //                                                   AsyncSnapshot<
                  //                                                       DocumentSnapshot>
                  //                                                   senderSnapshot) {
                  //                                                 if (!senderSnapshot
                  //                                                     .hasData) {
                  //                                                   return const SizedBox();
                  //                                                 }
                  //                                                 UserModel sender =
                  //                                                 UserModel.getFromDocument(
                  //                                                     senderSnapshot
                  //                                                         .data!);
                  //                                                 return !chat
                  //                                                     .isTyping!
                  //                                                     ? Row(
                  //                                                   children: [
                  //                                                     Text(
                  //                                                       '${sender.fullName}: ',
                  //                                                       style:
                  //                                                       TextStyle(
                  //                                                         fontFamily:
                  //                                                         myFontFamily,
                  //                                                         color:
                  //                                                         Colors.blueAccent,
                  //                                                         fontWeight:
                  //                                                         FontWeight.bold,
                  //                                                         fontSize:
                  //                                                         14,
                  //                                                       ),
                  //                                                     ),
                  //                                                     Expanded(
                  //                                                       child:
                  //                                                       Text(
                  //                                                         lastMessage.text!,
                  //                                                         style:
                  //                                                         TextStyle(
                  //                                                           fontFamily: myFontFamily,
                  //                                                           color: onThemeColor(context).withOpacity(0.7),
                  //                                                           fontSize: 12,
                  //                                                         ),
                  //                                                         overflow:
                  //                                                         TextOverflow.ellipsis,
                  //                                                       ),
                  //                                                     ),
                  //                                                   ],
                  //                                                 )
                  //                                                     : Row(
                  //                                                   children: [
                  //                                                     Text(
                  //                                                       chatUser
                  //                                                           .fullName!,
                  //                                                       style:
                  //                                                       TextStyle(
                  //                                                         fontFamily:
                  //                                                         myFontFamily,
                  //                                                         color:
                  //                                                         Colors.blueAccent,
                  //                                                         fontWeight:
                  //                                                         FontWeight.bold,
                  //                                                         fontSize:
                  //                                                         12,
                  //                                                       ),
                  //                                                     ),
                  //                                                     Expanded(
                  //                                                       child:
                  //                                                       Text(
                  //                                                         ' is typing...',
                  //                                                         style:
                  //                                                         TextStyle(
                  //                                                           fontFamily: myFontFamily,
                  //                                                           color: onThemeColor(context).withOpacity(0.7),
                  //                                                           fontSize: 11,
                  //                                                         ),
                  //                                                         overflow:
                  //                                                         TextOverflow.ellipsis,
                  //                                                       ),
                  //                                                     ),
                  //                                                   ],
                  //                                                 );
                  //                                               },
                  //                                             );
                  //                                           },
                  //                                         ),
                  //                                       ),
                  //                                   openBuilder:
                  //                                       (context, action) =>
                  //                                       PrivateChatScreen(
                  //                                         otherUserRef:
                  //                                         chat.chatRef!,
                  //                                       ),
                  //                                 ),
                  //                                 const SizedBox(
                  //                                   height: 3,
                  //                                 ),
                  //                               ],
                  //                             );
                  //                           },
                  //                         );
                  //                       } else {
                  //                         ChatModel chat = chats[index];
                  //                         return Column(
                  //                           children: [
                  //                             OpenContainer(
                  //                               closedColor:
                  //                               themeColor(context),
                  //                               openColor: themeColor(context),
                  //                               useRootNavigator: true,
                  //                               transitionDuration:
                  //                               const Duration(
                  //                                   milliseconds: 200),
                  //                               closedBuilder:
                  //                                   (context, action) =>
                  //                                   ListTile(
                  //                                     tileColor:
                  //                                     onThemeColor(context)
                  //                                         .withOpacity(0.02),
                  //                                     leading: CircleAvatar(
                  //                                       radius: 30,
                  //                                       child:
                  //                                       chat.chatImageAddress !=
                  //                                           ''
                  //                                           ? ClipRRect(
                  //                                         borderRadius:
                  //                                         BorderRadius
                  //                                             .circular(
                  //                                             30),
                  //                                         child: Image
                  //                                             .network(
                  //                                           chat.chatImageAddress!,
                  //                                           width: 60,
                  //                                           height: 60,
                  //                                           fit: BoxFit
                  //                                               .cover,
                  //                                         ),
                  //                                       )
                  //                                           : Text(
                  //                                         chat.groupName!
                  //                                             .toUpperCase()
                  //                                             .substring(
                  //                                             0, 1),
                  //                                         style:
                  //                                         myTextStyle(
                  //                                             context,
                  //                                             20,
                  //                                             'bold',
                  //                                             1),
                  //                                       ),
                  //                                     ),
                  //                                     title: Row(
                  //                                       children: [
                  //                                         const Icon(Icons.group),
                  //                                         const SizedBox(
                  //                                           width: 5,
                  //                                         ),
                  //                                         Text(
                  //                                           chat.groupName!,
                  //                                           style: myTextStyle(
                  //                                               context,
                  //                                               18,
                  //                                               'bold',
                  //                                               1),
                  //                                         ),
                  //                                       ],
                  //                                     ),
                  //                                     subtitle:
                  //                                     chat.lastMessage != null
                  //                                         ? StreamBuilder<
                  //                                         DocumentSnapshot>(
                  //                                       stream: chat
                  //                                           .lastMessage!
                  //                                           .snapshots(),
                  //                                       builder: (context,
                  //                                           AsyncSnapshot<
                  //                                               DocumentSnapshot>
                  //                                           lastMessageSnapshot) {
                  //                                         if (!lastMessageSnapshot
                  //                                             .hasData) {
                  //                                           return const SizedBox();
                  //                                         }
                  //                                         MessageModel
                  //                                         lastMessage =
                  //                                         MessageModel.getFromDocument(
                  //                                             lastMessageSnapshot
                  //                                                 .data!);
                  //
                  //                                         return StreamBuilder<
                  //                                             DocumentSnapshot>(
                  //                                           stream: lastMessage
                  //                                               .sender!
                  //                                               .snapshots(),
                  //                                           builder: (context,
                  //                                               AsyncSnapshot<
                  //                                                   DocumentSnapshot>
                  //                                               userSnapshot) {
                  //                                             if (!userSnapshot
                  //                                                 .hasData) {
                  //                                               return const SizedBox();
                  //                                             }
                  //                                             UserModel
                  //                                             sender =
                  //                                             UserModel.getFromDocument(
                  //                                                 userSnapshot.data!);
                  //                                             return chat
                  //                                                 .isTyping!
                  //                                                 .isEmpty
                  //                                                 ? Row(
                  //                                               children: [
                  //                                                 Text(
                  //                                                   '${sender.fullName}: ',
                  //                                                   style: TextStyle(
                  //                                                     fontFamily: myFontFamily,
                  //                                                     color: Colors.blueAccent,
                  //                                                     fontWeight: FontWeight.bold,
                  //                                                     fontSize: 14,
                  //                                                   ),
                  //                                                 ),
                  //                                                 Expanded(
                  //                                                   child: Text(
                  //                                                     lastMessage.text!,
                  //                                                     style: TextStyle(
                  //                                                       fontFamily: myFontFamily,
                  //                                                       color: onThemeColor(context).withOpacity(0.7),
                  //                                                       fontSize: 12,
                  //                                                     ),
                  //                                                     overflow: TextOverflow.ellipsis,
                  //                                                   ),
                  //                                                 ),
                  //                                               ],
                  //                                             )
                  //                                                 : chat.isTyping!.length ==
                  //                                                 1
                  //                                                 ? Row(
                  //                                               children: [
                  //                                                 Text(
                  //                                                   '${chat.isTyping!.first['fullName']} ',
                  //                                                   style: TextStyle(
                  //                                                     fontFamily: myFontFamily,
                  //                                                     color: Colors.blueAccent,
                  //                                                     fontWeight: FontWeight.bold,
                  //                                                     fontSize: 12,
                  //                                                   ),
                  //                                                 ),
                  //                                                 Expanded(
                  //                                                   child: Text(
                  //                                                     'is typing...',
                  //                                                     style: TextStyle(
                  //                                                       fontFamily: myFontFamily,
                  //                                                       color: onThemeColor(context).withOpacity(0.7),
                  //                                                       fontSize: 11,
                  //                                                     ),
                  //                                                     overflow: TextOverflow.ellipsis,
                  //                                                   ),
                  //                                                 ),
                  //                                               ],
                  //                                             )
                  //                                                 : Row(
                  //                                               children: [
                  //                                                 Text(
                  //                                                   '${chat.isTyping!.last['fullName']} and ${(chat.isTyping!.length - 1).toString()} other people ',
                  //                                                   style: TextStyle(
                  //                                                     fontFamily: myFontFamily,
                  //                                                     color: Colors.blueAccent,
                  //                                                     fontWeight: FontWeight.bold,
                  //                                                     fontSize: 12,
                  //                                                   ),
                  //                                                 ),
                  //                                                 Expanded(
                  //                                                   child: Text(
                  //                                                     'are typing...',
                  //                                                     style: TextStyle(
                  //                                                       fontFamily: myFontFamily,
                  //                                                       color: onThemeColor(context).withOpacity(0.7),
                  //                                                       fontSize: 11,
                  //                                                     ),
                  //                                                     overflow: TextOverflow.ellipsis,
                  //                                                   ),
                  //                                                 ),
                  //                                               ],
                  //                                             );
                  //                                           },
                  //                                         );
                  //                                       },
                  //                                     )
                  //                                         : Text(
                  //                                       'No messages',
                  //                                       style: TextStyle(
                  //                                         fontFamily:
                  //                                         myFontFamily,
                  //                                         color: Colors
                  //                                             .red[800]!
                  //                                             .withOpacity(
                  //                                             0.5),
                  //                                         fontSize: 11,
                  //                                       ),
                  //                                       overflow:
                  //                                       TextOverflow
                  //                                           .ellipsis,
                  //                                     ),
                  //                                   ),
                  //                               openBuilder:
                  //                                   (context, action) =>
                  //                                   ChatScreen(
                  //                                     chatRef: chat.chatRef!,
                  //                                   ),
                  //                             ),
                  //                             const SizedBox(
                  //                               height: 3,
                  //                             ),
                  //                           ],
                  //                         );
                  //                       }
                  //                     },
                  //                   ),
                  //                 );
                  //
                  //                 return Expanded(
                  //                   child: Column(
                  //                     mainAxisAlignment:
                  //                     MainAxisAlignment.center,
                  //                     children: [
                  //                       Text(
                  //                         'Have no Message yet',
                  //                         style: myTextStyle(
                  //                             context, 30, 'bold', 1),
                  //                       ),
                  //                       const SizedBox(
                  //                         height: 10,
                  //                       ),
                  //                       Row(
                  //                         mainAxisAlignment:
                  //                         MainAxisAlignment.center,
                  //                         children: [
                  //                           Text(
                  //                             'Tap',
                  //                             style: myTextStyle(
                  //                                 context, 16, 'normal', 0.5),
                  //                           ),
                  //                           const SizedBox(
                  //                             width: 10,
                  //                           ),
                  //                           const Icon(
                  //                             Iconsax.message,
                  //                             size: 20,
                  //                           ),
                  //                           const SizedBox(
                  //                             width: 10,
                  //                           ),
                  //                           Text(
                  //                             'to start messaging with your contacts',
                  //                             style: myTextStyle(
                  //                                 context, 16, 'normal', 0.5),
                  //                           ),
                  //                         ],
                  //                       ),
                  //                     ],
                  //                   ),
                  //                 );
                  //
                  //
                  //
                  //
                  //
                  //
                  //
                  //
                  //
                  //               });
                  //         }),
                  //   ],
                  // ),

                  // ),
                ],
              ),
            );
          }),
    );
  }

  takeSnapshot(DocumentReference ref) async {
    return await ref.get();
  }
}
