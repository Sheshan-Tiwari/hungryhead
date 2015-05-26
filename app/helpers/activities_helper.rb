module ActivitiesHelper
  def render_activity activities, options = {}
    if activities.is_a? Activity
      activities.render self, options
    elsif activities.respond_to?(:map)
      return nil if activities.empty?
      activities.map {|activity| activity.render self, options.dup }.join.html_safe
    end
  end

  alias_method :render_activities, :render_activity

  def single_content_for(name, content = nil, &block)
    @view_flow.set(name, ActiveSupport::SafeBuffer.new)
    content_for(name, content, &block)
  end

  def cache_key_for_activities activity
   "activities/activity-#{activity.trackable_type}-#{activity.trackable_id}-user-#{current_user.id}"
  end

end
