import 'package:avenirdz/models/application_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ApplicationModel omits empty subscription snapshots from writes', () {
    final application = ApplicationModel(
      id: 'student_1_opp_1',
      studentId: 'student_1',
      studentName: 'Student One',
      opportunityId: 'opp_1',
      companyId: 'company_1',
      cvId: '',
      status: 'pending',
    );

    final data = application.toMap();

    expect(data['isPremiumAtApply'], isFalse);
    expect(data['priorityApplication'], isFalse);
    expect(data.containsKey('subscriptionSnapshot'), isFalse);
    expect(application.shouldPrioritizeApplication, isFalse);
  });

  test('ApplicationModel reads applicantUid when studentId is missing', () {
    final application = ApplicationModel.fromMap({
      'id': 'student_1_opp_1',
      'applicantUid': 'student_1',
      'studentName': 'Student One',
      'opportunityId': 'opp_1',
      'companyId': 'company_1',
      'cvId': '',
      'status': 'pending',
    });

    expect(application.studentId, 'student_1');
  });

  test('ApplicationModel preserves premium application snapshots', () {
    final expiresAt = Timestamp.fromDate(DateTime(2026, 9, 1));
    final application = ApplicationModel(
      id: 'student_1_opp_1',
      studentId: 'student_1',
      studentName: 'Student One',
      opportunityId: 'opp_1',
      companyId: 'company_1',
      cvId: '',
      status: 'pending',
      isPremiumAtApply: true,
      priorityApplication: true,
      subscriptionSnapshot: {
        'plan': 'semester',
        'status': 'active',
        'expiresAt': expiresAt,
      },
    );

    final data = application.toMap();

    expect(data['subscriptionSnapshot'], {
      'plan': 'semester',
      'status': 'active',
      'expiresAt': expiresAt,
    });
    expect(application.shouldPrioritizeApplication, isTrue);
  });

  test(
    'Priority comparator sorts premium applications before newer free ones',
    () {
      final olderPremium = ApplicationModel(
        id: 'premium',
        studentId: 'student_1',
        studentName: 'Premium Student',
        opportunityId: 'opp_1',
        companyId: 'company_1',
        cvId: '',
        status: 'pending',
        appliedAt: Timestamp.fromDate(DateTime(2026, 5, 1, 9)),
        priorityApplication: true,
      );
      final newerFree = ApplicationModel(
        id: 'free',
        studentId: 'student_2',
        studentName: 'Free Student',
        opportunityId: 'opp_1',
        companyId: 'company_1',
        cvId: '',
        status: 'pending',
        appliedAt: Timestamp.fromDate(DateTime(2026, 5, 1, 10)),
      );
      final newestPriorityFromLegacyFlag = ApplicationModel(
        id: 'legacy',
        studentId: 'student_3',
        studentName: 'Legacy Premium Student',
        opportunityId: 'opp_1',
        companyId: 'company_1',
        cvId: '',
        status: 'pending',
        appliedAt: Timestamp.fromDate(DateTime(2026, 5, 1, 11)),
        isPremiumAtApply: true,
      );

      final applications = [
        newerFree,
        olderPremium,
        newestPriorityFromLegacyFlag,
      ]..sort(ApplicationModel.comparePriorityThenRecent);

      expect(applications.map((application) => application.id), [
        'legacy',
        'premium',
        'free',
      ]);
    },
  );
}
