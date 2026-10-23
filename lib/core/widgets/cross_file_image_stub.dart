import 'package:flutter/widgets.dart';

Widget renderFileImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  return Image.network(path, fit: fit, errorBuilder: errorBuilder);
}
