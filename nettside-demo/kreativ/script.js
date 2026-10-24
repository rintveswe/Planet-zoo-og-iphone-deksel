/* Kreativ variant – vanilla JS. Alt er enkelt å skru av: respekterer prefers-reduced-motion. */
(function () {
  "use strict";

  var root = document.documentElement;
  var RM = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var FINE = window.matchMedia("(hover: hover) and (pointer: fine)").matches;
  var IN_FRAME = root.classList.contains("in-frame");

  function $(s, r) { return (r || document).querySelector(s); }
  function $$(s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); }

  /* ---------- 1. Siden "bygges" når elementer kommer inn i bildet ---------- */
  var builds = $$("[data-build]");
  if (RM || !("IntersectionObserver" in window)) {
    builds.forEach(function (el) { el.classList.add("is-built"); });
  } else {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (en.isIntersecting) {
          var t = en.target;
          t.classList.add("is-built");
          io.unobserve(t);
          setTimeout(function () { t.style.transitionDelay = ""; }, 1600); // så hover-effekter ikke henger etter
        }
      });
    }, { threshold: 0.18, rootMargin: "0px 0px -6% 0px" });
    builds.forEach(function (el, i) {
      // Små forsinkelser gir en "trinnvis bygging" av søsken-elementer.
      var sibs = el.parentElement ? Array.prototype.indexOf.call(el.parentElement.children, el) : 0;
      el.style.transitionDelay = (sibs % 4) * 90 + "ms";
      io.observe(el);
    });
  }

  /* ---------- 2. Scroll: fremdrift, stadier, rutenett og wireframe→design ---------- */
  var bar = $("#progressBar");
  var stageText = $("#stageText");
  var stages = [[0, "01 · Blank side"], [0.18, "02 · Skisse"], [0.42, "03 · Wireframe"], [0.68, "04 · Design"], [0.93, "05 · Ferdig merkevare ✓"]];
  var stacks = $$(".mk-stack");
  var lastStage = -1, ticking = false;

  function setP(st, v) {
    v = Math.max(0, Math.min(1, v));
    if (st._p === v) return;
    st._p = v;
    st.style.setProperty("--p", v.toFixed(3));
    st.classList.toggle("scanning", v > 0.01 && v < 0.99);
  }

  function onScroll() {
    ticking = false;
    var max = root.scrollHeight - window.innerHeight;
    var p = max > 0 ? Math.min(1, Math.max(0, window.scrollY / max)) : 1;
    if (bar) bar.style.transform = "scaleX(" + p.toFixed(4) + ")";
    root.style.setProperty("--grid-o", (1 - p * 0.85).toFixed(3));

    var s = 0;
    for (var i = 0; i < stages.length; i++) if (p >= stages[i][0]) s = i;
    if (s !== lastStage && stageText) { lastStage = s; stageText.textContent = stages[s][1]; }

    var vh = window.innerHeight;
    stacks.forEach(function (st) {
      if (RM) { setP(st, 1); return; }
      var r = st.getBoundingClientRect();
      if (r.bottom < 0) return setP(st, 1);
      if (r.top > vh) return setP(st, 0);
      setP(st, (vh - r.top) / (vh * 0.5 + r.height * 0.5));
    });
  }
  function requestScroll() { if (!ticking) { ticking = true; requestAnimationFrame(onScroll); } }
  window.addEventListener("scroll", requestScroll, { passive: true });
  window.addEventListener("resize", requestScroll);
  onScroll();

  /* ---------- 3. Logo-lekeplass ---------- */
  var input = $("#navn");
  var cards = $$(".logo-card");
  var PAL = [
    ["#F6EFE2", "#1F3D2B", "#C9A24B"],
    ["#FF4B2B", "#FFF6E5", "#12110F"],
    ["#FFC933", "#12110F", "#FF4B2B"],
    ["#12110F", "#F4EFE4", "#2F3BFF"],
    ["#2F3BFF", "#FFFFFF", "#FFC933"],
    ["#12C48B", "#0B2A20", "#FF4B2B"]
  ];
  var shift = 0;

  function applyColors() {
    cards.forEach(function (card, i) {
      var p = PAL[(i + shift) % PAL.length];
      var art = $(".logo-art", card);
      art.style.setProperty("--bg", p[0]);
      art.style.setProperty("--fg", p[1]);
      art.style.setProperty("--ac", p[2]);
    });
  }

  function render(name) {
    var n = name.trim() || "Ditt navn";
    var len = Array.from(n).length;
    var k = Math.max(0.35, Math.min(1, 13 / len));
    $$(".js-name").forEach(function (el) { el.textContent = n; });
    $$(".js-init").forEach(function (el) { el.textContent = Array.from(n)[0].toUpperCase(); });
    $$(".logo-art").forEach(function (el) { el.style.setProperty("--k", k.toFixed(3)); });
  }

  var demoTimer = null;
  function stopDemo() { if (demoTimer) { clearInterval(demoTimer); demoTimer = null; } }

  if (input) {
    applyColors();
    render(input.value);
    input.addEventListener("input", function () { stopDemo(); render(input.value); });
    input.addEventListener("focus", stopDemo);

    $$(".chips .chip").forEach(function (b) {
      b.addEventListener("click", function () { stopDemo(); input.value = b.getAttribute("data-navn"); render(input.value); });
    });
    $("#shuffle").addEventListener("click", function () { stopDemo(); shift = (shift + 1) % PAL.length; applyColors(); });

    // Lekeplassen "viser seg selv" til besøkende tar over (ikke ved redusert bevegelse).
    if (!RM && !IN_FRAME) {
      var names = $$(".chips .chip").map(function (b) { return b.getAttribute("data-navn"); });
      var n = 0;
      demoTimer = setInterval(function () {
        if (document.hidden) return;
        input.value = names[n++ % names.length];
        render(input.value);
      }, 2600);
    }

    // "Velg denne" → fyller ut kontaktskjemaet
    $$("[data-pick]").forEach(function (b) {
      b.addEventListener("click", function () {
        stopDemo();
        var msg = $("#f-melding"), biz = $("#f-bedrift"), need = $("#f-behov");
        msg.value = "Jeg liker logostilen «" + b.getAttribute("data-pick") + "» for «" + input.value.trim() + "».";
        if (!biz.value) biz.value = input.value.trim();
        need.value = "Logo";
        $("#kontakt").scrollIntoView({ behavior: RM ? "auto" : "smooth" });
        setTimeout(function () { $("#f-navn").focus({ preventScroll: true }); }, RM ? 0 : 600);
      });
    });
  }

  // Prisknapper → forhåndsvelger i skjemaet
  $$("[data-velg]").forEach(function (a) {
    a.addEventListener("click", function () {
      var sel = $("#f-behov"), want = a.getAttribute("data-velg");
      Array.prototype.forEach.call(sel.options, function (o) { if (o.text === want) sel.value = o.value || o.text; });
    });
  });

  /* ---------- 4. Egen cursor, hjelpelinjer, parallakse, magnet-knapper ---------- */
  if (FINE && !RM && !IN_FRAME) {
    root.classList.add("has-cursor");
    var dot = document.createElement("div"); dot.className = "cur-dot";
    var ring = document.createElement("div"); ring.className = "cur-ring";
    document.body.appendChild(ring); document.body.appendChild(dot);

    var mx = -100, my = -100, rx = -100, ry = -100, raf = 0;
    var hero = $(".hero");
    var gx = $(".gx"), gy = $(".gy"), gl = $(".gl");
    var shapes = $$(".sh");

    function loop() {
      rx += (mx - rx) * 0.2; ry += (my - ry) * 0.2;
      ring.style.transform = "translate3d(" + rx.toFixed(1) + "px," + ry.toFixed(1) + "px,0)";
      var nx = rx / window.innerWidth - 0.5, ny = ry / window.innerHeight - 0.5;
      shapes.forEach(function (s) {
        var d = parseFloat(s.getAttribute("data-depth")) * 30;
        s.style.transform = "translate3d(" + (nx * d).toFixed(1) + "px," + (ny * d).toFixed(1) + "px,0)";
      });
      raf = (Math.abs(mx - rx) > 0.2 || Math.abs(my - ry) > 0.2) ? requestAnimationFrame(loop) : 0;
    }

    window.addEventListener("pointermove", function (e) {
      mx = e.clientX; my = e.clientY;
      dot.style.transform = "translate3d(" + mx + "px," + my + "px,0)";
      if (!raf) raf = requestAnimationFrame(loop);
      if (hero) {
        var r = hero.getBoundingClientRect();
        if (e.clientY >= r.top && e.clientY <= r.bottom) {
          var x = Math.round(e.clientX - r.left), y = Math.round(e.clientY - r.top);
          gx.style.transform = "translateY(" + y + "px)";
          gy.style.transform = "translateX(" + x + "px)";
          gl.style.transform = "translate(" + (x + 8) + "px," + (y + 8) + "px)";
          gl.textContent = "x " + x + " · y " + y;
        }
      }
    }, { passive: true });

    document.addEventListener("pointerover", function (e) {
      var t = e.target;
      ring.classList.toggle("big", !!(t.closest && t.closest("a, button, summary, label, select, .chip")));
      ring.classList.toggle("text", !!(t.closest && t.closest("input, textarea")));
    });
    document.addEventListener("pointerleave", function () { ring.style.opacity = 0; dot.style.opacity = 0; });
    document.addEventListener("pointerenter", function () { ring.style.opacity = 1; dot.style.opacity = 1; });

    $$("[data-magnet]").forEach(function (el) {
      el.addEventListener("pointermove", function (e) {
        var r = el.getBoundingClientRect();
        el.style.transform = "translate(" + ((e.clientX - r.left - r.width / 2) * 0.18).toFixed(1) + "px," + ((e.clientY - r.top - r.height / 2) * 0.3).toFixed(1) + "px)";
      });
      el.addEventListener("pointerleave", function () { el.style.transform = ""; });
    });
  }

  /* ---------- 5. Mobilmeny ---------- */
  var menuBtn = $("#menuBtn"), nav = $("#nav");
  function closeMenu() { nav.classList.remove("open"); menuBtn.setAttribute("aria-expanded", "false"); }
  menuBtn.addEventListener("click", function () {
    var open = nav.classList.toggle("open");
    menuBtn.setAttribute("aria-expanded", String(open));
  });
  $$("a", nav).forEach(function (a) { a.addEventListener("click", closeMenu); });
  document.addEventListener("keydown", function (e) { if (e.key === "Escape") closeMenu(); });

  /* ---------- 6. Kontaktskjema (foreløpig bare takkemelding) ---------- */
  var form = $("#contactForm"), thanks = $("#thanks");
  form.addEventListener("submit", function (e) {
    e.preventDefault(); // ← FJERN denne linjen når du kobler til Formspree via action="..." på <form>.

    /* Alternativ: send med fetch til Formspree og vis takkemeldingen når det lykkes:
       fetch("https://formspree.io/f/DIN_ID", {
         method: "POST", body: new FormData(form), headers: { Accept: "application/json" }
       }).then(function (res) { if (res.ok) visTakk(); else alert("Noe gikk galt – prøv igjen."); });
    */
    visTakk();
  });
  function visTakk() {
    form.hidden = true;
    thanks.hidden = false;
    thanks.focus();
  }
})();
