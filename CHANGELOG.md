## 1.0.4

- Updated `mongo_dart` to provide Dart 2.5 compatibility.



## 1.0.3

- Fixed the future already completed on status changed bug.

- Now, you can set a listener for the connection events.

  - ```dart
    Meteor.connectionListener = (ConnectionStatus connectionStatus){
      print(connectionStatus);
    }
    ```

- You can now provide a custom interval for checking the status of the server by specifying `heartbeatInterval` within `Meteor.connect()`

- You can now enable `autoLoginOnReconnect` to re-login the currently logged in user whenever the connection reconnects after a disconnection.



## 1.0.2

- Provided a method to call serviceMethods exported from Meteor using `Meteor.call()`.
- Provided documentation for most of the classes and methods.



## 1.0.1

- Improve package health and fix analysis issues



## 1.0.0

- Initial version, created by ShivamArora
- Features
  - Connect to Meteor server
  - Use Meteor Subscriptions
  - Meteor Authentication
  - Call Custom Methods on Meteor
  - Access underlying databases
