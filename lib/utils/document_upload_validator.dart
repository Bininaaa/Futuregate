class DocumentUploadValidator {
  static const int primaryCvMaxBytes = 10 * 1024 * 1024;
  static const int commercialRegisterMaxBytes = 10 * 1024 * 1024;

  static String? validatePrimaryCv({
    required String fileName,
    required int sizeInBytes,
    String? mimeType,
  }) {
    if (fileName.trim().isEmpty) {
      return 'Select a PDF CV file.';
    }

    if (sizeInBytes <= 0) {
      return 'The selected CV file is empty.';
    }

    if (sizeInBytes > primaryCvMaxBytes) {
      return 'Primary CV must be smaller than 10 MB.';
    }

    if (!isPdf(fileName: fileName, mimeType: mimeType)) {
      return 'Primary CV must be uploaded as a PDF file.';
    }

    return null;
  }

  static String? validateCommercialRegister({
    required String fileName,
    required int sizeInBytes,
    String? mimeType,
  }) {
    if (fileName.trim().isEmpty) {
      return 'سجل تجاري is required.';
    }

    if (sizeInBytes <= 0) {
      return 'The selected سجل تجاري file is empty.';
    }

    if (sizeInBytes > commercialRegisterMaxBytes) {
      return 'سجل تجاري must be smaller than 10 MB.';
    }

    if (!isAllowedCommercialRegister(fileName: fileName, mimeType: mimeType)) {
      return 'سجل تجاري must be a PDF, JPG, or PNG file.';
    }

    return null;
  }

  static bool isPdf({required String fileName, String? mimeType}) {
    final normalizedMimeType = normalizeMimeType(
      fileName: fileName,
      mimeType: mimeType,
    );
    return normalizedMimeType == 'application/pdf';
  }

  static bool isAllowedCommercialRegister({
    required String fileName,
    String? mimeType,
  }) {
    final normalizedMimeType = normalizeMimeType(
      fileName: fileName,
      mimeType: mimeType,
    );

    return normalizedMimeType == 'application/pdf' ||
        normalizedMimeType == 'image/png' ||
        normalizedMimeType == 'image/jpeg';
  }

  static String normalizeMimeType({
    required String fileName,
    String? mimeType,
  }) {
    final normalizedMimeType = (mimeType ?? '').trim().toLowerCase();
    if (normalizedMimeType.isNotEmpty &&
        normalizedMimeType != 'application/octet-stream') {
      return normalizedMimeType;
    }

    final normalizedFileName = fileName.trim().toLowerCase();
    if (normalizedFileName.endsWith('.pdf')) {
      return 'application/pdf';
    }
    if (normalizedFileName.endsWith('.png')) {
      return 'image/png';
    }
    if (normalizedFileName.endsWith('.jpg') ||
        normalizedFileName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    return normalizedMimeType;
  }
}
