import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseAuth auth = FirebaseAuth.instance;
CollectionReference usersRef = FirebaseFirestore.instance.collection('Users');



class ChatModel {
  late String id;
  late String? groupName;
  late String? bio;
  late String type;
  late DocumentReference? owner;
  late List? admins;
  late String? chatImageAddress;
  late List? isTyping;
  late DocumentReference? lastMessage;
  late Timestamp? lastMessageTime;
  late List? members;
  late DocumentReference? chatRef;

  ChatModel(this.id, this.type, this.owner, this.admins, this.chatImageAddress, this.groupName,
      this.isTyping,
      this.lastMessage, this.lastMessageTime, this.members,this.chatRef,this.bio);

  ChatModel.getFromDocument(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    id = data['id'];
    type = data['type'];
    owner = data['owner'];
    admins = data['admins'];
    chatImageAddress = data['chatImageAddress'];
    groupName = data['groupName'];
    bio = data['bio'];
    isTyping = data['isTyping'];
    lastMessage = data['lastMessage'];
    lastMessageTime = data['lastMessageTime'];
    members = data['members'];
    chatRef = data['chatRef'];
  }

}

