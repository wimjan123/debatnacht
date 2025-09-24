extends Node

# Seeded RNG validation and display system for simulation integrity
# Ensures reproducible results and constitutional transparency in random events

# Singleton instance
static var _instance: RNGValidator

# Dependencies
var event_bus: EventBus
var logging_manager: LoggingManager

# RNG Configuration
var master_seed: int = 0
var current_seed: int = 0
var rng_instance: RandomNumberGenerator
var validation_enabled: bool = true

# Simulation integrity features
var deterministic_mode: bool = true
var seed_locked: bool = false
var validation_history: Array[Dictionary] = []
var max_validation_history: int = 1000

# Educational transparency
var show_seed_to_user: bool = true
var explain_randomness: bool = true
var track_all_random_calls: bool = true

class RNGValidation:
	var call_id: int
	var timestamp: float
	var seed_before: int
	var seed_after: int
	var function_called: String
	var parameters: Dictionary
	var result: Variant
	var context: String  # What simulation system called this
	var reproducible: bool

	func _init():
		call_id = 0
		timestamp = Time.get_unix_time_from_system()
		seed_before = 0
		seed_after = 0
		function_called = ""
		parameters = {}
		result = null
		context = ""
		reproducible = true

	func to_dict() -> Dictionary:
		return {
			"call_id": call_id,
			"timestamp": timestamp,
			"seed_before": seed_before,
			"seed_after": seed_after,
			"function": function_called,
			"parameters": parameters,
			"result": result,
			"context": context,
			"reproducible": reproducible
		}

# Validation state
var validation_call_counter: int = 0
var current_validation_context: String = ""
var reproducibility_test_results: Dictionary = {}

# Seed management
var scenario_seeds: Dictionary = {}  # Predefined seeds for scenarios
var user_custom_seed: int = 0
var seed_source: String = "system_generated"  # "system_generated", "user_provided", "scenario_based"

# Constitutional compliance
var transparency_report: Dictionary = {}
var integrity_violations: Array[Dictionary] = []

# Signals
signal seed_changed(old_seed: int, new_seed: int, source: String)
signal rng_call_validated(validation: RNGValidation)
signal reproducibility_test_completed(success: bool, details: Dictionary)
signal integrity_violation_detected(violation: Dictionary)
signal transparency_report_updated()

func _ready() -> void:
	# Initialize singleton
	if _instance == null:
		_instance = self
		process_mode = Node.PROCESS_MODE_ALWAYS

		# Initialize dependencies
		_initialize_dependencies()

		# Setup RNG system
		_initialize_rng_system()

		# Setup scenario seeds
		_setup_scenario_seeds()

		print("RNGValidator: Seeded RNG validation system initialized")
	else:
		queue_free()

static func get_instance() -> RNGValidator:
	"""Get singleton instance of RNGValidator"""
	if _instance == null:
		# Create instance if it doesn't exist
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree:
			_instance = RNGValidator.new()
			scene_tree.root.add_child(_instance)
	return _instance

func _initialize_dependencies() -> void:
	"""Initialize references to required systems"""
	event_bus = EventBus.get_instance()
	logging_manager = LoggingManager.get_instance()

func _initialize_rng_system() -> void:
	"""Initialize the RNG system with proper seeding"""
	rng_instance = RandomNumberGenerator.new()

	# Generate or load master seed
	_setup_master_seed()

	# Apply seed to RNG
	rng_instance.seed = master_seed
	current_seed = master_seed

	if logging_manager:
		logging_manager.log(LoggingManager.LogLevel.INFO, LoggingManager.LogCategory.SYSTEM,
			"RNG initialized with seed: " + str(master_seed),
			{"seed": master_seed, "source": seed_source}
		)

func _setup_master_seed() -> void:
	"""Setup master seed based on configuration"""
	if user_custom_seed != 0:
		master_seed = user_custom_seed
		seed_source = "user_provided"
	else:
		# Generate deterministic seed based on system info for reproducibility
		var hash_source = str(Time.get_unix_time_from_system()).substr(0, 8)  # First 8 digits
		master_seed = hash_source.hash()
		seed_source = "system_generated"

		# Save generated seed for user reference
		_save_generated_seed()

func _setup_scenario_seeds() -> void:
	"""Setup predefined seeds for different scenarios"""
	scenario_seeds = {
		"tutorial": 12345,
		"coalition_crisis": 67890,
		"economic_downturn": 24680,
		"referendum_campaign": 13579,
		"snap_election": 97531,
		"coalition_formation": 86420,
		"media_scandal": 75319,
		"policy_debate": 64208
	}

# Public API for validated random generation
func randi_validated(context: String = "") -> int:
	"""Generate validated random integer"""
	var validation = _create_validation("randi", {}, context)
	var result = rng_instance.randi()
	_complete_validation(validation, result)
	return result

func randf_validated(context: String = "") -> float:
	"""Generate validated random float"""
	var validation = _create_validation("randf", {}, context)
	var result = rng_instance.randf()
	_complete_validation(validation, result)
	return result

func randi_range_validated(from: int, to: int, context: String = "") -> int:
	"""Generate validated random integer in range"""
	var params = {"from": from, "to": to}
	var validation = _create_validation("randi_range", params, context)
	var result = rng_instance.randi_range(from, to)
	_complete_validation(validation, result)
	return result

func randf_range_validated(from: float, to: float, context: String = "") -> float:
	"""Generate validated random float in range"""
	var params = {"from": from, "to": to}
	var validation = _create_validation("randf_range", params, context)
	var result = rng_instance.randf_range(from, to)
	_complete_validation(validation, result)
	return result

func weighted_choice_validated(weights: Array, context: String = "") -> int:
	"""Generate validated weighted random choice"""
	var params = {"weights": weights}
	var validation = _create_validation("weighted_choice", params, context)

	var total_weight = 0.0
	for weight in weights:
		total_weight += weight

	var random_value = rng_instance.randf() * total_weight
	var accumulated = 0.0

	for i in range(weights.size()):
		accumulated += weights[i]
		if random_value <= accumulated:
			_complete_validation(validation, i)
			return i

	# Fallback to last index
	_complete_validation(validation, weights.size() - 1)
	return weights.size() - 1

func probability_test_validated(probability: float, context: String = "") -> bool:
	"""Generate validated probability test result"""
	var params = {"probability": probability}
	var validation = _create_validation("probability_test", params, context)
	var result = rng_instance.randf() < probability
	_complete_validation(validation, result)
	return result

func shuffle_array_validated(array: Array, context: String = "") -> Array:
	"""Shuffle array with validated randomness"""
	var params = {"array_size": array.size()}
	var validation = _create_validation("shuffle_array", params, context)

	var result = array.duplicate()
	for i in range(result.size()):
		var j = rng_instance.randi_range(i, result.size() - 1)
		var temp = result[i]
		result[i] = result[j]
		result[j] = temp

	_complete_validation(validation, "shuffled_array")
	return result

# Validation system
func _create_validation(function_name: String, parameters: Dictionary, context: String) -> RNGValidation:
	"""Create validation record for RNG call"""
	if not validation_enabled:
		return null

	var validation = RNGValidation.new()
	validation.call_id = validation_call_counter
	validation.seed_before = rng_instance.seed
	validation.function_called = function_name
	validation.parameters = parameters.duplicate(true)
	validation.context = context if not context.is_empty() else current_validation_context

	validation_call_counter += 1
	return validation

func _complete_validation(validation: RNGValidation, result: Variant) -> void:
	"""Complete validation record after RNG call"""
	if not validation:
		return

	validation.seed_after = rng_instance.seed
	validation.result = result
	validation.reproducible = _check_reproducibility(validation)

	# Store validation
	validation_history.append(validation.to_dict())

	if validation_history.size() > max_validation_history:
		validation_history.pop_front()

	# Emit signal
	rng_call_validated.emit(validation)

	# Log for transparency
	if logging_manager and track_all_random_calls:
		logging_manager.log(LoggingManager.LogLevel.DEBUG, LoggingManager.LogCategory.SIMULATION,
			"RNG call: " + validation.function_called + " -> " + str(result),
			{
				"context": validation.context,
				"parameters": validation.parameters,
				"call_id": validation.call_id,
				"reproducible": validation.reproducible
			}
		)

func _check_reproducibility(validation: RNGValidation) -> bool:
	"""Check if the RNG call is reproducible"""
	# In deterministic mode with same seed, all calls should be reproducible
	return deterministic_mode and validation.seed_before > 0

# Seed management
func set_seed(new_seed: int, source: String = "user_provided", lock_seed: bool = false) -> void:
	"""Set new seed with validation and logging"""
	if seed_locked:
		if logging_manager:
			logging_manager.warning(LoggingManager.LogCategory.SYSTEM,
				"Attempted to change locked seed",
				{"current_seed": current_seed, "attempted_seed": new_seed}
			)
		return

	var old_seed = current_seed
	master_seed = new_seed
	current_seed = new_seed
	rng_instance.seed = new_seed
	seed_source = source

	if lock_seed:
		seed_locked = true

	# Log seed change for transparency
	if logging_manager:
		logging_manager.log_user_action("Seed changed",
			{
				"old_seed": old_seed,
				"new_seed": new_seed,
				"source": source,
				"locked": seed_locked
			}
		)

	# Reset validation counter
	validation_call_counter = 0

	# Clear validation history
	validation_history.clear()

	seed_changed.emit(old_seed, new_seed, source)

func set_scenario_seed(scenario_name: String) -> bool:
	"""Set seed for a specific scenario"""
	if not scenario_seeds.has(scenario_name):
		return false

	set_seed(scenario_seeds[scenario_name], "scenario_based")

	if logging_manager:
		logging_manager.log_user_action("Scenario seed set",
			{
				"scenario": scenario_name,
				"seed": scenario_seeds[scenario_name]
			}
		)

	return true

func reset_to_master_seed() -> void:
	"""Reset RNG to master seed"""
	rng_instance.seed = master_seed
	current_seed = master_seed
	validation_call_counter = 0

	if logging_manager:
		logging_manager.log(LoggingManager.LogLevel.INFO, LoggingManager.LogCategory.SYSTEM,
			"RNG reset to master seed: " + str(master_seed)
		)

# Reproducibility testing
func run_reproducibility_test(test_name: String = "standard") -> bool:
	"""Run reproducibility test to verify deterministic behavior"""
	if logging_manager:
		logging_manager.log(LoggingManager.LogLevel.INFO, LoggingManager.LogCategory.SIMULATION,
			"Starting reproducibility test: " + test_name
		)

	var test_seed = 54321  # Fixed test seed
	var original_seed = current_seed

	# First run
	rng_instance.seed = test_seed
	var first_run = _execute_test_sequence()

	# Second run with same seed
	rng_instance.seed = test_seed
	var second_run = _execute_test_sequence()

	# Compare results
	var success = _compare_test_results(first_run, second_run)

	var test_result = {
		"test_name": test_name,
		"success": success,
		"test_seed": test_seed,
		"first_run": first_run,
		"second_run": second_run,
		"timestamp": Time.get_unix_time_from_system()
	}

	reproducibility_test_results[test_name] = test_result
	reproducibility_test_completed.emit(success, test_result)

	# Restore original seed
	rng_instance.seed = original_seed
	current_seed = original_seed

	if logging_manager:
		logging_manager.log(
			LoggingManager.LogLevel.INFO if success else LoggingManager.LogLevel.ERROR,
			LoggingManager.LogCategory.SIMULATION,
			"Reproducibility test " + ("PASSED" if success else "FAILED"),
			test_result
		)

	return success

func _execute_test_sequence() -> Array:
	"""Execute standard test sequence for reproducibility testing"""
	var results = []

	# Test various RNG functions
	results.append(rng_instance.randi())
	results.append(rng_instance.randf())
	results.append(rng_instance.randi_range(1, 100))
	results.append(rng_instance.randf_range(0.0, 1.0))

	# Test with array
	var test_array = [1, 2, 3, 4, 5]
	for i in range(test_array.size()):
		var j = rng_instance.randi_range(i, test_array.size() - 1)
		var temp = test_array[i]
		test_array[i] = test_array[j]
		test_array[j] = temp
	results.append(test_array)

	return results

func _compare_test_results(first: Array, second: Array) -> bool:
	"""Compare two test result arrays for equality"""
	if first.size() != second.size():
		return false

	for i in range(first.size()):
		if typeof(first[i]) != typeof(second[i]):
			return false

		if first[i] is Array and second[i] is Array:
			if not _compare_arrays(first[i], second[i]):
				return false
		elif first[i] != second[i]:
			return false

	return true

func _compare_arrays(a: Array, b: Array) -> bool:
	"""Compare two arrays for equality"""
	if a.size() != b.size():
		return false

	for i in range(a.size()):
		if a[i] != b[i]:
			return false

	return true

# Transparency and reporting
func generate_transparency_report() -> Dictionary:
	"""Generate comprehensive transparency report"""
	transparency_report = {
		"report_timestamp": Time.get_unix_time_from_system(),
		"report_type": "rng_transparency",
		"constitutional_compliance": "full_disclosure",

		"seed_information": {
			"master_seed": master_seed,
			"current_seed": current_seed,
			"seed_source": seed_source,
			"seed_locked": seed_locked,
			"user_visible": show_seed_to_user
		},

		"validation_statistics": {
			"total_calls": validation_call_counter,
			"tracked_calls": validation_history.size(),
			"reproducible_calls": _count_reproducible_calls(),
			"validation_enabled": validation_enabled
		},

		"reproducibility_status": {
			"deterministic_mode": deterministic_mode,
			"last_test_results": reproducibility_test_results,
			"integrity_violations": integrity_violations.size()
		},

		"educational_features": {
			"seed_visible_to_user": show_seed_to_user,
			"randomness_explained": explain_randomness,
			"all_calls_tracked": track_all_random_calls
		}
	}

	transparency_report_updated.emit()
	return transparency_report

func get_seed_display_info() -> Dictionary:
	"""Get seed information for user display"""
	return {
		"current_seed": current_seed if show_seed_to_user else "hidden",
		"seed_source": seed_source,
		"deterministic": deterministic_mode,
		"locked": seed_locked,
		"explanation": _get_seed_explanation()
	}

func _get_seed_explanation() -> String:
	"""Get educational explanation of the seed system"""
	if not explain_randomness:
		return ""

	var explanation = "This simulation uses a 'seed' number (%d) to generate random events. " % current_seed
	explanation += "The same seed will always produce the same sequence of random results, "
	explanation += "ensuring that simulations can be replayed exactly. "

	match seed_source:
		"user_provided":
			explanation += "You provided this seed for reproducible results."
		"scenario_based":
			explanation += "This seed is predefined for this scenario."
		"system_generated":
			explanation += "This seed was automatically generated based on the current time."

	return explanation

func _count_reproducible_calls() -> int:
	"""Count number of reproducible RNG calls in history"""
	var count = 0
	for validation_dict in validation_history:
		if validation_dict.get("reproducible", false):
			count += 1
	return count

# Integrity monitoring
func detect_integrity_violations() -> Array[Dictionary]:
	"""Detect potential integrity violations"""
	var violations = []

	# Check for non-reproducible calls in deterministic mode
	if deterministic_mode:
		for validation_dict in validation_history:
			if not validation_dict.get("reproducible", true):
				violations.append({
					"type": "non_reproducible_call",
					"call_id": validation_dict.get("call_id", -1),
					"function": validation_dict.get("function", "unknown"),
					"context": validation_dict.get("context", "unknown"),
					"timestamp": validation_dict.get("timestamp", 0)
				})

	# Check for seed tampering
	if current_seed != rng_instance.seed:
		violations.append({
			"type": "seed_desync",
			"expected": current_seed,
			"actual": rng_instance.seed,
			"timestamp": Time.get_unix_time_from_system()
		})

	# Store new violations
	for violation in violations:
		if violation not in integrity_violations:
			integrity_violations.append(violation)
			integrity_violation_detected.emit(violation)

			if logging_manager:
				logging_manager.error(LoggingManager.LogCategory.SIMULATION,
					"RNG integrity violation: " + violation.type,
					violation
				)

	return violations

func _save_generated_seed() -> void:
	"""Save generated seed to file for reference"""
	var file = FileAccess.open("user://rng_seed.txt", FileAccess.WRITE)
	if file:
		file.store_line("Debatnacht RNG Seed Information")
		file.store_line("Generated: " + Time.get_datetime_string_from_unix_time(Time.get_unix_time_from_system()))
		file.store_line("Seed: " + str(master_seed))
		file.store_line("")
		file.store_line("This seed ensures reproducible simulation results.")
		file.store_line("Use this number to replay the exact same simulation.")
		file.close()

# Configuration
func set_validation_enabled(enabled: bool) -> void:
	"""Enable/disable RNG validation"""
	validation_enabled = enabled

func set_deterministic_mode(enabled: bool) -> void:
	"""Enable/disable deterministic mode"""
	deterministic_mode = enabled

func set_seed_visibility(visible: bool) -> void:
	"""Set whether seed is visible to users"""
	show_seed_to_user = visible

func set_randomness_explanation(enabled: bool) -> void:
	"""Enable/disable randomness explanations"""
	explain_randomness = enabled

func set_call_tracking(enabled: bool) -> void:
	"""Enable/disable tracking of all RNG calls"""
	track_all_random_calls = enabled

# Public query methods
func get_validation_history(max_count: int = 50) -> Array:
	"""Get recent validation history"""
	var start_index = max(0, validation_history.size() - max_count)
	return validation_history.slice(start_index)

func get_current_seed() -> int:
	"""Get current seed (if visibility enabled)"""
	return current_seed if show_seed_to_user else -1

func get_available_scenarios() -> Array[String]:
	"""Get list of available scenario seeds"""
	return scenario_seeds.keys()

func get_validation_statistics() -> Dictionary:
	"""Get validation system statistics"""
	return {
		"total_calls": validation_call_counter,
		"validation_history_size": validation_history.size(),
		"reproducible_calls": _count_reproducible_calls(),
		"integrity_violations": integrity_violations.size(),
		"deterministic_mode": deterministic_mode,
		"validation_enabled": validation_enabled
	}

# Debug functionality
func print_rng_status() -> void:
	"""Print current RNG system status"""
	print("=== RNG Validator Status ===")
	print("Master Seed: ", master_seed)
	print("Current Seed: ", current_seed)
	print("Source: ", seed_source)
	print("Locked: ", seed_locked)
	print("Deterministic: ", deterministic_mode)
	print("Validation: ", validation_enabled)
	print("Total Calls: ", validation_call_counter)
	print("History Size: ", validation_history.size())
	print("Violations: ", integrity_violations.size())
	print("===========================")

func run_integrity_check() -> bool:
	"""Run comprehensive integrity check"""
	var violations = detect_integrity_violations()
	var test_result = run_reproducibility_test("integrity_check")

	var success = violations.is_empty() and test_result

	if logging_manager:
		logging_manager.log(
			LoggingManager.LogLevel.INFO if success else LoggingManager.LogLevel.WARNING,
			LoggingManager.LogCategory.SIMULATION,
			"RNG integrity check " + ("PASSED" if success else "FAILED"),
			{
				"violations_found": violations.size(),
				"reproducibility_test": test_result,
				"timestamp": Time.get_unix_time_from_system()
			}
		)

	return success

# Cleanup
func _exit_tree() -> void:
	"""Cleanup RNG validator on shutdown"""
	# Generate final transparency report
	var final_report = generate_transparency_report()

	if logging_manager:
		logging_manager.log(LoggingManager.LogLevel.INFO, LoggingManager.LogCategory.SYSTEM,
			"RNG Validator shutdown - final transparency report generated",
			final_report
		)

	# Clear validation history
	validation_history.clear()
	integrity_violations.clear()
	reproducibility_test_results.clear()

	# Clear singleton reference
	if _instance == self:
		_instance = null

	print("RNGValidator: Cleaned up")