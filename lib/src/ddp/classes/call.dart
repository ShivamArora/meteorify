import '../ddp.dart';
import '../typedefs/typedefs.dart';

class Call {
  String? id;
  String? serviceMethod;
  dynamic args;
  dynamic reply;
  Error? error;
  DDP? owner;
  List<OnCallDone> _handlers = [];

  void onceDone(OnCallDone fn) {
    this._handlers.add(fn);
  }

  void done() {
    owner!.calls!.remove(this.id);
    _handlers.forEach((handler) => handler(this));
    _handlers.clear();
  }

  @override
  String toString() => 'Call(id: $id, serviceMethod: $serviceMethod,'
      ' args: $args, reply: $reply, error: $error';
}
