class AdminActivityPreviewModel {
  final String collection;
  final String documentId;
  final Map<String, dynamic> data;
  final String relatedCollection;
  final String relatedDocumentId;
  final Map<String, dynamic>? relatedData;

  const AdminActivityPreviewModel({
    required this.collection,
    required this.documentId,
    required this.data,
    this.relatedCollection = '',
    this.relatedDocumentId = '',
    this.relatedData,
  });
}
