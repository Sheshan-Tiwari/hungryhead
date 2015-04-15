if @feedback
	json.(@feedback, :id, :status, :idea_id, :created_at, :updated_at)
	json.user_id @feedback.user.id
  json.body markdownify(@feedback.body)
	json.user_name @feedback.user.name
	json.user_path user_path(@feedback.user)
	json.created_at @feedback.created_at
	json.user_avatar @feedback.user.avatar.url(:mini)

  json.meta do
    json.user_name your_name(current_user, false)
    json.idea_name @feedback.idea.name
    json.idea_path idea_path(@feedback.idea)
    json.can_feedback @feedback.idea.can_feedback?(current_user)
    json.is_owner @feedback.idea.is_owner?(current_user)
    json.user_avatar current_user.avatar.url(:mini)
  end
end
