/* Bygger de fiktive kunde-mockupene inn i <div class="mk-slot" data-mock="frisor|rorlegger|kafe|snekker">.
   Legg til data-wire på sloten for å få wireframe-lag som "bygges" ferdig ved scroll (kreativ variant). */
(function () {
  var D = {
    frisor: {
      label: "Frisør", logo: "Salong Lykke", nav: ["Behandlinger", "Priser"], navBtn: "Bestill",
      kicker: "Frisør", title: "Hår du trives i", text: "Klipp, farge og styling i rolige omgivelser.", cta: "Bestill time",
      cards: [["Klipp", "fra 590 kr"], ["Farge", "fra 990 kr"], ["Styling", "fra 390 kr"]],
      vars: "--bg:#F9EBE6;--fg:#3B1F2B;--ac:#C2476A;--ac2:#F2C9D3",
      art: '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="46" fill="var(--ac2)"/><g fill="none" stroke="var(--fg)" stroke-width="4" stroke-linecap="round"><circle cx="34" cy="74" r="9"/><circle cx="66" cy="74" r="9"/><path d="M40 66 66 24M60 66 34 24"/></g></svg>'
    },
    rorlegger: {
      label: "Rørlegger", logo: "Hansen Rør", nav: ["Tjenester", "Om oss"], navBtn: "Ring oss",
      kicker: "Rørleggerfirma", title: "Rørlegger når det haster", text: "Lekkasje, bad og varmtvann. Vi kommer raskt.", cta: "Be om befaring",
      cards: [["Lekkasje", "Akutthjelp"], ["Bad", "Rehabilitering"], ["Varmtvann", "Bereder"]],
      vars: "--bg:#EAF2FB;--fg:#0B2A4A;--ac:#E8780C;--ac2:#CFE2F7",
      art: '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="46" fill="var(--ac2)"/><path d="M20 58h34a10 10 0 0 0 10-10V28" fill="none" stroke="var(--fg)" stroke-width="10" stroke-linecap="round"/><path d="M64 66c-6 8-10 12-10 17a10 10 0 0 0 20 0c0-5-4-9-10-17z" fill="var(--ac)"/></svg>'
    },
    kafe: {
      label: "Kafé", logo: "Kaffekroken", nav: ["Meny", "Åpningstider"], navBtn: "Finn oss",
      kicker: "Kafé og bakeri", title: "God kaffe, ferske rundstykker", text: "Åpent hver dag. Kom som du er.", cta: "Se menyen",
      cards: [["Kaffe", "fra 38 kr"], ["Frokost", "fra 89 kr"], ["Kake", "fra 55 kr"]],
      vars: "--bg:#F4E8D4;--fg:#3A2415;--ac:#B5562B;--ac2:#E5CFA8",
      art: '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="46" fill="var(--ac2)"/><path d="M26 42h40v20a16 16 0 0 1-16 16h-8a16 16 0 0 1-16-16z" fill="var(--fg)"/><path d="M66 48h5a8 8 0 0 1 0 16h-7" fill="none" stroke="var(--fg)" stroke-width="5"/><path d="M38 34c0-6 6-6 6-12M52 34c0-6 6-6 6-12" fill="none" stroke="var(--ac)" stroke-width="3.5" stroke-linecap="round"/></svg>'
    },
    snekker: {
      label: "Snekker", logo: "Tre &amp; Tak", nav: ["Prosjekter", "Kontakt"], navBtn: "Be om tilbud",
      kicker: "Snekkerfirma", title: "Snekkerarbeid med omtanke", text: "Terrasser, kjøkken og tilbygg.", cta: "Be om tilbud",
      cards: [["Terrasse", "Skreddersydd"], ["Kjøkken", "Fra skisse til ferdig"], ["Tilbygg", "Hele prosessen"]],
      vars: "--bg:#EEF1E6;--fg:#22301F;--ac:#B87B36;--ac2:#D6DEC4",
      art: '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="46" fill="var(--ac2)"/><path d="M18 50 50 22l32 28" fill="none" stroke="var(--fg)" stroke-width="7" stroke-linejoin="round" stroke-linecap="round"/><rect x="28" y="50" width="44" height="30" fill="var(--ac)"/><rect x="45" y="60" width="12" height="20" fill="var(--bg)"/></svg>'
    }
  };

  function html(id) {
    var d = D[id];
    return '<div class="mk mk-' + id + '" style="' + d.vars + '" role="img" aria-label="Eksempel på nettside for ' + d.label.toLowerCase() + '">' +
      '<div class="mk-bar"><i></i><i></i><i></i></div>' +
      '<div class="mk-screen">' +
        '<div class="mk-nav"><b class="mk-logo">' + d.logo + "</b><span>" + d.nav[0] + "</span><span>" + d.nav[1] + '</span><em class="mk-btn">' + d.navBtn + "</em></div>" +
        '<div class="mk-hero"><div class="mk-copy"><small>' + d.kicker + "</small><h4>" + d.title + "</h4><p>" + d.text + '</p><em class="mk-btn">' + d.cta + '</em></div><div class="mk-art">' + d.art + "</div></div>" +
        '<div class="mk-cards">' + d.cards.map(function (c) { return "<div><b>" + c[0] + "</b><span>" + c[1] + "</span></div>"; }).join("") + "</div>" +
      "</div></div>";
  }

  // Merker "bladnoder" med tekst, slik at wireframe-laget kan tegne dem som grå tekstlinjer.
  function wireify(wrap) {
    var els = wrap.querySelectorAll(".mk *");
    Array.prototype.forEach.call(els, function (el) {
      if (el.namespaceURI === "http://www.w3.org/1999/xhtml" && !el.children.length && el.textContent.trim()) {
        el.classList.add("t");
      }
    });
  }

  function bygg() {
    Array.prototype.forEach.call(document.querySelectorAll("[data-mock]"), function (slot) {
      var id = slot.getAttribute("data-mock");
      if (!D[id]) return;
      slot.classList.add("mk-slot");
      if (slot.hasAttribute("data-wire")) {
        slot.innerHTML =
          '<div class="mk-stack"><div class="mk-lw" aria-hidden="true">' + html(id) + '</div>' +
          '<div class="mk-lf">' + html(id) + '</div><span class="mk-scan" aria-hidden="true"></span></div>';
        var w = slot.querySelector(".mk-lw");
        w.querySelector(".mk").classList.add("wire");
        wireify(w);
      } else {
        slot.innerHTML = html(id);
      }
    });
  }

  bygg();
})();
