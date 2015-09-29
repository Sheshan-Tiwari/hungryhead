class EventAttendee < ActiveRecord::Base

  # Associations
  belongs_to :event, touch: true
  belongs_to :attendee, class_name: 'User', foreign_key: 'attendee_id'

  # Callbacks
  before_destroy :update_counters, :delete_cached_attendees_ids
  after_commit :update_counters, :cache_attendees_ids, on: :create

  private

  # Update counters and cache attendee ids to Redis
  def update_counters
    event.attendees_counter.reset
    event.attendees_counter.incr(event.event_attendees.size)
    true
  end

  def cache_attendees_ids
    event.attendees_ids << attendee_id unless event.attending?(attendee)
  end

  def delete_cached_attendees_ids
    event.attendees_ids.delete(attendee_id)
    true
  end
end
