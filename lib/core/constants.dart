
import 'package:flutter/material.dart';
import 'package:infinity_messenger/screens/chat.dart';
import 'package:infinity_messenger/screens/contacts.dart';
import 'package:infinity_messenger/screens/home_screen.dart';
import 'package:infinity_messenger/screens/profile.dart';
import 'package:infinity_messenger/screens/sign_in.dart';
import 'package:infinity_messenger/screens/complete_profile_screen.dart';

String myFontFamily = 'Exo';

//Colors
Color themeColor(context) {return Theme.of(context).colorScheme.background;}
Color onThemeColor(context) {return Theme.of(context).colorScheme.onBackground;}


Widget showLoading (context) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Theme
          .of(context)
          .colorScheme
          .onBackground.withOpacity(0.8),
      borderRadius: BorderRadius.circular(20),
    ),
    child: CircularProgressIndicator(
      color: Theme
          .of(context)
          .colorScheme
          .background,
    ),
  );
}

TextStyle myTextStyle(
    context, double fontSize, String? fontWeight, double? opacity) {
  return TextStyle(
    fontFamily: myFontFamily,
    fontSize: fontSize,
    fontWeight: (fontWeight == 'bold') ? FontWeight.bold : FontWeight.normal,
    color: (opacity != null)
        ? Theme.of(context).colorScheme.onBackground.withOpacity(opacity)
        : Theme.of(context).colorScheme.onBackground,
  );
}

TextStyle myButtonTextStyle(
    context, double fontSize,Color? textColor, String? fontWeight, double? opacity) {
  return TextStyle(
    fontFamily: myFontFamily,
    fontSize: fontSize,
    fontWeight: (fontWeight == 'bold') ? FontWeight.bold : FontWeight.normal,
    color: textColor == null ? (opacity != null)
        ? Theme.of(context).colorScheme.background.withOpacity(opacity)
        : Theme.of(context).colorScheme.background :(opacity != null)
        ? textColor.withOpacity(opacity)
        : textColor,
  );
}

kNavigator(context, String page) {
  if (page == 'signIn') {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const SignInScreen(),
        ),
        (route) => false);
  } else if (page == 'CompleteProfileScreen') {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const CompleteProfileScreen(),
        ),
        (route) => false);
  } else if (page == 'HomeScreen') {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
        (route) => false);
  } else if (page == 'Profile') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Profile(),
      ),
    );
  }  else if (page == 'Contacts') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ContactsScreen(),
      ),
    );
  }
}

String getLastSeen(bool isActive,DateTime lastSeen) {
  int time = DateTime.now().difference(lastSeen).inMinutes;
  if (isActive) {
    return 'Online';
  } else if (time >= 0 && time < 5) {
    return 'Last seen recently';
  } else if (time >= 5 && time <= 59) {
    return 'Last seen ${time.toInt()} minutes ago';
  } else if (time >= 60 && time <= 1439) {
    return 'Last seen ${time ~/ 60} hours ago';
  } else if (time >= 1440 && time <= 10079) {
    return 'Last seen ${time ~/ (60 * 24)} days ago';
  } else if (time >= 10080 && time <= 43199) {
    return 'Last seen ${time ~/ (60 * 24 * 7)} weeks ago';
  } else if (time >= 43200 && time <= 129600) {
    return 'Last seen ${time ~/ (60 * 24 * 30)} month ago';
  } else {
    return 'Last seen a long time ago';
  }
}
