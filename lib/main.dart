import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:infinity_messenger/widgets/app_life_cycle.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:infinity_messenger/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FirebaseAuth auth = FirebaseAuth.instance;
  CollectionReference usersRef = FirebaseFirestore.instance.collection('Users');
  bool darkMode = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getTheme();
  }

  @override
  Widget build(BuildContext context) {
    return AppLifeCycle(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: darkMode ? ThemeData.dark() : ThemeData.light(),
        home: const SplashScreen(),
      ),
    );
  }

  void getTheme() async {
    if (auth.currentUser != null) {
      usersRef
          .doc(auth.currentUser!.uid)
          .snapshots()
          .listen((DocumentSnapshot snapshot) {
        if (snapshot.exists) {
          Map<String, dynamic> userData = snapshot.data()! as Map<String, dynamic>;
          setState(() {
            darkMode = userData['darkMode'];
          });
        }
      });
    }
  }
}
