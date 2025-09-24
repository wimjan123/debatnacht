extends Node
class_name ObjectPool

# Object pooling system for performance optimization
# Manages reusable UI elements like tooltips, notifications, and temporary components

# Singleton instance
static var _instance: ObjectPool

# Pool configuration
class PoolConfig:
	var initial_size: int
	var max_size: int
	var auto_grow: bool
	var cleanup_interval: float
	var scene_path: String
	var factory_function: Callable
	
	func _init(init_size: int = 5, maximum: int = 20, grow: bool = true, cleanup: float = 60.0):
		initial_size = init_size
		max_size = maximum
		auto_grow = grow
		cleanup_interval = cleanup
		scene_path = ""
		factory_function = Callable()

# Pool storage
var pools: Dictionary = {}  # pool_name -> PoolData
var active_objects: Dictionary = {}  # pool_name -> Array[Node]
var pool_stats: Dictionary = {}  # pool_name -> usage statistics

# Pool data structure
class PoolData:
	var available_objects: Array[Node] = []
	var config: PoolConfig
	var total_created: int = 0
	var peak_usage: int = 0
	var last_cleanup: float = 0.0
	
	func _init(pool_config: PoolConfig):
		config = pool_config
		last_cleanup = Time.get_unix_time_from_system()

# Common pool names
const TOOLTIP_POOL = "tooltips"
const NOTIFICATION_POOL = "notifications"
const PARTICLE_POOL = "particles"
const UI_ELEMENT_POOL = "ui_elements"
const BUTTON_POOL = "buttons"
const LABEL_POOL = "labels"
const ANIMATION_POOL = "animations"

# Performance settings
var enable_debug_logging: bool = false
var auto_cleanup_enabled: bool = true
var global_cleanup_interval: float = 30.0
var max_total_pooled_objects: int = 500

func _ready() -> void:
	# Initialize singleton
	if _instance == null:
		_instance = self
		process_mode = Node.PROCESS_MODE_ALWAYS
		
		# Initialize default pools
		_initialize_default_pools()
		
		# Setup cleanup timer
		_setup_cleanup_timer()
	else:
		queue_free()

static func get_instance() -> ObjectPool:
	"""Get singleton instance of ObjectPool"""
	if _instance == null:
		# Create instance if it doesn't exist
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree:
			_instance = ObjectPool.new()
			scene_tree.root.add_child(_instance)
	return _instance

func _initialize_default_pools() -> void:
	"""Initialize commonly used object pools"""
	# Tooltip pool
	create_pool(TOOLTIP_POOL, PoolConfig.new(3, 10, true, 60.0))
	set_pool_factory(TOOLTIP_POOL, _create_tooltip)
	
	# Notification pool
	create_pool(NOTIFICATION_POOL, PoolConfig.new(2, 8, true, 30.0))
	set_pool_factory(NOTIFICATION_POOL, _create_notification)
	
	# UI element pool for dynamic content
	create_pool(UI_ELEMENT_POOL, PoolConfig.new(5, 20, true, 45.0))
	set_pool_factory(UI_ELEMENT_POOL, _create_ui_element)
	
	# Button pool for dynamic menus
	create_pool(BUTTON_POOL, PoolConfig.new(8, 25, true, 60.0))
	set_pool_factory(BUTTON_POOL, _create_button)
	
	# Label pool for dynamic text
	create_pool(LABEL_POOL, PoolConfig.new(10, 30, true, 60.0))
	set_pool_factory(LABEL_POOL, _create_label)
	
	print("ObjectPool: Default pools initialized")

func _setup_cleanup_timer() -> void:
	"""Setup automatic cleanup timer"""
	if auto_cleanup_enabled:
		var timer = Timer.new()
		timer.wait_time = global_cleanup_interval
		timer.autostart = true
		timer.timeout.connect(_on_cleanup_timer)
		add_child(timer)

# Core pooling functions
func create_pool(pool_name: String, config: PoolConfig) -> bool:
	"""Create a new object pool"""
	if pools.has(pool_name):
		print("ObjectPool: Pool already exists: ", pool_name)
		return false
	
	var pool_data = PoolData.new(config)
	pools[pool_name] = pool_data
	active_objects[pool_name] = []
	pool_stats[pool_name] = {
		"gets": 0,
		"returns": 0,
		"creates": 0,
		"destroys": 0
	}
	
	# Pre-populate pool
	_prepopulate_pool(pool_name)
	
	if enable_debug_logging:
		print("ObjectPool: Created pool '", pool_name, "' with initial size ", config.initial_size)
	
	return true

func set_pool_factory(pool_name: String, factory: Callable) -> bool:
	"""Set factory function for a pool"""
	if not pools.has(pool_name):
		return false
	
	var pool_data = pools[pool_name] as PoolData
	pool_data.config.factory_function = factory
	return true

func set_pool_scene(pool_name: String, scene_path: String) -> bool:
	"""Set scene file for a pool (alternative to factory function)"""
	if not pools.has(pool_name):
		return false
	
	var pool_data = pools[pool_name] as PoolData
	pool_data.config.scene_path = scene_path
	return true

func get_object(pool_name: String) -> Node:
	"""Get an object from the pool"""
	if not pools.has(pool_name):
		print("ObjectPool: Pool not found: ", pool_name)
		return null
	
	var pool_data = pools[pool_name] as PoolData
	var active_list = active_objects[pool_name] as Array
	
	# Update statistics
	pool_stats[pool_name].gets += 1
	
	# Try to get from available objects
	var obj: Node = null
	if pool_data.available_objects.size() > 0:
		obj = pool_data.available_objects.pop_back()
	else:
		# Create new object if pool allows growth
		if pool_data.config.auto_grow and _get_total_pooled_objects() < max_total_pooled_objects:
			obj = _create_pooled_object(pool_name)
			if obj:
				pool_data.total_created += 1
				pool_stats[pool_name].creates += 1
	
	if obj:
		# Add to active objects
		active_list.append(obj)
		pool_data.peak_usage = max(pool_data.peak_usage, active_list.size())
		
		# Activate object
		_activate_object(obj, pool_name)
		
		if enable_debug_logging:
			print("ObjectPool: Got object from pool '", pool_name, "' (active: ", active_list.size(), ")")
	
	return obj

func return_object(obj: Node, pool_name: String) -> bool:
	"""Return an object to the pool"""
	if not obj or not pools.has(pool_name):
		return false
	
	var pool_data = pools[pool_name] as PoolData
	var active_list = active_objects[pool_name] as Array
	
	# Remove from active objects
	var index = active_list.find(obj)
	if index == -1:
		print("ObjectPool: Object not found in active list for pool: ", pool_name)
		return false
	
	active_list.remove_at(index)
	pool_stats[pool_name].returns += 1
	
	# Check if pool is at capacity
	if pool_data.available_objects.size() >= pool_data.config.max_size:
		# Pool is full, destroy the object
		_destroy_object(obj, pool_name)
		pool_stats[pool_name].destroys += 1
	else:
		# Deactivate and return to pool
		_deactivate_object(obj, pool_name)
		pool_data.available_objects.append(obj)
	
	if enable_debug_logging:
		print("ObjectPool: Returned object to pool '", pool_name, "' (available: ", pool_data.available_objects.size(), ")")
	
	return true

# Object lifecycle management
func _create_pooled_object(pool_name: String) -> Node:
	"""Create a new pooled object"""
	var pool_data = pools[pool_name] as PoolData
	var config = pool_data.config
	
	# Try factory function first
	if config.factory_function.is_valid():
		return config.factory_function.call()
	
	# Try scene path
	if not config.scene_path.is_empty() and ResourceLoader.exists(config.scene_path):
		var scene = load(config.scene_path) as PackedScene
		if scene:
			return scene.instantiate()
	
	print("ObjectPool: No factory or scene configured for pool: ", pool_name)
	return null

func _activate_object(obj: Node, pool_name: String) -> void:
	"""Activate an object when taken from pool"""
	# Reset object state
	if obj.has_method("reset_pooled_object"):
		obj.reset_pooled_object()
	
	# Make visible and enabled
	if obj.has_method("set_visible"):
		obj.set_visible(true)
	
	if obj.has_method("set_process_mode"):
		obj.set_process_mode(Node.PROCESS_MODE_INHERIT)
	
	# Add metadata
	obj.set_meta("_pool_name", pool_name)
	obj.set_meta("_pooled", true)

func _deactivate_object(obj: Node, pool_name: String) -> void:
	"""Deactivate an object when returned to pool"""
	# Clean up object state
	if obj.has_method("cleanup_pooled_object"):
		obj.cleanup_pooled_object()
	
	# Disconnect signals
	if obj.has_method("disconnect_all_signals"):
		obj.disconnect_all_signals()
	
	# Hide and disable
	if obj.has_method("set_visible"):
		obj.set_visible(false)
	
	if obj.has_method("set_process_mode"):
		obj.set_process_mode(Node.PROCESS_MODE_DISABLED)
	
	# Remove from parent if attached
	if obj.get_parent():
		obj.get_parent().remove_child(obj)

func _destroy_object(obj: Node, pool_name: String) -> void:
	"""Destroy an object permanently"""
	if obj:
		_deactivate_object(obj, pool_name)
		obj.queue_free()

func _prepopulate_pool(pool_name: String) -> void:
	"""Pre-populate a pool with initial objects"""
	var pool_data = pools[pool_name] as PoolData
	
	for i in range(pool_data.config.initial_size):
		var obj = _create_pooled_object(pool_name)
		if obj:
			_deactivate_object(obj, pool_name)
			pool_data.available_objects.append(obj)
			pool_data.total_created += 1

# Default factory functions
func _create_tooltip() -> Control:
	"""Create a tooltip control"""
	var tooltip = PanelContainer.new()
	tooltip.name = "PooledTooltip"
	
	# Add background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	style_box.corner_radius_bottom_left = 4
	style_box.corner_radius_bottom_right = 4
	tooltip.add_theme_stylebox_override("panel", style_box)
	
	# Add label
	var label = Label.new()
	label.name = "TooltipLabel"
	label.add_theme_color_override("font_color", Color.WHITE)
	tooltip.add_child(label)
	
	# Add pooled object interface
	tooltip.set_script(preload("res://presentation/pooled_objects/pooled_tooltip.gd"))
	
	return tooltip

func _create_notification() -> Control:
	"""Create a notification control"""
	var notification = PanelContainer.new()
	notification.name = "PooledNotification"
	
	# Add background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.6, 0.2, 0.9)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	notification.add_theme_stylebox_override("panel", style_box)
	
	# Add content container
	var vbox = VBoxContainer.new()
	notification.add_child(vbox)
	
	# Add title and message labels
	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title_label)
	
	var message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(message_label)
	
	return notification

func _create_ui_element() -> Control:
	"""Create a generic UI element"""
	var element = Control.new()
	element.name = "PooledUIElement"
	return element

func _create_button() -> Button:
	"""Create a button"""
	var button = Button.new()
	button.name = "PooledButton"
	return button

func _create_label() -> Label:
	"""Create a label"""
	var label = Label.new()
	label.name = "PooledLabel"
	return label

# Pool management
func clear_pool(pool_name: String) -> bool:
	"""Clear all objects from a pool"""
	if not pools.has(pool_name):
		return false
	
	var pool_data = pools[pool_name] as PoolData
	var active_list = active_objects[pool_name] as Array
	
	# Destroy all available objects
	for obj in pool_data.available_objects:
		_destroy_object(obj, pool_name)
	pool_data.available_objects.clear()
	
	# Force return active objects (dangerous - only use when necessary)
	var active_copy = active_list.duplicate()
	for obj in active_copy:
		return_object(obj, pool_name)
	
	if enable_debug_logging:
		print("ObjectPool: Cleared pool: ", pool_name)
	
	return true

func destroy_pool(pool_name: String) -> bool:
	"""Completely destroy a pool"""
	if not pools.has(pool_name):
		return false
	
	# Clear all objects first
	clear_pool(pool_name)
	
	# Remove pool data
	pools.erase(pool_name)
	active_objects.erase(pool_name)
	pool_stats.erase(pool_name)
	
	print("ObjectPool: Destroyed pool: ", pool_name)
	return true

# Utility functions
func get_pool_info(pool_name: String) -> Dictionary:
	"""Get information about a pool"""
	if not pools.has(pool_name):
		return {}
	
	var pool_data = pools[pool_name] as PoolData
	var active_list = active_objects[pool_name] as Array
	
	return {
		"available": pool_data.available_objects.size(),
		"active": active_list.size(),
		"total_created": pool_data.total_created,
		"peak_usage": pool_data.peak_usage,
		"max_size": pool_data.config.max_size,
		"auto_grow": pool_data.config.auto_grow,
		"statistics": pool_stats[pool_name]
	}

func get_all_pool_info() -> Dictionary:
	"""Get information about all pools"""
	var all_info = {}
	for pool_name in pools.keys():
		all_info[pool_name] = get_pool_info(pool_name)
	return all_info

func _get_total_pooled_objects() -> int:
	"""Get total number of pooled objects across all pools"""
	var total = 0
	for pool_name in pools.keys():
		var pool_data = pools[pool_name] as PoolData
		total += pool_data.available_objects.size()
		total += active_objects[pool_name].size()
	return total

func is_object_pooled(obj: Node) -> bool:
	"""Check if an object is from a pool"""
	return obj and obj.has_meta("_pooled")

func get_object_pool_name(obj: Node) -> String:
	"""Get the pool name for a pooled object"""
	if is_object_pooled(obj):
		return obj.get_meta("_pool_name", "")
	return ""

# Cleanup and maintenance
func _on_cleanup_timer() -> void:
	"""Handle periodic cleanup"""
	var current_time = Time.get_unix_time_from_system()
	
	for pool_name in pools.keys():
		var pool_data = pools[pool_name] as PoolData
		
		# Check if cleanup is needed for this pool
		if current_time - pool_data.last_cleanup >= pool_data.config.cleanup_interval:
			_cleanup_pool(pool_name)
			pool_data.last_cleanup = current_time

func _cleanup_pool(pool_name: String) -> void:
	"""Clean up a specific pool"""
	var pool_data = pools[pool_name] as PoolData
	var initial_size = pool_data.config.initial_size
	var available_count = pool_data.available_objects.size()
	
	# If we have more than initial size + 50%, remove excess
	var excess_threshold = initial_size + (initial_size / 2)
	if available_count > excess_threshold:
		var to_remove = available_count - initial_size
		for i in range(to_remove):
			if pool_data.available_objects.size() > 0:
				var obj = pool_data.available_objects.pop_back()
				_destroy_object(obj, pool_name)
				pool_stats[pool_name].destroys += 1
	
	if enable_debug_logging and to_remove > 0:
		print("ObjectPool: Cleaned up ", to_remove, " objects from pool: ", pool_name)

func force_cleanup_all() -> void:
	"""Force cleanup of all pools"""
	for pool_name in pools.keys():
		_cleanup_pool(pool_name)

func print_pool_statistics() -> void:
	"""Print statistics for all pools"""
	print("=== ObjectPool Statistics ===")
	print("Total pools: ", pools.size())
	print("Total pooled objects: ", _get_total_pooled_objects())
	
	for pool_name in pools.keys():
		var info = get_pool_info(pool_name)
		print("Pool '", pool_name, "':")
		print("  Available: ", info.available, ", Active: ", info.active)
		print("  Total created: ", info.total_created, ", Peak usage: ", info.peak_usage)
		print("  Stats - Gets: ", info.statistics.gets, ", Returns: ", info.statistics.returns)
	
	print("=============================")

# Cleanup
func _exit_tree() -> void:
	"""Cleanup when ObjectPool is destroyed"""
	# Clear all pools
	for pool_name in pools.keys():
		clear_pool(pool_name)
	
	# Clear all data
	pools.clear()
	active_objects.clear()
	pool_stats.clear()
	
	# Clear singleton reference
	if _instance == self:
		_instance = null
	
	print("ObjectPool: Cleaned up")
