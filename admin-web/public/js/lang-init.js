// Sets the document direction and lang attribute as early as possible based on
// the persisted admin language preference. Loaded as a non-module script in
// every page <head> alongside theme-init.js so RTL/LTR is correct before the
// first paint, before the i18n module is evaluated.
(function () {
  try {
    var STORAGE_KEY = 'futuregate-admin-lang';
    var SUPPORTED = ['en', 'ar', 'fr'];
    var stored = window.localStorage.getItem(STORAGE_KEY);
    var lang = SUPPORTED.indexOf(stored) >= 0 ? stored : 'en';
    document.documentElement.setAttribute('lang', lang);
    document.documentElement.setAttribute('dir', lang === 'ar' ? 'rtl' : 'ltr');
  } catch (error) {
    document.documentElement.setAttribute('lang', 'en');
    document.documentElement.setAttribute('dir', 'ltr');
  }
})();
