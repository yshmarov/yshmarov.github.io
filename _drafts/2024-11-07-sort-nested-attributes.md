abc

```shell
bin/importmap pin sortablejs
```

```ruby
# app/models/project.rb
  has_many :tasks, dependent: :destroy, inverse_of: :shop
  accepts_nested_attributes_for :tasks, reject_if: :all_blank, allow_destroy: true
```
```ruby
# app/models/task.rb
  belongs_to :shop
  default_scope { order("position ASC") }

```


```js
// app/assets/javascripts/controllers/sortable_controller.js
import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'

export default class extends Controller {
  connect() {
    this.sortable = Sortable.create(this.element, {
      handle: '.sortablejs-handle',
      animation: 150,
      forceFallback: true,
    })
  }
}
```

```css
/* app/assets/stylesheets/application.scss */
.sortablejs-handle {
  cursor: grab;
}

.sortablejs-handle:active {
  cursor: grabbing;
}
```


```ruby
# app/controllers/projects_controller.rb
  def update
    @project.update(project_params)
  end

  private

  def project_params
    project_attributes = params.require(:project).permit(
      :name,
        tasks_attributes: [:id,
          :title,
          :position,
          :_destroy]
    )
    tasks_attributes = project_attributes["tasks_attributes"]
    tasks_attributes.values.each_with_index do |value, index|
      value.merge!(position: index)
    end
    project_attributes
  end
```

```ruby
<div id='export-settings' data-controller="sortable">
  <%= form.fields_for :export_settings, form.object.export_settings.order(position: :desc) do |export_setting_form| %>
    <%= render 'export_setting_fields', form: export_setting_form %>
  <% end %>
</div>
<%= link_to_add_nested(form, :export_settings, '#export-settings', tag_attributes: {data: { action: 'click->form#formDirty' }}) do %>
  Add task
<% end %>
```


_fields

<div class="task-field">
  <%= content_tag :span, "drag me", class: "sortablejs-handle" %>
  <%= form.text_field :title %>
  <%= link_to_remove_nested(form, fields_wrapper_selector: '.task-field') do %>
    Remove task
  <% end %>
</div>
