class CreateVoteService

  def initialize(user, votable)
    @user = user
    @votable = votable
  end

  def create
    if @votable.voted?(@user)
      unvote
    else
      vote
    end
  end

  private

  def vote
    @vote = @votable.votes.create!(voter: @user)
    @activity = @user.notifications.create!(trackable: @vote, recipient: @votable, verb: 'voted', key: 'vote.create')
    send_notification @activity
    true
  end

  def unvote
    @votable.votes.where(voter: @user).each do |vote|
      vote.destroy
    end
    false
  end

  def send_notification activity
    @voter = @votable.class.to_s == "Idea" ? @votable.student : @votable.user
    if @user != @voter
      VoteNotificationService.new(activity).notify
    end
  end

end