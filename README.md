# yshmarov.github.io
trying out to creae a jekyll blog
```
gem install bundler jekyll
jekyll new my-awesome-site
jekyll new corsego-blog
cd corsego-blog
bundle exec jekyll serve --port=8080
bundle exec jekyll serve --trace --port=8080 --drafts --unpublished --future
bundle exec jekyll serve --port=8080 --unpublished
bundle exec jekyll serve --trace --port=8080 --future
jekyll serve --port=8080
```

{:target="blank"}

To import the XML downloaded from blogger into the main folder, just run

```
ruby -r rubygems -e 'require "jekyll-import";
    JekyllImport::Importers::Blogger.run({
      "source"                => "blog-11-10-2020.xml",
      "no-blogger-info"       => false,
      "replace-internal-link" => false,
    })'
```

To check for errors
```
jekyll build --trace
```

git remote set-url origin git@github.com:yshmarov/yshmarov.github.io.git
git remote set-url origin https://github.com/yshmarov/yshmarov.github.io
