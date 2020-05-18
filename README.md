# Enhanced Meteorify


Carefully extended [meteorify](https://github.com/ShivamArora/meteorify) package to interact with the Meteor framework.

Connect your web or flutter apps, written in Dart, to the Meteor framework.



## Features 

- Connect to Meteor server
- Use Meteor Subscriptions
- Meteor Authentication
- oAuth Authentication with Google, Facebook and Apple* (needs [server-side code in JavaScript](https://gist.github.com/wendellrocha/794b2154bb18ce2b81b21c5da79cc76e) for use with Meteor)
- Call custom Methods on Meteor
- Access underlying databases

*Login with Apple currently only supports iOS 13+.


## Dependency

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  enhanced_meteorify: ^1.0.3
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
  Meteor.connect('ws://example.meteor.com/websocket')
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
      var status = await Meteor.connect('ws://example.meteor.com/websocket');
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

#### Listen for connection updates

```dart
Meteor.connectionListener = (ConnectionStatus connectionStatus){
  print(connectionStatus);
}
```



### Subscriptions

#### Subscribe to Data

```dart
var subscriptionId = await Meteor.subscribe(subscriptionName);
```



#### Subscriptions with Parameters

```dart
var subscriptionId = await Meteor.subscribe(subscriptionName,args:[arg1,arg2]);
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
var userId = await Accounts.createUser(username, email, password, profileOptions);
```



#### Login

1. Login with password

   ```dart
   // Login with email
   String loginToken = await Meteor.loginWithPassword(email, password);

   // Login with username
   String loginToken = await Meteor.loginWithPassword(username, password);
   ```

2. Login with token

   ```dart
   String token = await Meteor.loginWithToken(loginToken);
   ```

3. Login with Google

   ```dart
   // `email` to register with. Must be fetched from the Google oAuth API
   // The unique Google `userId`. Must be fetched from the Google oAuth API
   // `authHeaders` from Google oAuth API for server side validation
   String token = await Meteor.loginWithGoogle(email, userId, authHeaders)
   ```

   Install google_sing_in package
   ```yml
   dependencies:
      flutter:
         sdk: flutter
      
      google_sign_in: ^4.4.4
   ```

   ```dart
   import 'package:google_sign_in/google_sign_in.dart';

   GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['profile', 'email', 'openid'],
   );

   Future<void> _loginWithGoogle(context) async {
    try {
      var info = await _googleSignIn.signIn();
      var authHeaders = await info.authHeaders;
      var result = await Meteor.loginWithGoogle(info.email, info.id, authHeaders);
     
      print(result);
    } catch (error) {
      print(error);
    }
   }
   ```

4. Login with Facebook
   
   ```dart
   // [userId] the unique Facebook userId. Must be fetched from the Facebook Login API
   // [token] the token from Facebook API Login for server side validation
   String token = await Meteor.loginWithFacebook(userId, token)
   ```

   Install flutter_facebook_login package
   ```yml
   dependencies:
      flutter:
         sdk: flutter
      
      flutter_facebook_login: ^3.0.0
   ```

   ```dart
   import 'package:flutter_facebook_login/flutter_facebook_login.dart';

   Future<void> _loginWithFacebook(context) async {
      final result = await facebookLogin.logIn(['email, public_profile']);

      switch (result.status) {
      case FacebookLoginStatus.loggedIn:
         var userId = result.accessToken.userId;
         var token = result.accessToken.userId;
         var res = await Meteor.loginWithFacebook(userId, token);
         
         print(res);
         break;
      case FacebookLoginStatus.cancelledByUser:
         print(':/');
         break;
      case FacebookLoginStatus.error:
         print('error: ${result.errorMessage}');
         break;
      }
   }
   ```

5. Login with Apple
   
   ```dart
   // [userId] the unique Apple userId. Must be fetch from the Apple Login API
   // [email] to register with. Must be fetched from the Apple Login API
   // [givenName] user's given Name. Must be fetched from the Apple Login API
   // [lastName] user's last Name. Must be fetched from the Apple Login API
   String token = await Meteor.loginWithApple(userId, email, givenName, lastName)
   ```


   Install flutter_facebook_login package
   ```yml
   dependencies:
      flutter:
         sdk: flutter
      
      apple_sign_in: ^0.1.0
   ```

   ```dart
   Future<void> _loginWithApple(context) async {
    try {
      final AuthorizationResult result = await AppleSignIn.performRequests([
        AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
      ]);

      switch (result.status) {
        case AuthorizationStatus.authorized:
          var email = result.credential.email;
          var givenName = result.credential.fullName.givenName;
          var lastName = result.credential.fullName.familyName;
          var userId = result.credential.user;

          var res = Meteor.loginWithApple(userId, email, givenName, lastName);
         
          print(res);
          break;
        case AuthorizationStatus.error:
          print('Erro: ${result.error.localizedDescription}');
          break;
        case AuthorizationStatus.cancelled:
          print(':/');
          break;
      }
    } catch (error) {
      print(error);
    }
  }
   ```

6. Change Password (need to be logged in)

   ```dart
   String result = await Accounts.changePassword(oldPassword, newPassword);
   ```

7. Forgot Password

   ```dart
   String result = await Accounts.forgotPassword(email);
   ```

8. Reset Password

   ```dart
   String result = await Accounts.resetPassword(resetToken, newPassword);
   ```

9.  Logout

   ```dart
   await Meteor.logout();
   ```

11. Get logged in userId

   ```dart
   String userId = Meteor.currentUserId;
   ```

11. Check if logged in

   ```dart
   bool isLoggedIn = Meteor.isLoggedIn();
   ```

11. Get current user as map

   ```dart
   Map<String,dynamic> currentUser = await Meteor.userAsMap();
   ```



### Call Custom Methods

#### Defining custom methods in meteor server

```js
export const helloWorld = new ValidatedMethod({
  name: 'hello',
  validate: new SimpleSchema({
    firstname: {type: String},
    lastname: {type: String},
  }).validator(),
  run({ firstname,lastname }) {
    const message = "hello "+ firstname + " " + lastname;
    console.log(message);
    return message;
  },
});
```



#### Invoking custom methods

```dart
try{
  var result = await Meteor.call('hello',[{'firstname':'Shivam','lastname':'Arora'}]);
  print(result);
}catch(error){
  print(error);
}
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

DbCollection collection = await db.collection('collectionName');
```

