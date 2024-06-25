import 'package:cloud_firestore/cloud_firestore.dart';


class MessageModel {
  late DocumentReference? sender;
  late Timestamp? dateTime;
  late bool? edited;
  late DocumentReference? reply;
  late String? text;


  MessageModel(this.sender, this.dateTime, this.edited, this.reply, this.text,);

  MessageModel.getFromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    sender = data['Sender'];
    dateTime = data['dateTime'];
    edited = data['edited'];
    reply = data['reply'];
    text = data['text'];
  }

  Map<String, dynamic> toMap() => {
    'Sender': sender,
    'dateTime': dateTime,
    'edited': edited,
    'reply': reply,
    'text': text,
  };
}

