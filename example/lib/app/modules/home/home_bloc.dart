import 'package:enhanced_meteorify/enhanced_meteorify.dart';
import 'package:example/app/modules/home/person_model.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:rxdart/rxdart.dart';

class HomeBloc extends Disposable {
  BehaviorSubject _controller = BehaviorSubject();

  get stream => _controller.stream;
  get add => _controller.sink.add;
  get listen => _controller.value;

  var _subId;
  var _doc;

  int _count = 0;
  SubscribedCollection _collection;

  fetch({bool reset = false}) async {
    try {
      if (reset || _subId == null) {
        if (_collection != null || _doc != null) {
          await _unsubscribe();
        }

        _subId = await Meteor.subscribe("Person");
        _collection = await Meteor.collection("Person");

        _doc = _collection.findAll();

        if (_doc != null) {
          Map<String, dynamic> obj = {};
          _doc.forEach((id, item) {
            if (id != null && item != null) {
              obj = _obj(id, item);
            }
          });

          PersonModel retorno = PersonModel.fromJson(obj);

          if (!_controller.isClosed) {
            _controller.add(retorno);
          }
        }
        var updateListener = (
          String collection,
          String operation,
          String id,
          Map<String, dynamic> document,
        ) {
          if (operation == 'reset') {
            _count++;
            if (_count == 1) {
              clean();
              fetch(
                reset: true,
              );
              return;
            }
          }
          if (id != null && document != null) {
            if ((operation != 'remove' && operation != 'reset')) {
              PersonModel novo = PersonModel.fromJson(_obj(id, document));
              if (!_controller.isClosed) {
                _controller.add(novo);
              }
              return;
            }
          }

          if (operation == 'remove') {
            if (!_controller.isClosed) {
              _controller.add(null);
            }
          }
        };
        _collection.removeUpdateListeners();
        _collection.addUpdateListener(updateListener);
      }
      return _subId;
    } catch (error) {
      print(error);
    }
  }

  clean() {
    if (_subId != null && (_doc != null && _doc.length > 0)) {
      _doc.clear();
      _controller.add(null);
      _unsubscribe();
    }
  }

  _unsubscribe() async {
    final String _id = await _subId;
    Meteor.unsubscribe(_id);
  }

  @override
  void dispose() {
    clean();
    _controller.close();
  }

  _obj(id, item) {
    return {
      "_id": id,
      "name": item['name'],
      "username": item['username'],
      "status": item['status'],
    };
  }
}
