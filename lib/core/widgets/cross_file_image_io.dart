import 'dart:io';
import 'package:flutter/widgets.dart';

Widget renderFileImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  return Image.file(File(path), fit: fit, errorBuilder: errorBuilder);
}
