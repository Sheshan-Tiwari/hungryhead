require_dependency "site_feedback/application_controller"

module SiteFeedback
  class FeedbacksController < ApplicationController
    before_action :set_feedback, only: [:show, :edit, :update, :destroy]

    # GET /feedbacks
    def index
      @feedback = SiteFeedback::Feedback.new
    end

    # GET /feedbacks/1
    def show
    end

    # GET /feedbacks/new
    def new
      @feedback = SiteFeedback::Feedback.new
    end

    # POST /feedbacks
    def create
      @feedback = SiteFeedback::Feedback.new(feedback_params)
      @feedback.user = current_user if current_user
      respond_to do |format|
        if @feedback.save
          #Track event in mixpanel
          meta_events_tracker.event!(:user, :new_contact_request, { :name => @feedback.name, :email => @feedback.email, :id => @feedback.id })
          format.html { redirect_to @feedback, notice: 'Thank you so much for your time. We have recieved your feedback.'}
          format.js {render :show, notice: 'Thank you so much for your time. We have recieved your feedback.'}
        else
          format.js
          format.json {render json: @feedback.errors}
        end
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_feedback
        @feedback = SiteFeedback::Feedback.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def feedback_params
        params.require(:feedback).permit(:name, :email, :body, :attachment)
      end
  end
end
