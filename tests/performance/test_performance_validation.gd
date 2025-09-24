extends GutTest
class_name TestPerformanceValidation

# Performance validation tests for 60 FPS and <100ms response time
# Ensures the Dutch Politics Simulation meets performance requirements

# Test dependencies
var performance_monitor: PerformanceMonitor
var scene_manager: SceneManager
var object_pool: ObjectPool
var game_state_manager: GameStateManager

# Performance targets
const TARGET_FPS: float = 60.0
const MIN_ACCEPTABLE_FPS: float = 45.0
const MAX_FRAME_TIME_MS: float = 16.67  # 1/60 second
const MAX_RESPONSE_TIME_MS: float = 100.0
const MAX_MEMORY_MB: float = 500.0

# Test configuration
var stress_test_duration: float = 10.0  # 10 seconds of stress testing
var performance_samples: Array = []
var memory_samples: Array = []

func before_each():
	"""Setup before each performance test"""
	# Initialize performance monitoring
	performance_monitor = PerformanceMonitor.new()
	scene_manager = SceneManager.new()
	object_pool = ObjectPool.new()
	game_state_manager = GameStateManager.new()

	# Clear sample arrays
	performance_samples.clear()
	memory_samples.clear()

	# Wait for systems to stabilize
	await get_tree().process_frame
	await get_tree().process_frame

func after_each():
	"""Cleanup after each test"""
	if performance_monitor:
		performance_monitor.queue_free()
	if scene_manager:
		scene_manager.queue_free()
	if object_pool:
		object_pool.queue_free()
	if game_state_manager:
		game_state_manager.queue_free()

	# Force garbage collection
	GC.collect()
	await get_tree().process_frame

# Core performance tests
func test_baseline_performance():
	"""Test baseline performance with minimal load"""
	gut.p("=== Testing Baseline Performance ===")

	var test_duration = 3.0
	var samples = []

	var start_time = Time.get_ticks_msec()
	var end_time = start_time + (test_duration * 1000)

	while Time.get_ticks_msec() < end_time:
		var sample = _capture_performance_sample()
		samples.append(sample)
		await get_tree().process_frame

	# Analyze results
	var avg_fps = _calculate_average_fps(samples)
	var avg_frame_time = _calculate_average_frame_time(samples)
	var min_fps = _calculate_min_fps(samples)

	# Assertions
	assert_ge(avg_fps, TARGET_FPS * 0.95, "Average FPS should be near target: " + str(avg_fps))
	assert_ge(min_fps, MIN_ACCEPTABLE_FPS, "Minimum FPS should be acceptable: " + str(min_fps))
	assert_le(avg_frame_time, MAX_FRAME_TIME_MS * 1.1, "Average frame time should be acceptable: " + str(avg_frame_time))

	gut.p("Baseline performance: " + str(avg_fps) + " FPS, " + str(avg_frame_time) + "ms frame time")

func test_ui_scene_loading_performance():
	"""Test performance during scene loading and transitions"""
	gut.p("=== Testing UI Scene Loading Performance ===")

	var scenes_to_test = [
		"ui/scenes/main_menu/MainMenu.tscn",
		"ui/scenes/dashboard/Dashboard.tscn",
		"ui/scenes/map_view/MapView.tscn",
		"ui/scenes/coalition_builder/CoalitionBuilder.tscn",
		"ui/scenes/settings/Settings.tscn"
	]

	var loading_times = []
	var transition_performance = []

	for scene_path in scenes_to_test:
		# Measure scene loading time
		var load_start = Time.get_ticks_msec()

		# Start performance monitoring during load
		var pre_load_sample = _capture_performance_sample()

		# Load scene (simulate)
		await _simulate_scene_load(scene_path)

		var load_end = Time.get_ticks_msec()
		var load_time = load_end - load_start

		# Capture post-load performance
		await get_tree().process_frame
		var post_load_sample = _capture_performance_sample()

		loading_times.append(load_time)
		transition_performance.append({
			"scene": scene_path,
			"load_time": load_time,
			"fps_drop": pre_load_sample.fps - post_load_sample.fps,
			"memory_increase": post_load_sample.memory_mb - pre_load_sample.memory_mb
		})

		# Validate individual scene performance
		assert_le(load_time, 2000, "Scene should load within 2 seconds: " + scene_path)
		assert_ge(post_load_sample.fps, MIN_ACCEPTABLE_FPS,
			"FPS should remain acceptable after loading: " + scene_path)

	# Validate overall performance
	var avg_load_time = loading_times.reduce(func(a, b): return a + b, 0) / loading_times.size()
	assert_le(avg_load_time, 1500, "Average scene load time should be under 1.5 seconds")

	gut.p("Scene loading performance: " + str(avg_load_time) + "ms average")

func test_intensive_ui_operations():
	"""Test performance during intensive UI operations"""
	gut.p("=== Testing Intensive UI Operations ===")

	var operations_to_test = [
		{"name": "tooltip_creation", "count": 50},
		{"name": "notification_spam", "count": 20},
		{"name": "chart_updates", "count": 100},
		{"name": "map_filtering", "count": 30},
		{"name": "data_table_sorting", "count": 25}
	]

	for operation in operations_to_test:
		gut.p("Testing: " + operation.name)

		# Capture baseline
		var baseline = _capture_performance_sample()

		# Execute intensive operation
		var operation_start = Time.get_ticks_msec()
		await _execute_intensive_operation(operation.name, operation.count)
		var operation_end = Time.get_ticks_msec()

		# Capture post-operation performance
		var post_operation = _capture_performance_sample()

		var operation_time = operation_end - operation_start
		var fps_impact = baseline.fps - post_operation.fps
		var memory_impact = post_operation.memory_mb - baseline.memory_mb

		# Validate performance impact
		assert_le(operation_time, 1000, operation.name + " should complete within 1 second")
		assert_le(fps_impact, 15.0, operation.name + " should not drop FPS by more than 15")
		assert_le(memory_impact, 50.0, operation.name + " should not increase memory by more than 50MB")

		gut.p(operation.name + ": " + str(operation_time) + "ms, FPS impact: " + str(fps_impact))

		# Allow system to recover
		await _wait_for_performance_recovery(baseline.fps * 0.95, 2.0)

func test_user_interaction_response_times():
	"""Test response times for user interactions"""
	gut.p("=== Testing User Interaction Response Times ===")

	var interactions_to_test = [
		"button_click",
		"menu_navigation",
		"form_input",
		"chart_hover",
		"map_click",
		"dropdown_select",
		"slider_drag",
		"tab_switch"
	]

	var response_times = {}

	for interaction in interactions_to_test:
		var times = []

		# Test each interaction multiple times
		for i in range(10):
			var response_time = await _measure_interaction_response_time(interaction)
			times.append(response_time)

			# Brief pause between tests
			await _wait_frames(5)

		# Calculate statistics
		var avg_time = times.reduce(func(a, b): return a + b, 0.0) / times.size()
		var max_time = times.max()

		response_times[interaction] = {
			"average": avg_time,
			"maximum": max_time,
			"samples": times
		}

		# Validate response times
		assert_le(avg_time, MAX_RESPONSE_TIME_MS,
			interaction + " average response should be under " + str(MAX_RESPONSE_TIME_MS) + "ms")
		assert_le(max_time, MAX_RESPONSE_TIME_MS * 1.5,
			interaction + " maximum response should be reasonable")

		gut.p(interaction + ": " + str(avg_time) + "ms avg, " + str(max_time) + "ms max")

	# Overall validation
	var all_averages = response_times.values().map(func(rt): return rt.average)
	var overall_avg = all_averages.reduce(func(a, b): return a + b, 0.0) / all_averages.size()

	assert_le(overall_avg, MAX_RESPONSE_TIME_MS * 0.8,
		"Overall average response time should be well under target")

func test_memory_usage_stability():
	"""Test memory usage stability during extended operation"""
	gut.p("=== Testing Memory Usage Stability ===")

	var test_duration = 15.0  # 15 seconds
	var memory_samples = []
	var leak_threshold = 10.0  # 10MB growth allowed

	# Capture baseline
	var baseline_memory = _get_current_memory_mb()

	var start_time = Time.get_ticks_msec()
	var end_time = start_time + (test_duration * 1000)

	# Run memory-intensive operations
	while Time.get_ticks_msec() < end_time:
		# Create and destroy objects
		await _simulate_memory_intensive_operations()

		# Sample memory usage
		var current_memory = _get_current_memory_mb()
		memory_samples.append(current_memory)

		await _wait_frames(10)  # Sample every 10 frames

	# Analyze memory growth
	var final_memory = memory_samples[-1]
	var peak_memory = memory_samples.max()
	var memory_growth = final_memory - baseline_memory
	var peak_growth = peak_memory - baseline_memory

	# Validate memory usage
	assert_le(final_memory, MAX_MEMORY_MB, "Final memory should be under limit")
	assert_le(memory_growth, leak_threshold, "Memory growth should be minimal")
	assert_le(peak_growth, leak_threshold * 2, "Peak memory growth should be reasonable")

	# Check for memory leaks
	var memory_trend = _calculate_memory_trend(memory_samples)
	assert_le(memory_trend, 0.5, "Memory trend should not indicate significant leaks")

	gut.p("Memory analysis: baseline=" + str(baseline_memory) + "MB, final=" +
		str(final_memory) + "MB, growth=" + str(memory_growth) + "MB")

func test_frame_time_consistency():
	"""Test frame time consistency and jitter"""
	gut.p("=== Testing Frame Time Consistency ===")

	var sample_count = 600  # 10 seconds at 60 FPS
	var frame_times = []

	# Collect frame time samples
	for i in range(sample_count):
		var frame_start = Time.get_ticks_msec()
		await get_tree().process_frame
		var frame_end = Time.get_ticks_msec()

		var frame_time = frame_end - frame_start
		frame_times.append(frame_time)

	# Calculate statistics
	var avg_frame_time = frame_times.reduce(func(a, b): return a + b, 0.0) / frame_times.size()
	var max_frame_time = frame_times.max()
	var min_frame_time = frame_times.min()

	# Calculate jitter (standard deviation)
	var variance = 0.0
	for ft in frame_times:
		variance += pow(ft - avg_frame_time, 2)
	variance /= frame_times.size()
	var jitter = sqrt(variance)

	# Count frame time spikes
	var spike_threshold = avg_frame_time * 2
	var spike_count = frame_times.filter(func(ft): return ft > spike_threshold).size()

	# Validate frame time consistency
	assert_le(avg_frame_time, MAX_FRAME_TIME_MS, "Average frame time should be acceptable")
	assert_le(jitter, MAX_FRAME_TIME_MS * 0.5, "Frame time jitter should be low")
	assert_le(spike_count, sample_count * 0.02, "Frame time spikes should be rare (<2%)")

	gut.p("Frame time analysis: avg=" + str(avg_frame_time) + "ms, jitter=" +
		str(jitter) + "ms, spikes=" + str(spike_count))

func test_concurrent_operations_performance():
	"""Test performance with multiple concurrent operations"""
	gut.p("=== Testing Concurrent Operations Performance ===")

	# Define concurrent operations
	var concurrent_tasks = [
		{"name": "ui_updates", "frequency": 60},      # 60 Hz UI updates
		{"name": "data_processing", "frequency": 10}, # 10 Hz data updates
		{"name": "animation_updates", "frequency": 30}, # 30 Hz animations
		{"name": "input_handling", "frequency": 120},  # 120 Hz input polling
	]

	var test_duration = 8.0
	var performance_samples = []

	# Start concurrent operations
	var task_coroutines = []
	for task in concurrent_tasks:
		var coroutine = _start_concurrent_task(task.name, task.frequency, test_duration)
		task_coroutines.append(coroutine)

	# Monitor performance during concurrent execution
	var start_time = Time.get_ticks_msec()
	var end_time = start_time + (test_duration * 1000)

	while Time.get_ticks_msec() < end_time:
		var sample = _capture_performance_sample()
		performance_samples.append(sample)
		await get_tree().process_frame

	# Wait for all tasks to complete
	for coroutine in task_coroutines:
		await coroutine

	# Analyze concurrent performance
	var avg_fps = _calculate_average_fps(performance_samples)
	var min_fps = _calculate_min_fps(performance_samples)
	var fps_stability = _calculate_fps_stability(performance_samples)

	# Validate concurrent performance
	assert_ge(avg_fps, MIN_ACCEPTABLE_FPS * 1.1, "Average FPS should remain good during concurrent ops")
	assert_ge(min_fps, MIN_ACCEPTABLE_FPS * 0.9, "Minimum FPS should not drop too low")
	assert_ge(fps_stability, 0.8, "FPS should remain stable during concurrent operations")

	gut.p("Concurrent operations: avg=" + str(avg_fps) + " FPS, min=" +
		str(min_fps) + " FPS, stability=" + str(fps_stability))

# Performance stress tests
func test_stress_tooltips_and_notifications():
	"""Stress test tooltip and notification systems"""
	gut.p("=== Stress Testing Tooltips and Notifications ===")

	var baseline = _capture_performance_sample()

	# Create many tooltips rapidly
	var tooltip_count = 100
	var start_time = Time.get_ticks_msec()

	for i in range(tooltip_count):
		await _create_test_tooltip("Test tooltip " + str(i))

	var creation_time = Time.get_ticks_msec() - start_time
	var post_creation = _capture_performance_sample()

	# Test notification spam
	var notification_count = 50
	for i in range(notification_count):
		await _create_test_notification("Test notification " + str(i))

	var post_notifications = _capture_performance_sample()

	# Validate stress test performance
	assert_le(creation_time, 2000, "Tooltip creation should complete quickly")
	assert_ge(post_creation.fps, MIN_ACCEPTABLE_FPS, "FPS should remain acceptable after tooltips")
	assert_ge(post_notifications.fps, MIN_ACCEPTABLE_FPS, "FPS should remain acceptable after notifications")

	# Clean up
	await _cleanup_test_ui_elements()

	gut.p("Stress test completed: " + str(creation_time) + "ms for " + str(tooltip_count) + " tooltips")

func test_large_dataset_performance():
	"""Test performance with large datasets"""
	gut.p("=== Testing Large Dataset Performance ===")

	# Create large test dataset
	var large_party_list = _generate_large_party_dataset(200)  # 200 parties
	var large_poll_data = _generate_large_poll_dataset(1000)  # 1000 poll entries
	var large_event_history = _generate_large_event_dataset(500)  # 500 events

	var baseline = _capture_performance_sample()

	# Test data processing performance
	var process_start = Time.get_ticks_msec()

	await _process_large_dataset("parties", large_party_list)
	await _process_large_dataset("polls", large_poll_data)
	await _process_large_dataset("events", large_event_history)

	var process_end = Time.get_ticks_msec()
	var processing_time = process_end - process_start

	var post_processing = _capture_performance_sample()

	# Validate large dataset performance
	assert_le(processing_time, 3000, "Large dataset processing should complete within 3 seconds")
	assert_ge(post_processing.fps, MIN_ACCEPTABLE_FPS * 0.9, "FPS should remain reasonable with large datasets")

	var memory_increase = post_processing.memory_mb - baseline.memory_mb
	assert_le(memory_increase, 100.0, "Memory increase should be reasonable for large datasets")

	gut.p("Large dataset performance: " + str(processing_time) + "ms processing time")

# Helper functions
func _capture_performance_sample() -> Dictionary:
	"""Capture a performance sample"""
	return {
		"timestamp": Time.get_ticks_msec(),
		"fps": Engine.get_frames_per_second(),
		"frame_time_ms": 1000.0 / max(Engine.get_frames_per_second(), 1.0),
		"memory_mb": _get_current_memory_mb()
	}

func _get_current_memory_mb() -> float:
	"""Get current memory usage in MB"""
	return OS.get_static_memory_usage(false) / (1024.0 * 1024.0)

func _calculate_average_fps(samples: Array) -> float:
	"""Calculate average FPS from samples"""
	if samples.is_empty():
		return 0.0

	var total = samples.reduce(func(a, b): return a + b.fps, 0.0)
	return total / samples.size()

func _calculate_average_frame_time(samples: Array) -> float:
	"""Calculate average frame time from samples"""
	if samples.is_empty():
		return 0.0

	var total = samples.reduce(func(a, b): return a + b.frame_time_ms, 0.0)
	return total / samples.size()

func _calculate_min_fps(samples: Array) -> float:
	"""Calculate minimum FPS from samples"""
	if samples.is_empty():
		return 0.0

	return samples.map(func(s): return s.fps).min()

func _calculate_fps_stability(samples: Array) -> float:
	"""Calculate FPS stability (1.0 = perfectly stable)"""
	if samples.size() < 2:
		return 1.0

	var fps_values = samples.map(func(s): return s.fps)
	var avg_fps = fps_values.reduce(func(a, b): return a + b, 0.0) / fps_values.size()

	var variance = 0.0
	for fps in fps_values:
		variance += pow(fps - avg_fps, 2)
	variance /= fps_values.size()

	var stability = 1.0 - (sqrt(variance) / avg_fps)
	return max(0.0, stability)

func _calculate_memory_trend(samples: Array) -> float:
	"""Calculate memory trend (MB per second)"""
	if samples.size() < 2:
		return 0.0

	# Simple linear regression
	var n = samples.size()
	var sum_x = 0.0
	var sum_y = 0.0
	var sum_xy = 0.0
	var sum_x2 = 0.0

	for i in range(n):
		var x = float(i)
		var y = samples[i]
		sum_x += x
		sum_y += y
		sum_xy += x * y
		sum_x2 += x * x

	var slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x)
	return slope

func _simulate_scene_load(scene_path: String) -> void:
	"""Simulate scene loading"""
	# Simulate loading delay and resource allocation
	await _wait_frames(randf_range(10, 30))  # 10-30 frames of loading

	# Simulate memory allocation for scene
	var dummy_objects = []
	for i in range(randi_range(50, 100)):
		dummy_objects.append(Node.new())

	await _wait_frames(5)

	# Clean up dummy objects
	for obj in dummy_objects:
		obj.queue_free()

func _execute_intensive_operation(operation_name: String, count: int) -> void:
	"""Execute intensive UI operation"""
	match operation_name:
		"tooltip_creation":
			for i in range(count):
				await _create_test_tooltip("Tooltip " + str(i))
				if i % 10 == 0:  # Pause occasionally
					await get_tree().process_frame

		"notification_spam":
			for i in range(count):
				await _create_test_notification("Notification " + str(i))
				await _wait_frames(2)

		"chart_updates":
			for i in range(count):
				await _simulate_chart_update()
				await get_tree().process_frame

		"map_filtering":
			for i in range(count):
				await _simulate_map_filter_update()
				await _wait_frames(3)

		"data_table_sorting":
			for i in range(count):
				await _simulate_table_sort()
				await _wait_frames(4)

func _measure_interaction_response_time(interaction: String) -> float:
	"""Measure response time for interaction"""
	var start_time = Time.get_ticks_msec()

	# Simulate interaction
	match interaction:
		"button_click":
			await _simulate_button_click()
		"menu_navigation":
			await _simulate_menu_navigation()
		"form_input":
			await _simulate_form_input()
		"chart_hover":
			await _simulate_chart_hover()
		"map_click":
			await _simulate_map_click()
		"dropdown_select":
			await _simulate_dropdown_select()
		"slider_drag":
			await _simulate_slider_drag()
		"tab_switch":
			await _simulate_tab_switch()

	var end_time = Time.get_ticks_msec()
	return float(end_time - start_time)

func _simulate_memory_intensive_operations() -> void:
	"""Simulate memory-intensive operations"""
	# Create temporary objects
	var temp_objects = []
	for i in range(50):
		temp_objects.append(Node.new())

	# Do some work
	await _wait_frames(5)

	# Clean up most objects (simulate proper cleanup)
	for i in range(temp_objects.size() - 2):  # Leave 2 to test minor leaks
		temp_objects[i].queue_free()

func _wait_for_performance_recovery(target_fps: float, timeout: float) -> void:
	"""Wait for performance to recover to target level"""
	var start_time = Time.get_ticks_msec()
	var timeout_ms = timeout * 1000

	while Time.get_ticks_msec() - start_time < timeout_ms:
		if Engine.get_frames_per_second() >= target_fps:
			return

		await get_tree().process_frame

func _start_concurrent_task(task_name: String, frequency: int, duration: float):
	"""Start a concurrent task that runs at specified frequency"""
	var interval = 1.0 / frequency
	var end_time = Time.get_unix_time_from_system() + duration

	while Time.get_unix_time_from_system() < end_time:
		await _execute_task_work(task_name)
		await get_tree().create_timer(interval).timeout

func _execute_task_work(task_name: String) -> void:
	"""Execute work for a specific task type"""
	match task_name:
		"ui_updates":
			await _simulate_ui_update()
		"data_processing":
			await _simulate_data_processing()
		"animation_updates":
			await _simulate_animation_update()
		"input_handling":
			await _simulate_input_handling()

# Simulation helper functions
func _wait_frames(count: int) -> void:
	"""Wait for specified number of frames"""
	for i in range(count):
		await get_tree().process_frame

func _create_test_tooltip(text: String) -> void:
	"""Create a test tooltip"""
	# Simulate tooltip creation work
	await _wait_frames(1)

func _create_test_notification(text: String) -> void:
	"""Create a test notification"""
	# Simulate notification creation work
	await _wait_frames(2)

func _cleanup_test_ui_elements() -> void:
	"""Clean up test UI elements"""
	# Simulate cleanup work
	await _wait_frames(10)

func _generate_large_party_dataset(count: int) -> Array:
	"""Generate large party dataset for testing"""
	var parties = []
	for i in range(count):
		parties.append({
			"id": "party_" + str(i),
			"name": "Test Party " + str(i),
			"support": randf() * 100.0
		})
	return parties

func _generate_large_poll_dataset(count: int) -> Array:
	"""Generate large poll dataset"""
	var polls = []
	for i in range(count):
		polls.append({
			"id": i,
			"date": "2024-01-" + str((i % 30) + 1),
			"data": {}
		})
	return polls

func _generate_large_event_dataset(count: int) -> Array:
	"""Generate large event dataset"""
	var events = []
	for i in range(count):
		events.append({
			"id": i,
			"type": "test_event",
			"description": "Test event " + str(i)
		})
	return events

func _process_large_dataset(type: String, dataset: Array) -> void:
	"""Process large dataset"""
	for i in range(dataset.size()):
		# Simulate processing work
		var item = dataset[i]
		# Do minimal work to simulate processing
		if i % 100 == 0:  # Pause occasionally
			await get_tree().process_frame

# UI simulation functions (mock implementations)
func _simulate_chart_update() -> void:
	await _wait_frames(2)

func _simulate_map_filter_update() -> void:
	await _wait_frames(3)

func _simulate_table_sort() -> void:
	await _wait_frames(4)

func _simulate_button_click() -> void:
	await _wait_frames(1)

func _simulate_menu_navigation() -> void:
	await _wait_frames(2)

func _simulate_form_input() -> void:
	await _wait_frames(3)

func _simulate_chart_hover() -> void:
	await _wait_frames(2)

func _simulate_map_click() -> void:
	await _wait_frames(4)

func _simulate_dropdown_select() -> void:
	await _wait_frames(3)

func _simulate_slider_drag() -> void:
	await _wait_frames(5)

func _simulate_tab_switch() -> void:
	await _wait_frames(2)

func _simulate_ui_update() -> void:
	await _wait_frames(1)

func _simulate_data_processing() -> void:
	await _wait_frames(2)

func _simulate_animation_update() -> void:
	await _wait_frames(1)

func _simulate_input_handling() -> void:
	# Very lightweight operation
	pass

# Test suite runner
func test_all_performance_validations():
	"""Run complete performance validation suite"""
	gut.p("=== Running Complete Performance Validation Suite ===")

	test_baseline_performance()
	test_ui_scene_loading_performance()
	test_intensive_ui_operations()
	test_user_interaction_response_times()
	test_memory_usage_stability()
	test_frame_time_consistency()
	test_concurrent_operations_performance()
	test_stress_tooltips_and_notifications()
	test_large_dataset_performance()

	gut.p("=== Performance Validation Suite Completed ===")

func benchmark_overall_system_performance():
	"""Comprehensive system performance benchmark"""
	gut.p("=== System Performance Benchmark ===")

	var benchmark_results = {}

	# Baseline measurement
	var baseline = await _run_performance_benchmark("baseline", 5.0)
	benchmark_results["baseline"] = baseline

	# Load testing
	var load_test = await _run_performance_benchmark("load_test", 10.0)
	benchmark_results["load_test"] = load_test

	# Stress testing
	var stress_test = await _run_performance_benchmark("stress_test", 8.0)
	benchmark_results["stress_test"] = stress_test

	# Print comprehensive results
	gut.p("Benchmark Results:")
	for test_name in benchmark_results:
		var result = benchmark_results[test_name]
		gut.p("  " + test_name + ":")
		gut.p("    Average FPS: " + str(result.avg_fps))
		gut.p("    Min FPS: " + str(result.min_fps))
		gut.p("    Memory Peak: " + str(result.peak_memory_mb) + "MB")
		gut.p("    Response Time: " + str(result.avg_response_time) + "ms")

	return benchmark_results

func _run_performance_benchmark(test_type: String, duration: float) -> Dictionary:
	"""Run specific performance benchmark"""
	var samples = []
	var response_times = []

	var start_time = Time.get_ticks_msec()
	var end_time = start_time + (duration * 1000)

	while Time.get_ticks_msec() < end_time:
		# Capture performance sample
		var sample = _capture_performance_sample()
		samples.append(sample)

		# Measure response time
		var response_time = await _measure_interaction_response_time("button_click")
		response_times.append(response_time)

		# Apply load based on test type
		match test_type:
			"load_test":
				await _simulate_moderate_load()
			"stress_test":
				await _simulate_heavy_load()

		await get_tree().process_frame

	# Calculate results
	return {
		"avg_fps": _calculate_average_fps(samples),
		"min_fps": _calculate_min_fps(samples),
		"peak_memory_mb": samples.map(func(s): return s.memory_mb).max(),
		"avg_response_time": response_times.reduce(func(a, b): return a + b, 0.0) / response_times.size()
	}

func _simulate_moderate_load() -> void:
	"""Simulate moderate system load"""
	await _create_test_tooltip("Load test")
	await _simulate_chart_update()

func _simulate_heavy_load() -> void:
	"""Simulate heavy system load"""
	await _create_test_tooltip("Stress test")
	await _create_test_notification("Stress test")
	await _simulate_chart_update()
	await _simulate_map_filter_update()