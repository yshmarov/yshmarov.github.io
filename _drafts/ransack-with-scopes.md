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

```ruby
- sorting takes filters off (not inside turbo frame)
- sorting should refresh sort form (Without refreshing input field) (not inside turbo frame) (to display reset_filters, filters_count)
<%#= link_to "filters_list", request.url, data: { turbo_frame: :filters_list, controller: "click-on-connect", click_on_connect_open_value: true } %>
if search_params.dig(:q, :risk_event_bookmarks_user_id_eq).present?
  params.dig(:q).merge!("status_eq"=>"")
  search_params.dig(:q).merge!("status_eq"=>"")
  @q.status_eq = ""
  @q.status_eq = nil
end
if search_params.dig(:q, :status_eq).present?
  params.dig(:q).merge!("risk_event_bookmarks_user_id_eq"=>"")
end
PolicyEngine::RiskEvent.joins(:risk_event_bookmarks).where(risk_event_bookmarks: { user_id: User.first })
PolicyEngine::RiskEvent.ransack({risk_event_bookmarks_id_in: 4}).result
PolicyEngine::RiskEvent.ransack({risk_event_bookmarks_user_id_in: 1}).result
PolicyEngine::RiskEvent.ransack({risk_event_bookmarks_user_id_eq: 1}).result
PolicyEngine::RiskEvent.ransack({assignee_name_in: "dev"}).result
PolicyEngine::RiskEvent.ransack({users_id_eq: 1}).result
@q.status_eq = "" if search_params.dig(:q, :risk_event_bookmarks_user_id_eq).present?
@q.risk_event_bookmarks_user_id_eq = "" if search_params.dig(:q, :status_eq).present?
params.dig(:q, :risk_event_bookmarks_user_id_eq).present?
params.dig(:q, :status_eq).present?
```