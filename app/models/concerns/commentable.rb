module Commentable
  extend ActiveSupport::Concern

  included do
    has_many :comments, as: :commentable, :dependent => :destroy
  end

  def root_comments
    self.comments.where(:parent_id => nil)
  end

  def comment_threads
    self.comments
  end

  def commenters
    commenters_ids.members
  end

end