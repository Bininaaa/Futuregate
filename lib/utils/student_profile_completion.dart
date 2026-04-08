import '../models/cv_model.dart';
import '../models/user_model.dart';

class StudentProfileCompletionSummary {
  const StudentProfileCompletionSummary({
    required this.completedChecks,
    required this.totalChecks,
    required this.missingItems,
    required this.hasReadyCv,
  });

  final int completedChecks;
  final int totalChecks;
  final List<String> missingItems;
  final bool hasReadyCv;

  double get completion => totalChecks == 0 ? 0 : completedChecks / totalChecks;
  int get completionPercent => (completion * 100).round();
  int get missingCount => missingItems.length;
  bool get isComplete => completedChecks >= totalChecks;
}

StudentProfileCompletionSummary buildStudentProfileCompletionSummary(
  UserModel? user,
  CvModel? cv,
) {
  final hasReadyCv = hasReadyStudentCv(cv);
  final checks = <bool>[
    (user?.fullName ?? '').trim().isNotEmpty,
    (user?.email ?? '').trim().isNotEmpty,
    (user?.phone ?? '').trim().isNotEmpty,
    (user?.location ?? '').trim().isNotEmpty,
    (user?.academicLevel ?? '').trim().isNotEmpty,
    (user?.university ?? '').trim().isNotEmpty,
    (user?.fieldOfStudy ?? '').trim().isNotEmpty,
    (user?.bio ?? '').trim().isNotEmpty,
    hasReadyCv,
  ];

  final missingItems = <String>[
    if ((user?.fullName ?? '').trim().isEmpty) 'Full name',
    if ((user?.email ?? '').trim().isEmpty) 'Email',
    if ((user?.phone ?? '').trim().isEmpty) 'Phone',
    if ((user?.location ?? '').trim().isEmpty) 'Location',
    if ((user?.academicLevel ?? '').trim().isEmpty) 'Academic level',
    if ((user?.university ?? '').trim().isEmpty) 'University',
    if ((user?.fieldOfStudy ?? '').trim().isEmpty) 'Field of study',
    if ((user?.bio ?? '').trim().isEmpty) 'Bio',
    if (!hasReadyCv) 'CV',
  ];

  return StudentProfileCompletionSummary(
    completedChecks: checks.where((value) => value).length,
    totalChecks: checks.length,
    missingItems: missingItems,
    hasReadyCv: hasReadyCv,
  );
}

bool hasReadyStudentCv(CvModel? cv) {
  if (cv == null) {
    return false;
  }

  return cv.hasUploadedCv || cv.hasExportedPdf || cv.hasBuilderContent;
}
