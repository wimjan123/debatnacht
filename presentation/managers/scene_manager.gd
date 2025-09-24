extends Node
class_name SceneManager

# Scene loading optimization with preloading and caching for 60 FPS performance
# Handles scene transitions, preloading, and memory management for smooth UI experience

# Singleton instance
static var _instance: SceneManager

# Dependencies
var performance_monitor: PerformanceMonitor
var event_bus: EventBus

# Scene caching system
var cached_scenes: Dictionary = {}
var preloaded_scenes: Dictionary = {}
var scene_cache_limit: int = 5  # Limit to prevent memory bloat
var cache_access_order: Array[String] = []

# Loading state
var current_scene: Node = null
var loading_in_progress: bool = false
var load_thread: Thread = null
var load_mutex: Mutex = null
var scene_load_progress: Dictionary = {}

# Preload configuration - scenes to preload during startup
var preload_scenes: Dictionary = {
	"main_menu": "ui/scenes/main_menu/MainMenu.tscn",
	"dashboard": "ui/scenes/dashboard/Dashboard.tscn",
	"map_view": "ui/scenes/map_view/MapView.tscn",
	"settings": "ui/scenes/settings/Settings.tscn"
}

# Scene transition settings
var transition_fade_duration: float = 0.3
var background_load_enabled: bool = true
var preload_on_startup: bool = true

# Performance metrics
class SceneLoadMetrics:
	var scene_path: String
	var load_time: float
	var memory_before: int
	var memory_after: int
	var cache_hit: bool
	var timestamp: float

	func _init():
		timestamp = Time.get_unix_time_from_system()

var load_metrics_history: Array[SceneLoadMetrics] = []
var max_metrics_history: int = 50

# Signals
signal scene_load_started(scene_path: String)
signal scene_load_progress_updated(scene_path: String, progress: float)
signal scene_load_completed(scene_path: String, load_time: float)
signal scene_load_failed(scene_path: String, error: String)
signal scene_changed(old_scene: String, new_scene: String)
signal cache_updated(cached_count: int, memory_usage: int)

func _ready() -> void:
	# Initialize singleton
	if _instance == null:
		_instance = self
		process_mode = Node.PROCESS_MODE_ALWAYS

		# Initialize dependencies
		_initialize_dependencies()

		# Initialize threading resources
		load_mutex = Mutex.new()

		# Setup preloading if enabled
		if preload_on_startup:
			_start_preloading()

		print("SceneManager: Initialized with caching and preloading")
	else:
		queue_free()

static func get_instance() -> SceneManager:
	"""Get singleton instance of SceneManager"""
	if _instance == null:
		# Create instance if it doesn't exist
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree:
			_instance = SceneManager.new()
			scene_tree.root.add_child(_instance)
	return _instance

func _initialize_dependencies() -> void:
	"""Initialize references to required systems"""
	performance_monitor = PerformanceMonitor.get_instance()
	event_bus = EventBus.get_instance()

	# Listen for performance warnings to adjust loading behavior
	if performance_monitor:
		performance_monitor.performance_warning.connect(_on_performance_warning)

# Core scene loading functionality
func change_scene_to_file(scene_path: String, use_transition: bool = true) -> void:
	"""Change to scene with caching and optimization"""
	if loading_in_progress:
		print("SceneManager: Load already in progress, ignoring request for: ", scene_path)
		return

	loading_in_progress = true
	scene_load_started.emit(scene_path)

	var metrics = SceneLoadMetrics.new()
	metrics.scene_path = scene_path
	metrics.memory_before = _get_memory_usage()

	var start_time = Time.get_unix_time_from_system()

	# Check cache first
	var new_scene: Node = null
	if cached_scenes.has(scene_path):
		new_scene = cached_scenes[scene_path]
		metrics.cache_hit = true
		_update_cache_access_order(scene_path)
		print("SceneManager: Using cached scene: ", scene_path)
	else:
		# Load scene with error handling
		var packed_scene = _load_scene_safe(scene_path)
		if packed_scene:
			new_scene = packed_scene.instantiate()
			metrics.cache_hit = false

			# Add to cache if under limit
			if cached_scenes.size() < scene_cache_limit:
				_cache_scene(scene_path, new_scene)
		else:
			loading_in_progress = false
			scene_load_failed.emit(scene_path, "Failed to load scene file")
			return

	# Perform scene transition
	if use_transition:
		await _transition_to_scene(new_scene, scene_path)
	else:
		_switch_to_scene(new_scene, scene_path)

	# Record metrics
	metrics.load_time = Time.get_unix_time_from_system() - start_time
	metrics.memory_after = _get_memory_usage()
	load_metrics_history.append(metrics)

	if load_metrics_history.size() > max_metrics_history:
		load_metrics_history.pop_front()

	loading_in_progress = false
	scene_load_completed.emit(scene_path, metrics.load_time)

	print("SceneManager: Scene loaded - ", scene_path, " (", "%.2f" % (metrics.load_time * 1000), "ms)")

func preload_scene(scene_path: String) -> void:
	"""Preload a scene into memory for faster access"""
	if preloaded_scenes.has(scene_path) or cached_scenes.has(scene_path):
		return  # Already loaded

	if background_load_enabled and load_thread == null:
		# Background loading
		load_thread = Thread.new()
		load_thread.start(_background_preload.bind(scene_path))
	else:
		# Synchronous preload
		_preload_scene_sync(scene_path)

func _background_preload(scene_path: String) -> void:
	"""Background preload function for threading"""
	load_mutex.lock()

	var packed_scene = _load_scene_safe(scene_path)
	if packed_scene:
		preloaded_scenes[scene_path] = packed_scene
		print("SceneManager: Background preloaded: ", scene_path)

		# Emit progress update on main thread
		call_deferred("_emit_preload_progress", scene_path, 1.0)
	else:
		print("SceneManager: Failed to preload: ", scene_path)

	load_mutex.unlock()

	# Clean up thread
	call_deferred("_cleanup_load_thread")

func _preload_scene_sync(scene_path: String) -> void:
	"""Synchronous scene preloading"""
	var packed_scene = _load_scene_safe(scene_path)
	if packed_scene:
		preloaded_scenes[scene_path] = packed_scene
		print("SceneManager: Preloaded: ", scene_path)
	else:
		print("SceneManager: Failed to preload: ", scene_path)

func _load_scene_safe(scene_path: String) -> PackedScene:
	"""Safe scene loading with error handling"""
	if not ResourceLoader.exists(scene_path):
		print("SceneManager: Scene file not found: ", scene_path)
		return null

	var packed_scene = load(scene_path) as PackedScene
	if not packed_scene:
		print("SceneManager: Failed to load scene: ", scene_path)
		return null

	return packed_scene

# Scene transition system
func _transition_to_scene(new_scene: Node, scene_path: String) -> void:
	"""Perform smooth scene transition with fade"""
	var scene_tree = get_tree()

	# Create transition overlay
	var transition_layer = CanvasLayer.new()
	transition_layer.layer = 100  # Above everything else

	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.color.a = 0.0
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	transition_layer.add_child(fade_rect)
	scene_tree.root.add_child(transition_layer)

	# Fade out
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, transition_fade_duration / 2)
	await tween.finished

	# Switch scenes
	_switch_to_scene(new_scene, scene_path)

	# Fade in
	tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, transition_fade_duration / 2)
	await tween.finished

	# Cleanup transition
	transition_layer.queue_free()

func _switch_to_scene(new_scene: Node, scene_path: String) -> void:
	"""Switch to new scene immediately"""
	var scene_tree = get_tree()
	var old_scene_path = ""

	# Store reference to old scene
	if current_scene:
		old_scene_path = current_scene.scene_file_path

		# Remove old scene
		current_scene.queue_free()

	# Set new scene as current
	current_scene = new_scene
	scene_tree.root.add_child(new_scene)

	# Update scene tree current scene reference
	scene_tree.current_scene = new_scene

	# Emit scene change signal
	scene_changed.emit(old_scene_path, scene_path)

	# Publish event
	if event_bus:
		event_bus.publish(EventBus.SCENE_CHANGED, {
			"old_scene": old_scene_path,
			"new_scene": scene_path
		}, EventBus.EventCategory.UI)

# Cache management
func _cache_scene(scene_path: String, scene: Node) -> void:
	"""Add scene to cache with LRU eviction"""
	# Remove least recently used if at limit
	if cached_scenes.size() >= scene_cache_limit and cache_access_order.size() > 0:
		var lru_path = cache_access_order[0]
		_evict_from_cache(lru_path)

	# Add to cache
	cached_scenes[scene_path] = scene
	cache_access_order.append(scene_path)

	# Update cache metrics
	var memory_usage = _estimate_cache_memory_usage()
	cache_updated.emit(cached_scenes.size(), memory_usage)

func _update_cache_access_order(scene_path: String) -> void:
	"""Update LRU order for cache"""
	var index = cache_access_order.find(scene_path)
	if index != -1:
		cache_access_order.remove_at(index)
		cache_access_order.append(scene_path)

func _evict_from_cache(scene_path: String) -> void:
	"""Remove scene from cache"""
	if cached_scenes.has(scene_path):
		var scene = cached_scenes[scene_path]
		scene.queue_free()
		cached_scenes.erase(scene_path)

		var index = cache_access_order.find(scene_path)
		if index != -1:
			cache_access_order.remove_at(index)

		print("SceneManager: Evicted from cache: ", scene_path)

func clear_cache() -> void:
	"""Clear all cached scenes"""
	for scene_path in cached_scenes.keys():
		var scene = cached_scenes[scene_path]
		scene.queue_free()

	cached_scenes.clear()
	cache_access_order.clear()

	cache_updated.emit(0, 0)
	print("SceneManager: Cache cleared")

func clear_preloaded() -> void:
	"""Clear all preloaded scenes"""
	preloaded_scenes.clear()
	print("SceneManager: Preloaded scenes cleared")

# Startup preloading
func _start_preloading() -> void:
	"""Start preloading important scenes"""
	print("SceneManager: Starting scene preloading")

	for scene_name in preload_scenes.keys():
		var scene_path = preload_scenes[scene_name]
		preload_scene(scene_path)

		# Yield briefly to prevent frame drops
		await get_tree().process_frame

# Performance integration
func _on_performance_warning(level: PerformanceMonitor.PerformanceLevel, metrics: PerformanceMonitor.PerformanceMetrics) -> void:
	"""Handle performance warnings by adjusting loading behavior"""
	match level:
		PerformanceMonitor.PerformanceLevel.WARNING:
			# Reduce cache size to free memory
			if cached_scenes.size() > 3:
				_evict_oldest_cached_scenes(1)

		PerformanceMonitor.PerformanceLevel.CRITICAL:
			# Aggressive memory management
			if cached_scenes.size() > 2:
				_evict_oldest_cached_scenes(cached_scenes.size() - 2)

			# Disable background loading temporarily
			background_load_enabled = false

func _evict_oldest_cached_scenes(count: int) -> void:
	"""Evict oldest cached scenes for memory management"""
	var to_evict = min(count, cache_access_order.size())

	for i in range(to_evict):
		if cache_access_order.size() > 0:
			var scene_path = cache_access_order[0]
			_evict_from_cache(scene_path)

# Utility functions
func _get_memory_usage() -> int:
	"""Get current memory usage"""
	return OS.get_static_memory_usage(false)

func _estimate_cache_memory_usage() -> int:
	"""Estimate memory usage of cached scenes"""
	# Simplified estimation - would need more sophisticated measurement in production
	return cached_scenes.size() * 1024 * 1024  # Rough estimate: 1MB per scene

func _emit_preload_progress(scene_path: String, progress: float) -> void:
	"""Emit preload progress signal on main thread"""
	scene_load_progress_updated.emit(scene_path, progress)

func _cleanup_load_thread() -> void:
	"""Clean up completed load thread"""
	if load_thread and load_thread.is_started():
		load_thread.wait_to_finish()
		load_thread = null

# Public API
func get_cache_info() -> Dictionary:
	"""Get information about scene cache"""
	return {
		"cached_scenes": cached_scenes.keys(),
		"cache_size": cached_scenes.size(),
		"cache_limit": scene_cache_limit,
		"memory_estimate": _estimate_cache_memory_usage(),
		"access_order": cache_access_order.duplicate()
	}

func get_preload_info() -> Dictionary:
	"""Get information about preloaded scenes"""
	return {
		"preloaded_scenes": preloaded_scenes.keys(),
		"preload_count": preloaded_scenes.size(),
		"background_loading": background_load_enabled
	}

func get_load_metrics() -> Array[SceneLoadMetrics]:
	"""Get recent load performance metrics"""
	return load_metrics_history.duplicate()

func get_average_load_time() -> float:
	"""Calculate average scene load time"""
	if load_metrics_history.is_empty():
		return 0.0

	var total_time = 0.0
	for metrics in load_metrics_history:
		total_time += metrics.load_time

	return total_time / load_metrics_history.size()

func get_cache_hit_rate() -> float:
	"""Calculate cache hit rate percentage"""
	if load_metrics_history.is_empty():
		return 0.0

	var cache_hits = 0
	for metrics in load_metrics_history:
		if metrics.cache_hit:
			cache_hits += 1

	return float(cache_hits) / float(load_metrics_history.size()) * 100.0

# Configuration
func set_cache_limit(limit: int) -> void:
	"""Set maximum number of cached scenes"""
	scene_cache_limit = max(1, limit)

	# Evict scenes if over new limit
	while cached_scenes.size() > scene_cache_limit:
		if cache_access_order.size() > 0:
			_evict_from_cache(cache_access_order[0])
		else:
			break

func set_transition_duration(duration: float) -> void:
	"""Set scene transition fade duration"""
	transition_fade_duration = max(0.1, duration)

func set_background_loading(enabled: bool) -> void:
	"""Enable or disable background loading"""
	background_load_enabled = enabled

# Debug and monitoring
func print_cache_debug() -> void:
	"""Print debug information about cache state"""
	print("=== SceneManager Cache Debug ===")
	print("Cached scenes: ", cached_scenes.size(), "/", scene_cache_limit)
	print("Access order: ", cache_access_order)
	print("Memory estimate: ", _estimate_cache_memory_usage() / 1024 / 1024, " MB")
	print("Cache hit rate: ", "%.1f" % get_cache_hit_rate(), "%")
	print("Average load time: ", "%.2f" % (get_average_load_time() * 1000), "ms")
	print("===============================")

func print_preload_debug() -> void:
	"""Print debug information about preloaded scenes"""
	print("=== SceneManager Preload Debug ===")
	print("Preloaded scenes: ", preloaded_scenes.size())
	for scene_path in preloaded_scenes.keys():
		print("  - ", scene_path)
	print("Background loading: ", background_load_enabled)
	print("==================================")

# Cleanup
func _exit_tree() -> void:
	"""Cleanup when manager is destroyed"""
	# Wait for background thread if running
	if load_thread and load_thread.is_started():
		load_thread.wait_to_finish()

	# Clean up resources
	if load_mutex:
		load_mutex = null

	# Clear caches
	clear_cache()
	clear_preloaded()

	# Clear singleton reference
	if _instance == self:
		_instance = null

	print("SceneManager: Cleaned up")