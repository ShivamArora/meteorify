import 'dart:async';

import 'package:ddp/ddp.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../listeners/listeners.dart';
import 'subscribed_collection.dart';

/// An enum for describing the [ConnectionStatus].
enum ConnectionStatus { CONNECTED, DISCONNECTED }

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

  /// Connection url of the Meteor server.
  static String _connectionUrl;

  /// A boolean to check the connection status.
  static bool isConnected = false;

  /// The [_currentUserId] of the logged in user.
  static String _currentUserId;

  /// Get the [_currentUserId].
  static String get currentUserId => _currentUserId;

  static Db db;

  /// Connect to the Meteor framework using the [url].
  ///
  /// Returns a [ConnectionStatus] wrapped in [Future].
  static Future<ConnectionStatus> connect(String url) async {
    Completer<ConnectionStatus> completer = Completer<ConnectionStatus>();

    _connectionUrl = url;
    _client = DdpClient("meteor", _connectionUrl, "meteor");
    _client.connect();

    _client.addStatusListener((status) {
      if (status == ConnectStatus.connected) {
        isConnected = true;
        _notifyConnected();
        completer.complete(ConnectionStatus.CONNECTED);
      } else if (status == ConnectStatus.disconnected) {
        isConnected = false;
        _notifyDisconnected();
        completer.completeError(ConnectionStatus.DISCONNECTED);
      }
    });
    return completer.future;
  }

  /// Disconnect from Meteor framework.
  static disconnect() {
    _client.close();
    _notifyDisconnected();
  }

  /// Reconnect with the Meteor framework.
  static reconnect() {
    _client.reconnect();
  }

  static void _notifyConnected() {
    if (_connectionListener != null) _connectionListener.onConnected();
  }

  static void _notifyDisconnected() {
    if (_connectionListener != null) _connectionListener.onDisconnected();
  }

/*
 * Methods associated with authentication
 */

  /// Returns `true` if user is logged in.
  static bool isLoggedIn() {
    return _currentUserId != null;
  }

  /// Login using the user's [email] and [password].
  ///
  /// Returns the `loginToken` after logging in.
  static Future<String> loginWithPassword(String email, String password) async {
    Completer completer = Completer<String>();
    if (isConnected) {
      var result = await _client.call("login", [
        {
          "password": password,
          "user": {"email": email}
        }
      ]);
      print(result.reply);
      _notifyLoginResult(result, completer);
      return completer.future;
    }
    completer.completeError("Not connected to server");
    return completer.future;
  }

  /// Login using a [loginToken].
  ///
  /// Returns the `loginToken` after logging in.
  static Future<String> loginWithToken(String loginToken) async {
    Completer completer = Completer<String>();
    if (isConnected) {
      var result = await _client.call("login", [
        {"resume": loginToken}
      ]);
      print(result.reply);
      _notifyLoginResult(result, completer);
      return completer.future;
    }
    completer.completeError("Not connected to server");
    return completer.future;
  }

  /// Used internally to notify the future about success/failure of login process.
  static void _notifyLoginResult(Call result, Completer completer) {
    String userId = result.reply["id"];
    String token = result.reply["token"];
    if (userId != null) {
      _currentUserId = userId;
      print("Logged in user $_currentUserId");
      if (completer != null) {
        completer.complete(token);
      }
    } else {
      _notifyError(completer, result);
    }
  }

  /// Logs out the user.
  static void logout() async {
    if (isConnected) {
      var result = await _client.call("logout", []);
      print(result.reply);
    }
  }

  /// Used internally to notify a future about the error returned from a ddp call.
  static void _notifyError(Completer completer, Call result) {
    completer.completeError(result.reply['reason']);
  }

  /*
   * Methods associated with connection to MongoDB
   */
  /// Returns the default Meteor database after opening a connection.
  ///
  /// This database can be accessed using the [Db] class.
  static Future<Db> getMeteorDatabase() async {
    Completer<Db> completer = Completer<Db>();
    if (db == null) {
      final uri = Uri.parse(_connectionUrl);
      String dbUrl = "mongodb://" + uri.host + ":3001/meteor";
      print("Connecting to $dbUrl");
      db = Db(dbUrl);
      await db.open();
    }
    completer.complete(db);
    return completer.future;
  }

  /// Returns connection to a Meteor database using [dbUrl].
  ///
  /// You need to manually open the connection using `db.open()` after getting the connection.
  static Db getCustomDatabase(String dbUrl) {
    return Db(dbUrl);
  }

/*
 * Methods associated with current user
 */
  /// Returns the logged in user object as a map of properties.
  static Future<Map<String, dynamic>> userAsMap() async {
    Completer completer = Completer<Map<String, dynamic>>();
    Db db = await getMeteorDatabase();
    print(db);
    var user = await db.collection("users").findOne({"_id": _currentUserId});
    print(_currentUserId);
    print(user);
    completer.complete(user);
    return completer.future;
  }

/*
 * Methods associated with subscriptions
 */

  /// Subscribe to a subscription using the [subscriptionName].
  ///
  /// Returns the `subscriptionId` as a [String].
  static Future<String> subscribe(String subscriptionName) async {
    Completer<String> completer = Completer<String>();
    Call result = await _client.sub(subscriptionName, []);
    print("Result");
    print(result.error.toString().contains("nosub"));
    ;
    if (result.error != null && result.error.toString().contains("nosub")) {
      print("Error: " + result.error.toString());
      completer.completeError("Subscription $subscriptionName not found");
    } else {
      completer.complete(result.id);
    }
    return completer.future;
  }

  /// Unsubscribe from a subscription using the [subscriptionId] returned by [subscribe].
  static Future<String> unsubscribe(String subscriptionId) async {
    Completer<String> completer = Completer<String>();
    Call result = await _client.unSub(subscriptionId);
    completer.complete(result.id);
    return completer.future;
  }

/*
 * Methods related to collections
 */

  /// Returns a [SubscribedCollection] using the [collectionName].
  ///
  /// [SubscribedCollection] supports only read operations.
  /// For more supported operations use the methods of the [Db] class from `mongo_dart` library.
  static Future<SubscribedCollection> collection(String collectionName) {
    Completer<SubscribedCollection> completer =
        Completer<SubscribedCollection>();
    Collection collection = _client.collectionByName(collectionName);
    completer.complete(SubscribedCollection(collection, collectionName));
    return completer.future;
  }

/*
 *  Methods related to meteor ddp calls
 */
  /// Makes a call to a service method exported from Meteor using the [methodName] and list of [arguments].
  ///
  /// Returns the value returned by the service method or an error using a [Future].
  static Future<dynamic> call(
      String methodName, List<dynamic> arguments) async {
    Completer<dynamic> completer = Completer<dynamic>();
    var result = await _client.call(methodName, arguments);
    if (result.error != null) {
      completer.completeError(result.error);
    } else {
      completer.complete(result.reply);
    }
    return completer.future;
  }
}
