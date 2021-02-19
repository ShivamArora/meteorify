import 'package:enhanced_meteorify/enhanced_meteorify.dart';
import 'package:flutter/material.dart';
import 'package:example/app/app_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Meteor.connect('ws://192.168.27.113:3000/websocket');
    runApp(ModularApp(module: AppModule()));
  } on MeteorError catch (error) {
    print(error);
  }
}
