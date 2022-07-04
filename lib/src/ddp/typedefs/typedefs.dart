import '../classes/call.dart';
import '../enums/connect_status.dart';

typedef MessageHandler = Function(Map<String, dynamic> message);
typedef ConnectionListener = Function();
typedef StatusListener = Function(ConnectStatus status);
typedef OnCallDone = Function(Call call);
