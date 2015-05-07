class Follow < ActiveRecord::Base

  belongs_to :follower, polymorphic: true
  belongs_to :followable, polymorphic: true

  # Validations
  validates :followable, presence: true
  validates :follower, presence: true

  after_create :increment_counters
  before_destroy :decrement_counters, :delete_notification

  private

  #Redis Counters
  def increment_counters
    follower.followings_counter.increment
    followable.followers_counter.increment
    follower.followings_ids << followable_id if followable_type == "User"
    follower.idea_followings_ids << followable_id if followable_type == "Idea"
    follower.school_followings_ids << followable_id if followable_type == "School"
    followable.followers_ids << follower_id
    Idea.popular.increment(followable_id) if followable_type == "Idea"
    User.popular.increment(followable_id) if followable_type == "User"

    #Send stats via pusher
    publish_stats
  end

  def decrement_counters
    follower.followings_counter.decrement
    followable.followers_counter.decrement
    follower.followings_ids.delete(followable_id) if followable_type == "User"
    follower.idea_followings_ids.delete(followable_id) if followable_type == "Idea"
    follower.school_followings_ids.delete(followable_id) if followable_type == "School"
    followable.followers_ids.delete(follower_id)

    Idea.popular.decrement(followable_id) if followable_type == "Idea"
    User.popular.decrement(followable_id) if followable_type == "User"

    #Send stats via pusher
    publish_stats
  end

  def publish_stats
    #Trigger pusher to update stats
    Pusher.trigger_async("user-stats-#{followable.id}",
     "user_stats_update",
       {data:
         {
           id: followable.id,
           followers_count: followable.followers_counter.value
         }
       }.to_json
    )
  end

  def delete_notification
    DeleteUserNotificationJob.perform_later(self.id, self.class.to_s) unless followable_type == "School"
  end

end
