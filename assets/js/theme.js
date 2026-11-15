// Light/dark theme toggle. The pre-paint part lives inline in custom-head.html;
// this file wires up the header button and keeps embeds (Giscus) in step.
//
// Three states, cycled by the button: "system" (no data-theme, CSS follows
// prefers-color-scheme), "light" and "dark" (stored in localStorage).
(function () {
  var root = document.documentElement;
  var ORDER = ["system", "light", "dark"];
  var LABELS = { system: "Auto", light: "Light", dark: "Dark" };

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

  function syncGiscus(choice) {
    var frame = document.querySelector("iframe.giscus-frame");
    if (!frame || !frame.contentWindow) return;
    frame.contentWindow.postMessage(
      { giscus: { setConfig: { theme: giscusTheme(choice) } } },
      "https://giscus.app"
    );
  }

  function apply(choice) {
    if (choice === "system") root.removeAttribute("data-theme");
    else root.setAttribute("data-theme", choice);
    syncGiscus(choice);
  }

  function render(button, choice) {
    var next = ORDER[(ORDER.indexOf(choice) + 1) % ORDER.length];
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
      choice = ORDER[(ORDER.indexOf(choice) + 1) % ORDER.length];
      store(choice);
      apply(choice);
      render(button, choice);
    });
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
