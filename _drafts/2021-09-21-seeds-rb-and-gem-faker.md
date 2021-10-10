http://blog.magmalabs.io/2019/11/25/best-practices-using-rails-seeds.html
https://edgeguides.rubyonrails.org/active_record_migrations.html#migrations-and-seed-data
https://github.com/rormvp/tourreise-core/tree/develop/db
https://github.com/AhmedNadar/PrivateSouq/tree/main/db/seeds
[gem faker](https://github.com/faker-ruby/faker)


rails db:seed
rails db:reset
rails db:setup

config/seeds.rb
```
Dir[File.join(Rails.root, 'db', 'seeds', '*.rb')].sort.each do |seed|
  load seed
end if Rails.env.development?
```

* add this on top to prevent seeds in production
```ruby
return unless Rails.env.development?
```

```
puts "Seeding..."

Country.delete_all

User.create(name: 'Matz')
User.create(name: 'DHH')

Office.create!(name: 'Kir', address: 'Kir', email: 'yshmarov@gmail.com', tel: '+380505532699')
Member.create!(first_name: 'Yaro', last_name: 'Shm', office: Office.first, email: 'yshmarov@gmail.com', dob: Date.today)
User.create!(email: 'yshmarov@gmail.com', password: 'yshmarov@gmail.com', password_confirmation: 'yshmarov@gmail.com',
             member: Member.first)
User.first.add_role(:admin)

k = Office.find_by(name: 'Kir')
p = Office.find_by(name: 'Piat')
r = Office.find_by(name: 'Rok')
m = Office.find_by(name: 'Mazepa')
s = Office.find_by(name: 'Shev')
Room.create(office: k, name: '1')

#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
5.times do
  user = User.create(
    email: Faker::Internet.email,
    name: Faker::Artist.name,
    password: 123456
  )
  rand(0..5).times do
    Post.create(
      title: Faker::Lorem.sentence(word_count: 5),
      description: Faker::Lorem.sentence(word_count: 15),
      body: Faker::Markdown.sandwich(sentences: 50),
      user: user,
      premium: [true, false].sample)
  end
end
p "#{User.count} users created"
p "#{Post.count} posts created"

puts "Seeding done."
```



5.times do
  user = User.create(
    email: Faker::Internet.email,
    name: Faker::Artist.name,
    password: 123456
  )
  rand(0..5).times do
    Post.create(
      title: Faker::Lorem.sentence(word_count: 5),
      description: Faker::Lorem.sentence(word_count: 15),
      body: Faker::Markdown.sandwich(sentences: 50),
      user: user,
      premium: [true, false].sample)
  end
end
p "#{User.count} users created"
p "#{Post.count} posts created"



rails c
Rails.application.load_seed

rails c --sandbox





100.times do |index|
  Movie.create!(title: "Title #{index}",
                director: "Director #{index}",
                storyline: "Storyline #{index}",
                watched_on: index.days.ago)
end





****

Sometimes you want to have some generic, dynamic fake data in your views (that does not persist in the database). Gem Faker to the rescue!

#app/controllers/static_pages_controller.rb
```ruby
def landing_page
  @faker_array = []
  5.times do |n|
    @faker_array.push(name: Faker::Movies::HarryPotter.character, email: Faker::Internet.email)
  end
end
```

#app/views/static_pages/landing_page.html.erb
```ruby
<%= @faker_array %>

<% @faker_array.each do |x| %>
  <br>
  <%= x[:name] %>
  <%= x[:email] %>
<% end %>
```





  @results = []
  5.times do |n|
    @results.push(component: Faker::Movies::HarryPotter.character, status: [:good, :bad].sample, )
  end

