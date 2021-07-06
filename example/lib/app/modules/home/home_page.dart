import 'package:enhanced_meteorify/enhanced_meteorify.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'home_bloc.dart';

class HomePage extends StatefulWidget {
  final String title;
  const HomePage({Key key, this.title = "Home"}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _bloc = Modular.get<HomeBloc>();
  String methodWithoutArguments = '';
  String methodWithArguments = '';
  String methodError = '';

  @override
  void initState() {
    Meteor.connectionListener = (value) {
      print(value);
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                children: [
                  ElevatedButton(
                      onPressed: () async {
                        try {
                          var result = await Meteor.call('method.test', []);
                          setState(() {
                            methodWithoutArguments = result;
                          });
                        } on MeteorError catch (error) {
                          print(error);
                        }
                      },
                      child: Text('Method without arguments')),
                  SizedBox(height: 10),
                  Text('$methodWithoutArguments'),
                  SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: () async {
                        try {
                          var result =
                              await Meteor.call('method.test.args', ['teste']);
                          setState(() {
                            methodWithArguments = result;
                          });
                        } on MeteorError catch (error) {
                          print(error);
                        }
                      },
                      child: Text('Method with arguments')),
                  SizedBox(height: 10),
                  Text('$methodWithArguments'),
                  SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: () async {
                        try {
                          await Meteor.call('method.test.argsaa', []);
                        } on MeteorError catch (error) {
                          setState(() {
                            methodError = error.reason;
                          });
                        }
                      },
                      child: Text('Method error')),
                  SizedBox(height: 10),
                  Text('$methodError'),
                  SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: () async {
                        try {
                          await Meteor.loginWithPassword('wendell', '3297862');
                          _bloc.fetch();
                        } on MeteorError catch (error) {
                          print(error);
                        }
                      },
                      child: Text('Login')),
                  SizedBox(height: 10),
                  Text('UserId: ${Meteor.currentUserId}'),
                  if (Meteor.currentUserId.isNotEmpty)
                    Text('Logado')
                  else
                    Text('Deslogado'),
                  ElevatedButton(
                      onPressed: () async {
                        try {
                          Meteor.logout();
                        } on MeteorError catch (error) {
                          print(error);
                        }
                      },
                      child: Text('Logout')),
                  SizedBox(height: 10),
                  Text('UserId: ${Meteor.currentUserId}'),
                  SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: () async {
                        try {
                          Meteor.disconnect();
                        } on MeteorError catch (error) {
                          print(error);
                        }
                      },
                      child: Text('Disconnected')),
                  SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: () async {
                        try {
                          Meteor.reconnect();
                        } on MeteorError catch (error) {
                          print(error);
                        }
                      },
                      child: Text('Reconnect')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
