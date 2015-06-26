module Help
  class ArticlePolicy < ApplicationPolicy
    def new?
      current_user.admin?
    end

    def update?
      current_user.admin?
    end

    def create?
      current_user.admin?
    end
  end
end