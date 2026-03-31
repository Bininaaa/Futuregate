import 'package:avenirdz/models/opportunity_model.dart';
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
}
