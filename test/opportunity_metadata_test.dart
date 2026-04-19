import 'package:avenirdz/models/admin_application_item_model.dart';
import 'package:avenirdz/models/application_model.dart';
import 'package:avenirdz/models/opportunity_model.dart';
import 'package:avenirdz/models/saved_opportunity_model.dart';
import 'package:avenirdz/models/saved_scholarship_model.dart';
import 'package:avenirdz/models/scholarship_model.dart';
import 'package:avenirdz/services/company_service.dart';
import 'package:avenirdz/utils/opportunity_metadata.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OpportunityModel parses structured opportunity metadata safely', () {
    final opportunity = OpportunityModel.fromMap({
      'id': 'opp_1',
      'companyId': 'company_1',
      'companyName': 'TechDZ',
      'companyLogo': '',
      'title': 'Junior Frontend Developer',
      'description': 'Build product experiences.',
      'type': 'job',
      'location': 'Algiers',
      'requirements': 'Flutter, Firebase',
      'status': 'open',
      'deadline': '2026-04-30',
      'applicationDeadline': Timestamp.fromDate(DateTime(2026, 4, 30)),
      'salaryMin': 50000,
      'salaryMax': 70000,
      'salaryCurrency': 'dzd',
      'salaryPeriod': 'monthly',
      'compensationText': 'Competitive package',
      'employmentType': 'full-time',
      'workMode': 'on site',
      'isPaid': true,
      'duration': null,
    });

    expect(opportunity.salaryMin, 50000);
    expect(opportunity.salaryMax, 70000);
    expect(opportunity.salaryCurrency, 'DZD');
    expect(opportunity.salaryPeriod, 'month');
    expect(opportunity.employmentType, 'full_time');
    expect(opportunity.workMode, 'onsite');
    expect(opportunity.isPaid, isTrue);
    expect(opportunity.deadlineLabel, '2026-04-30');
  });

  test(
    'Opportunity metadata formatter builds salary and internship labels',
    () {
      final label = OpportunityMetadata.buildCompensationLabel(
        salaryMin: 45000,
        salaryMax: 60000,
        salaryCurrency: 'DZD',
        salaryPeriod: 'month',
        isPaid: true,
      );
      final items = OpportunityMetadata.buildMetadataItems(
        type: 'internship',
        salaryMin: 20000,
        salaryMax: 30000,
        salaryCurrency: 'DZD',
        salaryPeriod: 'month',
        isPaid: true,
        employmentType: 'part_time',
        workMode: 'hybrid',
        duration: '2 months',
        maxItems: 4,
      );

      expect(label, '45k-60k DZD / month');
      expect(
        items,
        containsAll(<String>['20k-30k DZD / month', 'Part-time', 'Hybrid']),
      );
      expect(items, contains('2 months'));
    },
  );

  test('Opportunity metadata formatter falls back to paid labels', () {
    expect(OpportunityMetadata.buildCompensationLabel(isPaid: false), 'Unpaid');
    expect(
      OpportunityMetadata.buildCompensationLabel(
        compensationText: 'Stipend disclosed during interview',
        preferCompensationText: true,
      ),
      'Stipend disclosed during interview',
    );
  });

  test('Employment type options follow selected opportunity type', () {
    expect(
      OpportunityMetadata.employmentTypesForOpportunityType('job'),
      isNot(contains('internship')),
    );
    expect(
      OpportunityMetadata.employmentTypesForOpportunityType('internship'),
      <String>['internship'],
    );
  });

  test('Sponsored opportunity funding is parsed and formatted separately', () {
    final opportunity = OpportunityModel.fromMap({
      'id': 'opp_funding',
      'companyId': 'company_1',
      'companyName': 'SponsorDZ',
      'companyLogo': '',
      'title': 'Prototype Funding Program',
      'description': 'Support student teams building prototypes.',
      'type': 'sponsored',
      'location': 'Algiers',
      'requirements': 'Working prototype\nClear project budget',
      'requirementItems': ['Working prototype', 'Clear project budget'],
      'status': 'open',
      'deadline': '2026-05-30',
      'fundingAmount': '250000',
      'fundingCurrency': 'dzd',
      'fundingNote': 'Covers prototype costs and mentoring',
    });

    expect(opportunity.type, 'sponsoring');
    expect(opportunity.fundingAmount, 250000);
    expect(opportunity.fundingCurrency, 'DZD');
    expect(opportunity.fundingNote, 'Covers prototype costs and mentoring');
    expect(opportunity.fundingLabel(), '250k DZD');
    expect(
      opportunity.fundingLabel(includePrefix: true),
      'Company funding: 250k DZD',
    );
    expect(opportunity.requirementItems, <String>[
      'Working prototype',
      'Clear project budget',
    ]);
  });

  test(
    'Sponsored opportunity payload clears salary fields and keeps funding',
    () {
      final normalized = CompanyService.normalizeOpportunityPayload({
        'title': 'Student Launch Sponsoring',
        'description': 'Support student launch teams.',
        'type': 'sponsoring',
        'location': 'Remote',
        'requirements': 'Student team\nClear budget',
        'requirementItems': ['Student team', 'Student team', 'Clear budget'],
        'status': 'open',
        'deadline': '2026-06-01',
        'salaryMin': '60000',
        'salaryMax': '90000',
        'salaryCurrency': 'USD',
        'salaryPeriod': 'month',
        'fundingAmount': '500',
        'fundingCurrency': 'usd',
        'fundingNote': 'Covers materials',
      }, isCreate: true);

      expect(normalized['salaryMin'], isNull);
      expect(normalized['salaryMax'], isNull);
      expect(normalized['salaryCurrency'], isNull);
      expect(normalized['salaryPeriod'], isNull);
      expect(normalized['fundingAmount'], 500);
      expect(normalized['fundingCurrency'], 'USD');
      expect(normalized['fundingNote'], 'Covers materials');
      expect(normalized['requirementItems'], <String>[
        'Student team',
        'Clear budget',
      ]);
    },
  );

  test('ScholarshipModel prefers structured eligibility items', () {
    final scholarship = ScholarshipModel.fromMap({
      'id': 'sch_1',
      'title': 'Future Builders Scholarship',
      'description': 'Funding for strong students.',
      'provider': 'FutureGate',
      'eligibility': 'Legacy eligibility paragraph',
      'eligibilityItems': ['Open to Master students', 'Minimum GPA required'],
      'amount': 100000,
      'deadline': '2026-07-01',
      'link': 'example.com',
      'createdBy': 'admin_1',
      'createdByRole': 'admin',
    });

    expect(scholarship.eligibilityItems, <String>[
      'Open to Master students',
      'Minimum GPA required',
    ]);
    expect(scholarship.toMap()['eligibilityItems'], <String>[
      'Open to Master students',
      'Minimum GPA required',
    ]);
  });

  test('OpportunityModel detects only explicit admin-posted opportunities', () {
    final adminOpportunity = OpportunityModel.fromMap({
      'id': 'opp_admin',
      'companyId': 'admin_1',
      'companyName': 'FutureGate',
      'companyLogo': '',
      'title': 'Curated Role',
      'description': 'A role posted by an admin.',
      'type': 'job',
      'location': 'Algiers',
      'requirements': 'Flutter',
      'status': 'open',
      'deadline': '2026-04-30',
      'createdByRole': ' ADMIN ',
    });

    final companyOpportunity = OpportunityModel.fromMap({
      'id': 'opp_company',
      'companyId': 'company_1',
      'companyName': 'TechDZ',
      'companyLogo': '',
      'title': 'Company Role',
      'description': 'A role posted by a company.',
      'type': 'job',
      'location': 'Algiers',
      'requirements': 'Flutter',
      'status': 'open',
      'deadline': '2026-04-30',
      'createdByRole': 'company',
    });

    final legacyOpportunity = OpportunityModel.fromMap({
      'id': 'opp_legacy',
      'companyId': 'owner_1',
      'companyName': 'Unknown',
      'companyLogo': '',
      'title': 'Legacy Role',
      'description': 'A role without origin metadata.',
      'type': 'job',
      'location': 'Algiers',
      'requirements': 'Flutter',
      'status': 'open',
      'deadline': '2026-04-30',
    });

    expect(adminOpportunity.isAdminPosted, isTrue);
    expect(companyOpportunity.isAdminPosted, isFalse);
    expect(legacyOpportunity.isAdminPosted, isFalse);
  });

  test('Opportunity deadlines drive effective closed status', () {
    final now = DateTime(2026, 4, 13, 12);
    final futureOpportunity = OpportunityModel.fromMap({
      'id': 'opp_future',
      'companyId': 'company_1',
      'companyName': 'TechDZ',
      'companyLogo': '',
      'title': 'Future Role',
      'description': 'Still open.',
      'type': 'job',
      'location': 'Algiers',
      'requirements': 'Flutter',
      'status': 'open',
      'deadline': '2026-04-14',
    });
    final expiredOpportunity = OpportunityModel.fromMap({
      'id': 'opp_expired',
      'companyId': 'company_1',
      'companyName': 'TechDZ',
      'companyLogo': '',
      'title': 'Expired Role',
      'description': 'Past deadline.',
      'type': 'job',
      'location': 'Algiers',
      'requirements': 'Flutter',
      'status': 'open',
      'deadline': '2026-04-12',
    });
    final manuallyClosedOpportunity = OpportunityModel.fromMap({
      'id': 'opp_closed',
      'companyId': 'company_1',
      'companyName': 'TechDZ',
      'companyLogo': '',
      'title': 'Closed Role',
      'description': 'Closed manually.',
      'type': 'job',
      'location': 'Algiers',
      'requirements': 'Flutter',
      'status': 'closed',
      'deadline': '2026-04-30',
    });

    expect(futureOpportunity.effectiveStatus(now: now), 'open');
    expect(futureOpportunity.isVisibleToStudents(now: now), isTrue);
    expect(expiredOpportunity.effectiveStatus(now: now), 'closed');
    expect(expiredOpportunity.isVisibleToStudents(now: now), isFalse);
    expect(manuallyClosedOpportunity.effectiveStatus(now: now), 'closed');
  });

  test('Date-only deadlines remain valid until the end of the day', () {
    final opportunity = OpportunityModel.fromMap({
      'id': 'opp_last_day',
      'companyId': 'company_1',
      'companyName': 'TechDZ',
      'companyLogo': '',
      'title': 'Last Day Role',
      'description': 'Deadline is today.',
      'type': 'job',
      'location': 'Algiers',
      'requirements': 'Flutter',
      'status': 'open',
      'deadline': '2026-04-13',
    });

    expect(
      opportunity.isDeadlineExpired(
        now: DateTime(2026, 4, 13, 23, 59, 59, 999),
      ),
      isFalse,
    );
    expect(opportunity.isDeadlineExpired(now: DateTime(2026, 4, 14)), isTrue);
  });

  test('Saved snapshots and scholarships expose deadline expiry', () {
    final savedOpportunity = SavedOpportunityModel(
      id: 'saved_1',
      opportunityId: 'opp_1',
      studentId: 'student_1',
      title: 'Saved role',
      companyName: 'TechDZ',
      type: 'job',
      location: 'Algiers',
      deadline: '2026-04-12',
    );
    const savedScholarship = SavedScholarshipModel(
      id: 'saved_sch_1',
      scholarshipId: 'sch_1',
      studentId: 'student_1',
      title: 'Saved scholarship',
      provider: 'FutureGate',
      deadline: '2026-04-12',
      location: 'Algiers',
      fundingType: 'Fully funded',
      level: 'Master',
    );
    final scholarship = ScholarshipModel.fromMap({
      'id': 'sch_expired',
      'title': 'Expired Scholarship',
      'description': 'Past deadline.',
      'provider': 'FutureGate',
      'eligibility': 'Students',
      'amount': 1000,
      'deadline': '2026-04-12',
      'link': 'https://example.com',
      'createdBy': 'admin_1',
      'createdByRole': 'admin',
    });
    final now = DateTime(2026, 4, 13);

    expect(savedOpportunity.isDeadlineExpired(now: now), isTrue);
    expect(savedScholarship.isDeadlineExpired(now: now), isTrue);
    expect(scholarship.isVisibleToStudents(now: now), isFalse);
  });

  test('Admin applications are manageable only for the owning admin post', () {
    final application = ApplicationModel(
      id: 'app_1',
      studentId: 'student_1',
      studentName: 'Student',
      opportunityId: 'opp_1',
      companyId: 'admin_1',
      cvId: 'cv_1',
      status: 'pending',
    );

    final adminPostedApplication = AdminApplicationItemModel(
      application: application,
      companyId: 'admin_1',
      opportunityCreatedByRole: 'admin',
    );
    final companyPostedApplication = AdminApplicationItemModel(
      application: application,
      companyId: 'company_1',
      opportunityCreatedByRole: 'company',
    );

    expect(adminPostedApplication.canBeManagedByAdmin('admin_1'), isTrue);
    expect(adminPostedApplication.canBeManagedByAdmin('admin_2'), isFalse);
    expect(companyPostedApplication.canBeManagedByAdmin('admin_1'), isFalse);
  });
}
