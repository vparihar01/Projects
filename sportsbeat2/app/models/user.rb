require "likable"
require "search"

class User < ActiveRecord::Base
  extend Role::Helpers
  include Likable

  devise :database_authenticatable, :registerable, :confirmable,
    :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me,
    :first_name, :last_name, :current_school_id, :profile_picture, :birthdate, :gender

  has_many :athletes, :dependent => :destroy
  has_many :athlete_teams, :through => :athletes
  has_many :teams, :through => :athlete_teams
  has_many :teammates, :through => :teams, :source => :users, :uniq => true
  has_many :galleries, :as => :owner, :dependent => :destroy
  has_many :pictures, :as => :owner, :dependent => :destroy
  has_many :posts, :as => :author, :dependent => :destroy
  has_roles :admin, :alumnus, :athlete, :fan, :staff

  after_create :create_default_galleries

  def create_default_galleries
    Gallery.transaction do
      g = Gallery.new
      g.creator = self
      g.owner = self
      g.name = "My Pictures"
      g.save!

      g = Gallery.new
      g.creator = self
      g.owner = self
      g.name = "Beat Pictures"
      g.save!
    end
  end

  def current_athletes
    athletes.joins(:athlete_teams).where(:athlete_teams => {:season_id => Season.current.id})
  end

  def current_teams
    teams.where(:athlete_teams => {:season_id => Season.current.id})
  end

  def display_name
    first_name + " " + last_name
  end

  include Tire::Model::Callbacks
  include Tire::Model::Search
  include Search::ReloadHelper
  tire do
    settings({
      :analysis => {
        :filter => Search::Filters.user_filters,
        :analyzer => Search::Analyzers.user_analyzers
      }
    })

    mapping do
      indexes :id, :type => 'integer'
      indexes :name, :type => 'string', :analyzer => :user_name_analyzer
      indexes :email, :type => 'string', :analyzer => :user_name_analyzer
    end
  end

  def to_indexed_json
    {
      :id   => id,
      :name => display_name,
      :email => email,
    }.to_json
  end
end
