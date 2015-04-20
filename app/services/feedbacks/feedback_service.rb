class FeedbackService

  def initialize(params, idea, user)
    @params = params
    @idea = idea
    @user = user
  end

  def create
    @feedback = Feedback.new feedback_params
    @feedback.update_attributes(idea: @idea, user: @user)
    @feedback
  end

end