class VotesController < ApplicationController

  before_filter :authenticate_user!
  before_filter :load_votable, only: [:vote, :voters]

  def vote
    authorize @votable
    if @votable.voted?(current_user)
      CreateVoteService.new(current_user, @votable).unvote
      expire_fragment("activities/activity-#{@vote.votable_type}-#{@vote.votable_id}-user-#{current_user.id}")
    else
      @vote = CreateVoteService.new(current_user, @votable).vote
      if @vote.save
        render json: {
          voted: @votable.voted?(current_user),
          votes_count: @votable.votes_counter.value
        }
        CreateActivityJob.set(wait: 2.seconds).perform_later(@vote.id, @vote.class.to_s)
      else
        render json: @vote.errors, status: :unprocessable_entity
      end
    end
  end

  def voters
    @voters = User.find(@votable.voters_ids.values).paginate(:page => params[:page], :per_page => 10)
    render 'voters/index'
  end

  private

  def load_votable
    @votables = ["Idea", "Feedback", "Investment", "Comment", "Share", "Post"]
    if @votables.include? params[:votable_type]
      @votable = params[:votable_type].safe_constantize.find(params[:votable_id])
    else
      respond_to do |format|
       format.html { render json: {error: 'Sorry, unable to vote on this entity'}, status: :unprocessable_entity }
      end
    end
  end
end
