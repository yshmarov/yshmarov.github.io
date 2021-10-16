erb linting

https://github.com/Shopify/erb-lint

Gemfile
```
group :development, :test do
  gem "erb_lint", require: false # avoid better html checking all erb files
end
```

console
```
bundle add erb_lint
echo > .erb-lint.yml
```

[ERB Lint](https://github.com/Shopify/erb-lint).

To run ERB Lint locally, use any one of the following

bundle exec erblint
# this will lint all relevant files
bundle exec erblint --lint-all
# this will automatically fix issues where possible
bundle exec erblint -a

# GOOD
bundle exec erblint -a --lint-all


.erb-lint.yml
```
---
EnableDefaultLinters: false
linters:
  Rubocop:
    enabled: true
    exclude:
      - "**/vendor/**/*"
      - "**/vendor/**/.*"
      - "bin/**"
      - "db/**/*"
      - "spec/**/*"
      - "config/**/*"
      - "node_modules/**/*"
    rubocop_config:
      inherit_from:
        - .rubocop.yml
      Layout/InitialIndentation:
        Enabled: false
      Layout/TrailingEmptyLines:
        Enabled: false
      Layout/TrailingWhitespace:
        Enabled: false
      Naming/FileName:
        Enabled: false
      Style/FrozenStringLiteralComment:
        Enabled: false
      Layout/LineLength:
        Enabled: false
      Lint/UselessAssignment:
        Enabled: false
      Layout/FirstHashElementIndentation:
        Enabled: false
```

https://github.com/Shopify/better-html