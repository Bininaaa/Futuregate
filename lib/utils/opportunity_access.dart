import '../models/application_model.dart';
import '../models/opportunity_model.dart';
import '../models/student_application_item_model.dart';
import '../models/subscription_model.dart';
import 'application_status.dart';

bool hasActivePremium(SubscriptionModel? subscription) =>
    subscription?.isActive ?? false;

bool isEarlyAccessActive(OpportunityModel opportunity) =>
    opportunity.isEarlyAccessActive;

bool isEarlyAccessLockedForUser(
  OpportunityModel opportunity,
  SubscriptionModel? subscription,
) {
  return isEarlyAccessActive(opportunity) && !hasActivePremium(subscription);
}

bool canApplyNow(
  OpportunityModel opportunity,
  SubscriptionModel? subscription, {
  bool hasApplied = false,
  bool isClosed = false,
}) {
  if (hasApplied || isClosed) {
    return false;
  }

  if (opportunity.effectiveStatus() != 'open') {
    return false;
  }

  return !isEarlyAccessLockedForUser(opportunity, subscription);
}

Duration? getRemainingEarlyAccessTime(OpportunityModel opportunity) {
  final publicVisibleAt = opportunity.publicVisibleAt;
  if (!isEarlyAccessActive(opportunity) || publicVisibleAt == null) {
    return null;
  }

  final remaining = publicVisibleAt.difference(DateTime.now());
  if (remaining.isNegative) {
    return Duration.zero;
  }

  return remaining;
}

bool shouldShowPriorityApplication(StudentApplicationItemModel? item) {
  final application = item?.application;
  if (application == null) {
    return false;
  }

  return shouldShowPriorityApplicationForModel(application);
}

bool shouldShowPriorityApplicationForModel(ApplicationModel application) {
  if (ApplicationStatus.parse(application.status) ==
      ApplicationStatus.withdrawn) {
    return false;
  }

  return application.priorityApplication || application.isPremiumAtApply;
}
