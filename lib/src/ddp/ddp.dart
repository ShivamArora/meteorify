import 'dart:async';
import 'dart:convert';

import 'package:enhanced_meteorify/src/ddp/collection.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectStatus { disconnected, dialing, connecting, connected }

typedef void _MessageHandler(Map<String, dynamic> message);
typedef void ConnectionListener();
typedef void StatusListener(ConnectStatus status);

abstract class ConnectionNotifier {
  void addConnectionListener(ConnectionListener listener);
}

abstract class StatusNotifier {
  void addStatusListener(StatusListener listener);

  void removeStatusListener(StatusListener listener);
}

abstract class ReconnectListener {
  void onReconnectBegin();

  void onReconnectDone();

  void onConnected();
}

class ReconnectListenersHolder implements ReconnectListener {
  List<ReconnectListener> _listeners = [];

  void addReconnectListener(ReconnectListener listener) {
    if (listener == null) {
      return;
    }

    removeReconnectListener(listener);
    _listeners.add(listener);
  }

  void removeReconnectListener(ReconnectListener listener) {
    if (listener == null) {
      return;
    }
    _listeners.remove(listener);
  }

  void onReconnectBegin() {
    _listeners.forEach((listener) {
      try {
        listener.onReconnectBegin();
      } catch (exception) {
        print(exception);
      }
    });
  }

  void onReconnectDone() {
    _listeners.forEach((listener) {
      try {
        listener.onReconnectDone();
      } catch (exception) {
        print(exception);
      }
    });
  }

  void onConnected() {
    _listeners.forEach((listener) {
      try {
        listener.onConnected();
      } catch (exception) {
        print(exception);
      }
    });
  }
}

class IdManager {
  int _next = 0;

  String next() {
    final next = _next;
    _next++;
    return next.toRadixString(16);
  }
}

typedef void OnCallDone(Call call);

class Call {
  String id;
  String serviceMethod;
  dynamic args;
  dynamic reply;
  Error error;
  DDP owner;
  List<OnCallDone> _handlers = [];

  void onceDone(OnCallDone fn) {
    this._handlers.add(fn);
  }

  void done() {
    owner._calls.remove(this.id);
    _handlers.forEach((handler) => handler(this));
    _handlers.clear();
  }
}

class DDP implements ConnectionNotifier, StatusNotifier {
  Duration heartbeatInterval;
  Duration heartbeatTimeOut;
  Duration reconnectInterval;

  bool _waitingForConnect;
  bool _wasPingSent;

  String _sessionId;
  String _serverId;
  String _version;
  String _url;
  List<String> _support;

  WebSocketChannel _socket;
  Reader _reader;
  Writer _writer;
  IdManager _idManager;

  Timer _reconnectTimer;
  Timer _pingTimer;

  Map<String, Call> _calls;
  Map<String, Call> _subs;
  Map<String, Call> _unsubs;
  Map<String, Collection> _collections;
  Map<String, _MessageHandler> _messageHandlers;

  ConnectStatus _connectStatus;
  List<StatusListener> _statusListeners;
  List<ConnectionListener> _connectionListener;
  ReconnectListenersHolder _reconnectListenersHolder =
      ReconnectListenersHolder();

  DDP(this._url,
      {this.heartbeatInterval = const Duration(seconds: 20),
      this.heartbeatTimeOut = const Duration(seconds: 15),
      this.reconnectInterval = const Duration(seconds: 30)}) {
    this._url = _url;
    this._serverId = '';
    this._version = '1';
    this._support = ['1'];
    this._waitingForConnect = false;
    this._wasPingSent = false;
    this._idManager = IdManager();
    this._collections = {};
    this._calls = {};
    this._subs = {};
    this._unsubs = {};
    this._connectStatus = ConnectStatus.disconnected;
    this._statusListeners = [];
    this._connectionListener = [];
  }

  void addReconnectListener(ReconnectListener listener) {
    _reconnectListenersHolder.addReconnectListener(listener);
  }

  void removeReconnectListener(ReconnectListener listener) {
    _reconnectListenersHolder.removeReconnectListener(listener);
  }

  @override
  void addConnectionListener(ConnectionListener listener) {
    this._connectionListener.add(listener);
  }

  @override
  void addStatusListener(StatusListener listener) {
    this._statusListeners.add(listener);
  }

  @override
  void removeStatusListener(StatusListener listener) {
    this._statusListeners.remove(listener);
  }

  static void log(String msg, String direction) {
    if (direction == '->')
      print('\x1B[34m[DDP] -> :: $msg\x1B[0m');
    else
      print('\x1B[34m[DDP] <- :: $msg\x1B[0m');
  }

  void printWarning(String text) {
    print('\x1B[33m[DDP] :: $text\x1B[0m');
  }

  void printError(String text) {
    print('\x1B[31m[DDP] :: $text\x1B[0m');
  }

  String get session => _sessionId;

  String get version => _version;

  void _status(ConnectStatus status) {
    if (this._connectStatus == status) {
      return;
    }

    this._connectStatus = status;
    this._statusListeners.forEach((l) => l(status));
  }

  void _send(String msg) {
    this._writer.add(msg);
  }

  void _start(WebSocketChannel ws, String msg) {
    this._status(ConnectStatus.connecting);

    print(_connectMsg());
    this._initMessageHandlers();
    this._socket = ws;

    this._reader = Reader(ws.stream);
    this._writer = Writer(ws.sink);
    this._inboxManager();
    this._send(msg);
  }

  String _connectMsg() {
    if (this._sessionId != null)
      return json.encode({
        "msg": "connect",
        "version": this._version,
        "support": this._support,
        "session": this._sessionId
      });
    else
      return json.encode({
        "msg": "connect",
        "version": "${this._version}",
        "support": ["1", "pre2", "pre1"],
      });
  }

  String _reconnectMsg() {
    return json.encode({
      'msg': 'connect',
      'version': this._version,
      'support': this._support,
      'session': this._sessionId
    });
  }

  String _subMsg(String id, String subName, List<dynamic> args) {
    return json
        .encode({'msg': 'sub', 'name': subName, 'params': args, 'id': id});
  }

  String _methodMsg(String id, methodName, List<dynamic> args) {
    return json.encode(
        {'msg': 'method', 'method': methodName, 'params': args, 'id': id});
  }

  String _unsubMsg(String id) {
    return json.encode({'msg': 'unsub', 'id': id});
  }

  String _pingMsg() {
    return json.encode({'msg': 'ping'});
  }

  String _pongMsg() {
    return json.encode({'msg': 'pong'});
  }

  void connect() async {
    try {
      if (!_waitingForConnect) {
        _waitingForConnect = true;
        _reconnectListenersHolder.onReconnectBegin();
      }
      this._status(ConnectStatus.dialing);
      print(this._url);
      final ws = WebSocketChannel.connect(Uri.parse(this._url));
      this._start(ws, _connectMsg());
      _waitingForConnect = false;
      _reconnectListenersHolder.onConnected();
    } catch (err) {
      printError('DDP::ERROR::ON CONNECT: $err');
      this._reconnectLater();
    }
  }

  void reconnect() {
    try {
      if (this._reconnectTimer != null) {
        this._reconnectTimer.cancel();
        this._reconnectTimer = null;
      }

      if (_waitingForConnect = false) {
        _waitingForConnect = true;
        _reconnectListenersHolder.onReconnectBegin();
      }

      this.close();
      this._status(ConnectStatus.dialing);
      final connection = WebSocketChannel.connect(Uri.parse(this._url));
      this._start(connection, _reconnectMsg());
      this._calls.values.forEach(
          (call) => _methodMsg(call.id, call.serviceMethod, call.args));
      this
          ._subs
          .values
          .forEach((call) => _subMsg(call.id, call.serviceMethod, call.args));
      _waitingForConnect = false;
      _reconnectListenersHolder.onConnected();
    } catch (err) {
      printError('DDP::ERROR::ON RECONNECT: $err');
      this.close();
      this._reconnectLater();
    }
  }

  void close() {
    if (this._pingTimer != null) {
      this._pingTimer.cancel();
      this._pingTimer = null;
    }

    if (this._socket != null) {
      this._socket.closeCode;
      this._socket = null;
    }

    this._collections.values.forEach((collection) => collection.reset());
    this._status(ConnectStatus.disconnected);
  }

  void _reconnectLater() {
    this.close();
    if (this._reconnectTimer == null) {
      this._reconnectTimer = Timer(this.reconnectInterval, this.reconnect);
    }
  }

  void ping() {
    if (this._socket != null) {
      this._send(_pingMsg());
      Future.delayed(this.heartbeatInterval, () {
        if (this._wasPingSent) {
          printError('Disconnected due to not received pong');
          printError('heartbeat interval is ${this.heartbeatInterval}');
          this._reconnectLater();
        }
      });
    }
  }

  void pong() {
    if (this._socket != null) {
      this._send(_pongMsg());
    }
  }

  void _initMessageHandlers() {
    this._messageHandlers = {};
    this._messageHandlers['connected'] = (msg) {
      this._status(ConnectStatus.connected);
      this._version = '1';
      this._sessionId = msg['session'] as String;
      this._pingTimer = Timer.periodic(this.heartbeatInterval, (timer) {
        this.ping();
      });
      this._connectionListener.forEach((l) => l());
    };

    this._messageHandlers['ping'] = (msg) {
      if (!this._wasPingSent) {
        this._wasPingSent = true;
        this._send(_pongMsg());
      }
    };

    this._messageHandlers['pong'] = (msg) {
      Future.delayed(this.heartbeatTimeOut, () {
        this._wasPingSent = false;
        this._send(_pingMsg());
      });
    };

    this._messageHandlers['nosub'] = (msg) {
      if (msg.containsKey('id')) {
        final id = msg['id'] as String;
        final runningSub = this._subs['id'];
        if (runningSub != null) {
          print(runningSub);
          this.printError('Subscription returned a nosub error $msg');
          runningSub.error =
              ArgumentError('Subscription returned a nosub error');
          runningSub.done();
          this._subs.remove(id);
        }

        final runningUnSub = this._unsubs[id];
        if (runningUnSub != null) {
          runningUnSub.done();
          this._unsubs.remove(id);
        }
      }
    };

    this._messageHandlers['ready'] = (msg) {
      if (msg.containsKey('subs')) {
        final subs = msg['subs'] as List<dynamic>;
        subs.forEach((sub) {
          if (this._subs.containsKey(sub)) {
            this._subs[sub].done();
            this._subs.remove(sub);
          }
        });
      }
    };
    this._messageHandlers['added'] =
        (msg) => this._collectionBy(msg).added(msg);
    this._messageHandlers['changed'] =
        (msg) => this._collectionBy(msg).changed(msg);
    this._messageHandlers['removed'] =
        (msg) => this._collectionBy(msg).removed(msg);
    this._messageHandlers['result'] = (msg) {
      if (msg.containsKey('id')) {
        final id = msg['id'];
        final call = this._calls[id];
        this._calls.remove(id);
        if (msg.containsKey('error')) {
          if (msg['error'] != null) {
            final e = msg['error'];
            call.error = ArgumentError(json.encode(e));
            call.reply = e;
          }
        } else {
          call.reply = msg['result'];
        }
        call.done();
      }
    };
  }

  void _inboxManager() {
    this._reader.listen((event) {
      log(event.toString(), '<-');
      final message = json.decode(event) as Map<String, dynamic>;
      if (message.containsKey('msg')) {
        final mtype = message['msg'];
        if (this._messageHandlers.containsKey(mtype)) {
          this._messageHandlers[mtype](message);
        } else {
          this.printWarning('Server sent unexpected message $message');
        }
      } else if (message.containsKey('server_id')) {
        final serverId = message['server_id'];
        if (serverId.runtimeType == String) {
          this._serverId = serverId;
        } else {
          print('Server cluster node $serverId');
        }
      } else {
        this.printWarning('Server sent message without `msg` field $message');
      }
    }, onDone: this._onDone, onError: this._onError, cancelOnError: true);
  }

  void _onDone() {
    this._status(ConnectStatus.disconnected);
    this.printError('Disconnect due to websocket onDone');
    this.printError(
        'Disconnected code: ${this._socket.closeCode}, reason: ${this._socket.closeReason}');
    this.printError('Schedule reconnect due to websocket onDone');
    this._reconnectLater();
  }

  void _onError(dynamic error) {
    this._status(ConnectStatus.disconnected);
    this.printError('Disconnect due to websocket onError');
    this.printError('Error: $error');
    this.printError('Schedule reconnect due to websocket onError');
    this._reconnectLater();
  }

  Collection collectionByName(String name) {
    if (!this._collections.containsKey(name)) {
      final collection = Collection.key(name);
      this._collections[name] = collection;
    }
    return this._collections[name];
  }

  Collection _collectionBy(Map<String, dynamic> msg) {
    if (msg.containsKey('collection')) {
      final name = msg['collection'];
      if (name.runtimeType == String) {
        return this.collectionByName(name);
      }
    }
    return Collection.mock();
  }

  Future<Call> call(String serviceMetod, List<dynamic> args) {
    final completer = Completer<Call>();
    return completer.future;
  }

  Future<Call> sub(String subName, List<dynamic> args) {
    final completer = Completer<Call>();
    return completer.future;
  }

  Future<Call> unSub(String id) {
    final completer = Completer<Call>();
    return completer.future;
  }
}

class Writer implements StreamSink<dynamic> {
  StreamSink<dynamic> _writer;

  Writer(this._writer);

  @override
  void add(event) {
    DDP.log(event.toString(), '->');
    this._writer.add(event);
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    this._writer.addError(error, stackTrace);
  }

  @override
  Future addStream(Stream stream) => this._writer.addStream(stream);

  @override
  Future close() => this._writer.close();

  @override
  Future get done => this._writer.done;

  void setWriter(WebSocketSink writer) {
    this._writer = _writer;
  }
}

class Reader extends Stream<dynamic> {
  Stream<dynamic> _reader;

  Reader(this._reader);

  @override
  StreamSubscription listen(void Function(dynamic event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    return this._reader.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  void setReader(Stream<dynamic> reader) {
    this._reader = reader;
  }
}
