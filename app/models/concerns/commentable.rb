module Commentable
  extend ActiveSupport::Concern

  included do
    has_many :comments, as: :commentable, :dependent => :destroy
    cache_has_many :comments, :inverse_name => :commentable, embed: true
    list :commenters_ids
    counter :comments_counter
  end

  def root_comments
    self.comments.where(:parent_id => nil)
  end

  def comment_threads
    self.comments
  end

  def get_commenters
    User.where(id: commenters_ids)
  end

end