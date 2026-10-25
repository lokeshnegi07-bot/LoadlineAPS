/* Loadline sign-in and role access for the hosted demo.
   Accounts, passwords (hashed), role access and branding live in this browser's localStorage,
   shared by the landing page (/) and the app (/app/). This is a client-side demo, not real security:
   a production rollout needs server-side sign-in (for example SSO) and server-enforced access.
   Licensing: the vendor signs a license key (ECDSA P-256) with seats per workspace and an expiry date.
   Only the public key is here, so a customer can't raise their own seats; keys are issued with the
   vendor's License studio, which holds the private key and is never published. */
(function () {
  const CFG_KEY = 'loadline-access-v1', SES_KEY = 'loadline-session-v1', ENTRY_KEY = 'loadline-entry-v1';
  const ROLES = {
    planner: { label: 'Planner', ws: 'plan' },
    purchase: { label: 'Purchase', ws: 'buy' },
    wms: { label: 'WMS', ws: 'wms' },
    admin: { label: 'Admin', ws: 'admin' }
  };
  const TABS = {
    plan: [['upload', 'Upload plan'], ['orders', 'Orders'], ['dashboard', 'Factory loading'], ['calendar', 'Factory calendar'], ['shop', 'Shop floor'], ['masters', 'Masters & rules']],
    buy: [['bom', 'BOM by work order'], ['matsum', 'Material summary'], ['pos', 'Purchase orders'], ['suppliers', 'Supplier master'], ['products', 'Product master'], ['groups', 'Material groups'], ['forecast', 'Forecast & safety stock']],
    wms: [['stock', 'Stock by part'], ['grn', 'GRN'], ['iqc', 'IQC'], ['stores', 'Stores'], ['wip', 'WIP'], ['blocked', 'Blocked'], ['scrap', 'Scrap']]
  };
  const WS_LABEL = { plan: 'Planner', buy: 'Purchase', wms: 'WMS', admin: 'Admin' };
  const ACCENTS = {
    cobalt: { name: 'Cobalt', light: '#1d5bd6', dark: '#5b8ef0', soft: '#e7eefc', softDark: '#16264a' },
    teal: { name: 'Teal', light: '#0e7c86', dark: '#3fb8c2', soft: '#ddf2f3', softDark: '#0f2f33' },
    violet: { name: 'Violet', light: '#5b45d6', dark: '#9584f5', soft: '#ebe8fc', softDark: '#251f4d' },
    emerald: { name: 'Emerald', light: '#17804f', dark: '#46c088', soft: '#dff3e8', softDark: '#123222' },
    graphite: { name: 'Graphite', light: '#3a4f6c', dark: '#93a8c6', soft: '#e6ebf2', softDark: '#1e2836' }
  };

  const VENDOR_PUB = { kty: 'EC', crv: 'P-256', x: 'jhoyTW_sGsZWV7uUUv_h6Wx5gbQ3BAbug7YIIbWVHTw', y: 'FkLwCWlFjbmw8dRyNoIxBvbp_ZNdZyFVFEwyoL9IuVk', ext: true };
  // license for the public demo site: 5 Planner, 3 Purchase, 3 WMS, 2 Admin seats until 31 Dec 2027
  const DEMO_LICENSE = 'LL1.eyJsaWQiOiJMTC1ERU1PLTAwMDEiLCJjdXN0b21lciI6IkxvYWRsaW5lIGRlbW8gc2l0ZSIsImVkaXRpb24iOiJEZW1vIiwic2VhdHMiOnsicGxhbm5lciI6NSwicHVyY2hhc2UiOjMsIndtcyI6MywiYWRtaW4iOjJ9LCJpc3N1ZWQiOiIyMDI2LTEwLTI1IiwiZXhwaXJlcyI6IjIwMjctMTItMzEiLCJncmFjZSI6MTQsImRvbWFpbiI6IiJ9.k2q4QtlsYXUm98Rnl_90BhArTod4AC67s-vnI3sFSXSPffHiaU66Xb9Z_oJxIlPG6ZiUFWPGllKYFC1PpM6MNg';

  // cyrb53: small, fast string hash. Enough to keep demo passwords out of plain sight, not cryptographic.
  function hash(s) {
    let h1 = 0xdeadbeef, h2 = 0x41c6ce57;
    for (let i = 0; i < s.length; i++) { const c = s.charCodeAt(i); h1 = Math.imul(h1 ^ c, 2654435761); h2 = Math.imul(h2 ^ c, 1597334677); }
    h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507) ^ Math.imul(h2 ^ (h2 >>> 13), 3266489909);
    h2 = Math.imul(h2 ^ (h2 >>> 16), 2246822507) ^ Math.imul(h1 ^ (h1 >>> 13), 3266489909);
    return (h2 >>> 0).toString(16).padStart(8, '0') + (h1 >>> 0).toString(16).padStart(8, '0');
  }
  const pwHash = (u, pw) => hash('loadline:' + String(u).toLowerCase() + ':' + pw);

  const DEMO = [
    { u: 'planner', name: 'Priya Sharma', role: 'planner', appUser: 'Production planner', pw: 'Planner@123' },
    { u: 'buyer', name: 'Daniel Wong', role: 'purchase', appUser: 'Purchase buyer', pw: 'Buyer@123' },
    { u: 'stores', name: 'Mia Kelly', role: 'wms', appUser: 'Stores in-charge', pw: 'Stores@123' },
    { u: 'admin', name: 'Plant admin', role: 'admin', appUser: 'Plant planning head', pw: 'Admin@123' }
  ];
  const defaultAccess = () => ({
    planner: { plan: TABS.plan.map(t => t[0]) },
    purchase: { buy: TABS.buy.map(t => t[0]) },
    wms: { wms: TABS.wms.map(t => t[0]) }
  });
  const defaults = () => ({
    v: 1,
    accounts: DEMO.map(d => ({ u: d.u, name: d.name, role: d.role, appUser: d.appUser, pw: pwHash(d.u, d.pw), active: true, demo: true, last: null })),
    access: defaultAccess(),
    brand: { company: '', welcome: '', accent: 'cobalt', hours: 8 },
    license: DEMO_LICENSE,
    log: []
  });

  const read = (k, store) => { try { return JSON.parse((store || localStorage).getItem(k)); } catch (e) { return null; } };
  const write = (k, v, store) => { try { (store || localStorage).setItem(k, JSON.stringify(v)); } catch (e) {} };
  const drop = (k, store) => { try { (store || localStorage).removeItem(k); } catch (e) {} };

  let CFG = null;
  function cfg() {
    if (CFG) return CFG;
    const c = read(CFG_KEY);
    if (!c || c.v !== 1 || !Array.isArray(c.accounts)) { CFG = defaults(); save(); return CFG; }
    const d = defaults();
    c.access = c.access || d.access; c.license = c.license || DEMO_LICENSE; c.brand = Object.assign(d.brand, c.brand || {}); c.log = c.log || [];
    ['planner', 'purchase', 'wms'].forEach(r => { c.access[r] = c.access[r] || {}; });
    CFG = c; return CFG;
  }
  function save() { if (CFG) { if (CFG.log.length > 60) CFG.log.length = 60; write(CFG_KEY, CFG); } }
  const find = u => cfg().accounts.find(a => a.u.toLowerCase() === String(u || '').trim().toLowerCase());

  function logAttempt(u, entry, ok, why) { cfg().log.unshift({ at: new Date().toISOString(), u: String(u || '').trim().toLowerCase(), entry, ok, why: why || '' }); save(); }

  /* ---------- licensing ---------- */
  const b64uDec = t => { t = t.replace(/-/g, '+').replace(/_/g, '/'); while (t.length % 4) t += '='; const b = atob(t), a = new Uint8Array(b.length); for (let i = 0; i < b.length; i++) a[i] = b.charCodeAt(i); return a; };
  async function verifyLicense(key) {
    const k = String(key || '').replace(/\s+/g, ''), m = k.match(/^LL1\.([A-Za-z0-9_-]+)\.([A-Za-z0-9_-]+)$/);
    if (!m) return { ok: false, err: 'This is not a Loadline license key.' };
    let p; try { p = JSON.parse(new TextDecoder().decode(b64uDec(m[1]))); } catch (e) { return { ok: false, err: 'The license key is damaged. Copy it again in full.' }; }
    if (!(window.crypto && crypto.subtle)) return { ok: false, err: 'This browser cannot check license keys. Open the site over https.' };
    try {
      const pub = await crypto.subtle.importKey('jwk', VENDOR_PUB, { name: 'ECDSA', namedCurve: 'P-256' }, false, ['verify']);
      const good = await crypto.subtle.verify({ name: 'ECDSA', hash: 'SHA-256' }, pub, b64uDec(m[2]), new TextEncoder().encode(m[1]));
      if (!good) return { ok: false, err: 'The license key was not issued by Loadline, or it was changed.' };
    } catch (e) { return { ok: false, err: 'The license key could not be checked.' }; }
    if (p.domain && !(location.hostname === p.domain || location.hostname.endsWith('.' + p.domain))) return { ok: false, err: `This license is for ${p.domain}, not ${location.hostname || 'this site'}.`, p };
    return { ok: true, p, key: k };
  }
  let LIC = { state: 'checking' };
  const DAY = 864e5, endOfDay = d => new Date(d + 'T23:59:59').getTime();
  function licStatus() {
    if (LIC.state === 'checking' || !LIC.ok) return LIC.ok === false ? { state: 'invalid', err: LIC.err, p: LIC.p } : { state: 'checking' };
    const p = LIC.p, end = endOfDay(p.expires), left = Math.ceil((end - Date.now()) / DAY), graceEnd = end + (+p.grace || 0) * DAY;
    if (Date.now() <= end) return { state: 'ok', p, daysLeft: left };
    if (Date.now() <= graceEnd) return { state: 'grace', p, daysLeft: left, graceLeft: Math.ceil((graceEnd - Date.now()) / DAY) };
    return { state: 'expired', p, daysLeft: left };
  }
  const licUsable = () => ['ok', 'grace'].includes(licStatus().state);
  const seats = role => { const st = licStatus(); return st.p && st.p.seats ? Math.max(0, +st.p.seats[role] || 0) : 0; };
  const activeOf = role => cfg().accounts.filter(a => a.active && a.role === role);
  // named-user licensing: the first N active accounts of a role (in list order) hold its N seats
  const hasSeat = a => { const i = activeOf(a.role).indexOf(a); return i >= 0 && i < seats(a.role); };
  const seatsLeft = role => seats(role) - activeOf(role).length;
  const ready = verifyLicense(cfg().license).then(r => { LIC = r.ok ? { ok: true, p: r.p, state: 'done' } : { ok: false, err: r.err, p: r.p, state: 'done' }; return licStatus(); });
  async function applyLicense(key) {
    const r = await verifyLicense(key); if (!r.ok) return r;
    cfg().license = r.key; save(); LIC = { ok: true, p: r.p, state: 'done' };
    return { ok: true, status: licStatus() };
  }

  function login(u, pw, entry) {
    const a = find(u);
    if (!a || a.pw !== pwHash(a.u, pw)) { logAttempt(u, entry, false, 'Wrong user name or password'); return { ok: false, err: 'That user name and password do not match.' }; }
    if (!a.active) { logAttempt(u, entry, false, 'Account switched off'); return { ok: false, err: 'This account is switched off. Ask your admin to turn it back on.' }; }
    if (entry && a.role !== 'admin' && a.role !== entry) {
      logAttempt(u, entry, false, 'Wrong workspace');
      return { ok: false, err: `${a.name} signs in to ${ROLES[a.role].label}, not ${ROLES[entry].label}.`, hint: a.role };
    }
    const ls = licStatus();
    if (a.role !== 'admin') {
      if (!licUsable()) { logAttempt(u, entry, false, 'No valid license'); return { ok: false, err: ls.state === 'expired' ? 'Your company\'s Loadline license has expired. Ask your admin to renew it.' : 'Loadline has no valid license on this site yet. Ask your admin.' }; }
      if (!seats(a.role)) { logAttempt(u, entry, false, 'Workspace not licensed'); return { ok: false, err: `${ROLES[a.role].label} is not part of your company's license.` }; }
      if (!hasSeat(a)) { logAttempt(u, entry, false, 'No free seat'); return { ok: false, err: `All ${seats(a.role)} ${ROLES[a.role].label} licenses are in use. Ask your admin to free one.` }; }
    } else if (licUsable() && !hasSeat(a)) { logAttempt(u, entry, false, 'No free seat'); return { ok: false, err: `All ${seats('admin')} Admin licenses are in use.` }; }
    // with no valid license an admin can still sign in, to enter a new key
    const hrs = +cfg().brand.hours || 8, now = Date.now();
    const s = { u: a.u, at: now, exp: now + hrs * 3600e3, entry: entry || a.role };
    write(SES_KEY, s); write(ENTRY_KEY, ROLES[entry || a.role].ws, sessionStorage);
    a.last = new Date(now).toISOString(); logAttempt(a.u, entry || a.role, true); save();
    return { ok: true, account: a };
  }
  function session() {
    const s = read(SES_KEY); if (!s || !s.u || !(s.exp > Date.now())) return null;
    const a = find(s.u); if (!a || !a.active) return null;
    return { u: a.u, name: a.name, role: a.role, appUser: a.appUser, entry: s.entry, exp: s.exp };
  }
  function logout() { drop(SES_KEY); drop(ENTRY_KEY, sessionStorage); }
  const isAdmin = () => { const s = session(); return !!s && s.role === 'admin'; };
  function canTab(ws, tab) {
    const s = session(); if (!s) return false;
    if (s.role === 'admin') return true;
    if (ws === 'admin') return false;
    return ((cfg().access[s.role] || {})[ws] || []).includes(tab);
  }
  // the workspace the person picked on the landing page, used once when the app opens
  function takeEntry() { const w = read(ENTRY_KEY, sessionStorage); drop(ENTRY_KEY, sessionStorage); return w; }

  function applyBrand(doc) {
    doc = doc || document;
    const b = cfg().brand, a = ACCENTS[b.accent] || ACCENTS.cobalt;
    let st = doc.getElementById('loadlineBrand');
    if (!st) { st = doc.createElement('style'); st.id = 'loadlineBrand'; (doc.head || doc.documentElement).appendChild(st); }
    if (b.accent === 'cobalt' || !ACCENTS[b.accent]) { st.textContent = ''; return; }
    st.textContent = `:root{--accent:${a.light};--accent-soft:${a.soft};--brand:${a.light}}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--accent:${a.dark};--accent-soft:${a.softDark}}}
:root[data-theme="dark"]{--accent:${a.dark};--accent-soft:${a.softDark}}`;
  }

  window.LoadlineAuth = { ready, licStatus, licUsable, seats, seatsLeft, hasSeat, activeOf, applyLicense, verifyLicense, DEMO_LICENSE, ROLES, TABS, WS_LABEL, ACCENTS, DEMO, cfg, save, find, login, session, logout, isAdmin, canTab, takeEntry, applyBrand, pwHash, defaultAccess,
    reset() { CFG = defaults(); save(); } };

  // <script src="../auth.js" data-gate="../#signin"> sends anyone without a session back to sign in
  const me = document.currentScript;
  if (me && me.dataset.gate !== undefined && !session()) { location.replace(me.dataset.gate || '../#signin'); return; }
  applyBrand();
})();
