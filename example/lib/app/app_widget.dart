import 'package:enhanced_meteorify/enhanced_meteorify.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:get/get.dart';

class AppWidget extends StatefulWidget {
  @override
  _AppWidgetState createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  @override
  void initState() {
    Meteor.currentUserIdListener = (String userId) {
      if (Get.isSnackbarOpen) {
        Get.back();
      }
      if (userId == null) {
        Get.snackbar(
          'Sem usuário',
          'Sem usuário',
          margin: EdgeInsets.all(8),
          icon: Icon(
            Icons.warning_rounded,
          ),
          showProgressIndicator: false,
        );
      }
      if (userId != null) {
        Get.snackbar(
          'Usuário logado',
          "$userId",
          margin: EdgeInsets.all(8),
          icon: Icon(
            Icons.warning_rounded,
          ),
          showProgressIndicator: false,
        );
      }
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Meteor.currentUserIdListener = (String userId) {
    //   print(userId);
    //   setState(() {});
    // };
    return GetMaterialApp(
      navigatorKey: Modular.navigatorKey,
      title: 'Flutter Slidy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      onGenerateRoute: Modular.generateRoute,
    );
  }
}
