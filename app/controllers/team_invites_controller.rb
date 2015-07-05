class TeamInvitesController < ApplicationController

  before_action :set_team_invite, only: [:destroy, :update, :show]
  before_action :set_props, only: [:create, :update, :show, :destroy]
  before_action :authenticate_user!

  #Pundit authorization
  after_action :verify_authorized
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def create
    invited = []
    params[:team_invite][:invitees].split(",").each do |user_id|
      user = User.fetch(user_id)
      if @idea.in_team?(user) || @idea.invited?(user)
        skip_authorization
      else
        @team_invite = CreateTeamInviteService.new(user, current_user, @idea, params[:team_invite][:message]).create
        authorize @team_invite
        if @team_invite.save
          invited << user.name
          #cache invites ids
          unless @idea.team_invites_ids.include?(@team_invite.invited_id)
            @idea.team_invites_ids << @team_invite.invited_id
          end
          #Send invitations to recipients
          InviteMailer.invite_team(@team_invite).deliver_later
        else
          render json: @team_invite.errors, status: :unprocessable_entity
        end
      end
    end

    @idea.save!

    if @invited.present?
      render json: {success: "Successfully invited #{invited.to_sentence}"}, status: :created
    else
      render json: {
        invited: false,
        msg: "Something went wrong, please try again",
        status: :created
      }
    end
  end

  def show
    authorize @team_invite
    if current_user == @team_invite.invited && @team_invite.pending?
      @team_invite = UpdateTeamInviteService.new(@team_invite).join_team_invite

      if @team_invite.save
        @team_invite.pending = false
        @team_invite.save
        #Update cached ids
        @idea.team_ids << @team_invite.invited_id unless @idea.in_team?(current_user)
        @idea.team_invites_ids.delete(@team_invite.invited_id.to_s)

        #Follow idea
        current_user.votes.create!(votable: @idea) if Vote.votes_for(current_user, @idea).empty?

        #Increment idea counter
        current_user.ideas_counter.reset
        current_user.ideas_counter.incr(Idea.for_user(current_user).size)

        #cache idea id into redis set
        current_user.ideas_ids.add(@idea.id)

        #Save @idea and redirect
        @idea.save!

        #Send mails to recipients
        InviteMailer.joined_team(@team_invite).deliver_later

        redirect_to idea_path(@idea), notice: "You have successfully joined #{@idea.name} team"
      end
    else
      respond_to do |format|
         format.html { redirect_to idea_url(@idea), notice: "You are already in #{@idea.name} team" }
       end
    end
  end

  def update
    authorize @team_invite
    @team_invite = UpdateTeamInviteService.new(@team_invite).update_team_invite
    if @team_invite.save
      InviteMailer.invite_team(@team_invite).deliver_later
      render json: {success: "Successfully reinvited #{@team_invite.invited.name}"}, status: :created
    end
  end

  def destroy
    #delete cached ids
    @idea.team_ids.delete(@team_invite.invited_id.to_s)
    @idea.team_invites_ids.delete(@team_invite.invited_id.to_s)

    #Save idea
    @idea.save

    #UnVote idea
    @team_invite.invited.votes.destroy!(votable: @team_invite.idea)

    #Decrement idea counter
    @team_invite.invited.ideas_counter.reset
    @team_invite.invited.ideas_counter.incr(Idea.for_user(@team_invite.invited).size)

    #cache idea id into redis set
    @team_invite.invited.ideas_ids.delete(@idea.id)

    @team_invite.destroy
    respond_to do |format|
      format.html { redirect_to ideas_url, notice: 'Idea was successfully destroyed.' }
      format.json { head :no_content }
    end

  end

  private

  def set_team_invite
    @team_invite = TeamInvite.find(params[:id])
  end

  def set_props
    @idea = Idea.fetch_by_slug(params[:idea_id])
  end

  def user_not_authorized
    if request.xhr?
      render json: {error: "You are not authorised to perform this action"}, status: 404
    else
      raise ActionController::RoutingError.new('Not Found')
    end
  end

end
