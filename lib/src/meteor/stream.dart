import 'dart:async';
import 'package:rxdart/rxdart.dart';

class UserId {
  BehaviorSubject<String> _controller;
  UserId(this._controller);

  Stream get stream => _controller.stream;
  get add => _controller.sink.add;
  String get lasValue => _controller.value;
}
