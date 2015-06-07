class Notification < ActiveRecord::Base

  after_commit :delete_older_notifications, on: :create

  include Feedable

  public

  def self.mark_as_read(user_id)
    UpdateNotificationCacheService.new(user_id, self)
  end

  def delete_older_notifications
    refresh_friends_notifications
    refresh_ticker
    profile_latest_activities
  end

  def refresh_ticker
    user.ticker.remrangebyrank(100, user.ticker.members.length)
  end

  def refresh_friends_notifications
    user.friends_notifications.remrangebyrank(50, user.friends_notifications.members.length)
  end

  def profile_latest_activities
    user.latest_activities.remrangebyrank(5, user.latest_activities.members.length)
  end

end

