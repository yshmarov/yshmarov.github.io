Add simplecov #1273

https://github.com/Bearer/api-management-app/pull/1273/

Add simplecov and let ci/cd fail if our test coverage drops < 89.5% (we currently are at 89.59%)

coverage report is generated each time you run tests.
Once tests are completed you will see the simplecov notification about test coverage
coverage reports are stored in coverage folder, you can always run open coverage/index.html from the console to see more detailed coverage report (e.g. check which lines were not hit)

Gemfile
```ruby
gem "simplecov", require: false
```

.gitignore
```sh
.vscode/pinned-files.json
coverage
```

* add on top of the file

spec/spec_helper.rb
```ruby
require 'simplecov'
SimpleCov.minimum_coverage 89.5
SimpleCov.start
```

