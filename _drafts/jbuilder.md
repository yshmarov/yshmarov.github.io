Jbuilder Gem - https://github.com/rails/jbuilder
image_processing Gem - https://github.com/janko/image_processing

# Terminal
rails g scaffold movies title
rails g model actor name
rails g model actor_movie actor:belongs_to movie:belongs_to
rails active_storage:install
bundle add faker
rails db:seed


# models/actor.rb
class Actor < ApplicationRecord
  has_many :actor_movies, dependent: :destroy
  has_many :movies, through: :actor_movies
end


# models/actor_movie.rb
class ActorMovie < ApplicationRecord
  belongs_to :actor
  belongs_to :movie
end


# models/movie.rb
class Movie < ApplicationRecord
  has_many :actor_movies, dependent: :destroy
  has_many :actors, through: :actor_movies
  has_one_attached :poster do |attachable|
    attachable.variant :thumb, resize_to_limit: [100, 100]
    attachable.variant :small, resize_to_limit: [200, 200]
    attachable.variant :medium, resize_to_limit: [300, 300]
  end
end


# Gemfile
gem "image_processing", "~> 1.2"


# movies_controller.rb
before_action :set_movie, only: %i[ edit update destroy ]

def index
  @movies = Movie.all
  # respond_to do |format|
  #   format.html {}
  #   format.json { render json: @movies }
  # end
end

def show
  @movie = Movie.includes(:actors).find(params[:id])
end

def movie_params
  params.require(:movie).permit(:title, :poster)
end


# views/movies/index.json.jbuilder
json.array! @movies do |movie|
  json.id movie.id
  json.id_of_movie movie.id
  json.title movie.title
  json.url url_for(movie)
  json.url2 movie_url(movie, format: :json)
end


# views/movies/show.json.jbuilder
json.title @movie.title
json.number_of_actors @movie.actors.size
json.actors @movie.actors do |actor|
  json.name actor.name
end
ActiveStorage::Current.url_options =  { host: request.base_url }

json.set! "posters", [] unless @movie.poster.attached?
json.posters do
  json.child! do
    json.size "thumb"
    json.url @movie.poster.variant(:thumb).processed.url
  end
  json.child! do
    json.size "small"
    json.url @movie.poster.variant(:small).processed.url
  end
  json.child! do
    json.size "medium"
    json.url @movie.poster.variant(:medium).processed.url
  end
  json.child! do
    json.size "original"
    json.url @movie.poster.url
  end
end if @movie.poster.attached?

