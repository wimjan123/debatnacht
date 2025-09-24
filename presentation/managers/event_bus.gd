extends Node

# Global event bus system for loose coupling between components
# Enables publish-subscribe pattern for system-wide communication
# Note: This is an autoload singleton, so no class_name declaration needed

# Event subscribers storage
var subscribers: Dictionary = {}  # event_name -> Array[Callable]
var event_history: Array[Dictionary] = []  # For debugging and replay
var max_history_entries: int = 100

# Event categories for organization
enum EventCategory {
	GAME_STATE,
	UI_NAVIGATION,
	USER_ACTION,
	SIMULATION,
	AUDIO,
	ACCESSIBILITY,
	DEBUG
}

# Common event names as constants
const GAME_STATE_CHANGED = "game_state_changed"
const CAMPAIGN_ACTION_EXECUTED = "campaign_action_executed"
const ELECTION_TRIGGERED = "election_triggered"
const TIME_ADVANCED = "time_advanced"

const SCREEN_CHANGED = "screen_changed"
const MODAL_OPENED = "modal_opened"
const MODAL_CLOSED = "modal_closed"
const NAVIGATION_REQUESTED = "navigation_requested"

const TOOLTIP_REQUESTED = "tooltip_requested"
const NOTIFICATION_REQUESTED = "notification_requested"
const HELP_REQUESTED = "help_requested"

const MEDIA_EVENT_TRIGGERED = "media_event_triggered"
const OPINION_POLL_UPDATED = "opinion_poll_updated"
const COALITION_FORMED = "coalition_formed"

const ACCESSIBILITY_CHANGED = "accessibility_changed"
const THEME_CHANGED = "theme_changed"
const LANGUAGE_CHANGED = "language_changed"

# Debug events
const DEBUG_LOG = "debug_log"
const PERFORMANCE_WARNING = "performance_warning"

func _ready() -> void:
	# Initialize autoload singleton
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("EventBus: Initialized as autoload singleton")

# Core event system
func subscribe(event_name: String, callback: Callable) -> void:
	"""Subscribe to an event with a callback function"""
	if not subscribers.has(event_name):
		subscribers[event_name] = []
	
	# Check if callback is already subscribed to prevent duplicates
	var callbacks = subscribers[event_name] as Array
	if not callbacks.has(callback):
		callbacks.append(callback)
		# print("EventBus: Subscribed to ", event_name)  # Commented to reduce noise

func unsubscribe(event_name: String, callback: Callable) -> void:
	"""Unsubscribe from an event"""
	if not subscribers.has(event_name):
		return
	
	var callbacks = subscribers[event_name] as Array
	var index = callbacks.find(callback)
	if index >= 0:
		callbacks.remove_at(index)
		# print("EventBus: Unsubscribed from ", event_name)  # Commented to reduce noise
		
		# Clean up empty subscriber arrays
		if callbacks.is_empty():
			subscribers.erase(event_name)

func publish(event_name: String, data: Dictionary = {}, category: EventCategory = EventCategory.DEBUG) -> void:
	"""Publish an event with optional data"""
	# Record event in history for debugging
	_record_event(event_name, data, category)
	
	# Call all subscribed callbacks
	if subscribers.has(event_name):
		var callbacks = subscribers[event_name] as Array
		for callback in callbacks:
			if callback.is_valid():
				# GDScript doesn't have try/except - use direct call with validation
				if data.is_empty():
					callback.call()
				else:
					callback.call(data)
			else:
				print("EventBus: Invalid callback found for ", event_name, ", removing...")
				callbacks.erase(callback)

func unsubscribe_all(subscriber: Object) -> void:
	"""Unsubscribe an object from all events (useful for cleanup)"""
	for event_name in subscribers.keys():
		var callbacks = subscribers[event_name] as Array
		var callbacks_to_remove = []
		
		for callback in callbacks:
			# Check if callback belongs to the subscriber object
			if callback.is_valid() and callback.get_object() == subscriber:
				callbacks_to_remove.append(callback)
		
		for callback in callbacks_to_remove:
			unsubscribe(event_name, callback)

func has_subscribers(event_name: String) -> bool:
	"""Check if an event has any subscribers"""
	return subscribers.has(event_name) and subscribers[event_name].size() > 0

func get_subscriber_count(event_name: String) -> int:
	"""Get number of subscribers for an event"""
	if subscribers.has(event_name):
		return subscribers[event_name].size()
	return 0

# Convenience methods for common events
func publish_game_state_changed(new_state: GameState) -> void:
	"""Publish game state change event"""
	publish(GAME_STATE_CHANGED, {"new_state": new_state}, EventCategory.GAME_STATE)

func publish_screen_changed(old_screen: String, new_screen: String) -> void:
	"""Publish screen change event"""
	publish(SCREEN_CHANGED, {
		"old_screen": old_screen,
		"new_screen": new_screen
	}, EventCategory.UI_NAVIGATION)

func publish_campaign_action(action: CampaignAction, result: Dictionary) -> void:
	"""Publish campaign action execution event"""
	publish(CAMPAIGN_ACTION_EXECUTED, {
		"action": action,
		"result": result
	}, EventCategory.USER_ACTION)

func publish_media_event(event: MediaEvent) -> void:
	"""Publish media event trigger"""
	publish(MEDIA_EVENT_TRIGGERED, {
		"event": event,
		"timestamp": Time.get_unix_time_from_system()
	}, EventCategory.SIMULATION)

func publish_notification_request(message: String, type: String = "info") -> void:
	"""Publish notification request"""
	publish(NOTIFICATION_REQUESTED, {
		"message": message,
		"type": type,
		"timestamp": Time.get_unix_time_from_system()
	}, EventCategory.UI_NAVIGATION)

func publish_tooltip_request(target: Control, content: String) -> void:
	"""Publish tooltip request"""
	publish(TOOLTIP_REQUESTED, {
		"target": target,
		"content": content
	}, EventCategory.UI_NAVIGATION)

func publish_accessibility_change(setting: String, value) -> void:
	"""Publish accessibility setting change"""
	publish(ACCESSIBILITY_CHANGED, {
		"setting": setting,
		"value": value
	}, EventCategory.ACCESSIBILITY)

func publish_debug_log(message: String, level: String = "info") -> void:
	"""Publish debug log message"""
	publish(DEBUG_LOG, {
		"message": message,
		"level": level,
		"timestamp": Time.get_unix_time_from_system()
	}, EventCategory.DEBUG)

# Event history and debugging
func _record_event(event_name: String, data: Dictionary, category: EventCategory) -> void:
	"""Record event in history for debugging"""
	var event_record = {
		"name": event_name,
		"data": data.duplicate(true),
		"category": category,
		"timestamp": Time.get_unix_time_from_system(),
		"frame": Engine.get_process_frames()
	}
	
	event_history.append(event_record)
	
	# Limit history size
	if event_history.size() > max_history_entries:
		event_history.pop_front()

func get_recent_events(count: int = 10, category: EventCategory = EventCategory.DEBUG) -> Array[Dictionary]:
	"""Get recent events, optionally filtered by category"""
	var recent_events: Array[Dictionary] = []
	var events_added = 0
	
	# Get events in reverse order (most recent first)
	for i in range(event_history.size() - 1, -1, -1):
		if events_added >= count:
			break
		
		var event = event_history[i]
		if category == EventCategory.DEBUG or event.category == category:
			recent_events.append(event)
			events_added += 1
	
	return recent_events

func get_events_by_name(event_name: String, max_count: int = 50) -> Array[Dictionary]:
	"""Get events by name from history"""
	var matching_events: Array[Dictionary] = []
	
	for event in event_history:
		if event.name == event_name:
			matching_events.append(event)
			if matching_events.size() >= max_count:
				break
	
	return matching_events

func clear_event_history() -> void:
	"""Clear event history"""
	event_history.clear()

func get_event_statistics() -> Dictionary:
	"""Get statistics about events"""
	var stats = {
		"total_events": event_history.size(),
		"events_by_category": {},
		"events_by_name": {},
		"active_subscriptions": subscribers.size(),
		"total_subscribers": 0
	}
	
	# Count events by category
	for event in event_history:
		var category_name = EventCategory.keys()[event.category]
		if not stats.events_by_category.has(category_name):
			stats.events_by_category[category_name] = 0
		stats.events_by_category[category_name] += 1
		
		# Count events by name
		if not stats.events_by_name.has(event.name):
			stats.events_by_name[event.name] = 0
		stats.events_by_name[event.name] += 1
	
	# Count total subscribers
	for event_name in subscribers.keys():
		stats.total_subscribers += subscribers[event_name].size()
	
	return stats

# Debug utilities
func print_active_subscriptions() -> void:
	"""Print all active subscriptions for debugging"""
	print("=== EventBus Active Subscriptions ===")
	for event_name in subscribers.keys():
		var count = subscribers[event_name].size()
		print(event_name, ": ", count, " subscribers")
	print("Total events: ", subscribers.size())
	print("====================================")

func print_recent_events(count: int = 5) -> void:
	"""Print recent events for debugging"""
	print("=== EventBus Recent Events ===")
	var recent = get_recent_events(count)
	for event in recent:
		var time_str = Time.get_datetime_string_from_unix_time(event.timestamp)
		print("[", time_str, "] ", event.name, " - ", EventCategory.keys()[event.category])
	print("=============================")

# Performance monitoring
var _performance_warnings: Array[String] = []
var _max_warnings: int = 10

func _check_performance() -> void:
	"""Check for performance issues and emit warnings"""
	var total_subscribers = 0
	for event_name in subscribers.keys():
		var subscriber_count = subscribers[event_name].size()
		total_subscribers += subscriber_count
		
		# Warn about events with too many subscribers
		if subscriber_count > 20:
			_add_performance_warning("Event '" + event_name + "' has " + str(subscriber_count) + " subscribers")
	
	# Warn about too many total subscribers
	if total_subscribers > 100:
		_add_performance_warning("Total subscriber count is high: " + str(total_subscribers))
	
	# Warn about large event history
	if event_history.size() >= max_history_entries:
		_add_performance_warning("Event history at maximum size: " + str(max_history_entries))

func _add_performance_warning(warning: String) -> void:
	"""Add a performance warning"""
	if not _performance_warnings.has(warning):
		_performance_warnings.append(warning)
		if _performance_warnings.size() > _max_warnings:
			_performance_warnings.pop_front()
		
		# Publish performance warning event
		publish(PERFORMANCE_WARNING, {"warning": warning}, EventCategory.DEBUG)
		print("EventBus Performance Warning: ", warning)

func get_performance_warnings() -> Array[String]:
	"""Get current performance warnings"""
	return _performance_warnings.duplicate()

func clear_performance_warnings() -> void:
	"""Clear performance warnings"""
	_performance_warnings.clear()

# Event validation (for development)
func validate_event_data(event_name: String, data: Dictionary) -> bool:
	"""Validate event data structure (can be extended for specific events)"""
	# Basic validation - check for required fields based on event name
	match event_name:
		GAME_STATE_CHANGED:
			return data.has("new_state")
		SCREEN_CHANGED:
			return data.has("old_screen") and data.has("new_screen")
		CAMPAIGN_ACTION_EXECUTED:
			return data.has("action") and data.has("result")
		MEDIA_EVENT_TRIGGERED:
			return data.has("event")
		_:
			return true  # Unknown events are assumed valid

# Cleanup
func _exit_tree() -> void:
	"""Cleanup when EventBus is destroyed"""
	# Clear all subscriptions
	subscribers.clear()
	event_history.clear()
	_performance_warnings.clear()
	
	# Autoload cleanup handled by Godot
	
	print("EventBus: Cleaned up")
