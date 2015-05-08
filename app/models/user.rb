class User < ActiveRecord::Base

  include ActiveModel::Validations
  include Rails.application.routes.url_helpers
  include IdentityCache
  include Redis::Objects

  #Concerns for User class
  include Followable
  include Follower
  include Mentionable
  include Sluggable
  include Suggestions
  include Scorable

  acts_as_taggable_on :hobbies, :locations, :subjects, :markets
  acts_as_tagger

  #Redis data types
  list :ideas_ids
  #Store latest user notifications
  sorted_set :latest_notifications, maxlength: 100, marshal: true

  #Redis counters to cache total investments and ideas
  counter :feedbacks_counter
  counter :investments_counter
  counter :ideas_counter
  counter :views_counter

  #Enumerators to handle states
  enum state: { inactive: 0, published: 1}
  enum role: { user: 0, entrepreneur: 1, mentor: 2, teacher: 3 }

  #Accessor methods for JSONB datatypes
  store_accessor :profile, :facebook_url, :twitter_url, :linkedin_url, :website_url
  store_accessor :media, :avatar_position, :cover_position, :cover_left,
  :cover_processing, :avatar_processing
  store_accessor :settings, :theme, :idea_notifications, :note_notifications, :feedback_notifications,
  :investment_notifications, :follow_notifications, :weekly_mail
  store_accessor :fund, :balance, :invested_amount, :earned_amount
  serialize [:fund, :education, :interests, :profile, :settings], HashSerializer

  #Merit GEM for badges and points
  has_merit

  #Devise for authentication
  devise :invitable, :async, :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable, :confirmable,
    :registerable, :authentication_keys => [:login]

  attr_accessor :login

  #Model Relationships
  belongs_to :school

  has_many :authentications, :dependent => :destroy
  has_many :activities, :dependent => :destroy
  has_many :notifications, :dependent => :destroy
  has_many :feedbacks, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :investments, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :slugs, as: :sluggable, dependent: :destroy

  #Caching Model
  cache_has_many :activities, :embed => true
  cache_has_many :followings, :inverse_name => :follower, :embed => true
  cache_has_many :followers, :inverse_name => :followable, :embed => true
  cache_has_many :investments, :embed => true
  cache_has_many :feedbacks, :embed => true
  cache_has_many :activities, :embed => true
  cache_has_many :notifications, :embed => true

  cache_index :school_id
  cache_index :type
  cache_index :slug

  #Media Uploaders - carrierwave
  mount_uploader :avatar, LogoUploader
  mount_uploader :cover, CoverUploader

  #Scopes for searching
  scope :entrepreneurs, -> { where(role: 1) }
  scope :users, -> { where(role: 0) }

  #Callbacks
  before_save :add_fullname, unless: :name_present?
  before_save :add_username, if: :username_absent?
  after_save :load_into_soulmate, :rebuild_notifications, unless: :is_admin
  before_destroy :remove_from_soulmate, :decrement_counters, :delete_activity, unless: :is_admin
  after_create :increment_counters, :seed_fund, :seed_settings,  unless: :is_admin

  #Model Validations
  validates :email, :presence => true, :uniqueness => {:case_sensitive => false}
  validates :name, :presence => true
  validates :username, :presence => true, :uniqueness => true, format: { with: /\A[a-zA-Z0-9]+\Z/, message: "should not contain empty spaces or symbols" }
  validates :password, :confirmation => true, :presence => true, :length => {:within => 6..40}, :on => :create


  suggestions_for :username, :num_suggestions => 5,
      :first_name_attribute => :firstname, :last_name_attribute => :lastname

  #Reading models
  acts_as_reader

  #Messaging system
  acts_as_messageable

  #Public methods

  public

  def can_score?
    true
  end

  def mailboxer_email(object)
    email
  end

  def balance_available?(amount)
    balance > amount.to_i
  end

  #Login using both email and username
  def login=(login)
    @login = login
  end

  def login
    @login || self.username || self.email
  end

  def email_required?
    super && authentications.blank?
  end

  def password_required?
    super && authentications.blank?
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later!(wait: 5.seconds)
  end

  def school_name
    school_id.present? ? school.name : ""
  end

  def user_name_badge
    first_name.present? ? first_name.first + last_name.first : add_fullname
  end

  def firstname
    self.name.split(' ').first
  end

  def lastname
    self.name.split(' ').second
  end

  private

  #returns if a user is admin
  def is_admin
    admin?
  end

  def name_present?
    !first_name.present? && !last_name.present?
  end

  def username_absent?
    !username.present?
  end

  def add_username
    email_username = self.name.parameterize
    if User.find_by_username(email_username).blank?
      email_username = email_username
    else
      num = 1
      while(User.find_by_username(email_username).present?)
        email_username = "#{self.name.parameterize}#{num}"
        num += 1
      end
    end
    self.username = email_username
  end

  # returns and adds first_name and last_name to database
  def add_fullname
    words = self.name.split(" ")
    self.first_name = words.first
    self.last_name =  words.last
  end

  #Seeds amount into database on: :create
  def seed_fund
    self.fund = {balance: 1000}
  end

  #Seeds settings into database on: :create
  def seed_settings
    self.settings = {
      theme: 'solid',
      idea_notifications: true,
      feedback_notifications: true,
      investment_notifications: true,
      follow_notifications: true,
      note_notifications: true,
      weekly_mail: true
    }
  end

  #Slug attributes for friendly id
  def slug_candidates
    [:username]
  end

  def rebuild_notifications
    if rebuild_notification? && has_notifications?
      unless admin?
        #rebuild user feed every time name and avatar update.
        RebuildNotificationsCacheJob.set(wait: 5.seconds).perform_later(id)
        #Find all followers and followings and update their feed.
        User.where(id: followers_ids.members | followings_ids.members).find_each do |user|
          RebuildNotificationsCacheJob.set(wait: 5.seconds).perform_later(user.id)
        end
      end
    end
  end

  def rebuild_notification?
    name_changed? || avatar_changed? && !id_changed?
  end

  def has_notifications?
    latest_notifications.members.length > 0
  end

  #Load data to redis using soulmate after_save
  def load_into_soulmate
    unless admin?
      if type == "Student"
        soulmate_loader("students")
      elsif type == "Mentor"
        soulmate_loader("mentors")
      elsif type == "Teacher"
        soulmate_loader("teachers")
      end
    end
  end

  def soulmate_loader(type)
    loader = Soulmate::Loader.new(type)
    if avatar
      image =  avatar.url(:avatar)
      resume = mini_bio
    else
      image= "http://placehold.it/30"
    end
    loader.add("term" => name, "image" => image, "description" => resume, "id" => id, "data" => {
      "link" => profile_path(self)
      })
  end

  def remove_from_soulmate
    loader = Soulmate::Loader.new("students")
      loader.remove("id" => id)
  end

  def increment_counters
    school.students_counter.increment if school && type == "Student"
    school.students_ids << id if school && type == "Student"
    school.teachers_ids << id if school && type == "Teacher"
    User.latest << user_json unless type == "User"
    User.popular.add(id, 0) unless type == "User"
    User.trending.add(id, 0) unless type == "User"
  end

  def decrement_counters
    school.students_counter.decrement if school && school.students_counter.value > 0 && type == "Student"
    school.students_ids.delete(id) if school && type == "Student"
    school.teachers_ids.delete(id) if school && type == "Teacher"
    User.latest.delete(user_json) unless type == "User"
    User.popular.delete(id) unless type == "User"
    User.trending.delete(id) unless type == "User"
  end

  def user_json
    {
      id: id,
      name: name,
      description: mini_bio,
      url: profile_path(self)
    }
  end

  #Deletes all dependent activities for this user
  def delete_activity
    DeleteUserFeedJob.perform_later(self.id, self.class.to_s)
  end

  protected

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end

end
