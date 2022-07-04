import 'package:enhanced_meteorify/src/ddp/collection.dart';

/// Provides useful methods to read data from a collection on the frontend.
///
/// [SubscribedCollection] supports only read functionality useful in case of getting only the data subscribed by user and not any other data.
class SubscribedCollection {
  /// The internal collection instance.
  final Collection _collection;

  /// Name of the collection.
  String name;

  /// Construct a subscribed collection.
  SubscribedCollection(this._collection, this.name);

  /// Returns a single object by matching the [id] of the object.
  Map<String, dynamic> findOne(String id) {
    return _collection.findOne(id);
  }

  /// Returns all objects of the subscribed collection.
  Map<String, Map<String, dynamic>> findAll() {
    return _collection.findAll();
  }

  void addUpdateListener(UpdateListener listener) {
    _collection.addUpdateListener(listener);
  }

  void removeUpdateListeners() {
    _collection.removeUpdateListeners();
  }

  /// Returns specific objects from a subscribed collection using a set of [selectors].
  Map<String, Map<String, dynamic>> find(Map<String, dynamic> selectors) {
    var filteredCollection = <String, Map<String, dynamic>>{};
    _collection.findAll().forEach((key, document) {
      var shouldAdd = true;
      selectors.forEach((selector, value) {
        if (document[selector] != value) {
          shouldAdd = false;
        }
      });
      if (shouldAdd) {
        filteredCollection[key] = document;
      } else {
        print("Don't add");
      }
    });

    return filteredCollection;
  }
}
