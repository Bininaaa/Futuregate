// @ts-nocheck
// FutureGate Admin — Lightweight i18n
// Supports English (en), Arabic (ar), French (fr).
// Persists language in localStorage and applies dir/lang to <html>.

const STORAGE_KEY = 'futuregate-admin-lang';
const SUPPORTED = ['en', 'ar', 'fr'];
const DEFAULT_LANG = 'en';
const RTL_LANGS = new Set(['ar']);

const TRANSLATIONS = {
  // ─── Chrome / shell ─────────────────────────────────────
  'shell.workspace': { ar: 'مساحة العمل', fr: 'Espace de travail' },
  'shell.adminWorkspace': { ar: 'لوحة الإدارة', fr: 'Espace administrateur' },
  'shell.collapseSidebar': { ar: 'طيّ الشريط الجانبي', fr: 'Réduire la barre latérale' },
  'shell.expandSidebar': { ar: 'توسيع الشريط الجانبي', fr: 'Développer la barre latérale' },
  'shell.openNavigation': { ar: 'فتح القائمة', fr: 'Ouvrir la navigation' },
  'shell.toggleTheme': { ar: 'تبديل السمة', fr: 'Changer le thème' },
  'shell.notifications': { ar: 'الإشعارات', fr: 'Notifications' },
  'shell.signOut': { ar: 'تسجيل الخروج', fr: 'Déconnexion' },
  'shell.admin': { ar: 'مسؤول', fr: 'Administrateur' },
  'shell.language': { ar: 'اللغة', fr: 'Langue' },
  'shell.verifyingSession': { ar: 'جاري التحقق من الجلسة…', fr: 'Vérification de la session…' },

  // ─── Navigation items ───────────────────────────────────
  'nav.dashboard': { ar: 'لوحة التحكم', fr: 'Tableau de bord' },
  'nav.users': { ar: 'المستخدمون', fr: 'Utilisateurs' },
  'nav.content': { ar: 'المحتوى', fr: 'Contenu' },
  'nav.activity': { ar: 'النشاط', fr: 'Activité' },
  'nav.notifications': { ar: 'الإشعارات', fr: 'Notifications' },

  // ─── Page eyebrows / titles ─────────────────────────────
  'page.dashboard.title': { ar: 'لوحة التحكم', fr: 'Tableau de bord' },
  'page.dashboard.eyebrow': { ar: 'نظرة عامة', fr: 'Aperçu' },
  'page.users.title': { ar: 'المستخدمون', fr: 'Utilisateurs' },
  'page.users.eyebrow': { ar: 'الحسابات', fr: 'Comptes' },
  'page.content.title': { ar: 'المحتوى', fr: 'Contenu' },
  'page.content.eyebrow': { ar: 'الإشراف', fr: 'Modération' },
  'page.activity.title': { ar: 'النشاط', fr: 'Activité' },
  'page.activity.eyebrow': { ar: 'تدفق مباشر', fr: 'Flux en direct' },
  'page.notifications.title': { ar: 'الإشعارات', fr: 'Notifications' },
  'page.notifications.eyebrow': { ar: 'الصندوق الوارد', fr: 'Boîte de réception' },

  // ─── Login ──────────────────────────────────────────────
  'login.title': { ar: 'تسجيل الدخول · مسؤول FutureGate', fr: 'Connexion · Admin FutureGate' },
  'login.heading': { ar: 'مسؤول FutureGate', fr: 'Admin FutureGate' },
  'login.subheading': { ar: 'سجّل الدخول بحساب المسؤول الخاص بك.', fr: 'Connectez-vous avec votre compte administrateur.' },
  'login.email': { ar: 'البريد الإلكتروني', fr: 'E-mail' },
  'login.password': { ar: 'كلمة المرور', fr: 'Mot de passe' },
  'login.submit': { ar: 'تسجيل الدخول', fr: 'Se connecter' },
  'login.signingIn': { ar: 'جارٍ تسجيل الدخول...', fr: 'Connexion...' },
  'login.failed': { ar: 'فشل تسجيل الدخول', fr: 'Échec de la connexion' },
  'login.notAdmin': { ar: 'هذا الحساب ليس حساب مسؤول.', fr: 'Ce compte n\'est pas un compte administrateur.' },
  'login.inactive': { ar: 'حساب المسؤول الخاص بك غير نشط.', fr: 'Votre compte administrateur est inactif.' },
  'login.cantSignIn': { ar: 'تعذّر تسجيل الدخول.', fr: 'Connexion impossible.' },
  'login.wrongCreds': { ar: 'البريد الإلكتروني أو كلمة المرور غير صحيحة.', fr: 'E-mail ou mot de passe incorrect.' },
  'login.tooMany': { ar: 'محاولات كثيرة جدًا. حاول لاحقًا.', fr: 'Trop de tentatives. Réessayez plus tard.' },
  'login.network': { ar: 'خطأ في الشبكة. تحقّق من اتصالك.', fr: 'Erreur réseau. Vérifiez votre connexion.' },

  // ─── Common buttons / actions ───────────────────────────
  'btn.save': { ar: 'حفظ', fr: 'Enregistrer' },
  'btn.cancel': { ar: 'إلغاء', fr: 'Annuler' },
  'btn.close': { ar: 'إغلاق', fr: 'Fermer' },
  'btn.edit': { ar: 'تعديل', fr: 'Modifier' },
  'btn.delete': { ar: 'حذف', fr: 'Supprimer' },
  'btn.approve': { ar: 'موافقة', fr: 'Approuver' },
  'btn.reject': { ar: 'رفض', fr: 'Refuser' },
  'btn.publish': { ar: 'نشر', fr: 'Publier' },
  'btn.feature': { ar: 'تمييز', fr: 'Mettre en avant' },
  'btn.unfeature': { ar: 'إلغاء التمييز', fr: 'Retirer la mise en avant' },
  'btn.hide': { ar: 'إخفاء', fr: 'Masquer' },
  'btn.show': { ar: 'إظهار', fr: 'Afficher' },
  'btn.unhide': { ar: 'إظهار', fr: 'Afficher' },
  'btn.viewDetails': { ar: 'عرض التفاصيل', fr: 'Voir les détails' },
  'btn.loadMore': { ar: 'تحميل المزيد', fr: 'Charger plus' },
  'btn.markAllRead': { ar: 'وضع علامة قراءة على الكل', fr: 'Tout marquer comme lu' },
  'btn.add': { ar: 'إضافة', fr: 'Ajouter' },
  'btn.search': { ar: 'بحث', fr: 'Rechercher' },
  'btn.viewAll': { ar: 'عرض الكل', fr: 'Voir tout' },
  'btn.allUsers': { ar: 'جميع المستخدمين', fr: 'Tous les utilisateurs' },
  'btn.all': { ar: 'الكل', fr: 'Tout' },
  'btn.openResource': { ar: 'فتح المورد', fr: 'Ouvrir la ressource' },
  'btn.viewRegister': { ar: 'عرض السجل', fr: 'Voir le registre' },
  'btn.downloadRegister': { ar: 'تنزيل السجل', fr: 'Télécharger le registre' },
  'btn.publisherProfile': { ar: 'الملف الشخصي للناشر', fr: 'Profil du publicateur' },
  'btn.editAdminPost': { ar: 'تعديل منشور المسؤول', fr: 'Modifier le post administrateur' },
  'btn.editInModeration': { ar: 'تعديل في الإشراف', fr: 'Modifier dans la modération' },
  'btn.reviewCv': { ar: 'مراجعة السيرة الذاتية', fr: 'Examiner le CV' },
  'btn.retry': { ar: 'إعادة المحاولة', fr: 'Réessayer' },
  'btn.confirm': { ar: 'تأكيد', fr: 'Confirmer' },
  'btn.copy': { ar: 'نسخ', fr: 'Copier' },
  'btn.copied': { ar: 'تم النسخ', fr: 'Copié' },
  'btn.send': { ar: 'إرسال', fr: 'Envoyer' },
  'btn.next': { ar: 'التالي', fr: 'Suivant' },
  'btn.back': { ar: 'رجوع', fr: 'Retour' },
  'btn.preview': { ar: 'معاينة', fr: 'Aperçu' },

  // ─── Common labels / statuses ───────────────────────────
  'label.title': { ar: 'العنوان', fr: 'Titre' },
  'label.description': { ar: 'الوصف', fr: 'Description' },
  'label.email': { ar: 'البريد الإلكتروني', fr: 'E-mail' },
  'label.phone': { ar: 'الهاتف', fr: 'Téléphone' },
  'label.location': { ar: 'الموقع', fr: 'Emplacement' },
  'label.status': { ar: 'الحالة', fr: 'Statut' },
  'label.type': { ar: 'النوع', fr: 'Type' },
  'label.tag': { ar: 'الوسم', fr: 'Étiquette' },
  'label.tags': { ar: 'الوسوم', fr: 'Étiquettes' },
  'label.skills': { ar: 'المهارات', fr: 'Compétences' },
  'label.skillsNeeded': { ar: 'المهارات المطلوبة', fr: 'Compétences requises' },
  'label.deadline': { ar: 'الموعد النهائي', fr: 'Date limite' },
  'label.posted': { ar: 'تاريخ النشر', fr: 'Publié' },
  'label.added': { ar: 'تاريخ الإضافة', fr: 'Ajouté' },
  'label.amount': { ar: 'المبلغ', fr: 'Montant' },
  'label.unpaid': { ar: 'غير مدفوع', fr: 'Non rémunéré' },
  'label.from': { ar: 'من', fr: 'À partir de' },
  'label.country': { ar: 'البلد', fr: 'Pays' },
  'label.city': { ar: 'المدينة', fr: 'Ville' },
  'label.level': { ar: 'المستوى', fr: 'Niveau' },
  'label.category': { ar: 'الفئة', fr: 'Catégorie' },
  'label.fundingType': { ar: 'نوع التمويل', fr: 'Type de financement' },
  'label.applyUrl': { ar: 'رابط التقديم', fr: 'URL de candidature' },
  'label.eligibility': { ar: 'شروط الأهلية', fr: 'Éligibilité' },
  'label.requirements': { ar: 'المتطلبات', fr: 'Exigences' },
  'label.workMode': { ar: 'نمط العمل', fr: 'Mode de travail' },
  'label.employment': { ar: 'نوع التوظيف', fr: 'Type d\'emploi' },
  'label.publisher': { ar: 'الناشر', fr: 'Publicateur' },
  'label.provider': { ar: 'المزود', fr: 'Fournisseur' },
  'label.author': { ar: 'المؤلف', fr: 'Auteur' },
  'label.source': { ar: 'المصدر', fr: 'Source' },
  'label.link': { ar: 'الرابط', fr: 'Lien' },
  'label.coverLetter': { ar: 'خطاب التغطية', fr: 'Lettre de motivation' },
  'label.appliedAt': { ar: 'تاريخ التقديم', fr: 'Date de candidature' },
  'label.opportunity': { ar: 'الفرصة', fr: 'Opportunité' },
  'label.company': { ar: 'الشركة', fr: 'Entreprise' },
  'label.companyName': { ar: 'اسم الشركة', fr: 'Nom de l\'entreprise' },
  'label.companySize': { ar: 'حجم الشركة', fr: 'Taille de l\'entreprise' },
  'label.sector': { ar: 'القطاع', fr: 'Secteur' },
  'label.registrationNumber': { ar: 'رقم التسجيل', fr: 'N° d\'enregistrement' },
  'label.website': { ar: 'الموقع الإلكتروني', fr: 'Site web' },
  'label.student': { ar: 'الطالب', fr: 'Étudiant' },
  'label.academicLevel': { ar: 'المستوى الأكاديمي', fr: 'Niveau académique' },
  'label.university': { ar: 'الجامعة', fr: 'Université' },
  'label.fieldOfStudy': { ar: 'مجال الدراسة', fr: 'Domaine d\'études' },
  'label.researchTopic': { ar: 'موضوع البحث', fr: 'Sujet de recherche' },
  'label.laboratory': { ar: 'المختبر', fr: 'Laboratoire' },
  'label.supervisor': { ar: 'المشرف', fr: 'Superviseur' },
  'label.approval': { ar: 'الموافقة', fr: 'Approbation' },
  'label.bio': { ar: 'النبذة', fr: 'Biographie' },
  'label.about': { ar: 'حول', fr: 'À propos' },
  'label.academic': { ar: 'أكاديمي', fr: 'Académique' },
  'label.joined': { ar: 'انضم في', fr: 'Inscrit le' },
  'label.role': { ar: 'الدور', fr: 'Rôle' },
  'label.role.student': { ar: 'طالب', fr: 'Étudiant' },
  'label.role.company': { ar: 'شركة', fr: 'Entreprise' },
  'label.role.admin': { ar: 'مسؤول', fr: 'Administrateur' },
  'label.role.user': { ar: 'مستخدم', fr: 'Utilisateur' },
  'label.summary': { ar: 'الملخص', fr: 'Résumé' },
  'label.problemStatement': { ar: 'بيان المشكلة', fr: 'Énoncé du problème' },
  'label.solution': { ar: 'الحل', fr: 'Solution' },
  'label.toolsStack': { ar: 'الأدوات والتقنيات', fr: 'Outils & technologies' },
  'label.domain': { ar: 'المجال', fr: 'Domaine' },
  'label.stage': { ar: 'المرحلة', fr: 'Étape' },
  'label.submittedBy': { ar: 'قدّمها', fr: 'Soumis par' },
  'label.submitted': { ar: 'تاريخ التقديم', fr: 'Soumis le' },
  'label.applications': { ar: 'الطلبات', fr: 'Candidatures' },
  'label.publishedContent': { ar: 'المحتوى المنشور', fr: 'Contenu publié' },
  'label.commercialRegister': { ar: 'السجل التجاري', fr: 'Registre du commerce' },
  'label.document': { ar: 'المستند', fr: 'Document' },
  'label.uploaded': { ar: 'تم الرفع', fr: 'Téléversé' },
  'label.notProvided': { ar: 'غير متوفر', fr: 'Non fourni' },
  'label.commercialRegisterMissing': { ar: 'السجل التجاري مفقود.', fr: 'Le registre du commerce est manquant.' },
  'label.noResults': { ar: 'لا توجد نتائج', fr: 'Aucun résultat' },

  // ─── Statuses ───────────────────────────────────────────
  'status.active': { ar: 'نشط', fr: 'Actif' },
  'status.inactive': { ar: 'غير نشط', fr: 'Inactif' },
  'status.blocked': { ar: 'محظور', fr: 'Bloqué' },
  'status.pending': { ar: 'قيد الانتظار', fr: 'En attente' },
  'status.approved': { ar: 'موافَق عليه', fr: 'Approuvé' },
  'status.rejected': { ar: 'مرفوض', fr: 'Refusé' },
  'status.accepted': { ar: 'مقبول', fr: 'Accepté' },
  'status.reviewed': { ar: 'تمت المراجعة', fr: 'Examiné' },
  'status.featured': { ar: 'مميز', fr: 'Mis en avant' },
  'status.hidden': { ar: 'مخفي', fr: 'Masqué' },
  'status.open': { ar: 'مفتوح', fr: 'Ouvert' },
  'status.closed': { ar: 'مغلق', fr: 'Fermé' },
  'status.draft': { ar: 'مسودة', fr: 'Brouillon' },
  'status.withdrawn': { ar: 'مُسحب', fr: 'Retiré' },
  'status.visible': { ar: 'مرئي', fr: 'Visible' },

  // ─── Counts / summaries ─────────────────────────────────
  'count.total': { ar: 'الإجمالي', fr: 'Total' },
  'count.totalLabel': { ar: 'إجمالي', fr: 'Total' },
  'count.pending': { ar: 'قيد الانتظار', fr: 'En attente' },
  'count.accepted': { ar: 'مقبولة', fr: 'Acceptées' },
  'count.approved': { ar: 'موافَق عليها', fr: 'Approuvées' },
  'count.rejected': { ar: 'مرفوضة', fr: 'Refusées' },

  // ─── Activity / type labels ─────────────────────────────
  'type.application': { ar: 'طلب', fr: 'Candidature' },
  'type.opportunity': { ar: 'فرصة', fr: 'Opportunité' },
  'type.scholarship': { ar: 'منحة', fr: 'Bourse' },
  'type.training': { ar: 'تدريب', fr: 'Formation' },
  'type.project_idea': { ar: 'فكرة مشروع', fr: 'Idée de projet' },
  'type.user': { ar: 'حساب', fr: 'Compte' },
  'type.activity': { ar: 'نشاط', fr: 'Activité' },
  'type.job': { ar: 'وظيفة', fr: 'Emploi' },
  'type.internship': { ar: 'تدريب', fr: 'Stage' },
  'type.contract': { ar: 'عقد', fr: 'Contrat' },
  'type.volunteer': { ar: 'تطوع', fr: 'Bénévolat' },
  'type.freelance': { ar: 'عمل حر', fr: 'Freelance' },
  'type.sponsoring': { ar: 'رعاية', fr: 'Sponsoring' },

  // Plural forms used in lists
  'plural.jobs': { ar: 'وظائف', fr: 'Emplois' },
  'plural.internships': { ar: 'تدريبات', fr: 'Stages' },
  'plural.sponsored': { ar: 'مموَّلة', fr: 'Sponsorisés' },
  'plural.scholarships': { ar: 'المنح', fr: 'Bourses' },
  'plural.opportunities': { ar: 'الفرص', fr: 'Opportunités' },
  'plural.applications': { ar: 'الطلبات', fr: 'Candidatures' },
  'plural.trainings': { ar: 'التدريبات', fr: 'Formations' },
  'plural.projectIdeas': { ar: 'أفكار المشاريع', fr: 'Idées de projets' },
  'plural.conversations': { ar: 'المحادثات', fr: 'Conversations' },
  'plural.books': { ar: 'الكتب', fr: 'Livres' },
  'plural.videos': { ar: 'الفيديوهات', fr: 'Vidéos' },
  'plural.ideas': { ar: 'أفكار', fr: 'idées' },
  'plural.resources': { ar: 'موارد', fr: 'ressources' },
  'plural.sponsoring': { ar: 'رعاية', fr: 'Sponsoring' },

  // ─── Time labels ────────────────────────────────────────
  'time.justNow': { ar: 'الآن', fr: 'À l\'instant' },
  'time.minutesAgo': { ar: 'د', fr: 'min' },
  'time.hoursAgo': { ar: 'س', fr: 'h' },
  'time.ago': { ar: 'منذ', fr: 'il y a' },

  // ─── Empty / feedback ───────────────────────────────────
  'feedback.success': { ar: 'تم بنجاح', fr: 'Succès' },
  'feedback.somethingWentWrong': { ar: 'حدث خطأ ما', fr: 'Une erreur est survenue' },
  'feedback.attentionNeeded': { ar: 'يتطلب الانتباه', fr: 'Attention requise' },
  'feedback.update': { ar: 'تحديث', fr: 'Mise à jour' },
  'feedback.notice': { ar: 'إشعار', fr: 'Avis' },
  'feedback.nothingToShow': { ar: 'لا شيء لعرضه بعد', fr: 'Rien à afficher pour l\'instant' },
  'feedback.couldNotLoadDetails': { ar: 'تعذّر تحميل التفاصيل.', fr: 'Impossible de charger les détails.' },
  'feedback.couldNotLoadActivity': { ar: 'تعذّر تحميل النشاط.', fr: 'Impossible de charger l\'activité.' },
  'feedback.couldNotLoadNotifications': { ar: 'تعذّر تحميل الإشعارات.', fr: 'Impossible de charger les notifications.' },
  'feedback.couldNotLoadDashboard': { ar: 'تعذّر تحميل لوحة التحكم. حاول مرة أخرى.', fr: 'Impossible de charger le tableau de bord. Réessayez.' },
  'feedback.unableToLoad': { ar: 'تعذّر التحميل', fr: 'Chargement impossible' },
  'feedback.loadingDetails': { ar: 'جارٍ تحميل التفاصيل…', fr: 'Chargement des détails…' },

  // ─── Notifications page ─────────────────────────────────
  'notif.all': { ar: 'الكل', fr: 'Tout' },
  'notif.unread': { ar: 'غير المقروءة', fr: 'Non lues' },
  'notif.read': { ar: 'المقروءة', fr: 'Lues' },
  'notif.inboxEmpty': { ar: 'الصندوق فارغ', fr: 'Boîte vide' },
  'notif.allCaughtUp': { ar: 'لقد اطّلعت على كل شيء.', fr: 'Vous êtes à jour.' },
  'notif.markedAllRead': { ar: 'تم وضع علامة قراءة على جميع الإشعارات.', fr: 'Toutes les notifications ont été marquées comme lues.' },
  'notif.couldNotMarkAll': { ar: 'تعذّر وضع علامة قراءة على الكل.', fr: 'Impossible de tout marquer comme lu.' },

  // ─── Activity page ──────────────────────────────────────
  'activity.searchPlaceholder': { ar: 'ابحث بالعنوان أو الشخص أو الحالة...', fr: 'Rechercher par titre, personne ou statut...' },
  'activity.allTypes': { ar: 'جميع الأنواع', fr: 'Tous les types' },
  'activity.applications': { ar: 'الطلبات', fr: 'Candidatures' },
  'activity.opportunities': { ar: 'الفرص', fr: 'Opportunités' },
  'activity.scholarships': { ar: 'المنح', fr: 'Bourses' },
  'activity.trainings': { ar: 'التدريبات', fr: 'Formations' },
  'activity.projectIdeas': { ar: 'أفكار المشاريع', fr: 'Idées de projets' },
  'activity.accounts': { ar: 'الحسابات', fr: 'Comptes' },
  'activity.noMatching': { ar: 'لا يوجد نشاط مطابق', fr: 'Aucune activité correspondante' },
  'activity.tryChange': { ar: 'جرّب تغيير النوع أو مسح البحث.', fr: 'Essayez de changer le type ou d\'effacer la recherche.' },
  'activity.noActivity': { ar: 'لا يوجد نشاط', fr: 'Aucune activité' },
  'activity.nothingHappened': { ar: 'لم يحدث شيء مؤخرًا.', fr: 'Rien ne s\'est passé récemment.' },

  // ─── Dashboard ──────────────────────────────────────────
  'dash.commandCenter': { ar: 'مركز التحكم', fr: 'Centre de contrôle' },
  'dash.brand': { ar: 'مسؤول FutureGate', fr: 'Admin FutureGate' },
  'dash.usersCount': { ar: 'مستخدمون', fr: 'utilisateurs' },
  'dash.opportunitiesCount': { ar: 'فرص', fr: 'opportunités' },
  'dash.itemsNeedReview': { ar: 'بحاجة إلى مراجعة', fr: 'à examiner' },
  'dash.upToDate': { ar: 'كل شيء محدّث', fr: 'Tout est à jour' },
  'dash.companies': { ar: 'الشركات', fr: 'Entreprises' },
  'dash.projectIdeas': { ar: 'أفكار المشاريع', fr: 'Idées de projets' },
  'dash.applications': { ar: 'الطلبات', fr: 'Candidatures' },
  'dash.activity': { ar: 'النشاط', fr: 'Activité' },
  'dash.library': { ar: 'المكتبة', fr: 'Bibliothèque' },
  'dash.controlRoom': { ar: 'غرفة التحكم', fr: 'Salle de contrôle' },
  'dash.controlRoomCopy': { ar: 'العناصر التي تحتاج إلى انتباهك الآن.', fr: 'Éléments qui nécessitent votre attention maintenant.' },
  'dash.allClear': { ar: 'كل شيء جاهز', fr: 'Tout est en règle' },
  'dash.pendingIdeas': { ar: 'أفكار مشاريع بانتظار المراجعة', fr: 'Idées de projets en attente d\'examen' },
  'dash.pendingApps': { ar: 'الطلبات قيد الانتظار', fr: 'Candidatures en attente' },
  'dash.pendingCompanies': { ar: 'شركات بانتظار الموافقة', fr: 'Entreprises en attente d\'approbation' },
  'dash.blockedUsers': { ar: 'مستخدمون محظورون', fr: 'Utilisateurs bloqués' },
  'dash.hiddenOpps': { ar: 'فرص مخفية', fr: 'Opportunités masquées' },
  'dash.platformOverview': { ar: 'نظرة عامة على المنصة', fr: 'Aperçu de la plateforme' },
  'dash.platformOverviewCopy': { ar: 'عدد المستخدمين المباشر عبر جميع أنواع الحسابات.', fr: 'Nombre d\'utilisateurs en direct, tous types de comptes.' },
  'dash.totalUsers': { ar: 'إجمالي المستخدمين', fr: 'Total des utilisateurs' },
  'dash.activeUsers': { ar: 'النشطون', fr: 'Actifs' },
  'dash.inactiveUsers': { ar: 'غير النشطين', fr: 'Inactifs' },
  'dash.studentsCount': { ar: 'الطلاب', fr: 'Étudiants' },
  'dash.companiesCount': { ar: 'الشركات', fr: 'Entreprises' },
  'dash.academicLevels': { ar: 'المستويات الأكاديمية', fr: 'Niveaux académiques' },
  'dash.academicLevelsCopy': { ar: 'توزيع الطلاب حسب الدرجة العلمية.', fr: 'Répartition des étudiants par diplôme.' },
  'dash.usersByLevel': { ar: 'المستخدمون حسب المستوى الأكاديمي', fr: 'Utilisateurs par niveau académique' },
  'dash.roleDistribution': { ar: 'توزيع الأدوار', fr: 'Répartition par rôle' },
  'dash.monthlyRegistrations': { ar: 'التسجيلات الشهرية', fr: 'Inscriptions mensuelles' },
  'dash.contentInventory': { ar: 'جرد المحتوى', fr: 'Inventaire du contenu' },
  'dash.contentInventoryCopy': { ar: 'إجمالي المحتوى المنشور والنشط عبر جميع الفئات.', fr: 'Total des contenus publiés et actifs, toutes catégories.' },
  'dash.opportunities': { ar: 'الفرص', fr: 'Opportunités' },
  'dash.applicationsLabel': { ar: 'الطلبات', fr: 'Candidatures' },
  'dash.scholarships': { ar: 'المنح الدراسية', fr: 'Bourses' },
  'dash.trainings': { ar: 'التدريبات', fr: 'Formations' },
  'dash.projectIdeasLabel': { ar: 'أفكار المشاريع', fr: 'Idées de projets' },
  'dash.conversations': { ar: 'المحادثات', fr: 'Conversations' },
  'dash.engagement': { ar: 'تحليلات المشاركة', fr: 'Analytique d\'engagement' },
  'dash.engagementCopy': { ar: 'مقاييس الأداء الرئيسية للمنصة.', fr: 'Indicateurs clés de performance de la plateforme.' },
  'dash.applicationRate': { ar: 'معدل التقديم', fr: 'Taux de candidature' },
  'dash.appsPerOpp': { ar: 'طلب لكل فرصة', fr: 'cand. par opportunité' },
  'dash.cvCompletion': { ar: 'اكتمال السيرة الذاتية', fr: 'Complétude des CV' },
  'dash.cvCompletionFmt': { ar: 'من الطلاب', fr: 'des étudiants' },
  'dash.ideasPipeline': { ar: 'قائمة أفكار المشاريع', fr: 'Pipeline des idées de projets' },
  'dash.pendingShort': { ar: 'قيد الانتظار', fr: 'En attente' },
  'dash.approvedShort': { ar: 'موافَق عليها', fr: 'Approuvées' },
  'dash.mostApplied': { ar: 'الأكثر تقديمًا', fr: 'Plus candidatées' },
  'dash.mostSaved': { ar: 'الأكثر حفظًا', fr: 'Plus sauvegardées' },
  'dash.apps': { ar: 'طلبات', fr: 'cand.' },
  'dash.saves': { ar: 'حفظ', fr: 'sauv.' },
  'dash.noHighlights': { ar: 'لا توجد إبرازات بعد', fr: 'Aucun fait marquant pour l\'instant' },
  'dash.highlightsAppear': { ar: 'تظهر الإبرازات هنا بمجرد نمو النشاط.', fr: 'Les faits marquants apparaissent ici dès que l\'activité augmente.' },
  'dash.quickActions': { ar: 'إجراءات سريعة', fr: 'Actions rapides' },
  'dash.quickActionsCopy': { ar: 'انتقل مباشرة إلى أي قائمة إشراف.', fr: 'Accédez directement à toute file de modération.' },
  'dash.quickOpportunities': { ar: 'الفرص', fr: 'Opportunités' },
  'dash.quickOpportunitiesCopy': { ar: 'مراجعة الوظائف والتدريبات والرعاية.', fr: 'Examiner emplois, stages et publications sponsorisées.' },
  'dash.quickPendingApps': { ar: 'طلبات قيد الانتظار', fr: 'Candidatures en attente' },
  'dash.quickPendingAppsCopy': { ar: 'راجع الطلبات داخل منشورات المسؤول.', fr: 'Examinez les candidatures dans les posts admin.' },
  'dash.quickScholarships': { ar: 'المنح الدراسية', fr: 'Bourses' },
  'dash.quickScholarshipsCopy': { ar: 'انشر وأدِر المنح الدراسية.', fr: 'Publiez et gérez les bourses.' },
  'dash.quickTrainings': { ar: 'التدريبات', fr: 'Formations' },
  'dash.quickTrainingsCopy': { ar: 'استورد وأدِر مقاطع الفيديو التدريبية.', fr: 'Importez et gérez les vidéos de formation.' },
  'dash.quickLibrary': { ar: 'المكتبة', fr: 'Bibliothèque' },
  'dash.quickLibraryCopy': { ar: 'استورد وأدِر موارد الكتب.', fr: 'Importez et gérez les ressources de livres.' },
  'dash.quickProjectIdeas': { ar: 'أفكار المشاريع', fr: 'Idées de projets' },
  'dash.quickProjectIdeasCopy': { ar: 'الموافقة على إرسالات الطلاب.', fr: 'Approuver les soumissions des étudiants.' },
  'dash.quickUsers': { ar: 'المستخدمون', fr: 'Utilisateurs' },
  'dash.quickUsersCopy': { ar: 'الموافقة على الشركات وإدارة الحسابات.', fr: 'Approuver des entreprises, gérer les comptes.' },
  'dash.quickActivity': { ar: 'النشاط', fr: 'Activité' },
  'dash.quickActivityCopy': { ar: 'شاهد أحدث أحداث المنصة.', fr: 'Voir les derniers événements de la plateforme.' },
  'dash.recentActivity': { ar: 'النشاط الأخير', fr: 'Activité récente' },
  'dash.recentUsers': { ar: 'المستخدمون الأخيرون', fr: 'Utilisateurs récents' },
  'dash.recentOpps': { ar: 'الفرص الأخيرة', fr: 'Opportunités récentes' },
  'dash.noUsersYet': { ar: 'لا يوجد مستخدمون بعد.', fr: 'Aucun utilisateur pour le moment.' },
  'dash.empty': { ar: 'فارغ', fr: 'Vide' },
  'dash.noOppsYet': { ar: 'لا توجد فرص بعد.', fr: 'Aucune opportunité pour le moment.' },
  'dash.featured': { ar: 'مميز', fr: 'À la une' },

  // ─── Users page ─────────────────────────────────────────
  'users.title': { ar: 'المستخدمون', fr: 'Utilisateurs' },
  'users.userProfile': { ar: 'الملف الشخصي للمستخدم', fr: 'Profil utilisateur' },
  'users.applications': { ar: 'الطلبات', fr: 'Candidatures' },
  'users.searchPlaceholder': { ar: 'البحث بالاسم أو البريد الإلكتروني...', fr: 'Recherche par nom ou e-mail...' },
  'users.allRoles': { ar: 'جميع الأدوار', fr: 'Tous les rôles' },
  'users.students': { ar: 'الطلاب', fr: 'Étudiants' },
  'users.companies': { ar: 'الشركات', fr: 'Entreprises' },
  'users.admins': { ar: 'المسؤولون', fr: 'Administrateurs' },
  'users.allStatuses': { ar: 'جميع الحالات', fr: 'Tous les statuts' },
  'users.activeFilter': { ar: 'النشطون', fr: 'Actifs' },
  'users.blockedFilter': { ar: 'المحظورون', fr: 'Bloqués' },
  'users.pendingApproval': { ar: 'قيد الموافقة', fr: 'En attente d\'approbation' },
  'users.viewProfile': { ar: 'عرض الملف الشخصي', fr: 'Voir le profil' },
  'users.block': { ar: 'حظر', fr: 'Bloquer' },
  'users.unblock': { ar: 'إلغاء الحظر', fr: 'Débloquer' },
  'users.approve': { ar: 'موافقة', fr: 'Approuver' },
  'users.reject': { ar: 'رفض', fr: 'Refuser' },
  'users.delete': { ar: 'حذف الحساب', fr: 'Supprimer le compte' },
  'users.deleteConfirm': { ar: 'هل أنت متأكد من حذف هذا الحساب؟', fr: 'Voulez-vous vraiment supprimer ce compte ?' },
  'users.couldNotLoad': { ar: 'تعذّر تحميل المستخدمين.', fr: 'Impossible de charger les utilisateurs.' },
  'users.noResults': { ar: 'لا يوجد مستخدمون مطابقون', fr: 'Aucun utilisateur correspondant' },
  'users.tryClear': { ar: 'جرّب مسح المرشّحات.', fr: 'Essayez d\'effacer les filtres.' },
  'users.userBlocked': { ar: 'تم حظر المستخدم.', fr: 'Utilisateur bloqué.' },
  'users.userUnblocked': { ar: 'تم إلغاء حظر المستخدم.', fr: 'Utilisateur débloqué.' },
  'users.companyApproved': { ar: 'تمت الموافقة على الشركة.', fr: 'Entreprise approuvée.' },
  'users.companyRejected': { ar: 'تم رفض الشركة.', fr: 'Entreprise refusée.' },
  'users.userDeleted': { ar: 'تم حذف الحساب.', fr: 'Compte supprimé.' },
  'users.couldNotUpdate': { ar: 'تعذّر تحديث المستخدم.', fr: 'Impossible de mettre à jour l\'utilisateur.' },
  'users.couldNotDelete': { ar: 'تعذّر حذف المستخدم.', fr: 'Impossible de supprimer l\'utilisateur.' },

  // ─── Moderation / content ───────────────────────────────
  'mod.title': { ar: 'المحتوى', fr: 'Contenu' },
  'mod.editorEdit': { ar: 'تعديل', fr: 'Modifier' },
  'mod.applicationCv': { ar: 'السيرة الذاتية للطلب', fr: 'CV de candidature' },
  'mod.tabIdeas': { ar: 'أفكار المشاريع', fr: 'Idées de projets' },
  'mod.tabOpportunities': { ar: 'الفرص', fr: 'Opportunités' },
  'mod.tabScholarships': { ar: 'المنح', fr: 'Bourses' },
  'mod.tabLibrary': { ar: 'المكتبة', fr: 'Bibliothèque' },
  'mod.tab.ideas': { ar: 'أفكار المشاريع', fr: 'Idées de projets' },
  'mod.tab.opportunities': { ar: 'الفرص', fr: 'Opportunités' },
  'mod.tab.scholarships': { ar: 'المنح', fr: 'Bourses' },
  'mod.tab.library': { ar: 'المكتبة', fr: 'Bibliothèque' },
  'mod.searchPlaceholder': { ar: 'بحث...', fr: 'Rechercher...' },
  'mod.adminPosts': { ar: 'منشورات المسؤول', fr: 'Posts admin' },
  'mod.hasPendingApps': { ar: 'بها طلبات قيد الانتظار', fr: 'A des candidatures en attente' },
  'mod.anyType': { ar: 'أي نوع', fr: 'Tout type' },
  'mod.allOpportunities': { ar: 'جميع الفرص', fr: 'Toutes les opportunités' },
  'mod.filter.all': { ar: 'الكل', fr: 'Tout' },
  'mod.filter.adminPosts': { ar: 'منشورات المسؤول', fr: 'Posts admin' },
  'mod.filter.allOpportunities': { ar: 'جميع الفرص', fr: 'Toutes les opportunités' },
  'mod.filter.hasPendingApps': { ar: 'بها طلبات قيد الانتظار', fr: 'A des candidatures en attente' },
  'mod.filter.anyType': { ar: 'أي نوع', fr: 'Tout type' },
  'mod.pill.pendingIdeas': { ar: 'أفكار قيد الانتظار', fr: 'Idées en attente' },
  'mod.pill.pendingApps': { ar: 'طلبات قيد الانتظار', fr: 'Candidatures en attente' },
  'mod.couldNotLoad': { ar: 'تعذّر تحميل المحتوى.', fr: 'Impossible de charger le contenu.' },
  'mod.couldNotLoadContent': { ar: 'تعذّر تحميل المحتوى.', fr: 'Impossible de charger le contenu.' },
  'mod.couldNotLoadPublisher': { ar: 'تعذّر تحميل الملف الشخصي للناشر.', fr: 'Impossible de charger le profil du publicateur.' },
  'mod.noResults': { ar: 'لا توجد نتائج', fr: 'Aucun résultat' },
  'mod.tryClearFilters': { ar: 'جرّب تعديل المرشّحات.', fr: 'Essayez d\'ajuster les filtres.' },
  'mod.untitled': { ar: 'بدون عنوان', fr: 'Sans titre' },
  'mod.publisher': { ar: 'الناشر', fr: 'Publicateur' },
  'mod.confirmDelete': { ar: 'هل أنت متأكد من الحذف؟', fr: 'Voulez-vous vraiment supprimer ?' },
  'mod.deleted': { ar: 'تم الحذف.', fr: 'Supprimé.' },
  'mod.updated': { ar: 'تم التحديث.', fr: 'Mis à jour.' },
  'mod.couldNotUpdate': { ar: 'تعذّر التحديث.', fr: 'Mise à jour impossible.' },
  'mod.couldNotDelete': { ar: 'تعذّر الحذف.', fr: 'Suppression impossible.' },
  'mod.viewCv': { ar: 'عرض السيرة الذاتية', fr: 'Voir le CV' },
  'mod.downloadCv': { ar: 'تنزيل السيرة الذاتية', fr: 'Télécharger le CV' },
  'mod.cvUnavailable': { ar: 'السيرة الذاتية غير متوفرة.', fr: 'CV non disponible.' },
  'mod.markReviewed': { ar: 'وضع علامة كمُراجَع', fr: 'Marquer comme examiné' },
  'mod.applicationApproved': { ar: 'تمت الموافقة على الطلب.', fr: 'Candidature approuvée.' },
  'mod.applicationRejected': { ar: 'تم رفض الطلب.', fr: 'Candidature refusée.' },
  'mod.applicationReviewed': { ar: 'تمت مراجعة الطلب.', fr: 'Candidature examinée.' },

  // ─── Moderation toasts ──────────────────────────────────
  'toast.ideaApproved':  { ar: 'تمت الموافقة على الفكرة.', fr: 'Idée approuvée.' },
  'toast.ideaRejected':  { ar: 'تم رفض الفكرة.', fr: 'Idée refusée.' },
  'toast.ideaHidden':    { ar: 'تم إخفاء الفكرة.', fr: 'Idée masquée.' },
  'toast.ideaVisible':   { ar: 'الفكرة مرئية مرة أخرى.', fr: 'Idée à nouveau visible.' },
  'toast.ideaDeleted':   { ar: 'تم حذف الفكرة.', fr: 'Idée supprimée.' },
  'toast.canEditOwnIdea':{ ar: 'يمكنك تعديل الأفكار التي نشرتها كمسؤول فقط.', fr: 'Vous ne pouvez modifier que les idées publiées en tant qu\'admin.' },
  'toast.canEditOwnApp': { ar: 'يمكنك تحديث الطلبات على الفرص التي نشرتها كمسؤول فقط.', fr: 'Vous ne pouvez mettre à jour que les candidatures aux opportunités publiées en tant qu\'admin.' },
  'toast.canEditOwnOpp': { ar: 'يمكنك تعديل الفرص التي نشرتها كمسؤول فقط.', fr: 'Vous ne pouvez modifier que les opportunités publiées en tant qu\'admin.' },
  'toast.actionFailed':  { ar: 'فشل الإجراء.', fr: 'Action échouée.' },
  'toast.opportunityHidden':  { ar: 'تم إخفاء الفرصة.', fr: 'Opportunité masquée.' },
  'toast.opportunityVisible': { ar: 'الفرصة مرئية.', fr: 'Opportunité visible.' },
  'toast.opportunityDeleted': { ar: 'تم حذف الفرصة.', fr: 'Opportunité supprimée.' },
  'toast.scholarshipDeleted': { ar: 'تم حذف المنحة.', fr: 'Bourse supprimée.' },
  'toast.resourceDeleted':    { ar: 'تم حذف المورد.', fr: 'Ressource supprimée.' },
  'toast.hidden':        { ar: 'تم الإخفاء.', fr: 'Masqué.' },
  'toast.visible':       { ar: 'مرئي.', fr: 'Visible.' },
  'toast.featured':      { ar: 'تم التمييز.', fr: 'Mis en avant.' },
  'toast.unfeatured':    { ar: 'تم إلغاء التمييز.', fr: 'Mise en avant retirée.' },
  'toast.chooseDomain':  { ar: 'اختر المجال قبل الاستيراد.', fr: 'Choisissez un domaine avant d\'importer.' },
  'toast.chooseLanguageYt': { ar: 'اختر اللغة قبل استيراد مورد YouTube.', fr: 'Choisissez une langue avant d\'importer une ressource YouTube.' },
  'toast.bookImported':  { ar: 'تم استيراد الكتاب إلى المكتبة.', fr: 'Livre importé dans la bibliothèque.' },
  'toast.videoImported': { ar: 'تم استيراد الفيديو إلى المكتبة.', fr: 'Vidéo importée dans la bibliothèque.' },
  'toast.importFailed':  { ar: 'فشل الاستيراد.', fr: 'Importation échouée.' },

  // ─── Editor pages (opp/scholarship/idea) ────────────────
  'editor.opp.title': { ar: 'محرر الفرصة', fr: 'Éditeur d\'opportunité' },
  'editor.opp.heading': { ar: 'منشور المسؤول · فرصة', fr: 'Post admin · Opportunité' },
  'editor.scholarship.title': { ar: 'محرر المنحة', fr: 'Éditeur de bourse' },
  'editor.scholarship.heading': { ar: 'منشور المسؤول · منحة', fr: 'Post admin · Bourse' },
  'editor.idea.title': { ar: 'محرر الفكرة', fr: 'Éditeur d\'idée' },
  'editor.idea.heading': { ar: 'منشور المسؤول · فكرة', fr: 'Post admin · Idée' },
  'editor.saveChanges': { ar: 'حفظ التغييرات', fr: 'Enregistrer les modifications' },
  'editor.saved': { ar: 'تم الحفظ.', fr: 'Enregistré.' },
  'editor.couldNotSave': { ar: 'تعذّر الحفظ.', fr: 'Enregistrement impossible.' },
  'editor.required': { ar: 'مطلوب', fr: 'Requis' },
  'editor.optional': { ar: 'اختياري', fr: 'Facultatif' },

  // Editor — common
  'editor.backToContent': { ar: 'العودة إلى المحتوى', fr: 'Retour au contenu' },
  'editor.backToIdeas': { ar: 'العودة إلى الأفكار', fr: 'Retour aux idées' },
  'editor.backToOpportunities': { ar: 'العودة إلى الفرص', fr: 'Retour aux opportunités' },
  'editor.backToScholarships': { ar: 'العودة إلى المنح', fr: 'Retour aux bourses' },
  'editor.cancel': { ar: 'إلغاء', fr: 'Annuler' },
  'editor.publish': { ar: 'نشر', fr: 'Publier' },
  'editor.newPost': { ar: 'منشور جديد', fr: 'Nouveau post' },
  'editor.editingPost': { ar: 'تحرير المنشور', fr: 'Modification du post' },

  // Editor — idea page
  'editor.idea.unavailable': { ar: 'الفكرة غير متوفرة', fr: 'Idée indisponible' },
  'editor.idea.canEditOnlyOwn': { ar: 'يمكنك تعديل الأفكار التي نشرتها كمسؤول فقط.', fr: 'Vous ne pouvez modifier que les idées publiées en tant qu\'admin.' },
  'editor.idea.publishHeading': { ar: 'نشر الفكرة', fr: 'Publier une idée' },
  'editor.idea.editHeading': { ar: 'تعديل الفكرة', fr: 'Modifier l\'idée' },
  'editor.idea.subtitleNew': { ar: 'أنشئ فكرة مشروع يكتشفها الطلاب بسياق واضح وبيانات اكتشاف قوية.', fr: 'Créez une idée de projet que les étudiants pourront découvrir avec un contexte clair et des métadonnées solides.' },
  'editor.idea.subtitleEdit': { ar: 'حسّن هذه الفكرة بنصّ أوضح وبيانات اكتشاف أقوى وبنية أدق.', fr: 'Améliorez cette idée avec un texte plus clair, de meilleures métadonnées et une structure plus nette.' },
  'editor.idea.publishedToast': { ar: 'تم نشر فكرة المسؤول.', fr: 'Idée admin publiée.' },
  'editor.idea.updatedToast': { ar: 'تم تحديث فكرة المسؤول.', fr: 'Idée admin mise à jour.' },
  'editor.idea.titleMin': { ar: 'يجب أن يحتوي عنوان الفكرة على 4 أحرف على الأقل.', fr: 'Le titre de l\'idée doit comporter au moins 4 caractères.' },
  'editor.idea.descMin': { ar: 'يرجى إضافة المزيد من التفاصيل إلى نظرة عامة على الفكرة.', fr: 'Veuillez ajouter plus de détails à l\'aperçu de l\'idée.' },
  'editor.idea.categoryRequired': { ar: 'الفئة مطلوبة.', fr: 'La catégorie est requise.' },

  // Editor — opportunity page
  'editor.opp.unavailable': { ar: 'الفرصة غير متوفرة', fr: 'Opportunité indisponible' },
  'editor.opp.canEditOnlyOwn': { ar: 'يمكنك تعديل الفرص التي نشرتها كمسؤول فقط.', fr: 'Vous ne pouvez modifier que les opportunités publiées en tant qu\'admin.' },
  'editor.opp.publishHeading': { ar: 'نشر الفرصة', fr: 'Publier une opportunité' },
  'editor.opp.editHeading': { ar: 'تعديل الفرصة', fr: 'Modifier l\'opportunité' },
  'editor.opp.subtitleNew': { ar: 'أنشئ منشور فرصة احترافية يكتشفها الطلاب في التطبيق.', fr: 'Créez une publication d\'opportunité professionnelle que les étudiants découvriront dans l\'application.' },
  'editor.opp.subtitleEdit': { ar: 'حسّن هذه الفرصة ببنية أوضح وتفاصيل أقوى موجّهة للطلاب.', fr: 'Améliorez cette opportunité avec une structure plus nette et des détails plus pertinents.' },
  'editor.opp.publishedToast': { ar: 'تم نشر فرصة المسؤول.', fr: 'Opportunité admin publiée.' },
  'editor.opp.updatedToast': { ar: 'تم تحديث فرصة المسؤول.', fr: 'Opportunité admin mise à jour.' },
  'editor.opp.requiredFields': { ar: 'الناشر والعنوان والموقع والوصف حقول مطلوبة.', fr: 'Publicateur, titre, lieu et description sont requis.' },
  'editor.opp.deadlineRequired': { ar: 'الموعد النهائي للتقديم مطلوب.', fr: 'La date limite de candidature est requise.' },
  'editor.opp.deadlinePast': { ar: 'لا يمكن أن يكون الموعد النهائي في الماضي.', fr: 'La date limite ne peut pas être dans le passé.' },
  'editor.opp.eligibilityAtLeast': { ar: 'أضف عنصر أهلية واحدًا على الأقل.', fr: 'Ajoutez au moins une condition d\'éligibilité.' },
  'editor.opp.requirementsAtLeast': { ar: 'أضف متطلبًا واحدًا على الأقل.', fr: 'Ajoutez au moins une exigence.' },
  'editor.opp.fundingInvalid': { ar: 'أدخل مبلغ تمويل صالحًا.', fr: 'Entrez un montant de financement valide.' },
  'editor.opp.fundingOrNote': { ar: 'أضف مبلغ تمويل أو ملاحظة.', fr: 'Ajoutez un montant ou une note de financement.' },
  'editor.opp.salaryMinInvalid': { ar: 'أدخل حدًا أدنى صالحًا للراتب.', fr: 'Entrez un salaire minimum valide.' },
  'editor.opp.salaryMaxInvalid': { ar: 'أدخل حدًا أقصى صالحًا للراتب.', fr: 'Entrez un salaire maximum valide.' },
  'editor.opp.salaryMaxLessMin': { ar: 'يجب أن يكون الحد الأقصى للراتب أكبر من أو يساوي الحد الأدنى.', fr: 'Le salaire max doit être supérieur ou égal au salaire min.' },

  // Editor — scholarship page
  'editor.scholarship.publishHeading': { ar: 'نشر المنحة', fr: 'Publier une bourse' },
  'editor.scholarship.editHeading': { ar: 'تعديل المنحة', fr: 'Modifier la bourse' },
  'editor.scholarship.subtitleNew': { ar: 'أنشئ منشور منحة يكتشفه الطلاب في التطبيق.', fr: 'Créez une publication de bourse que les étudiants découvriront dans l\'application.' },
  'editor.scholarship.subtitleEdit': { ar: 'حسّن هذه المنحة ببنية أوضح وتفاصيل أهلية أقوى.', fr: 'Améliorez cette bourse avec une structure plus nette et des détails d\'éligibilité plus solides.' },
  'editor.scholarship.publishedToast': { ar: 'تم نشر المنحة.', fr: 'Bourse publiée.' },
  'editor.scholarship.updatedToast': { ar: 'تم تحديث المنحة.', fr: 'Bourse mise à jour.' },
  'editor.scholarship.featureLabel': { ar: 'تمييز هذه المنحة', fr: 'Mettre cette bourse en avant' },
  'editor.scholarship.featureHint': { ar: 'تموضع أقوى في تدفق اكتشاف الطلاب.', fr: 'Placement renforcé dans le flux de découverte des étudiants.' },
  'editor.scholarship.titleProviderDescRequired': { ar: 'العنوان والمزوّد والوصف مطلوبة.', fr: 'Titre, prestataire et description sont requis.' },
  'editor.scholarship.amountInvalid': { ar: 'أدخل مبلغًا صالحًا.', fr: 'Entrez un montant valide.' },
  'editor.scholarship.deadlineRequired': { ar: 'الموعد النهائي مطلوب.', fr: 'La date limite est requise.' },
  'editor.scholarship.deadlinePast': { ar: 'لا يمكن أن يكون الموعد النهائي في الماضي.', fr: 'La date limite ne peut pas être dans le passé.' },

  // Editor — section headings
  'editor.section.publishing': { ar: 'النشر', fr: 'Publication' },
  'editor.section.coreStory': { ar: 'القصة الأساسية', fr: 'Histoire principale' },
  'editor.section.metadataDiscovery': { ar: 'البيانات الوصفية والاكتشاف', fr: 'Métadonnées et découverte' },
  'editor.section.optionalExtras': { ar: 'إضافات اختيارية', fr: 'Compléments facultatifs' },
  'editor.section.basicInfo': { ar: 'المعلومات الأساسية', fr: 'Informations de base' },
  'editor.section.description': { ar: 'الوصف', fr: 'Description' },
  'editor.section.requirements': { ar: 'المتطلبات', fr: 'Exigences' },
  'editor.section.logistics': { ar: 'اللوجستيات', fr: 'Logistique' },
  'editor.section.logisticsCompensation': { ar: 'اللوجستيات والتعويضات', fr: 'Logistique et rémunération' },
  'editor.section.eligibility': { ar: 'متطلبات الأهلية', fr: 'Conditions d\'éligibilité' },
  'editor.section.additionalInfo': { ar: 'معلومات إضافية', fr: 'Informations supplémentaires' },

  // Editor — fields & inline labels
  'editor.field.publisherName': { ar: 'اسم الناشر', fr: 'Nom du publicateur' },
  'editor.field.statusLabel': { ar: 'الحالة', fr: 'Statut' },
  'editor.field.title': { ar: 'العنوان', fr: 'Titre' },
  'editor.field.language': { ar: 'اللغة', fr: 'Langue' },
  'editor.field.type': { ar: 'النوع', fr: 'Type' },
  'editor.field.location': { ar: 'الموقع', fr: 'Lieu' },
  'editor.field.descriptionRequired': { ar: 'الوصف *', fr: 'Description *' },
  'editor.field.requirementsRequired': { ar: 'المتطلبات *', fr: 'Exigences *' },
  'editor.field.requirementsHint': { ar: 'أدخل كل متطلب في سطر جديد.', fr: 'Entrez chaque exigence sur une nouvelle ligne.' },
  'editor.field.applicationDeadline': { ar: 'الموعد النهائي للتقديم', fr: 'Date limite de candidature' },
  'editor.field.salaryMin': { ar: 'الحد الأدنى للراتب', fr: 'Salaire minimum' },
  'editor.field.salaryMax': { ar: 'الحد الأقصى للراتب', fr: 'Salaire maximum' },
  'editor.field.currency': { ar: 'العملة', fr: 'Devise' },
  'editor.field.salaryPeriod': { ar: 'فترة الراتب', fr: 'Période salariale' },
  'editor.field.employmentType': { ar: 'نوع التوظيف', fr: 'Type d\'emploi' },
  'editor.field.workMode': { ar: 'طريقة العمل', fr: 'Mode de travail' },
  'editor.field.paidStatus': { ar: 'حالة الدفع', fr: 'Statut de rémunération' },
  'editor.field.duration': { ar: 'المدة', fr: 'Durée' },
  'editor.field.compensationNote': { ar: 'ملاحظة التعويض', fr: 'Note de rémunération' },
  'editor.field.fundingAmount': { ar: 'مبلغ التمويل', fr: 'Montant du financement' },
  'editor.field.fundingCurrency': { ar: 'عملة التمويل', fr: 'Devise du financement' },
  'editor.field.fundingNote': { ar: 'ملاحظة التمويل', fr: 'Note de financement' },
  'editor.field.ideaTitle': { ar: 'عنوان الفكرة *', fr: 'Titre de l\'idée *' },
  'editor.field.tagline': { ar: 'العنوان الفرعي', fr: 'Accroche' },
  'editor.field.ideaOverview': { ar: 'نظرة عامة على الفكرة *', fr: 'Aperçu de l\'idée *' },
  'editor.field.category': { ar: 'الفئة', fr: 'Catégorie' },
  'editor.field.academicLevel': { ar: 'المستوى الأكاديمي', fr: 'Niveau académique' },
  'editor.field.stage': { ar: 'المرحلة', fr: 'Étape' },
  'editor.field.skillsNeeded': { ar: 'المهارات المطلوبة', fr: 'Compétences requises' },
  'editor.field.teamRoles': { ar: 'الأدوار المطلوبة في الفريق', fr: 'Rôles d\'équipe requis' },
  'editor.field.targetAudience': { ar: 'الجمهور المستهدف', fr: 'Public cible' },
  'editor.field.problemStatement': { ar: 'بيان المشكلة', fr: 'Énoncé du problème' },
  'editor.field.solution': { ar: 'الحل المقترح', fr: 'Solution proposée' },
  'editor.field.resourcesNeeded': { ar: 'الموارد المطلوبة', fr: 'Ressources nécessaires' },
  'editor.field.benefits': { ar: 'الفوائد والأثر', fr: 'Avantages et impact' },
  'editor.field.coverImageUrl': { ar: 'رابط صورة الغلاف', fr: 'URL de l\'image de couverture' },
  'editor.field.deckLink': { ar: 'رابط العرض / العينة', fr: 'Lien de la présentation / démo' },
  'editor.field.scholarshipTitle': { ar: 'عنوان المنحة *', fr: 'Titre de la bourse *' },
  'editor.field.provider': { ar: 'المزوّد *', fr: 'Prestataire *' },
  'editor.field.eligibilityItems': { ar: 'عناصر الأهلية *', fr: 'Conditions d\'éligibilité *' },
  'editor.field.eligibilityHint': { ar: 'أدخل كل شرط أهلية في سطر جديد.', fr: 'Entrez chaque condition d\'éligibilité sur une nouvelle ligne.' },
  'editor.field.amount': { ar: 'المبلغ *', fr: 'Montant *' },
  'editor.field.deadlineRequired': { ar: 'الموعد النهائي *', fr: 'Date limite *' },
  'editor.field.country': { ar: 'البلد', fr: 'Pays' },
  'editor.field.city': { ar: 'المدينة', fr: 'Ville' },
  'editor.field.locationLabel': { ar: 'تسمية الموقع', fr: 'Libellé du lieu' },
  'editor.field.applicationLink': { ar: 'رابط التقديم', fr: 'Lien de candidature' },
  'editor.field.fundingType': { ar: 'نوع التمويل', fr: 'Type de financement' },
  'editor.field.tags': { ar: 'الوسوم', fr: 'Tags' },

  // Editor — visibility / option labels
  'editor.option.visible': { ar: 'مرئي', fr: 'Visible' },
  'editor.option.hidden': { ar: 'مخفي', fr: 'Masqué' },
  'editor.option.open': { ar: 'مفتوح', fr: 'Ouvert' },
  'editor.option.closed': { ar: 'مغلق', fr: 'Fermé' },
  'editor.option.selectStatus': { ar: 'اختر الحالة', fr: 'Sélectionner le statut' },
  'editor.option.paid': { ar: 'مدفوع', fr: 'Rémunéré' },
  'editor.option.unpaid': { ar: 'غير مدفوع', fr: 'Non rémunéré' },
  'editor.option.selectFundingType': { ar: 'اختر نوع التمويل', fr: 'Sélectionner le type de financement' },
  'editor.option.selectLevel': { ar: 'اختر المستوى', fr: 'Sélectionner le niveau' },

  'editor.lang.fr': { ar: 'الفرنسية', fr: 'Français' },
  'editor.lang.en': { ar: 'الإنجليزية', fr: 'Anglais' },
  'editor.lang.ar': { ar: 'العربية', fr: 'Arabe' },

  'editor.type.job': { ar: 'وظيفة', fr: 'Emploi' },
  'editor.type.internship': { ar: 'تدريب', fr: 'Stage' },
  'editor.type.sponsoring': { ar: 'رعاية / تمويل', fr: 'Sponsoring / Financement' },

  'editor.period.month': { ar: 'شهري', fr: 'Mensuel' },
  'editor.period.year': { ar: 'سنوي', fr: 'Annuel' },
  'editor.period.week': { ar: 'أسبوعي', fr: 'Hebdomadaire' },
  'editor.period.day': { ar: 'يومي', fr: 'Quotidien' },
  'editor.period.hour': { ar: 'بالساعة', fr: 'Horaire' },

  'editor.employment.full_time': { ar: 'دوام كامل', fr: 'Temps plein' },
  'editor.employment.part_time': { ar: 'دوام جزئي', fr: 'Temps partiel' },
  'editor.employment.internship': { ar: 'تدريب', fr: 'Stage' },
  'editor.employment.contract': { ar: 'عقد', fr: 'Contrat' },
  'editor.employment.temporary': { ar: 'مؤقت', fr: 'Temporaire' },
  'editor.employment.freelance': { ar: 'عمل حر', fr: 'Freelance' },

  'editor.workMode.onsite': { ar: 'في الموقع', fr: 'Sur site' },
  'editor.workMode.remote': { ar: 'عن بُعد', fr: 'À distance' },
  'editor.workMode.hybrid': { ar: 'هجين', fr: 'Hybride' },

  'editor.fundingType.fully_funded': { ar: 'تمويل كامل', fr: 'Entièrement financé' },
  'editor.fundingType.partial': { ar: 'تمويل جزئي', fr: 'Financement partiel' },
  'editor.fundingType.merit': { ar: 'على أساس الجدارة', fr: 'Au mérite' },
  'editor.fundingType.needs': { ar: 'على أساس الحاجة', fr: 'Selon les besoins' },

  'editor.saveFailed': { ar: 'فشل الحفظ', fr: 'Échec de l\'enregistrement' },

  // ─── Users page ────────────────────────────────────────
  'users.couldNotLoad': { ar: 'تعذّر تحميل المستخدمين.', fr: 'Impossible de charger les utilisateurs.' },
  'users.searchPlaceholder': { ar: 'ابحث بالاسم أو البريد أو الشركة...', fr: 'Rechercher par nom, e-mail ou entreprise...' },
  'users.summaryShown': { ar: '{n} مستخدم معروض من إجمالي {total}.', fr: '{n} utilisateurs affichés sur {total} au total.' },
  'users.summaryShownSingular': { ar: '{n} مستخدم معروض من إجمالي {total}.', fr: '{n} utilisateur affiché sur {total} au total.' },
  'users.notFoundTitle': { ar: 'لا يوجد مستخدم مطابق', fr: 'Aucun utilisateur correspondant' },
  'users.notFoundDesc': { ar: 'عدّل المرشّحات أو ابحث بطريقة مختلفة.', fr: 'Ajustez les filtres ou modifiez votre recherche.' },

  'users.summary.total': { ar: 'الإجمالي', fr: 'Total' },
  'users.summary.active': { ar: 'نشط', fr: 'Actifs' },
  'users.summary.blocked': { ar: 'محظور', fr: 'Bloqués' },
  'users.summary.admins': { ar: 'مسؤولون', fr: 'Administrateurs' },
  'users.summary.pendingReview': { ar: 'قيد المراجعة', fr: 'En attente de révision' },

  'users.chip.role.all': { ar: 'الكل', fr: 'Tous' },
  'users.chip.role.students': { ar: 'الطلاب', fr: 'Étudiants' },
  'users.chip.role.companies': { ar: 'الشركات', fr: 'Entreprises' },
  'users.chip.role.admins': { ar: 'المسؤولون', fr: 'Administrateurs' },
  'users.chip.accountState': { ar: 'حالة الحساب', fr: 'État du compte' },
  'users.chip.all': { ar: 'الكل', fr: 'Tous' },
  'users.chip.active': { ar: 'نشط', fr: 'Actif' },
  'users.chip.blocked': { ar: 'محظور', fr: 'Bloqué' },
  'users.chip.level': { ar: 'المستوى', fr: 'Niveau' },
  'users.chip.companyReview': { ar: 'مراجعة الشركة', fr: 'Révision entreprise' },
  'users.chip.disabledNote': { ar: 'معطّل أثناء تفعيل مرشّح المستوى', fr: 'Désactivé lorsque le filtre niveau est actif' },
  'users.chip.pending': { ar: 'قيد الانتظار', fr: 'En attente' },
  'users.chip.approved': { ar: 'موافَق', fr: 'Approuvé' },
  'users.chip.rejected': { ar: 'مرفوض', fr: 'Rejeté' },

  'users.action.approve': { ar: 'موافقة', fr: 'Approuver' },
  'users.action.reject': { ar: 'رفض', fr: 'Rejeter' },
  'users.action.block': { ar: 'حظر', fr: 'Bloquer' },
  'users.action.unblock': { ar: 'إلغاء الحظر', fr: 'Débloquer' },
  'users.action.view': { ar: 'عرض', fr: 'Voir' },

  'users.confirm.approveCompany.title': { ar: 'الموافقة على الشركة', fr: 'Approuver l\'entreprise' },
  'users.confirm.approveCompany.msg': { ar: 'ستتمكّن الشركة من نشر الفرص.', fr: 'L\'entreprise pourra publier des opportunités.' },
  'users.confirm.rejectCompany.title': { ar: 'رفض الشركة', fr: 'Rejeter l\'entreprise' },
  'users.confirm.rejectCompany.msg': { ar: 'ستظل الشركة مرئية للمسؤولين لكنها لن تتمكن من نشر محتوى مُعتمد.', fr: 'L\'entreprise restera visible pour les admins mais ne pourra pas publier de contenu approuvé.' },
  'users.confirm.movePending.title': { ar: 'إعادة إلى قيد الانتظار', fr: 'Remettre en attente' },
  'users.confirm.movePending.msg': { ar: 'ستحتاج الشركة إلى المراجعة من جديد.', fr: 'L\'entreprise devra être revue à nouveau.' },
  'users.confirm.blockUser.title': { ar: 'حظر المستخدم', fr: 'Bloquer l\'utilisateur' },
  'users.confirm.blockUser.msg': { ar: 'سيفقد المستخدم الوصول إلى التطبيق.', fr: 'L\'utilisateur perdra l\'accès à l\'application.' },
  'users.confirm.unblockUser.title': { ar: 'إلغاء حظر المستخدم', fr: 'Débloquer l\'utilisateur' },
  'users.confirm.unblockUser.msg': { ar: 'سيستعيد المستخدم الوصول.', fr: 'L\'utilisateur retrouvera l\'accès.' },

  'users.toast.companyApproved': { ar: 'تمت الموافقة على الشركة.', fr: 'Entreprise approuvée.' },
  'users.toast.companyRejected': { ar: 'تم رفض الشركة.', fr: 'Entreprise rejetée.' },
  'users.toast.companyMovedPending': { ar: 'تم نقل الشركة إلى قيد الانتظار.', fr: 'Entreprise remise en attente de révision.' },
  'users.toast.userBlocked': { ar: 'تم حظر المستخدم.', fr: 'Utilisateur bloqué.' },
  'users.toast.userUnblocked': { ar: 'تم إلغاء حظر المستخدم.', fr: 'Utilisateur débloqué.' },
  'users.toast.updated': { ar: 'تم التحديث.', fr: 'Mis à jour.' },
  'users.toast.updateFailed': { ar: 'فشل التحديث. أعد المحاولة.', fr: 'Échec de la mise à jour. Réessayez.' },

  'users.profile.couldNotLoad': { ar: 'تعذّر تحميل هذا الملف الشخصي.', fr: 'Impossible de charger ce profil.' },
  'users.subtitle.companyProfile': { ar: 'ملف شركة', fr: 'Profil entreprise' },
  'users.subtitle.studentProfile': { ar: 'ملف طالب', fr: 'Profil étudiant' },
  'users.subtitle.adminProfile': { ar: 'ملف مسؤول', fr: 'Profil admin' },
  'users.notProvided': { ar: 'غير متوفّر', fr: 'Non renseigné' },
  'users.unknown': { ar: 'غير معروف', fr: 'Inconnu' },

  'users.role.student': { ar: 'طالب', fr: 'Étudiant' },
  'users.role.company': { ar: 'شركة', fr: 'Entreprise' },
  'users.role.admin': { ar: 'مسؤول', fr: 'Admin' },
  'users.role.user': { ar: 'مستخدم', fr: 'Utilisateur' },

  'users.approval.pendingReview': { ar: 'قيد المراجعة', fr: 'En attente de révision' },
  'users.approval.approved': { ar: 'موافَق عليه', fr: 'Approuvé' },
  'users.approval.rejected': { ar: 'مرفوض', fr: 'Rejeté' },

  'users.account.active': { ar: 'نشط', fr: 'Actif' },
  'users.account.blocked': { ar: 'محظور', fr: 'Bloqué' },

  'users.section.contact': { ar: 'جهات الاتصال', fr: 'Contact' },
  'users.section.academic': { ar: 'الأكاديمي', fr: 'Académique' },
  'users.section.company': { ar: 'الشركة', fr: 'Entreprise' },
  'users.section.description': { ar: 'الوصف', fr: 'Description' },
  'users.section.bio': { ar: 'النبذة', fr: 'Bio' },
  'users.section.cv': { ar: 'السيرة الذاتية', fr: 'CV' },
  'users.section.applications': { ar: 'الطلبات', fr: 'Candidatures' },
  'users.section.postedOpportunities': { ar: 'الفرص المنشورة', fr: 'Opportunités publiées' },
  'users.section.companyReview': { ar: 'مراجعة الشركة', fr: 'Révision entreprise' },
  'users.section.access': { ar: 'الوصول', fr: 'Accès' },
  'users.section.commercialRegister': { ar: 'السجل التجاري', fr: 'Registre du commerce' },
  'users.section.applicationDetails': { ar: 'تفاصيل الطلب', fr: 'Détails de la candidature' },
  'users.section.opportunityDetails': { ar: 'تفاصيل الفرصة', fr: 'Détails de l\'opportunité' },
  'users.section.details': { ar: 'التفاصيل', fr: 'Détails' },

  'users.field.email': { ar: 'البريد الإلكتروني', fr: 'E-mail' },
  'users.field.phone': { ar: 'الهاتف', fr: 'Téléphone' },
  'users.field.location': { ar: 'الموقع', fr: 'Lieu' },
  'users.field.academicLevel': { ar: 'المستوى الأكاديمي', fr: 'Niveau académique' },
  'users.field.university': { ar: 'الجامعة', fr: 'Université' },
  'users.field.fieldOfStudy': { ar: 'مجال الدراسة', fr: 'Domaine d\'études' },
  'users.field.researchTopic': { ar: 'موضوع البحث', fr: 'Sujet de recherche' },
  'users.field.laboratory': { ar: 'المختبر', fr: 'Laboratoire' },
  'users.field.supervisor': { ar: 'المشرف', fr: 'Encadrant' },
  'users.field.researchDomain': { ar: 'مجال البحث', fr: 'Domaine de recherche' },
  'users.field.companyName': { ar: 'اسم الشركة', fr: 'Nom de l\'entreprise' },
  'users.field.approvalStatus': { ar: 'حالة الموافقة', fr: 'Statut d\'approbation' },
  'users.field.sector': { ar: 'القطاع', fr: 'Secteur' },
  'users.field.website': { ar: 'الموقع الإلكتروني', fr: 'Site web' },
  'users.field.totalApplications': { ar: 'إجمالي الطلبات', fr: 'Total des candidatures' },
  'users.field.status': { ar: 'الحالة', fr: 'Statut' },
  'users.field.applied': { ar: 'تاريخ التقديم', fr: 'Postulé' },
  'users.field.type': { ar: 'النوع', fr: 'Type' },
  'users.field.deadline': { ar: 'الموعد النهائي', fr: 'Date limite' },
  'users.field.compensation': { ar: 'التعويض', fr: 'Rémunération' },
  'users.field.workMode': { ar: 'طريقة العمل', fr: 'Mode de travail' },
  'users.field.employmentType': { ar: 'نوع التوظيف', fr: 'Type d\'emploi' },
  'users.field.paidStatus': { ar: 'حالة الدفع', fr: 'Statut de rémunération' },
  'users.field.duration': { ar: 'المدة', fr: 'Durée' },
  'users.field.posted': { ar: 'تاريخ النشر', fr: 'Publié' },

  'users.cv.viewUploaded': { ar: 'عرض السيرة المرفوعة', fr: 'Voir le CV téléversé' },
  'users.cv.downloadUploaded': { ar: 'تنزيل السيرة المرفوعة', fr: 'Télécharger le CV téléversé' },
  'users.cv.viewBuilt': { ar: 'عرض السيرة المُنشأة', fr: 'Voir le CV créé' },
  'users.cv.downloadBuilt': { ar: 'تنزيل السيرة المُنشأة', fr: 'Télécharger le CV créé' },
  'users.cv.builderDataExists': { ar: 'بيانات منشئ السيرة موجودة، لكن لا يتوفّر ملف PDF مُصدَّر.', fr: 'Données du créateur disponibles, mais aucun PDF exporté.' },
  'users.cv.noUploaded': { ar: 'لا توجد سيرة ذاتية مرفوعة بعد.', fr: 'Aucun CV téléversé pour le moment.' },
  'users.cv.noRecord': { ar: 'لا يوجد سجل سيرة ذاتية.', fr: 'Aucun enregistrement de CV.' },
  'users.cv.previewRequiresPdf': { ar: 'تتطلّب المعاينة ملف PDF', fr: 'L\'aperçu nécessite un fichier PDF' },

  'users.apps.title': { ar: 'الطلبات', fr: 'Candidatures' },
  'users.apps.detailsTitle': { ar: 'تفاصيل الطلب', fr: 'Détails de la candidature' },
  'users.apps.noApplicationsTitle': { ar: 'لا توجد طلبات', fr: 'Aucune candidature' },
  'users.apps.noApplicationsDesc': { ar: 'لم يتقدّم هذا الطالب إلى أي جهة بعد.', fr: 'Cet étudiant n\'a postulé nulle part pour le moment.' },
  'users.apps.noneYet': { ar: 'لا توجد طلبات بعد.', fr: 'Aucune candidature pour le moment.' },
  'users.apps.viewAll': { ar: 'عرض الكل', fr: 'Voir tout' },
  'users.apps.couldNotLoad': { ar: 'تعذّر تحميل الطلبات.', fr: 'Impossible de charger les candidatures.' },
  'users.apps.summaryUnavailable': { ar: 'تعذّر تحميل ملخّص الطلبات.', fr: 'Récapitulatif des candidatures indisponible.' },
  'users.apps.opportunityUnavailable': { ar: 'الفرصة غير متوفّرة', fr: 'Opportunité indisponible' },
  'users.apps.companyUnavailable': { ar: 'الشركة غير متوفّرة', fr: 'Entreprise indisponible' },
  'users.apps.locationNotSpecified': { ar: 'الموقع غير محدد', fr: 'Lieu non spécifié' },
  'users.apps.appliedUnavailable': { ar: 'تاريخ التقديم غير متوفّر', fr: 'Date de candidature indisponible' },
  'users.apps.back': { ar: 'رجوع', fr: 'Retour' },

  'users.appStatus.approved': { ar: 'موافَق عليه', fr: 'Approuvé' },
  'users.appStatus.rejected': { ar: 'مرفوض', fr: 'Rejeté' },
  'users.appStatus.withdrawn': { ar: 'مسحوب', fr: 'Retiré' },
  'users.appStatus.pending': { ar: 'قيد الانتظار', fr: 'En attente' },

  'users.opps.list.suffix': { ar: 'الفرص', fr: 'opportunités' },
  'users.opps.companyOpportunities': { ar: 'فرص الشركة', fr: 'Opportunités de l\'entreprise' },
  'users.opps.detailTitle': { ar: 'تفاصيل الفرصة', fr: 'Détails de l\'opportunité' },
  'users.opps.noTitle': { ar: 'لا توجد فرص', fr: 'Aucune opportunité' },
  'users.opps.noDesc': { ar: 'لم تنشر هذه الشركة أي فرص بعد.', fr: 'Cette entreprise n\'a publié aucune opportunité.' },
  'users.opps.untitled': { ar: 'فرصة بدون عنوان', fr: 'Opportunité sans titre' },
  'users.opps.unavailable': { ar: 'الفرصة غير متوفّرة', fr: 'Opportunité indisponible' },
  'users.opps.hidden': { ar: 'الفرصة مخفية', fr: 'Opportunité masquée' },
  'users.opps.closed': { ar: 'الفرصة مغلقة', fr: 'Opportunité fermée' },
  'users.opps.featured': { ar: 'مميّزة', fr: 'En vedette' },
  'users.opps.hiddenBadge': { ar: 'مخفية', fr: 'Masquée' },
  'users.opps.open': { ar: 'مفتوحة', fr: 'Ouverte' },
  'users.opps.closedLabel': { ar: 'مغلقة', fr: 'Fermée' },
  'users.opps.notSpecified': { ar: 'غير محدد', fr: 'Non spécifié' },
  'users.opps.historyUnavailable': { ar: 'سجل الفرص غير متوفر حاليًا.', fr: 'Historique des opportunités indisponible pour le moment.' },
  'users.opps.noPosted': { ar: 'لم تُنشر أي فرصة بعد.', fr: 'Aucune opportunité publiée.' },
  'users.opps.onePosted': { ar: 'فرصة واحدة منشورة', fr: '1 opportunité publiée' },
  'users.opps.manyPosted': { ar: '{n} فرص منشورة', fr: '{n} opportunités publiées' },
  'users.opps.viewOpportunities': { ar: 'عرض الفرص', fr: 'Voir les opportunités' },

  'users.companyMod.approve': { ar: 'الموافقة على الشركة', fr: 'Approuver l\'entreprise' },
  'users.companyMod.reject': { ar: 'رفض الشركة', fr: 'Rejeter l\'entreprise' },
  'users.companyMod.movePending': { ar: 'إعادة إلى قيد الانتظار', fr: 'Remettre en attente' },
  'users.companyMod.accountBlockedNote': { ar: 'الحساب محظور حاليًا.', fr: 'Le compte est actuellement bloqué.' },

  'users.access.blockUser': { ar: 'حظر المستخدم', fr: 'Bloquer l\'utilisateur' },
  'users.access.unblockUser': { ar: 'إلغاء حظر المستخدم', fr: 'Débloquer l\'utilisateur' },

  'users.commercial.defaultName': { ar: 'السجل التجاري', fr: 'Registre du commerce' },
  'users.commercial.uploadedPrefix': { ar: 'تم الرفع في', fr: 'Téléversé le' },
  'users.commercial.viewRegister': { ar: 'عرض السجل', fr: 'Voir le registre' },
  'users.commercial.downloadRegister': { ar: 'تنزيل السجل', fr: 'Télécharger le registre' },
  'users.commercial.missing': { ar: 'السجل التجاري مفقود.', fr: 'Registre du commerce manquant.' },

  'users.level.bac': { ar: 'باكالوريا', fr: 'Bac' },
  'users.level.licence': { ar: 'ليسانس', fr: 'Licence' },
  'users.level.master': { ar: 'ماستر', fr: 'Master' },
  'users.level.doctorat': { ar: 'دكتوراه', fr: 'Doctorat' },

  // ─── Document errors ────────────────────────────────────
  'doc.cantOpen': { ar: 'تعذّر فتح المستند الآن.', fr: 'Impossible d\'ouvrir le document maintenant.' },
  'doc.sessionExpired': { ar: 'انتهت جلسة المسؤول. يرجى تسجيل الدخول مرة أخرى.', fr: 'Votre session admin a expiré. Veuillez vous reconnecter.' },
  'doc.permissionDenied': { ar: 'تم رفض الإذن أثناء فتح المستند.', fr: 'Permission refusée lors de l\'ouverture du document.' },
  'doc.notFound': { ar: 'لم يعد المستند المطلوب متاحًا.', fr: 'Le document demandé n\'est plus disponible.' },
  'doc.invalid': { ar: 'رابط المستند غير صالح أو غير متوفر.', fr: 'Ce lien de document est invalide ou indisponible.' },
  'doc.notConfigured': { ar: 'الوصول الآمن إلى المستندات غير مُهيّأ في هذه البيئة.', fr: 'L\'accès sécurisé aux documents n\'est pas configuré pour cet environnement.' },
  'doc.unavailable': { ar: 'المستند غير متوفر.', fr: 'Document indisponible.' },
};

let currentLang = DEFAULT_LANG;

function readStoredLang() {
  try {
    const stored = window.localStorage.getItem(STORAGE_KEY);
    if (stored && SUPPORTED.includes(stored)) {
      return stored;
    }
  } catch (error) {
    console.warn('Language preference could not be read:', error);
  }
  // Try to detect from <html lang> or browser
  const htmlLang = String(document.documentElement.lang || '').toLowerCase().slice(0, 2);
  if (SUPPORTED.includes(htmlLang)) return htmlLang;
  const navLang = String(navigator.language || '').toLowerCase().slice(0, 2);
  if (SUPPORTED.includes(navLang)) return navLang;
  return DEFAULT_LANG;
}

function persistLang(lang) {
  try {
    window.localStorage.setItem(STORAGE_KEY, lang);
  } catch (error) {
    console.warn('Language preference could not be saved:', error);
  }
}

export function t(key, fallback) {
  if (currentLang === 'en' || !key) {
    return fallback != null ? String(fallback) : (key || '');
  }
  const entry = TRANSLATIONS[key];
  if (entry && entry[currentLang]) {
    return entry[currentLang];
  }
  return fallback != null ? String(fallback) : (key || '');
}

export function getLang() {
  return currentLang;
}

export function isRtl() {
  return RTL_LANGS.has(currentLang);
}

function applyDirection(lang) {
  const html = document.documentElement;
  html.setAttribute('lang', lang);
  html.setAttribute('dir', RTL_LANGS.has(lang) ? 'rtl' : 'ltr');
}

// Walk the DOM and replace text content for nodes with data-i18n attributes.
export function applyTranslations(root = document) {
  const scope = root || document;

  // Text content
  scope.querySelectorAll('[data-i18n]').forEach((el) => {
    const key = el.getAttribute('data-i18n');
    if (!key) return;
    const fallback = el.getAttribute('data-i18n-fallback') || el.textContent.trim();
    if (!el.hasAttribute('data-i18n-fallback')) {
      el.setAttribute('data-i18n-fallback', fallback);
    }
    el.textContent = t(key, fallback);
  });

  // Placeholders
  scope.querySelectorAll('[data-i18n-placeholder]').forEach((el) => {
    const key = el.getAttribute('data-i18n-placeholder');
    if (!key) return;
    const fallback = el.getAttribute('data-i18n-placeholder-fallback') || el.getAttribute('placeholder') || '';
    if (!el.hasAttribute('data-i18n-placeholder-fallback')) {
      el.setAttribute('data-i18n-placeholder-fallback', fallback);
    }
    el.setAttribute('placeholder', t(key, fallback));
  });

  // Titles / aria-labels
  scope.querySelectorAll('[data-i18n-title]').forEach((el) => {
    const key = el.getAttribute('data-i18n-title');
    if (!key) return;
    const fallback = el.getAttribute('data-i18n-title-fallback') || el.getAttribute('title') || '';
    if (!el.hasAttribute('data-i18n-title-fallback')) {
      el.setAttribute('data-i18n-title-fallback', fallback);
    }
    el.setAttribute('title', t(key, fallback));
  });

  scope.querySelectorAll('[data-i18n-aria-label]').forEach((el) => {
    const key = el.getAttribute('data-i18n-aria-label');
    if (!key) return;
    const fallback = el.getAttribute('data-i18n-aria-label-fallback') || el.getAttribute('aria-label') || '';
    if (!el.hasAttribute('data-i18n-aria-label-fallback')) {
      el.setAttribute('data-i18n-aria-label-fallback', fallback);
    }
    el.setAttribute('aria-label', t(key, fallback));
  });

  // Document title via <title data-i18n="...">
  const titleEl = scope.querySelector('title[data-i18n]');
  if (titleEl) {
    const key = titleEl.getAttribute('data-i18n');
    const fallback = titleEl.getAttribute('data-i18n-fallback') || titleEl.textContent;
    if (!titleEl.hasAttribute('data-i18n-fallback')) {
      titleEl.setAttribute('data-i18n-fallback', fallback);
    }
    document.title = t(key, fallback);
  }
}

export function setLang(lang, { silent = false } = {}) {
  const next = SUPPORTED.includes(lang) ? lang : DEFAULT_LANG;
  if (next === currentLang && !silent) {
    applyDirection(next);
    applyTranslations();
    return;
  }
  currentLang = next;
  persistLang(next);
  applyDirection(next);
  applyTranslations();
  document.dispatchEvent(new CustomEvent('languagechange', { detail: { lang: next } }));
}

export function initI18n() {
  currentLang = readStoredLang();
  applyDirection(currentLang);
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => applyTranslations(), { once: true });
  } else {
    applyTranslations();
  }
}

// Utility: format a relative time using localized labels.
export function formatRelativeMs(diffMs, dateFallback) {
  if (diffMs < 60000) return t('time.justNow', 'Just now');
  if (diffMs < 3600000) {
    const m = Math.floor(diffMs / 60000);
    if (currentLang === 'fr') return `il y a ${m} min`;
    if (currentLang === 'ar') return `منذ ${m} د`;
    return `${m}m ago`;
  }
  if (diffMs < 86400000) {
    const h = Math.floor(diffMs / 3600000);
    if (currentLang === 'fr') return `il y a ${h} h`;
    if (currentLang === 'ar') return `منذ ${h} س`;
    return `${h}h ago`;
  }
  if (!dateFallback) return '';
  const locale = currentLang === 'ar' ? 'ar' : currentLang === 'fr' ? 'fr-FR' : 'en-US';
  return dateFallback.toLocaleDateString(locale, { month: 'short', day: 'numeric', year: 'numeric' });
}

// Initialize lang as early as possible (so dir/lang are correct before the rest renders).
initI18n();

// Expose globals so non-module pages and inline scripts can use it.
window.FutureGateI18n = { t, setLang, getLang, isRtl, applyTranslations, formatRelativeMs };
