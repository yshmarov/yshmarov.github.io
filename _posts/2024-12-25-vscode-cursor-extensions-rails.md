---
layout: post
title: "My VS Code / Cursor plugins in 2025"
categories: cursor ide vscode
tags: ruby rails
---

I always add [rubocop]({% post_url 2021-08-03-install-and-use-rubocop %}) & [erb_lint]({% post_url 2022-08-06-erb-linting %}) to my projects.

These tools run ruby & erb lint on terminal command, and in CI.

But you can run linters **one step earlier**: in the code editor when clicking "Save".

For this you will need to install & configure some IDE extensions.

I read [Railsnotes VS Code Rails setup](https://railsnotes.xyz/blog/vscode-rails-setup), but it feels incomplete.

Here's the setup that works best for me:

```json
// .vscode/extensions.json
{
  "recommendations": [
    "esbenp.prettier-vscode",
    "bradlc.vscode-tailwindcss",
    "heybourn.headwind",
    "eamodio.gitlens",
    "Shopify.ruby-lsp",
    "elia.erb-formatter",
    "github.copilot",
    "github.copilot-chat",
    "marcoroth.stimulus-lsp"
  ]
}
```

About each extension:

- `esbenp.prettier-vscode` - format CSS, JS
- `bradlc.vscode-tailwindcss` - TailwindCSS autocomplete & style check
- `heybourn.headwind` - TailwindCSS style ordering
- `eamodio.gitlens` - see who did the last change to this line of code
- `Shopify.ruby-lsp` - Ruby LSP
- `elia.erb-formatter` - format ERB (requires [a gem](https://github.com/nebulab/erb-formatter)). I tried all the ERB formatters (`manuelpuyol.erb-linter` & `aliariff.vscode-erb-beautify`), however they format only ERB well, not HTML.
- `github.copilot` - (No need in Cursor IDE)
- `github.copilot-chat` - (No need in Cursor IDE)
- `marcoroth.stimulus-lsp` - Stimulus autocomplete

To ensure **lint on Save** works,

```json
// .vscode/settings.json
{
  "tailwindCSS.includeLanguages": {
    "html.erb": "html"
  },
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true,
  "[erb]": {
    // "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.defaultFormatter": "elia.erb-formatter",
    "editor.formatOnSave": true
  },
  "prettier.semi": false,
  "prettier.trailingComma": "none",
  "prettier.singleQuote": true,
  "files.associations": {
    "*.html.erb": "erb"
  },
  "erb-formatter.lineLength": 180
}
```

To make `elia.erb-formatter` work, add the gem:

```ruby
# Gemfile
group :development do
  gem "erb-formatter", "~> 0.7.3", require: false
end
```

Other notable extensions"

- `ckolkman.vscode-postgres` - access your Database
- `tomoki1207.pdf` - preview PDF in IDE
- `redhat.vscode-yaml` - yaml highlighting
- `karunamurti.haml` - HAML syntax highlighting
- `davidanson.vscode-markdownlint` - Markdown lint

That's it!
