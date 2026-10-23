/* CineConnect's multi-role navigation for the current production web build.
 * It reads only the signed-in user's granted roles from /me. Tokens stay in
 * memory, and every destination still passes the existing portal guards. */
(() => {
  'use strict';

  const authStorageKey = 'FlutterSecureStorage.cineconnect.access_token';
  const hiddenRoutes = new Set([
    '/login', '/signup', '/onboarding', '/roles', '/profile/roles',
    '/forgot-password', '/reset-password', '/demo-access',
  ]);
  const item = (key, label, route) => ({key, label, route});
  const portals = {
    director_producer: {
      label: 'Director / Producer', home: '/console', tools: [
        item('dashboard', 'Dashboard', '/console'),
        item('discover', 'Discover', '/director/marketplace'),
        item('cineplanner', 'CinePlanner', '/director/cineplanner'),
        item('projects', 'Projects', '/director/projects'),
        item('shortlist', 'Shortlist', '/director/shortlist'),
        item('bargaining', 'Bargaining', '/director/bargaining'),
        item('contracts', 'Contracts', '/director/contracts'),
        item('payments', 'Payments', '/director/payments'),
        item('schedule', 'Production schedule', '/director/schedule'),
        item('accounts', 'Accounts', '/director/accounts'),
        item('room', 'Production room', '/director/room'),
        item('reports', 'Reports', '/director/reports'),
      ],
    },
    actor_talent: {
      label: 'Actor', home: '/talent', tools: [
        item('dashboard', 'Dashboard', '/talent'),
        item('discover', 'Discover', '/discover'),
        item('profile', 'Profile', '/talent/profile'),
        item('portfolio', 'Portfolio', '/talent/portfolio'),
        item('availability', 'Availability', '/talent/availability'),
        item('rates', 'Rates', '/talent/rates'),
        item('opportunities', 'Opportunities', '/talent/opportunities'),
        item('applications', 'Applications', '/talent/applications'),
        item('auditions', 'Auditions', '/talent/auditions'),
        item('bookings', 'Bookings', '/talent/bookings'),
        item('contracts', 'Contracts', '/talent/contracts'),
        item('earnings', 'Earnings', '/talent/earnings'),
        item('reviews', 'Reviews', '/talent/reputation'),
        item('safety', 'Safety & support', '/talent/safety'),
      ],
    },
    model: {
      label: 'Model', home: '/model', tools: [
        item('dashboard', 'Dashboard', '/model'),
        item('profile', 'Profile', '/model/profile'),
        item('portfolio', 'Portfolio', '/model/portfolio-categories'),
        item('categories', 'Campaign categories', '/model'),
        item('usage', 'Usage rights', '/model/usage-rights'),
        item('rates', 'Rates', '/model/rate-by-usage'),
        item('brand-safety', 'Brand safety', '/model/brand-safety'),
        item('opportunities', 'Opportunities', '/model/opportunities'),
      ],
    },
    influencer: {
      label: 'Influencer', home: '/influencer', tools: [
        item('dashboard', 'Dashboard', '/influencer'),
        item('discover', 'Discover', '/discover'),
        item('media-kit', 'Media kit', '/influencer/media-kit'),
        item('packages', 'Rate packages', '/influencer/packages'),
        item('campaigns', 'Campaigns', '/influencer/campaigns'),
        item('analytics', 'Campaign analytics', '/influencer/analytics'),
        item('portfolio', 'Portfolio', '/influencer/portfolio'),
        item('availability', 'Availability', '/influencer/calendar'),
        item('contracts', 'Contracts', '/influencer/contracts'),
        item('earnings', 'Earnings', '/influencer/earnings'),
        item('reviews', 'Reviews', '/influencer/reviews'),
        item('safety', 'Safety & support', '/influencer/safety'),
      ],
    },
    general_public: {
      label: 'Customer', home: '/public', tools: [
        item('dashboard', 'Dashboard', '/public'),
        item('discover', 'Discover', '/public/browse'),
        item('cinema', 'Cinema', '/public/cinema'),
        item('actors', 'Find actors', '/public/actors'),
        item('models', 'Find models', '/public/models'),
        item('influencers', 'Find influencers', '/public/influencers'),
        item('requests', 'My requests', '/public/requests'),
        item('contracts', 'Contracts', '/public/contracts'),
        item('payments', 'Payments', '/public/payments'),
        item('account', 'Account', '/public/account'),
      ],
    },
    location_owner: {
      label: 'Location owner', home: '/location-owner', tools: [
        item('dashboard', 'Dashboard', '/location-owner'),
        item('profile', 'Profile', '/location-owner/profile'),
        item('portfolio', 'Portfolio', '/location-owner/portfolio'),
        item('properties', 'Properties', '/location-owner/listing-wizard'),
        item('availability', 'Availability', '/location-owner/availability'),
        item('rates', 'Rates', '/location-owner/pricing'),
        item('property-rules', 'Property rules', '/location-owner/rules'),
        item('requests', 'Booking requests', '/location-owner/requests'),
        item('check-in', 'Check-in', '/location-owner/check-in'),
        item('check-out', 'Check-out & claims', '/location-owner/check-out'),
        item('earnings', 'Earnings', '/location-owner/earnings'),
        item('performance', 'Property insights', '/location-owner/performance'),
        item('opportunities', 'Opportunities', '/location-owner/opportunities'),
      ],
    },
    equipment_provider: {
      label: 'Equipment provider', home: '/equipment-provider', tools: [
        item('dashboard', 'Dashboard', '/equipment-provider'),
        item('profile', 'Profile', '/equipment-provider/profile'),
        item('portfolio', 'Portfolio', '/equipment-provider/portfolio'),
        item('inventory', 'Inventory', '/equipment-provider/inventory'),
        item('packages', 'Packages', '/equipment-provider/packages'),
        item('availability', 'Availability', '/equipment-provider/availability'),
        item('rates', 'Rates & terms', '/equipment-provider/terms'),
        item('requests', 'Requests', '/equipment-provider/requests'),
        item('handover', 'Handover', '/equipment-provider/handover'),
        item('returns', 'Returns', '/equipment-provider/return'),
        item('earnings', 'Earnings', '/equipment-provider/earnings'),
        item('opportunities', 'Opportunities', '/equipment-provider/opportunities'),
      ],
    },
    crew_service: {
      label: 'Production services', home: '/crew', tools: [
        item('dashboard', 'Dashboard', '/crew'),
        item('profile', 'Profile', '/crew/profile'),
        item('portfolio', 'Portfolio', '/crew/portfolio'),
        item('availability', 'Availability', '/crew/availability'),
        item('requests', 'Requests', '/crew/requests'),
        item('contracts', 'Contracts & payments', '/crew/contracts-payments'),
        item('reviews', 'Ratings & work history', '/crew/ratings'),
        item('opportunities', 'Opportunities', '/crew/opportunities'),
      ],
    },
    casting_agency: {
      label: 'Casting agency', home: '/agency', tools: [
        item('dashboard', 'Dashboard', '/agency'),
        item('roster', 'Artist roster', '/agency/roster'),
        item('auditions', 'Auditions', '/agency/auditions'),
        item('shortlist', 'Candidate shortlist', '/agency/shortlist'),
        item('self-tapes', 'Self-tapes', '/agency/self-tapes'),
        item('selection-notes', 'Selection notes', '/agency/selection-notes'),
        item('commission', 'Commission', '/agency/commission'),
        item('bookings', 'Booking records', '/agency/records'),
      ],
    },
    brand_sponsor: {
      label: 'Brand / sponsor', home: '/brand', tools: [
        item('dashboard', 'Dashboard', '/brand'),
        item('profile', 'Profile', '/brand/profile'),
        item('discover', 'Discover', '/brand/discover'),
        item('projects', 'Projects & campaigns', '/brand/projects'),
        item('shortlist', 'Shortlists', '/brand/shortlists'),
        item('bookings', 'Bookings', '/brand/requests'),
        item('opportunities', 'Post an opportunity', '/brand/opportunity-composer'),
        item('applications', 'Applications', '/brand/applications'),
        item('bargaining', 'Terms & deals', '/brand/negotiation'),
        item('campaign-tracker', 'Campaign delivery', '/brand/campaign-tracker'),
        item('payments', 'Finance & records', '/brand/payments'),
      ],
    },
    legal_partner: {
      label: 'Legal partner', home: '/legal', tools: [
        item('dashboard', 'Dashboard', '/legal'),
        item('contract-review', 'Contract review', '/legal/contract-review'),
        item('template-review', 'Template review', '/legal/template-review'),
        item('addendum-review', 'Addendum review', '/legal/addendum-review'),
        item('billing', 'Review history & billing', '/legal/history-billing'),
      ],
    },
    insurance_partner: {
      label: 'Insurance / safety', home: '/insurance', tools: [
        item('dashboard', 'Dashboard', '/insurance'),
        item('insurance-records', 'Insurance records', '/insurance/records'),
        item('claims', 'Claim support', '/insurance/claims'),
        item('permits', 'Safety checks & permits', '/insurance/safety-permits'),
        item('incidents', 'Incident reports', '/insurance/incidents'),
      ],
    },
    distribution_partner: {
      label: 'Distribution partner', home: '/distribution', tools: [
        item('dashboard', 'Dashboard', '/distribution'),
        item('contacts', 'Distributor contacts', '/distribution/contacts'),
        item('release', 'Release coordination', '/distribution/release'),
        item('reports', 'Performance reports', '/distribution/reports'),
      ],
    },
    super_admin: {
      label: 'Admin', home: '/admin/dashboard', tools: [
        item('dashboard', 'Dashboard', '/admin/dashboard'),
        item('review-hub', 'Review hub', '/admin/review-hub'),
        item('verifications', 'Verifications', '/admin/verifications'),
        item('moderation', 'Moderation', '/admin/content-moderation'),
        item('bookings', 'Bookings monitor', '/admin/bookings-monitor'),
        item('payments', 'Payments', '/admin/payments'),
        item('disputes', 'Disputes', '/admin/disputes'),
        item('users', 'Users', '/admin/users'),
        item('permissions', 'Admin roles', '/admin/admin-roles'),
        item('analytics', 'Analytics', '/admin/analytics'),
      ],
    },
    reviewer: {label: 'Reviewer', home: '/admin/verifications', tools: [
      item('dashboard', 'Dashboard', '/admin/verifications'),
      item('verifications', 'Verifications', '/admin/verifications'),
      item('moderation', 'Moderation', '/admin/content-moderation'),
    ]},
    finance_admin: {label: 'Finance admin', home: '/admin/payment-queue', tools: [
      item('dashboard', 'Dashboard', '/admin/payment-queue'),
      item('payments', 'Payment queue', '/admin/payment-queue'),
      item('ledger', 'Payment ledger', '/admin/payments/ledger'),
    ]},
    support_agent: {label: 'Support', home: '/admin/disputes', tools: [
      item('dashboard', 'Dashboard', '/admin/disputes'),
      item('disputes', 'Disputes', '/admin/disputes'),
      item('support', 'Support', '/admin/support'),
    ]},
  };

  const nativeFetch = window.fetch.bind(window);
  let accessToken = null;
  let user = null;
  let roleLabels = {};
  let loadInFlight = null;
  let lastLoadAttempt = 0;
  let lastCaptureAt = 0;
  let menuOpen = false;
  let dashboardOpen = false;
  let lastRoute = null;
  let restoreFocus = null;
  let entry, drawer, backdrop, menuBody, dashboard, status, search;

  function currentRoute() {
    return location.hash.startsWith('#/')
      ? location.hash.slice(1).split('?')[0] : location.pathname;
  }
  function storedSession() {
    try { return Boolean(localStorage.getItem(authStorageKey)); }
    catch (_) { return false; }
  }
  function activeRoles() {
    return (user?.roles || [])
      .filter((role) => role.status === 'active' && portals[role.code])
      .map((role) => role.code);
  }
  function nameFor(code) { return roleLabels[code] || portals[code]?.label || code; }
  function primaryRole() {
    return (user?.roles || []).find((role) => role.is_primary)?.code;
  }
  function api(path, options = {}) {
    return nativeFetch('/api/v1' + path, {
      ...options,
      headers: {
        Authorization: 'Bearer ' + accessToken,
        Accept: 'application/json',
        ...(options.body ? {'Content-Type': 'application/json'} : {}),
        ...options.headers,
      },
      credentials: 'same-origin',
    });
  }
  async function loadMe() {
    if (!accessToken || !storedSession()) return;
    if (loadInFlight) return loadInFlight;
    lastLoadAttempt = Date.now();
    loadInFlight = (async () => {
      try {
        const response = await api('/me');
        if (!response.ok) return;
        const payload = await response.json();
        user = payload.data;
        roleLabels = {};
        if (activeRoles().includes('director_producer')) {
          try {
            const profile = await api('/professional-profiles/director_producer');
            if (profile.ok) {
              const focus = (await profile.json()).data?.fields?.focus;
              if (['Director', 'Producer', 'Director & Producer'].includes(focus)) {
                roleLabels.director_producer = focus;
              }
            }
          } catch (_) { /* The menu still uses the granted portal name. */ }
        }
        render();
      } catch (_) { /* The app can retry when its next authenticated request runs. */ }
      finally { loadInFlight = null; }
    })();
    return loadInFlight;
  }
  function capture(value) {
    if (typeof value !== 'string' || !value.startsWith('Bearer ')) return;
    const token = value.slice(7);
    if (!token || token === accessToken) return;
    accessToken = token;
    lastCaptureAt = Date.now();
    user = null;
    window.setTimeout(loadMe, 0);
  }
  function isOwnApi(url) {
    try {
      const parsed = new URL(url, location.href);
      return parsed.origin === location.origin && parsed.pathname.startsWith('/api/v1/');
    } catch (_) { return false; }
  }
  window.fetch = function (input, init) {
    const url = typeof input === 'string' || input instanceof URL ? input : input?.url;
    if (isOwnApi(url)) {
      const headers = new Headers(input?.headers || {});
      new Headers(init?.headers || {}).forEach((value, key) => headers.set(key, value));
      capture(headers.get('authorization'));
    }
    return nativeFetch(input, init);
  };
  const originalOpen = XMLHttpRequest.prototype.open;
  const originalSetHeader = XMLHttpRequest.prototype.setRequestHeader;
  const requestUrl = new WeakMap();
  XMLHttpRequest.prototype.open = function (method, url, ...rest) {
    requestUrl.set(this, url);
    return originalOpen.call(this, method, url, ...rest);
  };
  XMLHttpRequest.prototype.setRequestHeader = function (name, value) {
    if (isOwnApi(requestUrl.get(this)) && name.toLowerCase() === 'authorization') {
      capture(value);
    }
    return originalSetHeader.call(this, name, value);
  };

  function catalog() {
    const codes = activeRoles();
    const byKey = new Map();
    for (const code of codes) {
      for (const tool of portals[code].tools) {
        if (!byKey.has(tool.key)) byKey.set(tool.key, []);
        byKey.get(tool.key).push({...tool, role: code});
      }
    }
    const common = [];
    const exclusive = new Map(codes.map((code) => [code, []]));
    for (const variants of byKey.values()) {
      if (variants.length > 1) common.push({
        key: variants[0].key,
        label: variants[0].key === 'dashboard' ? 'Dashboard' : variants[0].label,
        variants,
      });
      else exclusive.get(variants[0].role).push(variants[0]);
    }
    common.sort((a, b) => (a.key === 'dashboard' ? -1 : b.key === 'dashboard' ? 1 : 0));
    return {common, exclusive};
  }
  function el(tag, className, text) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text != null) node.textContent = text;
    return node;
  }
  function button(label, action, className = 'ccu-link') {
    const node = el('button', className, label);
    node.type = 'button';
    node.addEventListener('click', action);
    return node;
  }
  function closeOverlays() {
    menuOpen = false;
    dashboardOpen = false;
    drawer.hidden = true;
    backdrop.hidden = true;
    dashboard.hidden = true;
    entry?.setAttribute('aria-expanded', 'false');
    document.body.classList.remove('ccu-open');
    restoreFocus?.focus();
    restoreFocus = null;
  }
  function openMenu() {
    if (!user || activeRoles().length < 2) return;
    restoreFocus = document.activeElement;
    menuOpen = true;
    dashboardOpen = false;
    renderMenu();
    drawer.hidden = false;
    backdrop.hidden = false;
    dashboard.hidden = true;
    document.body.classList.add('ccu-open');
    entry.setAttribute('aria-expanded', 'true');
    search.focus();
    loadMe();
  }
  function openDashboard() {
    if (!user || activeRoles().length < 2) return;
    restoreFocus = document.activeElement;
    menuOpen = false;
    dashboardOpen = true;
    renderDashboard();
    drawer.hidden = true;
    backdrop.hidden = true;
    dashboard.hidden = false;
    document.body.classList.add('ccu-open');
    entry.setAttribute('aria-expanded', 'true');
    dashboard.querySelector('button')?.focus();
  }
  async function goTo(role, route, nativeOverview = false) {
    if (!activeRoles().includes(role)) return;
    status.textContent = '';
    if (nativeOverview) {
      try { sessionStorage.setItem('ccu-native-overview', role + '|' + route); }
      catch (_) { /* The in-memory close still works. */ }
    }
    if (primaryRole() !== role) {
      status.textContent = 'Opening ' + nameFor(role) + ' tools…';
      try {
        const response = await api('/me/primary-role', {
          method: 'PATCH', body: JSON.stringify({role}),
        });
        if (!response.ok) throw new Error('Unable to switch to this role.');
        user = (await response.json()).data;
        location.hash = '#' + route;
        location.reload();
      } catch (_) {
        status.textContent = 'Could not open this role. Try again after refreshing.';
      }
      return;
    }
    closeOverlays();
    location.hash = '#' + route;
    if (nativeOverview) lastRoute = route;
  }
  function toolButton(tool, role, text = tool.label) {
    return button(text, () => goTo(role, tool.route));
  }
  function commonButton(entryData) {
    if (entryData.key === 'dashboard') {
      return button('Dashboard', openDashboard);
    }
    if (entryData.variants.length === 1) {
      const only = entryData.variants[0];
      return toolButton(only, only.role);
    }
    const holder = el('div', 'ccu-variant-holder');
    const toggle = button(entryData.label, () => {
      const expanded = toggle.getAttribute('aria-expanded') === 'true';
      toggle.setAttribute('aria-expanded', String(!expanded));
      choices.hidden = expanded;
    });
    toggle.setAttribute('aria-expanded', 'false');
    toggle.append(el('span', 'ccu-chevron', '⌄'));
    const choices = el('div', 'ccu-choices');
    choices.hidden = true;
    for (const variant of entryData.variants) {
      choices.append(toolButton(variant, variant.role, nameFor(variant.role)));
    }
    holder.append(toggle, choices);
    return holder;
  }
  function renderMenu() {
    if (!menuBody || !user) return;
    const query = search.value.trim().toLowerCase();
    const {common, exclusive} = catalog();
    menuBody.replaceChildren();
    const shared = el('div', 'ccu-list');
    for (const entryData of common) {
      if (!query || entryData.label.toLowerCase().includes(query)) {
        shared.append(commonButton(entryData));
      }
    }
    if (shared.childElementCount) menuBody.append(shared);
    for (const [code, tools] of exclusive) {
      const matches = tools.filter((tool) =>
        !query || tool.label.toLowerCase().includes(query) || nameFor(code).toLowerCase().includes(query));
      if (!matches.length) continue;
      const group = el('details', 'ccu-group');
      group.open = true;
      group.append(el('summary', '', nameFor(code) + ' exclusive'));
      const list = el('div', 'ccu-list');
      matches.forEach((tool) => list.append(toolButton(tool, code)));
      group.append(list);
      menuBody.append(group);
    }
    if (!menuBody.childElementCount) menuBody.append(el('p', 'ccu-empty', 'No tools match that search.'));
  }
  function renderDashboard() {
    if (!dashboard || !user) return;
    const {common, exclusive} = catalog();
    const content = dashboard.querySelector('.ccu-dashboard-content');
    content.replaceChildren();
    const intro = el('div', 'ccu-dashboard-intro');
    intro.append(el('p', 'ccu-overline', 'YOUR COMPLETE WORKSPACE'));
    intro.append(el('h1', '', (user.display_name || 'Your') + ' dashboard'));
    intro.append(el('p', 'ccu-muted',
      'Your shared tools appear once. Every specialist tool from your active roles is below.'));
    content.append(intro);
    const commonCard = el('section', 'ccu-dashboard-card');
    commonCard.setAttribute('aria-label', 'Tools available across your roles');
    const sharedGrid = el('div', 'ccu-tool-grid');
    common.forEach((entryData) => {
      if (entryData.key !== 'dashboard') sharedGrid.append(commonButton(entryData));
    });
    commonCard.append(sharedGrid);
    content.append(commonCard);
    const rolesGrid = el('div', 'ccu-role-grid');
    for (const code of activeRoles()) {
      const card = el('section', 'ccu-dashboard-card ccu-role-card');
      const top = el('div', 'ccu-card-top');
      const title = el('div');
      title.append(el('p', 'ccu-overline', 'ACTIVE ROLE'));
      title.append(el('h2', '', nameFor(code) + ' exclusive'));
      top.append(title);
      top.append(button('Open overview →', () => goTo(code, portals[code].home, true), 'ccu-overview'));
      card.append(top);
      const tools = exclusive.get(code) || [];
      const grid = el('div', 'ccu-tool-grid');
      tools.forEach((tool) => grid.append(toolButton(tool, code)));
      if (!tools.length) grid.append(el('p', 'ccu-muted', 'All your tools are shared with another role.'));
      card.append(grid);
      rolesGrid.append(card);
    }
    content.append(rolesGrid);
  }
  function render() {
    if (!entry) return;
    if (!storedSession()) {
      user = null;
      roleLabels = {};
      if (Date.now() - lastCaptureAt > 5000) accessToken = null;
    } else if (accessToken && !user && !loadInFlight &&
        Date.now() - lastLoadAttempt > 5000) {
      loadMe();
    }
    const visible = storedSession() && activeRoles().length > 1 && !hiddenRoutes.has(currentRoute());
    entry.hidden = !visible;
    if (!visible) {
      if (menuOpen || dashboardOpen) closeOverlays();
      return;
    }
    entry.querySelector('.ccu-entry-count').textContent = activeRoles().length + ' roles';
    if (menuOpen) renderMenu();
    if (dashboardOpen) renderDashboard();
    const route = currentRoute();
    if (route !== lastRoute) {
      lastRoute = route;
      let nativeOverview = false;
      try {
        const saved = sessionStorage.getItem('ccu-native-overview');
        nativeOverview = activeRoles().some((code) => saved === code + '|' + route);
        if (nativeOverview) sessionStorage.removeItem('ccu-native-overview');
      } catch (_) { /* Standard dashboard behavior remains available. */ }
      if (!nativeOverview && activeRoles().some((code) => portals[code].home === route)) {
        openDashboard();
      }
    }
  }
  function build() {
    const style = el('style');
    style.textContent = `
      .ccu-open { overflow: hidden !important; }
      #cc-unified-entry, #cc-unified-drawer, #cc-unified-dashboard,
      #cc-unified-backdrop { font-family: Inter,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif; box-sizing:border-box; }
      #cc-unified-drawer *, #cc-unified-dashboard * { box-sizing:border-box; min-width:0; }
      #cc-unified-entry[hidden], #cc-unified-drawer[hidden],
      #cc-unified-dashboard[hidden], #cc-unified-backdrop[hidden], .ccu-choices[hidden] { display:none !important; }
      #cc-unified-entry { position:fixed; z-index:2147482000; left:32px; bottom:28px;
        min-height:48px; padding:8px 15px; border:1px solid #d6b454; border-radius:16px;
        background:#fffdf8; color:#242019; box-shadow:0 12px 32px #27211330;
        display:flex; align-items:center; gap:9px; font-size:14px; font-weight:750; cursor:pointer; }
      #cc-unified-entry:hover, .ccu-link:hover, .ccu-overview:hover { background:#fbf1d6; }
      .ccu-entry-count { color:#8c6712; font-size:12px; font-weight:800; }
      #cc-unified-backdrop { position:fixed; inset:0; z-index:2147483000; background:#16130db3; }
      #cc-unified-drawer { position:fixed; z-index:2147483001; inset:0 auto 0 0;
        width:min(420px,100vw); background:#f8f6f1; color:#242019; box-shadow:18px 0 55px #17130d3d;
        display:flex; flex-direction:column; }
      .ccu-drawer-head { padding:24px 22px 16px; border-bottom:1px solid #e3ded3; }
      .ccu-head-row { display:flex; align-items:center; justify-content:space-between; gap:12px; }
      .ccu-brand { font-size:20px; font-weight:850; letter-spacing:-.04em; }
      .ccu-brand strong { color:#a7780c; }
      .ccu-close { min-width:44px; min-height:44px; border:1px solid #dcd7cd; border-radius:50%;
        background:#fff; color:#28231b; font-size:21px; cursor:pointer; }
      .ccu-drawer-head h2 { margin:16px 0 5px; font-size:22px; line-height:1.2; }
      .ccu-muted { color:#686258; line-height:1.5; }
      .ccu-drawer-head p { margin:0; font-size:13px; }
      .ccu-search-label { display:block; margin-top:18px; font-size:12px; font-weight:800; color:#5b544a; }
      .ccu-search { width:100%; height:46px; margin-top:7px; padding:0 13px; border:1px solid #dcd7cd;
        border-radius:13px; background:#fff; color:#201d18; font-size:14px; }
      .ccu-scroll { flex:1; overflow-y:auto; padding:15px 17px 20px; }
      .ccu-list { display:grid; gap:7px; }
      .ccu-link { width:100%; min-height:45px; padding:10px 14px; display:flex; justify-content:space-between;
        align-items:center; text-align:left; border:1px solid #e1ddd4; border-radius:13px;
        background:#fff; color:#28231b; font-size:14px; font-weight:700; cursor:pointer;
        overflow-wrap:anywhere; }
      .ccu-link:focus-visible, #cc-unified-entry:focus-visible, .ccu-close:focus-visible,
      .ccu-overview:focus-visible, .ccu-search:focus-visible { outline:3px solid #a87913; outline-offset:2px; }
      .ccu-group { margin-top:20px; }
      .ccu-group summary { margin:0 5px 10px; color:#8d6816; font-size:12px; font-weight:850;
        letter-spacing:.08em; text-transform:uppercase; cursor:pointer; }
      .ccu-choices { display:grid; gap:5px; margin:6px 0 8px 17px; padding-left:11px; border-left:2px solid #ddc778; }
      .ccu-choices .ccu-link { background:#faf8f3; }
      .ccu-chevron { color:#8d6816; font-size:20px; }
      .ccu-drawer-foot { padding:13px 20px 20px; border-top:1px solid #e3ded3; }
      .ccu-drawer-foot button { width:100%; min-height:44px; border:0; background:transparent;
        color:#8d6816; font-weight:800; text-align:left; cursor:pointer; }
      .ccu-status { min-height:18px; padding:0 20px 9px; color:#92511d; font-size:12px; }
      #cc-unified-dashboard { position:fixed; z-index:2147483002; inset:0; overflow-y:auto;
        background:#f5f2eb; color:#25211b; }
      .ccu-dashboard-head { position:sticky; top:0; z-index:2; min-height:72px; padding:12px 28px;
        background:#ffffffef; border-bottom:1px solid #e7e1d5; display:flex; align-items:center;
        justify-content:space-between; gap:12px; }
      .ccu-dashboard-content { max-width:1250px; margin:auto; padding:34px 24px 70px; }
      .ccu-overline { margin:0 0 8px; color:#9a7117; font-size:11px; font-weight:850; letter-spacing:.15em; }
      .ccu-dashboard-intro { margin-bottom:25px; }
      .ccu-dashboard-intro h1 { margin:0 0 9px; font-family:Georgia,serif; font-size:clamp(30px,4vw,48px); }
      .ccu-dashboard-intro p:last-child { margin:0; }
      .ccu-dashboard-card { padding:23px; margin-bottom:18px; border:1px solid #e2daca; border-radius:23px;
        background:#fff; box-shadow:0 12px 32px #3028170d; }
      .ccu-dashboard-card h2 { margin:0 0 17px; font-size:20px; }
      .ccu-tool-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(170px,1fr)); gap:9px; }
      .ccu-role-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(min(100%,420px),1fr)); gap:18px; }
      .ccu-card-top { display:flex; align-items:flex-start; justify-content:space-between; gap:12px; }
      .ccu-overview { min-height:44px; padding:8px 12px; border:1px solid #d2ba76; border-radius:12px;
        color:#835c0d; background:#fffaf0; font-weight:800; cursor:pointer; }
      .ccu-empty { padding:14px; color:#686258; }
      @media (max-width:700px) {
        #cc-unified-entry { left:auto; right:16px; bottom:120px; padding:8px 11px; font-size:12px; }
        .ccu-dashboard-head { padding:10px 16px; }
        .ccu-dashboard-content { padding:25px 14px 115px; }
        .ccu-dashboard-card { padding:18px; }
        .ccu-card-top { flex-direction:column; }
        .ccu-tool-grid { grid-template-columns:repeat(2,minmax(0,1fr)); }
      }
      @media (prefers-reduced-motion:reduce) { #cc-unified-entry, .ccu-link { transition:none; } }
    `;
    document.head.append(style);
    entry = button('All my tools', openMenu);
    entry.id = 'cc-unified-entry';
    entry.hidden = true;
    entry.setAttribute('aria-label', 'Open all tools for your active roles');
    entry.setAttribute('aria-expanded', 'false');
    entry.append(el('span', 'ccu-entry-count'));
    backdrop = el('div');
    backdrop.id = 'cc-unified-backdrop';
    backdrop.hidden = true;
    backdrop.addEventListener('click', closeOverlays);
    drawer = el('aside');
    drawer.id = 'cc-unified-drawer';
    drawer.hidden = true;
    drawer.setAttribute('aria-label', 'Your complete workspace menu');
    const head = el('div', 'ccu-drawer-head');
    const brand = el('div', 'ccu-brand');
    brand.append(el('span', '', 'Cine'), el('strong', '', 'Connect'));
    const headRow = el('div', 'ccu-head-row');
    headRow.append(brand, button('×', closeOverlays, 'ccu-close'));
    head.append(headRow, el('h2', '', 'All your tools'),
      el('p', 'ccu-muted', 'One menu for every role on your account.'));
    const searchLabel = el('label', 'ccu-search-label', 'Find a tool');
    search = el('input', 'ccu-search');
    search.type = 'search';
    search.placeholder = 'Search tools…';
    search.addEventListener('input', renderMenu);
    searchLabel.append(search);
    head.append(searchLabel);
    menuBody = el('nav', 'ccu-scroll');
    const foot = el('div', 'ccu-drawer-foot');
    foot.append(button('Manage my roles →', () => {
      closeOverlays();
      location.hash = '#/profile/roles';
    }));
    status = el('p', 'ccu-status');
    status.setAttribute('role', 'status');
    drawer.append(head, menuBody, foot, status);
    dashboard = el('main');
    dashboard.id = 'cc-unified-dashboard';
    dashboard.hidden = true;
    dashboard.setAttribute('aria-label', 'Combined dashboard for all active roles');
    const dashboardHead = el('div', 'ccu-dashboard-head');
    const dashboardBrand = el('div', 'ccu-brand');
    dashboardBrand.append(el('span', '', 'Cine'), el('strong', '', 'Connect'));
    dashboardHead.append(dashboardBrand, button('Close', closeOverlays, 'ccu-overview'));
    dashboard.append(dashboardHead, el('div', 'ccu-dashboard-content'));
    document.body.append(entry, backdrop, drawer, dashboard);
    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape' && (menuOpen || dashboardOpen)) closeOverlays();
    });
    window.addEventListener('hashchange', render);
    window.addEventListener('storage', render);
    window.setInterval(render, 1200);
    render();
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', build, {once: true});
  } else build();
})();
