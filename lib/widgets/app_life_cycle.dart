import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppLifeCycle extends StatefulWidget {
   const AppLifeCycle({super.key, required this.child});

   final Widget child;

  @override
  State<AppLifeCycle> createState() => _AppLifeCycleState();
}

class _AppLifeCycleState extends State<AppLifeCycle> with WidgetsBindingObserver{
  FirebaseAuth auth = FirebaseAuth.instance;
  CollectionReference usersRef = FirebaseFirestore.instance.collection('Users');

  changeStatus(bool status) async {
    if(auth.currentUser != null) {
      QuerySnapshot searchUser = await usersRef
          .where('id', isEqualTo: auth.currentUser!.uid)
          .limit(1)
          .get();
      if (searchUser.docs.isNotEmpty) {
        await usersRef.doc(searchUser.docs.first.id).update(
            {'isActive': status,'lastSeen':DateTime.now()});
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void deactivate() {
    // TODO: implement deactivate
    super.deactivate();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);
    if(state == AppLifecycleState.resumed){
      changeStatus(true);
    }
    else{
      changeStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: widget.child,);
  }
}
