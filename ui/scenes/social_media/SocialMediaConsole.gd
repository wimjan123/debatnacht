extends Control
class_name SocialMediaConsoleScene

# Social media management scene controller
# Handles post creation, feed management, and engagement analytics

# UI References - MainContainer structure
@onready var followers_label: Label = $MainContainer/HeaderContainer/EngagementMetrics/FollowersLabel
@onready var reach_label: Label = $MainContainer/HeaderContainer/EngagementMetrics/ReachLabel
@onready var engagement_label: Label = $MainContainer/HeaderContainer/EngagementMetrics/EngagementLabel

# Left Panel - Post Creation
@onready var post_type_option: OptionButton = $MainContainer/ContentContainer/LeftPanel/PostCreationPanel/PostCreationContent/PostTypeContainer/PostTypeOption
@onready var message_input: TextEdit = $MainContainer/ContentContainer/LeftPanel/PostCreationPanel/PostCreationContent/MessageContainer/MessageInput
@onready var character_count_label: Label = $MainContainer/ContentContainer/LeftPanel/PostCreationPanel/PostCreationContent/MessageContainer/CharacterCountLabel
@onready var schedule_post_check: CheckBox = $MainContainer/ContentContainer/LeftPanel/PostCreationPanel/PostCreationContent/SchedulingContainer/SchedulePostCheck
@onready var preview_button: Button = $MainContainer/ContentContainer/LeftPanel/PostCreationPanel/PostCreationContent/PostButtonsContainer/PreviewButton
@onready var post_button: Button = $MainContainer/ContentContainer/LeftPanel/PostCreationPanel/PostCreationContent/PostButtonsContainer/PostButton

# Central Panel - Feed
@onready var social_media_feed: VBoxContainer = $MainContainer/ContentContainer/CentralPanel/FeedScrollContainer/SocialMediaFeed

# Right Panel - Trending and Analytics
@onready var trending_list: VBoxContainer = $MainContainer/ContentContainer/RightPanel/TrendingScrollContainer/TrendingList
@onready var post_performance_label: Label = $MainContainer/ContentContainer/RightPanel/AnalyticsContainer/AnalyticsPanel/AnalyticsContent/PostPerformanceLabel
@onready var sentiment_label: Label = $MainContainer/ContentContainer/RightPanel/AnalyticsContainer/AnalyticsPanel/AnalyticsContent/SentimentLabel
@onready var demographics_label: Label = $MainContainer/ContentContainer/RightPanel/AnalyticsContainer/AnalyticsPanel/AnalyticsContent/DemographicsLabel

# Action Buttons
@onready var back_button: Button = $MainContainer/ActionContainer/BackButton
@onready var scheduled_posts_button: Button = $MainContainer/ActionContainer/ScheduledPostsButton
@onready var campaign_boost_button: Button = $MainContainer/ActionContainer/CampaignBoostButton
@onready var help_button: Button = $MainContainer/ActionContainer/HelpButton

# Social Media State
var current_post_draft: Dictionary = {}
var character_limit: int = 280
var follower_count: int = 0
var engagement_metrics: Dictionary = {}
var trending_topics: Array[String] = []

# Scene Dependencies
var localization_manager: LocalizationManager
var tooltip_manager: TooltipManager
var notification_system: NotificationSystem
var navigation_controller: NavigationController

func _ready() -> void:
	# Get singleton references
	localization_manager = LocalizationManager.get_instance()
	tooltip_manager = TooltipManager.get_instance()
	notification_system = NotificationSystem.get_instance()
	navigation_controller = NavigationController.get_instance()
	
	# Initialize social media interface
	_initialize_social_media_console()
	_setup_post_creation()
	_load_social_media_feed()
	_update_trending_topics()
	_update_analytics()
	_setup_tooltips()

func _initialize_social_media_console() -> void:
	"""Initialize social media console state and metrics"""
	# Load current engagement metrics from game state
	follower_count = _get_current_follower_count()
	engagement_metrics = _get_engagement_metrics()
	
	# Update header metrics
	followers_label.text = localization_manager.get_text("social_media.followers") + ": " + _format_number(follower_count)
	reach_label.text = localization_manager.get_text("social_media.reach") + ": " + _format_number(engagement_metrics.get("reach", 0))
	engagement_label.text = localization_manager.get_text("social_media.engagement") + ": " + str(engagement_metrics.get("engagement_rate", 0.0)) + "%"

func _setup_post_creation() -> void:
	"""Setup post creation interface and options"""
	# Populate post type options
	post_type_option.clear()
	post_type_option.add_item(localization_manager.get_text("social_media.post_type_text"))
	post_type_option.add_item(localization_manager.get_text("social_media.post_type_image"))
	post_type_option.add_item(localization_manager.get_text("social_media.post_type_video"))
	post_type_option.add_item(localization_manager.get_text("social_media.post_type_poll"))
	post_type_option.add_item(localization_manager.get_text("social_media.post_type_thread"))
	
	# Initialize post draft
	current_post_draft = {
		"type": "text",
		"message": "",
		"scheduled": false,
		"schedule_time": null
	}
	
	# Update character count
	_update_character_count()

func _get_current_follower_count() -> int:
	"""Get current follower count from game state"""
	# Stub implementation - would connect to game state
	return 15420 + randi() % 1000

func _get_engagement_metrics() -> Dictionary:
	"""Get current engagement metrics from social media analytics"""
	return {
		"reach": 45600 + randi() % 5000,
		"engagement_rate": 3.2 + randf() * 1.5,
		"impressions": 128000 + randi() % 20000,
		"clicks": 1240 + randi() % 200
	}

func _format_number(number: int) -> String:
	"""Format large numbers with K/M suffixes"""
	if number >= 1000000:
		return str(number / 1000000.0).pad_decimals(1) + "M"
	elif number >= 1000:
		return str(number / 1000.0).pad_decimals(1) + "K"
	else:
		return str(number)

func _load_social_media_feed() -> void:
	"""Load and display social media feed posts"""
	# Clear existing feed
	for child in social_media_feed.get_children():
		child.queue_free()
	
	# Load recent posts from game state
	var recent_posts = _get_recent_posts()
	
	for post_data in recent_posts:
		var post_item = _create_feed_post_item(post_data)
		social_media_feed.add_child(post_item)

func _get_recent_posts() -> Array[Dictionary]:
	"""Get recent social media posts"""
	var posts: Array[Dictionary] = []
	
	# Stub implementation - would load from game state/API
	posts.append({
		"message": "Excited to announce our new healthcare reform proposal! #Healthcare #Reform",
		"timestamp": "2024-09-24 10:30",
		"likes": 245,
		"shares": 18,
		"comments": 32,
		"sentiment": "positive"
	})
	
	posts.append({
		"message": "Join us at tomorrow's town hall meeting to discuss climate action initiatives.",
		"timestamp": "2024-09-24 08:15",
		"likes": 189,
		"shares": 24,
		"comments": 15,
		"sentiment": "neutral"
	})
	
	return posts

func _create_feed_post_item(post_data: Dictionary) -> Control:
	"""Create visual feed post item"""
	var post_container := VBoxContainer.new()
	post_container.add_theme_stylebox_override("panel", preload("res://ui/themes/post_panel.tres"))
	
	# Post content
	var message_label := RichTextLabel.new()
	message_label.text = post_data.message
	message_label.custom_minimum_size = Vector2(0, 60)
	message_label.fit_content = true
	post_container.add_child(message_label)
	
	# Post metrics
	var metrics_container := HBoxContainer.new()
	
	var likes_label := Label.new()
	likes_label.text = "👍 " + str(post_data.likes)
	metrics_container.add_child(likes_label)
	
	var shares_label := Label.new()
	shares_label.text = "🔄 " + str(post_data.shares)
	metrics_container.add_child(shares_label)
	
	var comments_label := Label.new()
	comments_label.text = "💬 " + str(post_data.comments)
	metrics_container.add_child(comments_label)
	
	# Sentiment indicator
	var sentiment_label := Label.new()
	var sentiment_text: String
	var sentiment_color: Color
	
	match post_data.sentiment:
		"positive":
			sentiment_text = "😊"
			sentiment_color = Color.GREEN
		"negative":
			sentiment_text = "😞"
			sentiment_color = Color.RED
		_:
			sentiment_text = "😐"
			sentiment_color = Color.GRAY
	
	sentiment_label.text = sentiment_text
	sentiment_label.add_theme_color_override("font_color", sentiment_color)
	metrics_container.add_child(sentiment_label)
	
	post_container.add_child(metrics_container)
	return post_container

func _update_trending_topics() -> void:
	"""Update trending topics display"""
	# Clear existing trending items
	for child in trending_list.get_children():
		child.queue_free()
	
	# Load trending topics
	trending_topics = _get_trending_topics()
	
	for topic in trending_topics:
		var topic_item := Button.new()
		topic_item.text = "#" + topic
		topic_item.alignment = HORIZONTAL_ALIGNMENT_LEFT
		topic_item.pressed.connect(_on_trending_topic_selected.bind(topic))
		trending_list.add_child(topic_item)

func _get_trending_topics() -> Array[String]:
	"""Get current trending topics"""
	return ["Healthcare", "Climate", "Economy", "Education", "Housing"]

func _update_analytics() -> void:
	"""Update analytics panel with current performance data"""
	var performance_data = _calculate_post_performance()
	
	post_performance_label.text = localization_manager.get_text("social_media.avg_engagement") + ": " + str(performance_data.avg_engagement) + "%"
	sentiment_label.text = localization_manager.get_text("social_media.sentiment_score") + ": " + str(performance_data.sentiment_score)
	demographics_label.text = localization_manager.get_text("social_media.top_demographic") + ": " + performance_data.top_demographic

func _calculate_post_performance() -> Dictionary:
	"""Calculate post performance metrics"""
	return {
		"avg_engagement": 3.8 + randf() * 2.0,
		"sentiment_score": "Positive",
		"top_demographic": "25-34 years"
	}

func _update_character_count() -> void:
	"""Update character count display for current message"""
	var current_length = message_input.text.length()
	var remaining = character_limit - current_length
	
	character_count_label.text = str(remaining) + "/" + str(character_limit)
	
	# Color code based on remaining characters
	if remaining < 0:
		character_count_label.add_theme_color_override("font_color", Color.RED)
		post_button.disabled = true
	elif remaining < 20:
		character_count_label.add_theme_color_override("font_color", Color.ORANGE)
		post_button.disabled = false
	else:
		character_count_label.add_theme_color_override("font_color", Color.WHITE)
		post_button.disabled = message_input.text.strip_edges().is_empty()

func _setup_tooltips() -> void:
	"""Setup educational tooltips for social media interface"""
	tooltip_manager.add_tooltip(post_type_option, "tooltip.post_type_explanation")
	tooltip_manager.add_tooltip(engagement_label, "tooltip.engagement_explanation")
	tooltip_manager.add_tooltip(sentiment_label, "tooltip.sentiment_explanation")
	tooltip_manager.add_tooltip(campaign_boost_button, "tooltip.campaign_boost_explanation")

# Signal Handlers
func _on_post_type_selected(index: int) -> void:
	"""Handle post type selection"""
	var post_types = ["text", "image", "video", "poll", "thread"]
	current_post_draft.type = post_types[index]
	
	# Update character limit based on post type
	match current_post_draft.type:
		"text":
			character_limit = 280
		"image":
			character_limit = 280
		"video":
			character_limit = 280
		"poll":
			character_limit = 100  # Shorter for poll questions
		"thread":
			character_limit = 280  # Per thread post
	
	_update_character_count()

func _on_message_text_changed() -> void:
	"""Handle message text changes"""
	current_post_draft.message = message_input.text
	_update_character_count()

func _on_preview_button_pressed() -> void:
	"""Handle post preview"""
	# Show post preview dialog
	var preview_text = _generate_post_preview()
	notification_system.show_notification("social_media.preview", preview_text)

func _generate_post_preview() -> String:
	"""Generate post preview text"""
	var preview = "📱 " + localization_manager.get_text("social_media.preview") + ":\n"
	preview += current_post_draft.message
	preview += "\n\n📊 " + localization_manager.get_text("social_media.estimated_reach") + ": " + _format_number(_calculate_estimated_reach())
	return preview

func _calculate_estimated_reach() -> int:
	"""Calculate estimated reach for current post"""
	# Simple reach calculation based on followers and engagement rate
	var base_reach = follower_count * 0.1  # 10% organic reach
	var engagement_multiplier = engagement_metrics.get("engagement_rate", 3.0) / 3.0
	return int(base_reach * engagement_multiplier)

func _on_post_button_pressed() -> void:
	"""Handle posting to social media"""
	if current_post_draft.message.strip_edges().is_empty():
		notification_system.show_notification("social_media.error_empty_post")
		return
	
	if message_input.text.length() > character_limit:
		notification_system.show_notification("social_media.error_too_long")
		return
	
	# Process the post
	if schedule_post_check.button_pressed:
		_schedule_post()
	else:
		_publish_post_immediately()

func _publish_post_immediately() -> void:
	"""Publish post immediately"""
	# Add post to feed
	var new_post = {
		"message": current_post_draft.message,
		"timestamp": Time.get_datetime_string_from_system(),
		"likes": 0,
		"shares": 0,
		"comments": 0,
		"sentiment": "neutral"
	}
	
	var post_item = _create_feed_post_item(new_post)
	social_media_feed.add_child(post_item)
	social_media_feed.move_child(post_item, 0)  # Move to top
	
	# Clear post draft
	message_input.text = ""
	current_post_draft.message = ""
	_update_character_count()
	
	notification_system.show_notification("social_media.post_published")

func _schedule_post() -> void:
	"""Schedule post for later"""
	# Would open scheduling interface
	notification_system.show_notification("social_media.post_scheduled")

func _on_trending_topic_selected(topic: String) -> void:
	"""Handle trending topic selection"""
	# Add hashtag to current message
	var current_text = message_input.text
	var hashtag = "#" + topic + " "
	
	if not current_text.contains(hashtag.strip_edges()):
		message_input.text += hashtag
		_on_message_text_changed()

func _on_back_button_pressed() -> void:
	"""Handle back button navigation"""
	navigation_controller.navigate_to_previous_scene()

func _on_scheduled_posts_pressed() -> void:
	"""Handle scheduled posts button"""
	# Would open scheduled posts management
	notification_system.show_notification("notification.feature_coming_soon")

func _on_campaign_boost_pressed() -> void:
	"""Handle campaign boost button"""
	# Would open campaign boost options
	notification_system.show_notification("notification.boost_feature_coming_soon")

func _on_help_button_pressed() -> void:
	"""Handle help button"""
	# Would show social media help
	notification_system.show_notification("notification.help_coming_soon")
