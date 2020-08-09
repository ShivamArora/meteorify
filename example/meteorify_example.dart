import 'package:meteorify/meteorify.dart';

main() async{
  try {
    ConnectionStatus status = await Meteor.connect(
        "ws://localhost:3000/websocket");
    print(status);

    final loginResult = await Meteor.loginWithPassword(
        "hello@example.com", "password@123");
    print(loginResult);

  }catch(err){
    print("Error occured");
    print(err);
  }
}