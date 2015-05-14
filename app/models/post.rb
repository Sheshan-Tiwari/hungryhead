class Post < ActiveRecord::Base

  #Includes Modules
  include Redis::Objects
  #Redis counters and lists
  list :voters_ids
  list :commenters_ids
  list :sharers_ids

  #Counters
  counter :votes_counter
  counter :shares_counter
  counter :comments_counter
  counter :views_counter

  #rank
  sorted_set :leaderboard, global: true
  sorted_set :trending, global: true

  extend FriendlyId
  friendly_id :slug_candidates

  has_merit

  belongs_to :user

  #Includes concerns
  include Commentable
  include Sluggable
  include Sharings
  include Votable
  include Scorable

  #Model callbacks
  after_commit :increment_counter, on: :create
  before_destroy :decrement_counter, :delete_activity

  public

  def can_score?
    true
  end

  private

  def slug_candidates
    [:title, [:title, :id]]
  end

  def increment_counter
    user.posts_counter.increment
  end

  def decrement_counter
    user.posts_counter.decrement
  end

  def delete_activity
    DeleteUserFeedJob.set(wait: 5.seconds).perform_later(self.id, self.class.to_s)
  end

end