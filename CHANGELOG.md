## 3.1.0
 - Bug fixes
 - Rename `Accounts` methods to `Meteor` methods. 
    ```dart
    var userId = await Meteor.createUser(username, email, password, profileOptions);
    bool result = await Meteor.changePassword(oldPassword, newPassword);
    bool result = await Meteor.forgotPassword(email);
    bool result = await Meteor.resetPassword(resetToken, newPassword);
    ```
 - Throwing subscription errors. Catch them all!
    ```dart
    try {
        var result = await Meteor.subscribe('test');
    } on MeteorError catch (e) {
        print(e.reason);
    }
    ```

## 3.0.3
 - Add suport to Meteor 2.3 🥳
 - Will no longer try to reconnect after `Meteor.disconnect()` [#4](https://github.com/wendellrocha/enhanced_meteorify/issues/4)

## 3.0.2
 - Added `enableLogs` argument (default: true) to Meteor.connect to enable or disable DDP logs (does not affect error logs) [#2](https://github.com/wendellrocha/enhanced_meteorify/issues/2)
  ```dart
   await Meteor.connect(
      'ws://' + Constants.URL_SERVIDOR + '/websocket',
      reconnectInterval: Duration(seconds: 1),
      autoLoginOnReconnect: true,
      enableLogs: false,
    );
  ```

## 3.0.1 
 - [Null check operator used on a null value](https://github.com/wendellrocha/enhanced_meteorify/pull/1#issuecomment-852964934) thanks [@ruerob](https://github.com/ruerob)

## 3.0.0
 - Fixed wrong null usage [#1](https://github.com/wendellrocha/enhanced_meteorify/pull/1) thanks [@ruerob](https://github.com/ruerob)
 - Update web_socket_channel
 - Update tuple
 - Update shared_preferences
 - Update crypto
 - Remove enhanced_ddp dependency
 - DDP rewritten, killing bugs and empowering enhanced meteorify
 - Null safety version 🥳
 - enhanced_ddp package is now deprecated

## 3.0.0-nullsafety.3
 - Fixed unexpected null value

## 3.0.0-nullsafety.2
 - Fixed unexpected null value

## 3.0.0-nullsafety.1
 - Fix analysis suggestions

## 3.0.0-nullsafety.0
 - Remove enhanced_ddp dependency
 - DDP rewritten, killing bugs and empowering enhanced meteorify
 - Null safety version 🥳
 - enhanced_ddp package is now deprecated

## 2.3.4
 - Update enhanced_ddp package

## 2.3.3+6
 - loginWithToken

## 2.3.3+4
 - loginWithToken

## 2.3.3
 - Update enhanced_ddp package

## 2.3.2
 - Update enhanced_ddp package

## 2.3.1
 - On logout remove _currentUserId

## 2.3.0
 - `Meteor.subscriptionsReady()` notify about subscriptions

## 2.2.0
 - Notify on subscriptions ready `Meteor.subscriptionsReady(['subscriptionName', ... 'subscriptionName'])`

## 2.1.7
 - Release

## 2.1.6
 - Release

## 2.1.5
 - Change heartbeat interval to 25s
 - Check if _seasonToken is null or empty
 - Update enhanced_ddp package

## 2.1.4
 - Change default heartbeatInterval to 10s
 - Update README
 - Update enhanced_ddp package 

## 2.1.3
 - Surround _loginWithToken with try...catch

## 2.1.2
 - Fix _notifyLogin return

## 2.1.1
 - Fix _notifyLogin return

## 2.1.0
- Update DDP Package
- Throw Meteor erros

## 2.0.1
- Update enhanced_ddp

## 2.0.0
 - 🚀
 - Stable
 - Remove mongo_dart package
 - Drop support to getCustomDatabase and getMeteorDatabase
 - Update shared_preferences to support flutter web

## 1.0.12
  - Update enhanced_ddp package

## 1.0.11
  - Update enhanced_ddp package
  - Add SubscribedCollection.removeUpdateListener
  
## 1.0.10
  - Update enhanced_ddp package
  
## 1.0.9
  - Sending encrypted password over the ddp

## 1.0.8
  - Save loginToken on shared preferences
  - Auto reconnect on connection lost (enhanced_ddp)

## 1.0.7
  - Update enhanced_ddp package
  
## 1.0.6
  - Update enhanced_ddp package

## 1.0.5
  - Remove DDP package
  - Add Enhanced_DDP package

## 1.0.4
  - Update README
  - Authentication with Apple* (needs sever-side code in JavaScript for use with Meteor)
  
  *Login with Apple currently only supports iOS 13+.
  
## 1.0.3
  - Update README
  - Authentication with Facebook (needs sever-side code in JavaScript for use with Meteor)
 
## 1.0.2
  - 🚀

## 1.0.1
  - Connect and login with loginWithPassword example

## 1.0.0

- Initial version
- Features
  - Connect to Meteor server
  - Use Meteor Subscriptions
  - Meteor Authentication
  - Authentication with Google oAuth (needs server-side code in JavaScript for use with Meteor)
  - Call Custom Methods on Meteor
  - Access underlying databases
