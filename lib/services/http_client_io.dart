import 'dart:io';

import 'package:cupertino_http/cupertino_http.dart';
import 'package:http/http.dart' as http;

http.Client makeClient() {
  if (Platform.isIOS || Platform.isMacOS) {
    final config = URLSessionConfiguration.ephemeralSessionConfiguration()
      ..timeoutIntervalForRequest = const Duration(seconds: 20)
      ..waitsForConnectivity = false;
    return CupertinoClient.fromSessionConfiguration(config);
  }
  return http.Client();
}
