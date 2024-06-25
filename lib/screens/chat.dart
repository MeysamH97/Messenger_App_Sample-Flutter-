
import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:iconsax/iconsax.dart';
import 'package:infinity_messenger/core/constants.dart';
import 'package:infinity_messenger/models/chat_model.dart';
import 'package:infinity_messenger/models/message_model.dart';
import 'package:infinity_messenger/models/user_model.dart';
import 'package:infinity_messenger/screens/chat_details.dart';
import 'package:infinity_messenger/screens/contact_profile.dart';
import 'package:infinity_messenger/widgets/base_widget.dart';
import 'package:infinity_messenger/widgets/custom_text_filed.dart';
import 'package:lottie/lottie.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chatRef});

  final DocumentReference chatRef;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  late CollectionReference usersRef;
  late FocusNode _focusNode;

  ScrollController scrollController = ScrollController();
  TextEditingController sendMessageController = TextEditingController();

  bool isJoined = false;
  bool isEditing = false;
  bool isReplying = false;


  MessageModel? messageOnTaped;
  String? messageId;
  String? messageOnTapedSender;
  List chatIsTyping = [];
  String chatName = '';
  List chatMembers = [];

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

  void _onFocusChange() async {
    if (_focusNode.hasFocus) {
      chatIsTyping.add({
        'fullName': auth.currentUser!.displayName,
        'ref': usersRef.doc(auth.currentUser!.uid),
      });
      await widget.chatRef
          .update({
        'isTyping': chatIsTyping,
      });
    }
    else{
      chatIsTyping.removeWhere((item) =>
      item['fullName'] == auth.currentUser!.displayName &&
          item['ref'] == usersRef.doc(auth.currentUser!.uid));
    }
    await widget.chatRef
        .update({
      'isTyping': chatIsTyping,
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: widget.chatRef.snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> chatSnapshot) {
          if (!chatSnapshot.hasData) {
            return const SizedBox();
          }

          ChatModel chat = ChatModel.getFromDocument(chatSnapshot.data!);
          chatIsTyping = chat.isTyping!;
          chatMembers = chat.members!;
          chatName = chat.groupName!;

          isMember(chat.members!);
        return BaseWidget(
          padding: 10,
          appBar: AppBar(
            elevation: 10,
            toolbarHeight: 75,
            shadowColor:
                onThemeColor(context).withOpacity(0.25),
            title: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetails(chatRef: widget.chatRef),));
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(width: 1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetails(
                              chatRef: widget.chatRef,
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'groupImage',
                        child: CircleAvatar(
                          backgroundColor: onThemeColor(context).withOpacity(0.5),
                          radius: 30,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(80),
                            child: chat.chatImageAddress != ''
                                ? FadeInImage(
                              placeholder: const AssetImage(
                                  'assets/images/defaultUser.jpg'),
                              image: NetworkImage(
                                chat.chatImageAddress!,
                              ),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                                : Text(
                              chat.groupName!
                                  .toUpperCase()
                                  .substring(0, 1),
                              style:
                              myTextStyle(context, 24, 'bold', 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.groupName ?? '',
                      style: myTextStyle(context, 16, 'bold', 1),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    chat.isTyping!.isEmpty
                        ?  Text('${chat.members!.length} Members',style: TextStyle(
                      fontFamily: myFontFamily,
                      color: onThemeColor(context).withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),)
                        : chat.isTyping!.length == 1
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    '${chat.isTyping!.first['fullName']} ',
                                    style: TextStyle(
                                      fontFamily: myFontFamily,
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'is typing...',
                                    style: TextStyle(
                                      fontFamily: myFontFamily,
                                      color:
                                          onThemeColor(context).withOpacity(0.7),
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Text(
                                    '${chat.isTyping!.last['fullName']} and ${(chat.isTyping!.length - 1).toString()} other people ',
                                    style: TextStyle(
                                      fontFamily: myFontFamily,
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'are typing...',
                                    style: TextStyle(
                                      fontFamily: myFontFamily,
                                      color:
                                          onThemeColor(context).withOpacity(0.7),
                                      fontSize: 11,
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
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                    stream: widget.chatRef
                        .collection('messages')
                        .orderBy('dateTime', descending: true)
                        .snapshots(),
                    builder:
                        (context, AsyncSnapshot<QuerySnapshot> messageSnapshot) {

                      if (!messageSnapshot.hasData) {
                        return Center(child: showLoading(context));
                      }

                        if (messageSnapshot.data!.docs.isNotEmpty) {
                          return ListView.builder(
                            itemCount: messageSnapshot.data!.docs.length,
                            controller: scrollController,
                            physics: const BouncingScrollPhysics(),
                            reverse: true,
                            itemBuilder: (context, index) {
                              MessageModel message = MessageModel.getFromDocument(messageSnapshot.data!.docs[index]);
                              return StreamBuilder<DocumentSnapshot>(
                                  stream: message.sender!.snapshots(),
                                  builder: (context,
                                      AsyncSnapshot<DocumentSnapshot>
                                          userSnapshot) {
                                    if (!userSnapshot.hasData) {
                                      return const SizedBox();
                                    }
                                    UserModel sender = UserModel.getFromDocument(userSnapshot.data!);
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
                                          Visibility(
                                            visible: !isMe,
                                            child: Column(
                                              children: [
                                                const SizedBox(
                                                  height: 8,
                                                ),
                                                Row(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(30),
                                                      child: OpenContainer(
                                                        closedColor:
                                                            onThemeColor(context)
                                                                .withOpacity(0.02),
                                                        openColor: onThemeColor(context)
                                                            .withOpacity(0.02),
                                                        useRootNavigator: true,
                                                        transitionDuration:
                                                            const Duration(
                                                                milliseconds: 300),
                                                        closedBuilder:
                                                            (context, action) =>
                                                                CircleAvatar(
                                                          backgroundColor:
                                                              themeColor(context),
                                                          radius: 30,
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(30),
                                                            child: sender.imageAddress !=
                                                                    null
                                                                ? FadeInImage(
                                                                    placeholder:
                                                                        const AssetImage(
                                                                            'assets/images/defaultUser.jpg'),
                                                                    image: NetworkImage(
                                                                        sender.imageAddress!),
                                                                    width: 60,
                                                                    height: 60,
                                                                    fit: BoxFit
                                                                        .cover)
                                                                : Image.asset(
                                                                    'assets/images/defaultUser.jpg',
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  ),
                                                          ),
                                                        ),
                                                        openBuilder: (context,
                                                                action) =>
                                                            ContactProfileScreen(
                                                          userRef: usersRef
                                                              .doc(sender.id),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width:
                                                MediaQuery.of(context).size.width -
                                                    100,
                                            child: GestureDetector(
                                              onTap: () {
                                                messageId = messageSnapshot
                                                    .data!.docs[index].id;
                                                messageOnTaped = message;
                                                messageOnTapedSender =
                                                    sender.fullName;
                                                messageOnTap(isMe);
                                              },
                                              child: ChatBubble(
                                                clipper: ChatBubbleClipper5(
                                                    type: isMe
                                                        ? BubbleType.sendBubble
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
                                                    ? Colors.blue.withOpacity(0.75)
                                                    : onThemeColor(context)
                                                        .withOpacity(0.5),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
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
                                                                            FontWeight
                                                                                .bold),
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
                                                          visible:
                                                              message.reply !=
                                                                  null,
                                                          child: message.reply !=
                                                                  null
                                                              ? StreamBuilder<
                                                                      DocumentSnapshot>(
                                                                  stream: message.reply!
                                                                      .snapshots(),
                                                                  builder: (context,
                                                                      AsyncSnapshot<
                                                                              DocumentSnapshot>
                                                                          replySnapshot) {
                                                                    if (!replySnapshot
                                                                        .hasData) {
                                                                      return const SizedBox();
                                                                    }
                                                                    MessageModel reply = MessageModel.getFromDocument(replySnapshot
                                                                        .data!);
                                                                    return Column(
                                                                      children: [
                                                                        Container(
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color: Colors
                                                                                .green[800],
                                                                            borderRadius:
                                                                                BorderRadius.circular(10),
                                                                          ),
                                                                          child:
                                                                              Container(
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              borderRadius: const BorderRadius
                                                                                  .only(
                                                                                  topRight: Radius.circular(10),
                                                                                  bottomRight: Radius.circular(10)),
                                                                              color:
                                                                                  themeColor(context),
                                                                            ),
                                                                            margin: const EdgeInsets
                                                                                .fromLTRB(
                                                                                8,
                                                                                0,
                                                                                0,
                                                                                0),
                                                                            child:
                                                                                Container(
                                                                              padding: const EdgeInsets
                                                                                  .all(
                                                                                  10),
                                                                              decoration: BoxDecoration(
                                                                                  borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
                                                                                  color: Colors.green[600]!.withOpacity(0.2)),
                                                                              child:
                                                                                  Row(
                                                                                mainAxisSize:
                                                                                    MainAxisSize.min,
                                                                                mainAxisAlignment:
                                                                                    MainAxisAlignment.center,
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
                                                                                            reply.text!.length < 33 ? reply.text! : '${reply.text!.substring(0, 33)}...',
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
                                                                          height: 5,
                                                                        ),
                                                                      ],
                                                                    );
                                                                  })
                                                              : const SizedBox(),
                                                        ),
                                                        Text(
                                                          message.text!,
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
                                                                FontWeight.bold,
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
                                                          MainAxisAlignment.start,
                                                      children: [
                                                        Visibility(
                                                          visible:
                                                              message.edited!,
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
                                                                    fontSize: 10,
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
                                                                  FontWeight.bold),
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
                                  });
                            },
                          );
                        } else {
                          return Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground
                                          .withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        InkWell(
                                          hoverColor: Colors.transparent,
                                          onTap: () async {
                                            await creatMessage('Hello guys');
                                          },
                                          child: Lottie.asset(
                                            'assets/animations/say_hello.json',
                                            width: 300,
                                            height: 300,
                                          ),
                                        ),
                                        Text(
                                          'No message yet',
                                          style:
                                              myTextStyle(context, 12, 'normal', 1),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          'Tap the robot to say hello',
                                          style:
                                              myTextStyle(context, 14, 'bold', 1),
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
                    }),
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
                                    color:
                                        onThemeColor(context),
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
                                                ? messageOnTaped!.text!
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
                            color: themeColor(context),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Icon(
                                    Icons.reply,
                                    color:
                                        onThemeColor(context),
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
                                                ? messageOnTaped!.sender == usersRef.doc(auth.currentUser!.uid) ? 'Me :':
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
                                                ? messageOnTaped!.text!
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
                  !isJoined ?
                      Row(
                        children: [
                          Expanded(child: InkWell(onTap: () {
                            joinGroup();
                          },borderRadius: BorderRadius.circular(15),
                            child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15),color: Colors.blue),
                            child: Text('Join ',style: myTextStyle(context, 16, 'bold', 1).copyWith(color: Colors.white),),
                          ),),),
                        ],
                      )
                  :Row(
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

  isMember(List members){
    for(var item in members){
      if(item == usersRef.doc(auth.currentUser!.uid)){
          isJoined = true;
      }
    }
  }

  void sendMessage() async {
    if (sendMessageController.text.isNotEmpty) {
      String text = sendMessageController.text.trim();
      sendMessageController.clear();
      await creatMessage(text);
      scrollController.animateTo(scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.bounceInOut);
    }
  }

  creatMessage(String text) async {
    Map<String, dynamic> newMessage = {};
    newMessage['Sender'] = usersRef.doc(auth.currentUser!.uid);
    newMessage['dateTime'] = DateTime.now();
    newMessage['text'] = text;
    newMessage['edited'] = false;
    isReplying
        ? newMessage['reply'] = widget.chatRef.collection('messages').doc(messageId)
        : newMessage['reply'] = null;
    closeReplyMessage();
    DocumentReference lastMessageRef =
        await widget.chatRef.collection('messages').add(newMessage);
    await widget.chatRef.update(
        {'lastMessageTime': DateTime.now(), 'lastMessage': lastMessageRef});
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
    sendMessageController.text = messageOnTaped!.text!;
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
    await widget.chatRef.collection('messages').doc(messageId).delete();
    Navigator.pop(context);
  }

  editMessage() {
    if (messageOnTaped!.text! != sendMessageController.text) {
      widget.chatRef.collection('messages').doc(messageId).update(
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

   joinGroup() async{
    chatMembers.add(usersRef.doc(auth.currentUser!.uid));
    
    await widget.chatRef.update({'members': chatMembers});

    if(widget.chatRef != fireStore.collection('publicChat').doc('publicChat')){
      await usersRef
          .doc(auth.currentUser!.uid)
          .collection('groups')
          .doc(widget.chatRef.id)
          .set({'chatRef': widget.chatRef, 'groupName': chatName});
    }
  }
}


