class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Pundit Authorization
  include Pundit
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :help_user

  #Devise Permitted paramaters
  before_filter :configure_permitted_parameters, if: :devise_controller?

  #Flash messages from rails
  after_filter :prepare_unobtrusive_flash

  #Temporary basic auth
  before_filter :authenticate_basic

  #Device specific templates
  before_action :set_device_type

  def help_user
    current_user
  end


  protected

  def authenticate_basic
    if Rails.env.production?
      authenticate_or_request_with_http_basic do |username, password|
        username == "hungryhead_testing" && password == "production_testing"
      end
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :first_name, :last_name, :name, :school_id, :terms_accepted, :remember_me, :name) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me, :password_confirmation) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:name, :username, :terms_accepted, :email, :password, :password_confirmation, :current_password) }
    devise_parameter_sanitizer.for(:accept_invitation) do |u|
      u.permit(:name, :password, :password_confirmation, :invitation_token)
    end
  end

  def render_forbidden
    flash[:notice] = "You are not authorized to access this page"
    if user_signed_in?
      redirect_to profile_path(current_user)
    else
      flash[:notice] = "Please login to access this page"
      redirect_to root_path
    end
    true
  end

  def authenticate_admin_user!
    authenticate_user!
    redirect_to root_path, alert: "This area is restricted to administrators only." unless current_user.admin?
  end

  def current_admin_user
    return nil if user_signed_in? && !current_user.admin?
    current_user
  end

  def check_logged_in
    redirect_to root_path, alert:  "You are already logged in" unless !user_signed_in?
  end


  def info_for_paper_trail
    {
      user_name: current_user.name,
      user_avatar: current_user.avatar.url(:avatar),
      owner_url: profile_path(current_user)
    } if current_user
  end

  def check_terms
    if user_signed_in? && !current_user.rules_accepted? && !current_user.admin?
      redirect_to(welcome_path(:hello), notice: "Please accept rules to get started")
    end
  end

  private

  #Error message if user not authorised
  def user_not_authorized
    if request.xhr?
      render json: {error: "Not found"}, :status => 404
    else
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  def set_device_type
    request.variant = :phone if browser.mobile?
    request.variant = :tablet if browser.tablet?
  end

end
