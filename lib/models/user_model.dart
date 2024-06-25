import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';



FirebaseAuth auth = FirebaseAuth.instance;
CollectionReference usersRef = FirebaseFirestore.instance.collection('Users');



class UserModel {
  late String id;
  late String? fullName;
  late String? bio;
  late String? username;
  late String phoneNumber;
  late String? email;
  late String? imageAddress;
  late bool isActive;
  late bool darkMode;
  late bool showPublicChat;
  late Timestamp? lastSeen;

  UserModel(this.id, this.fullName, this.bio, this.username, this.phoneNumber, this.email,
      this.lastSeen,
      this.imageAddress, this.isActive, this.darkMode, this.showPublicChat);

  UserModel.getFromDocument(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    id = data['id'];
    fullName = data['fullName'];
    bio = data['bio'];
    username = data['username'];
    phoneNumber = data['phoneNumber'];
    email = data['email'];
    lastSeen = data['lastSeen'];
    imageAddress = data['imageAddress'];
    isActive = data['isActive'];
    darkMode = data['darkMode'];
    showPublicChat = data['showPublicChat'];
  }
}
