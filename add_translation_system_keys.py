#!/usr/bin/env python3
"""Add new ARB keys for: notification screen l10n, translation system, posting language."""
import json, os, re

ROOT = os.path.dirname(os.path.abspath(__file__))

EN = os.path.join(ROOT, 'lib', 'l10n', 'app_en.arb')
FR = os.path.join(ROOT, 'lib', 'l10n', 'app_fr.arb')
AR = os.path.join(ROOT, 'lib', 'l10n', 'app_ar.arb')

# Keys: (key, en, fr, ar)
KEYS = [
    # Notification screen
    ('notifAdminTitle',        'Admin Notifications',      'Notifications Admin',       'إشعارات المسؤول'),
    ('notifCompanyTitle',      'Company Notifications',    'Notifications Entreprise',  'إشعارات الشركة'),
    ('notifReadAll',           'Read all',                 'Tout lire',                 'قراءة الكل'),
    ('notifFilterAll',         'All',                      'Tout',                      'الكل'),
    ('notifFilterNewContent',  'New content',              'Nouveau contenu',           'محتوى جديد'),
    ('notifFilterUnread',      'Unread',                   'Non lus',                   'غير مقروء'),
    ('notifFilterApplications','Applications',             'Candidatures',              'الطلبات'),
    ('notifFilterMessages',    'Messages',                 'Messages',                  'الرسائل'),
    ('notifContentAll',        'All new',                  'Tous les nouveaux',         'كل الجديد'),
    ('notifContentOpportunities','Opportunities',          'Opportunités',              'الفرص'),
    ('notifContentTrainings',  'Trainings',                'Formations',                'التدريبات'),
    ('notifContentScholarships','Scholarships',            'Bourses',                   'المنح'),
    ('notifContentIdeas',      'Ideas',                    'Idées',                     'الأفكار'),
    ('notifOppAll',            'All opps',                 'Toutes les opps',           'كل الفرص'),
    ('notifOppJobs',           'Jobs',                     'Emplois',                   'وظائف'),
    ('notifOppInternships',    'Internships',              'Stages',                    'تدريبات'),
    ('notifOppSponsored',      'Sponsored',                'Sponsorisé',                'مموّل'),
    ('notifAllCaughtUp',       'All caught up',            'Tout est à jour',           'لا شيء فائت'),
    ('notifTypeMessage',       'Message',                  'Message',                   'رسالة'),
    ('notifTypeApplication',   'Application',              'Candidature',               'طلب'),
    ('notifTypeOpportunity',   'Opportunity',              'Opportunité',               'فرصة'),
    ('notifTypeScholarship',   'Scholarship',              'Bourse',                    'منحة'),
    ('notifTypeTraining',      'Training',                 'Formation',                 'تدريب'),
    ('notifTypeIdea',          'Idea',                     'Idée',                      'فكرة'),
    ('notifTypeCompanyReview', 'Company review',           'Révision entreprise',       'مراجعة الشركة'),
    ('notifTypeUpdate',        'Update',                   'Mise à jour',               'تحديث'),
    ('notifJustNow',           'Just now',                 'À l\'instant',              'الآن'),
    # Translation system
    ('postingLanguageLabel',   'Posting language',         'Langue de publication',     'لغة النشر'),
    ('postingLanguageHint',    'Language this content is written in', 'Langue dans laquelle ce contenu est rédigé', 'اللغة التي كُتب بها هذا المحتوى'),
    ('translateLabel',         'Translate',                'Traduire',                  'ترجمة'),
    ('translatingLabel',       'Translating...',           'Traduction en cours...',    'جارٍ الترجمة...'),
    ('translationDoneLabel',   'Translation ready',        'Traduction prête',          'الترجمة جاهزة'),
    ('translationFailedLabel', 'Translation unavailable',  'Traduction indisponible',   'الترجمة غير متوفرة'),
    ('showOriginalLabel',      'Show original',            'Afficher l\'original',      'عرض الأصل'),
    ('showTranslatedLabel',    'Show translated',          'Afficher la traduction',    'عرض الترجمة'),
    ('contentLanguageLabel',   'Content language',         'Langue du contenu',         'لغة المحتوى'),
    ('autoTranslatedBadge',    'Auto-translated',          'Traduit automatiquement',   'مُترجم تلقائياً'),
    ('translatedBadge',        'Translated',               'Traduit',                   'مترجم'),
    ('originalBadge',          'Original',                 'Original',                  'أصلي'),
    ('translationNote',        'This content was automatically translated. Tap "Show original" to see the source.',
                               'Ce contenu a été traduit automatiquement. Appuyez sur "Afficher l\'original" pour voir la source.',
                               'تمت ترجمة هذا المحتوى تلقائياً. اضغط على "عرض الأصل" لرؤية المصدر الأصلي.'),
    # Dashboard section titles
    ('dashSectionClosingSoon', 'Closing Soon',             'Fermeture imminente',       'ينتهي قريباً'),
    ('dashSectionRecommended', 'Recommended',              'Recommandé',                'موصى به'),
    ('dashSectionQuickAccess', 'Quick Access',             'Accès rapide',              'وصول سريع'),
    ('dashSectionLatestActivity','Latest Activities',      'Dernières activités',       'آخر الأنشطة'),
    ('dashSectionSavedShortlist','Saved shortlist',        'Liste de raccourcis sauvegardés','القائمة المحفوظة'),
    ('dashBuildCv',            'Build CV',                 'Créer un CV',               'بناء السيرة'),
    ('dashCompleteProfile',    'Complete Profile',         'Compléter le profil',       'اكمال الملف'),
    ('dashDiscover',           'Discover',                 'Découvrir',                 'استكشاف'),
    ('dashViewStatus',         'View Status',              'Voir le statut',            'عرض الحالة'),
    ('dashTrackStatus',        'Track Status',             'Suivre le statut',          'تتبع الحالة'),
    ('dashSeeOpenRoles',       'See Open Roles',           'Voir les postes ouverts',   'رؤية الفرص المتاحة'),
    ('dashOpenSaved',          'Open Saved',               'Ouvrir les sauvegardés',    'فتح المحفوظات'),
    # Scholarship detail
    ('scholarshipOpportunityFallback','Scholarship Opportunity','Opportunité de bourse','فرصة منحة دراسية'),
    ('scholarshipPartnerFallback','FutureGate Partner',    'Partenaire FutureGate',     'شريك FutureGate'),
    ('scholarshipNoDescFallback','This scholarship does not include a detailed description yet.',
                               'Cette bourse n\'inclut pas encore de description détaillée.',
                               'لا تتضمن هذه المنحة وصفاً تفصيلياً بعد.'),
    ('scholarshipNoEligFallback','Eligibility details will be shared by the scholarship provider.',
                               'Les détails d\'éligibilité seront partagés par le fournisseur de bourse.',
                               'سيتم مشاركة تفاصيل الأهلية من قِبل مزود المنحة.'),
    ('scholarshipDeadlineFallback','Provider-announced deadline','Délai annoncé par le fournisseur','الموعد النهائي المُعلن من المزود'),
    ('scholarshipFundingFallback','Funding shared on the official call','Financement partagé sur l\'appel officiel','التمويل مُشارك في الإعلان الرسمي'),
    ('scholarshipFeaturedBadge','FEATURED',                'EN VEDETTE',                'مميّز'),
    ('scholarshipDefaultBadge','SCHOLARSHIP',              'BOURSE',                    'منحة'),
    ('scholarshipFundingAmount','Funding Amount',          'Montant du financement',    'مبلغ التمويل'),
    ('scholarshipFundingDetails','Funding Details',        'Détails du financement',    'تفاصيل التمويل'),
    ('scholarshipStudyLevel',  'Study Level',              'Niveau d\'études',          'مستوى الدراسة'),
    ('scholarshipProgramType', 'Program Type',             'Type de programme',         'نوع البرنامج'),
    ('scholarshipAtAGlance',   'AT A GLANCE',              'EN UN COUP D\'ŒIL',         'نظرة عامة'),
    ('scholarshipNoLink',      'The provider has not attached an external application link yet.',
                               'Le fournisseur n\'a pas encore joint de lien de candidature externe.',
                               'لم يُرفق المزود بعد رابط التقديم الخارجي.'),
    ('scholarshipOfficialSource','Official scholarship source','Source officielle de la bourse','المصدر الرسمي للمنحة'),
    ('scholarshipOpenPage',    'Open Official Page',       'Ouvrir la page officielle', 'فتح الصفحة الرسمية'),
    ('scholarshipLinkUnavailable','Link Not Available',    'Lien non disponible',       'الرابط غير متوفر'),
    # Idea detail
    ('ideaNotAvailable',       'This idea is no longer available.','Cette idée n\'est plus disponible.','هذه الفكرة لم تعد متاحة.'),
    ('ideaHubTitle',           'Innovation Hub',           'Hub d\'Innovation',         'مركز الابتكار'),
    ('ideaUnsaveTooltip',      'Unsave idea',              'Retirer l\'idée',           'إلغاء الحفظ'),
    ('ideaSaveTooltip',        'Save idea',                'Sauvegarder l\'idée',       'حفظ الفكرة'),
    ('ideaEditLabel',          'Edit Idea',                'Modifier l\'idée',          'تعديل الفكرة'),
    ('ideaManageLabel',        'Manage This Idea',         'Gérer cette idée',          'إدارة هذه الفكرة'),
    ('ideaInterestedLabel',    'Interested',               'Intéressé',                 'مهتم'),
    ('ideaImInterestedLabel',  "I'm Interested",           "Je suis intéressé",         'أنا مهتم'),
    ('ideaManageTeamLabel',    'Manage Team',              'Gérer l\'équipe',           'إدارة الفريق'),
    ('ideaContactCreator',     'Contact Creator',          'Contacter le créateur',     'التواصل مع المنشئ'),
    ('ideaSavedLabel',         'Saved',                    'Sauvegardé',                'محفوظة'),
    ('ideaSaveLabel',          'Save Idea',                'Sauvegarder l\'idée',       'حفظ الفكرة'),
    ('ideaShareLabel',         'Share Idea',               'Partager l\'idée',          'مشاركة الفكرة'),
]

def load_arb(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_arb(path, data):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')

def add_keys(arb_data, keys_by_lang):
    inserted = 0
    # Find insertion point before last `}`
    for key, value in keys_by_lang.items():
        if key not in arb_data:
            arb_data[key] = value
            inserted += 1
    return inserted

en_data = load_arb(EN)
fr_data = load_arb(FR)
ar_data = load_arb(AR)

en_keys = {}
fr_keys = {}
ar_keys = {}

for key, en, fr, ar in KEYS:
    en_keys[key] = en
    en_keys[f'@{key}'] = {'description': key}
    fr_keys[key] = fr
    ar_keys[key] = ar

en_ins = add_keys(en_data, en_keys)
fr_ins = add_keys(fr_data, fr_keys)
ar_ins = add_keys(ar_data, ar_keys)

save_arb(EN, en_data)
save_arb(FR, fr_data)
save_arb(AR, ar_data)

print(f'EN: {en_ins} items added')
print(f'FR: {fr_ins} items added')
print(f'AR: {ar_ins} items added')
