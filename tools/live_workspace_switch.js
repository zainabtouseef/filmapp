(() => {
  'use strict';
  const tokenKey = 'FlutterSecureStorage.cineconnect.access_token';
  const hiddenPaths = new Set([
    '/login', '/signup', '/onboarding', '/roles', '/profile/roles',
    '/forgot-password', '/reset-password', '/demo-access',
  ]);
  const style = document.createElement('style');
  style.textContent = `
    #cc-workspace-entry {
      position: fixed;
      z-index: 2147482000;
      left: 32px;
      bottom: 28px;
      display: none;
      align-items: center;
      gap: 10px;
      min-height: 42px;
      padding: 0 14px;
      border: 1px solid #d7bd6d;
      border-radius: 14px;
      background: #fffdf8;
      box-shadow: 0 8px 28px rgba(28, 24, 14, .14);
      color: #28251e;
      font: 700 13px/1.2 Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      text-decoration: none;
      white-space: nowrap;
    }
    #cc-workspace-entry:focus-visible {
      outline: 3px solid #a77a16;
      outline-offset: 3px;
    }
    #cc-workspace-entry:hover { background: #faf2d8; }
    #cc-workspace-entry .cc-workspace-icon {
      display: grid;
      place-items: center;
      width: 25px;
      height: 25px;
      border-radius: 9px;
      background: #f5e9c1;
      color: #967016;
      font-size: 19px;
      line-height: 1;
    }
    @media (max-width: 899px) {
      #cc-workspace-entry {
        left: auto;
        right: 16px;
        bottom: 130px;
        min-height: 40px;
        padding: 0 11px;
        font-size: 12px;
      }
    }
  `;
  document.head.appendChild(style);
  const link = document.createElement('a');
  link.id = 'cc-workspace-entry';
  link.href = '/#/profile/roles';
  link.setAttribute('aria-label', 'Open your CineConnect workspaces and switch roles');
  const icon = document.createElement('span');
  icon.className = 'cc-workspace-icon';
  icon.setAttribute('aria-hidden', 'true');
  icon.textContent = '⇄';
  const label = document.createElement('span');
  label.textContent = 'My workspaces';
  link.append(icon, label);
  document.body.appendChild(link);

  function refresh() {
    let signedIn = false;
    try { signedIn = Boolean(localStorage.getItem(tokenKey)); } catch (_) {}
    const hashRoute = location.hash.startsWith('#/')
      ? location.hash.slice(1).split('?')[0] : '';
    const route = hashRoute || location.pathname;
    link.style.display = signedIn && !hiddenPaths.has(route)
      ? 'inline-flex' : 'none';
  }
  refresh();
  window.addEventListener('storage', refresh);
  window.addEventListener('popstate', refresh);
  window.setInterval(refresh, 1000);
})();
