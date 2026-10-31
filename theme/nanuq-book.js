// The Nanuq book's script: Nim/Python tabs and the light/dark switch. `nimble genbook`
// appends it to nimibook's assets/js/book.js, so it runs on every page.
(function () {
  function choose(lang) {
    document.querySelectorAll(".nq-tabs").forEach(function (t) {
      t.querySelectorAll(".nq-tab").forEach(function (b) {
        b.setAttribute("aria-selected", b.dataset.lang === lang ? "true" : "false"); });
      t.querySelectorAll(".nq-panel").forEach(function (p) { p.hidden = p.dataset.lang !== lang; });
    });
    try { localStorage.setItem("nanuq-book-lang", lang); } catch (e) {}
  }
  document.addEventListener("click", function (e) {
    var b = e.target.closest && e.target.closest(".nq-tab");
    if (b) choose(b.dataset.lang);
  });
  // nimibook's theme menu becomes a one-click light/dark switch. Capturing the click
  // here keeps book.js from opening the menu; the menu's hidden Light/Dark buttons
  // still apply and remember the theme.
  function isDark() {
    var c = document.documentElement.classList;
    return c.contains("navy") || c.contains("coal") || c.contains("ayu");
  }
  function updateSwitch() {
    var b = document.getElementById("theme-toggle");
    if (!b) return;
    var dark = isDark(), label = dark ? "Switch to light theme" : "Switch to dark theme";
    b.title = label; b.setAttribute("aria-label", label);
    b.removeAttribute("aria-haspopup"); b.removeAttribute("aria-expanded");
    var i = b.querySelector("i");
    if (i) i.className = "fa " + (dark ? "fa-sun-o" : "fa-moon-o");
  }
  document.addEventListener("click", function (e) {
    var b = e.target.closest && e.target.closest("#theme-toggle");
    if (!b) return;
    e.preventDefault(); e.stopPropagation();
    var next = document.getElementById(isDark() ? "light" : "navy");
    if (next) next.click();
    updateSwitch();
  }, true);
  document.addEventListener("DOMContentLoaded", function () {
    updateSwitch();
    var lang = null;
    try { lang = localStorage.getItem("nanuq-book-lang"); } catch (e) {}
    if (lang) choose(lang);
    // Nim is highlighted when the page is built; highlight.js only does the Python cells
    var py = document.querySelectorAll("code.language-python");
    if (py.length) {
      var s = document.createElement("script");
      s.src = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js";
      s.onload = function () { py.forEach(function (c) {
        try { window.hljs.highlightElement(c); } catch (e) {} }); };
      document.head.appendChild(s);
    }
  });
})();
