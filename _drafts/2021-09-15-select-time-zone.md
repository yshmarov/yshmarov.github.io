
console

```
rails g migration add_time_zone_to_users time_zone:string
```

migration
```
  add_column :users, :time_zone, :string, default: 'UTC'
```

/app/controllers/application_controller.rb

```
  include SetTimeZone
```

/app/controllers/concerns/set_time_zone.rb

```
module SetTimeZone
  extend ActiveSupport::Concern

  included do
    around_action :set_time_zone, if: :current_user

    private

    def set_time_zone
      time_zone = params["time_zone"]
      if params["time_zone"].present?
        current_user.update(time_zone: time_zone)
        redirect_to user_path(current_user)
      end
      if ActiveSupport::TimeZone.all.map { |tz| tz.tzinfo.name }.include?(current_user.time_zone)
        Time.use_zone(current_user.time_zone) { yield }
      else
        yield
      end
    end
  end
end
```

in any view: allow current_user to select a time_zone

```
      <div class="btn-group">
        <div class="dropdown">
          <button class="btn btn-secondary dropdown-toggle" type="button" id="userTimeDropdown" data-bs-toggle="dropdown" aria-expanded="false">
            <%= model_class.human_attribute_name(:time_zone).capitalize %>:
            <%= Time.zone %>
          </button>
          <div class="dropdown-menu dropdown-scrollable" aria-labelledby="userTimeDropdown">
            <% ActiveSupport::TimeZone::MAPPING.each do |key, value| %>
                <%= link_to key, root_path(time_zone: value), class: "dropdown-item" %>
            <% end %>
          </div>
        </div>
      </div>
```
