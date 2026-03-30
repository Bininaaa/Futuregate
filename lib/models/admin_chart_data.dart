class AdminChartData {
  final int totalUsers;
  final int totalStudents;
  final int totalCompanies;
  final int totalOpportunities;
  final int totalApplications;
  final int bacCount;
  final int licenceCount;
  final int masterCount;
  final int doctoratCount;
  final List<MonthlyStat> monthlyRegistrations;

  AdminChartData({
    required this.totalUsers,
    required this.totalStudents,
    required this.totalCompanies,
    required this.totalOpportunities,
    required this.totalApplications,
    required this.bacCount,
    required this.licenceCount,
    required this.masterCount,
    required this.doctoratCount,
    required this.monthlyRegistrations,
  });
}

class MonthlyStat {
  final String month;
  final int count;

  MonthlyStat({
    required this.month,
    required this.count,
  });
}
