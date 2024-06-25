import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:iconsax/iconsax.dart';
import 'package:infinity_messenger/core/constants.dart';
import 'package:infinity_messenger/models/message_model.dart';
import 'package:infinity_messenger/models/private_chat_model.dart';
import 'package:infinity_messenger/models/user_model.dart';
import 'package:infinity_messenger/screens/contact_profile.dart';
import 'package:infinity_messenger/widgets/base_widget.dart';
import 'package:infinity_messenger/widgets/custom_text_filed.dart';
import 'package:lottie/lottie.dart';

class PrivateChatScreen extends StatefulWidget {
  final DocumentReference otherUserRef;

  const PrivateChatScreen({
    super.key,
    required this.otherUserRef,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  late CollectionReference usersRef;
  late FocusNode _focusNode;

  TextEditingController sendMessageController = TextEditingController();
  ScrollController scrollController = ScrollController();

  UserModel? chatUser;
  PrivateChatModel? chatData;

  bool isEditing = false;
  bool isReplying = false;
  bool isTyping = false;

  MessageModel? messageOnTaped;
  String? messageOnTapedSender;
  String? messageId;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    usersRef = fireStore.collection('Users');
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() async{
    if (_focusNode.hasFocus) {
      await usersRef
          .doc(chatUser!.id)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .update({
        'isTyping': true,
      });
    }
    else{
      await usersRef
          .doc(chatUser!.id)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .update({
        'isTyping': false,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: widget.otherUserRef.snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> otherUserSnapshot) {
          if (!otherUserSnapshot.hasData) {
            return Center(child: showLoading(context));
          }

          UserModel otherUser =
          UserModel.getFromDocument(otherUserSnapshot.data!);
          chatUser = otherUser;
          String lastSeen = getLastSeen(
            otherUser.isActive,
            otherUser.lastSeen!.toDate(),
          );

        return BaseWidget(
            padding: 10,
            appBar: AppBar(
                elevation: 10,
                toolbarHeight: 75,
                shadowColor: onThemeColor(context).withOpacity(0.25),
                title: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: OpenContainer(
                        closedColor: onThemeColor(context).withOpacity(0.07),
                        openColor: onThemeColor(context).withOpacity(0.07),
                        useRootNavigator: true,
                        transitionDuration:
                        const Duration(
                            milliseconds: 300),
                        closedBuilder: (context, action) => CircleAvatar(
                          backgroundColor: themeColor(context),
                          radius: 30,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: otherUser.imageAddress != ''
                                ? FadeInImage(
                                placeholder: const AssetImage(
                                    'assets/images/defaultUser.jpg'),
                                image: NetworkImage(
                                  otherUser.imageAddress ?? '',
                                ),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover)
                                : Image.asset(
                              'assets/images/defaultUser.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        openBuilder: (context, action) =>
                            ContactProfileScreen(userRef: widget.otherUserRef),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherUser.fullName ?? '',
                          style: myTextStyle(context, 16, 'bold', 1),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          isTyping ? 'is typing ...': lastSeen,
                          style: (isTyping == true || lastSeen == 'Online')
                              ? TextStyle(
                              fontFamily: myFontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)
                              : myTextStyle(context, 12, 'normal', 1),
                        ),
                      ],
                    ),
                  ],
                )
            ),
            child: Column(
              children: [
                const SizedBox(
                  height: 5,
                ),
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                      stream: usersRef
                          .doc(auth.currentUser!.uid)
                          .collection('chats')
                          .doc(chatUser!.id)
                          .snapshots(),
                      builder: (context, AsyncSnapshot<DocumentSnapshot> chatSnapshot) {
                        if(!chatSnapshot.hasData){
                          return Center(child: showLoading(context));
                        }
                        if (chatSnapshot.data!.exists) {
                          PrivateChatModel chat = PrivateChatModel.getFromDocument(chatSnapshot.data!);
                          isTyping = chat.isTyping!;
                          chatData = chat;
                          return StreamBuilder<QuerySnapshot>(
                              stream: usersRef
                                  .doc(auth.currentUser!.uid)
                                  .collection('chats')
                                  .doc(chatUser!.id)
                                  .collection('messages')
                                  .orderBy('dateTime', descending: true)
                                  .snapshots(),
                              builder: (context,
                                  AsyncSnapshot<QuerySnapshot> messageSnapshot) {
                                if (!messageSnapshot.hasData) {
                                  return const SizedBox();
                                }
                                if (messageSnapshot.data!.docs.isNotEmpty) {
                                  return ListView.builder(
                                      itemCount: messageSnapshot.data!.docs.length,
                                      controller: scrollController,
                                      physics: const BouncingScrollPhysics(),
                                      reverse: true,
                                      itemBuilder: (context, index) {
                                        MessageModel message =
                                        MessageModel.getFromDocument(messageSnapshot.data!.docs[index]);
                                        return StreamBuilder(
                                          stream: message.sender!.snapshots(),
                                          builder: (context,
                                              AsyncSnapshot<DocumentSnapshot>
                                              senderSnapshot) {
                                            if (!senderSnapshot.hasData) {
                                              return const SizedBox();
                                            }
                                            UserModel sender = UserModel.getFromDocument(senderSnapshot.data!);
                                            bool isMe =
                                                sender.id == auth.currentUser!.uid;
                                            return SingleChildScrollView(
                                              child: Row(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                mainAxisAlignment: isMe
                                                    ? MainAxisAlignment.end
                                                    : MainAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    width: MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                        100,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        messageOnTaped = message;
                                                        messageId = messageSnapshot
                                                            .data!.docs[index].id;
                                                        messageOnTapedSender =
                                                            sender.fullName;
                                                        messageOnTap(isMe);
                                                      },
                                                      child: ChatBubble(
                                                        clipper: ChatBubbleClipper5(
                                                            type: isMe
                                                                ? BubbleType
                                                                .sendBubble
                                                                : BubbleType
                                                                .receiverBubble),
                                                        margin: EdgeInsets.only(
                                                          bottom: 8,
                                                          top: 8,
                                                          right: isMe ? 0 : 20,
                                                          left: isMe ? 20 : 0,
                                                        ),
                                                        alignment: isMe
                                                            ? Alignment.bottomRight
                                                            : Alignment.bottomLeft,
                                                        backGroundColor: isMe
                                                            ? Colors.blue
                                                            .withOpacity(0.75)
                                                            : onThemeColor(context)
                                                            .withOpacity(0.5),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                          CrossAxisAlignment.end,
                                                          children: [
                                                            Column(
                                                              crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                              children: [
                                                                Visibility(
                                                                  visible: !isMe,
                                                                  child: Column(
                                                                    children: [
                                                                      Row(
                                                                        mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                        mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .start,
                                                                        children: [
                                                                          Text(
                                                                            '${sender.fullName} :',
                                                                            style: TextStyle(
                                                                                color: themeColor(context)
                                                                                    .withOpacity(
                                                                                    0.6),
                                                                                fontSize:
                                                                                12,
                                                                                fontFamily:
                                                                                myFontFamily,
                                                                                fontWeight:
                                                                                FontWeight.bold),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      const SizedBox(
                                                                        height: 5,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                Visibility(
                                                                  visible: message.reply != null,
                                                                  child: message.reply !=
                                                                      null
                                                                      ? StreamBuilder<
                                                                      DocumentSnapshot>(
                                                                      stream: message.reply!
                                                                          .snapshots(),
                                                                      builder: (context,
                                                                          AsyncSnapshot<DocumentSnapshot>
                                                                          replySnapshot) {
                                                                        if (!replySnapshot
                                                                            .hasData) {
                                                                          return const SizedBox();
                                                                        }
                                                                        MessageModel reply = MessageModel.getFromDocument(replySnapshot.data!);
                                                                        return Column(
                                                                          children: [
                                                                            Container(
                                                                              decoration:
                                                                              BoxDecoration(
                                                                                color: Colors.green[800],
                                                                                borderRadius: BorderRadius.circular(10),
                                                                              ),
                                                                              child:
                                                                              Container(
                                                                                decoration: BoxDecoration(
                                                                                  borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
                                                                                  color: themeColor(context),
                                                                                ),
                                                                                margin: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                                                                                child: Container(
                                                                                  padding: const EdgeInsets.all(10),
                                                                                  decoration: BoxDecoration(borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)), color: Colors.green[600]!.withOpacity(0.2)),
                                                                                  child: Row(
                                                                                    mainAxisSize: MainAxisSize.min,
                                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                                    children: [
                                                                                      Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        children: [
                                                                                          Row(
                                                                                            children: [
                                                                                              StreamBuilder<DocumentSnapshot>(
                                                                                                  stream: reply.sender!.snapshots(),
                                                                                                  builder: (context, AsyncSnapshot<DocumentSnapshot> replySenderSnapshot) {
                                                                                                    if (!replySenderSnapshot.hasData) {
                                                                                                      return const SizedBox();
                                                                                                    }
                                                                                                    UserModel replySender = UserModel.getFromDocument(replySenderSnapshot.data!);
                                                                                                    return Text(
                                                                                                      replySender.fullName!.length < 33 ? '${replySender.fullName}: ' : '${replySender.fullName!.substring(0, 33)}...',
                                                                                                      style: TextStyle(
                                                                                                        color: Colors.green[800],
                                                                                                        fontFamily: myFontFamily,
                                                                                                        fontWeight: FontWeight.bold,
                                                                                                        fontSize: 12,
                                                                                                      ),
                                                                                                    );
                                                                                                  }),
                                                                                            ],
                                                                                          ),
                                                                                          const SizedBox(
                                                                                            height: 5,
                                                                                          ),
                                                                                          Row(
                                                                                            children: [
                                                                                              Text(
                                                                                                reply.text!.length < 33 ? reply.text ?? '' : '${reply.text!.substring(0, 33)}...',
                                                                                                style: TextStyle(
                                                                                                  fontFamily: myFontFamily,
                                                                                                  fontSize: 14,
                                                                                                  fontWeight: FontWeight.bold,
                                                                                                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                                                                                                ),
                                                                                                overflow: TextOverflow.ellipsis,
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(
                                                                              height:
                                                                              5,
                                                                            ),
                                                                          ],
                                                                        );
                                                                      })
                                                                      : const SizedBox(),
                                                                ),
                                                                Text(
                                                                  message.text ?? '',
                                                                  textAlign:
                                                                  TextAlign.start,
                                                                  style: TextStyle(
                                                                    color: isMe
                                                                        ? onThemeColor(context)
                                                                        : themeColor(context),
                                                                    fontFamily:
                                                                    myFontFamily,
                                                                    fontSize: 14,
                                                                    fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height: 5,
                                                            ),
                                                            Row(
                                                              mainAxisSize:
                                                              MainAxisSize.min,
                                                              mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                              children: [
                                                                Visibility(
                                                                  visible: message.edited!,
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                        Icons.edit,
                                                                        color: isMe
                                                                            ? onThemeColor(context)
                                                                            .withOpacity(
                                                                            0.6)
                                                                            : themeColor(context)
                                                                            .withOpacity(
                                                                            0.6),
                                                                        size: 12,
                                                                      ),
                                                                      Text(
                                                                        'Edited, ',
                                                                        style: TextStyle(
                                                                            color: isMe
                                                                                ? onThemeColor(context)
                                                                                .withOpacity(
                                                                                0.6)
                                                                                : themeColor(context)
                                                                                .withOpacity(
                                                                                0.6),
                                                                            fontSize:
                                                                            10,
                                                                            fontFamily:
                                                                            myFontFamily,
                                                                            fontWeight:
                                                                            FontWeight
                                                                                .bold),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                Text(
                                                                  '${message.dateTime!.toDate().hour.toString().padLeft(2, '0')}:${message.dateTime!.toDate().minute.toString().padLeft(2, '0')}',
                                                                  style: TextStyle(
                                                                      color: isMe
                                                                          ? onThemeColor(context)
                                                                          .withOpacity(
                                                                          0.6)
                                                                          : themeColor(context)
                                                                          .withOpacity(
                                                                          0.6),
                                                                      fontSize: 11,
                                                                      fontFamily:
                                                                      myFontFamily,
                                                                      fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      });
                                }
                                else {
                                  return Center(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: onThemeColor(context)
                                                  .withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(25),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              children: [
                                                InkWell(
                                                  hoverColor: Colors.transparent,
                                                  onTap: () async {
                                                    await creatMessage(
                                                        'Hello ${otherUser.fullName}');
                                                  },
                                                  child: Lottie.asset(
                                                    'assets/animations/say_hello.json',
                                                    width: 300,
                                                    height: 300,
                                                  ),
                                                ),
                                                Text(
                                                  'No message yet',
                                                  style: myTextStyle(
                                                      context, 12, 'normal', 1),
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                Text(
                                                  'Tap the robot to say hello',
                                                  style: myTextStyle(
                                                      context, 14, 'bold', 1),
                                                ),
                                                const SizedBox(
                                                  height: 30,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              });
                        }
                        else{
                          return Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: onThemeColor(context)
                                          .withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        InkWell(
                                          hoverColor: Colors.transparent,
                                          onTap: () async {
                                            await creatMessage(
                                                'Hello ${otherUser.fullName}');
                                          },
                                          child: Lottie.asset(
                                            'assets/animations/say_hello.json',
                                            width: 300,
                                            height: 300,
                                          ),
                                        ),
                                        Text(
                                          'No message yet',
                                          style: myTextStyle(
                                              context, 12, 'normal', 1),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          'Tap the robot to say hello',
                                          style: myTextStyle(
                                              context, 14, 'bold', 1),
                                        ),
                                        const SizedBox(
                                          height: 30,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                    }
                  ),
                ),
                Column(
                  children: [
                    const SizedBox(
                      height: 5,
                    ),
                    Visibility(
                      visible: isEditing,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: themeColor(context),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      color: onThemeColor(context),
                                      size: 25,
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      'Edit',
                                      style: TextStyle(
                                        color: onThemeColor(context),
                                        fontFamily: myFontFamily,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Container(
                                  width: 5,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Me',
                                              style: TextStyle(
                                                fontFamily: myFontFamily,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: onThemeColor(context),
                                              ),
                                            ),
                                            Divider(
                                              color: Colors.amber[800],
                                            ),
                                            Text(
                                              (messageOnTaped != null)
                                                  ? messageOnTaped!.text ?? ''
                                                  : '',
                                              style: TextStyle(
                                                fontFamily: myFontFamily,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: onThemeColor(context),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => closeEditingMessage(),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: isReplying,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: onThemeColor(context),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    Icon(
                                      Icons.reply,
                                      color: onThemeColor(context),
                                      size: 25,
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      'Reply',
                                      style: TextStyle(
                                        color: onThemeColor(context),
                                        fontFamily: myFontFamily,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Container(
                                  width: 5,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.lightGreen,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (messageOnTaped != null)
                                                  ? messageOnTaped!.sender == usersRef.doc(auth.currentUser!.uid)? 'Me :':
                                              '$messageOnTapedSender :'
                                                  : '',
                                              style: TextStyle(
                                                fontFamily: myFontFamily,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: onThemeColor(context),
                                              ),
                                            ),
                                            Divider(
                                              color: Colors.lightGreen[800],
                                            ),
                                            Text(
                                              (messageOnTaped != null)
                                                  ? messageOnTaped!.text ?? ''
                                                  : '',
                                              style: TextStyle(
                                                fontFamily: myFontFamily,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: onThemeColor(context),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => closeReplyMessage(),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            focusNode: _focusNode,
                            controller: sendMessageController,
                            hint: 'Send Message',
                            maxLines: null,
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        SizedBox(
                          child: IconButton(
                              onPressed: () {
                                isEditing ? editMessage() : sendMessage();
                              },
                              icon: Icon(
                                isEditing ? Iconsax.edit : Icons.send,
                                size: 30,
                                color: Colors.blue,
                              )),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ],
            ),
          );
      }
    );
  }

  void sendMessage() async {
    if (sendMessageController.text.isNotEmpty) {
      String text = sendMessageController.text.trim();
      sendMessageController.clear();
      await creatMessage(text);
      scrollController.animateTo(scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 50),
          curve: Curves.bounceInOut);
    }
  }

  creatMessage(String text) async {
    Map<String, dynamic> newMessageForMe = {};
    newMessageForMe['Sender'] = usersRef.doc(auth.currentUser!.uid);
    newMessageForMe['dateTime'] = DateTime.now();
    newMessageForMe['text'] = text;
    newMessageForMe['edited'] = false;
    isReplying
        ? newMessageForMe['reply'] = usersRef
            .doc(auth.currentUser!.uid)
            .collection('chats')
            .doc(chatUser!.id)
            .collection('messages')
            .doc(messageId)
        : newMessageForMe['reply'] = null;

    Map<String, dynamic> newMessageForOther = {};
    newMessageForOther['Sender'] = usersRef.doc(auth.currentUser!.uid);
    newMessageForOther['dateTime'] = DateTime.now();
    newMessageForOther['text'] = text;
    newMessageForOther['edited'] = false;
    isReplying
        ? newMessageForOther['reply'] = usersRef
        .doc(chatUser!.id)
        .collection('chats')
        .doc(auth.currentUser!.uid)
        .collection('messages')
        .doc(messageId)
        : newMessageForOther['reply'] = null;
    closeReplyMessage();

    DocumentReference lastMessageRef = await usersRef
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(chatUser!.id)
        .collection('messages')
        .add(newMessageForMe);
    await usersRef
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(chatUser!.id)
        .get()
        .then((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) async {
      if (documentSnapshot.exists) {
        await usersRef
            .doc(auth.currentUser!.uid)
            .collection('chats')
            .doc(chatUser!.id)
            .update({
          'lastMessageTime': DateTime.now(),
          'lastMessage': lastMessageRef
        });
      } else {
        await usersRef
            .doc(auth.currentUser!.uid)
            .collection('chats')
            .doc(chatUser!.id)
            .set({
          'id': chatUser!.id,
          'type':'privateChat',
          'isTyping': false,
          'chatRef': widget.otherUserRef,
          'lastMessageTime': DateTime.now(),
          'lastMessage': lastMessageRef
        });
      }
    });

    await usersRef
        .doc(chatUser!.id)
        .collection('chats')
        .doc(auth.currentUser!.uid)
        .collection('messages')
        .doc(lastMessageRef.id).set(newMessageForOther);
    await usersRef
        .doc(chatUser!.id)
        .collection('chats')
        .doc(auth.currentUser!.uid)
        .get()
        .then((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) async {
      if (documentSnapshot.exists) {
        await usersRef
            .doc(chatUser!.id)
            .collection('chats')
            .doc(auth.currentUser!.uid)
            .update({
          'lastMessageTime': DateTime.now(),
          'lastMessage': lastMessageRef
        });
      } else {
        await usersRef
            .doc(chatUser!.id)
            .collection('chats')
            .doc(auth.currentUser!.uid)
            .set({
          'id': auth.currentUser!.uid,
          'type':'privateChat',
          'isTyping': false,
          'chatRef': usersRef.doc(auth.currentUser!.uid),
          'lastMessageTime': DateTime.now(),
          'lastMessage': lastMessageRef
        });
      }
    });
  }

  messageOnTap(bool isMe) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            themeColor(context).withOpacity(0.85),
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () {
                replyMessageOnTap(messageOnTaped!);
              },
              label: const Text('Reply'),
              icon: const Icon(Icons.reply),
            ),
            Visibility(visible: isMe, child: const Divider()),
            Visibility(
              visible: isMe,
              child: Column(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      editMessageOnTap(messageOnTaped!);
                    },
                    label: const Text('Edit'),
                    icon: const Icon(Iconsax.edit5),
                  ),
                  const Divider(),
                ],
              ),
            ),
            Visibility(
              visible: isMe,
              child: TextButton.icon(
                onPressed: () {
                  deleteMessageOnTap();
                },
                label: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                icon: const Icon(
                  Iconsax.trash,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  editMessageOnTap(MessageModel message) {
    Navigator.pop(context);
    messageOnTaped = message;
    isReplying = false;
    isEditing = true;
    sendMessageController.text = messageOnTaped!.text ?? '';
    setState(() {});
  }

  replyMessageOnTap(MessageModel message) {
    Navigator.pop(context);
    messageOnTaped = message;
    isEditing = false;
    isReplying = true;
    setState(() {});
  }

  deleteMessageOnTap() async {
    await usersRef
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(chatUser!.id)
        .collection('messages')
        .doc(messageId)
        .delete();
    await usersRef
        .doc(chatUser!.id)
        .collection('chats')
        .doc(auth.currentUser!.uid)
        .collection('messages')
        .doc(messageId)
        .delete();
    Navigator.pop(context);
  }

  editMessage() {
    if (messageOnTaped!.text != sendMessageController.text) {
      usersRef
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(chatUser!.id)
          .collection('messages')
          .doc(messageId)
          .update(
        {
          'text': sendMessageController.text,
          'edited': true,
        },
      );
      usersRef
          .doc(chatUser!.id)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .collection('messages')
          .doc(messageId)
          .update(
        {
          'text': sendMessageController.text,
          'edited': true,
        },
      );
      closeEditingMessage();
    }
  }

  closeEditingMessage() {
    isEditing = false;
    messageOnTaped = null;
    messageOnTapedSender = null;
    messageId = null;
    sendMessageController.clear();
    setState(() {});
  }

  closeReplyMessage() {
    isReplying = false;
    messageOnTaped = null;
    messageOnTapedSender = null;
    messageId = null;
    setState(() {});
  }
}
