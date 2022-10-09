TURBO PERMANENT ?!

turbo frames search

```ruby
# config/seeds.rb
10_000.times do |i|
  Employee.create(
    name: Faker::Name.name,
    position: ['Accountant', 'Accountant', 'CEO'].sample,
    office: ["London", "Singapore", "Tokyo", "New York", "Edinburgh"].sample,
    age: rand(20..100),
    start_date: rand(1..1000).days.ago.to_date,
  )
end
```

https://github.com/faker-ruby/faker
https://github.com/component/debounce

```ruby
bundle add faker
bundle add pagy
bundle add pg_search
rails g scaffold employee name position office age:integer start_date:datetime
yarn add debounce
rails g stimulus form
rails db:migrate
rails db:seed
```
```ruby
# app/views/posts/index.html.erb
<%= form_with url: employees_path, method: :get, data: { turbo_frame: "posts", turbo_action: "advance", controller: "form", action: "input->form#submit" } do |form| %>

  Per page: <%= form.select :count, options_for_select([10, 25, 50, 100], selected: params[:count]), {}, { onchange: "this.form.requestSubmit()" } %>

  Search <%= form.search_field :query, value: params[:query], oninput: "this.form.requestSubmit()" %>

<% end %>

<%= turbo_frame_tag "posts" do %>
  <%= sort_link_to "Name", :name, data: { turbo_action: "advance" } %>
  <%= sort_link_to "Start Date", :start_date, data: { turbo_action: "advance" } %>
  <%= render @posts %>
<% end %>
<%== pagy_nav(@pagy, link_extra: 'data-turbo-action="advance"') %>
```

debounce

```js
// app/javascript/form_controller.rb
import debounce from "debounce";

initialize() {
  this.submit = debounce(this.submit.bind(this), 300);
}

submit() {
  this.element.requestSubmit();
}

// remotesubmit() {
//   clearTimeout(this.timeout)
//   this.timeout = setTimeout(() => {
//     this.submitbtnTarget.click()
//   }, 500)
// }

```

```ruby
# app/helpers/posts_helper.rb
module ApplicationHelper
  include Pagy::Frontend

  def sort_link_to(name, column, **options)
    if params[:sort] == column.to_s
      direction = params[:direction] == "asc" ? "desc" : "asc"
    else
      direction = "asc"
    end

    link_to name, request.params.merge(sort: column, direction: direction), **options
  end
end

```

```ruby
# app/models/employee.rb
class Employee < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :search, against: [:name, :position, :office, :age, :start_date], using: { tsearch: { prefix: true } }
end
```

```ruby
# app/controllers/posts_controller.rb
class EmployeesController < ApplicationController
  def index
    @employees = Employee.all
    @employees = @employees.search(params[:query]) if params[:query].present?
    @pagy, @employees = pagy @employees.reorder(sort_column => sort_direction), items: params.fetch(:count, 10)
  end

  def sort_column
    %w{ name position office age start_date }.include?(params[:sort]) ? params[:sort] : "name"
  end

  def sort_direction
    %w{ asc desc }.include?(params[:direction]) ? params[:direction] : "asc"
  end
end

```