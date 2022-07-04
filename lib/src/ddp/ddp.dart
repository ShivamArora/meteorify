import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../enhanced_meteorify.dart';
import 'classes/call.dart';
import 'classes/connection_notifier.dart';
import 'classes/id_manager.dart';
import 'classes/reconnect_listener.dart';
import 'classes/reconnect_listener_holder.dart';
import 'classes/status_notifier.dart';
import 'collection.dart';
import 'enums/connect_status.dart';
import 'log.dart';
import 'message.dart';
import 'stream.dart';
import 'typedefs/typedefs.dart';

class DDP implements ConnectionNotifier, StatusNotifier {
  Duration reconnectInterval;

  bool _waitingForConnect = false;
  bool _isTryToReconnect = true;
  bool _enableLogs = true;

  String _sessionId = '';
  // ignore: unused_field
  String _serverId = '';
  String _url;
  String _version = '1';
  List<String> _support = ["1", "pre2", "pre1"];

  WebSocketChannel? _socket;
  Reader? _reader;
  // ignore: close_sinks
  Writer? _writer;
  IdManager? _idManager;

  Timer? _reconnectTimer;

  Map<String, Call>? calls;
  Map<String, Call>? _subs;
  Map<String, Call>? _unsubs;
  Map<String, Collection>? _collections;
  Map<String, MessageHandler>? _messageHandlers;
  List<dynamic>? _subscriptions;

  ConnectStatus? _connectStatus;
  List<StatusListener>? _statusListeners;
  List<ConnectionListener>? _connectionListener;
  ReconnectListenersHolder _reconnectListenersHolder =
      ReconnectListenersHolder();

  DDP(
    this._url, {
    this.reconnectInterval = const Duration(seconds: 30),
    bool enableLogs = true,
  }) {
    this._url = _url;
    this._serverId = '';
    this._waitingForConnect = false;
    this._enableLogs = enableLogs;
    this._idManager = IdManager();
    this._collections = {};
    this.calls = {};
    this._subs = {};
    this._unsubs = {};
    this._connectStatus = ConnectStatus.disconnected;
    this._statusListeners = [];
    this._connectionListener = [];
    this._subscriptions = [];
  }

  void addReconnectListener(ReconnectListener listener) {
    _reconnectListenersHolder.addReconnectListener(listener);
  }

  void removeReconnectListener(ReconnectListener listener) {
    _reconnectListenersHolder.removeReconnectListener(listener);
  }

  @override
  void addConnectionListener(ConnectionListener listener) {
    this._connectionListener!.add(listener);
  }

  @override
  void addStatusListener(StatusListener listener) {
    this._statusListeners!.add(listener);
  }

  @override
  void removeStatusListener(StatusListener listener) {
    this._statusListeners!.remove(listener);
  }

  String get session => _sessionId;

  String get version => _version;

  void _status(ConnectStatus status) {
    if (this._connectStatus == status) {
      return;
    }

    this._connectStatus = status;
    this._statusListeners!.forEach((l) => l(status));
  }

  void _send(String msg) {
    this._writer!.add(msg);
  }

  void _start(WebSocketChannel ws, String msg) {
    this._status(ConnectStatus.connecting);

    this._initMessageHandlers();
    this._socket = ws;

    this._reader = Reader(ws.stream);
    this._writer = Writer(ws.sink, enableLogs: this._enableLogs);
    this._inboxManager();
    this._send(msg);
  }

  void connect() async {
    try {
      if (!_waitingForConnect) {
        _waitingForConnect = true;
        _reconnectListenersHolder.onReconnectBegin();
      }

      this._status(ConnectStatus.dialing);
      _isTryToReconnect = true;
      final ws = WebSocketChannel.connect(Uri.parse(this._url));

      this._start(
        ws,
        Message.connect(
          this._sessionId,
          this._version,
          this._support,
        ),
      );

      _reconnectListenersHolder.onConnected();
    } catch (err) {
      Log.error('DDP::ERROR::ON CONNECT: $err');
      this._reconnectLater();
    }
  }

  void reconnect() {
    try {
      if (this._reconnectTimer != null) {
        this._reconnectTimer!.cancel();
        this._reconnectTimer = null;
      }

      _reconnectListenersHolder.onReconnectBegin();

      this.close();
      this._status(ConnectStatus.dialing);
      _isTryToReconnect = true;
      final connection = WebSocketChannel.connect(Uri.parse(this._url));
      this._start(
        connection,
        Message.connect(
          this._sessionId,
          this._version,
          this._support,
        ),
      );

      this.calls!.values.forEach((call) {
        this._send(
          Message.method(
            call.id!,
            call.serviceMethod!,
            call.args,
          ),
        );
      });

      this._subs!.values.forEach((call) {
        this._send(
          Message.sub(
            call.id!,
            call.serviceMethod!,
            call.args,
          ),
        );
      });

      _reconnectListenersHolder.onConnected();
    } catch (err) {
      if (err.toString().contains('No route to host')) {
        Log.error('DDP::ERROR::ON RECONNECT: $err');
        this.close();
      } else {
        Log.error('DDP::ERROR::ON RECONNECT: $err');
        this.close();
        this._reconnectLater();
      }
    }
  }

  void close() {
    if (this._socket != null && !_isTryToReconnect) {
      this._socket!.sink.close();
      _isTryToReconnect = false;
    }

    this._collections!.values.forEach((collection) => collection.reset());
    this._status(ConnectStatus.disconnected);
  }

  void _reconnectLater() {
    this.close();
    if (this._reconnectTimer == null) {
      this._reconnectTimer = Timer(this.reconnectInterval, () {
        this.reconnect();
      });
    }
  }

  void _ping() async {
    if (this._socket != null) {
      this._send(Message.ping());
    }
  }

  void _pong() {
    if (this._socket != null) {
      this._send(Message.pong());
    }
  }

  void _initMessageHandlers() {
    this._messageHandlers = {};
    this._messageHandlers!['connected'] = (msg) {
      this._status(ConnectStatus.connected);
      this._collections!.values.forEach((c) => c.init());
      this._version = '1';
      this._sessionId = msg['session'] as String;
      this._connectionListener!.forEach((l) => l());
    };
    this._messageHandlers!['ping'] = (msg) {
      this._pong();
    };
    this._messageHandlers!['pong'] = (msg) {
      this._ping();
    };
    this._messageHandlers!['nosub'] = (msg) {
      if (msg.containsKey('id')) {
        final id = msg['id'] as String;
        final runningSub = this._subs![id];

        if (runningSub != null) {
          if (msg.containsKey('error')) {
            Log.error('Subscription returned a nosub error $msg');
            runningSub.reply = msg;
            runningSub.error = MeteorError.parse(msg['error']);
            runningSub.done();
            this._subs!.remove(id);
          }
        }

        final runningUnSub = this._unsubs![id];
        if (runningUnSub != null) {
          runningUnSub.done();
          this._unsubs!.remove(id);
        }
      }
    };
    this._messageHandlers!['ready'] = (msg) {
      if (msg.containsKey('subs')) {
        this._subscriptions = msg['subs'] as List<dynamic>;
        _subscriptions!.forEach((sub) {
          if (this._subs!.containsKey(sub)) {
            this._subs![sub]!.done();
            this._subs!.remove(sub);
          }
        });
      }
    };
    this._messageHandlers!['added'] =
        (msg) => this._collectionBy(msg)!.added(msg);
    this._messageHandlers!['changed'] =
        (msg) => this._collectionBy(msg)!.changed(msg);
    this._messageHandlers!['removed'] =
        (msg) => this._collectionBy(msg)!.removed(msg);
    this._messageHandlers!['result'] = (msg) {
      if (msg.containsKey('id')) {
        final id = msg['id'];
        final call = this.calls![id];
        this.calls!.remove(id);
        if (msg.containsKey('error')) {
          if (msg['error'] != null) {
            final e = msg['error'];
            call!.error = ArgumentError(json.encode(e));
            call.reply = e;
          }
        } else {
          call!.reply = msg['result'];
        }
        call!.done();
      }
    };
    this._messageHandlers!['updated'] = (msg) {};
    this._messageHandlers!['error'] = (msg) {
      this._notifyError(msg);
    };
  }

  void _inboxManager() {
    this._reader?.listen((event) {
      final message = json.decode(event) as Map<String, dynamic>;
      if (this._enableLogs) Log.info(event, '<-');
      if (message.containsKey('msg')) {
        final mtype = message['msg'];

        if (this._messageHandlers!.containsKey(mtype)) {
          this._messageHandlers![mtype]!(message);
        } else {
          if (this._enableLogs)
            Log.warn('Server sent unexpected message $message');
        }
      } else if (message.containsKey('server_id')) {
        final serverId = message['server_id'];
        if (serverId.runtimeType == String) {
          this._serverId = serverId;
        } else {
          print('Server cluster node $serverId');
        }
      } else {
        if (message.containsKey('testMessageOnConnect')) {
          Log.info(
            'Server send message to test connection. Message: $message',
            '!',
          );
        } else {
          if (this._enableLogs)
            Log.warn('Server sent message without `msg` field $message');
        }
      }
    }, onDone: this._onDone, onError: this._onError, cancelOnError: true);
  }

  void _notifyError(Map<String, dynamic> error) {
    Log.error('Server returned an error: $error');
  }

  void _onDone() {
    if (_isTryToReconnect) {
      this._status(ConnectStatus.disconnected);
      Log.error('Disconnect due to websocket onDone');
      Log.error(
        'Disconnected code: ${this._socket?.closeCode},'
        ' reason: ${this._socket?.closeReason}',
      );
      Log.error('Schedule reconnect due to websocket onDone');
      this._reconnectLater();
    } else {
      this.close();
    }
  }

  void _onError(dynamic error) {
    if (error.toString().contains('No route to host')) {
      this._status(ConnectStatus.disconnected);
      Log.error('Disconnect due to websocket onError');
      Log.error('Error: $error');
    } else {
      Log.error('Schedule reconnect due to websocket onError');
      this._reconnectLater();
    }
  }

  Collection? collectionByName(String name) {
    if (!this._collections!.containsKey(name)) {
      final collection = Collection.key(name);
      this._collections![name] = collection;
    }
    return this._collections![name];
  }

  Collection? _collectionBy(Map<String, dynamic> msg) {
    if (msg.containsKey('collection')) {
      final name = msg['collection'];
      if (name.runtimeType == String) {
        return this.collectionByName(name);
      }
    }
    return Collection.mock();
  }

  Call _apply(String serviceMethod, OnCallDone done, List<dynamic> args) {
    final _call = Call()
      ..id = this._idManager!.next()
      ..serviceMethod = serviceMethod
      ..args = args
      ..owner = this;

    _call.onceDone(done);
    this.calls![_call.id!] = _call;
    this._send(Message.method(_call.id!, serviceMethod, args));
    return _call;
  }

  Future<Call> call(String serviceMetod, List<dynamic> args) {
    final completer = Completer<Call>();
    this._apply(serviceMetod, (call) => completer.complete(call), args);
    return completer.future;
  }

  Future<Call> sub(String subName, List<dynamic> args) {
    final completer = Completer<Call>();
    this._subscribe(subName, (call) => completer.complete(call), args);
    return completer.future;
  }

  Future<Call> unSub(String id) {
    final completer = Completer<Call>();
    this._unSubscribe(id, (call) => completer.complete(call));
    return completer.future;
  }

  Call _subscribe(String subName, OnCallDone? done, List<dynamic> args) {
    final latestSub = this._subs!.keys.singleWhere(
          (element) => element.contains(subName),
          orElse: () => '',
        );
    final _call = Call()
      ..id = latestSub.isNotEmpty ? latestSub : '$subName-${_idManager!.next()}'
      ..serviceMethod = subName
      ..args = args
      ..owner = this;

    if (done == null) {
      done = (call) {};
    }

    _call.onceDone(done);
    this._subs![_call.id!] = _call;
    this._send(Message.sub(_call.id!, subName, args));
    return _call;
  }

  Call _unSubscribe(String id, OnCallDone? done) {
    final _call = Call()
      ..id = id
      ..owner = this;

    if (done == null) {
      done = (call) {};
    }

    _call.onceDone(done);
    this._unsubs![_call.id!] = _call;
    this._send(Message.unSub(_call.id!));
    return _call;
  }
}
