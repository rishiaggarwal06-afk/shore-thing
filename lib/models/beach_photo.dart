/// A real photo of a beach, bundled in the app, with the credit its license requires.
class BeachPhoto {
  const BeachPhoto({
    required this.asset,
    required this.artist,
    required this.license,
    required this.source,
  });

  /// Path inside the app, e.g. assets/images/beaches/cape-may-1.jpg
  final String asset;

  /// Photographer / author as listed on Wikimedia Commons.
  final String artist;

  /// License name, e.g. "CC BY-SA 4.0".
  final String license;

  /// The photo's page on Wikimedia Commons.
  final String source;

  /// Short credit line shown under the photo.
  String get credit => 'Photo: $artist · $license · Wikimedia Commons';

  factory BeachPhoto.fromJson(Map<String, dynamic> j) => BeachPhoto(
        asset: j['asset'] as String,
        artist: j['artist'] as String,
        license: j['license'] as String,
        source: j['source'] as String,
      );
}
