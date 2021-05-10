# Enhanced Meteorify
[![Pub](https://img.shields.io/pub/v/enhanced_meteorify?include_prereleases)](https://pub.dev/packages/enhanced_meteorify)

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
  enhanced_meteorify: ^2.3.4
```


Null safety:

```yaml
dependencies:
  enhanced_meteorify: ^3.0.0
```


## Usage

### Capturing the result of operations

You can use the `await` syntax to capture the result of operations and handle errors.

**I'll be using the `await` syntax in this documentation to keep it short and straight.**

### Connection Operations

#### Connecting with Meteor

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

### Listen for userId
```dart
Meteor.currentUserIdListener = (String userId) {
    print(userId);
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
   try {
      String loginToken = await Meteor.loginWithPassword(email, password);
   } catch(error) {
      print(error);
   }

   // Login with username
   try {
      String loginToken = await Meteor.loginWithPassword(username, password);
   } catch(error) {
      print(error);
   }
   ```

2. Login with token

   ```dart
   try {
      String token = await Meteor.loginWithToken(loginToken);
   } catch(error) {
      print(error);
   }
   ```

3. Login with Google

   ```dart
   // `email` to register with. Must be fetched from the Google oAuth API
   // The unique Google `userId`. Must be fetched from the Google oAuth API
   // `authHeaders` from Google oAuth API for server side validation
   try {
      String token = await Meteor.loginWithGoogle(email, userId, authHeaders)
   } catch(error) {
      print(error);
   }
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
   try {
      String token = await Meteor.loginWithFacebook(userId, token)
   } catch(error) {
      print(error);
   }
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
   // [jwt] the jwt from Apple API Login to get user's e-mail
   // [givenName] user's given Name. Must be fetched from the Apple Login API
   // [lastName] user's last Name. Must be fetched from the Apple Login API
   try {
      String token = await Meteor.loginWithApple(userId, jwt, givenName, lastName)
   } catch(error) {
      print(error);
   }
   ```


   Install apple_sign_in package
   ```yml
   dependencies:
      flutter:
         sdk: flutter
      
      apple_sign_in: ^0.1.0
   ```

   ```dart
   import 'package:apple_sign_in/apple_sign_in.dart';

   Future<void> _loginWithApple(context) async {
    try {
      final AuthorizationResult result = await AppleSignIn.performRequests([
        AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
      ]);

      switch (result.status) {
        case AuthorizationStatus.authorized:
          var userId = result.credential.user;
          var jwt = result.credential.identityToken;
          var givenName = result.credential.fullName.givenName;
          var lastName = result.credential.fullName.familyName;

          var res = await Meteor.loginWithApple(userId, jwt, givenName, lastName);
         
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
  var result = await Meteor.call('hello',[{'firstname':'Wendell','lastname':'Rocha'}]);
  print(result);
}catch(error){
  print(error);
}
```
