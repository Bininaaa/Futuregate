import json
import sys

NEW_KEYS = {
    # === settings_screen.dart ===
    "securitySectionTitle": {
        "en": "Security",
        "fr": "Sécurité",
        "ar": "الأمان"
    },
    "securitySectionSubtitle": {
        "en": "Keep passwords, privacy controls, and account protections close at hand.",
        "fr": "Gardez vos mots de passe, contrôles de confidentialité et protections de compte à portée de main.",
        "ar": "احتفظ بكلمات المرور وإعدادات الخصوصية وحماية الحساب في متناول يدك."
    },
    "signOutCompanySubtitle": {
        "en": "Sign out of the company workspace",
        "fr": "Se déconnecter de l'espace entreprise",
        "ar": "تسجيل الخروج من مساحة عمل الشركة"
    },
    "adminSettingsTitle": {
        "en": "Admin settings",
        "fr": "Paramètres administrateur",
        "ar": "إعدادات المسؤول"
    },
    "adminAccountLabel": {
        "en": "Admin account",
        "fr": "Compte administrateur",
        "ar": "حساب المسؤول"
    },
    "adminWorkspaceBody": {
        "en": "Control your workspace preferences without changing the admin profile record.",
        "fr": "Contrôlez vos préférences d'espace de travail sans modifier le profil administrateur.",
        "ar": "تحكم في تفضيلات مساحة العمل دون تغيير سجل ملف المسؤول."
    },
    "adminLabel": {
        "en": "Admin",
        "fr": "Administrateur",
        "ar": "مسؤول"
    },
    "adminWorkspaceSectionSubtitle": {
        "en": "Keep platform operations close without exposing profile editing.",
        "fr": "Gardez les opérations de la plateforme à portée sans exposer la modification du profil.",
        "ar": "أبقِ عمليات المنصة قريبة دون كشف تعديل الملف الشخصي."
    },
    "adminSupportSubtitle": {
        "en": "App information and help for platform admins.",
        "fr": "Informations et aide pour les administrateurs de la plateforme.",
        "ar": "معلومات التطبيق والمساعدة لمسؤولي المنصة."
    },
    "signOutAdminSubtitle": {
        "en": "End this admin session on the current device",
        "fr": "Terminer cette session administrateur sur cet appareil",
        "ar": "إنهاء جلسة المسؤول على هذا الجهاز"
    },
    "themeTitle": {
        "en": "Theme",
        "fr": "Thème",
        "ar": "المظهر"
    },
    "appThemeTitle": {
        "en": "App theme",
        "fr": "Thème de l'application",
        "ar": "مظهر التطبيق"
    },
    "themeSystemLabel": {
        "en": "System",
        "fr": "Système",
        "ar": "النظام"
    },
    "themeLightLabel": {
        "en": "Light",
        "fr": "Clair",
        "ar": "فاتح"
    },
    "themeDarkLabel": {
        "en": "Dark",
        "fr": "Sombre",
        "ar": "داكن"
    },
    "themeSystemSubtitle": {
        "en": "Follow your device appearance setting",
        "fr": "Suivre le réglage d'apparence de votre appareil",
        "ar": "اتبع إعداد مظهر جهازك"
    },
    "themeLightSubtitle": {
        "en": "Keep FutureGate bright and airy",
        "fr": "Garder FutureGate lumineux et aéré",
        "ar": "أبقِ FutureGate مشرقًا ومريحًا"
    },
    "themeDarkSubtitle": {
        "en": "Use the premium dark workspace",
        "fr": "Utiliser l'espace de travail sombre premium",
        "ar": "استخدم مساحة العمل الداكنة المميزة"
    },
    "startSectionTitle": {
        "en": "Start",
        "fr": "Démarrage",
        "ar": "البدء"
    },
    "showStartupAnimationTitle": {
        "en": "Show startup animation",
        "fr": "Afficher l'animation de démarrage",
        "ar": "عرض حركة البدء"
    },
    "startupAnimCheckingSubtitle": {
        "en": "Checking your launch preference...",
        "fr": "Vérification de votre préférence de lancement...",
        "ar": "جارٍ التحقق من تفضيل الإطلاق..."
    },
    "startupAnimOnSubtitle": {
        "en": "The launch video will play when FutureGate opens.",
        "fr": "La vidéo de lancement sera jouée à l'ouverture de FutureGate.",
        "ar": "سيتم تشغيل فيديو الإطلاق عند فتح FutureGate."
    },
    "startupAnimOffSubtitle": {
        "en": "FutureGate will open directly next time.",
        "fr": "FutureGate s'ouvrira directement la prochaine fois.",
        "ar": "سيفتح FutureGate مباشرة في المرة القادمة."
    },
    "startupAnimErrorMessage": {
        "en": "Could not update the startup animation setting.",
        "fr": "Impossible de mettre à jour le paramètre d'animation de démarrage.",
        "ar": "تعذّر تحديث إعداد حركة البدء."
    },
    "languageInfoSheetMessage": {
        "en": "The current app experience is shown in English. Broader language selection can be introduced safely in a later iteration.",
        "fr": "L'expérience actuelle de l'application est affichée en français. Un choix de langue plus large pourra être introduit dans une prochaine version.",
        "ar": "تجربة التطبيق الحالية معروضة بالعربية. يمكن إدخال اختيار لغة أوسع بأمان في تحديث لاحق."
    },

    # === security_privacy_screen.dart ===
    "accountProtectionHubTitle": {
        "en": "Your account protection hub",
        "fr": "Votre centre de protection de compte",
        "ar": "مركز حماية حسابك"
    },
    "accountProtectionHubBody": {
        "en": "Update credentials, review privacy touchpoints, and keep access to your FutureGate profile secure.",
        "fr": "Mettez à jour vos identifiants, vérifiez les points de confidentialité et gardez l'accès à votre profil FutureGate sécurisé.",
        "ar": "حدّث بيانات الاعتماد، وراجع نقاط الخصوصية، وحافظ على أمان الوصول إلى ملفك الشخصي في FutureGate."
    },
    "accountSecuritySectionTitle": {
        "en": "Account Security",
        "fr": "Sécurité du compte",
        "ar": "أمان الحساب"
    },
    "accountSecuritySectionSubtitle": {
        "en": "Use the existing account tools safely without affecting your current sign-in flow.",
        "fr": "Utilisez les outils de compte existants en toute sécurité sans affecter votre flux de connexion actuel.",
        "ar": "استخدم أدوات الحساب الحالية بأمان دون التأثير على تدفق تسجيل الدخول."
    },
    "addPasswordTitle": {
        "en": "Add Password",
        "fr": "Ajouter un mot de passe",
        "ar": "إضافة كلمة مرور"
    },
    "addPasswordSubtitle": {
        "en": "Keep Google sign-in and add email/password too",
        "fr": "Conserver la connexion Google et ajouter email/mot de passe aussi",
        "ar": "احتفظ بتسجيل الدخول بـ Google وأضف البريد الإلكتروني/كلمة المرور أيضًا"
    },
    "changePasswordTitle": {
        "en": "Change Password",
        "fr": "Changer le mot de passe",
        "ar": "تغيير كلمة المرور"
    },
    "changePasswordSubtitle": {
        "en": "Update your sign-in password",
        "fr": "Mettre à jour votre mot de passe de connexion",
        "ar": "تحديث كلمة مرور تسجيل الدخول"
    },
    "changeEmailTitle": {
        "en": "Change Email",
        "fr": "Changer l'email",
        "ar": "تغيير البريد الإلكتروني"
    },
    "changeEmailCurrentSubtitle": {
        "en": "Current: {email}",
        "fr": "Actuel : {email}",
        "ar": "الحالي: {email}",
        "placeholders": {"email": {}}
    },
    "changeEmailVerifySubtitle": {
        "en": "Verify a new sign-in email",
        "fr": "Vérifier un nouvel email de connexion",
        "ar": "التحقق من بريد إلكتروني جديد لتسجيل الدخول"
    },
    "googleLinkedAccountTitle": {
        "en": "Google-linked account",
        "fr": "Compte lié à Google",
        "ar": "حساب مرتبط بـ Google"
    },
    "googleManagedAccountTitle": {
        "en": "Google-managed account",
        "fr": "Compte géré par Google",
        "ar": "حساب يديره Google"
    },
    "googleLinkedAccountBody": {
        "en": "This account can sign in with both Google and email/password, but the sign-in email stays managed through Google.",
        "fr": "Ce compte peut se connecter avec Google et email/mot de passe, mais l'email de connexion reste géré par Google.",
        "ar": "يمكن لهذا الحساب تسجيل الدخول بـ Google والبريد الإلكتروني/كلمة المرور، لكن البريد يبقى مدارًا عبر Google."
    },
    "googleManagedAccountBody": {
        "en": "This account signs in with Google. You can add a password if you want email/password access too, but the sign-in email itself stays managed through Google.",
        "fr": "Ce compte se connecte avec Google. Vous pouvez ajouter un mot de passe pour accéder aussi par email, mais l'email de connexion reste géré par Google.",
        "ar": "يسجّل هذا الحساب الدخول بـ Google. يمكنك إضافة كلمة مرور للوصول بالبريد الإلكتروني أيضًا، لكن بريد تسجيل الدخول يبقى مدارًا عبر Google."
    },
    "twoStepVerificationTitle": {
        "en": "Two-step verification",
        "fr": "Vérification en deux étapes",
        "ar": "التحقق بخطوتين"
    },
    "twoStepVerificationGoogleSubtitle": {
        "en": "Manage it through your Google account",
        "fr": "Gérez-la via votre compte Google",
        "ar": "إدارتها عبر حساب Google الخاص بك"
    },
    "twoStepVerificationEmailSubtitle": {
        "en": "Available through your email provider",
        "fr": "Disponible via votre fournisseur de messagerie",
        "ar": "متاح عبر مزوّد بريدك الإلكتروني"
    },
    "twoStepVerificationGoogleBody": {
        "en": "This account signs in with {provider}, so two-step verification is managed directly by Google.",
        "fr": "Ce compte se connecte avec {provider}, donc la vérification en deux étapes est gérée directement par Google.",
        "ar": "يسجّل هذا الحساب الدخول عبر {provider}، لذا يتم إدارة التحقق بخطوتين مباشرة عبر Google.",
        "placeholders": {"provider": {}}
    },
    "twoStepVerificationEmailBody": {
        "en": "A dedicated in-app two-step setup is not enabled yet. For now, keep your mailbox protected and use a strong password.",
        "fr": "La configuration de la vérification en deux étapes dans l'application n'est pas encore activée. En attendant, protégez votre boîte mail et utilisez un mot de passe fort.",
        "ar": "إعداد التحقق بخطوتين داخل التطبيق غير مفعّل بعد. في الوقت الحالي، احمِ صندوق بريدك واستخدم كلمة مرور قوية."
    },
    "manageSessionsTitle": {
        "en": "Manage sessions & devices",
        "fr": "Gérer les sessions et appareils",
        "ar": "إدارة الجلسات والأجهزة"
    },
    "manageSessionsSubtitle": {
        "en": "Review where your account is being used",
        "fr": "Vérifiez où votre compte est utilisé",
        "ar": "راجع أين يتم استخدام حسابك"
    },
    "sessionsDevicesTitle": {
        "en": "Sessions & devices",
        "fr": "Sessions et appareils",
        "ar": "الجلسات والأجهزة"
    },
    "sessionsDevicesBody": {
        "en": "Remote session management is not available in this build yet. Your active session on this device remains protected by Firebase authentication.",
        "fr": "La gestion des sessions à distance n'est pas encore disponible dans cette version. Votre session active sur cet appareil reste protégée par l'authentification Firebase.",
        "ar": "إدارة الجلسات عن بُعد غير متاحة بعد في هذا الإصدار. تبقى جلستك النشطة على هذا الجهاز محمية بمصادقة Firebase."
    },
    "privacyControlsSectionTitle": {
        "en": "Privacy Controls",
        "fr": "Contrôles de confidentialité",
        "ar": "ضوابط الخصوصية"
    },
    "privacyControlsSectionSubtitle": {
        "en": "Understand what information is stored and how it is used inside the platform.",
        "fr": "Comprenez quelles informations sont stockées et comment elles sont utilisées dans la plateforme.",
        "ar": "افهم ما هي المعلومات المخزنة وكيف يتم استخدامها داخل المنصة."
    },
    "dataPermissionsTitle": {
        "en": "Data permissions",
        "fr": "Autorisations des données",
        "ar": "أذونات البيانات"
    },
    "dataPermissionsSubtitle": {
        "en": "Profile, CV, and application data are used to power opportunities and recruiter review flows.",
        "fr": "Les données de profil, CV et candidatures sont utilisées pour alimenter les opportunités et les flux d'évaluation des recruteurs.",
        "ar": "تُستخدم بيانات الملف الشخصي والسيرة الذاتية والطلبات لتشغيل الفرص وتدفقات مراجعة المُوظفين."
    },
    "dataPermissionsBody": {
        "en": "FutureGate stores the profile details, CV content, saved items, and application activity needed to match students with opportunities and support application review.",
        "fr": "FutureGate stocke les détails du profil, le contenu du CV, les éléments enregistrés et l'activité de candidature nécessaires pour mettre en relation les étudiants avec les opportunités et soutenir l'examen des candidatures.",
        "ar": "يخزّن FutureGate تفاصيل الملف الشخصي ومحتوى السيرة الذاتية والعناصر المحفوظة ونشاط الطلبات اللازمة لمطابقة الطلاب بالفرص ودعم مراجعة الطلبات."
    },
    "privacyPolicySettingsTitle": {
        "en": "Privacy Policy",
        "fr": "Politique de confidentialité",
        "ar": "سياسة الخصوصية"
    },
    "privacyPolicySettingsSubtitle": {
        "en": "Read how personal information is handled",
        "fr": "Découvrez comment les informations personnelles sont traitées",
        "ar": "اقرأ كيف يتم التعامل مع المعلومات الشخصية"
    },
    "privacyPolicySettingsBody": {
        "en": "Your account data is used to provide sign-in, profile management, saved opportunities, notifications, CV access, and applications. Sensitive access is limited to the platform features that require it.",
        "fr": "Les données de votre compte sont utilisées pour fournir la connexion, la gestion du profil, les opportunités enregistrées, les notifications, l'accès au CV et les candidatures. L'accès sensible est limité aux fonctionnalités de la plateforme qui en ont besoin.",
        "ar": "تُستخدم بيانات حسابك لتوفير تسجيل الدخول وإدارة الملف الشخصي والفرص المحفوظة والإشعارات والوصول للسيرة الذاتية والطلبات. الوصول الحساس مقتصر على ميزات المنصة التي تتطلبه."
    },
    "termsOfUseSettingsTitle": {
        "en": "Terms of Use",
        "fr": "Conditions d'utilisation",
        "ar": "شروط الاستخدام"
    },
    "termsOfUseSettingsSubtitle": {
        "en": "Review expected platform usage",
        "fr": "Consultez les règles d'utilisation de la plateforme",
        "ar": "راجع قواعد استخدام المنصة المتوقعة"
    },
    "termsOfUseSettingsBody": {
        "en": "Use FutureGate responsibly, keep account information accurate, and avoid submitting misleading applications or content that violates platform rules.",
        "fr": "Utilisez FutureGate de manière responsable, gardez les informations de compte exactes et évitez de soumettre des candidatures trompeuses ou du contenu violant les règles de la plateforme.",
        "ar": "استخدم FutureGate بمسؤولية، وحافظ على دقة معلومات الحساب، وتجنب تقديم طلبات مضللة أو محتوى ينتهك قواعد المنصة."
    },

    # === account_security_screens.dart ===
    "addPasswordBannerTitle": {
        "en": "Add email and password sign-in",
        "fr": "Ajouter la connexion par email et mot de passe",
        "ar": "إضافة تسجيل الدخول بالبريد الإلكتروني وكلمة المرور"
    },
    "addPasswordBannerBodyGeneric": {
        "en": "Keep Google sign-in and add a password for this account.",
        "fr": "Conservez la connexion Google et ajoutez un mot de passe pour ce compte.",
        "ar": "احتفظ بتسجيل الدخول بـ Google وأضف كلمة مرور لهذا الحساب."
    },
    "addPasswordBannerBodyEmail": {
        "en": "Keep Google sign-in and add a password for {email}.",
        "fr": "Conservez la connexion Google et ajoutez un mot de passe pour {email}.",
        "ar": "احتفظ بتسجيل الدخول بـ Google وأضف كلمة مرور لـ {email}.",
        "placeholders": {"email": {}}
    },
    "newPasswordLabel": {
        "en": "New Password",
        "fr": "Nouveau mot de passe",
        "ar": "كلمة المرور الجديدة"
    },
    "confirmPasswordLabel": {
        "en": "Confirm Password",
        "fr": "Confirmer le mot de passe",
        "ar": "تأكيد كلمة المرور"
    },
    "currentPasswordLabel": {
        "en": "Current Password",
        "fr": "Mot de passe actuel",
        "ar": "كلمة المرور الحالية"
    },
    "addPasswordNote": {
        "en": "Your sign-in email will remain managed by Google. This only adds an additional way to sign in.",
        "fr": "Votre email de connexion restera géré par Google. Cela ajoute seulement un moyen supplémentaire de se connecter.",
        "ar": "سيبقى بريد تسجيل الدخول مدارًا بواسطة Google. هذا يضيف فقط طريقة إضافية لتسجيل الدخول."
    },
    "addingPasswordLabel": {
        "en": "Adding...",
        "fr": "Ajout en cours...",
        "ar": "جارٍ الإضافة..."
    },
    "passwordAddedSuccessBody": {
        "en": "Password added successfully. You can now sign in with Google or email and password.",
        "fr": "Mot de passe ajouté avec succès. Vous pouvez maintenant vous connecter avec Google ou email et mot de passe.",
        "ar": "تمت إضافة كلمة المرور بنجاح. يمكنك الآن تسجيل الدخول بـ Google أو البريد الإلكتروني وكلمة المرور."
    },
    "passwordSetupAlreadyEnabled": {
        "en": "This account already has email and password sign-in enabled.",
        "fr": "Ce compte a déjà la connexion par email et mot de passe activée.",
        "ar": "هذا الحساب مفعّل فيه بالفعل تسجيل الدخول بالبريد الإلكتروني وكلمة المرور."
    },
    "passwordSetupGoogleOnly": {
        "en": "A password can only be added while signed in to a Google account that does not already have email/password linked.",
        "fr": "Un mot de passe ne peut être ajouté que lorsque vous êtes connecté à un compte Google qui n'a pas encore d'email/mot de passe lié.",
        "ar": "لا يمكن إضافة كلمة مرور إلا أثناء تسجيل الدخول بحساب Google ليس لديه بالفعل بريد إلكتروني/كلمة مرور مرتبطة."
    },
    "secureAccountBannerTitle": {
        "en": "Secure your account",
        "fr": "Sécurisez votre compte",
        "ar": "أمّن حسابك"
    },
    "secureAccountBannerBody": {
        "en": "Use a strong password with a mix of letters, numbers, and symbols to keep your account protected.",
        "fr": "Utilisez un mot de passe fort avec un mélange de lettres, chiffres et symboles pour protéger votre compte.",
        "ar": "استخدم كلمة مرور قوية تجمع بين الحروف والأرقام والرموز للحفاظ على حماية حسابك."
    },
    "updatingPasswordLabel": {
        "en": "Updating...",
        "fr": "Mise à jour...",
        "ar": "جارٍ التحديث..."
    },
    "updatePasswordLabel": {
        "en": "Update Password",
        "fr": "Mettre à jour le mot de passe",
        "ar": "تحديث كلمة المرور"
    },
    "passwordUpdatedBody": {
        "en": "Your password has been updated successfully.",
        "fr": "Votre mot de passe a été mis à jour avec succès.",
        "ar": "تم تحديث كلمة مرورك بنجاح."
    },
    "passwordChangesUnavailableTitle": {
        "en": "Password changes unavailable",
        "fr": "Changement de mot de passe indisponible",
        "ar": "تغيير كلمة المرور غير متاح"
    },
    "passwordChangesGoogleBody": {
        "en": "This account uses Google sign-in right now. Add a password first, then you can change it later.",
        "fr": "Ce compte utilise actuellement la connexion Google. Ajoutez d'abord un mot de passe, puis vous pourrez le changer plus tard.",
        "ar": "يستخدم هذا الحساب حاليًا تسجيل الدخول بـ Google. أضف كلمة مرور أولاً، ثم يمكنك تغييرها لاحقًا."
    },
    "passwordChangesOnlyBody": {
        "en": "Password changes are only available for accounts that already use email and password sign-in.",
        "fr": "Le changement de mot de passe n'est disponible que pour les comptes utilisant déjà la connexion par email et mot de passe.",
        "ar": "تغيير كلمة المرور متاح فقط للحسابات التي تستخدم بالفعل تسجيل الدخول بالبريد الإلكتروني وكلمة المرور."
    },
    "emailChangesUnavailableTitle": {
        "en": "Email changes unavailable",
        "fr": "Changement d'email indisponible",
        "ar": "تغيير البريد الإلكتروني غير متاح"
    },
    "emailChangesGoogleBody": {
        "en": "This account is linked to Google, so the sign-in email must be managed through Google.",
        "fr": "Ce compte est lié à Google, donc l'email de connexion doit être géré via Google.",
        "ar": "هذا الحساب مرتبط بـ Google، لذا يجب إدارة بريد تسجيل الدخول عبر Google."
    },
    "emailChangesPasswordOnlyBody": {
        "en": "Email changes are only available for accounts that use email and password without Google linked.",
        "fr": "Le changement d'email n'est disponible que pour les comptes utilisant email et mot de passe sans Google lié.",
        "ar": "تغيير البريد الإلكتروني متاح فقط للحسابات التي تستخدم البريد الإلكتروني وكلمة المرور بدون ربط Google."
    },
    "currentEmailBannerTitle": {
        "en": "Current email",
        "fr": "Email actuel",
        "ar": "البريد الإلكتروني الحالي"
    },
    "noEmailAvailableBody": {
        "en": "No email is currently available for this account.",
        "fr": "Aucun email n'est actuellement disponible pour ce compte.",
        "ar": "لا يتوفر بريد إلكتروني حاليًا لهذا الحساب."
    },
    "newEmailLabel": {
        "en": "New Email",
        "fr": "Nouvel email",
        "ar": "البريد الإلكتروني الجديد"
    },
    "newEmailHint": {
        "en": "name@example.com",
        "fr": "nom@exemple.com",
        "ar": "nom@exemple.com"
    },
    "emailVerificationNote": {
        "en": "A verification link will be sent to the new address before the change becomes active.",
        "fr": "Un lien de vérification sera envoyé à la nouvelle adresse avant que le changement ne prenne effet.",
        "ar": "سيتم إرسال رابط تحقق إلى العنوان الجديد قبل أن يصبح التغيير ساري المفعول."
    },
    "updatingEmailLabel": {
        "en": "Updating...",
        "fr": "Mise à jour...",
        "ar": "جارٍ التحديث..."
    },
    "updateEmailLabel": {
        "en": "Update Email",
        "fr": "Mettre à jour l'email",
        "ar": "تحديث البريد الإلكتروني"
    },
    "verificationSentTitle": {
        "en": "Verification sent",
        "fr": "Vérification envoyée",
        "ar": "تم إرسال التحقق"
    },
    "verificationSentBody": {
        "en": "Verification email sent. Confirm your new address to complete the update.",
        "fr": "Email de vérification envoyé. Confirmez votre nouvelle adresse pour terminer la mise à jour.",
        "ar": "تم إرسال بريد التحقق. أكّد عنوانك الجديد لإتمام التحديث."
    },
    "backLabel": {
        "en": "Back",
        "fr": "Retour",
        "ar": "رجوع"
    },

    # === help_center_screen.dart ===
    "howCanWeHelpTitle": {
        "en": "How can we help?",
        "fr": "Comment pouvons-nous vous aider ?",
        "ar": "كيف يمكننا مساعدتك؟"
    },
    "howCanWeHelpSubtitle": {
        "en": "Search common topics, contact support, or report something that needs attention.",
        "fr": "Recherchez des sujets courants, contactez le support ou signalez quelque chose qui nécessite attention.",
        "ar": "ابحث في المواضيع الشائعة، أو تواصل مع الدعم، أو أبلغ عن شيء يحتاج اهتمامًا."
    },
    "searchHelpTopicsHint": {
        "en": "Search help topics",
        "fr": "Rechercher des sujets d'aide",
        "ar": "البحث في مواضيع المساعدة"
    },
    "quickSupportTitle": {
        "en": "Quick Support",
        "fr": "Support rapide",
        "ar": "الدعم السريع"
    },
    "quickSupportSubtitle": {
        "en": "Reach out with context so the team can help faster.",
        "fr": "Contactez-nous avec des détails pour que l'équipe puisse vous aider plus vite.",
        "ar": "تواصل مع تفاصيل ليتمكن الفريق من مساعدتك بشكل أسرع."
    },
    "contactSupportTitle": {
        "en": "Contact Support",
        "fr": "Contacter le support",
        "ar": "التواصل مع الدعم"
    },
    "reportProblemTitle": {
        "en": "Report a Problem",
        "fr": "Signaler un problème",
        "ar": "الإبلاغ عن مشكلة"
    },
    "reportProblemSubtitle": {
        "en": "Share screenshots, steps, or account issues",
        "fr": "Partagez des captures d'écran, étapes ou problèmes de compte",
        "ar": "شارك لقطات شاشة أو خطوات أو مشاكل الحساب"
    },
    "faqsSectionTitle": {
        "en": "FAQs",
        "fr": "FAQ",
        "ar": "الأسئلة الشائعة"
    },
    "noTopicsMatchedSubtitle": {
        "en": "No topics matched your search.",
        "fr": "Aucun sujet ne correspond à votre recherche.",
        "ar": "لا توجد مواضيع تطابق بحثك."
    },
    "helpTopicCount": {
        "en": "{count} help topic(s)",
        "fr": "{count} sujet(s) d'aide",
        "ar": "{count} موضوع(مواضيع) مساعدة",
        "placeholders": {"count": {}}
    },
    "noHelpTopicsMatchTitle": {
        "en": "No help topics match your search",
        "fr": "Aucun sujet d'aide ne correspond à votre recherche",
        "ar": "لا توجد مواضيع مساعدة تطابق بحثك"
    },
    "noHelpTopicsMatchBody": {
        "en": "Try a broader search term, or contact support if you need hands-on help.",
        "fr": "Essayez un terme de recherche plus large, ou contactez le support si vous avez besoin d'aide directe.",
        "ar": "جرّب مصطلح بحث أوسع، أو تواصل مع الدعم إذا كنت بحاجة إلى مساعدة مباشرة."
    },
    "emailUnavailableWarningTitle": {
        "en": "Email unavailable",
        "fr": "Email indisponible",
        "ar": "البريد الإلكتروني غير متاح"
    },
    "noEmailAppAvailableBody": {
        "en": "No email app is available on this device.",
        "fr": "Aucune application email n'est disponible sur cet appareil.",
        "ar": "لا يتوفر تطبيق بريد إلكتروني على هذا الجهاز."
    },
    "supportRequestSubject": {
        "en": "FutureGate Support Request",
        "fr": "Demande de support FutureGate",
        "ar": "طلب دعم FutureGate"
    },
    "bugReportSubject": {
        "en": "FutureGate Bug Report",
        "fr": "Rapport de bug FutureGate",
        "ar": "تقرير خلل FutureGate"
    },
    "helpAccountHelpTitle": {
        "en": "Account Help",
        "fr": "Aide compte",
        "ar": "مساعدة الحساب"
    },
    "helpAccountCategory": {
        "en": "Account",
        "fr": "Compte",
        "ar": "الحساب"
    },
    "helpAccountDescription": {
        "en": "Update profile details, manage sign-in methods, and keep your student profile ready for new opportunities.",
        "fr": "Mettez à jour les détails du profil, gérez les méthodes de connexion et gardez votre profil étudiant prêt pour de nouvelles opportunités.",
        "ar": "حدّث تفاصيل الملف الشخصي، وأدر طرق تسجيل الدخول، واحتفظ بملفك الطلابي جاهزًا لفرص جديدة."
    },
    "helpApplicationHelpTitle": {
        "en": "Application Help",
        "fr": "Aide candidatures",
        "ar": "مساعدة الطلبات"
    },
    "helpApplicationCategory": {
        "en": "Applications",
        "fr": "Candidatures",
        "ar": "الطلبات"
    },
    "helpApplicationDescription": {
        "en": "Track your submissions, review statuses, and understand what recruiters need to evaluate your profile.",
        "fr": "Suivez vos soumissions, consultez les statuts et comprenez ce dont les recruteurs ont besoin pour évaluer votre profil.",
        "ar": "تتبع طلباتك المقدمة، وراجع الحالات، وافهم ما يحتاجه المُوظفون لتقييم ملفك الشخصي."
    },
    "helpSavedItemsTitle": {
        "en": "Saved Items",
        "fr": "Éléments enregistrés",
        "ar": "العناصر المحفوظة"
    },
    "helpSavedItemsCategory": {
        "en": "Dashboard",
        "fr": "Tableau de bord",
        "ar": "لوحة المعلومات"
    },
    "helpSavedItemsDescription": {
        "en": "Bookmark opportunities you want to revisit later and stay organized while you prepare applications.",
        "fr": "Ajoutez en favoris les opportunités à revoir plus tard et restez organisé pendant la préparation de vos candidatures.",
        "ar": "احفظ الفرص التي تريد العودة إليها لاحقًا وابقَ منظمًا أثناء تحضير طلباتك."
    },
    "helpCvBuilderTitle": {
        "en": "CV Builder",
        "fr": "Créateur de CV",
        "ar": "منشئ السيرة الذاتية"
    },
    "helpCvBuilderCategory": {
        "en": "CV",
        "fr": "CV",
        "ar": "السيرة الذاتية"
    },
    "helpCvBuilderDescription": {
        "en": "Create structured CV content, choose a template, preview your document, and export a PDF when you are ready.",
        "fr": "Créez un contenu de CV structuré, choisissez un modèle, prévisualisez votre document et exportez un PDF quand vous êtes prêt.",
        "ar": "أنشئ محتوى سيرة ذاتية منظمًا، واختر قالبًا، واعرض مستندك مسبقًا، وصدّره بصيغة PDF عندما تكون جاهزًا."
    },
    "helpOpportunityPostingTitle": {
        "en": "Opportunity Posting Help",
        "fr": "Aide publication d'opportunités",
        "ar": "مساعدة نشر الفرص"
    },
    "helpOpportunityCategory": {
        "en": "Platform",
        "fr": "Plateforme",
        "ar": "المنصة"
    },
    "helpOpportunityDescription": {
        "en": "Learn how companies and approved listings appear inside the app so you can understand the platform flow end to end.",
        "fr": "Découvrez comment les entreprises et les annonces approuvées apparaissent dans l'application pour comprendre le flux de la plateforme de bout en bout.",
        "ar": "تعرّف على كيفية ظهور الشركات والإعلانات المعتمدة داخل التطبيق لفهم تدفق المنصة من البداية إلى النهاية."
    },
    "helpNotificationsCategory": {
        "en": "Updates",
        "fr": "Mises à jour",
        "ar": "التحديثات"
    },
    "helpNotificationsDescription": {
        "en": "Stay on top of application decisions, saved item changes, reminders, and platform alerts.",
        "fr": "Restez informé des décisions de candidature, des changements d'éléments enregistrés, des rappels et des alertes de la plateforme.",
        "ar": "ابقَ على اطلاع بقرارات الطلبات وتغييرات العناصر المحفوظة والتذكيرات وتنبيهات المنصة."
    },

    # === about_futuregate_screen.dart ===
    "aboutBridgeDescription": {
        "en": "FutureGate is designed as a bridge between students, their growing skills, and the real opportunities that can shape their next milestone.",
        "fr": "FutureGate est conçu comme un pont entre les étudiants, leurs compétences grandissantes et les vraies opportunités qui peuvent façonner leur prochain jalon.",
        "ar": "صُمم FutureGate كجسر بين الطلاب ومهاراتهم المتنامية والفرص الحقيقية التي يمكن أن تشكّل إنجازهم التالي."
    },
    "platformStoryTitle": {
        "en": "Platform Story",
        "fr": "Histoire de la plateforme",
        "ar": "قصة المنصة"
    },
    "platformStorySubtitle": {
        "en": "A clearer path from student ambition to real-world opportunity.",
        "fr": "Un chemin plus clair de l'ambition étudiante à l'opportunité concrète.",
        "ar": "مسار أوضح من طموح الطالب إلى الفرصة الحقيقية."
    },
    "platformStoryBody": {
        "en": "The app brings together profiles, CV tools, opportunities, scholarships, project ideas, and communication so students can move from discovery to action in one place.",
        "fr": "L'application rassemble les profils, les outils de CV, les opportunités, les bourses, les idées de projets et la communication pour que les étudiants puissent passer de la découverte à l'action en un seul endroit.",
        "ar": "يجمع التطبيق بين الملفات الشخصية وأدوات السيرة الذاتية والفرص والمنح الدراسية وأفكار المشاريع والتواصل ليتمكن الطلاب من الانتقال من الاكتشاف إلى العمل في مكان واحد."
    },
    "moreInformationTitle": {
        "en": "More Information",
        "fr": "Plus d'informations",
        "ar": "مزيد من المعلومات"
    },
    "moreInformationSubtitle": {
        "en": "Useful references and contact points for the platform.",
        "fr": "Références utiles et points de contact pour la plateforme.",
        "ar": "مراجع مفيدة ونقاط اتصال للمنصة."
    },
    "termsAboutTitle": {
        "en": "Terms",
        "fr": "Conditions",
        "ar": "الشروط"
    },
    "termsAboutSubtitle": {
        "en": "Read the platform usage summary",
        "fr": "Lire le résumé d'utilisation de la plateforme",
        "ar": "اقرأ ملخص استخدام المنصة"
    },
    "termsAboutBody": {
        "en": "FutureGate expects accurate profiles, respectful communication, and responsible use of the application and content tools available in the app.",
        "fr": "FutureGate exige des profils précis, une communication respectueuse et une utilisation responsable des outils de candidature et de contenu disponibles dans l'application.",
        "ar": "يتوقع FutureGate ملفات شخصية دقيقة وتواصلًا محترمًا واستخدامًا مسؤولًا لأدوات الطلبات والمحتوى المتاحة في التطبيق."
    },
    "privacyPolicyAboutSubtitle": {
        "en": "See how data supports the experience",
        "fr": "Découvrez comment les données soutiennent l'expérience",
        "ar": "اطلع على كيفية دعم البيانات للتجربة"
    },
    "privacyPolicyAboutBody": {
        "en": "Profile, CV, notification, and application data are used only to provide the matching, review, and communication features that power the FutureGate experience.",
        "fr": "Les données de profil, CV, notifications et candidatures ne sont utilisées que pour fournir les fonctionnalités de mise en correspondance, d'évaluation et de communication qui alimentent l'expérience FutureGate.",
        "ar": "تُستخدم بيانات الملف الشخصي والسيرة الذاتية والإشعارات والطلبات فقط لتوفير ميزات المطابقة والمراجعة والتواصل التي تشغّل تجربة FutureGate."
    },
    "contactAboutTitle": {
        "en": "Contact",
        "fr": "Contact",
        "ar": "التواصل"
    },
    "websiteSocialTitle": {
        "en": "Website & Social",
        "fr": "Site web et réseaux sociaux",
        "ar": "الموقع والتواصل الاجتماعي"
    },
    "websiteSocialSubtitle": {
        "en": "Public links are added here as they go live",
        "fr": "Les liens publics seront ajoutés ici dès leur mise en ligne",
        "ar": "ستُضاف الروابط العامة هنا عند نشرها"
    },
    "websiteSocialBody": {
        "en": "A public website and social channels are not linked inside this build yet. Support requests can still be sent directly by email.",
        "fr": "Un site web public et des réseaux sociaux ne sont pas encore liés dans cette version. Les demandes de support peuvent toujours être envoyées directement par email.",
        "ar": "لم يتم ربط موقع ويب عام وقنوات تواصل اجتماعي في هذا الإصدار بعد. لا يزال بالإمكان إرسال طلبات الدعم مباشرة عبر البريد الإلكتروني."
    },
    "noEmailAppAvailableAltBody": {
        "en": "No email app is available right now.",
        "fr": "Aucune application email n'est disponible pour le moment.",
        "ar": "لا يتوفر تطبيق بريد إلكتروني حاليًا."
    },
    "aboutFutureGateSubject": {
        "en": "About FutureGate",
        "fr": "À propos de FutureGate",
        "ar": "حول FutureGate"
    },

    # === logout_confirmation_sheet.dart ===
    "signOutAdminQuestion": {
        "en": "Sign out of admin?",
        "fr": "Se déconnecter du compte administrateur ?",
        "ar": "تسجيل الخروج من حساب المسؤول؟"
    },
    "signOutAdminBody": {
        "en": "You will leave the admin workspace on this device. Saved changes stay safe.",
        "fr": "Vous quitterez l'espace de travail administrateur sur cet appareil. Les modifications enregistrées restent en sécurité.",
        "ar": "ستغادر مساحة عمل المسؤول على هذا الجهاز. التغييرات المحفوظة تبقى آمنة."
    },
    "signOutCompanyQuestion": {
        "en": "Sign out of company?",
        "fr": "Se déconnecter du compte entreprise ?",
        "ar": "تسجيل الخروج من حساب الشركة؟"
    },
    "signOutCompanyBody": {
        "en": "You will leave the company workspace on this device. Your profile and opportunities stay saved.",
        "fr": "Vous quitterez l'espace de travail entreprise sur cet appareil. Votre profil et vos opportunités restent enregistrés.",
        "ar": "ستغادر مساحة عمل الشركة على هذا الجهاز. ملفك الشخصي والفرص تبقى محفوظة."
    },
    "signOutStudentQuestion": {
        "en": "Sign out of student?",
        "fr": "Se déconnecter du compte étudiant ?",
        "ar": "تسجيل الخروج من حساب الطالب؟"
    },
    "signOutStudentBody": {
        "en": "You will leave your student workspace on this device. Your profile and saved items stay safe.",
        "fr": "Vous quitterez votre espace de travail étudiant sur cet appareil. Votre profil et vos éléments enregistrés restent en sécurité.",
        "ar": "ستغادر مساحة عمل الطالب على هذا الجهاز. ملفك الشخصي والعناصر المحفوظة تبقى آمنة."
    },
    "signOutFutureGateQuestion": {
        "en": "Sign out of FutureGate?",
        "fr": "Se déconnecter de FutureGate ?",
        "ar": "تسجيل الخروج من FutureGate؟"
    },
    "signOutFutureGateBody": {
        "en": "You can sign back in anytime with the same account.",
        "fr": "Vous pouvez vous reconnecter à tout moment avec le même compte.",
        "ar": "يمكنك تسجيل الدخول مجددًا في أي وقت بنفس الحساب."
    },
    "adminRoleLabel": {
        "en": "Admin",
        "fr": "Administrateur",
        "ar": "مسؤول"
    },
    "companyRoleLabel": {
        "en": "Company",
        "fr": "Entreprise",
        "ar": "شركة"
    },
    "studentRoleLabel": {
        "en": "Student",
        "fr": "Étudiant",
        "ar": "طالب"
    },
    "accountRoleLabel": {
        "en": "Account",
        "fr": "Compte",
        "ar": "حساب"
    },
    "signingOutLabel": {
        "en": "Signing out",
        "fr": "Déconnexion en cours",
        "ar": "جارٍ تسجيل الخروج"
    },
    "futureGateAccountFallback": {
        "en": "FutureGate account",
        "fr": "Compte FutureGate",
        "ar": "حساب FutureGate"
    },
}


def process_arb(filepath, locale):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    data = json.loads(content)

    added = 0
    for key, translations in NEW_KEYS.items():
        if key not in data:
            data[key] = translations[locale]
            added += 1
            # Add placeholders metadata if present
            if "placeholders" in translations:
                data[f"@{key}"] = {"placeholders": translations["placeholders"]}

    # Write back with proper formatting
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')

    print(f"{filepath}: added {added} new keys")


process_arb('lib/l10n/app_en.arb', 'en')
process_arb('lib/l10n/app_fr.arb', 'fr')
process_arb('lib/l10n/app_ar.arb', 'ar')
print("Done!")
