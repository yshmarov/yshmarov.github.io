// WebMCP: expose read-only tools to AI agents running in the visitor's browser.
// https://webmachinelearning.github.io/webmcp/
//
// Progressive enhancement only. Browsers without WebMCP skip this file's work
// entirely. As of November 2026 Chrome ships it as an origin trial: the API is
// document.modelContext (earlier previews used navigator.modelContext), and it
// is only live on this origin when _config.yml carries a trial token
// (webmcp_origin_trial_token) or the visitor enables chrome://flags/#enable-webmcp-testing.
//
// Every tool reads public, static files this site already publishes
// (search.json, the .md twins), so none of them change any state.
(function () {
  var mc = document.modelContext || navigator.modelContext;
  if (!mc || typeof mc.registerTool !== "function") return;

  var origin = window.location.origin;
  var indexPromise = null;

  function loadIndex() {
    if (!indexPromise) {
      indexPromise = fetch("/search.json", { credentials: "omit" }).then(function (r) {
        if (!r.ok) throw new Error("search.json returned " + r.status);
        return r.json();
      });
      indexPromise.catch(function () { indexPromise = null; });
    }
    return indexPromise;
  }

  function absolute(path) {
    return new URL(path, origin).href;
  }

  // Resolve a page or post URL (absolute or root-relative) to its Markdown twin
  // on this origin. Returns null for anything off-site.
  function markdownUrlFor(input) {
    var url;
    try {
      url = new URL(String(input || "/"), origin);
    } catch (e) {
      return null;
    }
    if (url.origin !== origin) return null;
    var path = url.pathname;
    if (/\.md$/.test(path)) return path;
    if (path === "/" || path === "/index.html") return "/index.md";
    path = path.replace(/\.html$/, "").replace(/\/$/, "");
    return path + ".md";
  }

  var tools = [
    {
      name: "search_posts",
      description:
        "Search Yaroslav Shmarov's blog posts by keyword. Matches post titles, tags and summaries " +
        "(AI, payments and Stripe, native mobile, multi-tenant SaaS, deployment, Ruby on Rails). Returns newest first, " +
        "each with its canonical URL and a markdown_url holding the full post as Markdown.",
      inputSchema: {
        type: "object",
        properties: {
          query: { type: "string", description: "Words to look for, e.g. \"stripe checkout\" or \"hotwire native\"." },
          limit: { type: "integer", minimum: 1, maximum: 50, description: "Maximum results (default 10)." }
        },
        required: ["query"]
      },
      annotations: { readOnlyHint: true },
      execute: function (input) {
        var words = String((input && input.query) || "").toLowerCase().split(/\s+/).filter(Boolean);
        var limit = Math.min(Math.max(parseInt(input && input.limit, 10) || 10, 1), 50);
        return loadIndex().then(function (posts) {
          var hits = posts.filter(function (p) {
            var hay = (p.title + " " + (p.tags || []).join(" ") + " " + (p.excerpt || "")).toLowerCase();
            return words.every(function (w) { return hay.indexOf(w) !== -1; });
          });
          return {
            total_matches: hits.length,
            results: hits.slice(0, limit).map(function (p) {
              return {
                title: p.title,
                url: absolute(p.url),
                markdown_url: absolute(p.markdown_url),
                date: p.date,
                tags: p.tags,
                summary: p.excerpt
              };
            })
          };
        });
      }
    },
    {
      name: "get_page_markdown",
      description:
        "Get the Markdown source of any page or post on this site: the text the author wrote, with code " +
        "blocks intact. Pass a URL or path such as \"/wicked-pdf-to-sghtmltopdf\", \"/talks/\" or \"/\". " +
        "Defaults to the page currently open.",
      inputSchema: {
        type: "object",
        properties: {
          url: { type: "string", description: "Page URL or root-relative path on this site. Omit for the current page." }
        }
      },
      annotations: { readOnlyHint: true },
      execute: function (input) {
        var target = (input && input.url) || window.location.pathname;
        var md = markdownUrlFor(target);
        if (!md) return { error: "Only pages on " + origin + " are available." };
        return fetch(md, { credentials: "omit" }).then(function (r) {
          if (!r.ok) {
            return { error: "No Markdown version at " + absolute(md) + " (HTTP " + r.status + "). Try search_posts to find the right URL." };
          }
          return r.text().then(function (text) {
            return { markdown_url: absolute(md), markdown: text };
          });
        });
      }
    },
    {
      name: "get_author_profile",
      description:
        "Who Yaroslav Shmarov is: what he works on, what he has shipped, open source, talks, teaching and " +
        "how to contact him. Returns the homepage as Markdown.",
      inputSchema: { type: "object", properties: {} },
      annotations: { readOnlyHint: true },
      execute: function () {
        return fetch("/index.md", { credentials: "omit" }).then(function (r) {
          return r.ok ? r.text().then(function (text) { return { markdown: text }; })
                      : { error: "Profile unavailable (HTTP " + r.status + ")." };
        });
      }
    }
  ];

  tools.forEach(function (tool) {
    try {
      var result = mc.registerTool(tool);
      if (result && typeof result.catch === "function") result.catch(function () {});
    } catch (e) {
      // A spec change or a duplicate registration must never break the page.
    }
  });
})();
