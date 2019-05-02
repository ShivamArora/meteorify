A Dart package to interact with the Meteor framework.

Connect your web or flutter apps, written in Dart, to the Meteor framework.





## Features 

- Connect to Meteor server
- Use Meteor Subscriptions
- Meteor Authentication
- Call custom Methods on Meteor
- Access underlying databases



## Dependency

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  meteorify: ^1.0.1
```





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

5. Reset Password

   ```dart
   String result = await Accounts.resetPassword(resetToken,newPassword);
   ```

6. Logout

   ```dart
   await Meteor.logout();
   ```

7. Get logged in userId

   ```dart
   String userId = Meteor.currentUserId;
   ```

8. Check if logged in

   ```dart
   bool isLoggedIn = Meteor.isLoggedIn();
   ```

9. Get current user as map

   ```dart
   Map<String,dynamic> currentUser = await Meteor.userAsMap();
   ```



### Call Custom Methods

#### Defining custom methods in meteor server

```js
export const helloWorld = new ValidatedMethod({
  name: 'hello',
  validate: null,
  run({ firstname,lastname }) {
    const message = "hello "+firstname+" "+lastname;
    console.log(message);
    return message;
  },
});
```



#### Invoking custom methods

```dart
var result = await Meteor.client.call("hello",[{"firstname":"Shivam","lastname":"Arora"}]);
print(result.reply);
```



### Using Mongo Databases to manage data

Meteorify uses the `mongo_dart` package internally to provide access to actual database.

For more instructions regarding use of `mongo_dart` , visit their [mongo_dart guide](https://github.com/mongo-dart/mongo_dart).

#### Get Meteor Database

```dart
import 'package:mongo_dart/mongo_dart.dart';

Db db = await Meteor.getMeteorDatabase();
```



#### Get custom database

```dart
import 'package:mongo_dart/mongo_dart.dart';

Db db = await Meteor.getCustomDatabase(dbUrl);
await db.open();
```



#### Get collection

```dart
import 'package:mongo_dart/mongo_dart.dart';

DbCollection collection = await db.collection("collectionName");
```

