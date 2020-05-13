import 'package:enhanced_meteorify/enhanced_meteorify.dart';

void main() async {
  try {
    await Meteor.connect('ws://127.0.0.1:3000/websocket');
    if (Meteor.isConnected) {
      var result =
          await Meteor.loginWithPassword('Freeman', 'RiseAndShineMrFreeman');
      print(result);
    }
  } catch (error) {
    print(error);
  }
}
