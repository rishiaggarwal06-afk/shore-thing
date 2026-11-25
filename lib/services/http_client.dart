import 'package:http/http.dart' as http;

import 'http_client_other.dart' if (dart.library.io) 'http_client_io.dart' as impl;

/// The HTTP client for the weather forecast. On iPhone it uses Apple's own networking
/// (NSURLSession, the same as Safari), which copes better with mobile networks than
/// Dart's built-in one; elsewhere (web, tests) the standard client.
http.Client makeHttpClient() => impl.makeClient();
