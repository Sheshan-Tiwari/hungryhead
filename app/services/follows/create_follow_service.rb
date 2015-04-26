class CreateFollowService
	def initialize(user, followable)
		@user = user
    @followable = followable
	end

  def follow
    @user.follows.new(followable: @followable)
  end

  def unfollow
    @user.follows.where(followable: @followable).each do |follow|
      follow.destroy
      DeleteUserFeedJob.perform_later(follow.id, follow.class.to_s)
    end
  end

end