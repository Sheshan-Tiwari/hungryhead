class InviteRequestsController < ApplicationController

  respond_to :js
  layout "home"

  # POST /invite_requests
  # POST /invite_requests.json
  def create
    @invite_request = InviteRequest.new(invite_request_params)
    @invite_request.request = request
    if Rails.env.production?
      meta_events_tracker.event!(:user, :new_invite_request, { :name => @invite_request.name, user_type: @invite_request.user_type, :email => @invite_request.email, :id => @invite_request.id })
    end
    respond_to do |format|
      if @invite_request.save
        format.js {render :show}
      else
       format.js {render :new}
      end
    end

  end

  private

  def invite_request_params
    params.require(:invite_request).permit(:name, :email, :url, :user_type)
  end

end
