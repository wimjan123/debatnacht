extends Node
class_name PerformanceMonitor

# Performance monitoring system for maintaining 60 FPS target
# Tracks frame rates, memory usage, and system performance metrics

# Singleton instance
static var _instance: PerformanceMonitor

# Dependencies
var event_bus: EventBus

# Performance targets
const TARGET_FPS: float = 60.0
const MIN_ACCEPTABLE_FPS: float = 45.0
const FRAME_TIME_TARGET: float = 1.0 / TARGET_FPS  # ~16.67ms
const WARNING_FRAME_TIME: float = 1.0 / MIN_ACCEPTABLE_FPS  # ~22.22ms

# Monitoring configuration
var monitoring_enabled: bool = true
var detailed_profiling: bool = false
var auto_optimization: bool = true
var log_performance_warnings: bool = true
var save_performance_logs: bool = false

# Performance metrics
class PerformanceMetrics:
	var fps: float = 0.0
	var frame_time: float = 0.0
	var memory_usage: int = 0
	var memory_peak: int = 0
	var render_time: float = 0.0
	var process_time: float = 0.0
	var physics_time: float = 0.0
	var audio_time: float = 0.0
	var timestamp: float = 0.0
	
	func _init():
		timestamp = Time.get_unix_time_from_system()

# Monitoring state
var current_metrics: PerformanceMetrics
var metrics_history: Array[PerformanceMetrics] = []
var max_history_size: int = 300  # 5 seconds at 60 FPS

# Performance tracking
var frame_count: int = 0
var sample_interval: float = 1.0  # Update every second
var last_sample_time: float = 0.0
var accumulated_frame_time: float = 0.0
var frame_time_samples: Array[float] = []
var max_frame_samples: int = 60

# Warning system
var consecutive_slow_frames: int = 0
var max_slow_frames_before_warning: int = 5
var last_warning_time: float = 0.0
var warning_cooldown: float = 10.0  # Don't spam warnings

# Performance categories
enum PerformanceLevel {
	EXCELLENT,  # >55 FPS
	GOOD,       # 45-55 FPS
	WARNING,    # 30-45 FPS
	CRITICAL    # <30 FPS
}

# Optimization settings
var optimization_actions: Dictionary = {
	PerformanceLevel.WARNING: [
		"reduce_particle_quality",
		"disable_non_essential_animations",
		"reduce_tooltip_update_frequency"
	],
	PerformanceLevel.CRITICAL: [
		"disable_particles",
		"reduce_ui_update_frequency",
		"disable_background_animations",
		"force_garbage_collection"
	]
}

# Signals
signal performance_warning(level: PerformanceLevel, metrics: PerformanceMetrics)
signal performance_improved(level: PerformanceLevel)
signal frame_rate_changed(new_fps: float)
signal memory_warning(current: int, peak: int)
signal optimization_applied(action: String)

func _ready() -> void:
	# Initialize singleton
	if _instance == null:
		_instance = self
		process_mode = Node.PROCESS_MODE_ALWAYS
		
		# Initialize dependencies
		_initialize_dependencies()
		
		# Initialize monitoring
		_initialize_monitoring()
		
		# Setup performance tracking
		_setup_performance_tracking()
	else:
		queue_free()

static func get_instance() -> PerformanceMonitor:
	"""Get singleton instance of PerformanceMonitor"""
	if _instance == null:
		# Create instance if it doesn't exist
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree:
			_instance = PerformanceMonitor.new()
			scene_tree.root.add_child(_instance)
	return _instance

func _initialize_dependencies() -> void:
	"""Initialize references to required systems"""
	event_bus = EventBus.get_instance()
	
	print("PerformanceMonitor: Dependencies initialized")

func _initialize_monitoring() -> void:
	"""Initialize performance monitoring systems"""
	current_metrics = PerformanceMetrics.new()
	last_sample_time = Time.get_unix_time_from_system()
	
	# Set up engine performance monitoring
	Engine.max_fps = int(TARGET_FPS)  # Cap at target FPS
	
	print("PerformanceMonitor: Monitoring initialized (Target: ", TARGET_FPS, " FPS)")

func _setup_performance_tracking() -> void:
	"""Setup performance tracking timer"""
	var timer = Timer.new()
	timer.wait_time = sample_interval
	timer.autostart = true
	timer.timeout.connect(_on_performance_sample)
	add_child(timer)

func _process(_delta: float) -> void:
	"""Called every frame to track performance"""
	if not monitoring_enabled:
		return
	
	# Track frame timing
	var current_time = Time.get_unix_time_from_system()
	var frame_time = _delta
	
	# Add to frame time samples
	frame_time_samples.append(frame_time)
	if frame_time_samples.size() > max_frame_samples:
		frame_time_samples.pop_front()
	
	accumulated_frame_time += frame_time
	frame_count += 1
	
	# Check for slow frames
	if frame_time > WARNING_FRAME_TIME:
		consecutive_slow_frames += 1
		if consecutive_slow_frames >= max_slow_frames_before_warning:
			_handle_performance_warning()
	else:
		consecutive_slow_frames = 0

func _on_performance_sample() -> void:
	"""Handle periodic performance sampling"""
	if not monitoring_enabled:
		return
	
	# Calculate current FPS
	var current_fps = float(frame_count) / sample_interval if frame_count > 0 else 0.0
	var avg_frame_time = accumulated_frame_time / frame_count if frame_count > 0 else 0.0
	
	# Update current metrics
	current_metrics.fps = current_fps
	current_metrics.frame_time = avg_frame_time * 1000.0  # Convert to milliseconds
	current_metrics.memory_usage = _get_memory_usage()
	current_metrics.memory_peak = _get_peak_memory_usage()
	current_metrics.timestamp = Time.get_unix_time_from_system()
	
	# Get detailed profiling if enabled
	if detailed_profiling:
		_collect_detailed_metrics()
	
	# Add to history
	metrics_history.append(current_metrics.duplicate())
	if metrics_history.size() > max_history_size:
		metrics_history.pop_front()
	
	# Check performance level
	var performance_level = _get_performance_level(current_fps)
	_handle_performance_level(performance_level)
	
	# Reset counters
	frame_count = 0
	accumulated_frame_time = 0.0
	
	# Emit signals
	frame_rate_changed.emit(current_fps)
	
	# Log if enabled
	if log_performance_warnings and performance_level >= PerformanceLevel.WARNING:
		print("PerformanceMonitor: ", _get_performance_level_name(performance_level), " performance - FPS: ", 
			"%.1f" % current_fps, ", Frame time: ", "%.2f" % current_metrics.frame_time, "ms")

func _collect_detailed_metrics() -> void:
	"""Collect detailed performance metrics"""
	# Get render server information
	current_metrics.render_time = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TYPE_VISIBLE, RenderingServer.RENDERING_INFO_DRAW_CALLS_IN_FRAME)
	
	# Note: Some metrics might not be available in all Godot versions
	# This is a simplified implementation

func _get_memory_usage() -> int:
	"""Get current memory usage in bytes"""
	return OS.get_static_memory_usage(false)

func _get_peak_memory_usage() -> int:
	"""Get peak memory usage in bytes"""
	return OS.get_static_memory_peak_usage()

func _get_performance_level(fps: float) -> PerformanceLevel:
	"""Determine performance level based on FPS"""
	if fps >= 55.0:
		return PerformanceLevel.EXCELLENT
	elif fps >= 45.0:
		return PerformanceLevel.GOOD
	elif fps >= 30.0:
		return PerformanceLevel.WARNING
	else:
		return PerformanceLevel.CRITICAL

func _get_performance_level_name(level: PerformanceLevel) -> String:
	"""Get human-readable name for performance level"""
	match level:
		PerformanceLevel.EXCELLENT:
			return "Excellent"
		PerformanceLevel.GOOD:
			return "Good"
		PerformanceLevel.WARNING:
			return "Warning"
		PerformanceLevel.CRITICAL:
			return "Critical"
		_:
			return "Unknown"

func _handle_performance_level(level: PerformanceLevel) -> void:
	"""Handle different performance levels"""
	match level:
		PerformanceLevel.WARNING, PerformanceLevel.CRITICAL:
			# Emit warning
			performance_warning.emit(level, current_metrics)
			
			# Apply optimizations if enabled
			if auto_optimization:
				_apply_optimizations(level)
		
		PerformanceLevel.EXCELLENT, PerformanceLevel.GOOD:
			# Performance is good, maybe revert optimizations
			if auto_optimization:
				_maybe_revert_optimizations()

func _handle_performance_warning() -> void:
	"""Handle performance warning conditions"""
	var current_time = Time.get_unix_time_from_system()
	
	# Check warning cooldown
	if current_time - last_warning_time < warning_cooldown:
		return
	
	last_warning_time = current_time
	
	# Publish performance warning event
	if event_bus:
		event_bus.publish(EventBus.PERFORMANCE_WARNING, {
			"fps": current_metrics.fps,
			"frame_time": current_metrics.frame_time,
			"consecutive_slow_frames": consecutive_slow_frames
		}, EventBus.EventCategory.DEBUG)

var applied_optimizations: Array[String] = []

func _apply_optimizations(level: PerformanceLevel) -> void:
	"""Apply performance optimizations based on level"""
	var actions = optimization_actions.get(level, [])
	
	for action in actions:
		if not applied_optimizations.has(action):
			_execute_optimization_action(action)
			applied_optimizations.append(action)
			optimization_applied.emit(action)
			print("PerformanceMonitor: Applied optimization: ", action)

func _maybe_revert_optimizations() -> void:
	"""Maybe revert optimizations when performance is good"""
	# Only revert if we've had good performance for a while
	var recent_metrics = metrics_history.slice(max(0, metrics_history.size() - 10))
	var all_good = true
	
	for metrics in recent_metrics:
		if _get_performance_level(metrics.fps) >= PerformanceLevel.WARNING:
			all_good = false
			break
	
	if all_good and applied_optimizations.size() > 0:
		# Revert one optimization at a time
		var action = applied_optimizations.pop_back()
		_revert_optimization_action(action)
		print("PerformanceMonitor: Reverted optimization: ", action)

func _execute_optimization_action(action: String) -> void:
	"""Execute a specific optimization action"""
	match action:
		"reduce_particle_quality":
			# Would reduce particle system quality
			pass
		
		"disable_non_essential_animations":
			# Would disable decorative animations
			pass
		
		"reduce_tooltip_update_frequency":
			# Would reduce tooltip update rate
			pass
		
		"disable_particles":
			# Would completely disable particle systems
			pass
		
		"reduce_ui_update_frequency":
			# Would reduce UI refresh rate
			pass
		
		"disable_background_animations":
			# Would stop background animations
			pass
		
		"force_garbage_collection":
			# Force garbage collection
			# GC is automatic in Godot, but we can suggest it
			pass

func _revert_optimization_action(action: String) -> void:
	"""Revert a specific optimization action"""
	match action:
		"reduce_particle_quality":
			# Restore particle quality
			pass
		
		"disable_non_essential_animations":
			# Re-enable animations
			pass
		
		# ... etc for other actions

# Public API
func get_current_fps() -> float:
	"""Get current FPS"""
	return current_metrics.fps

func get_current_frame_time() -> float:
	"""Get current frame time in milliseconds"""
	return current_metrics.frame_time

func get_memory_usage() -> Dictionary:
	"""Get memory usage information"""
	return {
		"current": current_metrics.memory_usage,
		"peak": current_metrics.memory_peak,
		"formatted_current": _format_bytes(current_metrics.memory_usage),
		"formatted_peak": _format_bytes(current_metrics.memory_peak)
	}

func get_performance_summary() -> Dictionary:
	"""Get comprehensive performance summary"""
	var avg_fps = _calculate_average_fps()
	var min_fps = _calculate_min_fps()
	var max_fps = _calculate_max_fps()
	var performance_level = _get_performance_level(current_metrics.fps)
	
	return {
		"current_fps": current_metrics.fps,
		"average_fps": avg_fps,
		"min_fps": min_fps,
		"max_fps": max_fps,
		"frame_time_ms": current_metrics.frame_time,
		"memory_usage": get_memory_usage(),
		"performance_level": _get_performance_level_name(performance_level),
		"applied_optimizations": applied_optimizations.duplicate(),
		"metrics_history_size": metrics_history.size()
	}

func get_frame_time_graph_data(samples: int = 60) -> Array[float]:
	"""Get frame time data for graphing"""
	var data: Array[float] = []
	var start_index = max(0, frame_time_samples.size() - samples)
	
	for i in range(start_index, frame_time_samples.size()):
		data.append(frame_time_samples[i] * 1000.0)  # Convert to ms
	
	return data

func _calculate_average_fps() -> float:
	"""Calculate average FPS from recent history"""
	if metrics_history.is_empty():
		return 0.0
	
	var total = 0.0
	for metrics in metrics_history:
		total += metrics.fps
	
	return total / metrics_history.size()

func _calculate_min_fps() -> float:
	"""Calculate minimum FPS from recent history"""
	if metrics_history.is_empty():
		return 0.0
	
	var min_fps = metrics_history[0].fps
	for metrics in metrics_history:
		min_fps = min(min_fps, metrics.fps)
	
	return min_fps

func _calculate_max_fps() -> float:
	"""Calculate maximum FPS from recent history"""
	if metrics_history.is_empty():
		return 0.0
	
	var max_fps = metrics_history[0].fps
	for metrics in metrics_history:
		max_fps = max(max_fps, metrics.fps)
	
	return max_fps

func _format_bytes(bytes: int) -> String:
	"""Format bytes into human-readable format"""
	var units = ["B", "KB", "MB", "GB"]
	var value = float(bytes)
	var unit_index = 0
	
	while value >= 1024.0 and unit_index < units.size() - 1:
		value /= 1024.0
		unit_index += 1
	
	return "%.1f %s" % [value, units[unit_index]]

# Configuration
func set_monitoring_enabled(enabled: bool) -> void:
	"""Enable or disable monitoring"""
	monitoring_enabled = enabled

func set_detailed_profiling(enabled: bool) -> void:
	"""Enable or disable detailed profiling"""
	detailed_profiling = enabled

func set_auto_optimization(enabled: bool) -> void:
	"""Enable or disable automatic optimization"""
	auto_optimization = enabled

func set_target_fps(fps: float) -> void:
	"""Set target FPS (will require restart for full effect)"""
	Engine.max_fps = int(fps)
	# Note: Would need to update TARGET_FPS and related constants

# Logging and debugging
func enable_performance_logging(file_path: String = "user://performance.log") -> void:
	"""Enable performance logging to file"""
	save_performance_logs = true
	# Would implement file logging here

func print_performance_debug() -> void:
	"""Print debug information about performance"""
	print("=== Performance Monitor Debug ===")
	print("Current FPS: ", "%.1f" % current_metrics.fps)
	print("Frame time: ", "%.2f" % current_metrics.frame_time, "ms")
	print("Memory: ", _format_bytes(current_metrics.memory_usage), " (Peak: ", _format_bytes(current_metrics.memory_peak), ")")
	print("Performance Level: ", _get_performance_level_name(_get_performance_level(current_metrics.fps)))
	print("Applied Optimizations: ", applied_optimizations)
	print("History Size: ", metrics_history.size())
	print("=================================")

# Cleanup
func _exit_tree() -> void:
	"""Cleanup when monitor is destroyed"""
	# Save final performance log if enabled
	if save_performance_logs:
		# Would save performance data here
		pass
	
	# Clear data
	metrics_history.clear()
	frame_time_samples.clear()
	applied_optimizations.clear()
	
	# Clear singleton reference
	if _instance == self:
		_instance = null
	
	print("PerformanceMonitor: Cleaned up")
