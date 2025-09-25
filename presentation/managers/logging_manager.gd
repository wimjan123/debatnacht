extends Node

# Comprehensive logging system for debugging and constitutional transparency
# Ensures all actions are traceable for educational and audit purposes

# Singleton instance
static var _instance: LoggingManager

# Dependencies
var event_bus: EventBus

# Logging configuration
enum LogLevel {
	TRACE = 0,
	DEBUG = 1,
	INFO = 2,
	WARNING = 3,
	ERROR = 4,
	CRITICAL = 5
}

enum LogCategory {
	SYSTEM,        # System events and lifecycle
	GAME,          # Game state changes and actions
	UI,            # UI interactions and navigation
	INPUT,         # User input and shortcuts
	PERFORMANCE,   # Performance metrics and optimizations
	AUDIT,         # Constitutional transparency events
	SIMULATION,    # Simulation logic and calculations
	DATA,          # Data processing and validation
	NETWORK,       # Network operations (future)
	DEBUG          # Debug-specific information
}

# Logging targets
enum LogTarget {
	CONSOLE,       # Godot console output
	FILE,          # Log files on disk
	UI,            # In-game debug UI
	AUDIT,         # Special audit trail file
	MEMORY         # In-memory buffer
}

class LogEntry:
	var timestamp: float
	var level: LogLevel
	var category: LogCategory
	var message: String
	var context: Dictionary
	var stack_trace: String
	var session_id: String
	var user_action: bool  # Was this triggered by user action?

	func _init():
		timestamp = Time.get_unix_time_from_system()
		context = {}
		stack_trace = ""
		session_id = ""
		user_action = false

	func to_log_string() -> String:
		var level_str = _level_to_string(level)
		var category_str = _category_to_string(category)
		var time_str = Time.get_datetime_string_from_unix_time(timestamp)
		return "[%s] %s[%s] %s" % [time_str, level_str, category_str, message]

	func to_json() -> Dictionary:
		return {
			"timestamp": timestamp,
			"level": level,
			"category": category,
			"message": message,
			"context": context,
			"stack_trace": stack_trace,
			"session_id": session_id,
			"user_action": user_action
		}

	func _level_to_string(lvl: LogLevel) -> String:
		match lvl:
			LogLevel.TRACE: return "TRACE"
			LogLevel.DEBUG: return "DEBUG"
			LogLevel.INFO: return "INFO "
			LogLevel.WARNING: return "WARN "
			LogLevel.ERROR: return "ERROR"
			LogLevel.CRITICAL: return "CRIT "
			_: return "UNKN "

	func _category_to_string(cat: LogCategory) -> String:
		match cat:
			LogCategory.SYSTEM: return "SYS"
			LogCategory.GAME: return "GAME"
			LogCategory.UI: return "UI"
			LogCategory.INPUT: return "INPUT"
			LogCategory.PERFORMANCE: return "PERF"
			LogCategory.AUDIT: return "AUDIT"
			LogCategory.SIMULATION: return "SIM"
			LogCategory.DATA: return "DATA"
			LogCategory.NETWORK: return "NET"
			LogCategory.DEBUG: return "DEBUG"
			_: return "UNKN"

# Configuration
var logging_enabled: bool = true
var console_logging: bool = true
var file_logging: bool = true
var audit_logging: bool = true
var memory_logging: bool = true

var min_log_level: LogLevel = LogLevel.INFO
var min_console_level: LogLevel = LogLevel.INFO
var min_file_level: LogLevel = LogLevel.DEBUG
var min_audit_level: LogLevel = LogLevel.INFO

# File logging
var log_directory: String = "user://logs/"
var log_file_prefix: String = "debatnacht"
var max_log_file_size: int = 10 * 1024 * 1024  # 10MB
var max_log_files: int = 5
var current_log_file: FileAccess
var current_audit_file: FileAccess

# Memory logging
var memory_log_buffer: Array[LogEntry] = []
var max_memory_entries: int = 1000

# Session tracking
var session_id: String = ""
var session_start_time: float = 0.0
var user_action_count: int = 0
var error_count: int = 0

# Constitutional transparency features
var transparency_mode: bool = true
var audit_sensitive_actions: bool = true
var log_user_decisions: bool = true
var educational_context: bool = true

# Performance tracking
var log_performance_impact: bool = false
var logging_overhead_time: float = 0.0

# Signals
signal log_entry_added(entry: LogEntry)
signal log_file_rotated(old_file: String, new_file: String)
signal audit_event_logged(entry: LogEntry)
signal critical_error_detected(entry: LogEntry)

func _ready() -> void:
	# Initialize singleton
	if _instance == null:
		_instance = self
		process_mode = Node.PROCESS_MODE_ALWAYS

		# Initialize logging system
		_initialize_logging_system()

		# Initialize dependencies
		_initialize_dependencies()

		# Setup file logging
		_setup_file_logging()

		# Log system startup
		log_message(LogLevel.INFO, LogCategory.SYSTEM, "LoggingManager initialized - constitutional transparency enabled")
	else:
		queue_free()

static func get_instance() -> LoggingManager:
	"""Get singleton instance of LoggingManager"""
	if _instance == null:
		# Create instance if it doesn't exist
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree:
			_instance = LoggingManager.new()
			scene_tree.root.add_child(_instance)
	return _instance

func _initialize_logging_system() -> void:
	"""Initialize the logging system with session tracking"""
	session_id = _generate_session_id()
	session_start_time = Time.get_unix_time_from_system()

	# Ensure log directory exists
	if not DirAccess.dir_exists_absolute(log_directory):
		DirAccess.open("user://").make_dir_recursive(log_directory)

	print("LoggingManager: Session ", session_id, " started")

func _initialize_dependencies() -> void:
	"""Initialize event bus connections"""
	event_bus = EventBus.get_instance()

	# Subscribe to all major event categories for logging
	if event_bus:
		event_bus.subscribe_to_all(_on_event_bus_message)

func _setup_file_logging() -> void:
	"""Setup file logging with rotation"""
	if not file_logging:
		return

	var timestamp = Time.get_datetime_string_from_unix_time(Time.get_unix_time_from_system()).replace(":", "-").replace(" ", "_")
	var log_filename = "%s_%s_%s.log" % [log_file_prefix, session_id, timestamp]
	var audit_filename = "%s_audit_%s_%s.log" % [log_file_prefix, session_id, timestamp]

	current_log_file = FileAccess.open(log_directory + log_filename, FileAccess.WRITE)
	current_audit_file = FileAccess.open(log_directory + audit_filename, FileAccess.WRITE)

	if current_log_file:
		current_log_file.store_line("=== Debatnacht Logging Session Started ===")
		current_log_file.store_line("Session ID: " + session_id)
		current_log_file.store_line("Started: " + Time.get_datetime_string_from_unix_time(session_start_time))
		current_log_file.store_line("Constitutional Transparency: " + str(transparency_mode))
		current_log_file.store_line("Educational Context: " + str(educational_context))
		current_log_file.store_line("=" * 50)
		current_log_file.flush()

	if current_audit_file:
		current_audit_file.store_line("=== Constitutional Transparency Audit Trail ===")
		current_audit_file.store_line("Session ID: " + session_id)
		current_audit_file.store_line("Purpose: Educational political simulation with full transparency")
		current_audit_file.store_line("Compliance: All user actions and system decisions are logged")
		current_audit_file.store_line("=" * 50)
		current_audit_file.flush()

# Core logging functionality
func log_message(level: LogLevel, category: LogCategory, message: String, context: Dictionary = {}, user_initiated: bool = false) -> void:
	"""Main logging function with full context"""
	if not logging_enabled or level < min_log_level:
		return

	var start_time = Time.get_unix_time_from_system() if log_performance_impact else 0.0

	var entry = LogEntry.new()
	entry.level = level
	entry.category = category
	entry.message = message
	entry.context = context.duplicate(true)
	entry.session_id = session_id
	entry.user_action = user_initiated

	# Add stack trace for errors
	if level >= LogLevel.ERROR:
		entry.stack_trace = get_stack()
		error_count += 1

	# Track user actions for constitutional transparency
	if user_initiated:
		user_action_count += 1

	# Route to appropriate logging targets
	_route_log_entry(entry)

	# Emit signal
	log_entry_added.emit(entry)

	# Special handling for critical errors
	if level == LogLevel.CRITICAL:
		critical_error_detected.emit(entry)

	# Track logging performance impact
	if log_performance_impact:
		logging_overhead_time += Time.get_unix_time_from_system() - start_time

func _route_log_entry(entry: LogEntry) -> void:
	"""Route log entry to appropriate targets"""
	# Console logging
	if console_logging and entry.level >= min_console_level:
		print(entry.to_string())

	# File logging
	if file_logging and current_log_file and entry.level >= min_file_level:
		current_log_file.store_line(entry.to_string())

		# Add context if available
		if not entry.context.is_empty():
			current_log_file.store_line("  Context: " + JSON.stringify(entry.context))

		current_log_file.flush()

		# Check for file rotation
		if current_log_file.get_position() > max_log_file_size:
			_rotate_log_file()

	# Audit logging for transparency
	if audit_logging and current_audit_file and (entry.category == LogCategory.AUDIT or entry.user_action):
		_write_audit_entry(entry)

	# Memory logging
	if memory_logging:
		memory_log_buffer.append(entry)
		if memory_log_buffer.size() > max_memory_entries:
			memory_log_buffer.pop_front()

func _write_audit_entry(entry: LogEntry) -> void:
	"""Write entry to audit trail with enhanced context"""
	if not current_audit_file:
		return

	current_audit_file.store_line("")
	current_audit_file.store_line("--- Audit Entry ---")
	current_audit_file.store_line(entry.to_string())

	if entry.user_action:
		current_audit_file.store_line("** USER-INITIATED ACTION **")

	if not entry.context.is_empty():
		current_audit_file.store_line("Context: " + JSON.stringify(entry.context, "\t"))

	if not entry.stack_trace.is_empty():
		current_audit_file.store_line("Stack Trace:")
		current_audit_file.store_line(entry.stack_trace)

	current_audit_file.store_line("------------------")
	current_audit_file.flush()

	audit_event_logged.emit(entry)

# Convenience logging functions
func trace(category: LogCategory, message: String, context: Dictionary = {}) -> void:
	"""Log trace level message"""
	log_message(LogLevel.TRACE, category, message, context)

func debug(category: LogCategory, message: String, context: Dictionary = {}) -> void:
	"""Log debug level message"""
	log_message(LogLevel.DEBUG, category, message, context)

func info(category: LogCategory, message: String, context: Dictionary = {}) -> void:
	"""Log info level message"""
	log_message(LogLevel.INFO, category, message, context)

func warning(category: LogCategory, message: String, context: Dictionary = {}) -> void:
	"""Log warning level message"""
	log_message(LogLevel.WARNING, category, message, context)

func error(category: LogCategory, message: String, context: Dictionary = {}) -> void:
	"""Log error level message"""
	log_message(LogLevel.ERROR, category, message, context)

func critical(category: LogCategory, message: String, context: Dictionary = {}) -> void:
	"""Log critical level message"""
	log_message(LogLevel.CRITICAL, category, message, context)

# User action logging for constitutional transparency
func log_user_action(action: String, details: Dictionary = {}) -> void:
	"""Log user action with full transparency context"""
	var context = details.duplicate(true)
	context["action_type"] = "user_decision"
	context["transparency"] = "constitutional_requirement"
	context["educational_purpose"] = "democratic_simulation"

	log_message(LogLevel.INFO, LogCategory.AUDIT, "User action: " + action, context, true)

func log_simulation_decision(decision: String, rationale: String, data: Dictionary = {}) -> void:
	"""Log simulation decision for educational transparency"""
	var context = data.duplicate(true)
	context["decision_rationale"] = rationale
	context["transparency_level"] = "full"
	context["educational_value"] = "demonstrate_political_process"

	log_message(LogLevel.INFO, LogCategory.SIMULATION, "Simulation decision: " + decision, context)

func log_system_state_change(component: String, old_state: String, new_state: String, reason: String) -> void:
	"""Log system state changes for debugging"""
	var context = {
		"component": component,
		"old_state": old_state,
		"new_state": new_state,
		"change_reason": reason
	}

	log_message(LogLevel.DEBUG, LogCategory.SYSTEM, "State change in " + component, context)

func log_performance_metric(metric_name: String, value: float, threshold: float = 0.0, unit: String = "") -> void:
	"""Log performance metrics"""
	var context = {
		"metric": metric_name,
		"value": value,
		"unit": unit,
		"threshold": threshold,
		"exceeded": value > threshold if threshold > 0.0 else false
	}

	var level = LogLevel.WARNING if context.exceeded else LogLevel.DEBUG
	log_message(level, LogCategory.PERFORMANCE, "Performance metric: %s = %s%s" % [metric_name, value, unit], context)

# Event bus integration
func _on_event_bus_message(event_type: EventBus.EventType, data: Dictionary, category: EventBus.EventCategory) -> void:
	"""Handle events from event bus for logging"""
	var log_category = _map_event_category_to_log_category(category)
	var context = data.duplicate(true)
	context["event_bus_category"] = category

	var message = "EventBus: " + EventBus.event_type_to_string(event_type)

	# Determine if this was user-initiated
	var user_initiated = data.get("user_initiated", false)

	# Set appropriate log level based on event type
	var level = LogLevel.INFO
	match event_type:
		EventBus.ERROR_OCCURRED, EventBus.CRITICAL_ERROR:
			level = LogLevel.ERROR
		EventBus.WARNING_ISSUED:
			level = LogLevel.WARNING
		EventBus.DEBUG_INFO:
			level = LogLevel.DEBUG

	log_message(level, log_category, message, context, user_initiated)

func _map_event_category_to_log_category(event_category: EventBus.EventCategory) -> LogCategory:
	"""Map event bus categories to logging categories"""
	match event_category:
		EventBus.EventCategory.SYSTEM: return LogCategory.SYSTEM
		EventBus.EventCategory.GAME: return LogCategory.GAME
		EventBus.EventCategory.UI: return LogCategory.UI
		EventBus.EventCategory.INPUT: return LogCategory.INPUT
		EventBus.EventCategory.AUDIT: return LogCategory.AUDIT
		EventBus.EventCategory.DEBUG: return LogCategory.DEBUG
		_: return LogCategory.SYSTEM

# File management
func _rotate_log_file() -> void:
	"""Rotate log files when they get too large"""
	if not current_log_file:
		return

	var old_path = current_log_file.get_path()
	current_log_file.close()

	# Create new log file
	var timestamp = Time.get_datetime_string_from_unix_time(Time.get_unix_time_from_system()).replace(":", "-").replace(" ", "_")
	var new_filename = "%s_%s_%s.log" % [log_file_prefix, session_id, timestamp]
	current_log_file = FileAccess.open(log_directory + new_filename, FileAccess.WRITE)

	if current_log_file:
		current_log_file.store_line("=== Rotated Log File ===")
		current_log_file.store_line("Previous file: " + old_path)
		current_log_file.store_line("Session continues: " + session_id)
		current_log_file.flush()

	log_file_rotated.emit(old_path, current_log_file.get_path() if current_log_file else "")

	# Clean up old log files
	_cleanup_old_log_files()

func _cleanup_old_log_files() -> void:
	"""Remove old log files beyond retention limit"""
	var dir = DirAccess.open(log_directory)
	if not dir:
		return

	var files: Array[String] = []
	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.begins_with(log_file_prefix) and file_name.ends_with(".log"):
			files.append(file_name)
		file_name = dir.get_next()

	# Sort by modification time (newest first)
	files.sort_custom(_compare_file_times)

	# Remove excess files
	while files.size() > max_log_files:
		var file_to_remove = files.pop_back()
		dir.remove(file_to_remove)
		log_message(LogLevel.INFO, LogCategory.SYSTEM, "Removed old log file: " + file_to_remove)

func _compare_file_times(a: String, b: String) -> bool:
	"""Compare file modification times for sorting"""
	var file_a = FileAccess.open(log_directory + a, FileAccess.READ)
	var file_b = FileAccess.open(log_directory + b, FileAccess.READ)

	if not file_a or not file_b:
		return false

	var time_a = FileAccess.get_modified_time(file_a.get_path())
	var time_b = FileAccess.get_modified_time(file_b.get_path())

	file_a.close()
	file_b.close()

	return time_a > time_b

# Query and analysis
func get_logs_by_category(category: LogCategory, max_count: int = 100) -> Array[LogEntry]:
	"""Get recent logs by category"""
	var result: Array[LogEntry] = []
	var count = 0

	for i in range(memory_log_buffer.size() - 1, -1, -1):
		if count >= max_count:
			break

		var entry = memory_log_buffer[i]
		if entry.category == category:
			result.append(entry)
			count += 1

	return result

func get_logs_by_level(level: LogLevel, max_count: int = 100) -> Array[LogEntry]:
	"""Get recent logs by level"""
	var result: Array[LogEntry] = []
	var count = 0

	for i in range(memory_log_buffer.size() - 1, -1, -1):
		if count >= max_count:
			break

		var entry = memory_log_buffer[i]
		if entry.level >= level:
			result.append(entry)
			count += 1

	return result

func get_user_action_log_message() -> Array[LogEntry]:
	"""Get all user-initiated actions for audit trail"""
	var result: Array[LogEntry] = []

	for entry in memory_log_buffer:
		if entry.user_action:
			result.append(entry)

	return result

func search_logs(search_term: String, max_count: int = 50) -> Array[LogEntry]:
	"""Search logs by message content"""
	var result: Array[LogEntry] = []
	var count = 0

	for i in range(memory_log_buffer.size() - 1, -1, -1):
		if count >= max_count:
			break

		var entry = memory_log_buffer[i]
		if entry.message.to_lower().contains(search_term.to_lower()):
			result.append(entry)
			count += 1

	return result

# Statistics and reporting
func get_logging_statistics() -> Dictionary:
	"""Get comprehensive logging statistics"""
	var level_counts = {}
	var category_counts = {}

	for entry in memory_log_buffer:
		var level_key = str(entry.level)
		var category_key = str(entry.category)

		level_counts[level_key] = level_counts.get(level_key, 0) + 1
		category_counts[category_key] = category_counts.get(category_key, 0) + 1

	return {
		"session_id": session_id,
		"session_duration": Time.get_unix_time_from_system() - session_start_time,
		"total_entries": memory_log_buffer.size(),
		"user_actions": user_action_count,
		"error_count": error_count,
		"level_distribution": level_counts,
		"category_distribution": category_counts,
		"logging_overhead": logging_overhead_time
	}

func export_audit_report() -> String:
	"""Export complete audit report for constitutional transparency"""
	var report = "=== Constitutional Transparency Audit Report ===\n"
	report += "Generated: " + Time.get_datetime_string_from_unix_time(Time.get_unix_time_from_system()) + "\n"
	report += "Session ID: " + session_id + "\n"
	report += "Educational Purpose: Democratic simulation with full transparency\n\n"

	report += "=== Session Statistics ===\n"
	var stats = get_logging_statistics()
	for key in stats:
		report += key + ": " + str(stats[key]) + "\n"

	report += "\n=== User Actions (Constitutional Requirement) ===\n"
	var user_actions = get_user_action_log_message()
	for action in user_actions:
		report += action.to_string() + "\n"

	report += "\n=== System Decisions (Educational Transparency) ===\n"
	var sim_logs = get_logs_by_category(LogCategory.SIMULATION)
	for log_entry in sim_logs:
		report += log_entry.to_string() + "\n"

	report += "\n=== Errors and Issues ===\n"
	var errors = get_logs_by_level(LogLevel.ERROR)
	for error in errors:
		report += error.to_string() + "\n"

	return report

# Configuration
func set_log_level(level: LogLevel) -> void:
	"""Set minimum log level"""
	min_log_level = level
	log_message(LogLevel.INFO, LogCategory.SYSTEM, "Log level changed to: " + str(level))

func set_console_level(level: LogLevel) -> void:
	"""Set console log level"""
	min_console_level = level

func set_file_level(level: LogLevel) -> void:
	"""Set file log level"""
	min_file_level = level

func enable_category_logging(category: LogCategory, enabled: bool) -> void:
	"""Enable/disable logging for specific category"""
	# Would implement category-specific filtering
	log_message(LogLevel.INFO, LogCategory.SYSTEM, "Category logging changed: " + str(category) + " = " + str(enabled))

func set_transparency_mode(enabled: bool) -> void:
	"""Enable/disable constitutional transparency mode"""
	transparency_mode = enabled
	log_message(LogLevel.INFO, LogCategory.SYSTEM, "Constitutional transparency mode: " + str(enabled))

# Utility functions
func _generate_session_id() -> String:
	"""Generate unique session identifier"""
	var timestamp = str(int(Time.get_unix_time_from_system()))
	var random_part = str(randi() % 10000).pad_zeros(4)
	return timestamp + "_" + random_part

func flush_all_logs() -> void:
	"""Flush all log files to disk"""
	if current_log_file:
		current_log_file.flush()
	if current_audit_file:
		current_audit_file.flush()

# Debug functionality
func print_memory_logs(max_count: int = 20) -> void:
	"""Print recent memory logs to console"""
	print("=== Recent Log Entries ===")
	var count = 0
	for i in range(memory_log_buffer.size() - 1, -1, -1):
		if count >= max_count:
			break
		print(memory_log_buffer[i].to_string())
		count += 1
	print("==========================")

func print_logging_status() -> void:
	"""Print current logging system status"""
	print("=== LoggingManager Status ===")
	print("Enabled: ", logging_enabled)
	print("Session ID: ", session_id)
	print("Min Level: ", min_log_level)
	print("Console: ", console_logging, " (", min_console_level, ")")
	print("File: ", file_logging, " (", min_file_level, ")")
	print("Audit: ", audit_logging)
	print("Memory Buffer: ", memory_log_buffer.size(), "/", max_memory_entries)
	print("User Actions: ", user_action_count)
	print("Errors: ", error_count)
	print("Transparency Mode: ", transparency_mode)
	print("============================")

# Cleanup
func _exit_tree() -> void:
	"""Cleanup logging system on shutdown"""
	# Log shutdown
	log_message(LogLevel.INFO, LogCategory.SYSTEM, "LoggingManager shutting down - session ending")

	# Export final audit report
	if audit_logging:
		var report = export_audit_report()
		if current_audit_file:
			current_audit_file.store_line("\n" + report)

	# Close files
	if current_log_file:
		current_log_file.store_line("=== Session Ended ===")
		current_log_file.close()

	if current_audit_file:
		current_audit_file.store_line("=== Audit Session Ended ===")
		current_audit_file.close()

	# Clear memory
	memory_log_buffer.clear()

	# Clear singleton reference
	if _instance == self:
		_instance = null

	print("LoggingManager: Cleaned up session ", session_id)