
console

```
rails g migration add_language_to_users language:string
```

migration
```
  add_column :users, :language, :string, default: 'en'
```

/app/controllers/application_controller.rb

```
  include SetLocale
```

/app/controllers/concerns/set_locale.rb

```
module SetLocale
  extend ActiveSupport::Concern

  included do
    before_action :set_locale

    private

    def set_locale
      if params["locale"].present?
        language = params["locale"].to_sym
        session["locale"] = language
        if user_signed_in?
          current_user.update(language: language)
          redirect_to user_path(current_user)
        else
          # redirect to previous page OR root
          redirect_to(request.referrer || root_path)
        end
      elsif session["locale"].present?
        language = session["locale"]
      else
        language = I18n.default_locale
      end

      if user_signed_in? && current_user.language.present?
        language = current_user.language
      end

      I18n.locale = if I18n.available_locales.map(&:to_s).include?(language)
        language
      else
        I18n.default_locale
      end
    end
  end
end
```

in any view: allow current_user to select a locale

```
      <div class="btn-group">
        <div class="dropdown">
          <button class="btn btn-secondary dropdown-toggle" type="button" id="userLanguageDropdown" data-bs-toggle="dropdown" aria-expanded="false">
            <%= model_class.human_attribute_name(:language).capitalize %>:
            <%= @user.language %>
          </button>
          <div class="dropdown-menu" aria-labelledby="userLanguageDropdown">
            <% I18n.available_locales.excluding(I18n.locale).each do |language| %>
                <%= link_to language, root_path(locale: language), class: "dropdown-item" %>
            <% end %>
          </div>
        </div>
      </div>
```
