import 'dart:async';

import 'package:ddp/ddp.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../listeners/listeners.dart';
import 'subscribed_collection.dart';

enum ConnectionStatus { CONNECTED, DISCONNECTED }

class Meteor {
  static DdpClient _client;
  static DdpClient get client => _client;
  static MeteorConnectionListener _connectionListener;
  static String _connectionUrl;
  static bool isConnected = false;
  static String _currentUserId;
  static String get currentUserId => _currentUserId;
  static Db db;

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

  static disconnect() {
    _client.close();
    _notifyDisconnected();
  }

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

  static bool isLoggedIn() {
    return _currentUserId != null;
  }

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

  static Future<String> loginWithToken(String token) async {
    Completer completer = Completer<String>();
    if (isConnected) {
      var result = await _client.call("login", [
        {"resume": token}
      ]);
      print(result.reply);
      _notifyLoginResult(result, completer);
      return completer.future;
    }
    completer.completeError("Not connected to server");
    return completer.future;
  }

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

  static void logout() async {
    if (isConnected) {
      var result = await _client.call("logout", []);
      print(result.reply);
    }
  }

  static void _notifyError(Completer completer, Call result) {
    completer.completeError(result.reply['reason']);
  }

  /*
   * Methods associated with connection to MongoDB
   */
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

  static Db getCustomDatabase(String dbUrl) {
    return Db(dbUrl);
  }

/*
 * Methods associated with current user
 */
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

  static Future<String> unsubscribe(String subscriptionId) async {
    Completer<String> completer = Completer<String>();
    Call result = await _client.unSub(subscriptionId);
    completer.complete(result.id);
    return completer.future;
  }

/*
 * Methods related to collections
 */
  static Future<SubscribedCollection> collection(String collectionName) {
    Completer<SubscribedCollection> completer =
        Completer<SubscribedCollection>();
    Collection collection = _client.collectionByName(collectionName);
    completer.complete(SubscribedCollection(collection, collectionName));
    return completer.future;
  }
}
