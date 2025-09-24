extends Node
class_name SimulationIntegration

# Integration layer between simulation API and UI controllers
# Handles data transformation, event coordination, and state synchronization

# Singleton instance
static var _instance: SimulationIntegration

# Dependencies
var game_state_manager: GameStateManager
var ui_state_manager: UIStateManager
var event_bus: EventBus
var simulation_api: SimulationAPI

# Integration state
var is_connected: bool = false
var last_sync_timestamp: float = 0.0
var pending_actions: Array[Dictionary] = []
var action_results_cache: Dictionary = {}

# Synchronization settings
var auto_sync_enabled: bool = true
var sync_interval: float = 1.0  # seconds
var max_pending_actions: int = 10

func _ready() -> void:
	# Initialize singleton
	if _instance == null:
		_instance = self
		process_mode = Node.PROCESS_MODE_ALWAYS
		
		# Get manager references
		_initialize_dependencies()
		
		# Setup integration
		_setup_integration()
		
		# Start sync timer
		_setup_sync_timer()
	else:
		queue_free()

static func get_instance() -> SimulationIntegration:
	"""Get singleton instance of SimulationIntegration"""
	if _instance == null:
		# Create instance if it doesn't exist
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree:
			_instance = SimulationIntegration.new()
			scene_tree.root.add_child(_instance)
	return _instance

func _initialize_dependencies() -> void:
	"""Initialize references to required managers"""
	game_state_manager = GameStateManager.get_instance()
	ui_state_manager = UIStateManager.get_instance()
	event_bus = EventBus.get_instance()
	
	# Initialize simulation API (using stub for now)
	simulation_api = FakeSimulation.new()
	
	print("SimulationIntegration: Dependencies initialized")

func _setup_integration() -> void:
	"""Setup integration between systems"""
	# Connect to EventBus events
	event_bus.subscribe(EventBus.GAME_STATE_CHANGED, _on_game_state_changed)
	event_bus.subscribe(EventBus.CAMPAIGN_ACTION_EXECUTED, _on_campaign_action_executed)
	event_bus.subscribe(EventBus.SCREEN_CHANGED, _on_screen_changed)
	
	# Connect to GameStateManager signals
	game_state_manager.game_state_changed.connect(_on_game_state_updated)
	game_state_manager.game_initialized.connect(_on_game_initialized)
	
	is_connected = true
	print("SimulationIntegration: Integration setup complete")

func _setup_sync_timer() -> void:
	"""Setup automatic synchronization timer"""
	if auto_sync_enabled:
		var timer = Timer.new()
		timer.wait_time = sync_interval
		timer.autostart = true
		timer.timeout.connect(_on_sync_timer)
		add_child(timer)

# Core integration functions
func execute_campaign_action(action: CampaignAction, source_controller: String = "") -> Dictionary:
	"""Execute a campaign action through the simulation API with UI integration"""
	if not is_connected or not simulation_api:
		return {"success": false, "error": "Integration not ready"}
	
	print("SimulationIntegration: Executing campaign action: ", action.action_type)
	
	# Add to pending actions queue
	var action_data = {
		"action": action,
		"source_controller": source_controller,
		"timestamp": Time.get_unix_time_from_system(),
		"id": _generate_action_id()
	}
	
	_add_pending_action(action_data)
	
	# Get current game state
	var current_state = game_state_manager.get_current_state()
	if not current_state:
		return {"success": false, "error": "No game state available"}
	
	# Process action through simulation API
	var result = simulation_api.process_campaign_action(action)
	
	# Handle result
	if result.success:
		# Update game state through manager
		game_state_manager.update_game_state(result.new_game_state, "Action: " + action.action_type)
		
		# Cache result for UI controllers
		_cache_action_result(action_data.id, result)
		
		# Notify UI controllers through event bus
		event_bus.publish_campaign_action(action, result)
		
		# Remove from pending actions
		_remove_pending_action(action_data.id)
		
		print("SimulationIntegration: Campaign action executed successfully")
	else:
		print("SimulationIntegration: Campaign action failed: ", result.get("error", "Unknown error"))
	
	return result

func advance_game_time(days: int) -> Dictionary:
	"""Advance game time with UI synchronization"""
	if not is_connected or not simulation_api:
		return {"success": false, "error": "Integration not ready"}
	
	var current_state = game_state_manager.get_current_state()
	if not current_state:
		return {"success": false, "error": "No game state available"}
	
	# Process time advancement
	var result = simulation_api.advance_time(current_state, days)
	
	if result.success:
		# Update game state
		game_state_manager.update_game_state(result.new_game_state, "Time advanced: +" + str(days) + " days")
		
		# Publish time advancement event
		event_bus.publish(EventBus.TIME_ADVANCED, {
			"days_advanced": days,
			"new_date": result.new_game_state.current_date,
			"events_triggered": result.get("triggered_events", [])
		}, EventBus.EventCategory.SIMULATION)
	
	return result

func trigger_media_event(event_data: Dictionary) -> MediaEvent:
	"""Trigger a media event with UI coordination"""
	if not simulation_api:
		return null
	
	# Generate media event through simulation
	var media_event = simulation_api.generate_media_event(event_data)
	
	if media_event:
		# Publish media event through event bus
		event_bus.publish_media_event(media_event)
		
		# Update UI state to show media event screen
		if ui_state_manager:
			ui_state_manager.save_media_event_state(
				media_event.serialize(),
				[]  # Empty response history for new event
			)
	
	return media_event

func get_current_opinion_polls() -> Array[OpinionPoll]:
	"""Get current opinion polls with caching"""
	if not simulation_api:
		return []
	
	var current_state = game_state_manager.get_current_state()
	if not current_state:
		return []
	
	return simulation_api.get_current_polls(current_state)

func get_available_campaign_actions() -> Array[CampaignAction]:
	"""Get available campaign actions for current state"""
	if not simulation_api:
		return []
	
	var current_state = game_state_manager.get_current_state()
	if not current_state:
		return []
	
	return simulation_api.get_available_actions(current_state)

# Event handlers
func _on_game_state_changed(data: Dictionary) -> void:
	"""Handle game state changes from EventBus"""
	if data.has("new_state"):
		last_sync_timestamp = Time.get_unix_time_from_system()
		# Trigger UI updates through specific events
		_broadcast_state_updates(data.new_state)

func _on_campaign_action_executed(data: Dictionary) -> void:
	"""Handle campaign action execution events"""
	if data.has("action") and data.has("result"):
		# Update UI controllers with action results
		_notify_controllers_of_action_result(data.action, data.result)

func _on_screen_changed(data: Dictionary) -> void:
	"""Handle screen changes to optimize data loading"""
	if data.has("new_screen"):
		_preload_screen_data(data.new_screen)

func _on_game_state_updated(new_state: GameState) -> void:
	"""Handle game state updates from GameStateManager"""
	if simulation_api:
		simulation_api.update_game_state(new_state)

func _on_game_initialized(game_state: GameState) -> void:
	"""Handle game initialization"""
	if simulation_api:
		simulation_api.initialize_game_state(game_state)
	
	# Clear any cached data from previous games
	action_results_cache.clear()
	pending_actions.clear()

# Data transformation and broadcasting
func _broadcast_state_updates(game_state: GameState) -> void:
	"""Broadcast specific state updates to interested UI components"""
	# Publish opinion poll updates
	var polls = get_current_opinion_polls()
	if polls.size() > 0:
		event_bus.publish(EventBus.OPINION_POLL_UPDATED, {
			"polls": polls,
			"timestamp": Time.get_unix_time_from_system()
		}, EventBus.EventCategory.SIMULATION)
	
	# Check for election triggers
	if _should_trigger_election(game_state):
		event_bus.publish(EventBus.ELECTION_TRIGGERED, {
			"election_date": game_state.next_election_date,
			"current_date": game_state.current_date
		}, EventBus.EventCategory.SIMULATION)

func _should_trigger_election(game_state: GameState) -> bool:
	"""Check if election should be triggered based on game state"""
	if not game_state.next_election_date or not game_state.current_date:
		return false
	
	# Simple date comparison - would be more sophisticated in real implementation
	return game_state.current_date >= game_state.next_election_date

func _notify_controllers_of_action_result(action: CampaignAction, result: Dictionary) -> void:
	"""Notify specific controllers about action results"""
	# Publish targeted events based on action type
	match action.action_type:
		"campaign_rally":
			event_bus.publish("rally_completed", {
				"location": action.target_region,
				"impact": result.get("polling_impact", {})
			}, EventBus.EventCategory.USER_ACTION)
		"media_campaign":
			event_bus.publish("media_campaign_completed", {
				"medium": action.parameters.get("medium", ""),
				"reach": result.get("reach", 0)
			}, EventBus.EventCategory.USER_ACTION)
		"policy_announcement":
			event_bus.publish("policy_announced", {
				"policy": action.parameters.get("policy", ""),
				"reaction": result.get("public_reaction", {})
			}, EventBus.EventCategory.USER_ACTION)

func _preload_screen_data(screen_name: String) -> void:
	"""Preload data for specific screens to improve performance"""
	if not simulation_api:
		return
	
	match screen_name:
		"Dashboard":
			# Preload dashboard data
			var polls = get_current_opinion_polls()
			var actions = get_available_campaign_actions()
			# Cache for quick access
			_cache_screen_data("Dashboard", {
				"polls": polls,
				"available_actions": actions
			})
		
		"MapView":
			# Preload regional data
			var regional_data = _get_regional_data()
			_cache_screen_data("MapView", {"regional_data": regional_data})
		
		"CoalitionBuilder":
			# Preload party compatibility data
			var compatibility_data = _get_party_compatibility_data()
			_cache_screen_data("CoalitionBuilder", {"compatibility_data": compatibility_data})

# Caching and performance
var screen_data_cache: Dictionary = {}
var cache_expiry_time: float = 30.0  # 30 seconds

func _cache_screen_data(screen_name: String, data: Dictionary) -> void:
	"""Cache screen-specific data with timestamp"""
	screen_data_cache[screen_name] = {
		"data": data,
		"timestamp": Time.get_unix_time_from_system()
	}

func get_cached_screen_data(screen_name: String) -> Dictionary:
	"""Get cached screen data if still valid"""
	if not screen_data_cache.has(screen_name):
		return {}
	
	var cached = screen_data_cache[screen_name]
	var age = Time.get_unix_time_from_system() - cached.timestamp
	
	if age < cache_expiry_time:
		return cached.data
	else:
		# Cache expired, remove it
		screen_data_cache.erase(screen_name)
		return {}

func _clear_expired_cache() -> void:
	"""Clear expired cache entries"""
	var current_time = Time.get_unix_time_from_system()
	var keys_to_remove: Array[String] = []
	
	for screen_name in screen_data_cache.keys():
		var cached = screen_data_cache[screen_name]
		var age = current_time - cached.timestamp
		
		if age >= cache_expiry_time:
			keys_to_remove.append(screen_name)
	
	for key in keys_to_remove:
		screen_data_cache.erase(key)

# Helper functions for data retrieval
func _get_regional_data() -> Dictionary:
	"""Get regional polling and demographic data"""
	if not simulation_api:
		return {}
	
	var current_state = game_state_manager.get_current_state()
	if not current_state:
		return {}
	
	return simulation_api.get_regional_breakdown(current_state)

func _get_party_compatibility_data() -> Dictionary:
	"""Get party compatibility matrix for coalition building"""
	if not simulation_api:
		return {}
	
	var current_state = game_state_manager.get_current_state()
	if not current_state:
		return {}
	
	return simulation_api.calculate_party_compatibility_matrix(current_state)

# Action queue management
func _add_pending_action(action_data: Dictionary) -> void:
	"""Add action to pending queue with size limit"""
	pending_actions.append(action_data)
	
	# Limit queue size
	if pending_actions.size() > max_pending_actions:
		pending_actions.pop_front()

func _remove_pending_action(action_id: String) -> void:
	"""Remove action from pending queue"""
	for i in range(pending_actions.size()):
		if pending_actions[i].id == action_id:
			pending_actions.remove_at(i)
			break

func _generate_action_id() -> String:
	"""Generate unique ID for action tracking"""
	return "action_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func _cache_action_result(action_id: String, result: Dictionary) -> void:
	"""Cache action result for retrieval by UI controllers"""
	action_results_cache[action_id] = {
		"result": result,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# Limit cache size
	if action_results_cache.size() > 50:
		# Remove oldest entries
		var oldest_key = ""
		var oldest_time = Time.get_unix_time_from_system()
		
		for key in action_results_cache.keys():
			var timestamp = action_results_cache[key].timestamp
			if timestamp < oldest_time:
				oldest_time = timestamp
				oldest_key = key
		
		if not oldest_key.is_empty():
			action_results_cache.erase(oldest_key)

# Synchronization
func _on_sync_timer() -> void:
	"""Handle periodic synchronization"""
	if auto_sync_enabled:
		# Clear expired cache
		_clear_expired_cache()
		
		# Process any pending actions
		_process_pending_actions()
		
		# Update last sync time
		last_sync_timestamp = Time.get_unix_time_from_system()

func _process_pending_actions() -> void:
	"""Process any actions that might be stuck in the queue"""
	# For now, just report if there are old pending actions
	var current_time = Time.get_unix_time_from_system()
	for action_data in pending_actions:
		var age = current_time - action_data.timestamp
		if age > 10.0:  # Actions older than 10 seconds
			print("SimulationIntegration: Warning - pending action older than 10 seconds: ", action_data.action.action_type)

# Debug and monitoring
func get_integration_status() -> Dictionary:
	"""Get status information for debugging"""
	return {
		"connected": is_connected,
		"simulation_api_active": simulation_api != null,
		"pending_actions": pending_actions.size(),
		"cached_results": action_results_cache.size(),
		"cached_screens": screen_data_cache.size(),
		"last_sync": last_sync_timestamp
	}

# Cleanup
func _exit_tree() -> void:
	"""Cleanup when integration is destroyed"""
	# Unsubscribe from events
	if event_bus:
		event_bus.unsubscribe_all(self)
	
	# Clear caches
	action_results_cache.clear()
	screen_data_cache.clear()
	pending_actions.clear()
	
	# Clear singleton reference
	if _instance == self:
		_instance = null
	
	print("SimulationIntegration: Cleaned up")
