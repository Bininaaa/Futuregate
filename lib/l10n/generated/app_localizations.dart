import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FutureGate'**
  String get appTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @unknownLanguage.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownLanguage;

  /// No description provided for @currentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentLabel;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @saveChangesLabel.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChangesLabel;

  /// No description provided for @publishLabel.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publishLabel;

  /// No description provided for @retryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLabel;

  /// No description provided for @removeLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeLabel;

  /// No description provided for @changeLabel.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeLabel;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @uploadLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get uploadLabel;

  /// No description provided for @changeImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Change image'**
  String get changeImageLabel;

  /// No description provided for @uploadImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload image'**
  String get uploadImageLabel;

  /// No description provided for @removeImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get removeImageLabel;

  /// No description provided for @selectLabel.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectLabel;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languagePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose app language'**
  String get languagePickerTitle;

  /// No description provided for @languagePickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apply English, French, or Arabic across the app instantly.'**
  String get languagePickerSubtitle;

  /// No description provided for @languageUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageUpdatedTitle;

  /// No description provided for @languageUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'The app language was updated successfully.'**
  String get languageUpdatedMessage;

  /// No description provided for @originalLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Posted language'**
  String get originalLanguageLabel;

  /// No description provided for @translatedFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Translated from'**
  String get translatedFromLabel;

  /// No description provided for @viewingTranslatedVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Viewing translated version'**
  String get viewingTranslatedVersionLabel;

  /// No description provided for @viewingOriginalVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Viewing original version'**
  String get viewingOriginalVersionLabel;

  /// No description provided for @translatedContentFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Translation unavailable, showing the original content.'**
  String get translatedContentFallbackLabel;

  /// No description provided for @unknownOriginalLanguage.
  ///
  /// In en, this message translates to:
  /// **'Unknown original language'**
  String get unknownOriginalLanguage;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @accountBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account blocked'**
  String get accountBlockedTitle;

  /// No description provided for @accountBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been blocked by an administrator. You can no longer access the platform. If you believe this is a mistake, please contact support.'**
  String get accountBlockedMessage;

  /// No description provided for @backToSignInLabel.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignInLabel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @preferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesTitle;

  /// No description provided for @preferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tune the app experience, review account details, and jump into the settings that matter most.'**
  String get preferencesSubtitle;

  /// No description provided for @experienceTitle.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experienceTitle;

  /// No description provided for @experienceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the experience polished, consistent, and easy to navigate.'**
  String get experienceSubtitle;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @accountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the connected profile and security flows already wired to your account.'**
  String get accountSubtitle;

  /// No description provided for @workspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get workspaceTitle;

  /// No description provided for @workspaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Jump straight into the core areas that shape your company presence.'**
  String get workspaceSubtitle;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportTitle;

  /// No description provided for @supportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Helpful destinations beyond profile management.'**
  String get supportSubtitle;

  /// No description provided for @companyWorkspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Company workspace'**
  String get companyWorkspaceTitle;

  /// No description provided for @companyWorkspaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile, security, and support all in one polished hub.'**
  String get companyWorkspaceSubtitle;

  /// No description provided for @companyWorkspaceBody.
  ///
  /// In en, this message translates to:
  /// **'Use this area to keep your brand presence sharp, stay on top of notifications, and manage the parts of the workspace you need most.'**
  String get companyWorkspaceBody;

  /// No description provided for @companyDashboardTabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track live activity, fresh applications, and what needs attention first.'**
  String get companyDashboardTabSubtitle;

  /// No description provided for @companyOpportunitiesTabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Publish roles, monitor listings, and keep hiring momentum clear.'**
  String get companyOpportunitiesTabSubtitle;

  /// No description provided for @companyApplicationsTabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review candidates, filters, and decisions from one focused queue.'**
  String get companyApplicationsTabSubtitle;

  /// No description provided for @companyMessagesTabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay close to conversations, follow-ups, and candidate context.'**
  String get companyMessagesTabSubtitle;

  /// No description provided for @companyProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Company profile'**
  String get companyProfileTitle;

  /// No description provided for @companyProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preview your public-facing company presence'**
  String get companyProfileSubtitle;

  /// No description provided for @editCompanyProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit company profile'**
  String get editCompanyProfileTitle;

  /// No description provided for @editCompanyProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Refresh your description, contact info, and logo'**
  String get editCompanyProfileSubtitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open your notifications center'**
  String get notificationsSubtitle;

  /// No description provided for @securityPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Security & privacy'**
  String get securityPrivacyTitle;

  /// No description provided for @securityPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Passwords, email updates, privacy, and legal info'**
  String get securityPrivacySubtitle;

  /// No description provided for @helpCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Help center'**
  String get helpCenterTitle;

  /// No description provided for @helpCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse FAQs and contact support'**
  String get helpCenterSubtitle;

  /// No description provided for @aboutFutureGateTitle.
  ///
  /// In en, this message translates to:
  /// **'About FutureGate'**
  String get aboutFutureGateTitle;

  /// No description provided for @aboutFutureGateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mission, version, and platform details'**
  String get aboutFutureGateSubtitle;

  /// No description provided for @appVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersionTitle;

  /// No description provided for @appVersionCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get appVersionCurrentLabel;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutTitle;

  /// No description provided for @signOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'End this session on the current device'**
  String get signOutSubtitle;

  /// No description provided for @notificationPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notificationPreferencesTitle;

  /// No description provided for @notificationPreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open your notifications center'**
  String get notificationPreferencesSubtitle;

  /// No description provided for @accountPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Account preferences'**
  String get accountPreferencesTitle;

  /// No description provided for @accountPreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your profile details'**
  String get accountPreferencesSubtitle;

  /// No description provided for @appearanceThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance / theme'**
  String get appearanceThemeTitle;

  /// No description provided for @appearanceThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Light visual system'**
  String get appearanceThemeSubtitle;

  /// No description provided for @appearanceThemeSheetMessage.
  ///
  /// In en, this message translates to:
  /// **'This build currently uses a light visual system across the app. A global theme switch has not been wired yet.'**
  String get appearanceThemeSheetMessage;

  /// No description provided for @languageSheetMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose English, French, or Arabic and apply it immediately across the app.'**
  String get languageSheetMessage;

  /// No description provided for @lightVisualSystemLabel.
  ///
  /// In en, this message translates to:
  /// **'Light visual system'**
  String get lightVisualSystemLabel;

  /// No description provided for @openNotificationsCenterLabel.
  ///
  /// In en, this message translates to:
  /// **'Open your notifications center'**
  String get openNotificationsCenterLabel;

  /// No description provided for @companyAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Company account'**
  String get companyAccountLabel;

  /// No description provided for @publishingSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Publishing'**
  String get publishingSectionTitle;

  /// No description provided for @basicInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get basicInformationTitle;

  /// No description provided for @descriptionSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionSectionTitle;

  /// No description provided for @requirementsAndEligibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Requirements and eligibility'**
  String get requirementsAndEligibilityTitle;

  /// No description provided for @logisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get logisticsTitle;

  /// No description provided for @additionalInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional information'**
  String get additionalInformationTitle;

  /// No description provided for @publishingStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Publishing status'**
  String get publishingStatusLabel;

  /// No description provided for @opportunityTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Opportunity type'**
  String get opportunityTypeLabel;

  /// No description provided for @opportunityTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Opportunity title'**
  String get opportunityTitleLabel;

  /// No description provided for @scholarshipTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Scholarship title'**
  String get scholarshipTitleLabel;

  /// No description provided for @providerLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get providerLabel;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @applicationDeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Application deadline'**
  String get applicationDeadlineLabel;

  /// No description provided for @deadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadlineLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @linkLabel.
  ///
  /// In en, this message translates to:
  /// **'Application link'**
  String get linkLabel;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get levelLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @tagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsLabel;

  /// No description provided for @imageUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrlLabel;

  /// No description provided for @fundingTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Funding type'**
  String get fundingTypeLabel;

  /// No description provided for @fundingAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Funding amount'**
  String get fundingAmountLabel;

  /// No description provided for @fundingCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Funding currency'**
  String get fundingCurrencyLabel;

  /// No description provided for @fundingNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Funding note'**
  String get fundingNoteLabel;

  /// No description provided for @salaryMinimumLabel.
  ///
  /// In en, this message translates to:
  /// **'Salary minimum'**
  String get salaryMinimumLabel;

  /// No description provided for @salaryMaximumLabel.
  ///
  /// In en, this message translates to:
  /// **'Salary maximum'**
  String get salaryMaximumLabel;

  /// No description provided for @salaryPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Salary period'**
  String get salaryPeriodLabel;

  /// No description provided for @employmentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Employment type'**
  String get employmentTypeLabel;

  /// No description provided for @workModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Work mode'**
  String get workModeLabel;

  /// No description provided for @paidStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid status'**
  String get paidStatusLabel;

  /// No description provided for @compensationNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Compensation note'**
  String get compensationNoteLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @originalLanguageFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Original language'**
  String get originalLanguageFieldLabel;

  /// No description provided for @originalLanguageFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Select the source language for this content'**
  String get originalLanguageFieldHint;

  /// No description provided for @openStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openStatusLabel;

  /// No description provided for @openStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visible to students'**
  String get openStatusSubtitle;

  /// No description provided for @closedStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedStatusLabel;

  /// No description provided for @closedStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Saved privately'**
  String get closedStatusSubtitle;

  /// No description provided for @savedHiddenLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved but hidden'**
  String get savedHiddenLabel;

  /// No description provided for @selectClosingDateHint.
  ///
  /// In en, this message translates to:
  /// **'Select a closing date'**
  String get selectClosingDateHint;

  /// No description provided for @optionalDirectLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Optional direct link'**
  String get optionalDirectLinkHint;

  /// No description provided for @optionalCoverImageUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Optional cover image URL'**
  String get optionalCoverImageUrlHint;

  /// No description provided for @commaSeparatedTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated tags'**
  String get commaSeparatedTagsHint;

  /// No description provided for @scholarshipProviderHint.
  ///
  /// In en, this message translates to:
  /// **'Who offers this scholarship?'**
  String get scholarshipProviderHint;

  /// No description provided for @scholarshipDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Explain the scholarship and what it supports'**
  String get scholarshipDescriptionHint;

  /// No description provided for @scholarshipTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Future Builders Global Scholarship'**
  String get scholarshipTitleHint;

  /// No description provided for @opportunityTitleHintJob.
  ///
  /// In en, this message translates to:
  /// **'e.g. Junior Flutter Developer'**
  String get opportunityTitleHintJob;

  /// No description provided for @opportunityTitleHintInternship.
  ///
  /// In en, this message translates to:
  /// **'e.g. Flutter Internship - Mobile Team'**
  String get opportunityTitleHintInternship;

  /// No description provided for @opportunityTitleHintSponsoring.
  ///
  /// In en, this message translates to:
  /// **'e.g. Student Innovation Sponsoring Program'**
  String get opportunityTitleHintSponsoring;

  /// No description provided for @opportunityLocationHintDefault.
  ///
  /// In en, this message translates to:
  /// **'e.g. Algiers, Algeria'**
  String get opportunityLocationHintDefault;

  /// No description provided for @opportunityLocationHintSponsoring.
  ///
  /// In en, this message translates to:
  /// **'e.g. Algeria-wide or Algiers'**
  String get opportunityLocationHintSponsoring;

  /// No description provided for @eligibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Eligibility'**
  String get eligibilityLabel;

  /// No description provided for @requirementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get requirementsLabel;

  /// No description provided for @programDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Program description'**
  String get programDescriptionLabel;

  /// No description provided for @roleDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Role description'**
  String get roleDescriptionLabel;

  /// No description provided for @typeOneEligibilityHint.
  ///
  /// In en, this message translates to:
  /// **'Type one eligibility rule, then press Enter'**
  String get typeOneEligibilityHint;

  /// No description provided for @typeOneRequirementHint.
  ///
  /// In en, this message translates to:
  /// **'Type one requirement, then press Enter'**
  String get typeOneRequirementHint;

  /// No description provided for @addEligibilityEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add who can apply, required documents, or academic conditions.'**
  String get addEligibilityEmptyHint;

  /// No description provided for @addRequirementEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add the skills, background, or tools students need.'**
  String get addRequirementEmptyHint;

  /// No description provided for @featureScholarshipTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature this scholarship'**
  String get featureScholarshipTitle;

  /// No description provided for @featureScholarshipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use this for high-priority or especially strong scholarship opportunities.'**
  String get featureScholarshipSubtitle;

  /// No description provided for @scholarshipEditorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Curate scholarships in the same app where students discover them, with enough structure for richer cards and more useful filtering.'**
  String get scholarshipEditorSubtitle;

  /// No description provided for @scholarshipPublishingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Featured scholarships get stronger presence in the student discovery flow.'**
  String get scholarshipPublishingSubtitle;

  /// No description provided for @scholarshipBasicInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start with the core scholarship identity so the opportunity reads clearly across cards and details.'**
  String get scholarshipBasicInfoSubtitle;

  /// No description provided for @scholarshipDescriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explain what the scholarship supports and why it stands out.'**
  String get scholarshipDescriptionSubtitle;

  /// No description provided for @scholarshipRequirementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make the eligibility criteria explicit before students click out to apply.'**
  String get scholarshipRequirementsSubtitle;

  /// No description provided for @scholarshipLogisticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the amount, deadline, and destination details in one predictable section.'**
  String get scholarshipLogisticsSubtitle;

  /// No description provided for @scholarshipAdditionalInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use these optional fields to improve discovery, filtering, and outbound application clarity.'**
  String get scholarshipAdditionalInfoSubtitle;

  /// No description provided for @publishScholarshipTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish scholarship'**
  String get publishScholarshipTitle;

  /// No description provided for @editScholarshipTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit scholarship'**
  String get editScholarshipTitle;

  /// No description provided for @saveScholarshipChangesLabel.
  ///
  /// In en, this message translates to:
  /// **'Save scholarship changes'**
  String get saveScholarshipChangesLabel;

  /// No description provided for @publishOpportunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Create opportunity'**
  String get publishOpportunityTitle;

  /// No description provided for @editOpportunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit opportunity'**
  String get editOpportunityTitle;

  /// No description provided for @saveOpportunityChangesLabel.
  ///
  /// In en, this message translates to:
  /// **'Save opportunity changes'**
  String get saveOpportunityChangesLabel;

  /// No description provided for @publishAdminOpportunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish admin opportunity'**
  String get publishAdminOpportunityTitle;

  /// No description provided for @editAdminOpportunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit admin opportunity'**
  String get editAdminOpportunityTitle;

  /// No description provided for @futureGateAdminLabel.
  ///
  /// In en, this message translates to:
  /// **'FutureGate Admin'**
  String get futureGateAdminLabel;

  /// No description provided for @publishIdeaTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish an idea'**
  String get publishIdeaTitle;

  /// No description provided for @refineIdeaTitle.
  ///
  /// In en, this message translates to:
  /// **'Refine your idea'**
  String get refineIdeaTitle;

  /// No description provided for @launchBreakthroughTitle.
  ///
  /// In en, this message translates to:
  /// **'Launch your next breakthrough'**
  String get launchBreakthroughTitle;

  /// No description provided for @editLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Editing locked'**
  String get editLockedTitle;

  /// No description provided for @editLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Only pending ideas can be edited. This idea has already moved past review, so the form is shown in locked mode.'**
  String get editLockedMessage;

  /// No description provided for @uploadInProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload in progress'**
  String get uploadInProgressTitle;

  /// No description provided for @pleaseWaitForCoverUpload.
  ///
  /// In en, this message translates to:
  /// **'Please wait for the cover image upload to finish.'**
  String get pleaseWaitForCoverUpload;

  /// No description provided for @ideaPublishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Idea published'**
  String get ideaPublishedTitle;

  /// No description provided for @ideaPublishedMessage.
  ///
  /// In en, this message translates to:
  /// **'Idea published successfully.'**
  String get ideaPublishedMessage;

  /// No description provided for @ideaSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Idea submitted'**
  String get ideaSubmittedTitle;

  /// No description provided for @ideaSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Idea submitted successfully.'**
  String get ideaSubmittedMessage;

  /// No description provided for @ideaUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Idea updated'**
  String get ideaUpdatedTitle;

  /// No description provided for @ideaUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Idea updated successfully.'**
  String get ideaUpdatedMessage;

  /// No description provided for @submissionUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Submission unavailable'**
  String get submissionUnavailableTitle;

  /// No description provided for @readyForPublicDiscoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready for public discovery'**
  String get readyForPublicDiscoveryTitle;

  /// No description provided for @readyForPublicDiscoverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Approved ideas appear in Discover. Pending ideas still stay visible in My Ideas.'**
  String get readyForPublicDiscoverySubtitle;

  /// No description provided for @coverImageReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Cover image ready'**
  String get coverImageReadyTitle;

  /// No description provided for @uploadCoverImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a cover image'**
  String get uploadCoverImageTitle;

  /// No description provided for @coverImageReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your idea now has a visual header that will show across Discover, My Ideas, and the details view.'**
  String get coverImageReadySubtitle;

  /// No description provided for @uploadCoverImageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a JPG, PNG, or WebP image to make the idea feel polished from the first glance.'**
  String get uploadCoverImageSubtitle;

  /// No description provided for @coverImageUploadedLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover image uploaded'**
  String get coverImageUploadedLabel;

  /// No description provided for @strongVisualHint.
  ///
  /// In en, this message translates to:
  /// **'A strong visual makes the featured cards and detail hero feel much more alive.'**
  String get strongVisualHint;

  /// No description provided for @bestResultsImageHint.
  ///
  /// In en, this message translates to:
  /// **'Best results: 16:9 cover, under 5 MB.'**
  String get bestResultsImageHint;

  /// No description provided for @deckDemoLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Deck / demo link'**
  String get deckDemoLinkLabel;

  /// No description provided for @deckDemoLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Figma, Notion, pitch deck, landing page...'**
  String get deckDemoLinkHint;

  /// No description provided for @chooseOneOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose one option'**
  String get chooseOneOptionLabel;

  /// No description provided for @selectCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategoryTitle;

  /// No description provided for @selectStageTitle.
  ///
  /// In en, this message translates to:
  /// **'Select stage'**
  String get selectStageTitle;

  /// No description provided for @loginRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get loginRequiredTitle;

  /// No description provided for @signInContinuePublishingMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue publishing opportunities.'**
  String get signInContinuePublishingMessage;

  /// No description provided for @loginRequiredUploadMessage.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to upload images.'**
  String get loginRequiredUploadMessage;

  /// No description provided for @updateUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update unavailable'**
  String get updateUnavailableTitle;

  /// No description provided for @publishUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish unavailable'**
  String get publishUnavailableTitle;

  /// No description provided for @uploadUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload unavailable'**
  String get uploadUnavailableTitle;

  /// No description provided for @opportunityUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your opportunity details have been updated.'**
  String get opportunityUpdatedMessage;

  /// No description provided for @opportunityPublishedMessage.
  ///
  /// In en, this message translates to:
  /// **'Opportunity published successfully.'**
  String get opportunityPublishedMessage;

  /// No description provided for @scholarshipUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Scholarship updated successfully.'**
  String get scholarshipUpdatedMessage;

  /// No description provided for @scholarshipPublishedMessage.
  ///
  /// In en, this message translates to:
  /// **'Scholarship published successfully.'**
  String get scholarshipPublishedMessage;

  /// No description provided for @ideaUploadSizeMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose an image smaller than 5 MB.'**
  String get ideaUploadSizeMessage;

  /// No description provided for @validationTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get validationTitleRequired;

  /// No description provided for @validationDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get validationDescriptionRequired;

  /// No description provided for @validationLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Location is required'**
  String get validationLocationRequired;

  /// No description provided for @validationEligibilityItemRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one eligibility item'**
  String get validationEligibilityItemRequired;

  /// No description provided for @validationRequirementItemRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one requirement'**
  String get validationRequirementItemRequired;

  /// No description provided for @validationUseAtLeastFourCharacters.
  ///
  /// In en, this message translates to:
  /// **'Use at least 4 characters'**
  String get validationUseAtLeastFourCharacters;

  /// No description provided for @validationAddMoreDetail.
  ///
  /// In en, this message translates to:
  /// **'Please add a little more detail'**
  String get validationAddMoreDetail;

  /// No description provided for @validationValidDate.
  ///
  /// In en, this message translates to:
  /// **'Use a valid date'**
  String get validationValidDate;

  /// No description provided for @validationDeadlineRequired.
  ///
  /// In en, this message translates to:
  /// **'Application deadline is required'**
  String get validationDeadlineRequired;

  /// No description provided for @validationDeadlinePast.
  ///
  /// In en, this message translates to:
  /// **'Deadline cannot be in the past'**
  String get validationDeadlinePast;

  /// No description provided for @validationValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get validationValidAmount;

  /// No description provided for @validationAmountNonNegative.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot be negative'**
  String get validationAmountNonNegative;

  /// No description provided for @validationFundingAmountOrNote.
  ///
  /// In en, this message translates to:
  /// **'Add a funding amount or note'**
  String get validationFundingAmountOrNote;

  /// No description provided for @validationFundingNoteOrAmount.
  ///
  /// In en, this message translates to:
  /// **'Add a funding note or amount'**
  String get validationFundingNoteOrAmount;

  /// No description provided for @validationAddClearerDuration.
  ///
  /// In en, this message translates to:
  /// **'Add a clearer duration'**
  String get validationAddClearerDuration;

  /// No description provided for @validationEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get validationEnterValidNumber;

  /// No description provided for @validationMinCannotExceedMax.
  ///
  /// In en, this message translates to:
  /// **'Min cannot exceed max'**
  String get validationMinCannotExceedMax;

  /// No description provided for @validationMaxAtLeastMin.
  ///
  /// In en, this message translates to:
  /// **'Max must be at least min'**
  String get validationMaxAtLeastMin;

  /// No description provided for @validationOriginalLanguageRequired.
  ///
  /// In en, this message translates to:
  /// **'Original language is required'**
  String get validationOriginalLanguageRequired;

  /// No description provided for @validationProjectIdeaTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get validationProjectIdeaTitleRequired;

  /// No description provided for @validationFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get validationFieldRequired;

  /// No description provided for @continueWithGoogleLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogleLabel;

  /// No description provided for @orDividerLabel.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDividerLabel;

  /// No description provided for @stepProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String stepProgressLabel(Object step, Object total);

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(Object version);

  /// No description provided for @publishContentType.
  ///
  /// In en, this message translates to:
  /// **'Publish {contentType}'**
  String publishContentType(Object contentType);

  /// No description provided for @companyFundingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Company funding: {label}'**
  String companyFundingPrefix(Object label);

  /// No description provided for @academicLevelBachelor.
  ///
  /// In en, this message translates to:
  /// **'Bachelor'**
  String get academicLevelBachelor;

  /// No description provided for @academicLevelBachelorDescription.
  ///
  /// In en, this message translates to:
  /// **'Foundational university track'**
  String get academicLevelBachelorDescription;

  /// No description provided for @academicLevelLicence.
  ///
  /// In en, this message translates to:
  /// **'Licence'**
  String get academicLevelLicence;

  /// No description provided for @academicLevelLicenceDescription.
  ///
  /// In en, this message translates to:
  /// **'Licence degree program'**
  String get academicLevelLicenceDescription;

  /// No description provided for @academicLevelMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get academicLevelMaster;

  /// No description provided for @academicLevelMasterDescription.
  ///
  /// In en, this message translates to:
  /// **'Advanced academic specialization'**
  String get academicLevelMasterDescription;

  /// No description provided for @academicLevelDoctorat.
  ///
  /// In en, this message translates to:
  /// **'Doctorat'**
  String get academicLevelDoctorat;

  /// No description provided for @academicLevelDoctoratDescription.
  ///
  /// In en, this message translates to:
  /// **'Doctoral research and thesis work'**
  String get academicLevelDoctoratDescription;

  /// No description provided for @jobLabel.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get jobLabel;

  /// No description provided for @internshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Internship'**
  String get internshipLabel;

  /// No description provided for @sponsoredLabel.
  ///
  /// In en, this message translates to:
  /// **'Sponsored'**
  String get sponsoredLabel;

  /// No description provided for @jobLowercaseLabel.
  ///
  /// In en, this message translates to:
  /// **'job'**
  String get jobLowercaseLabel;

  /// No description provided for @internshipLowercaseLabel.
  ///
  /// In en, this message translates to:
  /// **'internship'**
  String get internshipLowercaseLabel;

  /// No description provided for @sponsoredLowercaseLabel.
  ///
  /// In en, this message translates to:
  /// **'sponsored'**
  String get sponsoredLowercaseLabel;

  /// No description provided for @opportunityHeadlineJob.
  ///
  /// In en, this message translates to:
  /// **'Hire for a real role'**
  String get opportunityHeadlineJob;

  /// No description provided for @opportunityHeadlineInternship.
  ///
  /// In en, this message translates to:
  /// **'Bring in future talent'**
  String get opportunityHeadlineInternship;

  /// No description provided for @opportunityHeadlineSponsoring.
  ///
  /// In en, this message translates to:
  /// **'Support students with a premium sponsored program'**
  String get opportunityHeadlineSponsoring;

  /// No description provided for @opportunitySubtitleJob.
  ///
  /// In en, this message translates to:
  /// **'Full-time & part-time work'**
  String get opportunitySubtitleJob;

  /// No description provided for @opportunitySubtitleInternship.
  ///
  /// In en, this message translates to:
  /// **'Learning & work experience'**
  String get opportunitySubtitleInternship;

  /// No description provided for @opportunitySubtitleSponsoring.
  ///
  /// In en, this message translates to:
  /// **'Premium funded & partner programs'**
  String get opportunitySubtitleSponsoring;

  /// No description provided for @opportunityDescriptionHintJob.
  ///
  /// In en, this message translates to:
  /// **'Describe the role, team, and responsibilities...'**
  String get opportunityDescriptionHintJob;

  /// No description provided for @opportunityDescriptionHintInternship.
  ///
  /// In en, this message translates to:
  /// **'Describe the internship scope, learning goals, and responsibilities...'**
  String get opportunityDescriptionHintInternship;

  /// No description provided for @opportunityDescriptionHintSponsoring.
  ///
  /// In en, this message translates to:
  /// **'Describe the sponsoring program, support offered, and who it is for...'**
  String get opportunityDescriptionHintSponsoring;

  /// No description provided for @opportunityRequirementsHintJob.
  ///
  /// In en, this message translates to:
  /// **'Share the skills and qualifications needed...'**
  String get opportunityRequirementsHintJob;

  /// No description provided for @opportunityRequirementsHintInternship.
  ///
  /// In en, this message translates to:
  /// **'Share preferred skills, academic background, or tools...'**
  String get opportunityRequirementsHintInternship;

  /// No description provided for @opportunityRequirementsHintSponsoring.
  ///
  /// In en, this message translates to:
  /// **'Share eligibility criteria, documents, or expectations...'**
  String get opportunityRequirementsHintSponsoring;

  /// No description provided for @employmentTypeFullTime.
  ///
  /// In en, this message translates to:
  /// **'Full-time'**
  String get employmentTypeFullTime;

  /// No description provided for @employmentTypePartTime.
  ///
  /// In en, this message translates to:
  /// **'Part-time'**
  String get employmentTypePartTime;

  /// No description provided for @employmentTypeInternship.
  ///
  /// In en, this message translates to:
  /// **'Internship'**
  String get employmentTypeInternship;

  /// No description provided for @employmentTypeContract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get employmentTypeContract;

  /// No description provided for @employmentTypeTemporary.
  ///
  /// In en, this message translates to:
  /// **'Temporary'**
  String get employmentTypeTemporary;

  /// No description provided for @employmentTypeFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get employmentTypeFreelance;

  /// No description provided for @workModeOnsite.
  ///
  /// In en, this message translates to:
  /// **'On-site'**
  String get workModeOnsite;

  /// No description provided for @workModeRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get workModeRemote;

  /// No description provided for @workModeHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get workModeHybrid;

  /// No description provided for @paidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidLabel;

  /// No description provided for @unpaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaidLabel;

  /// No description provided for @benefitFundingIncluded.
  ///
  /// In en, this message translates to:
  /// **'Funding included'**
  String get benefitFundingIncluded;

  /// No description provided for @benefitPaidOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Paid opportunity'**
  String get benefitPaidOpportunity;

  /// No description provided for @benefitRemoteFriendly.
  ///
  /// In en, this message translates to:
  /// **'Remote-friendly setup'**
  String get benefitRemoteFriendly;

  /// No description provided for @benefitHybridFormat.
  ///
  /// In en, this message translates to:
  /// **'Hybrid work format'**
  String get benefitHybridFormat;

  /// No description provided for @benefitFeaturedSponsored.
  ///
  /// In en, this message translates to:
  /// **'Featured sponsored placement'**
  String get benefitFeaturedSponsored;

  /// No description provided for @ui12Matches.
  ///
  /// In en, this message translates to:
  /// **'12 matches'**
  String get ui12Matches;

  /// No description provided for @ui70Completed.
  ///
  /// In en, this message translates to:
  /// **'70% Completed'**
  String get ui70Completed;

  /// No description provided for @uiABriefSummaryOfYourProfile.
  ///
  /// In en, this message translates to:
  /// **'A brief summary of your profile'**
  String get uiABriefSummaryOfYourProfile;

  /// No description provided for @uiACleanerBreakdownOfTheProviderDestinationAndTrack.
  ///
  /// In en, this message translates to:
  /// **'A cleaner breakdown of the provider, destination, and track.'**
  String get uiACleanerBreakdownOfTheProviderDestinationAndTrack;

  /// No description provided for @uiAClearerPathFromStudentAmbitionToRealWorldOpportunity.
  ///
  /// In en, this message translates to:
  /// **'A clearer path from student ambition to real-world opportunity.'**
  String get uiAClearerPathFromStudentAmbitionToRealWorldOpportunity;

  /// No description provided for @uiACurrentCommercialRegisterReinforcesTrustAndHelpsKeepThe.
  ///
  /// In en, this message translates to:
  /// **'A current commercial register reinforces trust and helps keep the company profile ready for review.'**
  String get uiACurrentCommercialRegisterReinforcesTrustAndHelpsKeepThe;

  /// No description provided for @uiAFocusedOverviewSoTheOpportunityFeelsEasyToScan.
  ///
  /// In en, this message translates to:
  /// **'A focused overview so the opportunity feels easy to scan.'**
  String get uiAFocusedOverviewSoTheOpportunityFeelsEasyToScan;

  /// No description provided for @uiAPublicWebsiteAndSocialChannelsAreNotLinkedInside.
  ///
  /// In en, this message translates to:
  /// **'A public website and social channels are not linked inside this build yet. Support requests can still be sent directly by email.'**
  String get uiAPublicWebsiteAndSocialChannelsAreNotLinkedInside;

  /// No description provided for @uiAQuickCountOfTheContentTypesHandledInsideThe.
  ///
  /// In en, this message translates to:
  /// **'A quick count of the content types handled inside the admin workspace.'**
  String get uiAQuickCountOfTheContentTypesHandledInsideThe;

  /// No description provided for @uiAQuickHighlightPickedFromTheScholarships.
  ///
  /// In en, this message translates to:
  /// **'A quick highlight picked from the scholarships '**
  String get uiAQuickHighlightPickedFromTheScholarships;

  /// No description provided for @uiAQuickPulseOnImportedResourcesSoAdminsCanCurate.
  ///
  /// In en, this message translates to:
  /// **'A quick pulse on imported resources so admins can curate instead of guessing.'**
  String get uiAQuickPulseOnImportedResourcesSoAdminsCanCurate;

  /// No description provided for @uiAReadyCvMakesJobsInternshipsAndScholarshipsMuchQuicker.
  ///
  /// In en, this message translates to:
  /// **'A ready CV makes jobs, internships, and scholarships much quicker to apply for.'**
  String get uiAReadyCvMakesJobsInternshipsAndScholarshipsMuchQuicker;

  /// No description provided for @uiASharperCompanyStoryMakesTheProfileFeelMoreConfident.
  ///
  /// In en, this message translates to:
  /// **'A sharper company story makes the profile feel more confident and trustworthy.'**
  String get uiASharperCompanyStoryMakesTheProfileFeelMoreConfident;

  /// No description provided for @uiAStrongLogoOrCompanyPhotoMakesTheProfileFeel.
  ///
  /// In en, this message translates to:
  /// **'A strong logo or company photo makes the profile feel more polished and recognizable.'**
  String get uiAStrongLogoOrCompanyPhotoMakesTheProfileFeel;

  /// No description provided for @uiAVerificationLinkWillBeSentToTheNewAddress.
  ///
  /// In en, this message translates to:
  /// **'A verification link will be sent to the new address before the change becomes active.'**
  String get uiAVerificationLinkWillBeSentToTheNewAddress;

  /// No description provided for @uiAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get uiAbout;

  /// No description provided for @uiAboutThisScholarship.
  ///
  /// In en, this message translates to:
  /// **'About This Scholarship'**
  String get uiAboutThisScholarship;

  /// No description provided for @uiAboutYou.
  ///
  /// In en, this message translates to:
  /// **'About You'**
  String get uiAboutYou;

  /// No description provided for @uiAcademicBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Academic Breakdown'**
  String get uiAcademicBreakdown;

  /// No description provided for @uiAcademicLevel.
  ///
  /// In en, this message translates to:
  /// **'Academic level'**
  String get uiAcademicLevel;

  /// No description provided for @uiAcademicLevel80Cc.
  ///
  /// In en, this message translates to:
  /// **'Academic Level'**
  String get uiAcademicLevel80Cc;

  /// No description provided for @uiAcademicProfile.
  ///
  /// In en, this message translates to:
  /// **'Academic Profile'**
  String get uiAcademicProfile;

  /// No description provided for @uiAcceptedFormatsJpgPngOrWebpMaximumSize5Mb.
  ///
  /// In en, this message translates to:
  /// **'Accepted formats: JPG, PNG, or WebP. Maximum size: 5 MB.'**
  String get uiAcceptedFormatsJpgPngOrWebpMaximumSize5Mb;

  /// No description provided for @uiAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get uiAccess;

  /// No description provided for @uiAccountAccess.
  ///
  /// In en, this message translates to:
  /// **'Account access'**
  String get uiAccountAccess;

  /// No description provided for @uiAccountCreationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Account creation unavailable'**
  String get uiAccountCreationUnavailable;

  /// No description provided for @uiAccountHelp.
  ///
  /// In en, this message translates to:
  /// **'Account Help'**
  String get uiAccountHelp;

  /// No description provided for @uiAccountPreferences.
  ///
  /// In en, this message translates to:
  /// **'Account Preferences'**
  String get uiAccountPreferences;

  /// No description provided for @uiAccountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get uiAccountSecurity;

  /// No description provided for @uiActBeforeDeadlinesClose.
  ///
  /// In en, this message translates to:
  /// **'Act before deadlines close.'**
  String get uiActBeforeDeadlinesClose;

  /// No description provided for @uiActionUser.
  ///
  /// In en, this message translates to:
  /// **'{action} User'**
  String uiActionUser(Object action);

  /// No description provided for @uiActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get uiActions;

  /// No description provided for @uiActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get uiActive;

  /// No description provided for @uiActiveJobPosts.
  ///
  /// In en, this message translates to:
  /// **'Active Job Posts'**
  String get uiActiveJobPosts;

  /// No description provided for @uiActiveJobs.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE JOBS'**
  String get uiActiveJobs;

  /// No description provided for @uiActiveUsers.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get uiActiveUsers;

  /// No description provided for @uiActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get uiActivity;

  /// No description provided for @uiActivityFeedUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Activity feed unavailable'**
  String get uiActivityFeedUnavailable;

  /// No description provided for @uiAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get uiAdd;

  /// No description provided for @uiAddAFewLinesAboutWhatYourCompanyBuildsAnd.
  ///
  /// In en, this message translates to:
  /// **'Add a few lines about what your company builds and what students can expect from your team.'**
  String get uiAddAFewLinesAboutWhatYourCompanyBuildsAnd;

  /// No description provided for @uiAddALanguage.
  ///
  /// In en, this message translates to:
  /// **'Add a language'**
  String get uiAddALanguage;

  /// No description provided for @uiAddAPlatformCuratedIdeaWithAStrongStoryClear.
  ///
  /// In en, this message translates to:
  /// **'Add a platform-curated idea with a strong story, clear metadata, and the same polished structure users already recognize in the innovation feed.'**
  String get uiAddAPlatformCuratedIdeaWithAStrongStoryClear;

  /// No description provided for @uiAddASkill.
  ///
  /// In en, this message translates to:
  /// **'Add a skill'**
  String get uiAddASkill;

  /// No description provided for @uiAddEachPointSeparatelySoStudentsSeeACleanChecklist.
  ///
  /// In en, this message translates to:
  /// **'Add each point separately so students see a clean checklist.'**
  String get uiAddEachPointSeparatelySoStudentsSeeACleanChecklist;

  /// No description provided for @uiAddEmailAndPasswordSignIn.
  ///
  /// In en, this message translates to:
  /// **'Add email and password sign-in'**
  String get uiAddEmailAndPasswordSignIn;

  /// No description provided for @uiAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get uiAddItem;

  /// No description provided for @uiAddOneClearItemAtATimeSoStudentsSee.
  ///
  /// In en, this message translates to:
  /// **'Add one clear item at a time so students see a clean checklist.'**
  String get uiAddOneClearItemAtATimeSoStudentsSee;

  /// No description provided for @uiAddPassword.
  ///
  /// In en, this message translates to:
  /// **'Add Password'**
  String get uiAddPassword;

  /// No description provided for @uiAddTheSupportingMaterialsVisibilitySettingsAndAttachmentsThatMake.
  ///
  /// In en, this message translates to:
  /// **'Add the supporting materials, visibility settings, and attachments that make the post feel complete.'**
  String
  get uiAddTheSupportingMaterialsVisibilitySettingsAndAttachmentsThatMake;

  /// No description provided for @uiAddYourStudentDetails.
  ///
  /// In en, this message translates to:
  /// **'Add your student details.'**
  String get uiAddYourStudentDetails;

  /// No description provided for @uiAdditionalInformation.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get uiAdditionalInformation;

  /// No description provided for @uiAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get uiAddress;

  /// No description provided for @uiAdminContentCenter.
  ///
  /// In en, this message translates to:
  /// **'Admin Content Center'**
  String get uiAdminContentCenter;

  /// No description provided for @uiAdminControlRoom.
  ///
  /// In en, this message translates to:
  /// **'Admin Control Room'**
  String get uiAdminControlRoom;

  /// No description provided for @uiAdminPosts.
  ///
  /// In en, this message translates to:
  /// **'Admin Posts'**
  String get uiAdminPosts;

  /// No description provided for @uiAiActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'AI action unavailable'**
  String get uiAiActionUnavailable;

  /// No description provided for @uiAiIsProcessing.
  ///
  /// In en, this message translates to:
  /// **'AI is processing...'**
  String get uiAiIsProcessing;

  /// No description provided for @uiAiTrainer.
  ///
  /// In en, this message translates to:
  /// **'AI Trainer'**
  String get uiAiTrainer;

  /// No description provided for @uiAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get uiAlerts;

  /// No description provided for @uiAlexFromTechcorp.
  ///
  /// In en, this message translates to:
  /// **'Alex from TechCorp'**
  String get uiAlexFromTechcorp;

  /// No description provided for @uiAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get uiAll;

  /// No description provided for @uiAllIdeas.
  ///
  /// In en, this message translates to:
  /// **'All Ideas'**
  String get uiAllIdeas;

  /// No description provided for @uiAllOppsValue1.
  ///
  /// In en, this message translates to:
  /// **'All Opportunities ({value1})'**
  String uiAllOppsValue1(Object value1);

  /// No description provided for @uiAllRoles.
  ///
  /// In en, this message translates to:
  /// **'All Roles'**
  String get uiAllRoles;

  /// No description provided for @uiAllSponsoredPrograms.
  ///
  /// In en, this message translates to:
  /// **'All Sponsored Programs'**
  String get uiAllSponsoredPrograms;

  /// No description provided for @uiAnswersGuidanceAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Answers, guidance, and support.'**
  String get uiAnswersGuidanceAndSupport;

  /// No description provided for @uiAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get uiAny;

  /// No description provided for @uiAppearanceTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance / Theme'**
  String get uiAppearanceTheme;

  /// No description provided for @uiApplicantcount.
  ///
  /// In en, this message translates to:
  /// **'{applicantCount}'**
  String uiApplicantcount(Object applicantCount);

  /// No description provided for @uiApplicantcountApplicants.
  ///
  /// In en, this message translates to:
  /// **'{applicantCount} applicants'**
  String uiApplicantcountApplicants(Object applicantCount);

  /// No description provided for @uiApplicants.
  ///
  /// In en, this message translates to:
  /// **'Applicants'**
  String get uiApplicants;

  /// No description provided for @uiApplicationActivity.
  ///
  /// In en, this message translates to:
  /// **'Application Activity'**
  String get uiApplicationActivity;

  /// No description provided for @uiApplicationApproved.
  ///
  /// In en, this message translates to:
  /// **'Application\nApproved'**
  String get uiApplicationApproved;

  /// No description provided for @uiApplicationApprovedB0Cb.
  ///
  /// In en, this message translates to:
  /// **'Application approved'**
  String get uiApplicationApprovedB0Cb;

  /// No description provided for @uiApplicationBlocked.
  ///
  /// In en, this message translates to:
  /// **'Application blocked'**
  String get uiApplicationBlocked;

  /// No description provided for @uiApplicationDataIsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Application data is unavailable.'**
  String get uiApplicationDataIsUnavailable;

  /// No description provided for @uiApplicationDataIsUnavailableRightNow.
  ///
  /// In en, this message translates to:
  /// **'Application data is unavailable right now.'**
  String get uiApplicationDataIsUnavailableRightNow;

  /// No description provided for @uiApplicationDetails.
  ///
  /// In en, this message translates to:
  /// **'Application details'**
  String get uiApplicationDetails;

  /// No description provided for @uiApplicationHelp.
  ///
  /// In en, this message translates to:
  /// **'Application Help'**
  String get uiApplicationHelp;

  /// No description provided for @uiApplicationLink.
  ///
  /// In en, this message translates to:
  /// **'Application Link'**
  String get uiApplicationLink;

  /// No description provided for @uiApplicationPipeline.
  ///
  /// In en, this message translates to:
  /// **'Application pipeline'**
  String get uiApplicationPipeline;

  /// No description provided for @uiApplicationProcess.
  ///
  /// In en, this message translates to:
  /// **'Application Process'**
  String get uiApplicationProcess;

  /// No description provided for @uiApplicationRate.
  ///
  /// In en, this message translates to:
  /// **'Application Rate'**
  String get uiApplicationRate;

  /// No description provided for @uiApplicationStatus.
  ///
  /// In en, this message translates to:
  /// **'Application Status'**
  String get uiApplicationStatus;

  /// No description provided for @uiApplicationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Application unavailable'**
  String get uiApplicationUnavailable;

  /// No description provided for @uiApplicationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Application updated'**
  String get uiApplicationUpdated;

  /// No description provided for @uiApplications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get uiApplications;

  /// No description provided for @uiApplicationsForOpportunitytitle.
  ///
  /// In en, this message translates to:
  /// **'Applications for {opportunityTitle}'**
  String uiApplicationsForOpportunitytitle(Object opportunityTitle);

  /// No description provided for @uiApplicationsReceived.
  ///
  /// In en, this message translates to:
  /// **'Applications Received'**
  String get uiApplicationsReceived;

  /// No description provided for @uiApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get uiApplied;

  /// No description provided for @uiAppliedAppliedtext.
  ///
  /// In en, this message translates to:
  /// **'Applied {appliedText}'**
  String uiAppliedAppliedtext(Object appliedText);

  /// No description provided for @uiAppliedOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Applied Opportunities'**
  String get uiAppliedOpportunities;

  /// No description provided for @uiAppliedRelativeappliedlabel.
  ///
  /// In en, this message translates to:
  /// **'Applied {relativeAppliedLabel}'**
  String uiAppliedRelativeappliedlabel(Object relativeAppliedLabel);

  /// No description provided for @uiApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get uiApply;

  /// No description provided for @uiApplyLink.
  ///
  /// In en, this message translates to:
  /// **'Apply Link'**
  String get uiApplyLink;

  /// No description provided for @uiApplyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get uiApplyNow;

  /// No description provided for @uiApplyTemplate.
  ///
  /// In en, this message translates to:
  /// **'Apply template'**
  String get uiApplyTemplate;

  /// No description provided for @uiApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get uiApprove;

  /// No description provided for @uiApproveCompany.
  ///
  /// In en, this message translates to:
  /// **'Approve Company'**
  String get uiApproveCompany;

  /// No description provided for @uiApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get uiApproved;

  /// No description provided for @uiApprovedValue1Approved.
  ///
  /// In en, this message translates to:
  /// **'{approved} {value1} approved.'**
  String uiApprovedValue1Approved(Object value1, Object approved);

  /// No description provided for @uiArchiveConversation.
  ///
  /// In en, this message translates to:
  /// **'Archive conversation?'**
  String get uiArchiveConversation;

  /// No description provided for @uiArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get uiArchived;

  /// No description provided for @uiAreYouSureYouWantToArchiveThisConversation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to archive this conversation?'**
  String get uiAreYouSureYouWantToArchiveThisConversation;

  /// No description provided for @uiAreYouSureYouWantToDeleteThisConversationThis.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this conversation? This action cannot be undone.'**
  String get uiAreYouSureYouWantToDeleteThisConversationThis;

  /// No description provided for @uiAtAGlance.
  ///
  /// In en, this message translates to:
  /// **'AT A GLANCE'**
  String get uiAtAGlance;

  /// No description provided for @uiAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get uiAttach;

  /// No description provided for @uiAttachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get uiAttachment;

  /// No description provided for @uiAttachmentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Attachment unavailable'**
  String get uiAttachmentUnavailable;

  /// No description provided for @uiAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get uiAttachments;

  /// No description provided for @uiAudienceAndImpact.
  ///
  /// In en, this message translates to:
  /// **'Audience And Impact'**
  String get uiAudienceAndImpact;

  /// No description provided for @uiAudienceAndMetadata.
  ///
  /// In en, this message translates to:
  /// **'Audience And Metadata'**
  String get uiAudienceAndMetadata;

  /// No description provided for @uiAudienceMetadata.
  ///
  /// In en, this message translates to:
  /// **'Audience & Metadata'**
  String get uiAudienceMetadata;

  /// No description provided for @uiAvailableInternships.
  ///
  /// In en, this message translates to:
  /// **'Available Internships'**
  String get uiAvailableInternships;

  /// No description provided for @uiAvailableJobs.
  ///
  /// In en, this message translates to:
  /// **'Available Jobs'**
  String get uiAvailableJobs;

  /// No description provided for @uiAvailableNow.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE NOW'**
  String get uiAvailableNow;

  /// No description provided for @uiAvailableScholarships.
  ///
  /// In en, this message translates to:
  /// **'Available\nScholarships'**
  String get uiAvailableScholarships;

  /// No description provided for @uiAvatarUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Avatar unavailable'**
  String get uiAvatarUnavailable;

  /// No description provided for @uiAvenirCloudSupport.
  ///
  /// In en, this message translates to:
  /// **'Avenir Cloud â¢ Support'**
  String get uiAvenirCloudSupport;

  /// No description provided for @uiBac.
  ///
  /// In en, this message translates to:
  /// **'Bac'**
  String get uiBac;

  /// No description provided for @uiBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get uiBack;

  /// No description provided for @uiBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get uiBackToLogin;

  /// No description provided for @uiBackToLoginB5Cd.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get uiBackToLoginB5Cd;

  /// No description provided for @uiBackendSupport.
  ///
  /// In en, this message translates to:
  /// **'Backend Support'**
  String get uiBackendSupport;

  /// No description provided for @uiBadgecount.
  ///
  /// In en, this message translates to:
  /// **'{badgeCount}'**
  String uiBadgecount(Object badgeCount);

  /// No description provided for @uiBasicDetails.
  ///
  /// In en, this message translates to:
  /// **'Basic Details'**
  String get uiBasicDetails;

  /// No description provided for @uiBasicIdentity.
  ///
  /// In en, this message translates to:
  /// **'Basic Identity'**
  String get uiBasicIdentity;

  /// No description provided for @uiBasicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get uiBasicInformation;

  /// No description provided for @uiBenefits.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get uiBenefits;

  /// No description provided for @uiBenefitsAndImpact.
  ///
  /// In en, this message translates to:
  /// **'Benefits and impact'**
  String get uiBenefitsAndImpact;

  /// No description provided for @uiBenefitsImpact.
  ///
  /// In en, this message translates to:
  /// **'Benefits / Impact'**
  String get uiBenefitsImpact;

  /// No description provided for @uiBenefitsOrImpact.
  ///
  /// In en, this message translates to:
  /// **'Benefits or impact'**
  String get uiBenefitsOrImpact;

  /// No description provided for @uiBestSuitedFor.
  ///
  /// In en, this message translates to:
  /// **'Best suited for'**
  String get uiBestSuitedFor;

  /// No description provided for @uiBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get uiBio;

  /// No description provided for @uiBookImportWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Book Import Workspace'**
  String get uiBookImportWorkspace;

  /// No description provided for @uiBookLibraryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Book library unavailable'**
  String get uiBookLibraryUnavailable;

  /// No description provided for @uiBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get uiBooks;

  /// No description provided for @uiBrandStory.
  ///
  /// In en, this message translates to:
  /// **'Brand Story'**
  String get uiBrandStory;

  /// No description provided for @uiBrightStudioGrowth.
  ///
  /// In en, this message translates to:
  /// **'Bright Studio â¢ Growth'**
  String get uiBrightStudioGrowth;

  /// No description provided for @uiBrowseCategories.
  ///
  /// In en, this message translates to:
  /// **'Browse categories'**
  String get uiBrowseCategories;

  /// No description provided for @uiBrowseJobsInternshipsSponsoredTracksAndTrainingPicksDesignedFor.
  ///
  /// In en, this message translates to:
  /// **'Browse jobs, internships, sponsored tracks, and training picks designed for students.'**
  String get uiBrowseJobsInternshipsSponsoredTracksAndTrainingPicksDesignedFor;

  /// No description provided for @uiBrowseLearningHub.
  ///
  /// In en, this message translates to:
  /// **'Browse learning hub'**
  String get uiBrowseLearningHub;

  /// No description provided for @uiBuildSaveAndGrowYourNextProjectIdeaWithConfidence.
  ///
  /// In en, this message translates to:
  /// **'Build, save, and grow your next project idea with confidence.'**
  String get uiBuildSaveAndGrowYourNextProjectIdeaWithConfidence;

  /// No description provided for @uiBuildSkillsAndGrowYourCareerWithCuratedLearningPaths.
  ///
  /// In en, this message translates to:
  /// **'Build skills and grow your career with curated learning paths.'**
  String get uiBuildSkillsAndGrowYourCareerWithCuratedLearningPaths;

  /// No description provided for @uiBuildStory.
  ///
  /// In en, this message translates to:
  /// **'Build Story'**
  String get uiBuildStory;

  /// No description provided for @uiBuildUploadAndExportYourCv.
  ///
  /// In en, this message translates to:
  /// **'Build, upload, and export your CV.'**
  String get uiBuildUploadAndExportYourCv;

  /// No description provided for @uiBuildYourCvFirst.
  ///
  /// In en, this message translates to:
  /// **'Build your CV first.'**
  String get uiBuildYourCvFirst;

  /// No description provided for @uiBuildYourNextSkill.
  ///
  /// In en, this message translates to:
  /// **'Build your next skill'**
  String get uiBuildYourNextSkill;

  /// No description provided for @uiBuiltCv.
  ///
  /// In en, this message translates to:
  /// **'Built CV'**
  String get uiBuiltCv;

  /// No description provided for @uiBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get uiBusiness;

  /// No description provided for @uiBusinessEmail.
  ///
  /// In en, this message translates to:
  /// **'Business Email'**
  String get uiBusinessEmail;

  /// No description provided for @uiByValue1.
  ///
  /// In en, this message translates to:
  /// **'By {value1}'**
  String uiByValue1(Object value1);

  /// No description provided for @uiCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Catalogue'**
  String get uiCatalogue;

  /// No description provided for @uiCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get uiCategories;

  /// No description provided for @uiCertificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get uiCertificate;

  /// No description provided for @uiChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get uiChangeEmail;

  /// No description provided for @uiChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get uiChangePassword;

  /// No description provided for @uiChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get uiChat;

  /// No description provided for @uiChatUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Chat unavailable'**
  String get uiChatUnavailable;

  /// No description provided for @uiCheckBackSoonForFreshCuratedOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Check back soon for fresh curated opportunities.'**
  String get uiCheckBackSoonForFreshCuratedOpportunities;

  /// No description provided for @uiCheckTheCoreEligibilitySignalsBeforeMovingForward.
  ///
  /// In en, this message translates to:
  /// **'Check the core eligibility signals before moving forward.'**
  String get uiCheckTheCoreEligibilitySignalsBeforeMovingForward;

  /// No description provided for @uiCheckYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get uiCheckYourEmail;

  /// No description provided for @uiChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get uiChoose;

  /// No description provided for @uiChooseATemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose a Template?'**
  String get uiChooseATemplate;

  /// No description provided for @uiChooseAnAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose an Avatar'**
  String get uiChooseAnAvatar;

  /// No description provided for @uiChooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose Avatar'**
  String get uiChooseAvatar;

  /// No description provided for @uiChooseLevel.
  ///
  /// In en, this message translates to:
  /// **'Choose level'**
  String get uiChooseLevel;

  /// No description provided for @uiChooseTemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose Template'**
  String get uiChooseTemplate;

  /// No description provided for @uiChooseTheNextModerationStepOrOpenTheFullProfile.
  ///
  /// In en, this message translates to:
  /// **'Choose the next moderation step or open the full profile.'**
  String get uiChooseTheNextModerationStepOrOpenTheFullProfile;

  /// No description provided for @uiChooseWhetherTheIdeaIsVisibleInDiscoveryAndWhether.
  ///
  /// In en, this message translates to:
  /// **'Choose whether the idea is visible in discovery and whether it reads as a public collaboration opportunity.'**
  String get uiChooseWhetherTheIdeaIsVisibleInDiscoveryAndWhether;

  /// No description provided for @uiChooseYourAccountType.
  ///
  /// In en, this message translates to:
  /// **'Choose your account type.'**
  String get uiChooseYourAccountType;

  /// No description provided for @uiChooseYourDomain.
  ///
  /// In en, this message translates to:
  /// **'Choose your domain'**
  String get uiChooseYourDomain;

  /// No description provided for @uiClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get uiClear;

  /// No description provided for @uiClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get uiClearFilters;

  /// No description provided for @uiClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get uiClearSearch;

  /// No description provided for @uiClosingSoon.
  ///
  /// In en, this message translates to:
  /// **'Closing soon'**
  String get uiClosingSoon;

  /// No description provided for @uiClosingSoonC287.
  ///
  /// In en, this message translates to:
  /// **'Closing Soon'**
  String get uiClosingSoonC287;

  /// No description provided for @uiCloudSupportEngineer.
  ///
  /// In en, this message translates to:
  /// **'Cloud Support Engineer'**
  String get uiCloudSupportEngineer;

  /// No description provided for @uiCollaboration.
  ///
  /// In en, this message translates to:
  /// **'Collaboration'**
  String get uiCollaboration;

  /// No description provided for @uiCollaborationNeeds.
  ///
  /// In en, this message translates to:
  /// **'Collaboration Needs'**
  String get uiCollaborationNeeds;

  /// No description provided for @uiCommercialRegister.
  ///
  /// In en, this message translates to:
  /// **'Commercial Register'**
  String get uiCommercialRegister;

  /// No description provided for @uiCompanies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get uiCompanies;

  /// No description provided for @uiCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get uiCompany;

  /// No description provided for @uiCompanyDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Company Description (optional)'**
  String get uiCompanyDescriptionOptional;

  /// No description provided for @uiCompanyModeration.
  ///
  /// In en, this message translates to:
  /// **'Company moderation'**
  String get uiCompanyModeration;

  /// No description provided for @uiCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get uiCompanyName;

  /// No description provided for @uiCompanyOverview.
  ///
  /// In en, this message translates to:
  /// **'Company Overview'**
  String get uiCompanyOverview;

  /// No description provided for @uiCompanyProfile.
  ///
  /// In en, this message translates to:
  /// **'Company Profile'**
  String get uiCompanyProfile;

  /// No description provided for @uiCompanyRegistration.
  ///
  /// In en, this message translates to:
  /// **'Company Registration'**
  String get uiCompanyRegistration;

  /// No description provided for @uiCompanyReview.
  ///
  /// In en, this message translates to:
  /// **'Company review'**
  String get uiCompanyReview;

  /// No description provided for @uiCompanyReviews.
  ///
  /// In en, this message translates to:
  /// **'Company Reviews'**
  String get uiCompanyReviews;

  /// No description provided for @uiCompensation.
  ///
  /// In en, this message translates to:
  /// **'Compensation'**
  String get uiCompensation;

  /// No description provided for @uiCompetition.
  ///
  /// In en, this message translates to:
  /// **'Competition'**
  String get uiCompetition;

  /// No description provided for @uiCompleteYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get uiCompleteYourProfile;

  /// No description provided for @uiCompleteYourProfile9A4B.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile.'**
  String get uiCompleteYourProfile9A4B;

  /// No description provided for @uiCompletedOfTotalSectionsComplete.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} sections complete'**
  String uiCompletedOfTotalSectionsComplete(Object completed, Object total);

  /// No description provided for @uiCompletion.
  ///
  /// In en, this message translates to:
  /// **'{completion}%'**
  String uiCompletion(Object completion);

  /// No description provided for @uiCompletionReadyForBetterStudentMatching.
  ///
  /// In en, this message translates to:
  /// **'{completion}% ready for better student matching'**
  String uiCompletionReadyForBetterStudentMatching(Object completion);

  /// No description provided for @uiConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get uiConfirmPassword;

  /// No description provided for @uiContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get uiContact;

  /// No description provided for @uiContactPresence.
  ///
  /// In en, this message translates to:
  /// **'Contact & Presence'**
  String get uiContactPresence;

  /// No description provided for @uiContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get uiContactSupport;

  /// No description provided for @uiContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get uiContent;

  /// No description provided for @uiContentNeeded.
  ///
  /// In en, this message translates to:
  /// **'Content needed'**
  String get uiContentNeeded;

  /// No description provided for @uiContentWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Content Workspace'**
  String get uiContentWorkspace;

  /// No description provided for @uiContinueWithConfidenceOnTheOfficialDestination.
  ///
  /// In en, this message translates to:
  /// **'Continue with confidence on the official destination.'**
  String get uiContinueWithConfidenceOnTheOfficialDestination;

  /// No description provided for @uiControl.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get uiControl;

  /// No description provided for @uiConversationContext.
  ///
  /// In en, this message translates to:
  /// **'Conversation Context'**
  String get uiConversationContext;

  /// No description provided for @uiConversationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Conversation deleted'**
  String get uiConversationDeleted;

  /// No description provided for @uiConversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get uiConversations;

  /// No description provided for @uiCoreStory.
  ///
  /// In en, this message translates to:
  /// **'Core Story'**
  String get uiCoreStory;

  /// No description provided for @uiCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get uiCorrect;

  /// No description provided for @uiCouldNotOpenTheScholarshipLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the scholarship link'**
  String get uiCouldNotOpenTheScholarshipLink;

  /// No description provided for @uiCouldNotRefreshOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh opportunities'**
  String get uiCouldNotRefreshOpportunities;

  /// No description provided for @uiCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String uiCount(Object count);

  /// No description provided for @uiCoursesBooksAndCertificationsThatSharpenYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Courses, books, and certifications that sharpen your journey.'**
  String get uiCoursesBooksAndCertificationsThatSharpenYourJourney;

  /// No description provided for @uiCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get uiCreateAccount;

  /// No description provided for @uiCreateAccountEff4.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get uiCreateAccountEff4;

  /// No description provided for @uiCreateTheFirstProjectIdeaToStartShapingTheInnovation.
  ///
  /// In en, this message translates to:
  /// **'Create the first project idea to start shaping the innovation feed.'**
  String get uiCreateTheFirstProjectIdeaToStartShapingTheInnovation;

  /// No description provided for @uiCreateYourFirstIdeaOrAdjustTheFilters.
  ///
  /// In en, this message translates to:
  /// **'Create your first idea or adjust the filters.'**
  String get uiCreateYourFirstIdeaOrAdjustTheFilters;

  /// No description provided for @uiCreator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get uiCreator;

  /// No description provided for @uiCurateImportedBooksAndVideoResourcesFromOnePlace.
  ///
  /// In en, this message translates to:
  /// **'Curate imported books and video resources from one place.'**
  String get uiCurateImportedBooksAndVideoResourcesFromOnePlace;

  /// No description provided for @uiCurateResourceHub.
  ///
  /// In en, this message translates to:
  /// **'Curate resource hub'**
  String get uiCurateResourceHub;

  /// No description provided for @uiCuratedFundingPathsDeadlinesAndGlobalStudyOptions.
  ///
  /// In en, this message translates to:
  /// **'Curated funding paths, deadlines, and global study options.'**
  String get uiCuratedFundingPathsDeadlinesAndGlobalStudyOptions;

  /// No description provided for @uiCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get uiCurrency;

  /// No description provided for @uiCurrentEmail.
  ///
  /// In en, this message translates to:
  /// **'Current email'**
  String get uiCurrentEmail;

  /// No description provided for @uiCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get uiCurrentPassword;

  /// No description provided for @uiCvBuilder.
  ///
  /// In en, this message translates to:
  /// **'CV Studio'**
  String get uiCvBuilder;

  /// No description provided for @uiCvCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'CV Completion Rate'**
  String get uiCvCompletionRate;

  /// No description provided for @uiCvDetailsAreNotAvailableForThisApplication.
  ///
  /// In en, this message translates to:
  /// **'CV details are not available for this application'**
  String get uiCvDetailsAreNotAvailableForThisApplication;

  /// No description provided for @uiCvPreview.
  ///
  /// In en, this message translates to:
  /// **'CV Preview'**
  String get uiCvPreview;

  /// No description provided for @uiCvRequired.
  ///
  /// In en, this message translates to:
  /// **'CV required'**
  String get uiCvRequired;

  /// No description provided for @uiCvSaved.
  ///
  /// In en, this message translates to:
  /// **'CV saved'**
  String get uiCvSaved;

  /// No description provided for @uiCvStudio.
  ///
  /// In en, this message translates to:
  /// **'CV Studio'**
  String get uiCvStudio;

  /// No description provided for @uiDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get uiDashboard;

  /// No description provided for @uiDashboardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Dashboard unavailable'**
  String get uiDashboardUnavailable;

  /// No description provided for @uiDataAnalyst.
  ///
  /// In en, this message translates to:
  /// **'Data Analyst'**
  String get uiDataAnalyst;

  /// No description provided for @uiDataPermissions.
  ///
  /// In en, this message translates to:
  /// **'Data permissions'**
  String get uiDataPermissions;

  /// No description provided for @uiDataSciencePro.
  ///
  /// In en, this message translates to:
  /// **'Data Science Pro'**
  String get uiDataSciencePro;

  /// No description provided for @uiDeadlineExpired.
  ///
  /// In en, this message translates to:
  /// **'Deadline expired'**
  String get uiDeadlineExpired;

  /// No description provided for @uiDeadlineSet.
  ///
  /// In en, this message translates to:
  /// **'Deadline Set'**
  String get uiDeadlineSet;

  /// No description provided for @uiDeckDemoLink.
  ///
  /// In en, this message translates to:
  /// **'Deck / Demo Link'**
  String get uiDeckDemoLink;

  /// No description provided for @uiDegree.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get uiDegree;

  /// No description provided for @uiDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get uiDelete;

  /// No description provided for @uiDeleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete Chat'**
  String get uiDeleteChat;

  /// No description provided for @uiDeleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation?'**
  String get uiDeleteConversation;

  /// No description provided for @uiDeleteForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get uiDeleteForEveryone;

  /// No description provided for @uiDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete message?'**
  String get uiDeleteMessage;

  /// No description provided for @uiDeleteOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Delete opportunity'**
  String get uiDeleteOpportunity;

  /// No description provided for @uiDeleteResource.
  ///
  /// In en, this message translates to:
  /// **'Delete resource'**
  String get uiDeleteResource;

  /// No description provided for @uiDeleteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Delete unavailable'**
  String get uiDeleteUnavailable;

  /// No description provided for @uiDeleteValue1FromFirestoreThisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{value1}\" from Firestore? This action cannot be undone.'**
  String uiDeleteValue1FromFirestoreThisActionCannotBeUndone(Object value1);

  /// No description provided for @uiDeleteValue1IfItAlreadyHasApplicationsItWillBe.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{value1}\"? If it already has applications, it will be closed instead so history is preserved.'**
  String uiDeleteValue1IfItAlreadyHasApplicationsItWillBe(Object value1);

  /// No description provided for @uiDeliveryAccess.
  ///
  /// In en, this message translates to:
  /// **'Delivery & Access'**
  String get uiDeliveryAccess;

  /// No description provided for @uiDesign.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get uiDesign;

  /// No description provided for @uiDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get uiDestination;

  /// No description provided for @uiDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get uiDetails;

  /// No description provided for @uiDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Details unavailable'**
  String get uiDetailsUnavailable;

  /// No description provided for @uiDisabledWhileLevelFilterIsActive.
  ///
  /// In en, this message translates to:
  /// **'Disabled while level filter is active'**
  String get uiDisabledWhileLevelFilterIsActive;

  /// No description provided for @uiDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get uiDiscover;

  /// No description provided for @uiDiscoverPremiumOpenRolesFromTrustedEmployersAndRemoteReady.
  ///
  /// In en, this message translates to:
  /// **'Discover premium open roles from trusted employers and remote-ready teams.'**
  String get uiDiscoverPremiumOpenRolesFromTrustedEmployersAndRemoteReady;

  /// No description provided for @uiDoctorate.
  ///
  /// In en, this message translates to:
  /// **'Doctorate'**
  String get uiDoctorate;

  /// No description provided for @uiDocumentMissing.
  ///
  /// In en, this message translates to:
  /// **'Document missing'**
  String get uiDocumentMissing;

  /// No description provided for @uiDocumentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Document unavailable'**
  String get uiDocumentUnavailable;

  /// No description provided for @uiDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get uiDocuments;

  /// No description provided for @uiDomain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get uiDomain;

  /// No description provided for @uiDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get uiDownload;

  /// No description provided for @uiDownloadA479.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get uiDownloadA479;

  /// No description provided for @uiDownloadBuiltCv.
  ///
  /// In en, this message translates to:
  /// **'Download Built CV'**
  String get uiDownloadBuiltCv;

  /// No description provided for @uiDownloadCv.
  ///
  /// In en, this message translates to:
  /// **'Download CV'**
  String get uiDownloadCv;

  /// No description provided for @uiEachSourceKeepsItsOwnSearchWorkflowAndManagementTools.
  ///
  /// In en, this message translates to:
  /// **'Each source keeps its own search workflow and management tools, but they now live under one library destination.'**
  String get uiEachSourceKeepsItsOwnSearchWorkflowAndManagementTools;

  /// No description provided for @uiEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get uiEdit;

  /// No description provided for @uiEditCompanyProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Company Profile'**
  String get uiEditCompanyProfile;

  /// No description provided for @uiEditCv.
  ///
  /// In en, this message translates to:
  /// **'Edit CV'**
  String get uiEditCv;

  /// No description provided for @uiEditIdea.
  ///
  /// In en, this message translates to:
  /// **'Edit Idea'**
  String get uiEditIdea;

  /// No description provided for @uiEditMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get uiEditMessage;

  /// No description provided for @uiEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get uiEditProfile;

  /// No description provided for @uiEditProfileCd28.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get uiEditProfileCd28;

  /// No description provided for @uiEditingMessage.
  ///
  /// In en, this message translates to:
  /// **'Editing message'**
  String get uiEditingMessage;

  /// No description provided for @uiEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get uiEmail;

  /// No description provided for @uiEmailSignUp.
  ///
  /// In en, this message translates to:
  /// **'Email sign-up'**
  String get uiEmailSignUp;

  /// No description provided for @uiEmailUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Email unavailable'**
  String get uiEmailUnavailable;

  /// No description provided for @uiEmailUpdateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Email update unavailable'**
  String get uiEmailUpdateUnavailable;

  /// No description provided for @uiEmployment.
  ///
  /// In en, this message translates to:
  /// **'Employment'**
  String get uiEmployment;

  /// No description provided for @uiEndThisSessionOnTheCurrentDevice.
  ///
  /// In en, this message translates to:
  /// **'End this session on the current device.'**
  String get uiEndThisSessionOnTheCurrentDevice;

  /// No description provided for @uiEngagementAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Engagement Analytics'**
  String get uiEngagementAnalytics;

  /// No description provided for @uiEnterYourEmailToGetAResetLink.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to get a reset link.'**
  String get uiEnterYourEmailToGetAResetLink;

  /// No description provided for @uiEverythingAroundYourProfileDocumentsNotificationsAndAccountSettings.
  ///
  /// In en, this message translates to:
  /// **'Everything around your profile, documents, notifications, and account settings.'**
  String
  get uiEverythingAroundYourProfileDocumentsNotificationsAndAccountSettings;

  /// No description provided for @uiEverythingImportantIsSurfacedHereBeforeYouOpenTheFull.
  ///
  /// In en, this message translates to:
  /// **'Everything important is surfaced here before you open the full application call.'**
  String get uiEverythingImportantIsSurfacedHereBeforeYouOpenTheFull;

  /// No description provided for @uiExternalApplication.
  ///
  /// In en, this message translates to:
  /// **'External Application'**
  String get uiExternalApplication;

  /// No description provided for @uiExternalLink.
  ///
  /// In en, this message translates to:
  /// **'External Link'**
  String get uiExternalLink;

  /// No description provided for @uiExternalLink6630.
  ///
  /// In en, this message translates to:
  /// **'External link'**
  String get uiExternalLink6630;

  /// No description provided for @uiFailedToLoadAdminContent.
  ///
  /// In en, this message translates to:
  /// **'Failed to load admin content'**
  String get uiFailedToLoadAdminContent;

  /// No description provided for @uiFaqs.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get uiFaqs;

  /// No description provided for @uiFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get uiFeatured;

  /// No description provided for @uiFeaturedDestination.
  ///
  /// In en, this message translates to:
  /// **'Featured destination'**
  String get uiFeaturedDestination;

  /// No description provided for @uiFeaturedFreshAndHighSignalPicksFromLiveData.
  ///
  /// In en, this message translates to:
  /// **'Featured, fresh, and high-signal picks from live data'**
  String get uiFeaturedFreshAndHighSignalPicksFromLiveData;

  /// No description provided for @uiFeaturedInternships.
  ///
  /// In en, this message translates to:
  /// **'Featured Internships'**
  String get uiFeaturedInternships;

  /// No description provided for @uiFeaturedJobs.
  ///
  /// In en, this message translates to:
  /// **'Featured Jobs'**
  String get uiFeaturedJobs;

  /// No description provided for @uiFeaturedListUpdated.
  ///
  /// In en, this message translates to:
  /// **'Featured list updated'**
  String get uiFeaturedListUpdated;

  /// No description provided for @uiFeaturedScholarship.
  ///
  /// In en, this message translates to:
  /// **'Featured\nScholarship'**
  String get uiFeaturedScholarship;

  /// No description provided for @uiFeaturedcountFeaturedResources.
  ///
  /// In en, this message translates to:
  /// **'{featuredCount} featured resources'**
  String uiFeaturedcountFeaturedResources(Object featuredCount);

  /// No description provided for @uiFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get uiFeed;

  /// No description provided for @uiFieldOfStudy.
  ///
  /// In en, this message translates to:
  /// **'Field of Study'**
  String get uiFieldOfStudy;

  /// No description provided for @uiFieldOfStudy81E2.
  ///
  /// In en, this message translates to:
  /// **'Field Of Study'**
  String get uiFieldOfStudy81E2;

  /// No description provided for @uiFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get uiFile;

  /// No description provided for @uiFilterOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Filter opportunities'**
  String get uiFilterOpportunities;

  /// No description provided for @uiFindBooksByDomainLevelAndLanguageThenImportThem.
  ///
  /// In en, this message translates to:
  /// **'Find books by domain, level, and language, then import them into the training library with admin metadata.'**
  String get uiFindBooksByDomainLevelAndLanguageThenImportThem;

  /// No description provided for @uiFindYourNextBestOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Find your next best opportunity.'**
  String get uiFindYourNextBestOpportunity;

  /// No description provided for @uiFindYourNextMove.
  ///
  /// In en, this message translates to:
  /// **'Find your next move.'**
  String get uiFindYourNextMove;

  /// No description provided for @uiFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get uiFinish;

  /// No description provided for @uiFinishProfile.
  ///
  /// In en, this message translates to:
  /// **'Finish profile'**
  String get uiFinishProfile;

  /// No description provided for @uiFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get uiFocus;

  /// No description provided for @uiFocusSearch.
  ///
  /// In en, this message translates to:
  /// **'Focus search'**
  String get uiFocusSearch;

  /// No description provided for @uiFocusedApplicationView.
  ///
  /// In en, this message translates to:
  /// **'Focused application view'**
  String get uiFocusedApplicationView;

  /// No description provided for @uiForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get uiForgotPassword;

  /// No description provided for @uiFormalize.
  ///
  /// In en, this message translates to:
  /// **'Formalize'**
  String get uiFormalize;

  /// No description provided for @uiFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get uiFree;

  /// No description provided for @uiFreshRecommendationsAreHighlightedAsNewListingsGoLive.
  ///
  /// In en, this message translates to:
  /// **'Fresh recommendations are highlighted as new listings go live.'**
  String get uiFreshRecommendationsAreHighlightedAsNewListingsGoLive;

  /// No description provided for @uiFullDescription.
  ///
  /// In en, this message translates to:
  /// **'Full description'**
  String get uiFullDescription;

  /// No description provided for @uiFullDescriptionB43E.
  ///
  /// In en, this message translates to:
  /// **'Full Description'**
  String get uiFullDescriptionB43E;

  /// No description provided for @uiFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get uiFullName;

  /// No description provided for @uiFullTuitionCoverage.
  ///
  /// In en, this message translates to:
  /// **'Full Tuition Coverage'**
  String get uiFullTuitionCoverage;

  /// No description provided for @uiFunding.
  ///
  /// In en, this message translates to:
  /// **'Funding'**
  String get uiFunding;

  /// No description provided for @uiFundingOpportunitiesDeadlinesAndGlobalStudyPaths.
  ///
  /// In en, this message translates to:
  /// **'Funding opportunities, deadlines, and global study paths.'**
  String get uiFundingOpportunitiesDeadlinesAndGlobalStudyPaths;

  /// No description provided for @uiFundingValue1.
  ///
  /// In en, this message translates to:
  /// **'Funding: {value1}'**
  String uiFundingValue1(Object value1);

  /// No description provided for @uiFuturegateExpectsAccurateProfilesRespectfulCommunicationAndResponsibleUseOf.
  ///
  /// In en, this message translates to:
  /// **'FutureGate expects accurate profiles, respectful communication, and responsible use of the application and content tools available in the app.'**
  String
  get uiFuturegateExpectsAccurateProfilesRespectfulCommunicationAndResponsibleUseOf;

  /// No description provided for @uiFuturegateIsDesignedAsABridgeBetweenStudentsTheirGrowing.
  ///
  /// In en, this message translates to:
  /// **'FutureGate is designed as a bridge between students, their growing skills, and the real opportunities that can shape their next milestone.'**
  String get uiFuturegateIsDesignedAsABridgeBetweenStudentsTheirGrowing;

  /// No description provided for @uiFuturegateStoresTheProfileDetailsCvContentSavedItemsAnd.
  ///
  /// In en, this message translates to:
  /// **'FutureGate stores the profile details, CV content, saved items, and application activity needed to match students with opportunities and support application review.'**
  String get uiFuturegateStoresTheProfileDetailsCvContentSavedItemsAnd;

  /// No description provided for @uiGenerateAPolishedPdfFromYourCv.
  ///
  /// In en, this message translates to:
  /// **'Generate a polished PDF from your CV.'**
  String get uiGenerateAPolishedPdfFromYourCv;

  /// No description provided for @uiGeneratingPdf.
  ///
  /// In en, this message translates to:
  /// **'Generating PDF...'**
  String get uiGeneratingPdf;

  /// No description provided for @uiGlobalScholarship.
  ///
  /// In en, this message translates to:
  /// **'Global Scholarship'**
  String get uiGlobalScholarship;

  /// No description provided for @uiGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get uiGoogle;

  /// No description provided for @uiGoogleBooks.
  ///
  /// In en, this message translates to:
  /// **'Google Books'**
  String get uiGoogleBooks;

  /// No description provided for @uiGoogleBooksImport.
  ///
  /// In en, this message translates to:
  /// **'Google Books Import'**
  String get uiGoogleBooksImport;

  /// No description provided for @uiGoogleSignInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in unavailable'**
  String get uiGoogleSignInUnavailable;

  /// No description provided for @uiGrants.
  ///
  /// In en, this message translates to:
  /// **'Grants'**
  String get uiGrants;

  /// No description provided for @uiGrowthMarketingLead.
  ///
  /// In en, this message translates to:
  /// **'Growth Marketing Lead'**
  String get uiGrowthMarketingLead;

  /// No description provided for @uiGrowthRate.
  ///
  /// In en, this message translates to:
  /// **'GROWTH RATE'**
  String get uiGrowthRate;

  /// No description provided for @uiHandsOnStudentPlacements.
  ///
  /// In en, this message translates to:
  /// **'Hands-on student placements'**
  String get uiHandsOnStudentPlacements;

  /// No description provided for @uiHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get uiHealth;

  /// No description provided for @uiHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get uiHelpCenter;

  /// No description provided for @uiHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get uiHidden;

  /// No description provided for @uiHighlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get uiHighlights;

  /// No description provided for @uiHiringInsights.
  ///
  /// In en, this message translates to:
  /// **'Hiring Insights'**
  String get uiHiringInsights;

  /// No description provided for @uiHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get uiHome;

  /// No description provided for @uiHowCanWeHelp.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get uiHowCanWeHelp;

  /// No description provided for @uiIMACompany.
  ///
  /// In en, this message translates to:
  /// **'I\'m a Company'**
  String get uiIMACompany;

  /// No description provided for @uiIMAStudent.
  ///
  /// In en, this message translates to:
  /// **'I\'m a Student'**
  String get uiIMAStudent;

  /// No description provided for @uiIVerified.
  ///
  /// In en, this message translates to:
  /// **'I Verified'**
  String get uiIVerified;

  /// No description provided for @uiIdeaBasics.
  ///
  /// In en, this message translates to:
  /// **'Idea Basics'**
  String get uiIdeaBasics;

  /// No description provided for @uiIdeaDescription.
  ///
  /// In en, this message translates to:
  /// **'Idea Description'**
  String get uiIdeaDescription;

  /// No description provided for @uiIdeaOverview.
  ///
  /// In en, this message translates to:
  /// **'Idea Overview'**
  String get uiIdeaOverview;

  /// No description provided for @uiIdeaTitle.
  ///
  /// In en, this message translates to:
  /// **'Idea title'**
  String get uiIdeaTitle;

  /// No description provided for @uiIdeaTitleAd83.
  ///
  /// In en, this message translates to:
  /// **'Idea Title'**
  String get uiIdeaTitleAd83;

  /// No description provided for @uiIdeas.
  ///
  /// In en, this message translates to:
  /// **'Ideas'**
  String get uiIdeas;

  /// No description provided for @uiIfThisAccountNormallySignsInWithGoogleReturnAnd.
  ///
  /// In en, this message translates to:
  /// **'If this account normally signs in with Google, return and use Google now, then add a password later from Settings if needed.'**
  String get uiIfThisAccountNormallySignsInWithGoogleReturnAnd;

  /// No description provided for @uiIfYouCreatedThisAccountWithGoogleUseGoogleTo.
  ///
  /// In en, this message translates to:
  /// **'If you created this account with Google, use Google to sign in now. After that, you can add a password from Settings if you want email/password access too.'**
  String get uiIfYouCreatedThisAccountWithGoogleUseGoogleTo;

  /// No description provided for @uiIllustratorIntern.
  ///
  /// In en, this message translates to:
  /// **'Illustrator Intern'**
  String get uiIllustratorIntern;

  /// No description provided for @uiImportAFewGoogleBooksResultsFirstThenManageFeaturing.
  ///
  /// In en, this message translates to:
  /// **'Import a few Google Books results first, then manage featuring, opening, and deleting from here.'**
  String get uiImportAFewGoogleBooksResultsFirstThenManageFeaturing;

  /// No description provided for @uiImportAFewYoutubeResultsFirstThenManageFeaturingOpening.
  ///
  /// In en, this message translates to:
  /// **'Import a few YouTube results first, then manage featuring, opening, and deleting from here.'**
  String get uiImportAFewYoutubeResultsFirstThenManageFeaturingOpening;

  /// No description provided for @uiImportBooks.
  ///
  /// In en, this message translates to:
  /// **'Import Books'**
  String get uiImportBooks;

  /// No description provided for @uiImportComplete.
  ///
  /// In en, this message translates to:
  /// **'Import complete'**
  String get uiImportComplete;

  /// No description provided for @uiImportGoogleBooks.
  ///
  /// In en, this message translates to:
  /// **'Import Google Books'**
  String get uiImportGoogleBooks;

  /// No description provided for @uiImportPipelines.
  ///
  /// In en, this message translates to:
  /// **'Import Pipelines'**
  String get uiImportPipelines;

  /// No description provided for @uiImportTheFirstLearningResourceToStartBuildingTheTraining.
  ///
  /// In en, this message translates to:
  /// **'Import the first learning resource to start building the training library.'**
  String get uiImportTheFirstLearningResourceToStartBuildingTheTraining;

  /// No description provided for @uiImportTrustedLearningResourcesKeepFeaturedContentFreshAndTurn.
  ///
  /// In en, this message translates to:
  /// **'Import trusted learning resources, keep featured content fresh, and turn external sources into a clean admin-managed library.'**
  String get uiImportTrustedLearningResourcesKeepFeaturedContentFreshAndTurn;

  /// No description provided for @uiImportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Import unavailable'**
  String get uiImportUnavailable;

  /// No description provided for @uiImportVideos.
  ///
  /// In en, this message translates to:
  /// **'Import Videos'**
  String get uiImportVideos;

  /// No description provided for @uiImportYoutubeVideos.
  ///
  /// In en, this message translates to:
  /// **'Import YouTube Videos'**
  String get uiImportYoutubeVideos;

  /// No description provided for @uiImportantFieldsAreGroupedHereInAMoreReadableAdmin.
  ///
  /// In en, this message translates to:
  /// **'Important fields are grouped here in a more readable admin detail layout.'**
  String get uiImportantFieldsAreGroupedHereInAMoreReadableAdmin;

  /// No description provided for @uiImported.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get uiImported;

  /// No description provided for @uiIndustrySectorOptional.
  ///
  /// In en, this message translates to:
  /// **'Industry / Sector (optional)'**
  String get uiIndustrySectorOptional;

  /// No description provided for @uiInnovationHub.
  ///
  /// In en, this message translates to:
  /// **'Innovation Hub'**
  String get uiInnovationHub;

  /// No description provided for @uiInstitution.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get uiInstitution;

  /// No description provided for @uiInterestSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Interest Snapshot'**
  String get uiInterestSnapshot;

  /// No description provided for @uiInterested.
  ///
  /// In en, this message translates to:
  /// **'Interested'**
  String get uiInterested;

  /// No description provided for @uiInterestedcountInterested.
  ///
  /// In en, this message translates to:
  /// **'{interestedCount} Interested'**
  String uiInterestedcountInterested(Object interestedCount);

  /// No description provided for @uiInternships.
  ///
  /// In en, this message translates to:
  /// **'Internships'**
  String get uiInternships;

  /// No description provided for @uiItemMetadata.
  ///
  /// In en, this message translates to:
  /// **'Item Metadata'**
  String get uiItemMetadata;

  /// No description provided for @uiJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get uiJobs;

  /// No description provided for @uiJobsInternshipsAndSponsoredTracksMatchedToYourNextMove.
  ///
  /// In en, this message translates to:
  /// **'Jobs, internships, and sponsored tracks matched to your next move.'**
  String get uiJobsInternshipsAndSponsoredTracksMatchedToYourNextMove;

  /// No description provided for @uiJobsInternshipsSponsoredTracksAndTrainingInOneStream.
  ///
  /// In en, this message translates to:
  /// **'Jobs, internships, sponsored tracks, and training in one stream.'**
  String get uiJobsInternshipsSponsoredTracksAndTrainingInOneStream;

  /// No description provided for @uiJoinFuturegate.
  ///
  /// In en, this message translates to:
  /// **'Join FutureGate'**
  String get uiJoinFuturegate;

  /// No description provided for @uiJumpBackIntoEverythingYouBookmarked.
  ///
  /// In en, this message translates to:
  /// **'Jump back into everything you bookmarked.'**
  String get uiJumpBackIntoEverythingYouBookmarked;

  /// No description provided for @uiJumpStraightIntoTheAdminAreasYouOpenMostOften.
  ///
  /// In en, this message translates to:
  /// **'Jump straight into the admin areas you open most often.'**
  String get uiJumpStraightIntoTheAdminAreasYouOpenMostOften;

  /// No description provided for @uiJuniorFrontendDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Junior Frontend Developer'**
  String get uiJuniorFrontendDeveloper;

  /// No description provided for @uiKeepACurrentVerificationDocumentAttachedToMaintainATrustworthy.
  ///
  /// In en, this message translates to:
  /// **'Keep a current verification document attached to maintain a trustworthy company profile.'**
  String get uiKeepACurrentVerificationDocumentAttachedToMaintainATrustworthy;

  /// No description provided for @uiKeepAFewStrongOptionsMovingWhileYouWaitFor.
  ///
  /// In en, this message translates to:
  /// **'Keep a few strong options moving while you wait for responses.'**
  String get uiKeepAFewStrongOptionsMovingWhileYouWaitFor;

  /// No description provided for @uiKeepApplyingWhileTeamsAreAlreadyEngagingWithYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Keep applying while teams are already engaging with your profile.'**
  String get uiKeepApplyingWhileTeamsAreAlreadyEngagingWithYourProfile;

  /// No description provided for @uiKeepGoogleSignInAndAddEmailPasswordToo.
  ///
  /// In en, this message translates to:
  /// **'Keep Google sign-in and add email/password too'**
  String get uiKeepGoogleSignInAndAddEmailPasswordToo;

  /// No description provided for @uiKeepItOutOfDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Keep it out of discovery'**
  String get uiKeepItOutOfDiscovery;

  /// No description provided for @uiKeepOutOfDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Keep out of discovery'**
  String get uiKeepOutOfDiscovery;

  /// No description provided for @uiKeepTheCompanyOutOfTheWorkspaceUntilTheProfile.
  ///
  /// In en, this message translates to:
  /// **'Keep the company out of the workspace until the profile is corrected.'**
  String get uiKeepTheCompanyOutOfTheWorkspaceUntilTheProfile;

  /// No description provided for @uiKeepTheExistingDataSourceButTailorWhatYouSee.
  ///
  /// In en, this message translates to:
  /// **'Keep the existing data source, but tailor what you see.'**
  String get uiKeepTheExistingDataSourceButTailorWhatYouSee;

  /// No description provided for @uiKeepTheHeadlineAndOverviewCrispSoTheIdeaReads.
  ///
  /// In en, this message translates to:
  /// **'Keep the headline and overview crisp so the idea reads strongly in both cards and full detail views.'**
  String get uiKeepTheHeadlineAndOverviewCrispSoTheIdeaReads;

  /// No description provided for @uiKeepThePageGroundedInTheCurrentAppBehaviorInstead.
  ///
  /// In en, this message translates to:
  /// **'Keep the page grounded in the current app behavior instead of introducing unsupported settings.'**
  String get uiKeepThePageGroundedInTheCurrentAppBehaviorInstead;

  /// No description provided for @uiKeepTheProfileCrispTrustworthyAndReadyForStudentsTo.
  ///
  /// In en, this message translates to:
  /// **'Keep the profile crisp, trustworthy, and ready for students to explore.'**
  String get uiKeepTheProfileCrispTrustworthyAndReadyForStudentsTo;

  /// No description provided for @uiKeepVisibilityDecisionsInTheSameStructuredPublishingAreaUsed.
  ///
  /// In en, this message translates to:
  /// **'Keep visibility decisions in the same structured publishing area used across content flows.'**
  String get uiKeepVisibilityDecisionsInTheSameStructuredPublishingAreaUsed;

  /// No description provided for @uiKeepYourCompanyPresenceTrustedWithAnUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Keep your company presence trusted with an up-to-date commercial register.'**
  String get uiKeepYourCompanyPresenceTrustedWithAnUpToDate;

  /// No description provided for @uiKeepYourStudentContextCurrentSoOpportunityMatchingStaysUseful.
  ///
  /// In en, this message translates to:
  /// **'Keep your student context current so opportunity matching stays useful.'**
  String get uiKeepYourStudentContextCurrentSoOpportunityMatchingStaysUseful;

  /// No description provided for @uiKeySkills.
  ///
  /// In en, this message translates to:
  /// **'Key Skills'**
  String get uiKeySkills;

  /// No description provided for @uiLabelValue.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String uiLabelValue(Object label, Object value);

  /// No description provided for @uiLaboratory.
  ///
  /// In en, this message translates to:
  /// **'Laboratory'**
  String get uiLaboratory;

  /// No description provided for @uiLanguageFilters.
  ///
  /// In en, this message translates to:
  /// **'Language Filters'**
  String get uiLanguageFilters;

  /// No description provided for @uiLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get uiLanguages;

  /// No description provided for @uiLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get uiLastUpdated;

  /// No description provided for @uiLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get uiLater;

  /// No description provided for @uiLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get uiLatest;

  /// No description provided for @uiLatestOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Latest Opportunities'**
  String get uiLatestOpportunities;

  /// No description provided for @uiLearnMoreAboutThePlatform.
  ///
  /// In en, this message translates to:
  /// **'Learn more about the platform.'**
  String get uiLearnMoreAboutThePlatform;

  /// No description provided for @uiLearners.
  ///
  /// In en, this message translates to:
  /// **'Learners'**
  String get uiLearners;

  /// No description provided for @uiLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get uiLegal;

  /// No description provided for @uiLevelFilters.
  ///
  /// In en, this message translates to:
  /// **'Level filters'**
  String get uiLevelFilters;

  /// No description provided for @uiLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get uiLibrary;

  /// No description provided for @uiLibraryOverview.
  ///
  /// In en, this message translates to:
  /// **'Library Overview'**
  String get uiLibraryOverview;

  /// No description provided for @uiLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get uiLink;

  /// No description provided for @uiLinkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Link unavailable'**
  String get uiLinkUnavailable;

  /// No description provided for @uiLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get uiLive;

  /// No description provided for @uiLiveFeed.
  ///
  /// In en, this message translates to:
  /// **'Live Feed'**
  String get uiLiveFeed;

  /// No description provided for @uiLiveProfileDetailsCouldNotBeRefreshedSoYouAre.
  ///
  /// In en, this message translates to:
  /// **'Live profile details could not be refreshed, so you are seeing safe fallback information.'**
  String get uiLiveProfileDetailsCouldNotBeRefreshedSoYouAre;

  /// No description provided for @uiLoadingLiveInternships.
  ///
  /// In en, this message translates to:
  /// **'Loading live internships...'**
  String get uiLoadingLiveInternships;

  /// No description provided for @uiLoadingOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Loading opportunities...'**
  String get uiLoadingOpportunities;

  /// No description provided for @uiLoadingYourApplications.
  ///
  /// In en, this message translates to:
  /// **'Loading your applications...'**
  String get uiLoadingYourApplications;

  /// No description provided for @uiLoadingYourSavedItems.
  ///
  /// In en, this message translates to:
  /// **'Loading your saved items...'**
  String get uiLoadingYourSavedItems;

  /// No description provided for @uiLocationAndLogistics.
  ///
  /// In en, this message translates to:
  /// **'Location And Logistics'**
  String get uiLocationAndLogistics;

  /// No description provided for @uiLocationLogistics.
  ///
  /// In en, this message translates to:
  /// **'Location & Logistics'**
  String get uiLocationLogistics;

  /// No description provided for @uiLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get uiLogin;

  /// No description provided for @uiLoginToContinue.
  ///
  /// In en, this message translates to:
  /// **'Login to continue.'**
  String get uiLoginToContinue;

  /// No description provided for @uiLoginUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Login unavailable'**
  String get uiLoginUnavailable;

  /// No description provided for @uiLogoVisualIdentity.
  ///
  /// In en, this message translates to:
  /// **'Logo & Visual Identity'**
  String get uiLogoVisualIdentity;

  /// No description provided for @uiLoomStudioDesign.
  ///
  /// In en, this message translates to:
  /// **'Loom Studio â¢ Design'**
  String get uiLoomStudioDesign;

  /// No description provided for @uiMakeItEasyForStudentsToUnderstandWhereYourCompany.
  ///
  /// In en, this message translates to:
  /// **'Make it easy for students to understand where your company is and how to reach it.'**
  String get uiMakeItEasyForStudentsToUnderstandWhereYourCompany;

  /// No description provided for @uiManageImportedBooks.
  ///
  /// In en, this message translates to:
  /// **'Manage Imported Books'**
  String get uiManageImportedBooks;

  /// No description provided for @uiManageImportedVideos.
  ///
  /// In en, this message translates to:
  /// **'Manage Imported Videos'**
  String get uiManageImportedVideos;

  /// No description provided for @uiManageLiveOffers.
  ///
  /// In en, this message translates to:
  /// **'Manage live offers'**
  String get uiManageLiveOffers;

  /// No description provided for @uiManageSessionsDevices.
  ///
  /// In en, this message translates to:
  /// **'Manage sessions & devices'**
  String get uiManageSessionsDevices;

  /// No description provided for @uiManageTeam.
  ///
  /// In en, this message translates to:
  /// **'Manage Team'**
  String get uiManageTeam;

  /// No description provided for @uiManageYourListings.
  ///
  /// In en, this message translates to:
  /// **'Manage your listings'**
  String get uiManageYourListings;

  /// No description provided for @uiManagedInventory.
  ///
  /// In en, this message translates to:
  /// **'Managed Inventory'**
  String get uiManagedInventory;

  /// No description provided for @uiMarkPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Mark Pending Review'**
  String get uiMarkPendingReview;

  /// No description provided for @uiMarketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get uiMarketing;

  /// No description provided for @uiMarketingAnalyst.
  ///
  /// In en, this message translates to:
  /// **'Marketing Analyst'**
  String get uiMarketingAnalyst;

  /// No description provided for @uiMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get uiMessage;

  /// No description provided for @uiMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Message required'**
  String get uiMessageRequired;

  /// No description provided for @uiMessageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Message unavailable'**
  String get uiMessageUnavailable;

  /// No description provided for @uiMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get uiMessages;

  /// No description provided for @uiMessagesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Messages unavailable'**
  String get uiMessagesUnavailable;

  /// No description provided for @uiManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get uiManage;

  /// No description provided for @uiMetadataAndCollaboration.
  ///
  /// In en, this message translates to:
  /// **'Metadata and collaboration'**
  String get uiMetadataAndCollaboration;

  /// No description provided for @uiMissingCommercialRegisterDocument.
  ///
  /// In en, this message translates to:
  /// **'Missing commercial register document.'**
  String get uiMissingCommercialRegisterDocument;

  /// No description provided for @uiMissingcountValue1StillMissingForBetterMatching.
  ///
  /// In en, this message translates to:
  /// **'{missingCount} {value1} still missing for better matching.'**
  String uiMissingcountValue1StillMissingForBetterMatching(
    Object value1,
    Object missingCount,
  );

  /// No description provided for @uiModerateIdeaQueue.
  ///
  /// In en, this message translates to:
  /// **'Moderate idea queue'**
  String get uiModerateIdeaQueue;

  /// No description provided for @uiModerateIdeasApplicationsListingsScholarshipsAndTraining.
  ///
  /// In en, this message translates to:
  /// **'Moderate ideas, applications, listings, scholarships, and training.'**
  String get uiModerateIdeasApplicationsListingsScholarshipsAndTraining;

  /// No description provided for @uiModeration.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get uiModeration;

  /// No description provided for @uiModerationActions.
  ///
  /// In en, this message translates to:
  /// **'Moderation Actions'**
  String get uiModerationActions;

  /// No description provided for @uiMonthlyRegistrations.
  ///
  /// In en, this message translates to:
  /// **'Monthly Registrations'**
  String get uiMonthlyRegistrations;

  /// No description provided for @uiMoreInformation.
  ///
  /// In en, this message translates to:
  /// **'More Information'**
  String get uiMoreInformation;

  /// No description provided for @uiMostAppliedOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Most Applied Opportunities'**
  String get uiMostAppliedOpportunities;

  /// No description provided for @uiMostRecentStudentApplicationsFromYourRealData.
  ///
  /// In en, this message translates to:
  /// **'Most recent student applications from your real data.'**
  String get uiMostRecentStudentApplicationsFromYourRealData;

  /// No description provided for @uiMostSavedOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Most Saved Opportunities'**
  String get uiMostSavedOpportunities;

  /// No description provided for @uiMoveTheCompanyBackIntoTheReviewQueueForAnother.
  ///
  /// In en, this message translates to:
  /// **'Move the company back into the review queue for another check.'**
  String get uiMoveTheCompanyBackIntoTheReviewQueueForAnother;

  /// No description provided for @uiMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get uiMuted;

  /// No description provided for @uiMyCv.
  ///
  /// In en, this message translates to:
  /// **'My CV'**
  String get uiMyCv;

  /// No description provided for @uiMyIdeas.
  ///
  /// In en, this message translates to:
  /// **'My Ideas'**
  String get uiMyIdeas;

  /// No description provided for @uiNameExampleCom.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get uiNameExampleCom;

  /// No description provided for @uiNeedToReviewYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Need to review your profile?'**
  String get uiNeedToReviewYourProfile;

  /// No description provided for @uiNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get uiNew;

  /// No description provided for @uiNewChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get uiNewChat;

  /// No description provided for @uiNewEmail.
  ///
  /// In en, this message translates to:
  /// **'New Email'**
  String get uiNewEmail;

  /// No description provided for @uiNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get uiNewPassword;

  /// No description provided for @uiNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get uiNewestFirst;

  /// No description provided for @uiNoActivityMatchesThisSearch.
  ///
  /// In en, this message translates to:
  /// **'No activity matches this search'**
  String get uiNoActivityMatchesThisSearch;

  /// No description provided for @uiNoApplicationsToReviewYet.
  ///
  /// In en, this message translates to:
  /// **'No applications to review yet'**
  String get uiNoApplicationsToReviewYet;

  /// No description provided for @uiNoApplicationsYet.
  ///
  /// In en, this message translates to:
  /// **'No applications yet'**
  String get uiNoApplicationsYet;

  /// No description provided for @uiNoBooksImportedYet.
  ///
  /// In en, this message translates to:
  /// **'No books imported yet'**
  String get uiNoBooksImportedYet;

  /// No description provided for @uiNoBooksMatchThisSearch.
  ///
  /// In en, this message translates to:
  /// **'No books match this search'**
  String get uiNoBooksMatchThisSearch;

  /// No description provided for @uiNoCvAvailableForValue1.
  ///
  /// In en, this message translates to:
  /// **'No CV available for {value1}'**
  String uiNoCvAvailableForValue1(Object value1);

  /// No description provided for @uiNoHelpTopicsMatchYourSearch.
  ///
  /// In en, this message translates to:
  /// **'No help topics match your search'**
  String get uiNoHelpTopicsMatchYourSearch;

  /// No description provided for @uiNoHighlightsAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'No highlights available yet'**
  String get uiNoHighlightsAvailableYet;

  /// No description provided for @uiNoIdeasMatchThisView.
  ///
  /// In en, this message translates to:
  /// **'No ideas match this view'**
  String get uiNoIdeasMatchThisView;

  /// No description provided for @uiNoIdeasYet.
  ///
  /// In en, this message translates to:
  /// **'No ideas yet'**
  String get uiNoIdeasYet;

  /// No description provided for @uiNoInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get uiNoInternetConnection;

  /// No description provided for @uiNoLearningResourcesYet.
  ///
  /// In en, this message translates to:
  /// **'No learning resources yet'**
  String get uiNoLearningResourcesYet;

  /// No description provided for @uiNoOpportunitiesMatchThisView.
  ///
  /// In en, this message translates to:
  /// **'No opportunities match this view'**
  String get uiNoOpportunitiesMatchThisView;

  /// No description provided for @uiNoOpportunitiesPublishedYet.
  ///
  /// In en, this message translates to:
  /// **'No opportunities published yet'**
  String get uiNoOpportunitiesPublishedYet;

  /// No description provided for @uiNoProjectIdeasToReviewYet.
  ///
  /// In en, this message translates to:
  /// **'No project ideas to review yet'**
  String get uiNoProjectIdeasToReviewYet;

  /// No description provided for @uiNoRecentActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No recent activity yet'**
  String get uiNoRecentActivityYet;

  /// No description provided for @uiNoRecentUsersYet.
  ///
  /// In en, this message translates to:
  /// **'No recent users yet'**
  String get uiNoRecentUsersYet;

  /// No description provided for @uiNoRecommendationsRightNow.
  ///
  /// In en, this message translates to:
  /// **'No recommendations right now'**
  String get uiNoRecommendationsRightNow;

  /// No description provided for @uiNoRequirementsProvided.
  ///
  /// In en, this message translates to:
  /// **'No requirements provided.'**
  String get uiNoRequirementsProvided;

  /// No description provided for @uiNoResultsInThisView.
  ///
  /// In en, this message translates to:
  /// **'No results in this view'**
  String get uiNoResultsInThisView;

  /// No description provided for @uiNoScholarshipLinkIsAvailableForThisItemYet.
  ///
  /// In en, this message translates to:
  /// **'No scholarship link is available for this item yet'**
  String get uiNoScholarshipLinkIsAvailableForThisItemYet;

  /// No description provided for @uiNoScholarshipsMatchYourSearch.
  ///
  /// In en, this message translates to:
  /// **'No scholarships match your search'**
  String get uiNoScholarshipsMatchYourSearch;

  /// No description provided for @uiNoScholarshipsPublishedYet.
  ///
  /// In en, this message translates to:
  /// **'No scholarships published yet'**
  String get uiNoScholarshipsPublishedYet;

  /// No description provided for @uiNoTrainingProgramsAvailableInThisTopic.
  ///
  /// In en, this message translates to:
  /// **'No training programs available in this topic'**
  String get uiNoTrainingProgramsAvailableInThisTopic;

  /// No description provided for @uiNoTrainingProgramsAvailableRightNow.
  ///
  /// In en, this message translates to:
  /// **'No training programs available right now'**
  String get uiNoTrainingProgramsAvailableRightNow;

  /// No description provided for @uiNoTrendingOpportunitiesRightNow.
  ///
  /// In en, this message translates to:
  /// **'No trending opportunities right now'**
  String get uiNoTrendingOpportunitiesRightNow;

  /// No description provided for @uiNoUrgentDeadlinesRightNow.
  ///
  /// In en, this message translates to:
  /// **'No urgent deadlines right now'**
  String get uiNoUrgentDeadlinesRightNow;

  /// No description provided for @uiNoUsersMatchThisSearch.
  ///
  /// In en, this message translates to:
  /// **'No users match this search'**
  String get uiNoUsersMatchThisSearch;

  /// No description provided for @uiNoVerificationDocumentUploadedYet.
  ///
  /// In en, this message translates to:
  /// **'No verification document uploaded yet'**
  String get uiNoVerificationDocumentUploadedYet;

  /// No description provided for @uiNoVideosImportedYet.
  ///
  /// In en, this message translates to:
  /// **'No videos imported yet'**
  String get uiNoVideosImportedYet;

  /// No description provided for @uiNoVideosMatchThisSearch.
  ///
  /// In en, this message translates to:
  /// **'No videos match this search'**
  String get uiNoVideosMatchThisSearch;

  /// No description provided for @uiNorthMetricsAnalytics.
  ///
  /// In en, this message translates to:
  /// **'North Metrics â¢ Analytics'**
  String get uiNorthMetricsAnalytics;

  /// No description provided for @uiNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get uiNotSignedIn;

  /// No description provided for @uiNotificationCenter.
  ///
  /// In en, this message translates to:
  /// **'Notification Center'**
  String get uiNotificationCenter;

  /// No description provided for @uiNovaLabsProductDesign.
  ///
  /// In en, this message translates to:
  /// **'Nova Labs â¢ Product Design'**
  String get uiNovaLabsProductDesign;

  /// No description provided for @uiOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get uiOffers;

  /// No description provided for @uiOneQuickStep.
  ///
  /// In en, this message translates to:
  /// **'One quick step'**
  String get uiOneQuickStep;

  /// No description provided for @uiOpenActivity.
  ///
  /// In en, this message translates to:
  /// **'Open activity'**
  String get uiOpenActivity;

  /// No description provided for @uiOpenActivityF327.
  ///
  /// In en, this message translates to:
  /// **'Open Activity'**
  String get uiOpenActivityF327;

  /// No description provided for @uiOpenAttachment.
  ///
  /// In en, this message translates to:
  /// **'Open Attachment'**
  String get uiOpenAttachment;

  /// No description provided for @uiOpenCandidateProfileForStudentname.
  ///
  /// In en, this message translates to:
  /// **'Open candidate profile for {studentName}'**
  String uiOpenCandidateProfileForStudentname(Object studentName);

  /// No description provided for @uiOpenCvStudio.
  ///
  /// In en, this message translates to:
  /// **'Open CV Studio'**
  String get uiOpenCvStudio;

  /// No description provided for @uiOpenDetails.
  ///
  /// In en, this message translates to:
  /// **'Open details'**
  String get uiOpenDetails;

  /// No description provided for @uiOpenLibraryStudio.
  ///
  /// In en, this message translates to:
  /// **'Open Library Studio'**
  String get uiOpenLibraryStudio;

  /// No description provided for @uiOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open Link'**
  String get uiOpenLink;

  /// No description provided for @uiOpenResource.
  ///
  /// In en, this message translates to:
  /// **'Open Resource'**
  String get uiOpenResource;

  /// No description provided for @uiOpenRoles.
  ///
  /// In en, this message translates to:
  /// **'Open Roles'**
  String get uiOpenRoles;

  /// No description provided for @uiOpenScholarshipLink.
  ///
  /// In en, this message translates to:
  /// **'Open Scholarship Link'**
  String get uiOpenScholarshipLink;

  /// No description provided for @uiOpenStudio.
  ///
  /// In en, this message translates to:
  /// **'Open Studio'**
  String get uiOpenStudio;

  /// No description provided for @uiOpenTheFullAdminProfileSheetForThisUser.
  ///
  /// In en, this message translates to:
  /// **'Open the full admin profile sheet for this user.'**
  String get uiOpenTheFullAdminProfileSheetForThisUser;

  /// No description provided for @uiOpenUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Open unavailable'**
  String get uiOpenUnavailable;

  /// No description provided for @uiOpenYourCompanyWorkspaceHub.
  ///
  /// In en, this message translates to:
  /// **'Open your company workspace hub'**
  String get uiOpenYourCompanyWorkspaceHub;

  /// No description provided for @uiOpenYourInboxAndConfirmYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Open your inbox and confirm your account.'**
  String get uiOpenYourInboxAndConfirmYourAccount;

  /// No description provided for @uiOpenYourInboxAndFollowTheResetLink.
  ///
  /// In en, this message translates to:
  /// **'Open your inbox and follow the reset link.'**
  String get uiOpenYourInboxAndFollowTheResetLink;

  /// No description provided for @uiOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Opportunities'**
  String get uiOpportunities;

  /// No description provided for @uiOpportunitiesNearingTheirDeadlinesAreHighlightedHere.
  ///
  /// In en, this message translates to:
  /// **'Opportunities nearing their deadlines are highlighted here.'**
  String get uiOpportunitiesNearingTheirDeadlinesAreHighlightedHere;

  /// No description provided for @uiOpportunitiesScholarshipsTraining.
  ///
  /// In en, this message translates to:
  /// **'Opportunities, scholarships, training'**
  String get uiOpportunitiesScholarshipsTraining;

  /// No description provided for @uiOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Opportunity'**
  String get uiOpportunity;

  /// No description provided for @uiOpportunityDetails.
  ///
  /// In en, this message translates to:
  /// **'Opportunity details'**
  String get uiOpportunityDetails;

  /// No description provided for @uiOpportunityPostingHelp.
  ///
  /// In en, this message translates to:
  /// **'Opportunity Posting Help'**
  String get uiOpportunityPostingHelp;

  /// No description provided for @uiOpportunityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Opportunity unavailable'**
  String get uiOpportunityUnavailable;

  /// No description provided for @uiOpps.
  ///
  /// In en, this message translates to:
  /// **'Opportunities'**
  String get uiOpps;

  /// No description provided for @uiOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get uiOptional;

  /// No description provided for @uiOptionalExtras.
  ///
  /// In en, this message translates to:
  /// **'Optional Extras'**
  String get uiOptionalExtras;

  /// No description provided for @uiOrUploadYourOwn.
  ///
  /// In en, this message translates to:
  /// **'or upload your own'**
  String get uiOrUploadYourOwn;

  /// No description provided for @uiOrbitAiAiOps.
  ///
  /// In en, this message translates to:
  /// **'Orbit AI â¢ AI Ops'**
  String get uiOrbitAiAiOps;

  /// No description provided for @uiOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get uiOverview;

  /// No description provided for @uiWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get uiWorkspace;

  /// No description provided for @uiPaidOnly.
  ///
  /// In en, this message translates to:
  /// **'Paid only'**
  String get uiPaidOnly;

  /// No description provided for @uiPartnerBackedSupport.
  ///
  /// In en, this message translates to:
  /// **'Partner-backed support'**
  String get uiPartnerBackedSupport;

  /// No description provided for @uiPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get uiPassword;

  /// No description provided for @uiPasswordAdded.
  ///
  /// In en, this message translates to:
  /// **'Password added'**
  String get uiPasswordAdded;

  /// No description provided for @uiPasswordAndAccountProtection.
  ///
  /// In en, this message translates to:
  /// **'Password and account protection.'**
  String get uiPasswordAndAccountProtection;

  /// No description provided for @uiPasswordSetupUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Password setup unavailable'**
  String get uiPasswordSetupUnavailable;

  /// No description provided for @uiPasswordUpdateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Password update unavailable'**
  String get uiPasswordUpdateUnavailable;

  /// No description provided for @uiPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get uiPasswordUpdated;

  /// No description provided for @uiPct.
  ///
  /// In en, this message translates to:
  /// **'{pct}%'**
  String uiPct(Object pct);

  /// No description provided for @uiPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get uiPending;

  /// No description provided for @uiPendingApprovedAndRejectedCountsFromYourLiveApplications.
  ///
  /// In en, this message translates to:
  /// **'Pending, approved, and rejected counts from your live applications.'**
  String get uiPendingApprovedAndRejectedCountsFromYourLiveApplications;

  /// No description provided for @uiPendingApps.
  ///
  /// In en, this message translates to:
  /// **'Pending Apps'**
  String get uiPendingApps;

  /// No description provided for @uiPendingIdeasNeedReview.
  ///
  /// In en, this message translates to:
  /// **'Pending ideas need review'**
  String get uiPendingIdeasNeedReview;

  /// No description provided for @uiPendingOpportunitiesNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'Pending opportunities need attention'**
  String get uiPendingOpportunitiesNeedAttention;

  /// No description provided for @uiPendingProjectIdeas.
  ///
  /// In en, this message translates to:
  /// **'Pending Project Ideas'**
  String get uiPendingProjectIdeas;

  /// No description provided for @uiPendingReviews.
  ///
  /// In en, this message translates to:
  /// **'Pending Reviews'**
  String get uiPendingReviews;

  /// No description provided for @uiPendingValue1InReview.
  ///
  /// In en, this message translates to:
  /// **'{pending} {value1} in review.'**
  String uiPendingValue1InReview(Object value1, Object pending);

  /// No description provided for @uiPendingapplicationsPendingApps.
  ///
  /// In en, this message translates to:
  /// **'{pendingApplications} pending apps'**
  String uiPendingapplicationsPendingApps(Object pendingApplications);

  /// No description provided for @uiPendingideasPendingIdeas.
  ///
  /// In en, this message translates to:
  /// **'{pendingIdeas} pending ideas'**
  String uiPendingideasPendingIdeas(Object pendingIdeas);

  /// No description provided for @uiPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String uiPercent(Object percent);

  /// No description provided for @uiPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get uiPerformance;

  /// No description provided for @uiPersonalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get uiPersonalInformation;

  /// No description provided for @uiPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get uiPhone;

  /// No description provided for @uiPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get uiPhoneNumber;

  /// No description provided for @uiPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get uiPhoto;

  /// No description provided for @uiPhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable'**
  String get uiPhotoUnavailable;

  /// No description provided for @uiPickABuiltInLookOrKeepUsingYourUploaded.
  ///
  /// In en, this message translates to:
  /// **'Pick a built-in look, or keep using your uploaded photo.'**
  String get uiPickABuiltInLookOrKeepUsingYourUploaded;

  /// No description provided for @uiPickTheResumeStyleThatBestFitsTheRoleYou.
  ///
  /// In en, this message translates to:
  /// **'Pick the resume style that best fits the role you want.'**
  String get uiPickTheResumeStyleThatBestFitsTheRoleYou;

  /// No description provided for @uiPixelFoundryEngineering.
  ///
  /// In en, this message translates to:
  /// **'Pixel Foundry â¢ Engineering'**
  String get uiPixelFoundryEngineering;

  /// No description provided for @uiPlatformMissionAndVersionDetails.
  ///
  /// In en, this message translates to:
  /// **'Platform mission and version details'**
  String get uiPlatformMissionAndVersionDetails;

  /// No description provided for @uiPlatformOverview.
  ///
  /// In en, this message translates to:
  /// **'Platform Overview'**
  String get uiPlatformOverview;

  /// No description provided for @uiPlatformPulseModerationLoadAndQuickControlPoints.
  ///
  /// In en, this message translates to:
  /// **'Platform pulse, moderation load, and quick control points.'**
  String get uiPlatformPulseModerationLoadAndQuickControlPoints;

  /// No description provided for @uiPlatformStory.
  ///
  /// In en, this message translates to:
  /// **'Platform Story'**
  String get uiPlatformStory;

  /// No description provided for @uiPleaseCheckYourConnectionAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get uiPleaseCheckYourConnectionAndTryAgain;

  /// No description provided for @uiPolishYourPublicCompanyPresence.
  ///
  /// In en, this message translates to:
  /// **'Polish your public company presence'**
  String get uiPolishYourPublicCompanyPresence;

  /// No description provided for @uiPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get uiPosition;

  /// No description provided for @uiPositioning.
  ///
  /// In en, this message translates to:
  /// **'Positioning'**
  String get uiPositioning;

  /// No description provided for @uiPositioningAccess.
  ///
  /// In en, this message translates to:
  /// **'Positioning & Access'**
  String get uiPositioningAccess;

  /// No description provided for @uiPostAdminIdea.
  ///
  /// In en, this message translates to:
  /// **'Post Admin Idea'**
  String get uiPostAdminIdea;

  /// No description provided for @uiPostOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Post Opportunity'**
  String get uiPostOpportunity;

  /// No description provided for @uiPostOpportunity2F1A.
  ///
  /// In en, this message translates to:
  /// **'Post\nOpportunity'**
  String get uiPostOpportunity2F1A;

  /// No description provided for @uiPostScholarship.
  ///
  /// In en, this message translates to:
  /// **'Post Scholarship'**
  String get uiPostScholarship;

  /// No description provided for @uiPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get uiPosted;

  /// No description provided for @uiPreferencesDisplayAndAppChoices.
  ///
  /// In en, this message translates to:
  /// **'Preferences, display, and app choices.'**
  String get uiPreferencesDisplayAndAppChoices;

  /// No description provided for @uiPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get uiPreview;

  /// No description provided for @uiPreviewExport.
  ///
  /// In en, this message translates to:
  /// **'Preview & Export'**
  String get uiPreviewExport;

  /// No description provided for @uiPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Preview unavailable'**
  String get uiPreviewUnavailable;

  /// No description provided for @uiPrimaryCvPdf.
  ///
  /// In en, this message translates to:
  /// **'Primary CV PDF'**
  String get uiPrimaryCvPdf;

  /// No description provided for @uiPrivacyControls.
  ///
  /// In en, this message translates to:
  /// **'Privacy Controls'**
  String get uiPrivacyControls;

  /// No description provided for @uiPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get uiPrivacyPolicy;

  /// No description provided for @uiProblemSolutionAndImpact.
  ///
  /// In en, this message translates to:
  /// **'Problem, Solution, And Impact'**
  String get uiProblemSolutionAndImpact;

  /// No description provided for @uiProblemSolutionImpact.
  ///
  /// In en, this message translates to:
  /// **'Problem, Solution & Impact'**
  String get uiProblemSolutionImpact;

  /// No description provided for @uiProblemStatement.
  ///
  /// In en, this message translates to:
  /// **'Problem Statement'**
  String get uiProblemStatement;

  /// No description provided for @uiProblemStatement1Ebe.
  ///
  /// In en, this message translates to:
  /// **'Problem statement'**
  String get uiProblemStatement1Ebe;

  /// No description provided for @uiProductDesign.
  ///
  /// In en, this message translates to:
  /// **'Product Design'**
  String get uiProductDesign;

  /// No description provided for @uiProfessionalSummary.
  ///
  /// In en, this message translates to:
  /// **'Professional Summary'**
  String get uiProfessionalSummary;

  /// No description provided for @uiProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get uiProfile;

  /// No description provided for @uiProfileCompletion.
  ///
  /// In en, this message translates to:
  /// **'Profile completion'**
  String get uiProfileCompletion;

  /// No description provided for @uiProfileCvAndApplicationDataAreUsedToPowerOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Profile, CV, and application data are used to power opportunities and recruiter review flows.'**
  String get uiProfileCvAndApplicationDataAreUsedToPowerOpportunities;

  /// No description provided for @uiProfileCvNotificationAndApplicationDataAreUsedOnlyTo.
  ///
  /// In en, this message translates to:
  /// **'Profile, CV, notification, and application data are used only to provide the matching, review, and communication features that power the FutureGate experience.'**
  String get uiProfileCvNotificationAndApplicationDataAreUsedOnlyTo;

  /// No description provided for @uiProfileNext.
  ///
  /// In en, this message translates to:
  /// **'Profile next'**
  String get uiProfileNext;

  /// No description provided for @uiProfileOverview.
  ///
  /// In en, this message translates to:
  /// **'Profile overview'**
  String get uiProfileOverview;

  /// No description provided for @uiProfileSetupUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Profile setup unavailable'**
  String get uiProfileSetupUnavailable;

  /// No description provided for @uiProfileStrength.
  ///
  /// In en, this message translates to:
  /// **'Profile Strength'**
  String get uiProfileStrength;

  /// No description provided for @uiProfileStrength491D.
  ///
  /// In en, this message translates to:
  /// **'Profile strength'**
  String get uiProfileStrength491D;

  /// No description provided for @uiProfileSync.
  ///
  /// In en, this message translates to:
  /// **'Profile Sync'**
  String get uiProfileSync;

  /// No description provided for @uiProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get uiProfileUpdated;

  /// No description provided for @uiProjectIdea.
  ///
  /// In en, this message translates to:
  /// **'Project Idea'**
  String get uiProjectIdea;

  /// No description provided for @uiProjectIdeas.
  ///
  /// In en, this message translates to:
  /// **'Project Ideas'**
  String get uiProjectIdeas;

  /// No description provided for @uiProposedSolution.
  ///
  /// In en, this message translates to:
  /// **'Proposed Solution'**
  String get uiProposedSolution;

  /// No description provided for @uiProviderAndAccess.
  ///
  /// In en, this message translates to:
  /// **'Provider And Access'**
  String get uiProviderAndAccess;

  /// No description provided for @uiProviderAndDeliverySetup.
  ///
  /// In en, this message translates to:
  /// **'Provider And Delivery Setup'**
  String get uiProviderAndDeliverySetup;

  /// No description provided for @uiPublicCollaborationAllowed.
  ///
  /// In en, this message translates to:
  /// **'Public collaboration allowed'**
  String get uiPublicCollaborationAllowed;

  /// No description provided for @uiPublicLinksAreAddedHereAsTheyGoLive.
  ///
  /// In en, this message translates to:
  /// **'Public links are added here as they go live'**
  String get uiPublicLinksAreAddedHereAsTheyGoLive;

  /// No description provided for @uiPublicSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Public Speaking'**
  String get uiPublicSpeaking;

  /// No description provided for @uiPublishOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Publish Opportunities'**
  String get uiPublishOpportunities;

  /// No description provided for @uiPublishTheFirstOpportunityToStartPopulatingTheStudentDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Publish the first opportunity to start populating the student discovery experience.'**
  String get uiPublishTheFirstOpportunityToStartPopulatingTheStudentDiscovery;

  /// No description provided for @uiPublishTheFirstScholarshipToStartShapingTheStudentDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Publish the first scholarship to start shaping the student discovery catalog.'**
  String get uiPublishTheFirstScholarshipToStartShapingTheStudentDiscovery;

  /// No description provided for @uiPublisherName.
  ///
  /// In en, this message translates to:
  /// **'Publisher name'**
  String get uiPublisherName;

  /// No description provided for @uiPullingTogetherYourSavedOpportunitiesScholarshipsTrainingsAndIdeas.
  ///
  /// In en, this message translates to:
  /// **'Pulling together your saved opportunities, scholarships, trainings, and ideas.'**
  String
  get uiPullingTogetherYourSavedOpportunitiesScholarshipsTrainingsAndIdeas;

  /// No description provided for @uiPullingTogetherYourSubmittedOpportunitiesAndTheirLatestStatuses.
  ///
  /// In en, this message translates to:
  /// **'Pulling together your submitted opportunities and their latest statuses.'**
  String get uiPullingTogetherYourSubmittedOpportunitiesAndTheirLatestStatuses;

  /// No description provided for @uiQuickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get uiQuickAccess;

  /// No description provided for @uiQuickAccessToRolesFundingLearningAndIdeasWorthRevisiting.
  ///
  /// In en, this message translates to:
  /// **'Quick access to roles, funding, learning, and ideas worth revisiting.'**
  String get uiQuickAccessToRolesFundingLearningAndIdeasWorthRevisiting;

  /// No description provided for @uiQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get uiQuickActions;

  /// No description provided for @uiQuickCuration.
  ///
  /// In en, this message translates to:
  /// **'Quick Curation'**
  String get uiQuickCuration;

  /// No description provided for @uiQuickFilters.
  ///
  /// In en, this message translates to:
  /// **'Quick filters'**
  String get uiQuickFilters;

  /// No description provided for @uiQuickSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Quick Snapshot'**
  String get uiQuickSnapshot;

  /// No description provided for @uiQuickSupport.
  ///
  /// In en, this message translates to:
  /// **'Quick Support'**
  String get uiQuickSupport;

  /// No description provided for @uiRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get uiRating;

  /// No description provided for @uiReachOutWithContextSoTheTeamCanHelpFaster.
  ///
  /// In en, this message translates to:
  /// **'Reach out with context so the team can help faster.'**
  String get uiReachOutWithContextSoTheTeamCanHelpFaster;

  /// No description provided for @uiReadAll.
  ///
  /// In en, this message translates to:
  /// **'Read all'**
  String get uiReadAll;

  /// No description provided for @uiReadHowPersonalInformationIsHandled.
  ///
  /// In en, this message translates to:
  /// **'Read how personal information is handled'**
  String get uiReadHowPersonalInformationIsHandled;

  /// No description provided for @uiReadThePlatformUsageSummary.
  ///
  /// In en, this message translates to:
  /// **'Read the platform usage summary'**
  String get uiReadThePlatformUsageSummary;

  /// No description provided for @uiReadyToApply.
  ///
  /// In en, this message translates to:
  /// **'Ready to apply'**
  String get uiReadyToApply;

  /// No description provided for @uiRealApplicationsSubmittedOverTheLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Real applications submitted over the last 7 days.'**
  String get uiRealApplicationsSubmittedOverTheLast7Days;

  /// No description provided for @uiRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get uiRecentActivity;

  /// No description provided for @uiRecentApplications.
  ///
  /// In en, this message translates to:
  /// **'Recent Applications'**
  String get uiRecentApplications;

  /// No description provided for @uiRecentContacts.
  ///
  /// In en, this message translates to:
  /// **'Recent contacts'**
  String get uiRecentContacts;

  /// No description provided for @uiRecentOffers.
  ///
  /// In en, this message translates to:
  /// **'Recent Offers'**
  String get uiRecentOffers;

  /// No description provided for @uiRecentOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Recent Opportunities'**
  String get uiRecentOpportunities;

  /// No description provided for @uiRecentPlatformActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Platform Activity'**
  String get uiRecentPlatformActivity;

  /// No description provided for @uiRecentUsers.
  ///
  /// In en, this message translates to:
  /// **'Recent Users'**
  String get uiRecentUsers;

  /// No description provided for @uiReferencesAndLinks.
  ///
  /// In en, this message translates to:
  /// **'References And Links'**
  String get uiReferencesAndLinks;

  /// No description provided for @uiRefreshActivityFeed.
  ///
  /// In en, this message translates to:
  /// **'Refresh activity feed'**
  String get uiRefreshActivityFeed;

  /// No description provided for @uiRefreshApplications.
  ///
  /// In en, this message translates to:
  /// **'Refresh applications'**
  String get uiRefreshApplications;

  /// No description provided for @uiRefreshSavedItems.
  ///
  /// In en, this message translates to:
  /// **'Refresh saved items'**
  String get uiRefreshSavedItems;

  /// No description provided for @uiRefreshYourDetailsSwitchAvatarsOrUploadANewPhoto.
  ///
  /// In en, this message translates to:
  /// **'Refresh your details, switch avatars, or upload a new photo without affecting your existing account logic.'**
  String get uiRefreshYourDetailsSwitchAvatarsOrUploadANewPhoto;

  /// No description provided for @uiRefreshYourStoryContactDetailsAndAssets.
  ///
  /// In en, this message translates to:
  /// **'Refresh your story, contact details, and assets'**
  String get uiRefreshYourStoryContactDetailsAndAssets;

  /// No description provided for @uiRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get uiRegister;

  /// No description provided for @uiRegisterCompany.
  ///
  /// In en, this message translates to:
  /// **'Register Company'**
  String get uiRegisterCompany;

  /// No description provided for @uiRegisterYourOrganizationToPostOpportunitiesAndConnectWithTalent.
  ///
  /// In en, this message translates to:
  /// **'Register your organization to post\nopportunities and connect with talent.'**
  String get uiRegisterYourOrganizationToPostOpportunitiesAndConnectWithTalent;

  /// No description provided for @uiRegistrationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Registration unavailable'**
  String get uiRegistrationUnavailable;

  /// No description provided for @uiReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get uiReject;

  /// No description provided for @uiRejectCompany.
  ///
  /// In en, this message translates to:
  /// **'Reject Company'**
  String get uiRejectCompany;

  /// No description provided for @uiRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get uiRejected;

  /// No description provided for @uiRemoteSessionManagementIsNotAvailableInThisBuildYet.
  ///
  /// In en, this message translates to:
  /// **'Remote session management is not available in this build yet. Your active session on this device remains protected by Firebase authentication.'**
  String get uiRemoteSessionManagementIsNotAvailableInThisBuildYet;

  /// No description provided for @uiRemoveLogo.
  ///
  /// In en, this message translates to:
  /// **'Remove Logo'**
  String get uiRemoveLogo;

  /// No description provided for @uiRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get uiRemovePhoto;

  /// No description provided for @uiRemoveUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Remove unavailable'**
  String get uiRemoveUnavailable;

  /// No description provided for @uiReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get uiReplace;

  /// No description provided for @uiReplyNow.
  ///
  /// In en, this message translates to:
  /// **'Reply Now'**
  String get uiReplyNow;

  /// No description provided for @uiReportAProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a Problem'**
  String get uiReportAProblem;

  /// No description provided for @uiRequiredForCompanyAccountCreationAcceptedFormatsPdfJpgPng.
  ///
  /// In en, this message translates to:
  /// **'Required for company account creation. Accepted formats: PDF, JPG, PNG. Maximum size: 10 MB.'**
  String get uiRequiredForCompanyAccountCreationAcceptedFormatsPdfJpgPng;

  /// No description provided for @uiRequirementsAndEligibility.
  ///
  /// In en, this message translates to:
  /// **'Requirements And Eligibility'**
  String get uiRequirementsAndEligibility;

  /// No description provided for @uiResearch.
  ///
  /// In en, this message translates to:
  /// **'Research'**
  String get uiResearch;

  /// No description provided for @uiResearchDetails.
  ///
  /// In en, this message translates to:
  /// **'Research details'**
  String get uiResearchDetails;

  /// No description provided for @uiResearchDomain.
  ///
  /// In en, this message translates to:
  /// **'Research Domain'**
  String get uiResearchDomain;

  /// No description provided for @uiResearchTopic.
  ///
  /// In en, this message translates to:
  /// **'Research Topic'**
  String get uiResearchTopic;

  /// No description provided for @uiResendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get uiResendEmail;

  /// No description provided for @uiResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get uiResetPassword;

  /// No description provided for @uiResetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reset unavailable'**
  String get uiResetUnavailable;

  /// No description provided for @uiResourceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Resource deleted'**
  String get uiResourceDeleted;

  /// No description provided for @uiResourceDetails.
  ///
  /// In en, this message translates to:
  /// **'Resource Details'**
  String get uiResourceDetails;

  /// No description provided for @uiResourceLibrary.
  ///
  /// In en, this message translates to:
  /// **'Resource Library'**
  String get uiResourceLibrary;

  /// No description provided for @uiResourceStudioForAdminCuration.
  ///
  /// In en, this message translates to:
  /// **'Resource Studio for Admin Curation'**
  String get uiResourceStudioForAdminCuration;

  /// No description provided for @uiResources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get uiResources;

  /// No description provided for @uiResourcesNeeded.
  ///
  /// In en, this message translates to:
  /// **'Resources needed'**
  String get uiResourcesNeeded;

  /// No description provided for @uiResourcesNeeds.
  ///
  /// In en, this message translates to:
  /// **'Resources / Needs'**
  String get uiResourcesNeeds;

  /// No description provided for @uiResourcesOrNeeds.
  ///
  /// In en, this message translates to:
  /// **'Resources or needs'**
  String get uiResourcesOrNeeds;

  /// No description provided for @uiResumePdf.
  ///
  /// In en, this message translates to:
  /// **'Resume.pdf'**
  String get uiResumePdf;

  /// No description provided for @uiRetrySync.
  ///
  /// In en, this message translates to:
  /// **'Retry sync'**
  String get uiRetrySync;

  /// No description provided for @uiReviewApplications.
  ///
  /// In en, this message translates to:
  /// **'Review\nApplications'**
  String get uiReviewApplications;

  /// No description provided for @uiReviewCompanies.
  ///
  /// In en, this message translates to:
  /// **'Review Companies'**
  String get uiReviewCompanies;

  /// No description provided for @uiReviewCompaniesContentAndPlatformActivityFromOneFocusedWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Review companies, content, and platform activity from one focused workspace.'**
  String get uiReviewCompaniesContentAndPlatformActivityFromOneFocusedWorkspace;

  /// No description provided for @uiReviewContactInfoAccountStatusAndRoleSpecificDetailsIn.
  ///
  /// In en, this message translates to:
  /// **'Review contact info, account status, and role-specific details in one clean profile view.'**
  String get uiReviewContactInfoAccountStatusAndRoleSpecificDetailsIn;

  /// No description provided for @uiReviewContent.
  ///
  /// In en, this message translates to:
  /// **'Review Content'**
  String get uiReviewContent;

  /// No description provided for @uiReviewExpectedPlatformUsage.
  ///
  /// In en, this message translates to:
  /// **'Review expected platform usage'**
  String get uiReviewExpectedPlatformUsage;

  /// No description provided for @uiReviewFundingQueue.
  ///
  /// In en, this message translates to:
  /// **'Review funding queue'**
  String get uiReviewFundingQueue;

  /// No description provided for @uiReviewIdentityStatusAndSubmittedInformationInOnePlace.
  ///
  /// In en, this message translates to:
  /// **'Review identity, status, and submitted information in one place.'**
  String get uiReviewIdentityStatusAndSubmittedInformationInOnePlace;

  /// No description provided for @uiReviewOfferSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Review offer submissions'**
  String get uiReviewOfferSubmissions;

  /// No description provided for @uiReviewSubmissionsMonitorQueuesAndMoveBetweenContentTypesWithout.
  ///
  /// In en, this message translates to:
  /// **'Review submissions, monitor queues, and move between content types without losing context.'**
  String get uiReviewSubmissionsMonitorQueuesAndMoveBetweenContentTypesWithout;

  /// No description provided for @uiReviewTheFinalLayoutBeforeYouExportOrShareIt.
  ///
  /// In en, this message translates to:
  /// **'Review the final layout before you export or share it.'**
  String get uiReviewTheFinalLayoutBeforeYouExportOrShareIt;

  /// No description provided for @uiReviewTheLatestModerationUpdatesPublishingChangesAndSubmissionsFrom.
  ///
  /// In en, this message translates to:
  /// **'Review the latest moderation updates, publishing changes, and submissions from one clean queue.'**
  String
  get uiReviewTheLatestModerationUpdatesPublishingChangesAndSubmissionsFrom;

  /// No description provided for @uiReviewTheUploadedCvAndTheBuiltCvExportWithout.
  ///
  /// In en, this message translates to:
  /// **'Review the uploaded CV and the built CV export without leaving the user profile.'**
  String get uiReviewTheUploadedCvAndTheBuiltCvExportWithout;

  /// No description provided for @uiReviewWhereYourAccountIsBeingUsed.
  ///
  /// In en, this message translates to:
  /// **'Review where your account is being used'**
  String get uiReviewWhereYourAccountIsBeingUsed;

  /// No description provided for @uiReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get uiReviewed;

  /// No description provided for @uiRevisitSavedPicksBeforeTheStrongestDeadlinesSlipBy.
  ///
  /// In en, this message translates to:
  /// **'Revisit saved picks before the strongest deadlines slip by.'**
  String get uiRevisitSavedPicksBeforeTheStrongestDeadlinesSlipBy;

  /// No description provided for @uiRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get uiRole;

  /// No description provided for @uiRoleDetails.
  ///
  /// In en, this message translates to:
  /// **'Role details'**
  String get uiRoleDetails;

  /// No description provided for @uiRoleOverview.
  ///
  /// In en, this message translates to:
  /// **'Role Overview'**
  String get uiRoleOverview;

  /// No description provided for @uiRoleSetup.
  ///
  /// In en, this message translates to:
  /// **'Role Setup'**
  String get uiRoleSetup;

  /// No description provided for @uiRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get uiRoles;

  /// No description provided for @uiSaveCv.
  ///
  /// In en, this message translates to:
  /// **'Save CV'**
  String get uiSaveCv;

  /// No description provided for @uiSaveUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Save unavailable'**
  String get uiSaveUnavailable;

  /// No description provided for @uiSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get uiSaved;

  /// No description provided for @uiSavedCollection.
  ///
  /// In en, this message translates to:
  /// **'Saved collection'**
  String get uiSavedCollection;

  /// No description provided for @uiSavedIdeas.
  ///
  /// In en, this message translates to:
  /// **'Saved Ideas'**
  String get uiSavedIdeas;

  /// No description provided for @uiSavedItems.
  ///
  /// In en, this message translates to:
  /// **'Saved Items'**
  String get uiSavedItems;

  /// No description provided for @uiSavedItems1D9C.
  ///
  /// In en, this message translates to:
  /// **'Saved items'**
  String get uiSavedItems1D9C;

  /// No description provided for @uiSavedResources.
  ///
  /// In en, this message translates to:
  /// **'Saved resources'**
  String get uiSavedResources;

  /// No description provided for @uiSavedScholarships.
  ///
  /// In en, this message translates to:
  /// **'Saved Scholarships'**
  String get uiSavedScholarships;

  /// No description provided for @uiSavedShortlist.
  ///
  /// In en, this message translates to:
  /// **'Saved shortlist'**
  String get uiSavedShortlist;

  /// No description provided for @uiSavedTraining.
  ///
  /// In en, this message translates to:
  /// **'Saved training'**
  String get uiSavedTraining;

  /// No description provided for @uiSayHelloToOthername.
  ///
  /// In en, this message translates to:
  /// **'Say hello to {otherName}'**
  String uiSayHelloToOthername(Object otherName);

  /// No description provided for @uiSearchAndCurateYoutubeLessonsInOneContinuousFlowInstead.
  ///
  /// In en, this message translates to:
  /// **'Search and curate YouTube lessons in one continuous flow instead of working inside separate fixed windows.'**
  String get uiSearchAndCurateYoutubeLessonsInOneContinuousFlowInstead;

  /// No description provided for @uiSearchAndImportBooksInOneContinuousFlowInsteadOf.
  ///
  /// In en, this message translates to:
  /// **'Search and import books in one continuous flow instead of working inside separate fixed windows.'**
  String get uiSearchAndImportBooksInOneContinuousFlowInsteadOf;

  /// No description provided for @uiSearchBooksForExampleAlgorithms.
  ///
  /// In en, this message translates to:
  /// **'Search books, for example: algorithms'**
  String get uiSearchBooksForExampleAlgorithms;

  /// No description provided for @uiSearchByCandidateOpportunityLocationOrType.
  ///
  /// In en, this message translates to:
  /// **'Search by candidate, opportunity, location, or type...'**
  String get uiSearchByCandidateOpportunityLocationOrType;

  /// No description provided for @uiSearchByNameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email...'**
  String get uiSearchByNameOrEmail;

  /// No description provided for @uiSearchByRoleCompanyLocationOrStatus.
  ///
  /// In en, this message translates to:
  /// **'Search by role, company, location, or status'**
  String get uiSearchByRoleCompanyLocationOrStatus;

  /// No description provided for @uiSearchByTitleCompanyProviderOrCategory.
  ///
  /// In en, this message translates to:
  /// **'Search by title, company, provider, or category'**
  String get uiSearchByTitleCompanyProviderOrCategory;

  /// No description provided for @uiSearchByTopicDomainLevelAndLanguageBeforePublishingA.
  ///
  /// In en, this message translates to:
  /// **'Search by topic, domain, level, and language before publishing a curated resource into the library.'**
  String get uiSearchByTopicDomainLevelAndLanguageBeforePublishingA;

  /// No description provided for @uiSearchByTypeTitleActorOrStatus.
  ///
  /// In en, this message translates to:
  /// **'Search by type, title, actor, or status...'**
  String get uiSearchByTypeTitleActorOrStatus;

  /// No description provided for @uiSearchCommonTopicsContactSupportOrReportSomethingThatNeeds.
  ///
  /// In en, this message translates to:
  /// **'Search common topics, contact support, or report something that needs attention.'**
  String get uiSearchCommonTopicsContactSupportOrReportSomethingThatNeeds;

  /// No description provided for @uiSearchConversations.
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get uiSearchConversations;

  /// No description provided for @uiSearchEducationalVideosReviewMetadataAndPublishCuratedTrainingContent.
  ///
  /// In en, this message translates to:
  /// **'Search educational videos, review metadata, and publish curated training content from YouTube into the admin library.'**
  String
  get uiSearchEducationalVideosReviewMetadataAndPublishCuratedTrainingContent;

  /// No description provided for @uiSearchEducationalVideosReviewTheMetadataAndPublishCuratedContent.
  ///
  /// In en, this message translates to:
  /// **'Search educational videos, review the metadata, and publish curated content into the admin library.'**
  String get uiSearchEducationalVideosReviewTheMetadataAndPublishCuratedContent;

  /// No description provided for @uiSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get uiSearchFailed;

  /// No description provided for @uiSearchForCourses.
  ///
  /// In en, this message translates to:
  /// **'Search for courses...'**
  String get uiSearchForCourses;

  /// No description provided for @uiSearchHelpTopics.
  ///
  /// In en, this message translates to:
  /// **'Search help topics'**
  String get uiSearchHelpTopics;

  /// No description provided for @uiSearchIdeas.
  ///
  /// In en, this message translates to:
  /// **'Search Ideas...'**
  String get uiSearchIdeas;

  /// No description provided for @uiSearchInternships.
  ///
  /// In en, this message translates to:
  /// **'Search internships...'**
  String get uiSearchInternships;

  /// No description provided for @uiSearchJobsInternshipsOrSponsoredRoles.
  ///
  /// In en, this message translates to:
  /// **'Search jobs, internships or sponsored roles'**
  String get uiSearchJobsInternshipsOrSponsoredRoles;

  /// No description provided for @uiSearchProgramsPartners.
  ///
  /// In en, this message translates to:
  /// **'Search programs, partners...'**
  String get uiSearchProgramsPartners;

  /// No description provided for @uiSearchQuicklyFilterByRoleOrLevelAndReviewAccount.
  ///
  /// In en, this message translates to:
  /// **'Search quickly, filter by role or level, and review account status without jumping around the admin area.'**
  String get uiSearchQuicklyFilterByRoleOrLevelAndReviewAccount;

  /// No description provided for @uiSearchRequired.
  ///
  /// In en, this message translates to:
  /// **'Search required'**
  String get uiSearchRequired;

  /// No description provided for @uiSearchRolesCompanies.
  ///
  /// In en, this message translates to:
  /// **'Search roles, companies...'**
  String get uiSearchRolesCompanies;

  /// No description provided for @uiSearchSearchquery.
  ///
  /// In en, this message translates to:
  /// **'Search: {searchQuery}'**
  String uiSearchSearchquery(Object searchQuery);

  /// No description provided for @uiSearchTitleLocationOrKeyword.
  ///
  /// In en, this message translates to:
  /// **'Search title, location, or keyword'**
  String get uiSearchTitleLocationOrKeyword;

  /// No description provided for @uiSearchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Search unavailable'**
  String get uiSearchUnavailable;

  /// No description provided for @uiSearchUniversityOrCountry.
  ///
  /// In en, this message translates to:
  /// **'Search university or country...'**
  String get uiSearchUniversityOrCountry;

  /// No description provided for @uiSearchUsersReviewProfilesAndManageAccountStatus.
  ///
  /// In en, this message translates to:
  /// **'Search users, review profiles, and manage account status.'**
  String get uiSearchUsersReviewProfilesAndManageAccountStatus;

  /// No description provided for @uiSearchVideosForExampleAlgorithms.
  ///
  /// In en, this message translates to:
  /// **'Search videos, for example: algorithms'**
  String get uiSearchVideosForExampleAlgorithms;

  /// No description provided for @uiSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get uiSearch;

  /// No description provided for @uiSector.
  ///
  /// In en, this message translates to:
  /// **'Sector'**
  String get uiSector;

  /// No description provided for @uiSecureYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Secure your account'**
  String get uiSecureYourAccount;

  /// No description provided for @uiSecurityAnalyst.
  ///
  /// In en, this message translates to:
  /// **'Security Analyst'**
  String get uiSecurityAnalyst;

  /// No description provided for @uiSecurityPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Security & Privacy'**
  String get uiSecurityPrivacy;

  /// No description provided for @uiSeeHowDataSupportsTheExperience.
  ///
  /// In en, this message translates to:
  /// **'See how data supports the experience'**
  String get uiSeeHowDataSupportsTheExperience;

  /// No description provided for @uiSeeHowTheStudentPopulationIsDistributedByLevelBefore.
  ///
  /// In en, this message translates to:
  /// **'See how the student population is distributed by level before diving into the charts.'**
  String get uiSeeHowTheStudentPopulationIsDistributedByLevelBefore;

  /// No description provided for @uiSelectYourAcademicLevel.
  ///
  /// In en, this message translates to:
  /// **'Select your academic level.'**
  String get uiSelectYourAcademicLevel;

  /// No description provided for @uiSendAgain.
  ///
  /// In en, this message translates to:
  /// **'Send Again'**
  String get uiSendAgain;

  /// No description provided for @uiSendLink.
  ///
  /// In en, this message translates to:
  /// **'Send Link'**
  String get uiSendLink;

  /// No description provided for @uiSendYourFirstMessageToStartTheConversation.
  ///
  /// In en, this message translates to:
  /// **'Send your first message to start the conversation.'**
  String get uiSendYourFirstMessageToStartTheConversation;

  /// No description provided for @uiSeniorProductDesigner.
  ///
  /// In en, this message translates to:
  /// **'Senior Product Designer'**
  String get uiSeniorProductDesigner;

  /// No description provided for @uiSentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to'**
  String get uiSentTo;

  /// No description provided for @uiSessionsDevices.
  ///
  /// In en, this message translates to:
  /// **'Sessions & devices'**
  String get uiSessionsDevices;

  /// No description provided for @uiSetTheCoreHeadlineCategoryAndStageSoTheIdea.
  ///
  /// In en, this message translates to:
  /// **'Set the core headline, category, and stage so the idea reads clearly from the start.'**
  String get uiSetTheCoreHeadlineCategoryAndStageSoTheIdea;

  /// No description provided for @uiShapeTheFirstImpressionStudentsGetFromYourCompany.
  ///
  /// In en, this message translates to:
  /// **'Shape the first impression students get from your company.'**
  String get uiShapeTheFirstImpressionStudentsGetFromYourCompany;

  /// No description provided for @uiShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get uiShare;

  /// No description provided for @uiShareIdea.
  ///
  /// In en, this message translates to:
  /// **'Share idea'**
  String get uiShareIdea;

  /// No description provided for @uiShareOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Share opportunity'**
  String get uiShareOpportunity;

  /// No description provided for @uiSharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get uiSharePdf;

  /// No description provided for @uiShareScreenshotsStepsOrAccountIssues.
  ///
  /// In en, this message translates to:
  /// **'Share screenshots, steps, or account issues'**
  String get uiShareScreenshotsStepsOrAccountIssues;

  /// No description provided for @uiShieldOpsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Shield Ops â¢ Security'**
  String get uiShieldOpsSecurity;

  /// No description provided for @uiShortDescription.
  ///
  /// In en, this message translates to:
  /// **'Short description'**
  String get uiShortDescription;

  /// No description provided for @uiShortIntro.
  ///
  /// In en, this message translates to:
  /// **'Short intro'**
  String get uiShortIntro;

  /// No description provided for @uiShortTagline.
  ///
  /// In en, this message translates to:
  /// **'Short Tagline'**
  String get uiShortTagline;

  /// No description provided for @uiShowArchived.
  ///
  /// In en, this message translates to:
  /// **'Show Archived'**
  String get uiShowArchived;

  /// No description provided for @uiShowInDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Show in discovery'**
  String get uiShowInDiscovery;

  /// No description provided for @uiShowInbox.
  ///
  /// In en, this message translates to:
  /// **'Show Inbox'**
  String get uiShowInbox;

  /// No description provided for @uiShowTheRolesSkillsAndResourcesThatWillHelpThis.
  ///
  /// In en, this message translates to:
  /// **'Show the roles, skills, and resources that will help this idea move forward.'**
  String get uiShowTheRolesSkillsAndResourcesThatWillHelpThis;

  /// No description provided for @uiShowThisIdeaToUsers.
  ///
  /// In en, this message translates to:
  /// **'Show this idea to users'**
  String get uiShowThisIdeaToUsers;

  /// No description provided for @uiShowingResultscountOfTotalapplicationsApplications.
  ///
  /// In en, this message translates to:
  /// **'Showing {resultsCount} of {totalApplications} applications'**
  String uiShowingResultscountOfTotalapplicationsApplications(
    Object resultsCount,
    Object totalApplications,
  );

  /// No description provided for @uiShownOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total}'**
  String uiShownOfTotal(Object shown, Object total);

  /// No description provided for @uiSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get uiSignIn;

  /// No description provided for @uiSignInToSeeYourMessages.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your messages'**
  String get uiSignInToSeeYourMessages;

  /// No description provided for @uiSignInToViewYourConversationsAndRecentUpdates.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your conversations and recent updates.'**
  String get uiSignInToViewYourConversationsAndRecentUpdates;

  /// No description provided for @uiSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get uiSignOut;

  /// No description provided for @uiSignOutOfAdmin.
  ///
  /// In en, this message translates to:
  /// **'Sign out of admin?'**
  String get uiSignOutOfAdmin;

  /// No description provided for @uiSignOutOfCompany.
  ///
  /// In en, this message translates to:
  /// **'Sign out of company?'**
  String get uiSignOutOfCompany;

  /// No description provided for @uiSignOutOfFuturegate.
  ///
  /// In en, this message translates to:
  /// **'Sign out of FutureGate?'**
  String get uiSignOutOfFuturegate;

  /// No description provided for @uiSignOutOfStudent.
  ///
  /// In en, this message translates to:
  /// **'Sign out of student?'**
  String get uiSignOutOfStudent;

  /// No description provided for @uiSignOutOfTheCompanyWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Sign out of the company workspace'**
  String get uiSignOutOfTheCompanyWorkspace;

  /// No description provided for @uiSignalGrowthMarketing.
  ///
  /// In en, this message translates to:
  /// **'Signal Growth â¢ Marketing'**
  String get uiSignalGrowthMarketing;

  /// No description provided for @uiSketchroomIllustration.
  ///
  /// In en, this message translates to:
  /// **'Sketchroom â¢ Illustration'**
  String get uiSketchroomIllustration;

  /// No description provided for @uiSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get uiSkills;

  /// No description provided for @uiSkillsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Skills needed'**
  String get uiSkillsNeeded;

  /// No description provided for @uiSkillsNeeded7988.
  ///
  /// In en, this message translates to:
  /// **'Skills Needed'**
  String get uiSkillsNeeded7988;

  /// No description provided for @uiSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get uiSkip;

  /// No description provided for @uiSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Snapshot'**
  String get uiSnapshot;

  /// No description provided for @uiSocialMediaManager.
  ///
  /// In en, this message translates to:
  /// **'Social Media Manager'**
  String get uiSocialMediaManager;

  /// No description provided for @uiSolution.
  ///
  /// In en, this message translates to:
  /// **'Solution'**
  String get uiSolution;

  /// No description provided for @uiSomeSavedIdeasCouldNotLoadRightNow.
  ///
  /// In en, this message translates to:
  /// **'Some saved ideas could not load right now.'**
  String get uiSomeSavedIdeasCouldNotLoadRightNow;

  /// No description provided for @uiSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get uiSource;

  /// No description provided for @uiSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get uiSources;

  /// No description provided for @uiStackHarborPlatform.
  ///
  /// In en, this message translates to:
  /// **'Stack Harbor â¢ Platform'**
  String get uiStackHarborPlatform;

  /// No description provided for @uiStage.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get uiStage;

  /// No description provided for @uiStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get uiStart;

  /// No description provided for @uiStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get uiStartDate;

  /// No description provided for @uiStartNewChat.
  ///
  /// In en, this message translates to:
  /// **'Start New Chat'**
  String get uiStartNewChat;

  /// No description provided for @uiStartWithAGoogleBooksSearch.
  ///
  /// In en, this message translates to:
  /// **'Start with a Google Books search'**
  String get uiStartWithAGoogleBooksSearch;

  /// No description provided for @uiStartWithAYoutubeSearch.
  ///
  /// In en, this message translates to:
  /// **'Start with a YouTube search'**
  String get uiStartWithAYoutubeSearch;

  /// No description provided for @uiStartYourStudentProfile.
  ///
  /// In en, this message translates to:
  /// **'Start your student profile.'**
  String get uiStartYourStudentProfile;

  /// No description provided for @uiStartup.
  ///
  /// In en, this message translates to:
  /// **'Startup'**
  String get uiStartup;

  /// No description provided for @uiStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get uiStatus;

  /// No description provided for @uiStayCloseToConversationsFollowUpsAndCollaboration.
  ///
  /// In en, this message translates to:
  /// **'Stay close to conversations, follow-ups, and collaboration.'**
  String get uiStayCloseToConversationsFollowUpsAndCollaboration;

  /// No description provided for @uiStep1Of2.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2'**
  String get uiStep1Of2;

  /// No description provided for @uiStep2Of2.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 2'**
  String get uiStep2Of2;

  /// No description provided for @uiStoryStillMissing.
  ///
  /// In en, this message translates to:
  /// **'Story still missing'**
  String get uiStoryStillMissing;

  /// No description provided for @uiStrategicDashboard.
  ///
  /// In en, this message translates to:
  /// **'STRATEGIC DASHBOARD'**
  String get uiStrategicDashboard;

  /// No description provided for @uiStrategicThinking.
  ///
  /// In en, this message translates to:
  /// **'Strategic Thinking'**
  String get uiStrategicThinking;

  /// No description provided for @uiStudentApplicationsAreAddedHereAsTheyComeIn.
  ///
  /// In en, this message translates to:
  /// **'Student applications are added here as they come in.'**
  String get uiStudentApplicationsAreAddedHereAsTheyComeIn;

  /// No description provided for @uiStudentCv.
  ///
  /// In en, this message translates to:
  /// **'Student CV'**
  String get uiStudentCv;

  /// No description provided for @uiStudentSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Student snapshot'**
  String get uiStudentSnapshot;

  /// No description provided for @uiStudentSpace.
  ///
  /// In en, this message translates to:
  /// **'STUDENT SPACE'**
  String get uiStudentSpace;

  /// No description provided for @uiStudentToolkit.
  ///
  /// In en, this message translates to:
  /// **'Student toolkit'**
  String get uiStudentToolkit;

  /// No description provided for @uiStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get uiStudents;

  /// No description provided for @uiStudentsByLevel.
  ///
  /// In en, this message translates to:
  /// **'Students by Level'**
  String get uiStudentsByLevel;

  /// No description provided for @uiStudio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get uiStudio;

  /// No description provided for @uiSubmittedByValue1.
  ///
  /// In en, this message translates to:
  /// **'Submitted by: {value1}'**
  String uiSubmittedByValue1(Object value1);

  /// No description provided for @uiSummer.
  ///
  /// In en, this message translates to:
  /// **'Summer'**
  String get uiSummer;

  /// No description provided for @uiSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get uiSupervisor;

  /// No description provided for @uiSupportFaqsAndContactOptions.
  ///
  /// In en, this message translates to:
  /// **'Support, FAQs, and contact options'**
  String get uiSupportFaqsAndContactOptions;

  /// No description provided for @uiSupportType.
  ///
  /// In en, this message translates to:
  /// **'Support Type'**
  String get uiSupportType;

  /// No description provided for @uiTagline.
  ///
  /// In en, this message translates to:
  /// **'Tagline'**
  String get uiTagline;

  /// No description provided for @uiTapCardForDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap card for details'**
  String get uiTapCardForDetails;

  /// No description provided for @uiTargetAudience.
  ///
  /// In en, this message translates to:
  /// **'Target audience'**
  String get uiTargetAudience;

  /// No description provided for @uiTargetAudience5Cc6.
  ///
  /// In en, this message translates to:
  /// **'Target Audience'**
  String get uiTargetAudience5Cc6;

  /// No description provided for @uiTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get uiTeam;

  /// No description provided for @uiTeamAndSkillSignals.
  ///
  /// In en, this message translates to:
  /// **'Team And Skill Signals'**
  String get uiTeamAndSkillSignals;

  /// No description provided for @uiTeamNeeded.
  ///
  /// In en, this message translates to:
  /// **'Team Needed'**
  String get uiTeamNeeded;

  /// No description provided for @uiTeamNeeded3437.
  ///
  /// In en, this message translates to:
  /// **'Team needed'**
  String get uiTeamNeeded3437;

  /// No description provided for @uiTeamRolesNeeded.
  ///
  /// In en, this message translates to:
  /// **'Team roles needed'**
  String get uiTeamRolesNeeded;

  /// No description provided for @uiTeamSkillSignals.
  ///
  /// In en, this message translates to:
  /// **'Team & Skill Signals'**
  String get uiTeamSkillSignals;

  /// No description provided for @uiTech.
  ///
  /// In en, this message translates to:
  /// **'Tech'**
  String get uiTech;

  /// No description provided for @uiTechnovaGlobalInc.
  ///
  /// In en, this message translates to:
  /// **'TechNova Global Inc.'**
  String get uiTechnovaGlobalInc;

  /// No description provided for @uiTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get uiTemplate;

  /// No description provided for @uiTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get uiTerms;

  /// No description provided for @uiTermsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get uiTermsOfUse;

  /// No description provided for @uiTheAppBringsTogetherProfilesCvToolsOpportunitiesScholarshipsProject.
  ///
  /// In en, this message translates to:
  /// **'The app brings together profiles, CV tools, opportunities, scholarships, project ideas, and communication so students can move from discovery to action in one place.'**
  String
  get uiTheAppBringsTogetherProfilesCvToolsOpportunitiesScholarshipsProject;

  /// No description provided for @uiTheCompanyWillContactYouByEmailSoon.
  ///
  /// In en, this message translates to:
  /// **'The company will contact you by email soon.'**
  String get uiTheCompanyWillContactYouByEmailSoon;

  /// No description provided for @uiTheEssentialsRecruitersAndProgramsOftenScanFirst.
  ///
  /// In en, this message translates to:
  /// **'The essentials recruiters and programs often scan first.'**
  String get uiTheEssentialsRecruitersAndProgramsOftenScanFirst;

  /// No description provided for @uiTheEssentialsStudentsAndApplicantsUsuallyLookForFirst.
  ///
  /// In en, this message translates to:
  /// **'The essentials students and applicants usually look for first.'**
  String get uiTheEssentialsStudentsAndApplicantsUsuallyLookForFirst;

  /// No description provided for @uiTheHighLevelUserAndAccountPictureAdminsUsuallyNeed.
  ///
  /// In en, this message translates to:
  /// **'The high-level user and account picture admins usually need first.'**
  String get uiTheHighLevelUserAndAccountPictureAdminsUsuallyNeed;

  /// No description provided for @uiTheLatestitemslimitNewestRolesInternshipsAndSponsoredTracks.
  ///
  /// In en, this message translates to:
  /// **'The {latestItemsLimit} newest roles, internships, and sponsored tracks'**
  String uiTheLatestitemslimitNewestRolesInternshipsAndSponsoredTracks(
    Object latestItemsLimit,
  );

  /// No description provided for @uiTheProfileAlreadyLooksPolishedAQuickRefreshFromTime.
  ///
  /// In en, this message translates to:
  /// **'The profile already looks polished. A quick refresh from time to time is enough.'**
  String get uiTheProfileAlreadyLooksPolishedAQuickRefreshFromTime;

  /// No description provided for @uiTheResetLinkIsOnItsWay.
  ///
  /// In en, this message translates to:
  /// **'The reset link is on its way.'**
  String get uiTheResetLinkIsOnItsWay;

  /// No description provided for @uiTheRoleThisCandidateAppliedFor.
  ///
  /// In en, this message translates to:
  /// **'The role this candidate applied for.'**
  String get uiTheRoleThisCandidateAppliedFor;

  /// No description provided for @uiTheUploadedFileIsNotAValidPdf.
  ///
  /// In en, this message translates to:
  /// **'The uploaded file is not a valid PDF.'**
  String get uiTheUploadedFileIsNotAValidPdf;

  /// No description provided for @uiThereAreNoSubmittedApplicationsForThisOpportunityRightNow.
  ///
  /// In en, this message translates to:
  /// **'There are no submitted applications for this opportunity right now.'**
  String get uiThereAreNoSubmittedApplicationsForThisOpportunityRightNow;

  /// No description provided for @uiTheseAreTheMainQualificationsOrExpectationsShownToApplicants.
  ///
  /// In en, this message translates to:
  /// **'These are the main qualifications or expectations shown to applicants.'**
  String get uiTheseAreTheMainQualificationsOrExpectationsShownToApplicants;

  /// No description provided for @uiTheseDetailsHelpYouEvaluateHowTheOpportunityIsPositioned.
  ///
  /// In en, this message translates to:
  /// **'These details help you evaluate how the opportunity is positioned for applicants.'**
  String get uiTheseDetailsHelpYouEvaluateHowTheOpportunityIsPositioned;

  /// No description provided for @uiTheseDetailsHelpYouReviewWhereTheScholarshipFitsAnd.
  ///
  /// In en, this message translates to:
  /// **'These details help you review where the scholarship fits and how students will reach it.'**
  String get uiTheseDetailsHelpYouReviewWhereTheScholarshipFitsAnd;

  /// No description provided for @uiTheseFieldsHelpYouJudgeWhereTheIdeaFitsAnd.
  ///
  /// In en, this message translates to:
  /// **'These fields help you judge where the idea fits and how ready it is for review.'**
  String get uiTheseFieldsHelpYouJudgeWhereTheIdeaFitsAnd;

  /// No description provided for @uiTheseFieldsShapeTheFiltersBadgesAndCollaborationFramingUsed.
  ///
  /// In en, this message translates to:
  /// **'These fields shape the filters, badges, and collaboration framing used throughout the app.'**
  String get uiTheseFieldsShapeTheFiltersBadgesAndCollaborationFramingUsed;

  /// No description provided for @uiTheseRatiosHelpAdminsSeeWhetherUsersAreEngagingDeeply.
  ///
  /// In en, this message translates to:
  /// **'These ratios help admins see whether users are engaging deeply or only browsing.'**
  String get uiTheseRatiosHelpAdminsSeeWhetherUsersAreEngagingDeeply;

  /// No description provided for @uiThisGivesTheAdminViewOfWhatMakesTheRole.
  ///
  /// In en, this message translates to:
  /// **'This gives the admin view of what makes the role attractive.'**
  String get uiThisGivesTheAdminViewOfWhatMakesTheRole;

  /// No description provided for @uiThisIdeaIsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This idea is no longer available.'**
  String get uiThisIdeaIsNoLongerAvailable;

  /// No description provided for @uiThisMessageWasDeleted.
  ///
  /// In en, this message translates to:
  /// **'This message was deleted'**
  String get uiThisMessageWasDeleted;

  /// No description provided for @uiThisSectionHelpsYouReviewHowTheTrainingIsPackaged.
  ///
  /// In en, this message translates to:
  /// **'This section helps you review how the training is packaged and presented to users.'**
  String get uiThisSectionHelpsYouReviewHowTheTrainingIsPackaged;

  /// No description provided for @uiThisSectionShowsWhatTheIdeaIsSolvingHowIt.
  ///
  /// In en, this message translates to:
  /// **'This section shows what the idea is solving, how it works, and the value it aims to create.'**
  String get uiThisSectionShowsWhatTheIdeaIsSolvingHowIt;

  /// No description provided for @uiThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get uiThisWeek;

  /// No description provided for @uiThisWorkspaceIsDedicatedToGoogleBooksImportsSoBook.
  ///
  /// In en, this message translates to:
  /// **'This workspace is dedicated to Google Books imports, so book curation stays focused.'**
  String get uiThisWorkspaceIsDedicatedToGoogleBooksImportsSoBook;

  /// No description provided for @uiThisWorkspaceIsDedicatedToYoutubeImportsSoVideoCuration.
  ///
  /// In en, this message translates to:
  /// **'This workspace is dedicated to YouTube imports, so video curation stays focused.'**
  String get uiThisWorkspaceIsDedicatedToYoutubeImportsSoVideoCuration;

  /// No description provided for @uiTimelineAndLocation.
  ///
  /// In en, this message translates to:
  /// **'Timeline and location'**
  String get uiTimelineAndLocation;

  /// No description provided for @uiToolsAndStack.
  ///
  /// In en, this message translates to:
  /// **'Tools and stack'**
  String get uiToolsAndStack;

  /// No description provided for @uiToolsOrStack.
  ///
  /// In en, this message translates to:
  /// **'Tools or stack'**
  String get uiToolsOrStack;

  /// No description provided for @uiTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get uiTop;

  /// No description provided for @uiTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get uiTotal;

  /// No description provided for @uiTotalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get uiTotalUsers;

  /// No description provided for @uiTotalthisweek.
  ///
  /// In en, this message translates to:
  /// **'{totalThisWeek}'**
  String uiTotalthisweek(Object totalThisWeek);

  /// No description provided for @uiTrackEachSubmissionAndSeeWhatDeservesYourNextMove.
  ///
  /// In en, this message translates to:
  /// **'Track each submission and see what deserves your next move.'**
  String get uiTrackEachSubmissionAndSeeWhatDeservesYourNextMove;

  /// No description provided for @uiTrackLatestEvents.
  ///
  /// In en, this message translates to:
  /// **'Track latest events'**
  String get uiTrackLatestEvents;

  /// No description provided for @uiTrackPlatformChangesAndJumpStraightIntoTheRightQueue.
  ///
  /// In en, this message translates to:
  /// **'Track platform changes and jump straight into the right queue.'**
  String get uiTrackPlatformChangesAndJumpStraightIntoTheRightQueue;

  /// No description provided for @uiTrackTheRolesYouNeedAndTheInterestBuildingAround.
  ///
  /// In en, this message translates to:
  /// **'Track the roles you need and the interest building around this idea.'**
  String get uiTrackTheRolesYouNeedAndTheInterestBuildingAround;

  /// No description provided for @uiTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get uiTraining;

  /// No description provided for @uiTrainingMenu.
  ///
  /// In en, this message translates to:
  /// **'Training menu'**
  String get uiTrainingMenu;

  /// No description provided for @uiTrainingOverview.
  ///
  /// In en, this message translates to:
  /// **'Training Overview'**
  String get uiTrainingOverview;

  /// No description provided for @uiTrainingPrograms.
  ///
  /// In en, this message translates to:
  /// **'Training Programs'**
  String get uiTrainingPrograms;

  /// No description provided for @uiTrainingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Training unavailable'**
  String get uiTrainingUnavailable;

  /// No description provided for @uiTrainings.
  ///
  /// In en, this message translates to:
  /// **'Trainings'**
  String get uiTrainings;

  /// No description provided for @uiTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get uiTranslate;

  /// No description provided for @uiTranslateTo.
  ///
  /// In en, this message translates to:
  /// **'Translate to'**
  String get uiTranslateTo;

  /// No description provided for @uiTrendingOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Trending Opportunities'**
  String get uiTrendingOpportunities;

  /// No description provided for @uiTryABroaderQueryOrChangeTheLanguageAndDomain.
  ///
  /// In en, this message translates to:
  /// **'Try a broader query or change the language and domain filters before searching again.'**
  String get uiTryABroaderQueryOrChangeTheLanguageAndDomain;

  /// No description provided for @uiTryABroaderQueryOrRefreshToLoadTheLatest.
  ///
  /// In en, this message translates to:
  /// **'Try a broader query or refresh to load the latest events.'**
  String get uiTryABroaderQueryOrRefreshToLoadTheLatest;

  /// No description provided for @uiTryABroaderQueryOrSwitchTheDomainAndLevel.
  ///
  /// In en, this message translates to:
  /// **'Try a broader query or switch the domain and level context before searching again.'**
  String get uiTryABroaderQueryOrSwitchTheDomainAndLevel;

  /// No description provided for @uiTryABroaderSearchTermOrContactSupportIfYou.
  ///
  /// In en, this message translates to:
  /// **'Try a broader search term, or contact support if you need hands-on help.'**
  String get uiTryABroaderSearchTermOrContactSupportIfYou;

  /// No description provided for @uiTryADifferentFilterOrStartANewIdea.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter or start a new idea.'**
  String get uiTryADifferentFilterOrStartANewIdea;

  /// No description provided for @uiTryAdjustingYourSearchOrFiltersToExploreMoreScholarships.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters\nto explore more scholarships.'**
  String get uiTryAdjustingYourSearchOrFiltersToExploreMoreScholarships;

  /// No description provided for @uiTryAdjustingYourSearchOrFiltersToUncoverMoreMatches.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters to uncover more matches.'**
  String get uiTryAdjustingYourSearchOrFiltersToUncoverMoreMatches;

  /// No description provided for @uiTryAnotherSearchOrRelaxTheCurrentRoleAndLevel.
  ///
  /// In en, this message translates to:
  /// **'Try another search or relax the current role and level filters.'**
  String get uiTryAnotherSearchOrRelaxTheCurrentRoleAndLevel;

  /// No description provided for @uiTwoStepVerification.
  ///
  /// In en, this message translates to:
  /// **'Two-step verification'**
  String get uiTwoStepVerification;

  /// No description provided for @uiType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get uiType;

  /// No description provided for @uiUiDesignIntern.
  ///
  /// In en, this message translates to:
  /// **'UI Design Intern'**
  String get uiUiDesignIntern;

  /// No description provided for @uiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get uiUnavailable;

  /// No description provided for @uiUnderstandWhatInformationIsStoredAndHowItIsUsed.
  ///
  /// In en, this message translates to:
  /// **'Understand what information is stored and how it is used inside the platform.'**
  String get uiUnderstandWhatInformationIsStoredAndHowItIsUsed;

  /// No description provided for @uiUniversity.
  ///
  /// In en, this message translates to:
  /// **'University'**
  String get uiUniversity;

  /// No description provided for @uiUnlockTheCompanyWorkspaceAndMoveItIntoTheApproved.
  ///
  /// In en, this message translates to:
  /// **'Unlock the company workspace and move it into the approved state.'**
  String get uiUnlockTheCompanyWorkspaceAndMoveItIntoTheApproved;

  /// No description provided for @uiUpcomingDeadlinesAreHighlightedHereAsNewOpportunitiesGoLive.
  ///
  /// In en, this message translates to:
  /// **'Upcoming deadlines are highlighted here as new opportunities go live.'**
  String get uiUpcomingDeadlinesAreHighlightedHereAsNewOpportunitiesGoLive;

  /// No description provided for @uiUpdateCredentialsReviewPrivacyTouchpointsAndKeepAccessToYour.
  ///
  /// In en, this message translates to:
  /// **'Update credentials, review privacy touchpoints, and keep access to your FutureGate profile secure.'**
  String get uiUpdateCredentialsReviewPrivacyTouchpointsAndKeepAccessToYour;

  /// No description provided for @uiUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update profile'**
  String get uiUpdateProfile;

  /// No description provided for @uiUpdateTheCompanyApprovalStateFromHereWithoutLeavingThe.
  ///
  /// In en, this message translates to:
  /// **'Update the company approval state from here without leaving the profile.'**
  String get uiUpdateTheCompanyApprovalStateFromHereWithoutLeavingThe;

  /// No description provided for @uiUpdateYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Update your profile'**
  String get uiUpdateYourProfile;

  /// No description provided for @uiUpdateYourSignInPassword.
  ///
  /// In en, this message translates to:
  /// **'Update your sign-in password'**
  String get uiUpdateYourSignInPassword;

  /// No description provided for @uiUploadAPdfJpgOrPngDocumentUpTo10.
  ///
  /// In en, this message translates to:
  /// **'Upload a PDF, JPG, or PNG document up to 10 MB to complete this part of the profile.'**
  String get uiUploadAPdfJpgOrPngDocumentUpTo10;

  /// No description provided for @uiUploadCommercialRegister.
  ///
  /// In en, this message translates to:
  /// **'Upload Commercial Register'**
  String get uiUploadCommercialRegister;

  /// No description provided for @uiUploadComplete.
  ///
  /// In en, this message translates to:
  /// **'Upload complete'**
  String get uiUploadComplete;

  /// No description provided for @uiUploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uiUploadDocument;

  /// No description provided for @uiUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uiUploadPhoto;

  /// No description provided for @uiUploadedCv.
  ///
  /// In en, this message translates to:
  /// **'Uploaded CV'**
  String get uiUploadedCv;

  /// No description provided for @uiUploadedUploadedatlabel.
  ///
  /// In en, this message translates to:
  /// **'Uploaded: {uploadedAtLabel}'**
  String uiUploadedUploadedatlabel(Object uploadedAtLabel);

  /// No description provided for @uiUrgentApplicationsThatNeedAttentionBeforeTheyExpire.
  ///
  /// In en, this message translates to:
  /// **'Urgent applications that need attention before they expire'**
  String get uiUrgentApplicationsThatNeedAttentionBeforeTheyExpire;

  /// No description provided for @uiUseAStrongPasswordWithAMixOfLettersNumbers.
  ///
  /// In en, this message translates to:
  /// **'Use a strong password with a mix of letters, numbers, and symbols to keep your account protected.'**
  String get uiUseAStrongPasswordWithAMixOfLettersNumbers;

  /// No description provided for @uiUseATopicDomainOrLanguageFilterToBringIn.
  ///
  /// In en, this message translates to:
  /// **'Use a topic, domain, or language filter to bring in curated books for review.'**
  String get uiUseATopicDomainOrLanguageFilterToBringIn;

  /// No description provided for @uiUseATopicSearchToBringBackImportReadyVideos.
  ///
  /// In en, this message translates to:
  /// **'Use a topic search to bring back import-ready videos for review.'**
  String get uiUseATopicSearchToBringBackImportReadyVideos;

  /// No description provided for @uiUseFuturegateResponsiblyKeepAccountInformationAccurateAndAvoidSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Use FutureGate responsibly, keep account information accurate, and avoid submitting misleading applications or content that violates platform rules.'**
  String
  get uiUseFuturegateResponsiblyKeepAccountInformationAccurateAndAvoidSubmitting;

  /// No description provided for @uiUseGracefulFallbacksWhereDataIsMissingAndKeepEmail.
  ///
  /// In en, this message translates to:
  /// **'Use graceful fallbacks where data is missing and keep email changes on the secure auth flow.'**
  String get uiUseGracefulFallbacksWhereDataIsMissingAndKeepEmail;

  /// No description provided for @uiUseTheExistingAccountToolsSafelyWithoutAffectingYourCurrent.
  ///
  /// In en, this message translates to:
  /// **'Use the existing account tools safely without affecting your current sign-in flow.'**
  String get uiUseTheExistingAccountToolsSafelyWithoutAffectingYourCurrent;

  /// No description provided for @uiUseTheExistingProfileAndSecurityFlowsAlreadyConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'Use the existing profile and security flows already connected to your account.'**
  String get uiUseTheExistingProfileAndSecurityFlowsAlreadyConnectedTo;

  /// No description provided for @uiUseTheLiveFeedToJumpDirectlyIntoTheRight.
  ///
  /// In en, this message translates to:
  /// **'Use the live feed to jump directly into the right moderation target.'**
  String get uiUseTheLiveFeedToJumpDirectlyIntoTheRight;

  /// No description provided for @uiUseTheseTagsToUnderstandWhatSupportTheIdeaNeeds.
  ///
  /// In en, this message translates to:
  /// **'Use these tags to understand what support the idea needs next.'**
  String get uiUseTheseTagsToUnderstandWhatSupportTheIdeaNeeds;

  /// No description provided for @uiUseUploaded.
  ///
  /// In en, this message translates to:
  /// **'Use Uploaded'**
  String get uiUseUploaded;

  /// No description provided for @uiUsefulReferencesAndContactPointsForThePlatform.
  ///
  /// In en, this message translates to:
  /// **'Useful references and contact points for the platform.'**
  String get uiUsefulReferencesAndContactPointsForThePlatform;

  /// No description provided for @uiUserActions.
  ///
  /// In en, this message translates to:
  /// **'User actions'**
  String get uiUserActions;

  /// No description provided for @uiUserDetails.
  ///
  /// In en, this message translates to:
  /// **'User Details'**
  String get uiUserDetails;

  /// No description provided for @uiUserManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get uiUserManagement;

  /// No description provided for @uiUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get uiUsers;

  /// No description provided for @uiUsersCouldNotBeLoaded.
  ///
  /// In en, this message translates to:
  /// **'Users could not be loaded'**
  String get uiUsersCouldNotBeLoaded;

  /// No description provided for @uiUsersDistribution.
  ///
  /// In en, this message translates to:
  /// **'Users Distribution'**
  String get uiUsersDistribution;

  /// No description provided for @uiUsingGoogleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Using Google sign-in?'**
  String get uiUsingGoogleSignIn;

  /// No description provided for @uiUxDesignAtTech.
  ///
  /// In en, this message translates to:
  /// **'UX Design at Tech'**
  String get uiUxDesignAtTech;

  /// No description provided for @uiUxResearchInternship.
  ///
  /// In en, this message translates to:
  /// **'UX Research Internship'**
  String get uiUxResearchInternship;

  /// No description provided for @uiValue1.
  ///
  /// In en, this message translates to:
  /// **'{value1}%'**
  String uiValue1(Object value1);

  /// No description provided for @uiValue1Active.
  ///
  /// In en, this message translates to:
  /// **'{value1} active'**
  String uiValue1Active(Object value1);

  /// No description provided for @uiValue1Admins.
  ///
  /// In en, this message translates to:
  /// **'{value1} admins'**
  String uiValue1Admins(Object value1);

  /// No description provided for @uiValue1Apps.
  ///
  /// In en, this message translates to:
  /// **'{value1} Apps'**
  String uiValue1Apps(Object value1);

  /// No description provided for @uiValue1Blocked.
  ///
  /// In en, this message translates to:
  /// **'{value1} blocked'**
  String uiValue1Blocked(Object value1);

  /// No description provided for @uiValue1CompanyReviews.
  ///
  /// In en, this message translates to:
  /// **'{value1} company reviews'**
  String uiValue1CompanyReviews(Object value1);

  /// No description provided for @uiValue1CompanyWorkspace.
  ///
  /// In en, this message translates to:
  /// **'{value1} company workspace'**
  String uiValue1CompanyWorkspace(Object value1);

  /// No description provided for @uiValue1De35.
  ///
  /// In en, this message translates to:
  /// **'{value1}'**
  String uiValue1De35(Object value1);

  /// No description provided for @uiValue1Featured.
  ///
  /// In en, this message translates to:
  /// **'{value1} featured'**
  String uiValue1Featured(Object value1);

  /// No description provided for @uiValue1ImportedBooks.
  ///
  /// In en, this message translates to:
  /// **'{value1} imported books'**
  String uiValue1ImportedBooks(Object value1);

  /// No description provided for @uiValue1ImportedVideos.
  ///
  /// In en, this message translates to:
  /// **'{value1} imported videos'**
  String uiValue1ImportedVideos(Object value1);

  /// No description provided for @uiValue1Interested.
  ///
  /// In en, this message translates to:
  /// **'{value1} interested'**
  String uiValue1Interested(Object value1);

  /// No description provided for @uiValue1Mb.
  ///
  /// In en, this message translates to:
  /// **'{value1} MB'**
  String uiValue1Mb(Object value1);

  /// No description provided for @uiValue1MbSelected.
  ///
  /// In en, this message translates to:
  /// **'{value1} MB selected'**
  String uiValue1MbSelected(Object value1);

  /// No description provided for @uiValue1Opportunities.
  ///
  /// In en, this message translates to:
  /// **'{value1} opportunities'**
  String uiValue1Opportunities(Object value1);

  /// No description provided for @uiValue1OpportunitiesCloseWithinTheNextTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'{value1} opportunities close within the next two weeks.'**
  String uiValue1OpportunitiesCloseWithinTheNextTwoWeeks(Object value1);

  /// No description provided for @uiValue1Results.
  ///
  /// In en, this message translates to:
  /// **'{value1} results'**
  String uiValue1Results(Object value1);

  /// No description provided for @uiValue1Scholarships.
  ///
  /// In en, this message translates to:
  /// **'{value1} scholarships'**
  String uiValue1Scholarships(Object value1);

  /// No description provided for @uiValue1Trainings.
  ///
  /// In en, this message translates to:
  /// **'{value1} trainings'**
  String uiValue1Trainings(Object value1);

  /// No description provided for @uiValue1Users.
  ///
  /// In en, this message translates to:
  /// **'{value1} users'**
  String uiValue1Users(Object value1);

  /// No description provided for @uiValue1Value2.
  ///
  /// In en, this message translates to:
  /// **'{value1} ({value2})'**
  String uiValue1Value2(Object value1, Object value2);

  /// No description provided for @uiValue1Value2Dca3.
  ///
  /// In en, this message translates to:
  /// **'{value1} - {value2}'**
  String uiValue1Value2Dca3(Object value1, Object value2);

  /// No description provided for @uiVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get uiVerification;

  /// No description provided for @uiVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification sent'**
  String get uiVerificationSent;

  /// No description provided for @uiVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get uiVerifyEmail;

  /// No description provided for @uiVersionValue1.
  ///
  /// In en, this message translates to:
  /// **'Version {value1}'**
  String uiVersionValue1(Object value1);

  /// No description provided for @uiVideoImportWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Video Import Workspace'**
  String get uiVideoImportWorkspace;

  /// No description provided for @uiVideoLessons.
  ///
  /// In en, this message translates to:
  /// **'Video Lessons'**
  String get uiVideoLessons;

  /// No description provided for @uiVideoLibraryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Video library unavailable'**
  String get uiVideoLibraryUnavailable;

  /// No description provided for @uiVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get uiVideos;

  /// No description provided for @uiView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get uiView;

  /// No description provided for @uiView69Bd.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get uiView69Bd;

  /// No description provided for @uiViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get uiViewAll;

  /// No description provided for @uiViewAllScholarships.
  ///
  /// In en, this message translates to:
  /// **'View all scholarships'**
  String get uiViewAllScholarships;

  /// No description provided for @uiViewApplicationsValue1.
  ///
  /// In en, this message translates to:
  /// **'View Applications ({value1})'**
  String uiViewApplicationsValue1(Object value1);

  /// No description provided for @uiViewBuiltCv.
  ///
  /// In en, this message translates to:
  /// **'View Built CV'**
  String get uiViewBuiltCv;

  /// No description provided for @uiViewCv.
  ///
  /// In en, this message translates to:
  /// **'View CV'**
  String get uiViewCv;

  /// No description provided for @uiViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get uiViewProfile;

  /// No description provided for @uiViewProfileB987.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get uiViewProfileB987;

  /// No description provided for @uiVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get uiVisibility;

  /// No description provided for @uiVisible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get uiVisible;

  /// No description provided for @uiWaveHouseSocial.
  ///
  /// In en, this message translates to:
  /// **'Wave House â¢ Social'**
  String get uiWaveHouseSocial;

  /// No description provided for @uiWeCouldNotLoadAdminAnalyticsRightNow.
  ///
  /// In en, this message translates to:
  /// **'We could not load admin analytics right now.'**
  String get uiWeCouldNotLoadAdminAnalyticsRightNow;

  /// No description provided for @uiWeCouldnTGenerateThisPdfPreviewRightNowValue1.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t generate this PDF preview right now. {value1}'**
  String uiWeCouldnTGenerateThisPdfPreviewRightNowValue1(Object value1);

  /// No description provided for @uiWeDLoveToChatAbout.
  ///
  /// In en, this message translates to:
  /// **'\"We\'d love to chat about...\"'**
  String get uiWeDLoveToChatAbout;

  /// No description provided for @uiWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get uiWebsite;

  /// No description provided for @uiWebsiteSocial.
  ///
  /// In en, this message translates to:
  /// **'Website & Social'**
  String get uiWebsiteSocial;

  /// No description provided for @uiWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FutureGate'**
  String get uiWelcomeBack;

  /// No description provided for @uiWhenEnabledTheIdeaReadsLikeAPublicCommunityOpportunity.
  ///
  /// In en, this message translates to:
  /// **'When enabled, the idea reads like a public community opportunity instead of a hidden internal note.'**
  String get uiWhenEnabledTheIdeaReadsLikeAPublicCommunityOpportunity;

  /// No description provided for @uiWhoCanApply.
  ///
  /// In en, this message translates to:
  /// **'Who Can Apply'**
  String get uiWhoCanApply;

  /// No description provided for @uiWorkSetup.
  ///
  /// In en, this message translates to:
  /// **'Work Setup'**
  String get uiWorkSetup;

  /// No description provided for @uiYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get uiYear;

  /// No description provided for @uiYouCanNowMessageCompanylabel.
  ///
  /// In en, this message translates to:
  /// **'You can now message {companyLabel}.'**
  String uiYouCanNowMessageCompanylabel(Object companyLabel);

  /// No description provided for @uiYouCanOpenTheCompanyProfileRightNowToImprove.
  ///
  /// In en, this message translates to:
  /// **'You can open the company profile right now to improve the company story, website, phone number, logo, or commercial register while the account is waiting for review.'**
  String get uiYouCanOpenTheCompanyProfileRightNowToImprove;

  /// No description provided for @uiYouCanSignBackInAnytimeWithTheSameAccount.
  ///
  /// In en, this message translates to:
  /// **'You can sign back in anytime with the same account.'**
  String get uiYouCanSignBackInAnytimeWithTheSameAccount;

  /// No description provided for @uiYouHaveReachedTheEndOfTheRecentActivityFeed.
  ///
  /// In en, this message translates to:
  /// **'You have reached the end of the recent activity feed.'**
  String get uiYouHaveReachedTheEndOfTheRecentActivityFeed;

  /// No description provided for @uiYouWillLeaveTheAdminWorkspaceOnThisDeviceSaved.
  ///
  /// In en, this message translates to:
  /// **'You will leave the admin workspace on this device. Saved changes stay safe.'**
  String get uiYouWillLeaveTheAdminWorkspaceOnThisDeviceSaved;

  /// No description provided for @uiYouWillLeaveTheCompanyWorkspaceOnThisDeviceYour.
  ///
  /// In en, this message translates to:
  /// **'You will leave the company workspace on this device. Your profile and opportunities stay saved.'**
  String get uiYouWillLeaveTheCompanyWorkspaceOnThisDeviceYour;

  /// No description provided for @uiYouWillLeaveYourStudentWorkspaceOnThisDeviceYour.
  ///
  /// In en, this message translates to:
  /// **'You will leave your student workspace on this device. Your profile and saved items stay safe.'**
  String get uiYouWillLeaveYourStudentWorkspaceOnThisDeviceYour;

  /// No description provided for @uiYourAccountDataIsUsedToProvideSignInProfile.
  ///
  /// In en, this message translates to:
  /// **'Your account data is used to provide sign-in, profile management, saved opportunities, notifications, CV access, and applications. Sensitive access is limited to the platform features that require it.'**
  String get uiYourAccountDataIsUsedToProvideSignInProfile;

  /// No description provided for @uiYourAccountProtectionHub.
  ///
  /// In en, this message translates to:
  /// **'Your account protection hub'**
  String get uiYourAccountProtectionHub;

  /// No description provided for @uiYourCvIsSavedPickATemplateToPreviewAnd.
  ///
  /// In en, this message translates to:
  /// **'Your CV is saved. Pick a template to preview and export as PDF.'**
  String get uiYourCvIsSavedPickATemplateToPreviewAnd;

  /// No description provided for @uiYourDailyStudentPulseShortcutsAndFreshMomentum.
  ///
  /// In en, this message translates to:
  /// **'Your daily student pulse, shortcuts, and fresh momentum.'**
  String get uiYourDailyStudentPulseShortcutsAndFreshMomentum;

  /// No description provided for @uiYourFiles.
  ///
  /// In en, this message translates to:
  /// **'Your Files'**
  String get uiYourFiles;

  /// No description provided for @uiYourLatestApplicationsSavesAndCvUpdatesAreReflectedHere.
  ///
  /// In en, this message translates to:
  /// **'Your latest applications, saves, and CV updates are reflected here.'**
  String get uiYourLatestApplicationsSavesAndCvUpdatesAreReflectedHere;

  /// No description provided for @uiYourShortlist.
  ///
  /// In en, this message translates to:
  /// **'Your shortlist'**
  String get uiYourShortlist;

  /// No description provided for @uiYourShortlistIsReady.
  ///
  /// In en, this message translates to:
  /// **'Your shortlist is ready.'**
  String get uiYourShortlistIsReady;

  /// No description provided for @uiYourSignInEmailWillRemainManagedByGoogleThis.
  ///
  /// In en, this message translates to:
  /// **'Your sign-in email will remain managed by Google. This only adds an additional way to sign in.'**
  String get uiYourSignInEmailWillRemainManagedByGoogleThis;

  /// No description provided for @uiYoutube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get uiYoutube;

  /// No description provided for @uiYoutubeImport.
  ///
  /// In en, this message translates to:
  /// **'YouTube Import'**
  String get uiYoutubeImport;

  /// No description provided for @uiBookLabel.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get uiBookLabel;

  /// No description provided for @uiVideoLabel.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get uiVideoLabel;

  /// No description provided for @uiCourseLabel.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get uiCourseLabel;

  /// No description provided for @uiGuideLabel.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get uiGuideLabel;

  /// No description provided for @uiProgramLabel.
  ///
  /// In en, this message translates to:
  /// **'Program'**
  String get uiProgramLabel;

  /// No description provided for @uiTrainLabel.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get uiTrainLabel;

  /// No description provided for @uiLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get uiLoading;

  /// No description provided for @uiNoTrainingResourcesAvailableRightNow.
  ///
  /// In en, this message translates to:
  /// **'No training resources available right now'**
  String get uiNoTrainingResourcesAvailableRightNow;

  /// No description provided for @uiFeature.
  ///
  /// In en, this message translates to:
  /// **'Feature'**
  String get uiFeature;

  /// No description provided for @uiUnfeature.
  ///
  /// In en, this message translates to:
  /// **'Unfeature'**
  String get uiUnfeature;

  /// No description provided for @uiThisOpportunityIsCurrentlyHidden.
  ///
  /// In en, this message translates to:
  /// **'This Opportunity Is Currently Hidden'**
  String get uiThisOpportunityIsCurrentlyHidden;

  /// No description provided for @uiThisScholarshipIsCurrentlyHidden.
  ///
  /// In en, this message translates to:
  /// **'This Scholarship Is Currently Hidden'**
  String get uiThisScholarshipIsCurrentlyHidden;

  /// No description provided for @uiScholarshipUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Scholarship Unavailable'**
  String get uiScholarshipUnavailable;

  /// No description provided for @uiThisTrainingResourceIsCurrentlyHidden.
  ///
  /// In en, this message translates to:
  /// **'This Training Resource Is Currently Hidden'**
  String get uiThisTrainingResourceIsCurrentlyHidden;

  /// No description provided for @uiThisTrainingDoesNotHaveALinkYet.
  ///
  /// In en, this message translates to:
  /// **'This Training Does Not Have A Link Yet'**
  String get uiThisTrainingDoesNotHaveALinkYet;

  /// No description provided for @uiThisTrainingLinkIsNotValid.
  ///
  /// In en, this message translates to:
  /// **'This Training Link Is Not Valid'**
  String get uiThisTrainingLinkIsNotValid;

  /// No description provided for @uiWeCouldnTOpenThisTrainingLinkRightNow.
  ///
  /// In en, this message translates to:
  /// **'We Couldn T Open This Training Link Right Now'**
  String get uiWeCouldnTOpenThisTrainingLinkRightNow;

  /// No description provided for @uiValueValue468dde.
  ///
  /// In en, this message translates to:
  /// **'{value1} {value2}'**
  String uiValueValue468dde(Object value1, Object value2);

  /// No description provided for @uiEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get uiEdited;

  /// No description provided for @uiScholarshipOverview.
  ///
  /// In en, this message translates to:
  /// **'Scholarship Overview'**
  String get uiScholarshipOverview;

  /// No description provided for @uiScholarshipDetails.
  ///
  /// In en, this message translates to:
  /// **'Scholarship Details'**
  String get uiScholarshipDetails;

  /// No description provided for @uiExpectedBenefits.
  ///
  /// In en, this message translates to:
  /// **'Expected Benefits'**
  String get uiExpectedBenefits;

  /// No description provided for @uiWeCouldntLoadLinkedActivity.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the linked {value1}.'**
  String uiWeCouldntLoadLinkedActivity(Object value1);

  /// No description provided for @uiValuede3545.
  ///
  /// In en, this message translates to:
  /// **'{value1}%'**
  String uiValuede3545(Object value1);

  /// No description provided for @uiWeCouldnTOpenThisAttachment.
  ///
  /// In en, this message translates to:
  /// **'We Couldn T Open This Attachment'**
  String get uiWeCouldnTOpenThisAttachment;

  /// No description provided for @uiView69bd4e.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get uiView69bd4e;

  /// No description provided for @uiValueInterested27bcc0.
  ///
  /// In en, this message translates to:
  /// **'{value1} Interested'**
  String uiValueInterested27bcc0(Object value1);

  /// No description provided for @uiSavedItems1d9c1a.
  ///
  /// In en, this message translates to:
  /// **'Saved Items'**
  String get uiSavedItems1d9c1a;

  /// No description provided for @uiValuePendingIdeas.
  ///
  /// In en, this message translates to:
  /// **'{value1} Pending Ideas'**
  String uiValuePendingIdeas(Object value1);

  /// No description provided for @uiValuePendingApps.
  ///
  /// In en, this message translates to:
  /// **'{value1} Pending Apps'**
  String uiValuePendingApps(Object value1);

  /// No description provided for @uiValueOpportunities.
  ///
  /// In en, this message translates to:
  /// **'{value1} opportunities'**
  String uiValueOpportunities(Object value1);

  /// No description provided for @uiValueScholarships.
  ///
  /// In en, this message translates to:
  /// **'{value1} scholarships'**
  String uiValueScholarships(Object value1);

  /// No description provided for @uiValueTrainings.
  ///
  /// In en, this message translates to:
  /// **'{value1} trainings'**
  String uiValueTrainings(Object value1);

  /// No description provided for @uiScholarships.
  ///
  /// In en, this message translates to:
  /// **'Scholarships'**
  String get uiScholarships;

  /// No description provided for @uiValue.
  ///
  /// In en, this message translates to:
  /// **'{value1}%'**
  String uiValue(Object value1);

  /// No description provided for @uiValueValue.
  ///
  /// In en, this message translates to:
  /// **'{value1} ({value2})'**
  String uiValueValue(Object value1, Object value2);

  /// No description provided for @uiSearchValue.
  ///
  /// In en, this message translates to:
  /// **'Search {value1}'**
  String uiSearchValue(Object value1);

  /// No description provided for @uiByValue.
  ///
  /// In en, this message translates to:
  /// **'By {value1}'**
  String uiByValue(Object value1);

  /// No description provided for @uiPendingIdeasStillWaiting.
  ///
  /// In en, this message translates to:
  /// **'Pending Ideas Still Waiting {value1}'**
  String uiPendingIdeasStillWaiting(Object value1);

  /// No description provided for @uiApplicationsForValue.
  ///
  /// In en, this message translates to:
  /// **'Applications For {value1}'**
  String uiApplicationsForValue(Object value1);

  /// No description provided for @uiApplicationsLinkedToOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Applications Linked To Opportunity {value1}'**
  String uiApplicationsLinkedToOpportunity(Object value1);

  /// No description provided for @uiValueApps.
  ///
  /// In en, this message translates to:
  /// **'{value1} Apps'**
  String uiValueApps(Object value1);

  /// No description provided for @uiUntitledScholarship.
  ///
  /// In en, this message translates to:
  /// **'Untitled Scholarship'**
  String get uiUntitledScholarship;

  /// No description provided for @uiYouCanOnlyUpdateApplicationsForOpportunitiesYouPostedAs.
  ///
  /// In en, this message translates to:
  /// **'You Can Only Update Applications For Opportunities You Posted As'**
  String get uiYouCanOnlyUpdateApplicationsForOpportunitiesYouPostedAs;

  /// No description provided for @uiThisDocumentIsNotAValidPdfFile.
  ///
  /// In en, this message translates to:
  /// **'This Document Is Not A Valid PDF File'**
  String get uiThisDocumentIsNotAValidPdfFile;

  /// No description provided for @uiWeCouldnTOpenTheDocumentRightNow.
  ///
  /// In en, this message translates to:
  /// **'We Couldn T Open The Document Right Now'**
  String get uiWeCouldnTOpenTheDocumentRightNow;

  /// No description provided for @uiViewApplicationsValue.
  ///
  /// In en, this message translates to:
  /// **'View Applications ({value1})'**
  String uiViewApplicationsValue(Object value1);

  /// No description provided for @uiOpenActivityf327dd.
  ///
  /// In en, this message translates to:
  /// **'Open activity'**
  String get uiOpenActivityf327dd;

  /// No description provided for @uiUntitledOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Untitled Opportunity'**
  String get uiUntitledOpportunity;

  /// No description provided for @uiEnterASearchQueryToContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter A Search Query To Continue'**
  String get uiEnterASearchQueryToContinue;

  /// No description provided for @uiAdminUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'Admin User Not Found'**
  String get uiAdminUserNotFound;

  /// No description provided for @uiDeleteValueFromFirestoreThisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{value1}\" from Firestore? This action cannot be undone.'**
  String uiDeleteValueFromFirestoreThisActionCannotBeUndone(Object value1);

  /// No description provided for @uiThisResultDoesNotIncludeAnExternalLink.
  ///
  /// In en, this message translates to:
  /// **'This Result Does Not Include An External Link'**
  String get uiThisResultDoesNotIncludeAnExternalLink;

  /// No description provided for @uiThisLinkIsNotValid.
  ///
  /// In en, this message translates to:
  /// **'This Link Is Not Valid'**
  String get uiThisLinkIsNotValid;

  /// No description provided for @uiWeCouldnTOpenThisLinkRightNow.
  ///
  /// In en, this message translates to:
  /// **'We Couldn T Open This Link Right Now'**
  String get uiWeCouldnTOpenThisLinkRightNow;

  /// No description provided for @uiValueImportedBooks.
  ///
  /// In en, this message translates to:
  /// **'{value1} imported books'**
  String uiValueImportedBooks(Object value1);

  /// No description provided for @uiValueFeatured.
  ///
  /// In en, this message translates to:
  /// **'{value1} featured'**
  String uiValueFeatured(Object value1);

  /// No description provided for @uiValueResults.
  ///
  /// In en, this message translates to:
  /// **'{value1} results'**
  String uiValueResults(Object value1);

  /// No description provided for @uiValueFeaturedResources.
  ///
  /// In en, this message translates to:
  /// **'{value1} Featured Resources'**
  String uiValueFeaturedResources(Object value1);

  /// No description provided for @uiInternalItems.
  ///
  /// In en, this message translates to:
  /// **'{value1} internal items'**
  String uiInternalItems(Object value1);

  /// No description provided for @uiProblemStatement1ebe49.
  ///
  /// In en, this message translates to:
  /// **'Problem Statement'**
  String get uiProblemStatement1ebe49;

  /// No description provided for @uiLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location Label'**
  String get uiLocationLabel;

  /// No description provided for @uiValueImportedVideos.
  ///
  /// In en, this message translates to:
  /// **'{value1} imported videos'**
  String uiValueImportedVideos(Object value1);

  /// No description provided for @uiSubmittedByValue.
  ///
  /// In en, this message translates to:
  /// **'Submitted by: {value1}'**
  String uiSubmittedByValue(Object value1);

  /// No description provided for @uiDueValue.
  ///
  /// In en, this message translates to:
  /// **'Due {value1}'**
  String uiDueValue(Object value1);

  /// No description provided for @uiValueUsers.
  ///
  /// In en, this message translates to:
  /// **'{value1} users'**
  String uiValueUsers(Object value1);

  /// No description provided for @uiValueActive.
  ///
  /// In en, this message translates to:
  /// **'{value1} active'**
  String uiValueActive(Object value1);

  /// No description provided for @uiValueBlocked.
  ///
  /// In en, this message translates to:
  /// **'{value1} blocked'**
  String uiValueBlocked(Object value1);

  /// No description provided for @uiValueAdmins.
  ///
  /// In en, this message translates to:
  /// **'{value1} admins'**
  String uiValueAdmins(Object value1);

  /// No description provided for @uiValueCompanyReviews.
  ///
  /// In en, this message translates to:
  /// **'{value1} company reviews'**
  String uiValueCompanyReviews(Object value1);

  /// No description provided for @uiValueUser.
  ///
  /// In en, this message translates to:
  /// **'{value1} users'**
  String uiValueUser(Object value1);

  /// No description provided for @uiText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get uiText;

  /// No description provided for @uiUploadedValue.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {value1}'**
  String uiUploadedValue(Object value1);

  /// No description provided for @uiValueMb.
  ///
  /// In en, this message translates to:
  /// **'{value1} MB'**
  String uiValueMb(Object value1);

  /// No description provided for @uiBackToLoginb5cd32.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get uiBackToLoginb5cd32;

  /// No description provided for @uiCreateAccounteff4fd.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get uiCreateAccounteff4fd;

  /// No description provided for @uiAcademicLevel80ccd3.
  ///
  /// In en, this message translates to:
  /// **'Academic level'**
  String get uiAcademicLevel80ccd3;

  /// No description provided for @uiWriteAMessageBeforeUsingAiTools.
  ///
  /// In en, this message translates to:
  /// **'Write A Message Before Using AI Tools'**
  String get uiWriteAMessageBeforeUsingAiTools;

  /// No description provided for @uiWriteAMessageBeforeChoosingATranslation.
  ///
  /// In en, this message translates to:
  /// **'Write A Message Before Choosing A Translation'**
  String get uiWriteAMessageBeforeChoosingATranslation;

  /// No description provided for @uiDeleteThisMessageForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete This Message For Everyone'**
  String get uiDeleteThisMessageForEveryone;

  /// No description provided for @uiTheConversationHasBeenDeleted.
  ///
  /// In en, this message translates to:
  /// **'The Conversation Has Been Deleted'**
  String get uiTheConversationHasBeenDeleted;

  /// No description provided for @uiSayHelloToValue.
  ///
  /// In en, this message translates to:
  /// **'Say Hello To {value1}'**
  String uiSayHelloToValue(Object value1);

  /// No description provided for @uiFieldOfStudy81e26d.
  ///
  /// In en, this message translates to:
  /// **'Field of Study'**
  String get uiFieldOfStudy81e26d;

  /// No description provided for @uiFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get uiFilters;

  /// No description provided for @uiStatus716883.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get uiStatus716883;

  /// No description provided for @uiType6e9816.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get uiType6e9816;

  /// No description provided for @uiRolesdd8b65.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get uiRolesdd8b65;

  /// No description provided for @uiShowingValueOfValueApplications.
  ///
  /// In en, this message translates to:
  /// **'Showing {value1} Of {value2} Applications'**
  String uiShowingValueOfValueApplications(Object value1, Object value2);

  /// No description provided for @uiNew66aabd.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get uiNew66aabd;

  /// No description provided for @uiAppliedValue.
  ///
  /// In en, this message translates to:
  /// **'Applied {value1}'**
  String uiAppliedValue(Object value1);

  /// No description provided for @uiTheLinkedOpportunityIsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'The Linked Opportunity Is No Longer Available'**
  String get uiTheLinkedOpportunityIsNoLongerAvailable;

  /// No description provided for @uiNoCvAvailableForValue.
  ///
  /// In en, this message translates to:
  /// **'No CV available for {value1}'**
  String uiNoCvAvailableForValue(Object value1);

  /// No description provided for @uiValueValuedca30a.
  ///
  /// In en, this message translates to:
  /// **'{value1} {value2}'**
  String uiValueValuedca30a(Object value1, Object value2);

  /// No description provided for @uiTheRequestedFileIsNotAValidPdf.
  ///
  /// In en, this message translates to:
  /// **'The Requested File Is Not A Valid PDF'**
  String get uiTheRequestedFileIsNotAValidPdf;

  /// No description provided for @uiValue45e7ea.
  ///
  /// In en, this message translates to:
  /// **'{value1}%'**
  String uiValue45e7ea(Object value1);

  /// No description provided for @uiOpenCandidateProfileForValue.
  ///
  /// In en, this message translates to:
  /// **'Open Candidate Profile For {value1}'**
  String uiOpenCandidateProfileForValue(Object value1);

  /// No description provided for @uiAppliedValue051b93.
  ///
  /// In en, this message translates to:
  /// **'Applied {value1}'**
  String uiAppliedValue051b93(Object value1);

  /// No description provided for @uiValueCompanyWorkspace.
  ///
  /// In en, this message translates to:
  /// **'{value1} company workspace'**
  String uiValueCompanyWorkspace(Object value1);

  /// No description provided for @uiPostOpportunity2f1ac8.
  ///
  /// In en, this message translates to:
  /// **'Post Opportunity'**
  String get uiPostOpportunity2f1ac8;

  /// No description provided for @uiValue391ff6.
  ///
  /// In en, this message translates to:
  /// **'{value1}%'**
  String uiValue391ff6(Object value1);

  /// No description provided for @uiMoveTheDeadlineIntoTheFutureBeforeReopeningThisOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Move The Deadline Into The Future Before Reopening This Opportunity'**
  String get uiMoveTheDeadlineIntoTheFutureBeforeReopeningThisOpportunity;

  /// No description provided for @uiDeleteValueIfItAlreadyHasApplicationsItWillBe.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{value1}\"? If it already has applications, it will be closed instead so history is preserved.'**
  String uiDeleteValueIfItAlreadyHasApplicationsItWillBe(Object value1);

  /// No description provided for @uiValueOfValue.
  ///
  /// In en, this message translates to:
  /// **'{value1} Of {value2}'**
  String uiValueOfValue(Object value1, Object value2);

  /// No description provided for @uiValueb1531b.
  ///
  /// In en, this message translates to:
  /// **'{value1}%'**
  String uiValueb1531b(Object value1);

  /// No description provided for @uiValueApplicants.
  ///
  /// In en, this message translates to:
  /// **'{value1} Applicants'**
  String uiValueApplicants(Object value1);

  /// No description provided for @uiDownloada479c9.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get uiDownloada479c9;

  /// No description provided for @uiValueMbSelected.
  ///
  /// In en, this message translates to:
  /// **'{value1} MB selected'**
  String uiValueMbSelected(Object value1);

  /// No description provided for @uiText85.
  ///
  /// In en, this message translates to:
  /// **'Text85'**
  String get uiText85;

  /// No description provided for @uiInternship.
  ///
  /// In en, this message translates to:
  /// **'Internships'**
  String get uiInternship;

  /// No description provided for @uiVersionValue.
  ///
  /// In en, this message translates to:
  /// **'Version {value1}'**
  String uiVersionValue(Object value1);

  /// No description provided for @uiNoEmailAppIsAvailableRightNow.
  ///
  /// In en, this message translates to:
  /// **'No Email App Is Available Right Now'**
  String get uiNoEmailAppIsAvailableRightNow;

  /// No description provided for @uiPasswordAddedSuccessfullyYouCanNowSignInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Password Added Successfully You Can Now Sign In With Google'**
  String get uiPasswordAddedSuccessfullyYouCanNowSignInWithGoogle;

  /// No description provided for @uiYourPasswordHasBeenUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your Password Has Been Updated Successfully'**
  String get uiYourPasswordHasBeenUpdatedSuccessfully;

  /// No description provided for @uiVerificationEmailSentConfirmYourNewAddressToCompleteThe.
  ///
  /// In en, this message translates to:
  /// **'Verification Email Sent Confirm Your New Address To Complete The'**
  String get uiVerificationEmailSentConfirmYourNewAddressToCompleteThe;

  /// No description provided for @uiNoEmailAppIsAvailableOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'No Email App Is Available On This Device'**
  String get uiNoEmailAppIsAvailableOnThisDevice;

  /// No description provided for @uiThisOpportunityIsNoLongerAvailableToOpen.
  ///
  /// In en, this message translates to:
  /// **'This Opportunity Is No Longer Available To Open'**
  String get uiThisOpportunityIsNoLongerAvailableToOpen;

  /// No description provided for @uiCoverImageUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Cover Image Uploaded Successfully'**
  String get uiCoverImageUploadedSuccessfully;

  /// No description provided for @uiIdeaTitlead8343.
  ///
  /// In en, this message translates to:
  /// **'Idea title'**
  String get uiIdeaTitlead8343;

  /// No description provided for @uiExplainTheConceptTheProblemBehindItAndTheSolution.
  ///
  /// In en, this message translates to:
  /// **'Explain The Concept The Problem Behind It And The Solution'**
  String get uiExplainTheConceptTheProblemBehindItAndTheSolution;

  /// No description provided for @uiTargetAudience5cc631.
  ///
  /// In en, this message translates to:
  /// **'Target audience'**
  String get uiTargetAudience5cc631;

  /// No description provided for @uiSkillsNeeded7988fd.
  ///
  /// In en, this message translates to:
  /// **'Skills needed'**
  String get uiSkillsNeeded7988fd;

  /// No description provided for @uiYourCvChangesHaveBeenSaved.
  ///
  /// In en, this message translates to:
  /// **'Your CV Changes Have Been Saved'**
  String get uiYourCvChangesHaveBeenSaved;

  /// No description provided for @uiEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get uiEducation;

  /// No description provided for @uiYourCvPdfHasBeenExportedAndSaved.
  ///
  /// In en, this message translates to:
  /// **'Your CV PDF has been saved to My CV'**
  String get uiYourCvPdfHasBeenExportedAndSaved;

  /// No description provided for @uiExportComplete.
  ///
  /// In en, this message translates to:
  /// **'PDF saved'**
  String get uiExportComplete;

  /// No description provided for @uiExportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Save unavailable'**
  String get uiExportUnavailable;

  /// No description provided for @uiExportSaveCv.
  ///
  /// In en, this message translates to:
  /// **'Save PDF to My CV'**
  String get uiExportSaveCv;

  /// No description provided for @uiAddYourCvDetailsBeforeGeneratingAPdf.
  ///
  /// In en, this message translates to:
  /// **'Add Your CV Details Before Generating A PDF'**
  String get uiAddYourCvDetailsBeforeGeneratingAPdf;

  /// No description provided for @uiThisFileIsNotAValidPdfYet.
  ///
  /// In en, this message translates to:
  /// **'This File Is Not A Valid PDF Yet'**
  String get uiThisFileIsNotAValidPdfYet;

  /// No description provided for @uiValuea6a59e.
  ///
  /// In en, this message translates to:
  /// **'{value1}%'**
  String uiValuea6a59e(Object value1);

  /// No description provided for @uiValueOfValueSectionsComplete.
  ///
  /// In en, this message translates to:
  /// **'{value1} Of {value2} Sections Complete'**
  String uiValueOfValueSectionsComplete(Object value1, Object value2);

  /// No description provided for @uiYourProfileHasBeenUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your Profile Has Been Updated Successfully'**
  String get uiYourProfileHasBeenUpdatedSuccessfully;

  /// No description provided for @uiEditProfilecd280a.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get uiEditProfilecd280a;

  /// No description provided for @uiFullDescriptionb43e9e.
  ///
  /// In en, this message translates to:
  /// **'Full description'**
  String get uiFullDescriptionb43e9e;

  /// No description provided for @uiTeamNeeded343772.
  ///
  /// In en, this message translates to:
  /// **'Team Needed'**
  String get uiTeamNeeded343772;

  /// No description provided for @uiCouldNotOpenThatLink.
  ///
  /// In en, this message translates to:
  /// **'Could Not Open That Link'**
  String get uiCouldNotOpenThatLink;

  /// No description provided for @uiSignInToSaveInternshipsForLater.
  ///
  /// In en, this message translates to:
  /// **'Sign In To Save Internships For Later'**
  String get uiSignInToSaveInternshipsForLater;

  /// No description provided for @uiSignInToSaveOpportunitiesForLater.
  ///
  /// In en, this message translates to:
  /// **'Sign In To Save Opportunities For Later'**
  String get uiSignInToSaveOpportunitiesForLater;

  /// No description provided for @uiFullTime.
  ///
  /// In en, this message translates to:
  /// **'Full Time'**
  String get uiFullTime;

  /// No description provided for @uiTheValueNewestRolesInternshipsAndSponsoredTracks.
  ///
  /// In en, this message translates to:
  /// **'The {value1} Newest Roles Internships And Sponsored Tracks'**
  String uiTheValueNewestRolesInternshipsAndSponsoredTracks(Object value1);

  /// No description provided for @uiClosingSoonc287b7.
  ///
  /// In en, this message translates to:
  /// **'Closing soon'**
  String get uiClosingSoonc287b7;

  /// No description provided for @uiSignInToContinueWithYourApplication.
  ///
  /// In en, this message translates to:
  /// **'Sign In To Continue With Your Application'**
  String get uiSignInToContinueWithYourApplication;

  /// No description provided for @uiCreateYourCvBeforeApplyingToThisOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Create Your CV Before Applying To This Opportunity'**
  String get uiCreateYourCvBeforeApplyingToThisOpportunity;

  /// No description provided for @uiApplicationApprovedb0cb9c.
  ///
  /// In en, this message translates to:
  /// **'Application\nApproved'**
  String get uiApplicationApprovedb0cb9c;

  /// No description provided for @uiSignInToChatWithTheCompany.
  ///
  /// In en, this message translates to:
  /// **'Sign In To Chat With The Company'**
  String get uiSignInToChatWithTheCompany;

  /// No description provided for @uiCompanyDetailsAreMissingForThisOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Company Details Are Missing For This Opportunity'**
  String get uiCompanyDetailsAreMissingForThisOpportunity;

  /// No description provided for @uiExperienceLevel.
  ///
  /// In en, this message translates to:
  /// **'Experience Level'**
  String get uiExperienceLevel;

  /// No description provided for @uiExternalLink663054.
  ///
  /// In en, this message translates to:
  /// **'External Link'**
  String get uiExternalLink663054;

  /// No description provided for @uiYouCanNowMessageValue.
  ///
  /// In en, this message translates to:
  /// **'You Can Now Message {value1}'**
  String uiYouCanNowMessageValue(Object value1);

  /// No description provided for @uiProfileStrength491db6.
  ///
  /// In en, this message translates to:
  /// **'Profile Strength'**
  String get uiProfileStrength491db6;

  /// No description provided for @uiValuee5544c.
  ///
  /// In en, this message translates to:
  /// **'{value1}%'**
  String uiValuee5544c(Object value1);

  /// No description provided for @uiValuee95f65.
  ///
  /// In en, this message translates to:
  /// **'{value1}%'**
  String uiValuee95f65(Object value1);

  /// No description provided for @uiThisOpportunityIsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This Opportunity Is No Longer Available To Open'**
  String get uiThisOpportunityIsNoLongerAvailable;

  /// No description provided for @uiThisScholarshipIsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This Scholarship Is No Longer Available'**
  String get uiThisScholarshipIsNoLongerAvailable;

  /// No description provided for @uiAllOppsValue.
  ///
  /// In en, this message translates to:
  /// **'All Opportunities ({value1})'**
  String uiAllOppsValue(Object value1);

  /// No description provided for @uiFundingValue.
  ///
  /// In en, this message translates to:
  /// **'Funding: {value1}'**
  String uiFundingValue(Object value1);

  /// No description provided for @uiValueInterested.
  ///
  /// In en, this message translates to:
  /// **'{value1} interested'**
  String uiValueInterested(Object value1);

  /// No description provided for @uiFeaturedc00531.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get uiFeaturedc00531;

  /// No description provided for @uiBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse categories'**
  String get uiBrowse;

  /// No description provided for @uiExploreScholarship.
  ///
  /// In en, this message translates to:
  /// **'Explore Scholarship'**
  String get uiExploreScholarship;

  /// No description provided for @uiScholarship.
  ///
  /// In en, this message translates to:
  /// **'Scholarship Unavailable'**
  String get uiScholarship;

  /// No description provided for @uiScholarshipProfile.
  ///
  /// In en, this message translates to:
  /// **'Scholarship Profile'**
  String get uiScholarshipProfile;

  /// No description provided for @uiTexte21a07.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get uiTexte21a07;

  /// No description provided for @uiCompleteYourProfile9a4b2b.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get uiCompleteYourProfile9a4b2b;

  /// No description provided for @uiValueValueStillMissingForBetterMatching.
  ///
  /// In en, this message translates to:
  /// **'{value1} {value2} Still Missing For Better Matching'**
  String uiValueValueStillMissingForBetterMatching(
    Object value1,
    Object value2,
  );

  /// No description provided for @uiValueValueApproved.
  ///
  /// In en, this message translates to:
  /// **'{value1} {value2} Approved'**
  String uiValueValueApproved(Object value1, Object value2);

  /// No description provided for @uiValueValueInReview.
  ///
  /// In en, this message translates to:
  /// **'{value1} {value2} In Review'**
  String uiValueValueInReview(Object value1, Object value2);

  /// No description provided for @uiValueOpportunitiesCloseWithinTheNextTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'{value1} opportunities close within the next two weeks.'**
  String uiValueOpportunitiesCloseWithinTheNextTwoWeeks(Object value1);

  /// No description provided for @uiExploreOpenRolesInternshipsFundingAndLearningPicksDesignedFor.
  ///
  /// In en, this message translates to:
  /// **'Explore Open Roles Internships Funding And Learning Picks Designed For'**
  String get uiExploreOpenRolesInternshipsFundingAndLearningPicksDesignedFor;

  /// No description provided for @uiValueReadyForBetterStudentMatching.
  ///
  /// In en, this message translates to:
  /// **'{value1} Ready For Better Student Matching'**
  String uiValueReadyForBetterStudentMatching(Object value1);

  /// No description provided for @uiValue6497ea.
  ///
  /// In en, this message translates to:
  /// **'{value1}%'**
  String uiValue6497ea(Object value1);

  /// No description provided for @uiViewProfileb98795.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get uiViewProfileb98795;

  /// No description provided for @uiThisSavedResourceLinkIsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This Saved Resource Link Is Not Available'**
  String get uiThisSavedResourceLinkIsNotAvailable;

  /// No description provided for @uiWeCouldnTOpenThisSavedResourceRightNow.
  ///
  /// In en, this message translates to:
  /// **'We Couldn T Open This Saved Resource Right Now'**
  String get uiWeCouldnTOpenThisSavedResourceRightNow;

  /// No description provided for @uiSignInToSaveTrainingResourcesForLater.
  ///
  /// In en, this message translates to:
  /// **'Sign In To Save Training Resources For Later'**
  String get uiSignInToSaveTrainingResourcesForLater;

  /// No description provided for @uiWeCouldnTGenerateThisPdfPreviewRightNowValue.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t generate this PDF preview right now. {value1}'**
  String uiWeCouldnTGenerateThisPdfPreviewRightNowValue(Object value1);

  /// No description provided for @uiAlreadyHaveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get uiAlreadyHaveAccountPrompt;

  /// No description provided for @uiLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get uiLogIn;

  /// No description provided for @uiByRegisteringAgreePrefix.
  ///
  /// In en, this message translates to:
  /// **'By registering, you agree to our '**
  String get uiByRegisteringAgreePrefix;

  /// No description provided for @uiBySigningUpAgreePrefix.
  ///
  /// In en, this message translates to:
  /// **'By signing up, you agree to our '**
  String get uiBySigningUpAgreePrefix;

  /// No description provided for @uiAndOur.
  ///
  /// In en, this message translates to:
  /// **' and our '**
  String get uiAndOur;

  /// No description provided for @uiCertified.
  ///
  /// In en, this message translates to:
  /// **'Certified'**
  String get uiCertified;

  /// No description provided for @authGoogleMissingToken.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in could not retrieve the required account token.'**
  String get authGoogleMissingToken;

  /// No description provided for @authGoogleSignInFailedShort.
  ///
  /// In en, this message translates to:
  /// **'Google sign in failed.'**
  String get authGoogleSignInFailedShort;

  /// No description provided for @authInvalidEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'The email address is not valid.'**
  String get authInvalidEmailMessage;

  /// No description provided for @authGoogleOnlyPasswordResetMessage.
  ///
  /// In en, this message translates to:
  /// **'This account uses Google sign-in. Sign in with Google, then add a password from Settings if you want reset emails later.'**
  String get authGoogleOnlyPasswordResetMessage;

  /// No description provided for @authTooManyAttemptsMessage.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get authTooManyAttemptsMessage;

  /// No description provided for @authPasswordResetFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email.'**
  String get authPasswordResetFailedMessage;

  /// No description provided for @authPasswordProviderNotLinkedMessage.
  ///
  /// In en, this message translates to:
  /// **'This account does not use email and password for sensitive changes.'**
  String get authPasswordProviderNotLinkedMessage;

  /// No description provided for @authPasswordAlreadyAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This account already has email and password sign-in enabled.'**
  String get authPasswordAlreadyAvailableMessage;

  /// No description provided for @authMissingEmailForPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'This account does not have an email address available for password sign-in.'**
  String get authMissingEmailForPasswordMessage;

  /// No description provided for @authPasswordChangeNotSupportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Password changes are only available for accounts with email and password sign-in.'**
  String get authPasswordChangeNotSupportedMessage;

  /// No description provided for @workerNotAuthenticatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated'**
  String get workerNotAuthenticatedMessage;

  /// No description provided for @uiSearchFailedValue.
  ///
  /// In en, this message translates to:
  /// **'Search failed: {value1}'**
  String uiSearchFailedValue(Object value1);

  /// No description provided for @uiValueImportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'\"{value1}\" imported successfully.'**
  String uiValueImportedSuccessfully(Object value1);

  /// No description provided for @uiImportFailedValue.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {value1}'**
  String uiImportFailedValue(Object value1);

  /// No description provided for @uiValueDeleted.
  ///
  /// In en, this message translates to:
  /// **'\"{value1}\" deleted.'**
  String uiValueDeleted(Object value1);

  /// No description provided for @uiCouldNotOpenChatValue.
  ///
  /// In en, this message translates to:
  /// **'Could not open chat: {value1}'**
  String uiCouldNotOpenChatValue(Object value1);

  /// No description provided for @uiApplicationStatusValue.
  ///
  /// In en, this message translates to:
  /// **'Application {value1}.'**
  String uiApplicationStatusValue(Object value1);

  /// No description provided for @uiWeCouldnTOpenThisAttachmentValue.
  ///
  /// In en, this message translates to:
  /// **'We couldn?t open this attachment. {value1}'**
  String uiWeCouldnTOpenThisAttachmentValue(Object value1);

  /// No description provided for @uiSearchBooksFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while searching books. Please try again.'**
  String get uiSearchBooksFailedMessage;

  /// No description provided for @validationFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get validationFullNameRequired;

  /// No description provided for @validationNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get validationNameMinLength;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validationEmailRequired;

  /// No description provided for @validationValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validationValidEmailAddress;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get validationPasswordMinLength;

  /// No description provided for @validationPasswordUppercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain an uppercase letter'**
  String get validationPasswordUppercase;

  /// No description provided for @validationPasswordLowercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain a lowercase letter'**
  String get validationPasswordLowercase;

  /// No description provided for @validationPasswordNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must contain a number'**
  String get validationPasswordNumber;

  /// No description provided for @validationConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get validationConfirmPasswordRequired;

  /// No description provided for @validationPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordsDoNotMatch;

  /// No description provided for @documentSelectPrimaryCv.
  ///
  /// In en, this message translates to:
  /// **'Select a PDF CV file.'**
  String get documentSelectPrimaryCv;

  /// No description provided for @documentPrimaryCvEmpty.
  ///
  /// In en, this message translates to:
  /// **'The selected CV file is empty.'**
  String get documentPrimaryCvEmpty;

  /// No description provided for @documentPrimaryCvTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Primary CV must be smaller than 10 MB.'**
  String get documentPrimaryCvTooLarge;

  /// No description provided for @documentPrimaryCvMustBePdf.
  ///
  /// In en, this message translates to:
  /// **'Primary CV must be uploaded as a PDF file.'**
  String get documentPrimaryCvMustBePdf;

  /// No description provided for @documentCommercialRegisterRequired.
  ///
  /// In en, this message translates to:
  /// **'Commercial register is required.'**
  String get documentCommercialRegisterRequired;

  /// No description provided for @documentCommercialRegisterEmpty.
  ///
  /// In en, this message translates to:
  /// **'The selected commercial register file is empty.'**
  String get documentCommercialRegisterEmpty;

  /// No description provided for @documentCommercialRegisterTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Commercial register must be smaller than 10 MB.'**
  String get documentCommercialRegisterTooLarge;

  /// No description provided for @documentCommercialRegisterInvalidType.
  ///
  /// In en, this message translates to:
  /// **'Commercial register must be a PDF, JPG, or PNG file.'**
  String get documentCommercialRegisterInvalidType;

  /// No description provided for @applicationStatusApprovedSentence.
  ///
  /// In en, this message translates to:
  /// **'approved'**
  String get applicationStatusApprovedSentence;

  /// No description provided for @applicationStatusRejectedSentence.
  ///
  /// In en, this message translates to:
  /// **'rejected'**
  String get applicationStatusRejectedSentence;

  /// No description provided for @applicationStatusPendingSentence.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get applicationStatusPendingSentence;

  /// No description provided for @launchAnimationHint.
  ///
  /// In en, this message translates to:
  /// **'Prefer a faster start? Turn this off in Settings.'**
  String get launchAnimationHint;

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Connect with the\nRight Opportunities.'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Description.
  ///
  /// In en, this message translates to:
  /// **'Reach companies, explore real career paths, and take the next step toward your future.'**
  String get onboardingSlide1Description;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Build a Strong\nStudent Profile.'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Description.
  ///
  /// In en, this message translates to:
  /// **'Create your profile, showcase your skills, and prepare for the opportunities that match your goals.'**
  String get onboardingSlide2Description;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Open the Door to\nYour Future.'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Description.
  ///
  /// In en, this message translates to:
  /// **'Build your FutureGate space to apply faster, track replies, and keep internships, jobs, and scholarships organized.'**
  String get onboardingSlide3Description;

  /// No description provided for @uiDontHaveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get uiDontHaveAccountPrompt;

  /// No description provided for @uiEmailHint.
  ///
  /// In en, this message translates to:
  /// **'email@example.com'**
  String get uiEmailHint;

  /// No description provided for @uiEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get uiEnterYourPassword;

  /// No description provided for @uiIncorrectEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. Please try again.'**
  String get uiIncorrectEmailOrPassword;

  /// No description provided for @uiStartYourStudentProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start your student profile.'**
  String get uiStartYourStudentProfileSubtitle;

  /// No description provided for @uiHowYourNameShouldAppear.
  ///
  /// In en, this message translates to:
  /// **'How your name should appear'**
  String get uiHowYourNameShouldAppear;

  /// No description provided for @uiCreateAStrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a strong password'**
  String get uiCreateAStrongPassword;

  /// No description provided for @uiRepeatYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password'**
  String get uiRepeatYourPassword;

  /// No description provided for @uiResearchTopicHint.
  ///
  /// In en, this message translates to:
  /// **'Machine learning in healthcare'**
  String get uiResearchTopicHint;

  /// No description provided for @uiLaboratoryHint.
  ///
  /// In en, this message translates to:
  /// **'Research laboratory'**
  String get uiLaboratoryHint;

  /// No description provided for @uiSupervisorHint.
  ///
  /// In en, this message translates to:
  /// **'Supervisor name'**
  String get uiSupervisorHint;

  /// No description provided for @uiResearchDomainHint.
  ///
  /// In en, this message translates to:
  /// **'Artificial intelligence'**
  String get uiResearchDomainHint;

  /// No description provided for @uiBySigningUpAgreeSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get uiBySigningUpAgreeSuffix;

  /// No description provided for @uiAccountCreationUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Account creation unavailable'**
  String get uiAccountCreationUnavailableTitle;

  /// No description provided for @uiDiscoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Jobs, internships, and sponsored tracks matched to your next move.'**
  String get uiDiscoverSubtitle;

  /// No description provided for @uiScholarshipsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Funding opportunities, deadlines, and global study paths.'**
  String get uiScholarshipsSubtitle;

  /// No description provided for @uiTrainingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Courses, books, and certifications that sharpen your journey.'**
  String get uiTrainingSubtitle;

  /// No description provided for @uiIdeasSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build, save, and grow your next project idea with confidence.'**
  String get uiIdeasSubtitle;

  /// No description provided for @uiChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay close to conversations, follow-ups, and collaboration.'**
  String get uiChatSubtitle;

  /// No description provided for @uiHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your daily student pulse, shortcuts, and fresh momentum.'**
  String get uiHomeSubtitle;

  /// No description provided for @uiPreferFasterStart.
  ///
  /// In en, this message translates to:
  /// **'Prefer a faster start? Turn this off in Settings.'**
  String get uiPreferFasterStart;

  /// No description provided for @opportunityTypeJob.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get opportunityTypeJob;

  /// No description provided for @opportunityTypeInternship.
  ///
  /// In en, this message translates to:
  /// **'Internship'**
  String get opportunityTypeInternship;

  /// No description provided for @opportunityTypeSponsored.
  ///
  /// In en, this message translates to:
  /// **'Sponsored'**
  String get opportunityTypeSponsored;

  /// No description provided for @opportunityDescriptionLabelSponsoring.
  ///
  /// In en, this message translates to:
  /// **'Program description'**
  String get opportunityDescriptionLabelSponsoring;

  /// No description provided for @opportunityRequirementsLabelSponsoring.
  ///
  /// In en, this message translates to:
  /// **'Eligibility'**
  String get opportunityRequirementsLabelSponsoring;

  /// No description provided for @opportunityRequirementsLabelJob.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get opportunityRequirementsLabelJob;

  /// No description provided for @uiContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get uiContinueWithGoogle;

  /// No description provided for @uiOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get uiOr;

  /// No description provided for @authAcademicBacLabel.
  ///
  /// In en, this message translates to:
  /// **'Bachelor'**
  String get authAcademicBacLabel;

  /// No description provided for @authAcademicBacDescription.
  ///
  /// In en, this message translates to:
  /// **'Foundational university track'**
  String get authAcademicBacDescription;

  /// No description provided for @authAcademicLicenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Licence'**
  String get authAcademicLicenceLabel;

  /// No description provided for @authAcademicLicenceDescription.
  ///
  /// In en, this message translates to:
  /// **'Licence degree program'**
  String get authAcademicLicenceDescription;

  /// No description provided for @authAcademicMasterLabel.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get authAcademicMasterLabel;

  /// No description provided for @authAcademicMasterDescription.
  ///
  /// In en, this message translates to:
  /// **'Advanced academic specialization'**
  String get authAcademicMasterDescription;

  /// No description provided for @authAcademicDoctoratLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctorat'**
  String get authAcademicDoctoratLabel;

  /// No description provided for @authAcademicDoctoratDescription.
  ///
  /// In en, this message translates to:
  /// **'Doctoral research and thesis work'**
  String get authAcademicDoctoratDescription;

  /// No description provided for @uiJoinFutureGate.
  ///
  /// In en, this message translates to:
  /// **'Join FutureGate'**
  String get uiJoinFutureGate;

  /// No description provided for @uiImAStudent.
  ///
  /// In en, this message translates to:
  /// **'I\'m a Student'**
  String get uiImAStudent;

  /// No description provided for @uiImACompany.
  ///
  /// In en, this message translates to:
  /// **'I\'m a Company'**
  String get uiImACompany;

  /// No description provided for @uiEmailNotVerifiedYet.
  ///
  /// In en, this message translates to:
  /// **'Email not verified yet.'**
  String get uiEmailNotVerifiedYet;

  /// No description provided for @uiVerificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent.'**
  String get uiVerificationEmailSent;

  /// No description provided for @uiYourUniversity.
  ///
  /// In en, this message translates to:
  /// **'Your university'**
  String get uiYourUniversity;

  /// No description provided for @uiComputerScience.
  ///
  /// In en, this message translates to:
  /// **'Computer science'**
  String get uiComputerScience;

  /// No description provided for @uiCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get uiCity;

  /// No description provided for @uiLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get uiLevel;

  /// No description provided for @uiFieldIsRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String uiFieldIsRequired(String field);

  /// No description provided for @uiLabName.
  ///
  /// In en, this message translates to:
  /// **'Lab name'**
  String get uiLabName;

  /// No description provided for @uiAiFinance.
  ///
  /// In en, this message translates to:
  /// **'AI, finance...'**
  String get uiAiFinance;

  /// No description provided for @uiPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+213 ...'**
  String get uiPhoneHint;

  /// No description provided for @uiRegisterCompanySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register your organization to post opportunities and connect with talent.'**
  String get uiRegisterCompanySubtitle;

  /// No description provided for @uiCompanyNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Company name is required'**
  String get uiCompanyNameIsRequired;

  /// No description provided for @uiExTechCorpAlgeria.
  ///
  /// In en, this message translates to:
  /// **'Ex: TechCorp Algeria'**
  String get uiExTechCorpAlgeria;

  /// No description provided for @uiExTechnologyHealthcareFinance.
  ///
  /// In en, this message translates to:
  /// **'Ex: Technology, Healthcare, Finance...'**
  String get uiExTechnologyHealthcareFinance;

  /// No description provided for @uiBriefDescriptionOfYourOrganization.
  ///
  /// In en, this message translates to:
  /// **'Brief description of your organization...'**
  String get uiBriefDescriptionOfYourOrganization;

  /// No description provided for @uiContactOptional.
  ///
  /// In en, this message translates to:
  /// **'Contact (optional)'**
  String get uiContactOptional;

  /// No description provided for @uiContactEmailHint.
  ///
  /// In en, this message translates to:
  /// **'contact@company.com'**
  String get uiContactEmailHint;

  /// No description provided for @uiPhoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'+213 xxx xxx xxx'**
  String get uiPhoneNumberHint;

  /// No description provided for @uiWebsiteHint.
  ///
  /// In en, this message translates to:
  /// **'https://www.company.com'**
  String get uiWebsiteHint;

  /// No description provided for @uiUploadCommercialRegisterToContinue.
  ///
  /// In en, this message translates to:
  /// **'Upload your commercial register to continue.'**
  String get uiUploadCommercialRegisterToContinue;

  /// No description provided for @uiContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get uiContinue;

  /// No description provided for @uiLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get uiLocation;

  /// No description provided for @uiBackToLoginLower.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get uiBackToLoginLower;

  /// No description provided for @uiSignOutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get uiSignOutTooltip;

  /// No description provided for @uiCompanyInformation.
  ///
  /// In en, this message translates to:
  /// **'Company Information'**
  String get uiCompanyInformation;

  /// No description provided for @uiAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get uiAccountDetails;

  /// No description provided for @securitySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securitySectionTitle;

  /// No description provided for @securitySectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep passwords, privacy controls, and account protections close at hand.'**
  String get securitySectionSubtitle;

  /// No description provided for @signOutCompanySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of the company workspace'**
  String get signOutCompanySubtitle;

  /// No description provided for @adminSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin settings'**
  String get adminSettingsTitle;

  /// No description provided for @adminAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin account'**
  String get adminAccountLabel;

  /// No description provided for @adminWorkspaceBody.
  ///
  /// In en, this message translates to:
  /// **'Control your workspace preferences without changing the admin profile record.'**
  String get adminWorkspaceBody;

  /// No description provided for @adminLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminLabel;

  /// No description provided for @adminWorkspaceSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep platform operations close without exposing profile editing.'**
  String get adminWorkspaceSectionSubtitle;

  /// No description provided for @adminSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App information and help for platform admins.'**
  String get adminSupportSubtitle;

  /// No description provided for @signOutAdminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'End this admin session on the current device'**
  String get signOutAdminSubtitle;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @appThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'App theme'**
  String get appThemeTitle;

  /// No description provided for @themeSystemLabel.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystemLabel;

  /// No description provided for @themeLightLabel.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLightLabel;

  /// No description provided for @themeDarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDarkLabel;

  /// No description provided for @themeSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow your device appearance setting'**
  String get themeSystemSubtitle;

  /// No description provided for @themeLightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep FutureGate bright and airy'**
  String get themeLightSubtitle;

  /// No description provided for @themeDarkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the premium dark workspace'**
  String get themeDarkSubtitle;

  /// No description provided for @startSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startSectionTitle;

  /// No description provided for @showStartupAnimationTitle.
  ///
  /// In en, this message translates to:
  /// **'Show startup animation'**
  String get showStartupAnimationTitle;

  /// No description provided for @startupAnimCheckingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Checking your launch preference...'**
  String get startupAnimCheckingSubtitle;

  /// No description provided for @startupAnimOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The launch video will play when FutureGate opens.'**
  String get startupAnimOnSubtitle;

  /// No description provided for @startupAnimOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FutureGate will open directly next time.'**
  String get startupAnimOffSubtitle;

  /// No description provided for @startupAnimErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not update the startup animation setting.'**
  String get startupAnimErrorMessage;

  /// No description provided for @languageInfoSheetMessage.
  ///
  /// In en, this message translates to:
  /// **'The current app experience is shown in English. Broader language selection can be introduced safely in a later iteration.'**
  String get languageInfoSheetMessage;

  /// No description provided for @accountProtectionHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account protection hub'**
  String get accountProtectionHubTitle;

  /// No description provided for @accountProtectionHubBody.
  ///
  /// In en, this message translates to:
  /// **'Update credentials, review privacy touchpoints, and keep access to your FutureGate profile secure.'**
  String get accountProtectionHubBody;

  /// No description provided for @accountSecuritySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get accountSecuritySectionTitle;

  /// No description provided for @accountSecuritySectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the existing account tools safely without affecting your current sign-in flow.'**
  String get accountSecuritySectionSubtitle;

  /// No description provided for @addPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Password'**
  String get addPasswordTitle;

  /// No description provided for @addPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep Google sign-in and add email/password too'**
  String get addPasswordSubtitle;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your sign-in password'**
  String get changePasswordSubtitle;

  /// No description provided for @changeEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get changeEmailTitle;

  /// No description provided for @changeEmailCurrentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Current: {email}'**
  String changeEmailCurrentSubtitle(Object email);

  /// No description provided for @changeEmailVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify a new sign-in email'**
  String get changeEmailVerifySubtitle;

  /// No description provided for @googleLinkedAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Google-linked account'**
  String get googleLinkedAccountTitle;

  /// No description provided for @googleManagedAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Google-managed account'**
  String get googleManagedAccountTitle;

  /// No description provided for @googleLinkedAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This account can sign in with both Google and email/password, but the sign-in email stays managed through Google.'**
  String get googleLinkedAccountBody;

  /// No description provided for @googleManagedAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This account signs in with Google. You can add a password if you want email/password access too, but the sign-in email itself stays managed through Google.'**
  String get googleManagedAccountBody;

  /// No description provided for @twoStepVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-step verification'**
  String get twoStepVerificationTitle;

  /// No description provided for @twoStepVerificationGoogleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage it through your Google account'**
  String get twoStepVerificationGoogleSubtitle;

  /// No description provided for @twoStepVerificationEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Available through your email provider'**
  String get twoStepVerificationEmailSubtitle;

  /// No description provided for @twoStepVerificationGoogleBody.
  ///
  /// In en, this message translates to:
  /// **'This account signs in with {provider}, so two-step verification is managed directly by Google.'**
  String twoStepVerificationGoogleBody(Object provider);

  /// No description provided for @twoStepVerificationEmailBody.
  ///
  /// In en, this message translates to:
  /// **'A dedicated in-app two-step setup is not enabled yet. For now, keep your mailbox protected and use a strong password.'**
  String get twoStepVerificationEmailBody;

  /// No description provided for @manageSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage sessions & devices'**
  String get manageSessionsTitle;

  /// No description provided for @manageSessionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review where your account is being used'**
  String get manageSessionsSubtitle;

  /// No description provided for @sessionsDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sessions & devices'**
  String get sessionsDevicesTitle;

  /// No description provided for @sessionsDevicesBody.
  ///
  /// In en, this message translates to:
  /// **'Remote session management is not available in this build yet. Your active session on this device remains protected by Firebase authentication.'**
  String get sessionsDevicesBody;

  /// No description provided for @privacyControlsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Controls'**
  String get privacyControlsSectionTitle;

  /// No description provided for @privacyControlsSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Understand what information is stored and how it is used inside the platform.'**
  String get privacyControlsSectionSubtitle;

  /// No description provided for @dataPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Data permissions'**
  String get dataPermissionsTitle;

  /// No description provided for @dataPermissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile, CV, and application data are used to power opportunities and recruiter review flows.'**
  String get dataPermissionsSubtitle;

  /// No description provided for @dataPermissionsBody.
  ///
  /// In en, this message translates to:
  /// **'FutureGate stores the profile details, CV content, saved items, and application activity needed to match students with opportunities and support application review.'**
  String get dataPermissionsBody;

  /// No description provided for @privacyPolicySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicySettingsTitle;

  /// No description provided for @privacyPolicySettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read how personal information is handled'**
  String get privacyPolicySettingsSubtitle;

  /// No description provided for @privacyPolicySettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Your account data is used to provide sign-in, profile management, saved opportunities, notifications, CV access, and applications. Sensitive access is limited to the platform features that require it.'**
  String get privacyPolicySettingsBody;

  /// No description provided for @termsOfUseSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUseSettingsTitle;

  /// No description provided for @termsOfUseSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review expected platform usage'**
  String get termsOfUseSettingsSubtitle;

  /// No description provided for @termsOfUseSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Use FutureGate responsibly, keep account information accurate, and avoid submitting misleading applications or content that violates platform rules.'**
  String get termsOfUseSettingsBody;

  /// No description provided for @addPasswordBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add email and password sign-in'**
  String get addPasswordBannerTitle;

  /// No description provided for @addPasswordBannerBodyGeneric.
  ///
  /// In en, this message translates to:
  /// **'Keep Google sign-in and add a password for this account.'**
  String get addPasswordBannerBodyGeneric;

  /// No description provided for @addPasswordBannerBodyEmail.
  ///
  /// In en, this message translates to:
  /// **'Keep Google sign-in and add a password for {email}.'**
  String addPasswordBannerBodyEmail(Object email);

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPasswordLabel;

  /// No description provided for @addPasswordNote.
  ///
  /// In en, this message translates to:
  /// **'Your sign-in email will remain managed by Google. This only adds an additional way to sign in.'**
  String get addPasswordNote;

  /// No description provided for @addingPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Adding...'**
  String get addingPasswordLabel;

  /// No description provided for @passwordAddedSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Password added successfully. You can now sign in with Google or email and password.'**
  String get passwordAddedSuccessBody;

  /// No description provided for @passwordSetupAlreadyEnabled.
  ///
  /// In en, this message translates to:
  /// **'This account already has email and password sign-in enabled.'**
  String get passwordSetupAlreadyEnabled;

  /// No description provided for @passwordSetupGoogleOnly.
  ///
  /// In en, this message translates to:
  /// **'A password can only be added while signed in to a Google account that does not already have email/password linked.'**
  String get passwordSetupGoogleOnly;

  /// No description provided for @secureAccountBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure your account'**
  String get secureAccountBannerTitle;

  /// No description provided for @secureAccountBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Use a strong password with a mix of letters, numbers, and symbols to keep your account protected.'**
  String get secureAccountBannerBody;

  /// No description provided for @updatingPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updatingPasswordLabel;

  /// No description provided for @updatePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePasswordLabel;

  /// No description provided for @passwordUpdatedBody.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated successfully.'**
  String get passwordUpdatedBody;

  /// No description provided for @passwordChangesUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Password changes unavailable'**
  String get passwordChangesUnavailableTitle;

  /// No description provided for @passwordChangesGoogleBody.
  ///
  /// In en, this message translates to:
  /// **'This account uses Google sign-in right now. Add a password first, then you can change it later.'**
  String get passwordChangesGoogleBody;

  /// No description provided for @passwordChangesOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Password changes are only available for accounts that already use email and password sign-in.'**
  String get passwordChangesOnlyBody;

  /// No description provided for @emailChangesUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Email changes unavailable'**
  String get emailChangesUnavailableTitle;

  /// No description provided for @emailChangesGoogleBody.
  ///
  /// In en, this message translates to:
  /// **'This account is linked to Google, so the sign-in email must be managed through Google.'**
  String get emailChangesGoogleBody;

  /// No description provided for @emailChangesPasswordOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Email changes are only available for accounts that use email and password without Google linked.'**
  String get emailChangesPasswordOnlyBody;

  /// No description provided for @currentEmailBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Current email'**
  String get currentEmailBannerTitle;

  /// No description provided for @noEmailAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'No email is currently available for this account.'**
  String get noEmailAvailableBody;

  /// No description provided for @newEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'New Email'**
  String get newEmailLabel;

  /// No description provided for @newEmailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get newEmailHint;

  /// No description provided for @emailVerificationNote.
  ///
  /// In en, this message translates to:
  /// **'A verification link will be sent to the new address before the change becomes active.'**
  String get emailVerificationNote;

  /// No description provided for @updatingEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updatingEmailLabel;

  /// No description provided for @updateEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Update Email'**
  String get updateEmailLabel;

  /// No description provided for @verificationSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification sent'**
  String get verificationSentTitle;

  /// No description provided for @verificationSentBody.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Confirm your new address to complete the update.'**
  String get verificationSentBody;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// No description provided for @howCanWeHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get howCanWeHelpTitle;

  /// No description provided for @howCanWeHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search common topics, contact support, or report something that needs attention.'**
  String get howCanWeHelpSubtitle;

  /// No description provided for @searchHelpTopicsHint.
  ///
  /// In en, this message translates to:
  /// **'Search help topics'**
  String get searchHelpTopicsHint;

  /// No description provided for @quickSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Support'**
  String get quickSupportTitle;

  /// No description provided for @quickSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reach out with context so the team can help faster.'**
  String get quickSupportSubtitle;

  /// No description provided for @contactSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupportTitle;

  /// No description provided for @reportProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a Problem'**
  String get reportProblemTitle;

  /// No description provided for @reportProblemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share screenshots, steps, or account issues'**
  String get reportProblemSubtitle;

  /// No description provided for @faqsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get faqsSectionTitle;

  /// No description provided for @noTopicsMatchedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No topics matched your search.'**
  String get noTopicsMatchedSubtitle;

  /// No description provided for @helpTopicCount.
  ///
  /// In en, this message translates to:
  /// **'{count} help topic(s)'**
  String helpTopicCount(Object count);

  /// No description provided for @noHelpTopicsMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No help topics match your search'**
  String get noHelpTopicsMatchTitle;

  /// No description provided for @noHelpTopicsMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Try a broader search term, or contact support if you need hands-on help.'**
  String get noHelpTopicsMatchBody;

  /// No description provided for @emailUnavailableWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Email unavailable'**
  String get emailUnavailableWarningTitle;

  /// No description provided for @noEmailAppAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'No email app is available on this device.'**
  String get noEmailAppAvailableBody;

  /// No description provided for @supportRequestSubject.
  ///
  /// In en, this message translates to:
  /// **'FutureGate Support Request'**
  String get supportRequestSubject;

  /// No description provided for @bugReportSubject.
  ///
  /// In en, this message translates to:
  /// **'FutureGate Bug Report'**
  String get bugReportSubject;

  /// No description provided for @helpAccountHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Help'**
  String get helpAccountHelpTitle;

  /// No description provided for @helpAccountCategory.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get helpAccountCategory;

  /// No description provided for @helpAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Update profile details, manage sign-in methods, and keep your student profile ready for new opportunities.'**
  String get helpAccountDescription;

  /// No description provided for @helpApplicationHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Application Help'**
  String get helpApplicationHelpTitle;

  /// No description provided for @helpApplicationCategory.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get helpApplicationCategory;

  /// No description provided for @helpApplicationDescription.
  ///
  /// In en, this message translates to:
  /// **'Track your submissions, review statuses, and understand what recruiters need to evaluate your profile.'**
  String get helpApplicationDescription;

  /// No description provided for @helpSavedItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Items'**
  String get helpSavedItemsTitle;

  /// No description provided for @helpSavedItemsCategory.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get helpSavedItemsCategory;

  /// No description provided for @helpSavedItemsDescription.
  ///
  /// In en, this message translates to:
  /// **'Bookmark opportunities you want to revisit later and stay organized while you prepare applications.'**
  String get helpSavedItemsDescription;

  /// No description provided for @helpCvBuilderTitle.
  ///
  /// In en, this message translates to:
  /// **'CV Studio'**
  String get helpCvBuilderTitle;

  /// No description provided for @helpCvBuilderCategory.
  ///
  /// In en, this message translates to:
  /// **'CV'**
  String get helpCvBuilderCategory;

  /// No description provided for @helpCvBuilderDescription.
  ///
  /// In en, this message translates to:
  /// **'Create structured CV content, choose a template, preview your document, and export a PDF when you are ready.'**
  String get helpCvBuilderDescription;

  /// No description provided for @helpOpportunityPostingTitle.
  ///
  /// In en, this message translates to:
  /// **'Opportunity Posting Help'**
  String get helpOpportunityPostingTitle;

  /// No description provided for @helpOpportunityCategory.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get helpOpportunityCategory;

  /// No description provided for @helpOpportunityDescription.
  ///
  /// In en, this message translates to:
  /// **'Learn how companies and approved listings appear inside the app so you can understand the platform flow end to end.'**
  String get helpOpportunityDescription;

  /// No description provided for @helpNotificationsCategory.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get helpNotificationsCategory;

  /// No description provided for @helpNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Stay on top of application decisions, saved item changes, reminders, and platform alerts.'**
  String get helpNotificationsDescription;

  /// No description provided for @aboutBridgeDescription.
  ///
  /// In en, this message translates to:
  /// **'FutureGate is designed as a bridge between students, their growing skills, and the real opportunities that can shape their next milestone.'**
  String get aboutBridgeDescription;

  /// No description provided for @platformStoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform Story'**
  String get platformStoryTitle;

  /// No description provided for @platformStorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'A clearer path from student ambition to real-world opportunity.'**
  String get platformStorySubtitle;

  /// No description provided for @platformStoryBody.
  ///
  /// In en, this message translates to:
  /// **'The app brings together profiles, CV tools, opportunities, scholarships, project ideas, and communication so students can move from discovery to action in one place.'**
  String get platformStoryBody;

  /// No description provided for @moreInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'More Information'**
  String get moreInformationTitle;

  /// No description provided for @moreInformationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Useful references and contact points for the platform.'**
  String get moreInformationSubtitle;

  /// No description provided for @termsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get termsAboutTitle;

  /// No description provided for @termsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read the platform usage summary'**
  String get termsAboutSubtitle;

  /// No description provided for @termsAboutBody.
  ///
  /// In en, this message translates to:
  /// **'FutureGate expects accurate profiles, respectful communication, and responsible use of the application and content tools available in the app.'**
  String get termsAboutBody;

  /// No description provided for @privacyPolicyAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See how data supports the experience'**
  String get privacyPolicyAboutSubtitle;

  /// No description provided for @privacyPolicyAboutBody.
  ///
  /// In en, this message translates to:
  /// **'Profile, CV, notification, and application data are used only to provide the matching, review, and communication features that power the FutureGate experience.'**
  String get privacyPolicyAboutBody;

  /// No description provided for @contactAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactAboutTitle;

  /// No description provided for @websiteSocialTitle.
  ///
  /// In en, this message translates to:
  /// **'Website & Social'**
  String get websiteSocialTitle;

  /// No description provided for @websiteSocialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Public links are added here as they go live'**
  String get websiteSocialSubtitle;

  /// No description provided for @websiteSocialBody.
  ///
  /// In en, this message translates to:
  /// **'A public website and social channels are not linked inside this build yet. Support requests can still be sent directly by email.'**
  String get websiteSocialBody;

  /// No description provided for @noEmailAppAvailableAltBody.
  ///
  /// In en, this message translates to:
  /// **'No email app is available right now.'**
  String get noEmailAppAvailableAltBody;

  /// No description provided for @aboutFutureGateSubject.
  ///
  /// In en, this message translates to:
  /// **'About FutureGate'**
  String get aboutFutureGateSubject;

  /// No description provided for @signOutAdminQuestion.
  ///
  /// In en, this message translates to:
  /// **'Sign out of admin?'**
  String get signOutAdminQuestion;

  /// No description provided for @signOutAdminBody.
  ///
  /// In en, this message translates to:
  /// **'You will leave the admin workspace on this device. Saved changes stay safe.'**
  String get signOutAdminBody;

  /// No description provided for @signOutCompanyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Sign out of company?'**
  String get signOutCompanyQuestion;

  /// No description provided for @signOutCompanyBody.
  ///
  /// In en, this message translates to:
  /// **'You will leave the company workspace on this device. Your profile and opportunities stay saved.'**
  String get signOutCompanyBody;

  /// No description provided for @signOutStudentQuestion.
  ///
  /// In en, this message translates to:
  /// **'Sign out of student?'**
  String get signOutStudentQuestion;

  /// No description provided for @signOutStudentBody.
  ///
  /// In en, this message translates to:
  /// **'You will leave your student workspace on this device. Your profile and saved items stay safe.'**
  String get signOutStudentBody;

  /// No description provided for @signOutFutureGateQuestion.
  ///
  /// In en, this message translates to:
  /// **'Sign out of FutureGate?'**
  String get signOutFutureGateQuestion;

  /// No description provided for @signOutFutureGateBody.
  ///
  /// In en, this message translates to:
  /// **'You can sign back in anytime with the same account.'**
  String get signOutFutureGateBody;

  /// No description provided for @adminRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRoleLabel;

  /// No description provided for @companyRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get companyRoleLabel;

  /// No description provided for @studentRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get studentRoleLabel;

  /// No description provided for @accountRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountRoleLabel;

  /// No description provided for @signingOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Signing out'**
  String get signingOutLabel;

  /// No description provided for @futureGateAccountFallback.
  ///
  /// In en, this message translates to:
  /// **'FutureGate account'**
  String get futureGateAccountFallback;

  /// No description provided for @studentHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your daily student pulse, shortcuts, and fresh momentum.'**
  String get studentHomeSubtitle;

  /// No description provided for @studentDiscoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Jobs, internships, and sponsored tracks matched to your next move.'**
  String get studentDiscoverSubtitle;

  /// No description provided for @studentScholarshipsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Funding opportunities, deadlines, and global study paths.'**
  String get studentScholarshipsSubtitle;

  /// No description provided for @studentTrainingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Courses, books, and certifications that sharpen your journey.'**
  String get studentTrainingSubtitle;

  /// No description provided for @studentIdeasSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build, save, and grow your next project idea with confidence.'**
  String get studentIdeasSubtitle;

  /// No description provided for @studentChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay close to conversations, follow-ups, and collaboration.'**
  String get studentChatSubtitle;

  /// No description provided for @notificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTooltip;

  /// No description provided for @savedScholarshipsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Saved scholarships'**
  String get savedScholarshipsTooltip;

  /// No description provided for @savedTrainingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Saved training'**
  String get savedTrainingTooltip;

  /// No description provided for @savedIdeasTooltip.
  ///
  /// In en, this message translates to:
  /// **'Saved ideas'**
  String get savedIdeasTooltip;

  /// No description provided for @deadlineSoon.
  ///
  /// In en, this message translates to:
  /// **'Deadline soon'**
  String get deadlineSoon;

  /// No description provided for @fundingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Funding: {amount}'**
  String fundingPrefix(Object amount);

  /// No description provided for @savedOpportunityFallback.
  ///
  /// In en, this message translates to:
  /// **'Saved opportunity'**
  String get savedOpportunityFallback;

  /// No description provided for @closingSoonBadge.
  ///
  /// In en, this message translates to:
  /// **'Closing soon'**
  String get closingSoonBadge;

  /// No description provided for @savedTypeBadge.
  ///
  /// In en, this message translates to:
  /// **'Saved {type}'**
  String savedTypeBadge(Object type);

  /// No description provided for @savedTypeFromCompany.
  ///
  /// In en, this message translates to:
  /// **'Saved {type} from {company}'**
  String savedTypeFromCompany(Object type, Object company);

  /// No description provided for @savedTypeNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Saved {type} that needs attention'**
  String savedTypeNeedsAttention(Object type);

  /// No description provided for @closesDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Closes {date}'**
  String closesDateLabel(Object date);

  /// No description provided for @muteChatLabel.
  ///
  /// In en, this message translates to:
  /// **'Mute Chat'**
  String get muteChatLabel;

  /// No description provided for @unmuteChatLabel.
  ///
  /// In en, this message translates to:
  /// **'Unmute Chat'**
  String get unmuteChatLabel;

  /// No description provided for @chatMutedTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat muted'**
  String get chatMutedTitle;

  /// No description provided for @chatUnmutedTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat unmuted'**
  String get chatUnmutedTitle;

  /// No description provided for @chatMutedBody.
  ///
  /// In en, this message translates to:
  /// **'Notifications for this chat are now muted.'**
  String get chatMutedBody;

  /// No description provided for @chatUnmutedBody.
  ///
  /// In en, this message translates to:
  /// **'Chat notifications are active again.'**
  String get chatUnmutedBody;

  /// No description provided for @uiOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get uiOpen;

  /// No description provided for @uiViewAllApps.
  ///
  /// In en, this message translates to:
  /// **'View All Apps'**
  String get uiViewAllApps;

  /// No description provided for @uiViewApplicationsCount.
  ///
  /// In en, this message translates to:
  /// **'View Applications ({count})'**
  String uiViewApplicationsCount(Object count);

  /// No description provided for @openLibraryStudioLabel.
  ///
  /// In en, this message translates to:
  /// **'Open Library Studio'**
  String get openLibraryStudioLabel;

  /// No description provided for @noScholarshipLinkAvailable.
  ///
  /// In en, this message translates to:
  /// **'No scholarship link is available for this item yet.'**
  String get noScholarshipLinkAvailable;

  /// No description provided for @couldNotOpenScholarshipLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the scholarship link.'**
  String get couldNotOpenScholarshipLink;

  /// No description provided for @editMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessageLabel;

  /// No description provided for @noRecentUsersYet.
  ///
  /// In en, this message translates to:
  /// **'No recent users yet'**
  String get noRecentUsersYet;

  /// No description provided for @uiBachelor.
  ///
  /// In en, this message translates to:
  /// **'Bachelor'**
  String get uiBachelor;

  /// Success title when an opportunity is closed
  ///
  /// In en, this message translates to:
  /// **'Opportunity closed'**
  String get uiOpportunityClosed;

  /// Success title when an opportunity is deleted
  ///
  /// In en, this message translates to:
  /// **'Opportunity deleted'**
  String get uiOpportunityDeleted;

  /// Success message when deleting an opportunity closes it because applications already exist
  ///
  /// In en, this message translates to:
  /// **'Opportunity closed because applications already exist.'**
  String get uiOpportunityClosedBecauseApplicationsAlreadyExist;

  /// Generic error message when a document cannot be opened
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open the document right now.'**
  String get uiCouldNotOpenTheDocumentRightNow;

  /// Generic error message when a link cannot be opened
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open this link right now.'**
  String get uiWeCouldNotOpenThisLinkRightNow;

  /// Success message when a resource is removed from featured
  ///
  /// In en, this message translates to:
  /// **'This resource was removed from featured.'**
  String get uiResourceRemovedFromFeatured;

  /// Success message when a resource is added to featured
  ///
  /// In en, this message translates to:
  /// **'This resource is now featured.'**
  String get uiResourceFeatured;

  /// Label shown when there is no uploaded CV file
  ///
  /// In en, this message translates to:
  /// **'No uploaded CV'**
  String get uiNoUploadedCv;

  /// Status message when a built CV PDF is available
  ///
  /// In en, this message translates to:
  /// **'Built CV PDF is ready for review.'**
  String get uiBuiltCvPdfReadyForReview;

  /// Status message when built CV content exists without an exported PDF
  ///
  /// In en, this message translates to:
  /// **'Built CV details are available, but no PDF has been exported yet.'**
  String get uiBuiltCvDetailsAvailableNoPdfYet;

  /// Status message when no built CV data exists
  ///
  /// In en, this message translates to:
  /// **'No built CV details available.'**
  String get uiNoBuiltCvDetailsAvailable;

  /// Success title when a conversation is archived
  ///
  /// In en, this message translates to:
  /// **'Conversation archived'**
  String get uiConversationArchived;

  /// Success title when a conversation is restored from archive
  ///
  /// In en, this message translates to:
  /// **'Conversation restored'**
  String get uiConversationRestored;

  /// Success message when a conversation is archived
  ///
  /// In en, this message translates to:
  /// **'This conversation has been moved to Archived.'**
  String get uiConversationMovedToArchived;

  /// Success message when a conversation is restored to the inbox
  ///
  /// In en, this message translates to:
  /// **'This conversation is back in your inbox.'**
  String get uiConversationBackInInbox;

  /// Warning shown when the user tries to use AI tools without a message
  ///
  /// In en, this message translates to:
  /// **'Write a message before using AI tools.'**
  String get uiWriteMessageBeforeAiTools;

  /// Warning shown when the user opens translation choices without a message
  ///
  /// In en, this message translates to:
  /// **'Write a message before choosing a translation.'**
  String get uiWriteMessageBeforeTranslation;

  /// Subtitle showing the number of unread alerts
  ///
  /// In en, this message translates to:
  /// **'{count} unread alerts'**
  String uiUnreadAlertsCount(Object count);

  /// Subtitle for the notifications quick access tile
  ///
  /// In en, this message translates to:
  /// **'Open alert center'**
  String get uiOpenAlertCenter;

  /// Quick access subtitle for learning resources management
  ///
  /// In en, this message translates to:
  /// **'Manage learning resources'**
  String get uiManageLearningResources;

  /// Action label to manage an application
  ///
  /// In en, this message translates to:
  /// **'Manage Application'**
  String get uiManageApplication;

  /// Action label to manage an opportunity
  ///
  /// In en, this message translates to:
  /// **'Manage Opportunity'**
  String get uiManageOpportunity;

  /// Action label to manage a scholarship
  ///
  /// In en, this message translates to:
  /// **'Manage Scholarship'**
  String get uiManageScholarship;

  /// Action label to manage a library resource
  ///
  /// In en, this message translates to:
  /// **'Manage Library Resource'**
  String get uiManageLibraryResource;

  /// Action label to manage a project idea
  ///
  /// In en, this message translates to:
  /// **'Manage Project Idea'**
  String get uiManageProjectIdea;

  /// Label showing the number of recent activities
  ///
  /// In en, this message translates to:
  /// **'{count} recent activities'**
  String uiRecentActivitiesCount(Object count);

  /// Label showing the number of activities matching a search
  ///
  /// In en, this message translates to:
  /// **'{count} matching activities'**
  String uiMatchingActivitiesCount(Object count);

  /// Submit label when saving changes to an idea
  ///
  /// In en, this message translates to:
  /// **'Save idea changes'**
  String get saveIdeaChangesLabel;

  /// Opportunity editor subtitle in edit mode
  ///
  /// In en, this message translates to:
  /// **'Update the fields below and save.'**
  String get uiUpdateTheFieldsBelowAndSave;

  /// Opportunity editor subtitle in create mode
  ///
  /// In en, this message translates to:
  /// **'Fill in the fields below, then publish.'**
  String get uiFillInTheFieldsBelowThenPublish;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Book Library'**
  String get uiBookLibrary;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Featured Resources'**
  String get uiFeaturedResources;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Hidden Resources'**
  String get uiHiddenResources;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'No featured resources match this search'**
  String get uiNoFeaturedResourcesMatchThisSearch;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'No hidden resources match this search'**
  String get uiNoHiddenResourcesMatchThisSearch;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'No library resources match this search'**
  String get uiNoLibraryResourcesMatchThisSearch;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'This resource link is invalid.'**
  String get uiThisResourceLinkIsInvalid;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'This resource is visible again.'**
  String get uiThisResourceIsVisibleAgain;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'This resource was hidden. You can restore it later.'**
  String get uiThisResourceWasHiddenYouCanRestoreItLater;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Resource visible'**
  String get uiResourceVisible;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Resource hidden'**
  String get uiResourceHidden;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Unknown provider'**
  String get uiUnknownProvider;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Keep books and video resources in one admin-friendly library, then open the source studios only when you need new imports.'**
  String
  get uiKeepBooksAndVideoResourcesInOneAdminFriendlyLibraryThenOpenTheSourceStudiosOnlyWhenYouNeedNewImports;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Library now holds all learning resources. Search, filter, review details, and jump into import studios when you need to add more.'**
  String
  get uiLibraryNowHoldsAllLearningResourcesSearchFilterReviewDetailsAndJumpIntoImportStudiosWhenYouNeedToAddMore;

  /// Subtitle shown when the admin library is filtered by a search query.
  ///
  /// In en, this message translates to:
  /// **'Showing filtered results for \"{searchQuery}\".'**
  String uiShowingFilteredResultsForSearchQuery(Object searchQuery);

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Search library by title, provider, domain, level, or source...'**
  String get uiSearchLibraryByTitleProviderDomainLevelOrSource;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get uiHide;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Unhide'**
  String get uiUnhide;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Library unavailable'**
  String get uiLibraryUnavailable;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get uiLanguage;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get uiSearching;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get uiImport;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get uiImporting;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get uiSyncing;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get uiSynced;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Student Details'**
  String get uiStudentDetails;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Review identity, academic details, CV documents, and visible submitted applications in one place.'**
  String
  get uiReviewIdentityAcademicDetailsCvDocumentsAndVisibleSubmittedApplicationsInOnePlace;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Review the uploaded CV and the built CV export without leaving the student profile.'**
  String
  get uiReviewTheUploadedCvAndTheBuiltCvExportWithoutLeavingTheStudentProfile;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'No CV has been created for this student.'**
  String get uiNoCvHasBeenCreatedForThisStudent;

  /// Label showing the primary CV file name.
  ///
  /// In en, this message translates to:
  /// **'Primary CV: {value}'**
  String uiPrimaryCvValue(Object value);

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Primary CV not uploaded'**
  String get uiPrimaryCvNotUploaded;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Built CV unavailable'**
  String get uiBuiltCvUnavailable;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Built CV PDF available'**
  String get uiBuiltCvPdfAvailable;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Built CV information available'**
  String get uiBuiltCvInformationAvailable;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Loading visible applications...'**
  String get uiLoadingVisibleApplications;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Application history is unavailable right now.'**
  String get uiApplicationHistoryIsUnavailableRightNow;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'No visible applications available for this student.'**
  String get uiNoVisibleApplicationsAvailableForThisStudent;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'1 visible application'**
  String get uiOneVisibleApplication;

  /// Count of visible applications for a student.
  ///
  /// In en, this message translates to:
  /// **'{count} visible applications'**
  String uiVisibleApplicationsCount(Object count);

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Student Applications'**
  String get uiStudentApplications;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Open the student application history using the same visible-opportunity rule shown in the app.'**
  String
  get uiReviewTheStudentApplicationHistoryUsingTheSameVisibleOpportunityRuleShownInTheApp;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Visible submissions'**
  String get uiVisibleSubmissions;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'We could not load the application count right now. You can still open the applications sheet and try again.'**
  String
  get uiCouldNotLoadApplicationCountRightNowYouCanStillOpenTheApplicationsSheetAndTryAgain;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Student profile available for admin review.'**
  String get uiStudentProfileAvailableForAdminReview;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Application history unavailable'**
  String get uiApplicationHistoryUnavailable;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'No visible applications'**
  String get uiNoVisibleApplications;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Loading visible opportunity applications.'**
  String get uiLoadingVisibleOpportunityApplications;

  /// Count of visible applications available for review.
  ///
  /// In en, this message translates to:
  /// **'{count} visible applications available for review.'**
  String uiVisibleApplicationsAvailableForReviewCount(Object count);

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'We could not load this student\'s visible applications right now.'**
  String get uiCouldNotLoadThisStudentsVisibleApplicationsRightNow;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'This student has no applications linked to open and visible opportunities right now.'**
  String
  get uiThisStudentHasNoApplicationsLinkedToOpenAndVisibleOpportunitiesRightNow;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Applied date unavailable'**
  String get uiAppliedDateUnavailable;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Permission denied while opening the document.'**
  String get uiPermissionDeniedWhileOpeningTheDocument;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'The requested document is no longer available.'**
  String get uiTheRequestedDocumentIsNoLongerAvailable;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get uiNotProvided;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get uiStudent;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get uiBlocked;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Use a topic, domain, or language filter to bring in curated books for review.'**
  String get uiUseATopicDomainOrLanguageFilterToBringInCuratedBooksForReview;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Try a broader query or change the language and domain filters before searching again.'**
  String
  get uiTryABroaderQueryOrChangeTheLanguageAndDomainFiltersBeforeSearchingAgain;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'This workspace is dedicated to Google Books imports, so book curation stays focused.'**
  String
  get uiThisWorkspaceIsDedicatedToGoogleBooksImportsSoBookCurationStaysFocused;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Use a topic search to bring back import-ready videos for review.'**
  String get uiUseATopicSearchToBringBackImportReadyVideosForReview;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Try a broader query or switch the domain and level context before searching again.'**
  String
  get uiTryABroaderQueryOrSwitchTheDomainAndLevelContextBeforeSearchingAgain;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'This workspace is dedicated to YouTube imports, so video curation stays focused.'**
  String
  get uiThisWorkspaceIsDedicatedToYouTubeImportsSoVideoCurationStaysFocused;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Video Library'**
  String get uiVideoLibrary;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Learning Resources'**
  String get uiLearningResources;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Primary CV'**
  String get uiPrimaryCv;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Try another search or relax the current role and level filters.'**
  String get uiTryAnotherSearchOrRelaxTheCurrentRoleAndLevelFilters;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Review contact info, account status, and role-specific details in one clean profile view.'**
  String
  get uiReviewContactInfoAccountStatusAndRoleSpecificDetailsInOneCleanProfileView;

  /// Admin localization label.
  ///
  /// In en, this message translates to:
  /// **'Update the company approval state from here without leaving the profile.'**
  String get uiUpdateTheCompanyApprovalStateFromHereWithoutLeavingTheProfile;

  /// Label for device/system default locale option
  ///
  /// In en, this message translates to:
  /// **'Device Default'**
  String get languageDeviceDefault;

  /// uiSponsored
  ///
  /// In en, this message translates to:
  /// **'Sponsored'**
  String get uiSponsored;

  /// uiClosed
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get uiClosed;

  /// uiCourse
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get uiCourse;

  /// uiVideo
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get uiVideo;

  /// uiBook
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get uiBook;

  /// uiGuide
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get uiGuide;

  /// uiProgram
  ///
  /// In en, this message translates to:
  /// **'Program'**
  String get uiProgram;

  /// uiTrain
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get uiTrain;

  /// uiCategory
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get uiCategory;

  /// uiDeadline
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get uiDeadline;

  /// uiDuration
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get uiDuration;

  /// uiWorkMode
  ///
  /// In en, this message translates to:
  /// **'Work mode'**
  String get uiWorkMode;

  /// uiEmploymentType
  ///
  /// In en, this message translates to:
  /// **'Employment type'**
  String get uiEmploymentType;

  /// uiPaidStatus
  ///
  /// In en, this message translates to:
  /// **'Paid status'**
  String get uiPaidStatus;

  /// uiTags
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get uiTags;

  /// uiLoginRequired
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get uiLoginRequired;

  /// uiUploadUnavailable
  ///
  /// In en, this message translates to:
  /// **'Upload unavailable'**
  String get uiUploadUnavailable;

  /// uiUploadInProgress
  ///
  /// In en, this message translates to:
  /// **'Upload in progress'**
  String get uiUploadInProgress;

  /// uiUpdateUnavailable
  ///
  /// In en, this message translates to:
  /// **'Update unavailable'**
  String get uiUpdateUnavailable;

  /// uiEditingLocked
  ///
  /// In en, this message translates to:
  /// **'Editing locked'**
  String get uiEditingLocked;

  /// uiSubmissionUnavailable
  ///
  /// In en, this message translates to:
  /// **'Submission unavailable'**
  String get uiSubmissionUnavailable;

  /// uiNoUrgentDeadlines
  ///
  /// In en, this message translates to:
  /// **'No urgent deadlines right now'**
  String get uiNoUrgentDeadlines;

  /// uiNoRecommendations
  ///
  /// In en, this message translates to:
  /// **'No recommendations right now'**
  String get uiNoRecommendations;

  /// uiCheckBackSoon
  ///
  /// In en, this message translates to:
  /// **'Check back soon for fresh curated opportunities.'**
  String get uiCheckBackSoon;

  /// uiNoRecentActivity
  ///
  /// In en, this message translates to:
  /// **'No recent activity yet'**
  String get uiNoRecentActivity;

  /// uiNoTrendingOpportunities
  ///
  /// In en, this message translates to:
  /// **'No trending opportunities right now'**
  String get uiNoTrendingOpportunities;

  /// uiNoOpportunitiesMatchView
  ///
  /// In en, this message translates to:
  /// **'No opportunities match this view'**
  String get uiNoOpportunitiesMatchView;

  /// uiNoIdeasMatchView
  ///
  /// In en, this message translates to:
  /// **'No ideas match this view'**
  String get uiNoIdeasMatchView;

  /// uiNoTrainingAvailableNow
  ///
  /// In en, this message translates to:
  /// **'No training programs available right now'**
  String get uiNoTrainingAvailableNow;

  /// uiNoTrainingInTopic
  ///
  /// In en, this message translates to:
  /// **'No training programs available in this topic'**
  String get uiNoTrainingInTopic;

  /// uiLoadingApplications
  ///
  /// In en, this message translates to:
  /// **'Loading your applications...'**
  String get uiLoadingApplications;

  /// uiLoadingSavedItems
  ///
  /// In en, this message translates to:
  /// **'Loading your saved items...'**
  String get uiLoadingSavedItems;

  /// uiBuildCvFirst
  ///
  /// In en, this message translates to:
  /// **'Build your CV first.'**
  String get uiBuildCvFirst;

  /// uiCompleteProfile
  ///
  /// In en, this message translates to:
  /// **'Complete your profile.'**
  String get uiCompleteProfile;

  /// uiActBeforeDeadlines
  ///
  /// In en, this message translates to:
  /// **'Act before deadlines close.'**
  String get uiActBeforeDeadlines;

  /// uiShortlistReady
  ///
  /// In en, this message translates to:
  /// **'Your shortlist is ready.'**
  String get uiShortlistReady;

  /// uiRevisitSavedPicks
  ///
  /// In en, this message translates to:
  /// **'Revisit saved picks before the strongest deadlines slip by.'**
  String get uiRevisitSavedPicks;

  /// uiFindNextOpportunity
  ///
  /// In en, this message translates to:
  /// **'Find your next best opportunity.'**
  String get uiFindNextOpportunity;

  /// uiJumpBackBookmarked
  ///
  /// In en, this message translates to:
  /// **'Jump back into everything you bookmarked.'**
  String get uiJumpBackBookmarked;

  /// uiRemote
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get uiRemote;

  /// uiPaid
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get uiPaid;

  /// uiNotifications
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get uiNotifications;

  /// uiSettings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get uiSettings;

  /// uiAboutFutureGate
  ///
  /// In en, this message translates to:
  /// **'About FutureGate'**
  String get uiAboutFutureGate;

  /// uiSettingsSubtitle
  ///
  /// In en, this message translates to:
  /// **'Preferences, display, and app choices.'**
  String get uiSettingsSubtitle;

  /// uiSecuritySubtitle
  ///
  /// In en, this message translates to:
  /// **'Password and account protection.'**
  String get uiSecuritySubtitle;

  /// uiHelpCenterSubtitle
  ///
  /// In en, this message translates to:
  /// **'Answers, guidance, and support.'**
  String get uiHelpCenterSubtitle;

  /// uiAboutSubtitle
  ///
  /// In en, this message translates to:
  /// **'Learn more about the platform.'**
  String get uiAboutSubtitle;

  /// uiSignOutSubtitle
  ///
  /// In en, this message translates to:
  /// **'End this session on the current device.'**
  String get uiSignOutSubtitle;

  /// uiExperience
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get uiExperience;

  /// uiBriefSummary
  ///
  /// In en, this message translates to:
  /// **'A brief summary of your profile'**
  String get uiBriefSummary;

  /// uiAddSkill
  ///
  /// In en, this message translates to:
  /// **'Add a skill'**
  String get uiAddSkill;

  /// uiCvPreviewSubtitle
  ///
  /// In en, this message translates to:
  /// **'Review the final layout before you save or download it.'**
  String get uiCvPreviewSubtitle;

  /// uiChooseTemplateSubtitle
  ///
  /// In en, this message translates to:
  /// **'Pick the resume style that best fits the role you want.'**
  String get uiChooseTemplateSubtitle;

  /// uiProvider
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get uiProvider;

  /// uiApplicationDeadline
  ///
  /// In en, this message translates to:
  /// **'Application deadline'**
  String get uiApplicationDeadline;

  /// uiFundingType
  ///
  /// In en, this message translates to:
  /// **'Funding type'**
  String get uiFundingType;

  /// uiAmount
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get uiAmount;

  /// uiSearchCourses
  ///
  /// In en, this message translates to:
  /// **'Search for courses...'**
  String get uiSearchCourses;

  /// uiSelectCategory
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get uiSelectCategory;

  /// uiSelectStage
  ///
  /// In en, this message translates to:
  /// **'Select stage'**
  String get uiSelectStage;

  /// uiPublish
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get uiPublish;

  /// uiHiddenLabel
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get uiHiddenLabel;

  /// uiSearchPrograms
  ///
  /// In en, this message translates to:
  /// **'Search programs, partners...'**
  String get uiSearchPrograms;

  /// uiInternshipsSubtitle
  ///
  /// In en, this message translates to:
  /// **'Hands-on student placements'**
  String get uiInternshipsSubtitle;

  /// uiSponsoredSubtitle
  ///
  /// In en, this message translates to:
  /// **'Partner-backed support'**
  String get uiSponsoredSubtitle;

  /// uiTryDifferentFilter
  ///
  /// In en, this message translates to:
  /// **'Try a different filter or start a new idea.'**
  String get uiTryDifferentFilter;

  /// uiCreateFirstIdea
  ///
  /// In en, this message translates to:
  /// **'Create your first idea or adjust the filters.'**
  String get uiCreateFirstIdea;

  /// uiCvStudioSubtitle
  ///
  /// In en, this message translates to:
  /// **'Build, upload, and export your CV.'**
  String get uiCvStudioSubtitle;

  /// notifAdminTitle
  ///
  /// In en, this message translates to:
  /// **'Admin Notifications'**
  String get notifAdminTitle;

  /// notifCompanyTitle
  ///
  /// In en, this message translates to:
  /// **'Company Notifications'**
  String get notifCompanyTitle;

  /// notifReadAll
  ///
  /// In en, this message translates to:
  /// **'Read all'**
  String get notifReadAll;

  /// notifFilterAll
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notifFilterAll;

  /// notifFilterNewContent
  ///
  /// In en, this message translates to:
  /// **'New content'**
  String get notifFilterNewContent;

  /// notifFilterUnread
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get notifFilterUnread;

  /// notifFilterApplications
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get notifFilterApplications;

  /// notifFilterMessages
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notifFilterMessages;

  /// notifContentAll
  ///
  /// In en, this message translates to:
  /// **'All new'**
  String get notifContentAll;

  /// notifContentOpportunities
  ///
  /// In en, this message translates to:
  /// **'Opportunities'**
  String get notifContentOpportunities;

  /// notifContentTrainings
  ///
  /// In en, this message translates to:
  /// **'Trainings'**
  String get notifContentTrainings;

  /// notifContentScholarships
  ///
  /// In en, this message translates to:
  /// **'Scholarships'**
  String get notifContentScholarships;

  /// notifContentIdeas
  ///
  /// In en, this message translates to:
  /// **'Ideas'**
  String get notifContentIdeas;

  /// notifOppAll
  ///
  /// In en, this message translates to:
  /// **'All Opportunities'**
  String get notifOppAll;

  /// notifOppJobs
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get notifOppJobs;

  /// notifOppInternships
  ///
  /// In en, this message translates to:
  /// **'Internships'**
  String get notifOppInternships;

  /// notifOppSponsored
  ///
  /// In en, this message translates to:
  /// **'Sponsored'**
  String get notifOppSponsored;

  /// notifAllCaughtUp
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get notifAllCaughtUp;

  /// notifTypeMessage
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get notifTypeMessage;

  /// notifTypeApplication
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get notifTypeApplication;

  /// notifTypeOpportunity
  ///
  /// In en, this message translates to:
  /// **'Opportunity'**
  String get notifTypeOpportunity;

  /// notifTypeScholarship
  ///
  /// In en, this message translates to:
  /// **'Scholarship'**
  String get notifTypeScholarship;

  /// notifTypeTraining
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get notifTypeTraining;

  /// notifTypeIdea
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get notifTypeIdea;

  /// notifTypeCompanyReview
  ///
  /// In en, this message translates to:
  /// **'Company review'**
  String get notifTypeCompanyReview;

  /// notifTypeUpdate
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get notifTypeUpdate;

  /// notifJustNow
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notifJustNow;

  /// postingLanguageLabel
  ///
  /// In en, this message translates to:
  /// **'Posting language'**
  String get postingLanguageLabel;

  /// postingLanguageHint
  ///
  /// In en, this message translates to:
  /// **'Language this content is written in'**
  String get postingLanguageHint;

  /// translateLabel
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translateLabel;

  /// translatingLabel
  ///
  /// In en, this message translates to:
  /// **'Translating...'**
  String get translatingLabel;

  /// translationDoneLabel
  ///
  /// In en, this message translates to:
  /// **'Translation ready'**
  String get translationDoneLabel;

  /// translationFailedLabel
  ///
  /// In en, this message translates to:
  /// **'Translation unavailable'**
  String get translationFailedLabel;

  /// showOriginalLabel
  ///
  /// In en, this message translates to:
  /// **'Show original'**
  String get showOriginalLabel;

  /// showTranslatedLabel
  ///
  /// In en, this message translates to:
  /// **'Show translated'**
  String get showTranslatedLabel;

  /// contentLanguageLabel
  ///
  /// In en, this message translates to:
  /// **'Content language'**
  String get contentLanguageLabel;

  /// autoTranslatedBadge
  ///
  /// In en, this message translates to:
  /// **'Auto-translated'**
  String get autoTranslatedBadge;

  /// translatedBadge
  ///
  /// In en, this message translates to:
  /// **'Translated'**
  String get translatedBadge;

  /// originalBadge
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get originalBadge;

  /// translationNote
  ///
  /// In en, this message translates to:
  /// **'This content was automatically translated. Tap \"Show original\" to see the source.'**
  String get translationNote;

  /// dashSectionClosingSoon
  ///
  /// In en, this message translates to:
  /// **'Closing Soon'**
  String get dashSectionClosingSoon;

  /// dashSectionRecommended
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get dashSectionRecommended;

  /// dashSectionQuickAccess
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get dashSectionQuickAccess;

  /// dashSectionLatestActivity
  ///
  /// In en, this message translates to:
  /// **'Latest Activities'**
  String get dashSectionLatestActivity;

  /// dashSectionSavedShortlist
  ///
  /// In en, this message translates to:
  /// **'Saved shortlist'**
  String get dashSectionSavedShortlist;

  /// dashBuildCv
  ///
  /// In en, this message translates to:
  /// **'Build CV'**
  String get dashBuildCv;

  /// dashCompleteProfile
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get dashCompleteProfile;

  /// dashDiscover
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get dashDiscover;

  /// dashViewStatus
  ///
  /// In en, this message translates to:
  /// **'View Status'**
  String get dashViewStatus;

  /// dashTrackStatus
  ///
  /// In en, this message translates to:
  /// **'Track Status'**
  String get dashTrackStatus;

  /// dashSeeOpenRoles
  ///
  /// In en, this message translates to:
  /// **'See Open Roles'**
  String get dashSeeOpenRoles;

  /// dashOpenSaved
  ///
  /// In en, this message translates to:
  /// **'Open Saved'**
  String get dashOpenSaved;

  /// scholarshipOpportunityFallback
  ///
  /// In en, this message translates to:
  /// **'Scholarship Opportunity'**
  String get scholarshipOpportunityFallback;

  /// scholarshipPartnerFallback
  ///
  /// In en, this message translates to:
  /// **'FutureGate Partner'**
  String get scholarshipPartnerFallback;

  /// scholarshipNoDescFallback
  ///
  /// In en, this message translates to:
  /// **'This scholarship does not include a detailed description yet.'**
  String get scholarshipNoDescFallback;

  /// scholarshipNoEligFallback
  ///
  /// In en, this message translates to:
  /// **'Eligibility details will be shared by the scholarship provider.'**
  String get scholarshipNoEligFallback;

  /// scholarshipDeadlineFallback
  ///
  /// In en, this message translates to:
  /// **'Provider-announced deadline'**
  String get scholarshipDeadlineFallback;

  /// scholarshipFundingFallback
  ///
  /// In en, this message translates to:
  /// **'Funding shared on the official call'**
  String get scholarshipFundingFallback;

  /// scholarshipFeaturedBadge
  ///
  /// In en, this message translates to:
  /// **'FEATURED'**
  String get scholarshipFeaturedBadge;

  /// scholarshipDefaultBadge
  ///
  /// In en, this message translates to:
  /// **'SCHOLARSHIP'**
  String get scholarshipDefaultBadge;

  /// scholarshipFundingAmount
  ///
  /// In en, this message translates to:
  /// **'Funding Amount'**
  String get scholarshipFundingAmount;

  /// scholarshipFundingDetails
  ///
  /// In en, this message translates to:
  /// **'Funding Details'**
  String get scholarshipFundingDetails;

  /// scholarshipStudyLevel
  ///
  /// In en, this message translates to:
  /// **'Study Level'**
  String get scholarshipStudyLevel;

  /// scholarshipProgramType
  ///
  /// In en, this message translates to:
  /// **'Program Type'**
  String get scholarshipProgramType;

  /// scholarshipAtAGlance
  ///
  /// In en, this message translates to:
  /// **'AT A GLANCE'**
  String get scholarshipAtAGlance;

  /// scholarshipNoLink
  ///
  /// In en, this message translates to:
  /// **'The provider has not attached an external application link yet.'**
  String get scholarshipNoLink;

  /// scholarshipOfficialSource
  ///
  /// In en, this message translates to:
  /// **'Official scholarship source'**
  String get scholarshipOfficialSource;

  /// scholarshipOpenPage
  ///
  /// In en, this message translates to:
  /// **'Open Official Page'**
  String get scholarshipOpenPage;

  /// scholarshipLinkUnavailable
  ///
  /// In en, this message translates to:
  /// **'Link Not Available'**
  String get scholarshipLinkUnavailable;

  /// ideaNotAvailable
  ///
  /// In en, this message translates to:
  /// **'This idea is no longer available.'**
  String get ideaNotAvailable;

  /// ideaHubTitle
  ///
  /// In en, this message translates to:
  /// **'Innovation Hub'**
  String get ideaHubTitle;

  /// ideaUnsaveTooltip
  ///
  /// In en, this message translates to:
  /// **'Unsave idea'**
  String get ideaUnsaveTooltip;

  /// ideaSaveTooltip
  ///
  /// In en, this message translates to:
  /// **'Save idea'**
  String get ideaSaveTooltip;

  /// ideaEditLabel
  ///
  /// In en, this message translates to:
  /// **'Edit Idea'**
  String get ideaEditLabel;

  /// ideaManageLabel
  ///
  /// In en, this message translates to:
  /// **'Manage This Idea'**
  String get ideaManageLabel;

  /// ideaInterestedLabel
  ///
  /// In en, this message translates to:
  /// **'Interested'**
  String get ideaInterestedLabel;

  /// ideaImInterestedLabel
  ///
  /// In en, this message translates to:
  /// **'I\'m Interested'**
  String get ideaImInterestedLabel;

  /// ideaManageTeamLabel
  ///
  /// In en, this message translates to:
  /// **'Manage Team'**
  String get ideaManageTeamLabel;

  /// ideaContactCreator
  ///
  /// In en, this message translates to:
  /// **'View Creator Profile'**
  String get ideaContactCreator;

  /// ideaSavedLabel
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get ideaSavedLabel;

  /// ideaSaveLabel
  ///
  /// In en, this message translates to:
  /// **'Save Idea'**
  String get ideaSaveLabel;

  /// ideaShareLabel
  ///
  /// In en, this message translates to:
  /// **'Share Idea'**
  String get ideaShareLabel;

  /// trainingRecommendedForYou
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get trainingRecommendedForYou;

  /// No description provided for @trainingNoProgramsForDomain.
  ///
  /// In en, this message translates to:
  /// **'No training programs are available right now for {domain}.'**
  String trainingNoProgramsForDomain(Object domain);

  /// trainingLinkMissingMessage
  ///
  /// In en, this message translates to:
  /// **'This training does not have a link yet.'**
  String get trainingLinkMissingMessage;

  /// trainingLinkInvalidMessage
  ///
  /// In en, this message translates to:
  /// **'This training link is not valid.'**
  String get trainingLinkInvalidMessage;

  /// trainingLinkOpenFailedMessage
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open this training link right now.'**
  String get trainingLinkOpenFailedMessage;

  /// trainingSaveLoginMessage
  ///
  /// In en, this message translates to:
  /// **'Sign in to save training resources for later.'**
  String get trainingSaveLoginMessage;

  /// trainingRemovedSavedMessage
  ///
  /// In en, this message translates to:
  /// **'Removed from saved resources'**
  String get trainingRemovedSavedMessage;

  /// trainingSavedMessage
  ///
  /// In en, this message translates to:
  /// **'Resource saved'**
  String get trainingSavedMessage;

  /// trainingSavedUpdatedTitle
  ///
  /// In en, this message translates to:
  /// **'Saved items updated'**
  String get trainingSavedUpdatedTitle;

  /// trainingUpdateUnavailableTitle
  ///
  /// In en, this message translates to:
  /// **'Update unavailable'**
  String get trainingUpdateUnavailableTitle;

  /// trainingProviderFallback
  ///
  /// In en, this message translates to:
  /// **'Training Provider'**
  String get trainingProviderFallback;

  /// trainingFlexibleLabel
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get trainingFlexibleLabel;

  /// trainingAllLevelsLabel
  ///
  /// In en, this message translates to:
  /// **'All levels'**
  String get trainingAllLevelsLabel;

  /// trainingCareerCourseLabel
  ///
  /// In en, this message translates to:
  /// **'Career Course'**
  String get trainingCareerCourseLabel;

  /// trainingVideoLessonLabel
  ///
  /// In en, this message translates to:
  /// **'Video Lesson'**
  String get trainingVideoLessonLabel;

  /// trainingReadingTrackLabel
  ///
  /// In en, this message translates to:
  /// **'Reading Track'**
  String get trainingReadingTrackLabel;

  /// trainingGuideToolkitLabel
  ///
  /// In en, this message translates to:
  /// **'Guide & Toolkit'**
  String get trainingGuideToolkitLabel;

  /// trainingLearningPathLabel
  ///
  /// In en, this message translates to:
  /// **'Learning Path'**
  String get trainingLearningPathLabel;

  /// trainingGeneralDomainLabel
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get trainingGeneralDomainLabel;

  /// opportunityFutureGatePartner
  ///
  /// In en, this message translates to:
  /// **'FutureGate partner'**
  String get opportunityFutureGatePartner;

  /// opportunityStudentInternshipFallback
  ///
  /// In en, this message translates to:
  /// **'Student Internship Opportunity'**
  String get opportunityStudentInternshipFallback;

  /// opportunitySponsoredFallback
  ///
  /// In en, this message translates to:
  /// **'Sponsored Opportunity'**
  String get opportunitySponsoredFallback;

  /// opportunityOpenJobFallback
  ///
  /// In en, this message translates to:
  /// **'Open Job Opportunity'**
  String get opportunityOpenJobFallback;

  /// opportunityOpenFallback
  ///
  /// In en, this message translates to:
  /// **'Open Opportunity'**
  String get opportunityOpenFallback;

  /// scholarshipExploreLabel
  ///
  /// In en, this message translates to:
  /// **'Explore Scholarship'**
  String get scholarshipExploreLabel;

  /// ideaCreateCta
  ///
  /// In en, this message translates to:
  /// **'Create an idea'**
  String get ideaCreateCta;

  /// ideaCreateFirstCta
  ///
  /// In en, this message translates to:
  /// **'Create your first idea'**
  String get ideaCreateFirstCta;

  /// ideaPublicLabel
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get ideaPublicLabel;

  /// ideaPrivateLabel
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get ideaPrivateLabel;

  /// ideaSharedFromHub
  ///
  /// In en, this message translates to:
  /// **'Shared from Innovation Hub'**
  String get ideaSharedFromHub;

  /// ideaCategoryInnovation
  ///
  /// In en, this message translates to:
  /// **'Innovation'**
  String get ideaCategoryInnovation;

  /// ideaCategoryAi
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ideaCategoryAi;

  /// ideaCategoryFintech
  ///
  /// In en, this message translates to:
  /// **'Fintech'**
  String get ideaCategoryFintech;

  /// ideaCategoryEdTech
  ///
  /// In en, this message translates to:
  /// **'EdTech'**
  String get ideaCategoryEdTech;

  /// ideaCategorySustainability
  ///
  /// In en, this message translates to:
  /// **'Sustainability'**
  String get ideaCategorySustainability;

  /// ideaCategorySocialImpact
  ///
  /// In en, this message translates to:
  /// **'Social Impact'**
  String get ideaCategorySocialImpact;

  /// ideaStageConcept
  ///
  /// In en, this message translates to:
  /// **'Concept'**
  String get ideaStageConcept;

  /// ideaStageMvp
  ///
  /// In en, this message translates to:
  /// **'MVP'**
  String get ideaStageMvp;

  /// ideaStagePrototype
  ///
  /// In en, this message translates to:
  /// **'Prototype'**
  String get ideaStagePrototype;

  /// ideaStageBeta
  ///
  /// In en, this message translates to:
  /// **'Beta'**
  String get ideaStageBeta;

  /// scholarshipRemovedSavedMessage
  ///
  /// In en, this message translates to:
  /// **'Removed from saved scholarships'**
  String get scholarshipRemovedSavedMessage;

  /// scholarshipSavedMessage
  ///
  /// In en, this message translates to:
  /// **'Scholarship saved'**
  String get scholarshipSavedMessage;

  /// scholarshipSnapshotSubtitle
  ///
  /// In en, this message translates to:
  /// **'Everything important is surfaced here before you open the full application call.'**
  String get scholarshipSnapshotSubtitle;

  /// scholarshipOverviewSubtitle
  ///
  /// In en, this message translates to:
  /// **'A focused overview so the opportunity feels easy to scan.'**
  String get scholarshipOverviewSubtitle;

  /// No description provided for @uiNoArchivedConversations.
  ///
  /// In en, this message translates to:
  /// **'No archived conversations'**
  String get uiNoArchivedConversations;

  /// No description provided for @uiNoConversationsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No conversations match your search'**
  String get uiNoConversationsMatchSearch;

  /// No description provided for @uiNoConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get uiNoConversationsYet;

  /// No description provided for @uiArchivedConversationsInfo.
  ///
  /// In en, this message translates to:
  /// **'Archived conversations are shown here when you move them out of your inbox.'**
  String get uiArchivedConversationsInfo;

  /// No description provided for @uiTryDifferentNameOrKeyword.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or keyword.'**
  String get uiTryDifferentNameOrKeyword;

  /// No description provided for @uiStartConversationToChat.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation to begin chatting.'**
  String get uiStartConversationToChat;

  /// No description provided for @uiMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get uiMute;

  /// No description provided for @uiUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get uiUnmute;

  /// No description provided for @uiArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get uiArchive;

  /// No description provided for @uiUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get uiUnarchive;

  /// No description provided for @uiGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get uiGoodMorning;

  /// No description provided for @uiGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get uiGoodAfternoon;

  /// No description provided for @uiGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get uiGoodEvening;

  /// No description provided for @uiInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get uiInbox;

  /// No description provided for @uiUnread.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get uiUnread;

  /// No description provided for @uiProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get uiProjects;

  /// No description provided for @uiAllScholarships.
  ///
  /// In en, this message translates to:
  /// **'All Scholarships'**
  String get uiAllScholarships;

  /// No description provided for @uiFullyFunded.
  ///
  /// In en, this message translates to:
  /// **'Fully Funded'**
  String get uiFullyFunded;

  /// No description provided for @scholarshipBrowseLabel.
  ///
  /// In en, this message translates to:
  /// **'BROWSE'**
  String get scholarshipBrowseLabel;

  /// No description provided for @scholarshipNoFeaturedYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No featured scholarships yet'**
  String get scholarshipNoFeaturedYetTitle;

  /// No description provided for @scholarshipNoFeaturedNowTitle.
  ///
  /// In en, this message translates to:
  /// **'No featured scholarships right now'**
  String get scholarshipNoFeaturedNowTitle;

  /// No description provided for @scholarshipNoFeaturedInViewTitle.
  ///
  /// In en, this message translates to:
  /// **'No featured scholarships in this view'**
  String get scholarshipNoFeaturedInViewTitle;

  /// No description provided for @scholarshipNoFeaturedYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Featured picks will appear here once scholarships are published.'**
  String get scholarshipNoFeaturedYetSubtitle;

  /// No description provided for @scholarshipNoFeaturedNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The full scholarship list is still available below.'**
  String get scholarshipNoFeaturedNowSubtitle;

  /// No description provided for @scholarshipNoFeaturedInViewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try another search or filter to browse the available scholarships.'**
  String get scholarshipNoFeaturedInViewSubtitle;

  /// No description provided for @uiNoTrainingMatchesYourSearch.
  ///
  /// In en, this message translates to:
  /// **'No training matches your search'**
  String get uiNoTrainingMatchesYourSearch;

  /// No description provided for @uiTryDifferentCourseProviderTopicOrSkill.
  ///
  /// In en, this message translates to:
  /// **'Try a different course, provider, topic, or skill.'**
  String get uiTryDifferentCourseProviderTopicOrSkill;

  /// No description provided for @uiOpenPosition.
  ///
  /// In en, this message translates to:
  /// **'open position'**
  String get uiOpenPosition;

  /// No description provided for @uiOpenPositions.
  ///
  /// In en, this message translates to:
  /// **'open positions'**
  String get uiOpenPositions;

  /// No description provided for @uiNoJobsAvailableRightNow.
  ///
  /// In en, this message translates to:
  /// **'No jobs available right now'**
  String get uiNoJobsAvailableRightNow;

  /// No description provided for @uiOpenInternship.
  ///
  /// In en, this message translates to:
  /// **'open internship'**
  String get uiOpenInternship;

  /// No description provided for @uiOpenInternships.
  ///
  /// In en, this message translates to:
  /// **'open internships'**
  String get uiOpenInternships;

  /// No description provided for @uiNoInternshipsAvailableRightNow.
  ///
  /// In en, this message translates to:
  /// **'No internships available right now'**
  String get uiNoInternshipsAvailableRightNow;

  /// No description provided for @uiActiveTrack.
  ///
  /// In en, this message translates to:
  /// **'active track'**
  String get uiActiveTrack;

  /// No description provided for @uiActiveTracks.
  ///
  /// In en, this message translates to:
  /// **'active tracks'**
  String get uiActiveTracks;

  /// No description provided for @uiNoSponsoredProgramsAvailableRightNow.
  ///
  /// In en, this message translates to:
  /// **'No sponsored programs available right now'**
  String get uiNoSponsoredProgramsAvailableRightNow;

  /// No description provided for @uiResource.
  ///
  /// In en, this message translates to:
  /// **'resource'**
  String get uiResource;

  /// No description provided for @uiCountOpenOpportunitiesCuratedForStudents.
  ///
  /// In en, this message translates to:
  /// **'{count} open opportunities curated for students.'**
  String uiCountOpenOpportunitiesCuratedForStudents(Object count);

  /// No description provided for @uiShowingVisibleFilterFromTotalOpenListings.
  ///
  /// In en, this message translates to:
  /// **'Showing {visible} matching {filter} from {total} open listings.'**
  String uiShowingVisibleFilterFromTotalOpenListings(
    Object filter,
    Object total,
    Object visible,
  );

  /// No description provided for @uiBadgeNextStep.
  ///
  /// In en, this message translates to:
  /// **'NEXT STEP'**
  String get uiBadgeNextStep;

  /// No description provided for @uiBadgeProfileReady.
  ///
  /// In en, this message translates to:
  /// **'PROFILE {percent}% READY'**
  String uiBadgeProfileReady(Object percent);

  /// No description provided for @uiBadgeMomentum.
  ///
  /// In en, this message translates to:
  /// **'MOMENTUM'**
  String get uiBadgeMomentum;

  /// No description provided for @uiBadgeInReview.
  ///
  /// In en, this message translates to:
  /// **'IN REVIEW'**
  String get uiBadgeInReview;

  /// No description provided for @uiBadgeSavedPicks.
  ///
  /// In en, this message translates to:
  /// **'SAVED PICKS'**
  String get uiBadgeSavedPicks;

  /// No description provided for @uiBadgeDiscover.
  ///
  /// In en, this message translates to:
  /// **'DISCOVER'**
  String get uiBadgeDiscover;

  /// No description provided for @uiActionBuildCv.
  ///
  /// In en, this message translates to:
  /// **'Build CV'**
  String get uiActionBuildCv;

  /// No description provided for @uiActionCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get uiActionCompleteProfile;

  /// No description provided for @uiActionViewStatus.
  ///
  /// In en, this message translates to:
  /// **'View Status'**
  String get uiActionViewStatus;

  /// No description provided for @uiActionTrackStatus.
  ///
  /// In en, this message translates to:
  /// **'Track Status'**
  String get uiActionTrackStatus;

  /// No description provided for @uiActionSeeOpenRoles.
  ///
  /// In en, this message translates to:
  /// **'See Open Roles'**
  String get uiActionSeeOpenRoles;

  /// No description provided for @uiActionOpenSaved.
  ///
  /// In en, this message translates to:
  /// **'Open Saved'**
  String get uiActionOpenSaved;

  /// No description provided for @uiSavedScholarshipBadge.
  ///
  /// In en, this message translates to:
  /// **'Saved scholarship'**
  String get uiSavedScholarshipBadge;

  /// No description provided for @uiSavedTypeBadge.
  ///
  /// In en, this message translates to:
  /// **'Saved {type}'**
  String uiSavedTypeBadge(Object type);

  /// No description provided for @uiGrowthNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get uiGrowthNew;

  /// No description provided for @uiNoApplicationsWereSubmittedInTheLast7Days.
  ///
  /// In en, this message translates to:
  /// **'No applications were submitted in the last 7 days.'**
  String get uiNoApplicationsWereSubmittedInTheLast7Days;

  /// No description provided for @uiPeakActivityReachedCountInASingleDay.
  ///
  /// In en, this message translates to:
  /// **'Peak activity reached {count} applications in a single day.'**
  String uiPeakActivityReachedCountInASingleDay(Object count);

  /// No description provided for @uiNoReviewedApplicationsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviewed applications yet.'**
  String get uiNoReviewedApplicationsYet;

  /// No description provided for @uiReviewedApplicationsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'{approved} approved and {rejected} rejected so far.'**
  String uiReviewedApplicationsBreakdown(Object approved, Object rejected);

  /// No description provided for @uiNoApplicationsAreWaitingForReviewRightNow.
  ///
  /// In en, this message translates to:
  /// **'No applications are waiting for review right now.'**
  String get uiNoApplicationsAreWaitingForReviewRightNow;

  /// No description provided for @uiPendingApplicationsNeedReview.
  ///
  /// In en, this message translates to:
  /// **'{count} pending applications need review.'**
  String uiPendingApplicationsNeedReview(Object count);

  /// No description provided for @uiNoOpenPostsExpireWithinTwoDays.
  ///
  /// In en, this message translates to:
  /// **'No open posts expire within two days.'**
  String get uiNoOpenPostsExpireWithinTwoDays;

  /// No description provided for @uiOpenPostsExpireWithinTwoDays.
  ///
  /// In en, this message translates to:
  /// **'{count} open posts expire within two days.'**
  String uiOpenPostsExpireWithinTwoDays(Object count);

  /// No description provided for @uiYourDashboardIsReadyForIncomingApplicants.
  ///
  /// In en, this message translates to:
  /// **'Your dashboard is ready for incoming applicants.'**
  String get uiYourDashboardIsReadyForIncomingApplicants;

  /// No description provided for @uiQuickHighlightsPulledFromYourLiveDashboardData.
  ///
  /// In en, this message translates to:
  /// **'Quick highlights pulled from your live dashboard data.'**
  String get uiQuickHighlightsPulledFromYourLiveDashboardData;

  /// No description provided for @uiToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get uiToday;

  /// No description provided for @uiYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get uiYesterday;

  /// No description provided for @uiDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String uiDaysAgo(Object count);

  /// No description provided for @uiWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String uiWeeksAgo(Object count);

  /// No description provided for @uiFocusedReviewMode.
  ///
  /// In en, this message translates to:
  /// **'Focused review mode'**
  String get uiFocusedReviewMode;

  /// No description provided for @uiReviewAndRespondToCandidates.
  ///
  /// In en, this message translates to:
  /// **'Review and respond to candidates'**
  String get uiReviewAndRespondToCandidates;

  /// No description provided for @uiPendingApplicationsAcrossOpportunitiesNeedReview.
  ///
  /// In en, this message translates to:
  /// **'{count} pending applications across {opportunities} opportunities need review.'**
  String uiPendingApplicationsAcrossOpportunitiesNeedReview(
    Object count,
    Object opportunities,
  );

  /// No description provided for @uiShowPending.
  ///
  /// In en, this message translates to:
  /// **'Show pending'**
  String get uiShowPending;

  /// No description provided for @uiShowingOnlyTheCandidatesWhoAppliedToThisRole.
  ///
  /// In en, this message translates to:
  /// **'Showing only the candidates who applied to this role.'**
  String get uiShowingOnlyTheCandidatesWhoAppliedToThisRole;

  /// No description provided for @uiDirectApplicationReviewWithAllCandidateDetailsInOnePlace.
  ///
  /// In en, this message translates to:
  /// **'Direct application review with all candidate details in one place.'**
  String get uiDirectApplicationReviewWithAllCandidateDetailsInOnePlace;

  /// No description provided for @uiLatestCandidatesReadyForReviewMessagingAndCvChecks.
  ///
  /// In en, this message translates to:
  /// **'Latest candidates ready for review, messaging, and CV checks.'**
  String get uiLatestCandidatesReadyForReviewMessagingAndCvChecks;

  /// No description provided for @uiApplicationSpotlight.
  ///
  /// In en, this message translates to:
  /// **'Application spotlight'**
  String get uiApplicationSpotlight;

  /// No description provided for @uiCandidateQueue.
  ///
  /// In en, this message translates to:
  /// **'Candidate queue'**
  String get uiCandidateQueue;

  /// No description provided for @uiLocationNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Location not specified'**
  String get uiLocationNotSpecified;

  /// No description provided for @uiNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get uiNotSpecified;

  /// No description provided for @uiNoDescriptionProvided.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get uiNoDescriptionProvided;

  /// No description provided for @uiStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Status unavailable'**
  String get uiStatusUnavailable;

  /// No description provided for @uiTheRequestedFileIsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'The requested file is no longer available.'**
  String get uiTheRequestedFileIsNoLongerAvailable;

  /// No description provided for @uiSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get uiSummary;

  /// No description provided for @uiShowingTheApplicationYouOpenedDirectly.
  ///
  /// In en, this message translates to:
  /// **'Showing the application you opened directly.'**
  String get uiShowingTheApplicationYouOpenedDirectly;

  /// No description provided for @uiThisApplicationIsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This application is no longer available.'**
  String get uiThisApplicationIsNoLongerAvailable;

  /// No description provided for @uiNoApplicationsMatchThisView.
  ///
  /// In en, this message translates to:
  /// **'No applications match this view.'**
  String get uiNoApplicationsMatchThisView;

  /// No description provided for @uiTheApplicationYouOpenedIsNoLongerAvailableItMayHaveBeenRemovedOrMayNoLongerBelongToThisCompany.
  ///
  /// In en, this message translates to:
  /// **'The application you opened is no longer available. It may have been removed or may no longer belong to this company.'**
  String
  get uiTheApplicationYouOpenedIsNoLongerAvailableItMayHaveBeenRemovedOrMayNoLongerBelongToThisCompany;

  /// No description provided for @uiTryClearingTheFiltersOrBroadeningTheSearchToSeeMoreCandidates.
  ///
  /// In en, this message translates to:
  /// **'Try clearing the filters or broadening the search to see more candidates.'**
  String get uiTryClearingTheFiltersOrBroadeningTheSearchToSeeMoreCandidates;

  /// No description provided for @uiCandidateApplicationsAreListedHereWithQuickReviewActionsAndCvAccess.
  ///
  /// In en, this message translates to:
  /// **'Candidate applications are listed here with quick review actions and CV access.'**
  String
  get uiCandidateApplicationsAreListedHereWithQuickReviewActionsAndCvAccess;

  /// No description provided for @uiReviewTheCandidateBeforeMakingADecision.
  ///
  /// In en, this message translates to:
  /// **'Review the candidate before making a decision.'**
  String get uiReviewTheCandidateBeforeMakingADecision;

  /// No description provided for @uiKeepTheCandidateContextCloseAtHand.
  ///
  /// In en, this message translates to:
  /// **'Keep the candidate context close at hand.'**
  String get uiKeepTheCandidateContextCloseAtHand;

  /// No description provided for @uiUnnamedCandidate.
  ///
  /// In en, this message translates to:
  /// **'Unnamed candidate'**
  String get uiUnnamedCandidate;

  /// No description provided for @uiCandidateApproved.
  ///
  /// In en, this message translates to:
  /// **'Candidate approved'**
  String get uiCandidateApproved;

  /// No description provided for @uiCandidateRejected.
  ///
  /// In en, this message translates to:
  /// **'Candidate rejected'**
  String get uiCandidateRejected;

  /// No description provided for @uiApplicationWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Application withdrawn'**
  String get uiApplicationWithdrawn;

  /// No description provided for @uiReadyForDecision.
  ///
  /// In en, this message translates to:
  /// **'Ready for decision'**
  String get uiReadyForDecision;

  /// No description provided for @uiThisApplicationIsApprovedUseMessageOrCvReviewForNextSteps.
  ///
  /// In en, this message translates to:
  /// **'This application is approved. Use message or CV review for next steps.'**
  String get uiThisApplicationIsApprovedUseMessageOrCvReviewForNextSteps;

  /// No description provided for @uiThisApplicationIsRejectedTheProfileAndCvRemainAvailableForReference.
  ///
  /// In en, this message translates to:
  /// **'This application is rejected. The profile and CV remain available for reference.'**
  String
  get uiThisApplicationIsRejectedTheProfileAndCvRemainAvailableForReference;

  /// No description provided for @uiThisApplicationHasBeenWithdrawnByTheCandidate.
  ///
  /// In en, this message translates to:
  /// **'This application has been withdrawn by the candidate.'**
  String get uiThisApplicationHasBeenWithdrawnByTheCandidate;

  /// No description provided for @uiApproveTheCandidateToMoveThemForwardOrRejectIfTheFitIsNotRight.
  ///
  /// In en, this message translates to:
  /// **'Approve the candidate to move them forward, or reject if the fit is not right.'**
  String get uiApproveTheCandidateToMoveThemForwardOrRejectIfTheFitIsNotRight;

  /// No description provided for @uiWorking.
  ///
  /// In en, this message translates to:
  /// **'Working...'**
  String get uiWorking;

  /// No description provided for @uiApplication.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get uiApplication;

  /// No description provided for @uiApplicationConversation.
  ///
  /// In en, this message translates to:
  /// **'Application conversation'**
  String get uiApplicationConversation;

  /// No description provided for @companyFundingSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Company funding'**
  String get companyFundingSectionTitle;

  /// No description provided for @internshipCompensationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Internship compensation'**
  String get internshipCompensationSectionTitle;

  /// No description provided for @compensationAndFormatSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Compensation & format'**
  String get compensationAndFormatSectionTitle;

  /// No description provided for @optionalSupportDetailsShownToStudents.
  ///
  /// In en, this message translates to:
  /// **'Optional support details shown to students'**
  String get optionalSupportDetailsShownToStudents;

  /// No description provided for @durationExampleHint.
  ///
  /// In en, this message translates to:
  /// **'Duration, e.g. 2 months'**
  String get durationExampleHint;

  /// No description provided for @optionalCompensationNoteForDetailScreens.
  ///
  /// In en, this message translates to:
  /// **'Optional compensation note for detail screens'**
  String get optionalCompensationNoteForDetailScreens;

  /// No description provided for @eligibilityChecklistHelper.
  ///
  /// In en, this message translates to:
  /// **'Add each eligibility point separately so students see a clean checklist.'**
  String get eligibilityChecklistHelper;

  /// No description provided for @requirementsChecklistHelper.
  ///
  /// In en, this message translates to:
  /// **'Add each requirement separately so students see a clean checklist.'**
  String get requirementsChecklistHelper;

  /// No description provided for @opportunityUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Opportunity updated'**
  String get opportunityUpdatedTitle;

  /// No description provided for @opportunityPublishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Opportunity published'**
  String get opportunityPublishedTitle;

  /// No description provided for @uiSearchApplicants.
  ///
  /// In en, this message translates to:
  /// **'Search applicants'**
  String get uiSearchApplicants;

  /// No description provided for @uiSearchApprovedCompanies.
  ///
  /// In en, this message translates to:
  /// **'Search approved companies'**
  String get uiSearchApprovedCompanies;

  /// No description provided for @uiSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get uiSuggested;

  /// No description provided for @uiApprovedCompanies.
  ///
  /// In en, this message translates to:
  /// **'Approved companies'**
  String get uiApprovedCompanies;

  /// No description provided for @uiNoApplicantsMatchYourSearch.
  ///
  /// In en, this message translates to:
  /// **'No applicants match your search.'**
  String get uiNoApplicantsMatchYourSearch;

  /// No description provided for @uiNoApprovedCompaniesMatchYourSearch.
  ///
  /// In en, this message translates to:
  /// **'No approved companies match your search.'**
  String get uiNoApprovedCompaniesMatchYourSearch;

  /// No description provided for @pressBackAgainToExitApp.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit the app.'**
  String get pressBackAgainToExitApp;

  /// No description provided for @uiDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Platform pulse, moderation load, and quick control points.'**
  String get uiDashboardSubtitle;

  /// No description provided for @uiUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search users, review profiles, and manage account status.'**
  String get uiUsersSubtitle;

  /// No description provided for @uiContentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Moderate ideas, applications, listings, scholarships, and library resources.'**
  String get uiContentSubtitle;

  /// No description provided for @uiActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track platform changes and jump straight into the right queue.'**
  String get uiActivitySubtitle;

  /// No description provided for @uiAdmins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get uiAdmins;

  /// No description provided for @uiAccountState.
  ///
  /// In en, this message translates to:
  /// **'Account state'**
  String get uiAccountState;

  /// No description provided for @uiApprovalStatus.
  ///
  /// In en, this message translates to:
  /// **'Approval Status'**
  String get uiApprovalStatus;

  /// No description provided for @uiDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get uiDescription;

  /// No description provided for @uiPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get uiPendingReview;

  /// No description provided for @uiSelectedAccount.
  ///
  /// In en, this message translates to:
  /// **'Selected account'**
  String get uiSelectedAccount;

  /// No description provided for @uiSelectedCompany.
  ///
  /// In en, this message translates to:
  /// **'Selected company'**
  String get uiSelectedCompany;

  /// No description provided for @uiBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get uiBlockUser;

  /// No description provided for @uiUnblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock User'**
  String get uiUnblockUser;

  /// No description provided for @uiBlockUserMessage.
  ///
  /// In en, this message translates to:
  /// **'This will immediately remove access to the app until you restore the account later.'**
  String get uiBlockUserMessage;

  /// No description provided for @uiUnblockUserMessage.
  ///
  /// In en, this message translates to:
  /// **'This will restore access and let the user sign in and use the app again.'**
  String get uiUnblockUserMessage;

  /// No description provided for @uiApproveCompanyMessage.
  ///
  /// In en, this message translates to:
  /// **'This will unlock the workspace and let the company use its approved features right away.'**
  String get uiApproveCompanyMessage;

  /// No description provided for @uiRejectCompanyMessage.
  ///
  /// In en, this message translates to:
  /// **'This will keep the company out of the workspace until the profile details are corrected.'**
  String get uiRejectCompanyMessage;

  /// No description provided for @uiMarkPendingCompanyMessage.
  ///
  /// In en, this message translates to:
  /// **'This will move the company back into the review queue for another moderation pass.'**
  String get uiMarkPendingCompanyMessage;

  /// No description provided for @uiApproveCompanySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock the company workspace and move it into the approved state.'**
  String get uiApproveCompanySubtitle;

  /// No description provided for @uiRejectCompanySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the company out of the workspace until the profile is corrected.'**
  String get uiRejectCompanySubtitle;

  /// No description provided for @uiMarkPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Move the company back into the review queue for another check.'**
  String get uiMarkPendingSubtitle;

  /// No description provided for @uiBlockUserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Temporarily remove access to this account.'**
  String get uiBlockUserSubtitle;

  /// No description provided for @uiUnblockUserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore access and let the user sign in again.'**
  String get uiUnblockUserSubtitle;

  /// No description provided for @uiApplicationsSuffix.
  ///
  /// In en, this message translates to:
  /// **'applications'**
  String get uiApplicationsSuffix;

  /// No description provided for @uiSavesSuffix.
  ///
  /// In en, this message translates to:
  /// **'saves'**
  String get uiSavesSuffix;

  /// No description provided for @uiUnknownTime.
  ///
  /// In en, this message translates to:
  /// **'Unknown time'**
  String get uiUnknownTime;

  /// No description provided for @uiCompanyNameNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Company name not added'**
  String get uiCompanyNameNotAdded;

  /// No description provided for @uiPostedOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Posted Opportunities'**
  String get uiPostedOpportunities;

  /// No description provided for @uiViewOpportunities.
  ///
  /// In en, this message translates to:
  /// **'View Opportunities'**
  String get uiViewOpportunities;

  /// No description provided for @uiOpportunitiesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not load opportunities right now.'**
  String get uiOpportunitiesUnavailable;

  /// No description provided for @uiNoOpportunitiesPostedYet.
  ///
  /// In en, this message translates to:
  /// **'No opportunities posted yet.'**
  String get uiNoOpportunitiesPostedYet;

  /// No description provided for @uiCompanyOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Company opportunities'**
  String get uiCompanyOpportunities;

  /// No description provided for @uiNoCompanyOpportunitiesYet.
  ///
  /// In en, this message translates to:
  /// **'No opportunities posted by this company yet.'**
  String get uiNoCompanyOpportunitiesYet;

  /// No description provided for @uiOpportunityHistoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Opportunity history unavailable'**
  String get uiOpportunityHistoryUnavailable;

  /// No description provided for @uiOpportunityHistoryUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load this company\'s posted opportunities right now.'**
  String get uiOpportunityHistoryUnavailableMessage;

  /// No description provided for @uiNoOpportunitiesYet.
  ///
  /// In en, this message translates to:
  /// **'No opportunities yet'**
  String get uiNoOpportunitiesYet;

  /// No description provided for @uiNoOpportunitiesPostedByCompany.
  ///
  /// In en, this message translates to:
  /// **'This company has not posted any opportunities yet.'**
  String get uiNoOpportunitiesPostedByCompany;

  /// No description provided for @uiCommercialRegisterUploaded.
  ///
  /// In en, this message translates to:
  /// **'Commercial Register uploaded'**
  String get uiCommercialRegisterUploaded;

  /// No description provided for @uiCommercialRegisterMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing commercial register document.'**
  String get uiCommercialRegisterMissing;

  /// No description provided for @uiJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get uiJustNow;

  /// No description provided for @uiOlderActivity.
  ///
  /// In en, this message translates to:
  /// **'Older Activity'**
  String get uiOlderActivity;

  /// No description provided for @uiEndOfActivityFeed.
  ///
  /// In en, this message translates to:
  /// **'You have reached the end of the recent activity feed.'**
  String get uiEndOfActivityFeed;

  /// No description provided for @uiOlderActivityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Older activity could not be loaded'**
  String get uiOlderActivityUnavailable;

  /// No description provided for @uiNeedMoreActivity.
  ///
  /// In en, this message translates to:
  /// **'Need more activity?'**
  String get uiNeedMoreActivity;

  /// No description provided for @uiFetchingOlderUpdates.
  ///
  /// In en, this message translates to:
  /// **'Fetching older updates from across the platform.'**
  String get uiFetchingOlderUpdates;

  /// No description provided for @uiLoadOlderUpdates.
  ///
  /// In en, this message translates to:
  /// **'Load older updates from submissions, listings, trainings, scholarships, and project ideas.'**
  String get uiLoadOlderUpdates;

  /// No description provided for @uiAdminCreatedIdeas.
  ///
  /// In en, this message translates to:
  /// **'Admin-Created Ideas'**
  String get uiAdminCreatedIdeas;

  /// No description provided for @uiReviewSubmittedIdeas.
  ///
  /// In en, this message translates to:
  /// **'Review submitted ideas, keep the pending queue moving, and open details when you need the full picture.'**
  String get uiReviewSubmittedIdeas;

  /// No description provided for @uiReviewJobsDescription.
  ///
  /// In en, this message translates to:
  /// **'Review jobs, internships, and sponsored posts. Filter by source, status, or pending reviews.'**
  String get uiReviewJobsDescription;

  /// No description provided for @uiAllTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get uiAllTypes;

  /// No description provided for @uiEditOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Edit Opportunity'**
  String get uiEditOpportunity;

  /// No description provided for @uiUnknownCompany.
  ///
  /// In en, this message translates to:
  /// **'Unknown company'**
  String get uiUnknownCompany;

  /// No description provided for @uiOpenPostToReview.
  ///
  /// In en, this message translates to:
  /// **'Open this post to review the full role and requirements.'**
  String get uiOpenPostToReview;

  /// No description provided for @uiDeleteProjectIdea.
  ///
  /// In en, this message translates to:
  /// **'Delete Project Idea'**
  String get uiDeleteProjectIdea;

  /// Confirmation message for deleting an item.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String uiDeleteItemConfirm(Object title);

  /// Attributed label e.g. 'By John'.
  ///
  /// In en, this message translates to:
  /// **'By {name}'**
  String uiByName(Object name);

  /// No description provided for @uiYourPost.
  ///
  /// In en, this message translates to:
  /// **'Your Post'**
  String get uiYourPost;

  /// No description provided for @uiApps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get uiApps;

  /// No description provided for @uiUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get uiUpdated;

  /// No description provided for @uiAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get uiAdded;

  /// No description provided for @uiDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get uiDue;

  /// No description provided for @uiDeleteScholarship.
  ///
  /// In en, this message translates to:
  /// **'Delete Scholarship'**
  String get uiDeleteScholarship;

  /// No description provided for @uiKeepFundingCallsClear.
  ///
  /// In en, this message translates to:
  /// **'Keep funding calls clear, trustworthy, and easy to scan before students open the full details.'**
  String get uiKeepFundingCallsClear;

  /// No description provided for @uiOpenScholarshipToReview.
  ///
  /// In en, this message translates to:
  /// **'Open this scholarship to review eligibility and access details.'**
  String get uiOpenScholarshipToReview;

  /// No description provided for @uiPendingIdeas.
  ///
  /// In en, this message translates to:
  /// **'Pending Ideas'**
  String get uiPendingIdeas;

  /// No description provided for @uiApprovedIdeas.
  ///
  /// In en, this message translates to:
  /// **'Approved Ideas'**
  String get uiApprovedIdeas;

  /// No description provided for @uiRejectedIdeas.
  ///
  /// In en, this message translates to:
  /// **'Rejected Ideas'**
  String get uiRejectedIdeas;

  /// No description provided for @uiHiddenIdeas.
  ///
  /// In en, this message translates to:
  /// **'Hidden Ideas'**
  String get uiHiddenIdeas;

  /// No description provided for @uiFeaturedScholarships.
  ///
  /// In en, this message translates to:
  /// **'Featured Scholarships'**
  String get uiFeaturedScholarships;

  /// No description provided for @uiHiddenScholarships.
  ///
  /// In en, this message translates to:
  /// **'Hidden Scholarships'**
  String get uiHiddenScholarships;

  /// No description provided for @uiScholarshipListings.
  ///
  /// In en, this message translates to:
  /// **'Scholarship Listings'**
  String get uiScholarshipListings;

  /// No description provided for @uiNoAdminIdeasMatch.
  ///
  /// In en, this message translates to:
  /// **'No admin-created ideas match this search'**
  String get uiNoAdminIdeasMatch;

  /// No description provided for @uiNoPendingIdeasMatch.
  ///
  /// In en, this message translates to:
  /// **'No pending ideas match this search'**
  String get uiNoPendingIdeasMatch;

  /// No description provided for @uiNoApprovedIdeasMatch.
  ///
  /// In en, this message translates to:
  /// **'No approved ideas match this search'**
  String get uiNoApprovedIdeasMatch;

  /// No description provided for @uiNoRejectedIdeasMatch.
  ///
  /// In en, this message translates to:
  /// **'No rejected ideas match this search'**
  String get uiNoRejectedIdeasMatch;

  /// No description provided for @uiNoHiddenIdeasMatch.
  ///
  /// In en, this message translates to:
  /// **'No hidden ideas match this search'**
  String get uiNoHiddenIdeasMatch;

  /// No description provided for @uiNoIdeasMatch.
  ///
  /// In en, this message translates to:
  /// **'No ideas match this search'**
  String get uiNoIdeasMatch;

  /// No description provided for @uiNoFeaturedScholarshipsMatch.
  ///
  /// In en, this message translates to:
  /// **'No featured scholarships match this search'**
  String get uiNoFeaturedScholarshipsMatch;

  /// No description provided for @uiNoHiddenScholarshipsMatch.
  ///
  /// In en, this message translates to:
  /// **'No hidden scholarships match this search'**
  String get uiNoHiddenScholarshipsMatch;

  /// No description provided for @uiNoScholarshipsMatch.
  ///
  /// In en, this message translates to:
  /// **'No scholarships match this search'**
  String get uiNoScholarshipsMatch;

  /// No description provided for @uiAdminOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Admin Opportunities'**
  String get uiAdminOpportunities;

  /// No description provided for @uiPendingApplications.
  ///
  /// In en, this message translates to:
  /// **'Pending Applications'**
  String get uiPendingApplications;

  /// No description provided for @uiClosedOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Closed Opportunities'**
  String get uiClosedOpportunities;

  /// No description provided for @uiFeaturedOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Featured Opportunities'**
  String get uiFeaturedOpportunities;

  /// No description provided for @uiHiddenOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Hidden Opportunities'**
  String get uiHiddenOpportunities;

  /// No description provided for @uiOpportunityQueue.
  ///
  /// In en, this message translates to:
  /// **'Opportunity Queue'**
  String get uiOpportunityQueue;

  /// No description provided for @uiExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get uiExpired;

  /// Collection label for an opportunity type, e.g. job opportunities.
  ///
  /// In en, this message translates to:
  /// **'{type} opportunities'**
  String uiOpportunityTypeCollectionLabel(Object type);

  /// Empty state for admin-posted filtered content.
  ///
  /// In en, this message translates to:
  /// **'No admin-posted {items} match this search'**
  String uiNoAdminPostedItemsMatchSearch(Object items);

  /// Empty state for content with pending applications.
  ///
  /// In en, this message translates to:
  /// **'No {items} with pending applications right now'**
  String uiNoItemsWithPendingApplicationsRightNow(Object items);

  /// Empty state for closed filtered content.
  ///
  /// In en, this message translates to:
  /// **'No closed {items} match this search'**
  String uiNoClosedItemsMatchSearch(Object items);

  /// Empty state for featured filtered content.
  ///
  /// In en, this message translates to:
  /// **'No featured {items} match this search'**
  String uiNoFeaturedItemsMatchSearch(Object items);

  /// Empty state for hidden filtered content.
  ///
  /// In en, this message translates to:
  /// **'No hidden {items} match this search'**
  String uiNoHiddenItemsMatchSearch(Object items);

  /// Generic empty state for filtered content.
  ///
  /// In en, this message translates to:
  /// **'No {items} match this search'**
  String uiNoItemsMatchSearch(Object items);

  /// Snackbar message shown after hiding an item.
  ///
  /// In en, this message translates to:
  /// **'{itemType} \"{title}\" hidden. You can restore it later.'**
  String uiItemHiddenMessage(Object itemType, Object title);

  /// Snackbar message shown after making an item visible.
  ///
  /// In en, this message translates to:
  /// **'{itemType} \"{title}\" is visible again.'**
  String uiItemVisibleMessage(Object itemType, Object title);

  /// Snackbar title shown after hiding an item.
  ///
  /// In en, this message translates to:
  /// **'{itemType} hidden'**
  String uiItemHiddenTitle(Object itemType);

  /// Snackbar title shown after making an item visible.
  ///
  /// In en, this message translates to:
  /// **'{itemType} visible'**
  String uiItemVisibleTitle(Object itemType);

  /// No description provided for @uiPublicIdea.
  ///
  /// In en, this message translates to:
  /// **'Public Idea'**
  String get uiPublicIdea;

  /// No description provided for @uiPrivateIdea.
  ///
  /// In en, this message translates to:
  /// **'Private Idea'**
  String get uiPrivateIdea;

  /// No description provided for @uiSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get uiSubmitted;

  /// No description provided for @uiOpportunityTags.
  ///
  /// In en, this message translates to:
  /// **'Opportunity Tags'**
  String get uiOpportunityTags;

  /// No description provided for @uiApplicationLinkReady.
  ///
  /// In en, this message translates to:
  /// **'Application Link Ready'**
  String get uiApplicationLinkReady;

  /// No description provided for @uiLinkNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Link not added'**
  String get uiLinkNotAdded;

  /// No description provided for @uiExternalLinkAvailable.
  ///
  /// In en, this message translates to:
  /// **'External Link Available'**
  String get uiExternalLinkAvailable;

  /// No description provided for @uiScholarshipTags.
  ///
  /// In en, this message translates to:
  /// **'Scholarship Tags'**
  String get uiScholarshipTags;

  /// No description provided for @uiCertificateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Certificate Available'**
  String get uiCertificateAvailable;

  /// No description provided for @uiCertificateNotIncluded.
  ///
  /// In en, this message translates to:
  /// **'Certificate not included'**
  String get uiCertificateNotIncluded;

  /// No description provided for @uiAuthors.
  ///
  /// In en, this message translates to:
  /// **'Authors'**
  String get uiAuthors;

  /// No description provided for @uiStudentProfileDocumentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Student profile and submitted documents.'**
  String get uiStudentProfileDocumentsSubtitle;

  /// No description provided for @uiCouldNotLoadFullStudentProfile.
  ///
  /// In en, this message translates to:
  /// **'We could not load the full student profile right now. You can still open the application CV and the visible submitted applications.'**
  String get uiCouldNotLoadFullStudentProfile;

  /// No description provided for @uiApplicant.
  ///
  /// In en, this message translates to:
  /// **'Applicant'**
  String get uiApplicant;

  /// CV file name and upload date shown together.
  ///
  /// In en, this message translates to:
  /// **'File: {fileName}\nUploaded: {uploadedAt}'**
  String uiFileUploadedAt(Object fileName, Object uploadedAt);

  /// No description provided for @uiUploadedFileInvalidPdfAskReplace.
  ///
  /// In en, this message translates to:
  /// **'This uploaded file is not a valid PDF. Ask the user to replace it with a PDF version.'**
  String get uiUploadedFileInvalidPdfAskReplace;

  /// No description provided for @uiDocumentPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied while opening the document.'**
  String get uiDocumentPermissionDenied;

  /// No description provided for @uiRequestedDocumentNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'The requested document is no longer available.'**
  String get uiRequestedDocumentNoLongerAvailable;

  /// No description provided for @uiScholarshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Scholarship'**
  String get uiScholarshipLabel;

  /// No description provided for @uiSearchIdeasByTitleDomainSubmitterOrStatus.
  ///
  /// In en, this message translates to:
  /// **'Search ideas by title, domain, submitter, or status...'**
  String get uiSearchIdeasByTitleDomainSubmitterOrStatus;

  /// No description provided for @uiSearchOpportunitiesByTitleCompanyLocationStatusOrCompensation.
  ///
  /// In en, this message translates to:
  /// **'Search opportunities by title, company, location, status, or compensation...'**
  String get uiSearchOpportunitiesByTitleCompanyLocationStatusOrCompensation;

  /// No description provided for @uiSearchScholarshipsByTitleProviderOrDeadline.
  ///
  /// In en, this message translates to:
  /// **'Search scholarships by title, provider, or deadline...'**
  String get uiSearchScholarshipsByTitleProviderOrDeadline;

  /// No description provided for @uiSearchLibraryResources.
  ///
  /// In en, this message translates to:
  /// **'Search library resources...'**
  String get uiSearchLibraryResources;

  /// No description provided for @uiFocused.
  ///
  /// In en, this message translates to:
  /// **'Focused'**
  String get uiFocused;

  /// Label for the active search query chip.
  ///
  /// In en, this message translates to:
  /// **'Search: {query}'**
  String uiSearchQueryLabel(Object query);

  /// Compact relative time in minutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String uiMinutesAgoShort(Object count);

  /// Compact relative time in hours.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String uiHoursAgoShort(Object count);

  /// Compact relative time in days.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String uiDaysAgoShort(Object count);

  /// Dashboard application rate value.
  ///
  /// In en, this message translates to:
  /// **'{rate} apps per opportunity'**
  String uiAppsPerOpportunity(Object rate);

  /// Dashboard CV completion rate value.
  ///
  /// In en, this message translates to:
  /// **'{percent}% ({totalCvs} of {students} students)'**
  String uiCvCompletionRateValue(
    Object percent,
    Object totalCvs,
    Object students,
  );

  /// Dashboard pending and approved idea counts.
  ///
  /// In en, this message translates to:
  /// **'{pending} pending and {approved} approved'**
  String uiPendingApprovedIdeasValue(Object pending, Object approved);

  /// No description provided for @dashSectionRecommendedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chosen around your profile, timing, and momentum.'**
  String get dashSectionRecommendedSubtitle;

  /// No description provided for @dashSectionQuickAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your fastest path back into jobs, funding, tools, and saves.'**
  String get dashSectionQuickAccessSubtitle;

  /// No description provided for @dashSectionLatestActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your recent applications, saves, and CV updates.'**
  String get dashSectionLatestActivitySubtitle;

  /// No description provided for @dashSectionClosingSoonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deadlines worth acting on this week.'**
  String get dashSectionClosingSoonSubtitle;

  /// No description provided for @dashSectionDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything important stays one tap away.'**
  String get dashSectionDefaultSubtitle;

  /// No description provided for @dashFocusCvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A ready CV makes jobs, internships, and scholarships much quicker to apply for.'**
  String get dashFocusCvSubtitle;

  /// No description provided for @dashFocusCvInsight.
  ///
  /// In en, this message translates to:
  /// **'Start with your CV, then tighten the profile details that make matching feel smarter.'**
  String get dashFocusCvInsight;

  /// No description provided for @dashFocusProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} detail(s) still missing for better matching.'**
  String dashFocusProfileSubtitle(Object count);

  /// No description provided for @dashFocusInsightApprovedMomentum.
  ///
  /// In en, this message translates to:
  /// **'This is a strong moment to keep exploring while your profile is landing well.'**
  String get dashFocusInsightApprovedMomentum;

  /// No description provided for @dashFocusSubtitleInReview.
  ///
  /// In en, this message translates to:
  /// **'Keep a few strong options moving while you wait for responses.'**
  String get dashFocusSubtitleInReview;

  /// No description provided for @dashFocusInsightInReview.
  ///
  /// In en, this message translates to:
  /// **'A little follow-through now keeps your pipeline healthier later.'**
  String get dashFocusInsightInReview;

  /// No description provided for @dashFocusInsightSavedReady.
  ///
  /// In en, this message translates to:
  /// **'Your saved list is ready for a second pass before deadlines tighten.'**
  String get dashFocusInsightSavedReady;

  /// No description provided for @dashFocusSubtitleDiscover.
  ///
  /// In en, this message translates to:
  /// **'Explore open roles, internships, funding, and learning picks designed for students building momentum.'**
  String get dashFocusSubtitleDiscover;

  /// No description provided for @dashFocusInsightDiscover.
  ///
  /// In en, this message translates to:
  /// **'Use quick access below to jump into jobs, internships, scholarships, learning, or your saved shortlist.'**
  String get dashFocusInsightDiscover;

  /// No description provided for @dashFocusClosingSoonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} opportunities close within the next two weeks.'**
  String dashFocusClosingSoonSubtitle(Object count);

  /// No description provided for @dashFocusClosingSoonInsight.
  ///
  /// In en, this message translates to:
  /// **'{company} is first up, and it closes {deadline}.'**
  String dashFocusClosingSoonInsight(Object company, Object deadline);

  /// No description provided for @dashSavedBannerEmpty.
  ///
  /// In en, this message translates to:
  /// **'Keep your strongest roles, funding, and learning picks one tap away.'**
  String get dashSavedBannerEmpty;

  /// No description provided for @dashSavedBannerCount.
  ///
  /// In en, this message translates to:
  /// **'{count} saved item(s) ready for a second look.'**
  String dashSavedBannerCount(Object count);

  /// No description provided for @dashDeadlineSoon.
  ///
  /// In en, this message translates to:
  /// **'deadline soon'**
  String get dashDeadlineSoon;

  /// No description provided for @dashLastDay.
  ///
  /// In en, this message translates to:
  /// **'Last day'**
  String get dashLastDay;

  /// No description provided for @dashDayLeft.
  ///
  /// In en, this message translates to:
  /// **'1 day left'**
  String get dashDayLeft;

  /// No description provided for @dashDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String dashDaysLeft(Object count);

  /// No description provided for @discoverResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get discoverResultsTitle;

  /// No description provided for @discoverResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Listings that match your current search and filters'**
  String get discoverResultsSubtitle;

  /// No description provided for @discoverNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters to uncover more matches.'**
  String get discoverNoResultsHint;

  /// No description provided for @discoverTrendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Featured, fresh, and high-signal picks from live data'**
  String get discoverTrendingSubtitle;

  /// No description provided for @discoverTrendingEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Fresh recommendations are highlighted as new listings go live.'**
  String get discoverTrendingEmptyHint;

  /// No description provided for @discoverLatestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The {count} newest roles, internships, and sponsored tracks'**
  String discoverLatestSubtitle(Object count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
