AskVote.io
https://www.upvoty.com/
pollanywhere
pigeonholelive
A lot like substack?

imboxify
imboxly
imboxes $150

audience engagement and feedback tool

Inbox
- visibility
    public
    unlisted (default)
    password-protected
- status
    upcoming starts_at?
    active
    finished (locked) ends_at?
- message visibility
    admin only
    public (default)
- message creation
    admin only
    signed in users
    anonymous (default)
- message commenting [on/off]
- message voting [on/off]


SUPPORT FEATURES:
- QR codes to scan?
- Live dashboard?

PRO:
- message moderation before public visibility
- messages kanban
- send invite emails?
- embed on website? branding?

Templates (not finished):
- collect user feedback about your tool
- (wall of love) collect reviews
- vote for initiatives
- questions
- contact form
- idea board `status:active visibility:unlisted message_visibility:public message_creation:signed_in message_commenting:on message_voting:on`
- event `status:active_between visibility:password_protected message_visibility:public message_creation:anonymous message_commenting:on message_voting:on`

<h1>Create a public inbox</h1>

Inbox types:
  1. Minimalistic blog
    Public inbox
    You post public messages
    Vote/like feature
  2. Collect leads / contact form
    Public inbox
    Users post private messages
  3. Voting
    3.1. Public voting
      Public inbox
      Users post public messages
      Vote/like feature
      Everybody sees results
    3.2. Private voting
      Password-protected inbox
      Users post public messages
      Vote/like feature
      Everybody/voters see results
    3.3. Secret voting
      Password-protected inbox
      Users post public messages
      Vote/like feature
      You see results
  4. Secret notebook
    Private inbox
    You post private messages
  5. Custom - whatever you can imagine

Voting with/without login can be enabled

askdemos = dmsis = pikabu = reddit = world@hey.com

public-discoverable inbox with public-visible-messages owner-create-messages = blog = insta2site
private-discoverable inbox with public-visible-messages public-create-messages = pigeonholelive/QnA/Voting
public-discoverable inbox with owner-visible-messages public-create-messages = collect leads
private-discoverable inbox with owner-visible-messages owner-create-messages = secret notebook

who can delete a message? creator or inbox owner.

Inbox
- slug URL?
- description
-- theme (pro); logo/bg image
- invite-only (with user account)
- invite-only (HTTP auth) (password field, or autogenerated (encrypted attributes?) )
- subdomain/own domain (pro)
- embeddable
- starts_at, ends_at (upcoming/in progress/finished)
- discoverable on askdemos.com website - boolean

Message settings:
  -- messages can be added by owner or other users?
  -- visible to inbox owner (and message creator?) or everybody (make_messages_public:boolean)
  -- messages can be voted up/down on (votable:boolean feature flag)
  -- messages can be filtered by created_at/votes (top rated / recent-oldest)
  -- messages can be searched for by body
  -- messages can be moderated: marked as [spam, new, seen, accepted, resolved, rejected] (votable OR status field)

Price
- Free
- Pro $12/year for all features
- Enterprise + custom domain
**$99/year all featuers**

V2 
- Messages can be answered
- markdown support
V3 Audio messages
V4
- email inbox{id}@askdemos.com to add a message
- CRUD email notifications
V5
- tags for public inboxes (for better discovery)
- top tags
- recent activity
V6
- subscribe to inbox? = separate inbox connected to the first one?
- message/show page
V7
- SEO
- breadcrumb navigation


participants
messages - poll view (chart - votes per message)
PDF/XLSX download
json/rss

******

### Input password to enter a room

any view
```ruby
<%= form_with url: search_inboxes_path, method: :get do |form| %>
  <%= form.text_field :passkey %>
  <%= form.submit "GO" %>
<% end %>
```

posts_controller.rb
```ruby
  def search
    inbox = Inbox.find_by(passkey: params[:passkey])
    if inbox.present?
      redirect_to inboxes_path(inbox), notice: "Success"
    else
      redirect_to inboxes_path, alert: "Failure"
    end
  end
```

routes.rb
```ruby
  resources :inboxes do
    get :search, on: :collection
  end
```

****

Canny analysis

    User avatarUpload name
  Member (Team) (roles)
Company (account, tenant, workspace, organization) / logoUpload faviconUpload name subdomain brand_color
  Inbox (board) (name, url, visibility:private/public, seo_index:boolean, display_on_homepage:boolean)
    Message
      Comment


invitations

remove branding

integrations
  omniauth
    microsoft "azure active directory"
    gsuite
  notifications
    teams
    slack
    discord
    github issues


Onboarding
  use for
    public feedback (customer)
    private feedback (customer)
    internal feedback (employees)
