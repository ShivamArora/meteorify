import 'dart:async';

import 'package:ddp/ddp.dart';
import 'package:meteorify/meteorify.dart';
import 'package:meteorify/src/listeners/listeners.dart';

class SubscribedCollection{
  Collection _collection;
  String name;
  SubscribedCollection(this._collection,this.name);

  Map<String, dynamic> findOne(String id) {
    return _collection.findOne(id);
  }

  Map<String, Map<String, dynamic>> findAll() {
    return _collection.findAll();
  }

  void addUpdateListener(UpdateListener listener) {
    _collection.addUpdateListener(listener);
  }

  //TODO: Check/reduce the complexity of this method
  Map<String, Map<String, dynamic>> find(Map<String,dynamic> selectors){
    Map<String,Map<String,dynamic>> filteredCollection = Map<String,Map<String,dynamic>>();
    print("Finding docs");
    print(selectors.keys);
    _collection.findAll().forEach((key,document){
      bool shouldAdd = true;
      selectors.forEach((selector,value){
        print("Key: $selector");
        print("Value: ${document[selector]}");
        if(document[selector]!=value){
          shouldAdd = false;
        }
      });
      if(shouldAdd){
        print('Add');
        filteredCollection[key]=document;
      }
      else{
        print("Don't add");
      }

    });

    return filteredCollection;
  }

}