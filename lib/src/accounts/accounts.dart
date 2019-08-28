import 'dart:async';

import '../meteor/meteor.dart';
import 'package:ddp/ddp.dart';

/// Provides useful methods of the `accounts-password` Meteor package.
///
/// Assumes, your Meteor server uses the `accounts-password` package.
class Accounts {
  /// Creates a new user using [username], [email], [password] and a [profile] map.
  ///
  /// Returns the `userId` of the created user.
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
    } else {
      completer.completeError("Not connected to server");
    }
    return completer.future;
  }

  /// Change the user account password provided the user is already logged in.
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

  /// Sends a `forgotPassword` email to the user with a link to reset the password.
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

  /// Resets the user password by taking the [passwordResetToken] and the [newPassword].
  static Future<String> resetPassword(
      String passwordResetToken, String newPassword) async {
    Completer completer = Completer<String>();
    if (Meteor.isConnected) {
      var result = await Meteor.client
          .call("resetPassword", [passwordResetToken, newPassword]);
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

  /// Verifies the user email by taking the [verificationToken] sent to the user.
  static verifyEmail(String verificationToken) async {
    Completer completer = Completer<String>();
    if (Meteor.isConnected) {
      var result = await Meteor.client.call("verifyEmail", [verificationToken]);
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

  /// Notifies a future with the error.
  ///
  /// This error can be handled using `catchError` if using the `Future` directly.
  /// And using the `try-catch` block, if using the `await` feature.
  static void _notifyError(Completer completer, Call result) {
    completer.completeError(result.reply['reason']);
  }
}
