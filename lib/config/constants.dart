class AppConstants {
  static const String host = "localhost"; //79.137.34.134
  static const int port = 8000;

  // Use string interpolation to include host and port
  static String get baseApiUrl => "http://$host:$port";
  static String get baseWsUrl => "ws://$host:$port";
}
