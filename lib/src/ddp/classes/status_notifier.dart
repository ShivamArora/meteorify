import '../typedefs/typedefs.dart';

abstract class StatusNotifier {
  void addStatusListener(StatusListener listener);

  void removeStatusListener(StatusListener listener);
}
