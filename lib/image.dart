import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart';

// Random image service
final _uri = Uri.parse("https://picsum.photos/200/300");

Future<Uint8List> loadRandomImage() async {
  final image = await get(_uri);
  return image.bodyBytes;
}

