#!/usr/bin/env python3
"""Replace remaining hardcoded Text strings with l10n calls across all files."""
import re
from pathlib import Path

L10N_IMPORT = "import '../../l10n/generated/app_localizations.dart';"
L10N_IMPORT_WIDGET = "import '../l10n/generated/app_localizations.dart';"
L10N_CALL = "AppLocalizations.of(context)!"

# (old_text, new_text) — old_text must be unique enough per file
FILE_FIXES = {
    # ── Admin: content center ────────────────────────────────────────────────
    "lib/screens/admin/admin_content_center_screen.dart": {
        "import": L10N_IMPORT,
        "after":  "import 'package:flutter/material.dart';",
        "replacements": [
            ("child: const Text('Retry')",              f"child: Text({L10N_CALL}.retryLabel)"),
            ("title: const Text('Admin Content Center')",f"title: Text({L10N_CALL}.uiAdminContentCenter)"),
            ("label: const Text('Post Admin Idea')",    f"label: Text({L10N_CALL}.uiPostAdminIdea)"),
            ("label: const Text('Details')",            f"label: Text({L10N_CALL}.uiDetails)"),
            ("child: const Text('Open')",               f"child: Text({L10N_CALL}.uiOpen)"),
            ("label: const Text('Post Opportunity')",   f"label: Text({L10N_CALL}.uiPostOpportunity)"),
            ("label: const Text('Post Scholarship')",   f"label: Text({L10N_CALL}.uiPostScholarship)"),
            ("label: const Text('Apply Link')",         f"label: Text({L10N_CALL}.uiApplyLink)"),
            ("label: const Text('Open Library Studio')",f"label: Text({L10N_CALL}.openLibraryStudioLabel)"),
            ("label: const Text('Open Resource')",      f"label: Text({L10N_CALL}.uiOpenResource)"),
            ("label: const Text('Cancel')",             f"label: Text({L10N_CALL}.cancelLabel)"),
            ("label: const Text('Delete')",             f"label: Text({L10N_CALL}.uiDelete)"),
            ("label: const Text('Edit Idea')",          f"label: Text({L10N_CALL}.uiEditIdea)"),
            ("label: const Text('Reject')",             f"label: Text({L10N_CALL}.uiReject)"),
            ("label: const Text('View Profile')",       f"label: Text({L10N_CALL}.uiViewProfile)"),
            ("label: const Text('View CV')",            f"label: Text({L10N_CALL}.uiViewCv)"),
            ("label: const Text('View All Apps')",      f"label: Text({L10N_CALL}.uiViewAllApps)"),
            ("label: const Text('Download CV')",        f"label: Text({L10N_CALL}.uiDownloadCv)"),
            # parameterized — keep as is (needs manual fix, complex interpolation)
        ],
    },
    # ── Admin: Google Books import ───────────────────────────────────────────
    "lib/screens/admin/admin_google_books_import_screen.dart": {
        "import": L10N_IMPORT,
        "after":  "import 'package:flutter/material.dart';",
        "replacements": [
            ("title: const Text('Delete resource')",    f"title: Text({L10N_CALL}.uiDeleteResource)"),
            ("child: const Text('Cancel')",             f"child: Text({L10N_CALL}.cancelLabel)"),
            ("label: const Text('Retry')",              f"label: Text({L10N_CALL}.retryLabel)"),
            ("label: const Text('Open')",               f"label: Text({L10N_CALL}.uiOpen)"),
            ("label: const Text('Delete')",             f"label: Text({L10N_CALL}.uiDelete)"),
            ("title: const Text('Import Google Books')",f"title: Text({L10N_CALL}.uiImportGoogleBooks)"),
        ],
    },
    # ── Admin: Library screen ────────────────────────────────────────────────
    "lib/screens/admin/admin_library_screen.dart": {
        "import": L10N_IMPORT,
        "after":  "import 'package:flutter/material.dart';",
        "replacements": [
            ("label: const Text('Retry sync')",         f"label: Text({L10N_CALL}.uiRetrySync)"),
            ("label: const Text('Open Studio')",        f"label: Text({L10N_CALL}.uiOpenStudio)"),
        ],
    },
    # ── Admin: Student profile sheet ─────────────────────────────────────────
    "lib/screens/admin/admin_student_profile_sheet.dart": {
        "import": L10N_IMPORT,
        "after":  "import 'package:flutter/material.dart';",
        "replacements": [
            ("label: const Text('Retry')",              f"label: Text({L10N_CALL}.retryLabel)"),
        ],
    },
    # ── Admin: YouTube import ────────────────────────────────────────────────
    "lib/screens/admin/admin_youtube_import_screen.dart": {
        "import": L10N_IMPORT,
        "after":  "import 'package:flutter/material.dart';",
        "replacements": [
            ("title: const Text('Delete resource')",    f"title: Text({L10N_CALL}.uiDeleteResource)"),
            ("child: const Text('Cancel')",             f"child: Text({L10N_CALL}.cancelLabel)"),
            ("label: const Text('Retry')",              f"label: Text({L10N_CALL}.retryLabel)"),
            ("label: const Text('Open')",               f"label: Text({L10N_CALL}.uiOpen)"),
            ("label: const Text('Delete')",             f"label: Text({L10N_CALL}.uiDelete)"),
            ("title: const Text('Import YouTube Videos')", f"title: Text({L10N_CALL}.uiImportYoutubeVideos)"),
        ],
    },
    # ── Company: applications screen ─────────────────────────────────────────
    "lib/screens/company/applications_screen.dart": {
        "import": "import '../../l10n/generated/app_localizations.dart';",
        "after":  "import 'package:flutter/material.dart';",
        "replacements": [
            ("const Center(child: Text('Not logged in'))",
             f"Center(child: Text({L10N_CALL}.notLoggedIn))"),
            ("Text('FILTERS', style: sectionLabelStyle)",
             f"Text({L10N_CALL}.uiFilters.toUpperCase(), style: sectionLabelStyle)"),
            ("Text('STATUS', style: sectionLabelStyle)",
             f"Text({L10N_CALL}.uiStatus.toUpperCase(), style: sectionLabelStyle)"),
            ("Text('TYPE', style: sectionLabelStyle)",
             f"Text({L10N_CALL}.uiType.toUpperCase(), style: sectionLabelStyle)"),
            ("Text('ROLES', style: sectionLabelStyle)",
             f"Text({L10N_CALL}.uiRoles.toUpperCase(), style: sectionLabelStyle)"),
            ("const _DetailBodyText('No requirements provided.')",
             f"_DetailBodyText({L10N_CALL}.uiNoRequirementsProvided)"),
            ("label: const Text('View CV')",            f"label: Text({L10N_CALL}.uiViewCv)"),
            ("label: const Text('Download CV')",        f"label: Text({L10N_CALL}.uiDownloadCv)"),
        ],
    },
    # ── Company: publish opportunity ─────────────────────────────────────────
    "lib/screens/company/publish_opportunity_screen.dart": {
        "import": "import '../../l10n/generated/app_localizations.dart';",
        "after":  "import 'package:flutter/material.dart';",
        "replacements": [
            ("child: Text('Paid')",    f"child: Text({L10N_CALL}.paidLabel)"),
            ("child: Text('Unpaid')",  f"child: Text({L10N_CALL}.unpaidLabel)"),
        ],
    },
    # ── Notifications screen ─────────────────────────────────────────────────
    "lib/screens/notifications_screen.dart": {
        "import": "import '../l10n/generated/app_localizations.dart';",
        "after":  "import 'package:flutter/material.dart';",
        "replacements": [
            ("title: const Text('Company Reviews')", f"title: Text({L10N_CALL}.uiCompanyReviews)"),
        ],
    },
    # ── Student: create idea screen ──────────────────────────────────────────
    "lib/screens/student/create_idea_screen.dart": {
        "import": "import '../../l10n/generated/app_localizations.dart';",
        "after":  "import 'package:flutter/material.dart';",
        "replacements": [
            ("Text('Choose one option', style: SettingsFlowTheme.caption())",
             f"Text({L10N_CALL}.chooseOneOptionLabel, style: SettingsFlowTheme.caption())"),
            ("child: Text('Bachelor')",   f"child: Text({L10N_CALL}.uiBachelor)"),
            ("child: Text('Licence')",    f"child: Text({L10N_CALL}.academicLevelLicence)"),
            ("child: Text('Master')",     f"child: Text({L10N_CALL}.academicLevelMaster)"),
            ("child: Text('Doctorate')",  f"child: Text({L10N_CALL}.uiDoctorate)"),
        ],
    },
    # ── Student: edit profile ────────────────────────────────────────────────
    "lib/screens/student/edit_profile_screen.dart": {
        "import": "import '../../l10n/generated/app_localizations.dart';",
        "after":  "import 'package:flutter/material.dart';",
        "replacements": [
            ("Text('Choose an Avatar', style: SettingsFlowTheme.sectionTitle())",
             f"Text({L10N_CALL}.uiChooseAvatar, style: SettingsFlowTheme.sectionTitle())"),
        ],
    },
    # ── Student: idea details ────────────────────────────────────────────────
    "lib/screens/student/idea_details_screen.dart": {
        "import": "import '../../l10n/generated/app_localizations.dart';",
        "after":  "import 'package:flutter/material.dart';",
        "replacements": [
            ("Text('Manage Team', style: _theme.section(size: 20))",
             f"Text({L10N_CALL}.uiManageTeam, style: _theme.section(size: 20))"),
        ],
    },
    # ── Student: opportunities ───────────────────────────────────────────────
    "lib/screens/student/opportunities_screen.dart": {
        "import": "import '../../l10n/generated/app_localizations.dart';",
        "after":  "import 'package:flutter/material.dart';",
        "replacements": [
            ("child: const Text('Clear')", f"child: Text({L10N_CALL}.uiClear)"),
            ("child: const Text('Apply')", f"child: Text({L10N_CALL}.uiApply)"),
        ],
    },
    # ── Student: scholarship detail ──────────────────────────────────────────
    "lib/screens/student/scholarship_detail_screen.dart": {
        "import": "import '../../l10n/generated/app_localizations.dart';",
        "after":  "import 'package:flutter/material.dart';",
        "replacements": [
            ("content: Text('No scholarship link is available for this item yet')",
             f"content: Text({L10N_CALL}.noScholarshipLinkAvailable)"),
            ("content: Text('Could not open the scholarship link')",
             f"content: Text({L10N_CALL}.couldNotOpenScholarshipLink)"),
        ],
    },
    # ── Student: dashboard ───────────────────────────────────────────────────
    "lib/screens/student/student_dashboard_screen.dart": {
        "import": "import '../../l10n/generated/app_localizations.dart';",
        "after":  "import 'package:flutter/material.dart';",
        "replacements": [
            ("child: const Text('View profile')", f"child: Text({L10N_CALL}.uiViewProfile)"),
        ],
    },
    # ── Widget: message bubble ───────────────────────────────────────────────
    "lib/widgets/message_bubble.dart": {
        "import": "import '../l10n/generated/app_localizations.dart';",
        "after":  "import 'package:flutter/material.dart';",
        "replacements": [
            ("title: Text('Edit message', style: GoogleFonts.poppins())",
             f"title: Text({L10N_CALL}.editMessageLabel, style: GoogleFonts.poppins())"),
        ],
    },
    # ── Widget: recent users list ────────────────────────────────────────────
    "lib/widgets/recent_users_list.dart": {
        "import": "import '../l10n/generated/app_localizations.dart';",
        "after":  "import 'package:flutter/material.dart';",
        "replacements": [
            ("if (users.isEmpty) const Text('No recent users yet')",
             f"if (users.isEmpty) Text({L10N_CALL}.noRecentUsersYet)"),
        ],
    },
    # ── Widget: training resource card ───────────────────────────────────────
    "lib/widgets/training_resource_card.dart": {
        "import": "import '../l10n/generated/app_localizations.dart';",
        "after":  "import 'package:flutter/material.dart';",
        "replacements": [
            ("label: const Text('Open')", f"label: Text({L10N_CALL}.uiOpen)"),
        ],
    },
}

def fix_file(rel_path, spec):
    path = Path(rel_path)
    if not path.exists():
        print(f"  SKIP (not found): {rel_path}")
        return

    text = path.read_text(encoding="utf-8")
    original = text

    # Add import if missing
    imp = spec["import"]
    if imp not in text:
        after = spec["after"]
        if after in text:
            text = text.replace(after, after + "\n" + imp, 1)
        else:
            print(f"  WARN: anchor not found in {rel_path}: {after[:60]}")

    # Apply replacements
    applied = 0
    for old, new in spec["replacements"]:
        if old in text:
            text = text.replace(old, new)
            applied += 1
        else:
            print(f"  MISS: {old[:70]} in {path.name}")

    if text != original:
        path.write_text(text, encoding="utf-8")
        print(f"  {path.name}: {applied}/{len(spec['replacements'])} fixes")
    else:
        print(f"  {path.name}: unchanged")

for rel_path, spec in FILE_FIXES.items():
    fix_file(rel_path, spec)

print("\nDone.")
