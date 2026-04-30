(function () {
  var supportedLangs = ['en', 'fr', 'ar'];
  var pageKey = document.body.dataset.page || 'home';
  if (pageKey === 'canceled') pageKey = 'cancelled';

  var icons = {
    success: '<svg viewBox="0 0 96 96" role="img" aria-label="Payment received"><path d="M48 8 78 21v22c0 20-12.2 36.8-30 43-17.8-6.2-30-23-30-43V21L48 8Z"></path><path d="m32 49 11 11 23-27"></path></svg>',
    pending: '<svg viewBox="0 0 96 96" role="img" aria-label="Payment pending"><circle cx="48" cy="48" r="34"></circle><path d="M48 25v24l16 10"></path><path d="M20 20l10 10M76 20 66 30"></path></svg>',
    failed: '<svg viewBox="0 0 96 96" role="img" aria-label="Payment failed"><path d="M48 8 78 21v22c0 20-12.2 36.8-30 43-17.8-6.2-30-23-30-43V21L48 8Z"></path><path d="m36 36 24 24M60 36 36 60"></path></svg>',
    cancelled: '<svg viewBox="0 0 96 96" role="img" aria-label="Payment cancelled"><circle cx="48" cy="48" r="34"></circle><path d="M28 68 68 28"></path><path d="M34 34h28v28H34z"></path></svg>',
    notfound: '<svg viewBox="0 0 96 96" role="img" aria-label="Page not found"><circle cx="42" cy="42" r="25"></circle><path d="M61 61 78 78"></path><path d="M34 35h.01M50 35h.01M36 55c6-5 14-5 20 0"></path></svg>',
    home: '<svg viewBox="0 0 96 96" role="img" aria-label="Payment return"><path d="M18 28h60v44H18z"></path><path d="M18 40h60"></path><path d="M30 58h20M30 66h12"></path><path d="m62 62 6 6 12-16"></path></svg>'
  };

  var copy = {
    en: {
      common: {
        brandTagline: 'Payment return',
        eyebrow: 'Chargily Pay checkout',
        trustNote: 'This page does not activate Premium. The app confirms your subscription from the backend after the secure webhook is received.',
        returnButton: 'Return to FutureGate',
        downloadButton: 'Download APK',
        footer: 'FutureGate payment pages for Chargily Pay test checkout returns.'
      },
      pages: {
        home: {
          title: 'FutureGate payment return',
          message: 'Please open the payment status link provided after checkout, or return to FutureGate.',
          hint: 'Your Premium status is verified only inside the FutureGate app.',
          documentTitle: 'Payment Return | FutureGate'
        },
        success: {
          title: 'Payment received',
          message: 'We are confirming your Premium Pass. Please return to the FutureGate app.',
          hint: 'If Premium does not appear immediately, refresh your subscription status in the app.',
          documentTitle: 'Payment Received | FutureGate'
        },
        pending: {
          title: 'Payment is being checked',
          message: 'Please return to the app and refresh your subscription status.',
          hint: 'The final Premium status appears only after backend confirmation.',
          documentTitle: 'Payment Pending | FutureGate'
        },
        failed: {
          title: 'Payment failed',
          message: 'No money was confirmed for the Premium Pass. Please return to the app and try again.',
          hint: 'You can restart checkout from the Premium Pass screen inside FutureGate.',
          documentTitle: 'Payment Failed | FutureGate'
        },
        cancelled: {
          title: 'Payment was cancelled',
          message: 'You can return to the app and try again anytime.',
          hint: 'No Premium change happens from this page.',
          documentTitle: 'Payment Cancelled | FutureGate'
        },
        notfound: {
          title: 'Page not found',
          message: 'This FutureGate payment return page does not exist.',
          hint: 'Return to FutureGate and use the app to check your subscription status.',
          documentTitle: 'Page Not Found | FutureGate'
        }
      }
    },
    fr: {
      common: {
        brandTagline: 'Retour paiement',
        eyebrow: 'Paiement Chargily Pay',
        trustNote: "Cette page n'active pas Premium. L'application confirme votre abonnement depuis le backend après réception du webhook sécurisé.",
        returnButton: 'Retourner à FutureGate',
        downloadButton: "Télécharger l'APK",
        footer: 'Pages de retour FutureGate pour les paiements de test Chargily Pay.'
      },
      pages: {
        home: {
          title: 'Retour de paiement FutureGate',
          message: 'Ouvrez le lien de statut fourni après le paiement, ou retournez à FutureGate.',
          hint: "Votre statut Premium est vérifié uniquement dans l'application FutureGate.",
          documentTitle: 'Retour Paiement | FutureGate'
        },
        success: {
          title: 'Paiement reçu',
          message: "Nous confirmons votre Premium Pass. Veuillez retourner dans l'application FutureGate.",
          hint: "Si Premium n'apparaît pas immédiatement, actualisez le statut de votre abonnement dans l'application.",
          documentTitle: 'Paiement Reçu | FutureGate'
        },
        pending: {
          title: 'Paiement en vérification',
          message: "Veuillez retourner dans l'application et actualiser le statut de votre abonnement.",
          hint: 'Le statut Premium final apparaît uniquement après confirmation du backend.',
          documentTitle: 'Paiement En Attente | FutureGate'
        },
        failed: {
          title: 'Paiement échoué',
          message: "Aucun paiement n'a été confirmé pour le Premium Pass. Veuillez retourner dans l'application et réessayer.",
          hint: "Vous pouvez relancer le paiement depuis l'écran Premium Pass dans FutureGate.",
          documentTitle: 'Paiement Échoué | FutureGate'
        },
        cancelled: {
          title: 'Paiement annulé',
          message: "Vous pouvez retourner dans l'application et réessayer à tout moment.",
          hint: "Aucun changement Premium n'est effectué depuis cette page.",
          documentTitle: 'Paiement Annulé | FutureGate'
        },
        notfound: {
          title: 'Page introuvable',
          message: "Cette page de retour de paiement FutureGate n'existe pas.",
          hint: "Retournez à FutureGate et utilisez l'application pour vérifier le statut de votre abonnement.",
          documentTitle: 'Page Introuvable | FutureGate'
        }
      }
    },
    ar: {
      common: {
        brandTagline: 'عودة الدفع',
        eyebrow: 'دفع Chargily Pay',
        trustNote: 'هذه الصفحة لا تفعّل Premium. التطبيق يؤكد اشتراكك من الخادم بعد وصول إشعار الويب الآمن.',
        returnButton: 'العودة إلى FutureGate',
        downloadButton: 'تحميل APK',
        footer: 'صفحات عودة FutureGate لعمليات الدفع التجريبية عبر Chargily Pay.'
      },
      pages: {
        home: {
          title: 'عودة دفع FutureGate',
          message: 'افتح رابط حالة الدفع الذي ظهر بعد عملية الدفع، أو عد إلى FutureGate.',
          hint: 'يتم التحقق من حالة Premium فقط داخل تطبيق FutureGate.',
          documentTitle: 'عودة الدفع | FutureGate'
        },
        success: {
          title: 'تم استلام الدفع',
          message: 'نحن نؤكد Premium Pass الخاص بك. يرجى العودة إلى تطبيق FutureGate.',
          hint: 'إذا لم يظهر Premium فورًا، حدّث حالة الاشتراك داخل التطبيق.',
          documentTitle: 'تم استلام الدفع | FutureGate'
        },
        pending: {
          title: 'يتم التحقق من الدفع',
          message: 'يرجى العودة إلى التطبيق وتحديث حالة الاشتراك.',
          hint: 'تظهر حالة Premium النهائية فقط بعد تأكيد الخادم.',
          documentTitle: 'الدفع قيد التحقق | FutureGate'
        },
        failed: {
          title: 'فشل الدفع',
          message: 'لم يتم تأكيد أي مبلغ مقابل Premium Pass. يرجى العودة إلى التطبيق والمحاولة مرة أخرى.',
          hint: 'يمكنك بدء الدفع من جديد من شاشة Premium Pass داخل FutureGate.',
          documentTitle: 'فشل الدفع | FutureGate'
        },
        cancelled: {
          title: 'تم إلغاء الدفع',
          message: 'يمكنك العودة إلى التطبيق والمحاولة مرة أخرى في أي وقت.',
          hint: 'لا يحدث أي تغيير في Premium من هذه الصفحة.',
          documentTitle: 'تم إلغاء الدفع | FutureGate'
        },
        notfound: {
          title: 'الصفحة غير موجودة',
          message: 'صفحة عودة الدفع هذه غير موجودة في FutureGate.',
          hint: 'عد إلى FutureGate واستخدم التطبيق للتحقق من حالة اشتراكك.',
          documentTitle: 'الصفحة غير موجودة | FutureGate'
        }
      }
    }
  };

  function normalizeLang(lang) {
    return supportedLangs.indexOf(lang) >= 0 ? lang : 'en';
  }

  function currentLang() {
    var stored = localStorage.getItem('fg-payment-lang') || localStorage.getItem('fg-lang');
    if (stored) return normalizeLang(stored);
    return normalizeLang((navigator.language || 'en').slice(0, 2));
  }

  function setText(selector, value) {
    var node = document.querySelector(selector);
    if (node) node.textContent = value;
  }

  function applyLanguage(lang) {
    lang = normalizeLang(lang);
    var dictionary = copy[lang];
    var page = dictionary.pages[pageKey] || dictionary.pages.notfound;

    document.documentElement.lang = lang;
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
    document.title = page.documentTitle;

    document.querySelectorAll('[data-i18n]').forEach(function (node) {
      var key = node.getAttribute('data-i18n');
      if (dictionary.common[key]) node.textContent = dictionary.common[key];
    });

    setText('#pageTitle', page.title);
    setText('#pageMessage', page.message);
    setText('#pageHint', page.hint);

    document.querySelectorAll('.lang-btn').forEach(function (button) {
      button.classList.toggle('is-active', button.dataset.lang === lang);
    });

    localStorage.setItem('fg-payment-lang', lang);
  }

  function applyTheme(theme) {
    var normalized = theme === 'light' ? 'light' : 'dark';
    document.documentElement.dataset.theme = normalized;
    localStorage.setItem('fg-theme', normalized);
  }

  function initThemeToggle() {
    var toggle = document.getElementById('themeToggle');
    if (!toggle) return;
    toggle.addEventListener('click', function () {
      var next = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
      applyTheme(next);
    });
  }

  function initLanguageButtons() {
    document.querySelectorAll('.lang-btn').forEach(function (button) {
      button.addEventListener('click', function () {
        applyLanguage(button.dataset.lang);
      });
    });
  }

  function initStatus() {
    document.body.dataset.status = pageKey;
    var illustration = document.getElementById('statusIllustration');
    if (illustration) {
      illustration.innerHTML = icons[pageKey] || icons.notfound;
    }
  }

  document.addEventListener('DOMContentLoaded', function () {
    initStatus();
    initThemeToggle();
    initLanguageButtons();
    applyLanguage(currentLang());
  });
})();
