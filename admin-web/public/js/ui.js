// Lightweight UI helpers shared across pages

export function refreshIcons() {
  if (window.lucide && typeof window.lucide.createIcons === 'function') {
    window.lucide.createIcons();
  }
}

export function openModal(id) {
  const el = document.getElementById(id);
  if (el) {
    el.classList.add('open');
    document.body.style.overflow = 'hidden';
  }
}

export function closeModal(id) {
  const el = document.getElementById(id);
  if (el) {
    el.classList.remove('open');
    document.body.style.overflow = '';
  }
}

export function bindModalDismiss() {
  document.addEventListener('click', (e) => {
    const close = e.target.closest('[data-close-modal]');
    if (close) {
      const id = close.getAttribute('data-close-modal');
      if (id) closeModal(id);
      return;
    }
    if (e.target.classList && e.target.classList.contains('modal-backdrop')) {
      e.target.classList.remove('open');
      document.body.style.overflow = '';
    }
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      document.querySelectorAll('.modal-backdrop.open').forEach((m) => m.classList.remove('open'));
      document.body.style.overflow = '';
    }
  });
}

// Run lucide on initial load and re-run after async renders via MutationObserver
document.addEventListener('DOMContentLoaded', () => {
  refreshIcons();
  bindModalDismiss();
  const target = document.body;
  const obs = new MutationObserver(() => {
    if (target.querySelector('[data-lucide]:not([data-lucide-done])')) {
      target.querySelectorAll('[data-lucide]').forEach((el) => el.setAttribute('data-lucide-done', '1'));
      refreshIcons();
    }
  });
  obs.observe(target, { childList: true, subtree: true });
});
