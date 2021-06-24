import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'log.dart';

class Writer implements StreamSink<dynamic> {
  StreamSink<dynamic> _writer;
  bool _enableLogs = true;

  Writer(this._writer, {enableLogs = true}) {
    this._enableLogs = enableLogs;
  }

  @override
  void add(event) {
    if (_enableLogs) Log.info(event.toString(), '->');
    this._writer.add(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
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
  StreamSubscription listen(void Function(dynamic event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return this._reader.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  void setReader(Stream<dynamic> reader) {
    this._reader = reader;
  }
}
