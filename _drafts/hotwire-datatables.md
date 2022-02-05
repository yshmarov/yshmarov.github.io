
# https://turbo.hotwired.dev/handbook/drive#pausing-rendering
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  hideBeforeRender(event) {
    if (this.isOpen()) {
      event.preventDefault()
      this.element.addEventListener('hidden.bs.modal', event.detail.resume)
      this.modal.hide()
    }
  }
  isOpen() {
    return this.element.classList.contains("show")
  }
}

if we want to redirect and close the modal, we need to target the whole page by default with a target="_top".
# application.html.erb
<%= turbo_frame_tag "remote_modal", target: "_top" %>
-> change content of the whole page



****


respond_to do |format|
  format.html { render BookComponent.new }
end

#23 Dynamic select forms (without Stimulus or other Javascript) (InventoryComponents#new)

Inspired by [this repo](https://github.com/gorails-screencasts/422-hotwire-datatables)

https://github.com/magma-labs/spreadsheet

```ruby
def update
  if params[:transition]
    update_transition
    redirect_to request.referer
  end
end

def update_transition
  case transition
  when "archive"
    InventoryComponent::ArchivedInteractor.call(component: @component)
  end
end

<%= styled_button_to(nil,
                  item_path(@item),
                  params: { transition: :restore },
                  method: :put) %>
```
****

```ruby
# Gemfile
gem "faker"
gem "pagy", "~> 5.5"
gem "pg_search", "~> 2.3"
```

```ruby
# migration
create_table "employees", force: :cascade do |t|
  t.string "name"
  t.string "position"
  t.string "office"
  t.integer "age"
  t.date "start_date"
  t.datetime "created_at", precision: 6, null: false
  t.datetime "updated_at", precision: 6, null: false
end
```

```ruby
# seeds.rb
10_000.times do |i|
  Employee.create(
    name: Faker::Name.name,
    position: ['Accountant', 'Leader', 'Author'].sample,
    office: ["London", "Singapore"].sample,
    age: rand(20..100),
    start_date: rand(1..1000).days.ago.to_date,
  )
end
```
