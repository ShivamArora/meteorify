class Log {
  static void info(String msg) {
    print('\x1B[36m[ENHANCED METEORIFY] :: $msg\x1B[0m');
  }

  static void warn(String text) {
    print('\x1B[33m[ENHANCED METEORIFY] :: $text\x1B[0m');
  }

  static void error(String text) {
    print('\x1B[31m[ENHANCED METEORIFY] :: $text\x1B[0m');
  }
}
