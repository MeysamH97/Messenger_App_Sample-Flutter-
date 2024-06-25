import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseAuth auth = FirebaseAuth.instance;
CollectionReference usersRef = FirebaseFirestore.instance.collection('Users');



class PrivateChatModel {
  late String? id;
  late String? type;
  late bool? isTyping;
  late DocumentReference? lastMessage;
  late Timestamp? lastMessageTime;
  late DocumentReference? chatRef;

  PrivateChatModel( this.id, this.type,
      this.isTyping,
      this.lastMessage, this.lastMessageTime, this.chatRef);

  PrivateChatModel.getFromDocument(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    id = data['id'];
    type = data['type'];
    isTyping = data['isTyping'];
    lastMessage = data['lastMessage'];
    lastMessageTime = data['lastMessageTime'];
    chatRef = data['chatRef'];
  }

}

