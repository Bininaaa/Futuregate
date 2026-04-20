import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/document_access_service.dart';

class ProjectIdeaCoverImage extends StatefulWidget {
  final String imageUrl;
  final String ideaId;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Color? placeholderColor;
  final Color? iconColor;

  const ProjectIdeaCoverImage({
    super.key,
    required this.imageUrl,
    this.ideaId = '',
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.placeholderColor,
    this.iconColor,
  });

  @override
  State<ProjectIdeaCoverImage> createState() => _ProjectIdeaCoverImageState();
}

class _ProjectIdeaCoverImageState extends State<ProjectIdeaCoverImage> {
  late Future<_ResolvedIdeaCoverRequest> _requestFuture;

  @override
  void initState() {
    super.initState();
    _requestFuture = _resolveRequest();
  }

  @override
  void didUpdateWidget(covariant ProjectIdeaCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.ideaId != widget.ideaId) {
      _requestFuture = _resolveRequest();
    }
  }

  Future<_ResolvedIdeaCoverRequest> _resolveRequest() async {
    final rawUrl = widget.imageUrl.trim();
    if (rawUrl.isEmpty) {
      return const _ResolvedIdeaCoverRequest(url: '');
    }

    if (!_isPrivateStorageAsset(rawUrl)) {
      return _ResolvedIdeaCoverRequest(url: rawUrl);
    }

    final ideaId = widget.ideaId.trim();
    if (ideaId.isNotEmpty) {
      try {
        final document = await DocumentAccessService()
            .getProjectIdeaImageDocument(ideaId: ideaId);
        final signedUrl = document.viewUrl.trim();
        if (signedUrl.isNotEmpty) {
          return _ResolvedIdeaCoverRequest(url: signedUrl);
        }
      } catch (_) {
        // Fall back to an owner-authenticated request when the secure image
        // route is unavailable or the idea has not been persisted yet.
      }
    }

    if (!kIsWeb) {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if ((idToken ?? '').trim().isNotEmpty) {
        return _ResolvedIdeaCoverRequest(
          url: rawUrl,
          headers: <String, String>{'Authorization': 'Bearer $idToken'},
        );
      }
    }

    return _ResolvedIdeaCoverRequest(url: rawUrl);
  }

  bool _isPrivateStorageAsset(String value) {
    if (!value.contains('/file/')) {
      return false;
    }

    return !value.contains('/file/ideas/') &&
        !value.contains('/file/profiles/');
  }

  Widget _buildPlaceholder() {
    return Container(
      height: widget.height,
      width: widget.width,
      color: widget.placeholderColor ?? Colors.transparent,
      alignment: Alignment.center,
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(
            (widget.iconColor ?? const Color(0xFF64748B)).withValues(
              alpha: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      height: widget.height,
      width: widget.width,
      color: widget.placeholderColor ?? Colors.transparent,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: widget.iconColor ?? const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildResolvedImage(_ResolvedIdeaCoverRequest request) {
    if (request.url.trim().isEmpty) {
      return _buildError();
    }

    return Image.network(
      request.url,
      headers: request.headers.isEmpty ? null : request.headers,
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return _buildPlaceholder();
      },
      errorBuilder: (_, _, _) => _buildError(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ResolvedIdeaCoverRequest>(
      future: _requestFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildPlaceholder();
        }

        final request = snapshot.data;
        if (request == null) {
          return _buildError();
        }

        return _buildResolvedImage(request);
      },
    );
  }
}

class _ResolvedIdeaCoverRequest {
  final String url;
  final Map<String, String> headers;

  const _ResolvedIdeaCoverRequest({
    required this.url,
    this.headers = const <String, String>{},
  });
}
