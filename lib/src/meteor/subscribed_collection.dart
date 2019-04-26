import 'package:ddp/ddp.dart';

class SubscribedCollection{
  Collection _collection;
  SubscribedCollection(this._collection);

  Map<String, dynamic> findOne(String id) {
    return _collection.findOne(id);
  }

  Map<String, Map<String, dynamic>> findAll() {
    return _collection.findAll();
  }

  void addUpdateListener(UpdateListener listener) {
    _collection.addUpdateListener(listener);
  }

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