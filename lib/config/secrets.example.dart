// Template for your private keys. To use it:
//   1. Copy this file to lib/config/secrets.dart
//   2. Put your real keys there.
// secrets.dart is gitignored, so your keys never go to GitHub.
//
// Map keys ship inside the app and website, so anyone determined can find them.
// Protect them in the provider's dashboard instead: restrict the website's key to
// your site's address and watch usage.

class Secrets {
  /// MapTiler map key (cloud.maptiler.com → API keys). Leave as-is to use the
  /// built-in Natural Earth map instead (no key, no outside requests).
  static const maptilerKey = 'YOUR_MAPTILER_KEY';
}
