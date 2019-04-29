A Dart package to interact with the Meteor framework.

Connect your web or flutter apps, written in Dart, to the Meteor framework.

## Usage

### Capturing the result of operations

You can use either the `then-catchError` or `await` syntax to capture the result of operations and handle errors.

**I'll be using the `await` syntax in this documentation to keep it short and straight.**
You can use either `catchError` on `Future` object or `try/catch` syntax to catch errors.

### Connection Operations

#### Connecting with Meteor

Using `then-catchError`:

```dart
import 'package:meteorify/meteorify.dart';

main() async{
  Meteor.connect("ws://example.meteor.com/websocket")
      .then((status){
          // Do something after connection is successful
      })
      .catchError((error){
          print(error);
          //Handle error
      });
}
```

Using `await`:

```dart
import 'package:meteorify/meteorify.dart';

main() async{
  try{
      var status = await Meteor.connect("ws://example.meteor.com/websocket");
      // Do something after connection is successful
  }catch(error){
      print(error);
      //Handle error
  }
}
```

#### Check connection status

```dart
var isConnected = Meteor.isConnected;		
```



#### Disconnect from server

```dart
Meteor.disconnect();
```



### Subscriptions

#### Subscribe to Data

```dart
var subscriptionId = await Meteor.subscribe(subscriptionName);
```



#### Unsubscribe from Data

```dart
await Meteor.unsubscribe(subscriptionId);
```



#### Get subscribed data/collection

```dart
SubscribedCollection collection = await Meteor.collection(collectionName);
//collection.find({selectors});
//collection.findAll();
//collection.findOne(id);
```



### Authentication

#### Creating New Account

```dart
var userId = await Accounts.createUser(username,email,password,profileOptions);
```



#### Login

1. Login with password

   ```dart
   String loginToken = await Meteor.loginWithPassword(email,password);
   ```

2. Login with token

   ```dart
   String token = await Meteor.loginWithToken(loginToken);
   ```

3. Change Password (need to be logged in)

   ```dart
   String result = await Accounts.changePassword(oldPassword,newPassword);
   ```

4. Forgot Password

   ```dart
   String result = await Accounts.forgotPassword(email);
   ```

   

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme
