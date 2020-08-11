import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:enhanced_ddp/enhanced_ddp.dart';
import 'package:enhanced_meteorify/src/utils/utils.dart';
import 'subscribed_collection.dart';

/// An enum for describing the [ConnectionStatus].
enum ConnectionStatus { CONNECTED, DISCONNECTED }

/// An class to parse Meteor Errors
class MeteorError extends Error {
  String error;
  String errorType;
  String message;
  String reason;

  MeteorError.parse(Map<String, dynamic> err) {
    error = err['error']?.toString();
    errorType = err['errorType']?.toString();
    message = err['message']?.toString();
    reason = err['reason']?.toString();
  }

  String get errorMessage => reason;

  @override
  String toString() {
    return 'error: $error, errorType: $errorType, message: $message, reason: $reason';
  }
}

/// A listener for the current connection status.
typedef MeteorConnectionListener = void Function(
    ConnectionStatus connectionStatus);

/// Provides useful methods for interacting with the Meteor server.
///
/// Provided methods use the same syntax as of the [Meteor] class used by the Meteor framework.
class Meteor {
  /// The client used to interact with DDP framework.
  static DdpClient _client;

  /// Get the [_client].
  static DdpClient get client => _client;

  /// A listener for the connection status.
  static MeteorConnectionListener _connectionListener;

  /// Set the [_connectionListener]
  static set connectionListener(MeteorConnectionListener listener) =>
      _connectionListener = listener;

  /// Connection url of the Meteor server.
  static String _connectionUrl;

  /// A boolean to check the connection status.
  static bool isConnected = false;

  /// The [_currentUserId] of the logged in user.
  static String _currentUserId;

  /// Get the [_currentUserId].
  static String get currentUserId => _currentUserId;

  /// The status listener used to listen for connection status updates.
  static StatusListener _statusListener;

  /// The session token used to store the currently logged in user's login token.
  static String _sessionToken;

  /// Connect to the Meteor framework using the [url].
  /// Takes an optional parameter [autoLoginOnReconnect] which, if true would login the current user again with the [_sessionToken] when the server reconnects.
  /// Takes another optional parameter [heartbeatInterval] which indicates the duration after which the client checks if the connection is still alive.
  ///
  /// Returns a [ConnectionStatus] wrapped in [Future].
  static Future<ConnectionStatus> connect(String url,
      {bool autoLoginOnReconnect = false,
      Duration heartbeatInterval = const Duration(seconds: 15)}) async {
    var connectionStatus = await _connectToServer(url, heartbeatInterval);
    _client.removeStatusListener(_statusListener);

    var _token = await Utils.getString('token');
    _statusListener = (status) {
      if (status == ConnectStatus.connected) {
        isConnected = true;
        print('token: $_token');
        if (autoLoginOnReconnect && _token != null && _token.isNotEmpty) {
          loginWithToken(_token);
        } else if (autoLoginOnReconnect && _sessionToken != null) {
          print('_sessionToken: $_token');
          loginWithToken(_sessionToken);
        }
        _notifyConnected();
      } else if (status == ConnectStatus.disconnected) {
        isConnected = false;
        _notifyDisconnected();
      }
    };
    _client.addStatusListener(_statusListener);
    return connectionStatus;
  }

  /// Connect to Meteor framework using the [url].
  /// Takes an another parameter [heartbeatInterval] which indicates the duration after which the client checks if the connection is still alive.
  ///
  /// Returns a [ConnectionStatus] wrapped in a future.
  static Future<ConnectionStatus> _connectToServer(
      String url, Duration heartbeatInterval) async {
    var completer = Completer<ConnectionStatus>();

    _connectionUrl = url;
    _client = DdpClient('meteor', _connectionUrl, 'meteor');
    _client.heartbeatInterval = heartbeatInterval;
    _client.connect();

    _statusListener = (status) {
      if (status == ConnectStatus.connected) {
        isConnected = true;
        _notifyConnected();
        if (!completer.isCompleted) {
          completer.complete(ConnectionStatus.CONNECTED);
        }
      } else if (status == ConnectStatus.disconnected) {
        isConnected = false;
        _notifyDisconnected();
        if (!completer.isCompleted) {
          completer.completeError(ConnectionStatus.DISCONNECTED);
        }
      }
    };
    _client.addStatusListener(_statusListener);
    return completer.future;
  }

  /// Disconnect from Meteor framework.
  static void disconnect() {
    _client.close();
    _notifyDisconnected();
  }

  /// Reconnect with the Meteor framework.
  static void reconnect() {
    _client.reconnect();
  }

  /// Notifies the [_connectionListener] about the network connected status.
  static void _notifyConnected() {
    if (_connectionListener != null) {
      _connectionListener(ConnectionStatus.CONNECTED);
    }
  }

  /// Notifies the [_connectionListener] about the network disconnected status.
  static void _notifyDisconnected() {
    if (_connectionListener != null) {
      _connectionListener(ConnectionStatus.DISCONNECTED);
    }
  }

/*
 * Methods associated with authentication
 */

  /// Returns `true` if user is logged in.
  static bool isLoggedIn() {
    return _currentUserId != null;
  }

  /// Login using the user's [email] or [username] and [password].
  ///
  /// Returns the `loginToken` after logging in.
  static Future<String> loginWithPassword(String user, String password) async {
    if (isConnected) {
      var query;
      if (!user.contains('@')) {
        query = {'username': user};
      } else {
        query = {'email': user};
      }
      var result = await _client.call('login', [
        {
          'user': query,
          'password': {
            'digest': sha256.convert(utf8.encode(password)).toString(),
            'algorithm': 'sha-256'
          },
        }
      ]);
      if (result.error == null) {
        print(result.reply);
        return await _notifyLoginResult(result);
      } else {
        throw MeteorError.parse(result.reply);
      }
    } 
  }

  /// Login or register a new user with de Google oAuth API
  ///
  /// [email] the email to register with. Must be fetched from the Google oAuth API
  /// [userId] the unique Google userId. Must be fetched from the Google oAuth API
  /// [authHeaders] the authHeaders from Google oAuth API for server side validation
  /// Returns the `loginToken` after logging in.
  static Future<String> loginWithGoogle(
      String email, String userId, Object authHeaders) async {
    final googleLoginPlugin = true;
    if (isConnected) {
      var result = await _client.call('login', [
        {
          'email': email,
          'userId': userId,
          'authHeaders': authHeaders,
          'googleLoginPlugin': googleLoginPlugin
        }
      ]);
      if (result.error == null) {
        print(result.reply);
        return await _notifyLoginResult(result);
      } else {
        throw MeteorError.parse(result.reply);
      }
    }
  }

  ///Login or register a new user with the Facebook Login API
  ///
  /// [userId] the unique Facebook userId. Must be fetched from the Facebook Login API
  /// [token] the token from Facebook API Login for server side validation
  /// Returns the `loginToken` after logging in.
  static Future<String> loginWithFacebook(String userId, String token) async {
    final facebookLoginPlugin = true;
    if (isConnected) {
      var result = await _client.call('login', [
        {
          'userId': userId,
          'token': token,
          'facebookLoginPlugin': facebookLoginPlugin
        }
      ]);
      if (result.error == null) {
        print(result.reply);
        return await _notifyLoginResult(result);
      } else {
        throw MeteorError.parse(result.reply);
      }
    } 
  }

  ///Login or register a new user with the Apple Login API
  ///
  /// [userId] the unique Apple userId. Must be fetched from the Apple Login API
  /// [jwt] the jwt from Apple API Login to get user's e-mail. (result.credential.identityToken)
  /// [givenName] user's given name. Must be fetched from the Apple Login API
  /// [lastName] user's last name. Must be fetched from the Apple Login API
  /// Returns the `loginToken` after logging in.
  static Future<String> loginWithApple(
      String userId, List<int> jwt, String givenName, String lastName) async {
    final appleLoginPlugin = true;
    if (isConnected) {
      var token = Utils.parseJwt(utf8.decode(jwt));
      var result = await _client.call('login', [
        {
          'userId': userId,
          'email': token['email'],
          'givenName': givenName,
          'lastName': lastName,
          'appleLoginPlugin': appleLoginPlugin
        }
      ]);
      if (result.error == null) {
        print(result.reply);
        return await _notifyLoginResult(result);
      } else {
        throw MeteorError.parse(result.reply);
      }
    } 
  }

  /// Login using a [loginToken].
  ///
  /// Returns the `loginToken` after logging in.
  static Future<String> loginWithToken(String loginToken) async {
      if (isConnected) {
        var result = await _client.call('login', [
          {'resume': loginToken}
        ]);
        if (result.error == null) {
          print(result.reply);
          return await _notifyLoginResult(result);
        } else {
          throw MeteorError.parse(result.reply);
        }
      } else {
        return null;
      }
  }

  /// Used internally to notify the future about success/failure of login process.
  static Future<String> _notifyLoginResult(Call result) async {
    String userId = result.reply['id'];
    String token = result.reply['token'];
    print('login result: ${result.reply}');
    if (userId != null) {
      _currentUserId = userId;
      print('Logged in user $_currentUserId');
      var _token = await Utils.setString('token', token);
      print('loginToken: $_token');
      _sessionToken = token;
      return token;
    } else {
      return null;
    }
  }

  /// Logs out the user.
  static void logout() async {
    if (isConnected) {
      var result = await _client.call('logout', []);
      await Utils.remove('loginToken');
      _sessionToken = null;

      print(result.reply);
    }
  }

/*
 * Methods associated with subscriptions
 */

  /// Subscribe to a subscription using the [subscriptionName].
  ///
  /// Returns the `subscriptionId` as a [String].
  static Future<String> subscribe(String subscriptionName,
      {List<dynamic> args = const []}) async {
    var result = await _client.sub(subscriptionName, args);
    if (result.error != null && result.error.toString().contains('nosub')) {
      throw MeteorError.parse(result.reply);
    } else {
      return await result.id;
    }
  }

  /// Unsubscribe from a subscription using the [subscriptionId] returned by [subscribe].
  static Future<String> unsubscribe(String subscriptionId) async {
    var result = await _client.unSub(subscriptionId);
    if (result.error == null) {
      return await result.id;
    } else {
      throw MeteorError.parse(result.reply);
    }
  }

/*
 * Methods related to collections
 */

  /// Returns a [SubscribedCollection] using the [collectionName].
  ///
  /// [SubscribedCollection] supports only read operations.
  static Future<SubscribedCollection> collection(String collectionName) async {
    try {
      var collection = _client.collectionByName(collectionName);
      return await SubscribedCollection(collection, collectionName);
    } catch (err) {
      MeteorError.parse(err);
      return null;
    }
  }

/*
 *  Methods related to meteor ddp calls
 */

  /// Makes a call to a service method exported from Meteor using the [methodName] and list of [arguments].
  ///
  /// Returns the value returned by the service method or an error using a [Future].
  static Future<dynamic> call(
      String methodName, List<dynamic> arguments) async {
    var result = await _client.call(methodName, arguments);
    if (result.error == null) {
      return await result.reply;
    } else {
      throw MeteorError.parse(result.reply);
    }
  }
}
