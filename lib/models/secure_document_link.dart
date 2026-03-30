class SecureDocumentLink {
  final String viewUrl;
  final String downloadUrl;
  final String fileName;
  final String mimeType;
  final String storagePath;

  const SecureDocumentLink({
    required this.viewUrl,
    required this.downloadUrl,
    required this.fileName,
    required this.mimeType,
    required this.storagePath,
  });

  factory SecureDocumentLink.fromMap(Map<String, dynamic> map) {
    return SecureDocumentLink(
      viewUrl: (map['viewUrl'] ?? '') as String,
      downloadUrl: (map['downloadUrl'] ?? '') as String,
      fileName: (map['fileName'] ?? '') as String,
      mimeType: (map['mimeType'] ?? '') as String,
      storagePath: (map['storagePath'] ?? '') as String,
    );
  }

  bool get isPdf {
    final normalizedMimeType = mimeType.trim().toLowerCase();
    if (normalizedMimeType == 'application/pdf') {
      return true;
    }

    return fileName.trim().toLowerCase().endsWith('.pdf');
  }

  bool get isImage {
    final normalizedMimeType = mimeType.trim().toLowerCase();
    if (normalizedMimeType.startsWith('image/')) {
      return true;
    }

    final normalizedFileName = fileName.trim().toLowerCase();
    return normalizedFileName.endsWith('.png') ||
        normalizedFileName.endsWith('.jpg') ||
        normalizedFileName.endsWith('.jpeg');
  }
}
