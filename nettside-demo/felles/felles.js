/* ==========================================================================
   FELLES KONFIG – endre ting HER, så oppdateres begge variantene.
   ========================================================================== */
window.SITE = {
  // Firmanavn (plassholder). Fylles inn overalt der HTML har data-brand.
  navn: "Startsiden",

  // E-post som vises i kontaktseksjonen (plassholder).
  epost: "hei@startsiden.example",

  // ⚠️ ALLE PRISER HER ER PLASSHOLDERE – bytt til dine egne før lansering.
  // Verdiene vises overalt der HTML har data-pris="nøkkel".
  priser: {
    hjemmeside: "2 000", // fra-pris, kr
    logo: "1 000",       // fra-pris, kr
    pakke: "2 400",      // rabattert pris for hjemmeside + logo, kr
    pakkeSpar: "600",    // hva kunden sparer på pakken, kr
    abonnement: "299"    // valgfritt månedsabonnement, kr/mnd
  }
};

/* ==========================================================================
   Under her trenger du normalt ikke endre noe.
   ========================================================================== */
(function () {
  var S = window.SITE;
  var root = document.documentElement;

  // Skjul demo-bryteren når siden vises som forhåndsvisning i velgersiden.
  try {
    if (window.top !== window.self) root.classList.add("in-frame");
  } catch (e) {
    root.classList.add("in-frame");
  }

  function qsa(sel) {
    return Array.prototype.slice.call(document.querySelectorAll(sel));
  }

  function fyllInn() {
    document.title = document.title.replace(/Startsiden/g, S.navn);
    qsa("[data-brand]").forEach(function (el) { el.textContent = S.navn; });
    qsa("[data-pris]").forEach(function (el) {
      var v = S.priser[el.getAttribute("data-pris")];
      if (v) el.textContent = v;
    });
    qsa("[data-epost]").forEach(function (el) {
      el.textContent = S.epost;
      if (el.tagName === "A") el.href = "mailto:" + S.epost;
    });
    qsa("[data-year]").forEach(function (el) { el.textContent = new Date().getFullYear(); });
  }

  // Flytende demo-bryter (kun for sammenligning av variantene – fjernes i produksjon).
  function bryter() {
    var v = root.getAttribute("data-variant");
    if (!v) return;
    var andre = v === "kreativ" ? { slug: "praktisk", navn: "praktisk" } : { slug: "kreativ", navn: "kreativ" };

    var css = document.createElement("style");
    css.textContent =
      ".vx-switch{position:fixed;left:12px;bottom:12px;z-index:2147483000;display:flex;gap:4px;padding:4px;border-radius:999px;" +
      "background:rgba(20,20,24,.9);-webkit-backdrop-filter:blur(8px);backdrop-filter:blur(8px);box-shadow:0 6px 24px rgba(0,0,0,.28);" +
      "font:600 12.5px/1 system-ui,-apple-system,'Segoe UI',sans-serif}" +
      ".vx-switch a{color:#fff;text-decoration:none;padding:9px 12px;border-radius:999px;white-space:nowrap;cursor:pointer}" +
      ".vx-switch a:hover,.vx-switch a:focus-visible{background:rgba(255,255,255,.2);outline:none}" +
      ".vx-switch a.vx-main{background:#fff;color:#111}" +
      ".vx-switch a.vx-main:hover,.vx-switch a.vx-main:focus-visible{background:#e6e6e6}" +
      "@media(max-width:480px){.vx-switch{left:8px;bottom:8px}.vx-switch a{padding:8px 10px;font-size:12px}}" +
      ".in-frame .vx-switch{display:none}";
    document.head.appendChild(css);

    var nav = document.createElement("nav");
    nav.className = "vx-switch";
    nav.setAttribute("aria-label", "Demo-bryter");
    nav.innerHTML =
      '<a class="vx-main" href="../' + andre.slug + '/index.html">Bytt til ' + andre.navn + "</a>" +
      '<a href="../index.html">Tilbake til velger</a>';
    document.body.appendChild(nav);
  }

  fyllInn();
  bryter();
})();
