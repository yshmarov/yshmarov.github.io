Create new Rails app
Scaffold posts
Add authentication
Admin user

Do you need admin?
- display static data, use as CMS
- admin for a big app
Create or use existing?

image_processing gem?

gem avo
gem devise

enum user role

grid view
grid do
  title :title, as: :text
  cover: image, as : :file, link_to_resource: true
end

AVO
- install
- admin authentication (current_user:admin, routes)
- own branding
- add resources
- resource display fields - custom fields, readonly
- resource display fields - associations: belongs_to, has_many, has_many_through
- resource display fields - ransack search
- resource display fields - sort
- filters (association, enum, custom)
- active_storage attachments
- grid view
- customize sidebar
- PRO authorization
- PRO acts_as_list sorting
