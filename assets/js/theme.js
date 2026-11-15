// Light/dark theme toggle. The pre-paint part lives inline in custom-head.html;
// this file wires up the header button and keeps embeds (Giscus) in step.
//
// Three states, cycled by the button: "system" (no data-theme, CSS follows
// prefers-color-scheme), "light" and "dark" (stored in localStorage).
// The aria-label names the theme the next click selects.
(function () {
  var root = document.documentElement;
  var LABELS = { system: "Auto", light: "Light", dark: "Dark" };
  var darkQuery = window.matchMedia ? window.matchMedia("(prefers-color-scheme: dark)") : null;

  // The first click always changes what you see: from Auto it goes to the
  // opposite of the OS theme, then to the OS theme pinned, then back to Auto.
  function order() {
    var osDark = darkQuery && darkQuery.matches;
    return osDark ? ["system", "light", "dark"] : ["system", "dark", "light"];
  }

  function nextOf(choice) {
    var o = order();
    return o[(o.indexOf(choice) + 1) % o.length];
  }

  function stored() {
    try {
      var t = localStorage.getItem("theme");
      return t === "light" || t === "dark" ? t : "system";
    } catch (e) {
      return "system";
    }
  }

  function store(choice) {
    try {
      if (choice === "system") localStorage.removeItem("theme");
      else localStorage.setItem("theme", choice);
    } catch (e) {}
  }

  // Giscus theme names: an explicit choice maps 1:1, "system" lets Giscus
  // follow the OS the same way our CSS does.
  function giscusTheme(choice) {
    return choice === "system" ? "preferred_color_scheme" : choice;
  }

  // Giscus documents a postMessage setConfig for this, but in testing
  // (November 2026) the widget ignored it. Reloading the iframe with the new
  // theme parameter works, and only happens when the theme actually changes.
  function syncGiscus(choice) {
    var frame = document.querySelector("iframe.giscus-frame");
    if (!frame || !frame.src) return;
    try {
      var url = new URL(frame.src);
      var theme = giscusTheme(choice);
      if (url.searchParams.get("theme") === theme) return;
      url.searchParams.set("theme", theme);
      frame.src = url.toString();
    } catch (e) {}
  }

  function apply(choice) {
    if (choice === "system") root.removeAttribute("data-theme");
    else root.setAttribute("data-theme", choice);
    syncGiscus(choice);
  }

  function render(button, choice) {
    var next = nextOf(choice);
    button.textContent = "Theme: " + LABELS[choice];
    button.setAttribute(
      "aria-label",
      "Color theme: " + LABELS[choice] + (choice === "system" ? " (follows your system)" : "") +
        ". Switch to " + LABELS[next] + "."
    );
  }

  window.siteTheme = { current: stored, giscusTheme: giscusTheme };

  function init() {
    var button = document.getElementById("theme-toggle");
    if (!button) return;
    var choice = stored();
    render(button, choice);
    button.hidden = false;
    button.addEventListener("click", function () {
      choice = nextOf(choice);
      store(choice);
      apply(choice);
      render(button, choice);
    });
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
