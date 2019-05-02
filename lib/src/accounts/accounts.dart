import 'dart:async';

import '../meteor/meteor.dart';
import 'package:ddp/ddp.dart';

class Accounts {
  static Future<String> createUser(String username, String email,
      String password, Map<String, String> profile) async {
    Completer completer = Completer<String>();
    if (Meteor.isConnected) {
      var map = {
        "username": username,
        "email": email,
        "password": password,
        "profile": profile
      };
      var result = await Meteor.client.call("createUser", [map]);
      print(result.reply);
      //Handle result
      if (result.reply["error"] != null) {
        _notifyError(completer, result);
      } else {
        completer.complete(result.reply['id']);
        ;
      }
      print("User: ${result.reply}");
      print("Error: ${result.reply['error']}");
      print("User created with userId: ${result.reply['id']}");
    } else {
      print("Not connected to server");
      completer.completeError("Not connected to server");
    }
    return completer.future;
  }

  static Future<String> changePassword(
      String oldPassword, String newPassword) async {
    Completer completer = Completer<String>();
    if (Meteor.isConnected) {
      var result = await Meteor.client
          .call("changePassword", [oldPassword, newPassword]);
      print(result.reply);
      //Handle result
      if (result.reply['passwordChanged'] != null) {
        completer.complete("Password changed");
      } else {
        _notifyError(completer, result);
      }
    } else {
      print("Not connected to server");
      completer.completeError("Not connected to server");
    }
    return completer.future;
  }

  static Future<String> forgotPassword(String email) async {
    Completer completer = Completer<String>();
    if (Meteor.isConnected) {
      var result = await Meteor.client.call("forgotPassword", [
        {"email": email}
      ]);
      print(result.reply);
      //Handle result
      if (result.reply == null) {
        completer.complete("Email sent");
      } else {
        _notifyError(completer, result);
      }
    } else {
      print("Not connected to server");
      completer.completeError("Not connected to server");
    }
    return completer.future;
  }

  static Future<String> resetPassword(
      String resetToken, String newPassword) async {
    Completer completer = Completer<String>();
    if (Meteor.isConnected) {
      var result =
          await Meteor.client.call("resetPassword", [resetToken, newPassword]);
      if (result.reply["error"] != null) {
        _notifyError(completer, result);
      } else {
        completer.complete(result.reply.toString());
      }
    } else {
      print("Not connected to server");
      completer.completeError("Not connected to server");
    }
    return completer.future;
  }

  static verifyEmail(String verifyToken) async {
    Completer completer = Completer<String>();
    if (Meteor.isConnected) {
      var result = await Meteor.client.call("verifyEmail", [verifyToken]);
      if (result.reply["error"] != null) {
        _notifyError(completer, result);
      } else {
        completer.complete(result.reply.toString());
      }
    } else {
      print("Not connected to server");
      completer.completeError("Not connected to server");
    }
    return completer.future;
  }

  static void _notifyError(Completer completer, Call result) {
    completer.completeError(result.reply['reason']);
  }
}
