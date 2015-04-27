class Subject < ActiveRecord::Base
  include Sluggable

  private
  def slug_candidates
    [:name]
  end
end