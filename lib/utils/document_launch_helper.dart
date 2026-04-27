import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/secure_document_link.dart';
import '../widgets/shared/app_feedback.dart';

class DocumentLaunchHelper {
  const DocumentLaunchHelper._();

  static Uri? normalizeHttpUri(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) {
      return null;
    }

    final value = raw.contains('://') ? raw : 'https://$raw';
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.trim().isEmpty) {
      return null;
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'https' && scheme != 'http') {
      return null;
    }

    return uri;
  }

  static Future<bool> openUrl(
    BuildContext context, {
    required String url,
    required String unavailableMessage,
    required String unavailableTitle,
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    final uri = normalizeHttpUri(url);
    if (uri == null) {
      context.showAppSnackBar(
        unavailableMessage,
        title: unavailableTitle,
        type: AppFeedbackType.error,
      );
      return false;
    }

    final launched = await launchUrl(
      uri,
      mode: mode,
      webOnlyWindowName: '_blank',
    );
    if (!context.mounted) {
      return launched;
    }

    if (!launched) {
      context.showAppSnackBar(
        unavailableMessage,
        title: unavailableTitle,
        type: AppFeedbackType.error,
      );
    }
    return launched;
  }

  static Future<bool> openSecureDocument(
    BuildContext context, {
    required SecureDocumentLink document,
    required bool download,
    required bool requirePdf,
    required String notPdfMessage,
    required String unavailableMessage,
    required String unavailableTitle,
    String? notPdfTitle,
  }) async {
    if (requirePdf && !document.isPdf) {
      context.showAppSnackBar(
        notPdfMessage,
        title: notPdfTitle ?? unavailableTitle,
        type: AppFeedbackType.warning,
      );
      return false;
    }

    final url = download ? document.downloadUrl : document.viewUrl;
    return openUrl(
      context,
      url: url,
      unavailableMessage: unavailableMessage,
      unavailableTitle: unavailableTitle,
      mode: LaunchMode.platformDefault,
    );
  }
}
