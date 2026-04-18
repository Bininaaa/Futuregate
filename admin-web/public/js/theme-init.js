(() => {
  const storageKey = 'futuregate-admin-theme';
  let theme = 'light';

  try {
    const stored = window.localStorage.getItem(storageKey);
    if (stored === 'dark' || stored === 'light') {
      theme = stored;
    } else if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
      theme = 'dark';
    }
  } catch (error) {
    if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
      theme = 'dark';
    }
  }

  document.documentElement.setAttribute('data-theme', theme);
})();
