/* Praktisk variant – vanilla JS */
(function () {
  "use strict";

  function $(s, r) { return (r || document).querySelector(s); }
  function $$(s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); }
  var RM = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* Rolige fade-in-animasjoner ved scroll */
  var items = $$(".rv");
  if (RM || !("IntersectionObserver" in window)) {
    items.forEach(function (el) { el.classList.add("in"); });
  } else {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (en.isIntersecting) {
          var t = en.target;
          t.classList.add("in");
          io.unobserve(t);
          setTimeout(function () { t.style.transitionDelay = "0ms"; }, 1200); // hover-effekter skal ikke henge etter
        }
      });
    }, { threshold: 0.12, rootMargin: "0px 0px -5% 0px" });
    items.forEach(function (el) { io.observe(el); });
  }

  /* Header får en tynn linje når man har scrollet */
  var top = $(".top");
  function onScroll() { top.classList.toggle("scrolled", window.scrollY > 8); }
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  /* Mobilmeny */
  var btn = $("#menuBtn"), nav = $("#nav");
  function close() { nav.classList.remove("open"); btn.setAttribute("aria-expanded", "false"); }
  btn.addEventListener("click", function () {
    btn.setAttribute("aria-expanded", String(nav.classList.toggle("open")));
  });
  $$("a", nav).forEach(function (a) { a.addEventListener("click", close); });
  document.addEventListener("keydown", function (e) { if (e.key === "Escape") close(); });

  /* Prisknapper forhåndsvelger i skjemaet */
  $$("[data-velg]").forEach(function (a) {
    a.addEventListener("click", function () {
      var sel = $("#f-behov"), want = a.getAttribute("data-velg");
      Array.prototype.forEach.call(sel.options, function (o) { if (o.text === want) sel.value = o.value || o.text; });
    });
  });

  /* Kontaktskjema (foreløpig bare takkemelding) */
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
