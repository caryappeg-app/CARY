import 'package:flutter/widgets.dart';
import 'cross_file_image_stub.dart'
    if (dart.library.io) 'cross_file_image_io.dart'
    if (dart.library.js_interop) 'cross_file_image_web.dart'
    if (dart.library.html) 'cross_file_image_web.dart';

Widget fileImageWidget(
  String path, {
  BoxFit fit = BoxFit.cover,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  return renderFileImage(path, fit: fit, errorBuilder: errorBuilder);
}
