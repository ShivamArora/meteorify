import '../meteor/meteor.dart';
import '../listeners/listeners.dart';
import 'package:ddp/ddp.dart';

class Accounts{

  static createUser(String username, String email,String password,Map<String,String> profile, ResultListener resultListener) async {
    if(Meteor.isConnected) {
      var map = {"username": username, "email": email, "password": password, "profile":profile};
      var result = await Meteor.client.call("createUser", [map]);
      print(result.reply);
      //Handle result
      if(result.reply["error"]!=null){
        _notifyError(resultListener, result);
      }
      else{
        resultListener.onSuccess(result.reply['id']);;
      }
      print("Error: ${result.reply['error']}");
      print("User created with userId: ${result.reply['id']}");
    }
    else{
      print("Not connected to server");
    }
  }

  static changePassword(String oldPassword,String newPassword,ResultListener resultListener ) async{
    if(Meteor.isConnected){
      var result = await Meteor.client.call("changePassword",[oldPassword,newPassword]);
      print(result.reply);
      //Handle result
      if(result.reply['passwordChanged']!=null){
        resultListener.onSuccess();
      }
      else{
        _notifyError(resultListener, result);
      }
    }
  }

  static forgotPassword(String email,ResultListener resultListener) async{
    if(Meteor.isConnected){
      var result = await Meteor.client.call("forgotPassword", [{"email":email}]);
      print(result.reply);
      //Handle result
      if(result.reply==null){
        resultListener.onSuccess();
      }
      else{
        _notifyError(resultListener, result);
      }
    }
  }

  static resetPassword(String resetToken,String newPassword,ResultListener resultListener) async{
    if(Meteor.isConnected){
      var result = await Meteor.client.call("resetPassword", [resetToken,newPassword]);
      print(result.reply);
      //TODO: Yet to test
    }
  }


  static verifyEmail(String verifyToken,ResultListener resultListener) async{
    if(Meteor.isConnected){
      var result = await Meteor.client.call("verifyEmail",[verifyToken]);
      print(result.reply);
      //TODO: Yet to test
    }
  }

  static void _notifyError(ResultListener resultListener, Call result) {
    resultListener.onError(result.reply['reason']);
  }
}