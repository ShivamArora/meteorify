class Log {
  static void info(String msg, String direction) {
    switch (direction) {
      case '->':
        print('\x1B[34m[DDP] -> :: $msg\x1B[0m');
        break;
      case '<-':
        print('\x1B[34m[DDP] <- :: $msg\x1B[0m');
        break;
      default:
        print('\x1B[34m[DDP] $direction :: $msg\x1B[0m');
    }
  }

  static void warn(String text) {
    print('\x1B[33m[DDP] :: $text\x1B[0m');
  }

  static void error(String text) {
    print('\x1B[31m[DDP] :: $text\x1B[0m');
  }
}
