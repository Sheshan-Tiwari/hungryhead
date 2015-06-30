class Comment < ActiveRecord::Base

  include IdentityCache
  include Redis::Objects

  #Redis counters and ids cache
  counter :votes_counter
  list :voters_ids

  acts_as_nested_set :scope => [:commentable_id, :commentable_type]

  validates :body, :presence => true
  validates :commentable, :presence => true
  validates :user, :presence => true

  include Votable
  include Mentioner

  #Callback hooks
  after_create :increment_counters, :create_activity
  before_destroy :decrement_counters, :delete_notification

  #Model Associations
  belongs_to :user
  belongs_to :commentable, :polymorphic => true, touch: true

  #Model Scopes
  default_scope -> { order('created_at DESC') }

  # Helper class method that allows you to build a comment
  # by passing a commentable object, a user_id, and comment text
  # example in readme
  def self.build_from(obj, user_id, comment)
    new \
      :commentable => obj,
      :body        => comment,
      :user_id     => user_id
  end

  #helper method to check if a comment has children
  def has_children?
    self.children.any?
  end

  # Helper class method to lookup all comments assigned
  # to all commentable types for a given user.
  scope :find_comments_by_user, lambda { |user|
    where(:user_id => user.id).order('created_at DESC')
  }

  # Helper class method to look up all comments for
  # commentable class name and commentable id.
  scope :find_comments_for_commentable, lambda { |commentable_str, commentable_id|
    where(:commentable_type => commentable_str.to_s, :commentable_id => commentable_id).order('created_at DESC')
  }

  # Helper class method to look up all comments for
  # commentable class name and commentable id except current_user
  scope :find_comments_for_commentable_without_current, lambda { |commentable_str, commentable_id|
    where(:commentable_type => commentable_str.to_s, :commentable_id => commentable_id).order('created_at DESC').not(user_id: current_user.id)
  }

  # Helper class method to look up a commentable object
  # given the commentable class name and id
  def self.find_commentable(commentable_str, commentable_id)
    commentable_str.constantize.find(commentable_id)
  end

  def can_score?
    true
  end

  #Get commentable user
  def commentable_user
    commentable.user
  end

  private

  def create_activity
    CreateActivityJob.perform_later(id, self.class.to_s)
  end

  def increment_counters
    #Increment counters for commentable
    commentable.comments_counter.increment
    user.comments_counter.increment
    #cache commenters ids
    commentable.commenters_ids << user_id
  end

  def decrement_counters
    #Decrement comments counter
    commentable.comments_counter.decrement if commentable.comments_counter.value > 0
    user.comments_counter.decrement if user.comments_counter.value > 0
    #cache commenters ids
    commentable.commenters_ids.delete(user_id)
  end

  def delete_notification
    #Delete activity item from feed
    DeleteUserNotificationJob.perform_later(self.id, self.class.to_s)
  end

end
