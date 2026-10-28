import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/strings.dart';

/// Opens [uri] outside the app; shows a snack bar if that is not possible.
Future<void> openExternal(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception {
    opened = false;
  }
  if (!opened) messenger?.showSnackBar(const SnackBar(content: Text(S.linkFailed)));
}

/// Google Maps directions to a point; opens the Maps app where installed.
Uri directionsUri(double latitude, double longitude) =>
    Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': '$latitude,$longitude'});
