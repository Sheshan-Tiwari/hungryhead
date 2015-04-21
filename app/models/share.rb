class Share < ActiveRecord::Base

  #Associations
  belongs_to :shareable, polymorphic: true, counter_cache: true
	belongs_to :user, touch: true, counter_cache: true
 	store_accessor :parameters, :shareable_name

 	#Enumerators to handle status
	enum status: {pending: 0, shared: 1}

	acts_as_votable

	include PublicActivity::Model
	include Redis::Objects
	tracked only: [:create],
	owner: ->(controller, model) { controller && controller.current_user },
	recipient: ->(controller, model) { model && model.shareable.student }

	counter :votes_counter
	sorted_set :voters_ids

	before_destroy :remove_activity
	after_create :increment_counters
	before_destroy :decrement_counters

	private

	def remove_activity
	 PublicActivity::Activity.where(trackable_id: self.id, trackable_type: self.class.to_s).find_each do |activity|
	  activity.destroy if activity.present?
	  true
	 end
	end

	def increment_counters
		shareable.shares_counter.increment
	  shareable.sharers_ids.add(user_id, created_at.to_i)
	end

	def decrement_counters
		shareable.shares_counter.decrement
	  shareable.sharers_ids.delete(user_id)
	end

end
