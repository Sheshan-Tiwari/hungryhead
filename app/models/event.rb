class Event < ActiveRecord::Base

  #included modules
  include Redis::Objects

  #Slug
  extend FriendlyId
  friendly_id :slug_candidates

  #Geocode
  geocoded_by :address
  after_validation :geocode, if: ->(event){ event.address.present? and event.address_changed? }

  #Validation
  validates :title, :presence => true, length: {within: 10..50}
  validates :start_time, :end_time, :presence => true
  validates :excerpt, :presence => true, length: {within: 100..300}
  validates :description, :presence => true, length: {within: 300..2000}
  validates :address, :presence => true

  #Includes concerns
  include Sluggable
  include Commentable
  include Votable
  include Impressionable

  #JSONB store accessor
  store_accessor :media, :cover_position, :cover_left,
  :cover_processing, :cover_tmp

  #Enumerators for handling states
  enum status: { draft:0, published:1 }
  enum privacy: { me: 0, friends: 1, everyone: 2 }

  #Redis Lists
  list :attendees_ids
  list :invites_ids
  counter :attendees_counter
  counter :invites_counter
  counter :comments_counter

  #Mount carrierwave
  mount_uploader :cover, CoverUploader

  #Tags for feedback
  acts_as_taggable_on :categories

  #Associations
  belongs_to :owner, polymorphic: true, touch: true
  has_many :event_attendees
  has_many :event_invites

  #Callbacks
  after_destroy  :delete_activity
  after_commit :create_activity, on: :create

  public

  def attending?(user)
    attendees_ids.include?(user.id.to_s)
  end

  def name_badge
    (title.split('').first + title.split('').second).upcase
  end

  def invited?(user)
    invites_ids.include?(user.id.to_s)
  end

  def profile_complete?
    if [self.title, self.description, self.cover,
      self.excerpt, self.space, self.address].any?{|f| f.blank? }
      return false
    else
      return true
    end
  end

  private

  def should_generate_new_friendly_id?
    slug.blank? || title_changed?
  end

  def slug_candidates
   [:title]
  end

  def create_activity
    # Enque activity creation
    CreateActivityJob.perform_later(id, self.class.to_s) if Activity.where(trackable: self).empty?
  end

  def delete_activity
    #Delete activity item from feed
    DeleteActivityJob.perform_later(self.id, self.class.to_s)
  end

end