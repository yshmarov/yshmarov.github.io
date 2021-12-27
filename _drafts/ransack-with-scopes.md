ransack scopes

app/models/inbox.rb
```ruby
  scope :responsibility_in, (proc { |*args|
    if args.include?("internal") && args.include?("external")
      all
    elsif args.include?("external")
      external_api
    elsif args.include?("internal")
      not_external_api
    end
  })

  def self.ransackable_scopes(_auth_object = nil)
    %i[responsibility_in]
  end
```

app/inboxes/index.html.erb
```ruby
<%= form.select :responsibility_in,
              [["Internal", :internal], ["External", :external]],
              {},
              filter_style: true,
              search: true,
              select_all: true,
              multiple: true,
              data: { action: "change->form#delayedSubmit" },
              placeholder: "Responsibility" %>
```
