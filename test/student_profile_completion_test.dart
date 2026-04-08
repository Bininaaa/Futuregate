import 'package:avenirdz/models/cv_model.dart';
import 'package:avenirdz/models/user_model.dart';
import 'package:avenirdz/utils/student_profile_completion.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _buildStudent({
  String fullName = 'Yasser',
  String email = 'yasser@example.com',
  String phone = '0550123456',
  String location = 'Tlemcen',
  String academicLevel = 'Licence',
  String university = 'University of Tlemcen',
  String fieldOfStudy = 'Computer Science',
  String bio = 'Student builder',
}) {
  return UserModel(
    uid: 'student_1',
    fullName: fullName,
    email: email,
    role: 'student',
    phone: phone,
    location: location,
    profileImage: '',
    isActive: true,
    academicLevel: academicLevel,
    university: university,
    fieldOfStudy: fieldOfStudy,
    bio: bio,
  );
}

CvModel _buildCv({
  String uploadedCvUrl = '',
  String uploadedCvPath = '',
  String exportedPdfUrl = '',
  String exportedPdfPath = '',
  String summary = '',
}) {
  return CvModel(
    id: 'cv_1',
    studentId: 'student_1',
    fullName: '',
    email: '',
    phone: '',
    address: '',
    summary: summary,
    education: const [],
    experience: const [],
    skills: const [],
    languages: const [],
    sourceType: '',
    templateId: '',
    primaryCvMode: '',
    uploadedCvUrl: uploadedCvUrl,
    uploadedCvPath: uploadedCvPath,
    uploadedFileName: uploadedCvPath.isEmpty ? '' : 'primary_cv.pdf',
    uploadedCvMimeType: uploadedCvPath.isEmpty ? '' : 'application/pdf',
    exportedPdfUrl: exportedPdfUrl,
    exportedPdfPath: exportedPdfPath,
  );
}

void main() {
  test(
    'uploaded CV satisfies the CV requirement when the rest of the profile is complete',
    () {
      final summary = buildStudentProfileCompletionSummary(
        _buildStudent(),
        _buildCv(uploadedCvPath: 'cvs/student_1/primary_cv.pdf'),
      );

      expect(summary.hasReadyCv, isTrue);
      expect(summary.completionPercent, 100);
      expect(summary.missingItems, isEmpty);
    },
  );

  test('uploaded CV does not auto-complete missing profile fields', () {
    final summary = buildStudentProfileCompletionSummary(
      _buildStudent(phone: '', location: '', bio: ''),
      _buildCv(uploadedCvPath: 'cvs/student_1/primary_cv.pdf'),
    );

    expect(summary.hasReadyCv, isTrue);
    expect(summary.completionPercent, 67);
    expect(
      summary.missingItems,
      containsAll(<String>['Phone', 'Location', 'Bio']),
    );
  });

  test('missing CV keeps the profile below 100 percent', () {
    final summary = buildStudentProfileCompletionSummary(
      _buildStudent(),
      _buildCv(),
    );

    expect(summary.hasReadyCv, isFalse);
    expect(summary.completionPercent, 89);
    expect(summary.missingItems, contains('CV'));
  });
}
