extends Node

# Advanced undo/redo system for safe user actions
# Provides granular state management with action grouping and selective undo

# Singleton instance
static var _instance: UndoRedoManager

# Dependencies
var game_state_manager: GameStateManager
var event_bus: EventBus

# Undo/Redo State
class ActionEntry:
	var id: String
	var description: String
	var timestamp: float
	var action_type: String
	var before_state: Dictionary
	var after_state: Dictionary
	var is_grouped: bool
	var group_id: String
	var is_safe_to_undo: bool
	var metadata: Dictionary
	
	func _init():
		id = ""
		description = ""
		timestamp = Time.get_unix_time_from_system()
		action_type = ""
		before_state = {}
		after_state = {}
		is_grouped = false
		group_id = ""
		is_safe_to_undo = true
		metadata = {}

var action_history: Array[ActionEntry] = []
var current_position: int = -1  # Position in history (-1 = no actions)
var max_history_size: int = 100
var current_group_id: String = ""
var grouping_enabled: bool = false

# Action categories that are safe to undo
var safe_action_types: Array[String] = [
	"campaign_action",
	"policy_change",
	"media_response",
	"coalition_negotiation",
	"resource_allocation"
]

# Actions that should not be undone
var unsafe_action_types: Array[String] = [
	"election_trigger",
	"save_game",
	"load_game",
	"time_advancement"  # Can be made safe with special handling
]

# Signals
signal action_recorded(action: ActionEntry)
signal undo_performed(action: ActionEntry)
signal redo_performed(action: ActionEntry)
signal history_changed(can_undo: bool, can_redo: bool)
signal group_started(group_id: String)
signal group_ended(group_id: String, action_count: int)

func _ready() -> void:
	# Initialize singleton
	if _instance == null:
		_instance = self
		process_mode = Node.PROCESS_MODE_ALWAYS
		
		# Initialize dependencies
		_initialize_dependencies()
		
		# Setup event listeners
		_setup_event_listeners()
	else:
		queue_free()

static func get_instance() -> UndoRedoManager:
	"""Get singleton instance of UndoRedoManager"""
	if _instance == null:
		# Create instance if it doesn't exist
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree:
			_instance = UndoRedoManager.new()
			scene_tree.root.add_child(_instance)
	return _instance

func _initialize_dependencies() -> void:
	"""Initialize references to required managers"""
	game_state_manager = GameStateManager.get_instance()
	event_bus = EventBus.get_instance()
	
	print("UndoRedoManager: Dependencies initialized")

func _setup_event_listeners() -> void:
	"""Setup listeners for state changes"""
	# Listen for game state changes to record actions
	if game_state_manager:
		game_state_manager.game_state_changed.connect(_on_game_state_changed)
	
	# Listen for campaign actions through event bus
	if event_bus:
		event_bus.subscribe(EventBus.CAMPAIGN_ACTION_EXECUTED, _on_campaign_action_executed)

# Core undo/redo functionality
func record_action(description: String, action_type: String, before_state: GameState, after_state: GameState, metadata: Dictionary = {}) -> String:
	"""Record an action for potential undo/redo"""
	var action = ActionEntry.new()
	action.id = _generate_action_id()
	action.description = description
	action.action_type = action_type
	action.before_state = before_state.serialize() if before_state else {}
	action.after_state = after_state.serialize() if after_state else {}
	action.is_safe_to_undo = _is_action_safe_to_undo(action_type)
	action.metadata = metadata.duplicate(true)
	
	# Handle grouping
	if grouping_enabled and not current_group_id.is_empty():
		action.is_grouped = true
		action.group_id = current_group_id
	
	# Clear any redo history when recording new action
	if current_position < action_history.size() - 1:
		# Remove everything after current position
		var actions_to_remove = action_history.slice(current_position + 1)
		for i in range(actions_to_remove.size()):
			action_history.pop_back()
	
	# Add new action
	action_history.append(action)
	current_position = action_history.size() - 1
	
	# Limit history size
	if action_history.size() > max_history_size:
		action_history.pop_front()
		current_position -= 1
	
	# Emit signals
	action_recorded.emit(action)
	history_changed.emit(can_undo(), can_redo())
	
	print("UndoRedoManager: Recorded action: ", description)
	return action.id

func undo() -> bool:
	"""Undo the last action"""
	if not can_undo():
		return false
	
	var action = action_history[current_position]
	
	# Check if action is safe to undo
	if not action.is_safe_to_undo:
		print("UndoRedoManager: Action not safe to undo: ", action.description)
		return false
	
	# Handle grouped actions
	if action.is_grouped:
		return _undo_action_group(action.group_id)
	else:
		return _undo_single_action(action)

func redo() -> bool:
	"""Redo the next action"""
	if not can_redo():
		return false
	
	var action = action_history[current_position + 1]
	
	# Handle grouped actions
	if action.is_grouped:
		return _redo_action_group(action.group_id)
	else:
		return _redo_single_action(action)

func can_undo() -> bool:
	"""Check if undo is possible"""
	return current_position >= 0

func can_redo() -> bool:
	"""Check if redo is possible"""
	return current_position < action_history.size() - 1

func _undo_single_action(action: ActionEntry) -> bool:
	"""Undo a single action"""
	# Restore previous state
	if action.before_state.size() > 0:
		var previous_state = GameState.new()
		if previous_state.deserialize(action.before_state):
			# Temporarily disable action recording to avoid recording the undo itself
			var original_position = current_position
			current_position -= 1
			
			# Update game state
			game_state_manager.update_game_state(previous_state, "Undo: " + action.description)
			
			# Restore position after state update
			current_position = original_position - 1
			
			# Emit signals
			undo_performed.emit(action)
			history_changed.emit(can_undo(), can_redo())
			
			print("UndoRedoManager: Undid action: ", action.description)
			return true
	
	return false

func _redo_single_action(action: ActionEntry) -> bool:
	"""Redo a single action"""
	# Restore next state
	if action.after_state.size() > 0:
		var next_state = GameState.new()
		if next_state.deserialize(action.after_state):
			# Temporarily adjust position
			current_position += 1
			
			# Update game state
			game_state_manager.update_game_state(next_state, "Redo: " + action.description)
			
			# Emit signals
			redo_performed.emit(action)
			history_changed.emit(can_undo(), can_redo())
			
			print("UndoRedoManager: Redid action: ", action.description)
			return true
	
	return false

func _undo_action_group(group_id: String) -> bool:
	"""Undo a group of actions"""
	var group_actions = _get_actions_in_group(group_id)
	if group_actions.is_empty():
		return false
	
	# Find the first action in the group to get the before state
	var first_action = group_actions[0]
	if first_action.before_state.size() > 0:
		var previous_state = GameState.new()
		if previous_state.deserialize(first_action.before_state):
			# Move position back by the number of actions in the group
			current_position -= group_actions.size()
			
			# Update game state
			game_state_manager.update_game_state(previous_state, "Undo group: " + group_id)
			
			# Emit signals for all actions in group
			for action in group_actions:
				undo_performed.emit(action)
			
			history_changed.emit(can_undo(), can_redo())
			print("UndoRedoManager: Undid action group: ", group_id)
			return true
	
	return false

func _redo_action_group(group_id: String) -> bool:
	"""Redo a group of actions"""
	var group_actions = _get_actions_in_group_for_redo(group_id)
	if group_actions.is_empty():
		return false
	
	# Find the last action in the group to get the after state
	var last_action = group_actions[-1]
	if last_action.after_state.size() > 0:
		var next_state = GameState.new()
		if next_state.deserialize(last_action.after_state):
			# Move position forward by the number of actions in the group
			current_position += group_actions.size()
			
			# Update game state
			game_state_manager.update_game_state(next_state, "Redo group: " + group_id)
			
			# Emit signals for all actions in group
			for action in group_actions:
				redo_performed.emit(action)
			
			history_changed.emit(can_undo(), can_redo())
			print("UndoRedoManager: Redid action group: ", group_id)
			return true
	
	return false

# Action grouping
func start_action_group(group_description: String) -> String:
	"""Start grouping actions together"""
	current_group_id = _generate_group_id(group_description)
	grouping_enabled = true
	
	group_started.emit(current_group_id)
	print("UndoRedoManager: Started action group: ", current_group_id)
	return current_group_id

func end_action_group() -> int:
	"""End action grouping and return number of actions in group"""
	if current_group_id.is_empty():
		return 0
	
	var group_actions = _get_actions_in_group(current_group_id)
	var action_count = group_actions.size()
	
	group_ended.emit(current_group_id, action_count)
	print("UndoRedoManager: Ended action group: ", current_group_id, " (", action_count, " actions)")
	
	current_group_id = ""
	grouping_enabled = false
	
	return action_count

# History management
func get_undo_description() -> String:
	"""Get description of action that would be undone"""
	if not can_undo():
		return ""
	
	var action = action_history[current_position]
	if action.is_grouped:
		var group_actions = _get_actions_in_group(action.group_id)
		return "Undo group (" + str(group_actions.size()) + " actions)"
	else:
		return "Undo: " + action.description

func get_redo_description() -> String:
	"""Get description of action that would be redone"""
	if not can_redo():
		return ""
	
	var action = action_history[current_position + 1]
	if action.is_grouped:
		var group_actions = _get_actions_in_group_for_redo(action.group_id)
		return "Redo group (" + str(group_actions.size()) + " actions)"
	else:
		return "Redo: " + action.description

func get_action_history(max_count: int = 20) -> Array[Dictionary]:
	"""Get recent action history for UI display"""
	var history_info: Array[Dictionary] = []
	var start_index = max(0, current_position - max_count + 1)
	
	for i in range(start_index, min(current_position + 1, action_history.size())):
		var action = action_history[i]
		history_info.append({
			"description": action.description,
			"action_type": action.action_type,
			"timestamp": action.timestamp,
			"is_grouped": action.is_grouped,
			"group_id": action.group_id,
			"can_undo": action.is_safe_to_undo
		})
	
	return history_info

func clear_history() -> void:
	"""Clear all undo/redo history"""
	action_history.clear()
	current_position = -1
	current_group_id = ""
	grouping_enabled = false
	
	history_changed.emit(false, false)
	print("UndoRedoManager: History cleared")

# Helper functions
func _is_action_safe_to_undo(action_type: String) -> bool:
	"""Check if an action type is safe to undo"""
	if action_type in unsafe_action_types:
		return false
	return action_type in safe_action_types or action_type.begins_with("user_")

func _get_actions_in_group(group_id: String) -> Array[ActionEntry]:
	"""Get all actions in a group (for undo - reverse order)"""
	var group_actions: Array[ActionEntry] = []
	
	# Find actions in group from current position backwards
	for i in range(current_position, -1, -1):
		var action = action_history[i]
		if action.group_id == group_id:
			group_actions.append(action)
		else:
			break  # Stop when we leave the group
	
	return group_actions

func _get_actions_in_group_for_redo(group_id: String) -> Array[ActionEntry]:
	"""Get all actions in a group (for redo - forward order)"""
	var group_actions: Array[ActionEntry] = []
	
	# Find actions in group from current position + 1 forwards
	for i in range(current_position + 1, action_history.size()):
		var action = action_history[i]
		if action.group_id == group_id:
			group_actions.append(action)
		else:
			break  # Stop when we leave the group
	
	return group_actions

func _generate_action_id() -> String:
	"""Generate unique action ID"""
	return "action_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func _generate_group_id(description: String) -> String:
	"""Generate unique group ID"""
	return "group_" + description.to_snake_case() + "_" + str(Time.get_unix_time_from_system())

# Event handlers
func _on_game_state_changed(new_state: GameState) -> void:
	"""Handle game state changes from GameStateManager"""
	# This is called after the state has already changed
	# We rely on explicit calls to record_action for better control
	pass

func _on_campaign_action_executed(data: Dictionary) -> void:
	"""Handle campaign action execution events"""
	if data.has("action") and data.has("result"):
		var action = data.action as CampaignAction
		var result = data.result as Dictionary
		
		# Record the action if it was successful and has before/after states
		if result.get("success", false) and result.has("before_state") and result.has("after_state"):
			record_action(
				"Campaign action: " + action.action_type,
				"campaign_action",
				result.before_state,
				result.after_state,
				{"action_details": action.serialize()}
			)

# Selective undo functionality
func undo_specific_action(action_id: String) -> bool:
	"""Undo a specific action (advanced feature)"""
	var action_index = _find_action_index(action_id)
	if action_index == -1:
		return false
	
	var action = action_history[action_index]
	if not action.is_safe_to_undo:
		return false
	
	# This is complex - would need to recalculate all states after this action
	# For now, only allow if it's the most recent action
	if action_index == current_position:
		return undo()
	
	print("UndoRedoManager: Selective undo not implemented for non-recent actions")
	return false

func _find_action_index(action_id: String) -> int:
	"""Find index of action by ID"""
	for i in range(action_history.size()):
		if action_history[i].id == action_id:
			return i
	return -1

# Debug and monitoring
func get_undo_system_info() -> Dictionary:
	"""Get information about the undo system"""
	return {
		"history_size": action_history.size(),
		"current_position": current_position,
		"can_undo": can_undo(),
		"can_redo": can_redo(),
		"grouping_enabled": grouping_enabled,
		"current_group": current_group_id,
		"max_history_size": max_history_size
	}

func print_history_debug() -> void:
	"""Print debug information about action history"""
	print("=== UndoRedoManager History Debug ===")
	print("History size: ", action_history.size())
	print("Current position: ", current_position)
	print("Can undo: ", can_undo())
	print("Can redo: ", can_redo())
	
	for i in range(action_history.size()):
		var action = action_history[i]
		var marker = " -> " if i == current_position else "    "
		print(marker, i, ": ", action.description, " (", action.action_type, ")")
	
	print("===================================")

# Cleanup
func _exit_tree() -> void:
	"""Cleanup when manager is destroyed"""
	# Unsubscribe from events
	if event_bus:
		event_bus.unsubscribe_all(self)
	
	# Clear history
	action_history.clear()
	
	# Clear singleton reference
	if _instance == self:
		_instance = null
	
	print("UndoRedoManager: Cleaned up")
