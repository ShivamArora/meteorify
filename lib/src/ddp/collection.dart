import 'package:tuple/tuple.dart';

typedef UpdateListener = void Function(
  String collection,
  String operation,
  String id,
  Map<String, dynamic> doc,
);

Tuple2<String, Map<String, dynamic>> _parse(Map<String, dynamic> update) {
  if (update.containsKey('id')) {
    final _id = update['id'];
    if (_id.runtimeType == String) {
      if (update.containsKey('fields')) {
        final _updates = update['fields'];
        if (_updates is Map) {
          return Tuple2(_id, _updates as Map<String, dynamic>);
        }
      }
      return Tuple2(_id, Map<String, dynamic>.from({}));
    }
  }
  return Tuple2('', Map<String, dynamic>.from({}));
}

abstract class Collection {
  void notify(String operation, String id, Map<String, dynamic> doc);

  void added(Map<String, dynamic> doc);

  void changed(Map<String, dynamic> doc);

  void removed(Map<String, dynamic> doc);

  void reset();

  void addUpdateListener(UpdateListener listener);

  void removeUpdateListeners();

  Map<String, Map<String, dynamic>> findAll();

  Map<String, dynamic> findOne(String id);

  factory Collection.mock() => _MockCache();

  factory Collection.key(String name) => KeyCache(name, {}, []);
}

class KeyCache implements Collection {
  String name;
  Map<String, Map<String, dynamic>> _items;
  List<UpdateListener> _listeners;

  KeyCache(this.name, this._items, this._listeners);

  @override
  void notify(String operation, String id, Map<String, dynamic> doc) {
    this._listeners.forEach((listener) {
      listener(this.name, operation, id, doc);
    });
  }

  @override
  void added(Map<String, dynamic> doc) {
    final _pair = _parse(doc);
    if (_pair.item2.isNotEmpty) {
      this._items[_pair.item1] = _pair.item2;
      this.notify('create', _pair.item1, _pair.item2);
    }
  }

  @override
  void changed(Map<String, dynamic> doc) {
    final _pair = _parse(doc);
    // ignore: unnecessary_null_comparison
    if (_pair.item2 != null) {
      if (this._items.containsKey((_pair.item1))) {
        final _item = this._items[_pair.item1];
        _pair.item2.forEach((key, value) => _item![key] = value);
        this._items[_pair.item1] = _item as Map<String, dynamic>;
        this.notify('update', _pair.item1, _item);
      }
    }
  }

  @override
  void removed(Map<String, dynamic> doc) {
    final _pair = _parse(doc);
    // ignore: unnecessary_null_comparison
    if (_pair.item1 != null) {
      this._items.remove(_pair.item1);
      this.notify('remove', _pair.item1, Map<String, dynamic>());
    }
  }

  @override
  void reset() {
    this.notify('reset', '', Map<String, dynamic>());
  }

  @override
  void addUpdateListener(UpdateListener listener) {
    this._listeners.add(listener);
  }

  @override
  void removeUpdateListeners() {
    this._listeners.clear();
  }

  @override
  Map<String, Map<String, dynamic>> findAll() => this._items;

  @override
  Map<String, dynamic> findOne(String id) => this._items[id]!;
}

class _MockCache implements Collection {
  @override
  void addUpdateListener(UpdateListener listener) {}

  @override
  void added(Map<String, dynamic> doc) {}

  @override
  void changed(Map<String, dynamic> doc) {}

  @override
  Map<String, Map<String, dynamic>> findAll() => {};

  @override
  Map<String, dynamic> findOne(String id) => {};

  @override
  void notify(String operation, String id, Map<String, dynamic> doc) {}

  @override
  void removeUpdateListeners() {}

  @override
  void removed(Map<String, dynamic> doc) {}

  @override
  void reset() {}
}
