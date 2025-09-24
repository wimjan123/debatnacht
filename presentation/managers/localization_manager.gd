extends RefCounted
class_name LocalizationManager

# Localization manager for runtime language switching between Dutch and English
# Implements constitutional requirement for Dutch/English accessibility

var current_language: String = "en"
var supported_languages: Array[String] = ["en", "nl"]
var translations_loaded: bool = false

signal language_changed(new_language: String)

func _init():
	_load_translations()

func set_language(language_code: String) -> void:
	if language_code not in supported_languages:
		push_error("Unsupported language: " + language_code)
		return

	if current_language == language_code:
		return  # No change needed

	current_language = language_code
	TranslationServer.set_locale(language_code)

	# Emit signal for UI components to update
	language_changed.emit(language_code)

func get_current_language() -> String:
	return current_language

func get_supported_languages() -> Array[String]:
	return supported_languages.duplicate()

func is_language_supported(language_code: String) -> bool:
	return language_code in supported_languages

func get_localized_text(key: String) -> String:
	return tr(key)

func format_percentage(value: float) -> String:
	# Localized percentage formatting
	return "%.1f%%" % value

func format_currency(amount: int) -> String:
	# Format currency for Dutch context (Euro)
	match current_language:
		"nl":
			return "€%s" % String.num(amount, 0).replace(",", ".")
		"en":
			return "€%s" % String.num(amount, 0)
		_:
			return "€%s" % String.num(amount, 0)

func format_seat_count(count: int) -> String:
	# Localized seat count formatting
	match current_language:
		"nl":
			if count == 1:
				return "1 zetel"
			else:
				return "%d zetels" % count
		"en":
			if count == 1:
				return "1 seat"
			else:
				return "%d seats" % count
		_:
			return "%d seats" % count

func format_date(date_string: String) -> String:
	# Format date according to local conventions
	# Input: ISO format (YYYY-MM-DD)
	var date_parts = date_string.split("-")
	if date_parts.size() != 3:
		return date_string  # Return original if invalid

	var year = date_parts[0]
	var month = date_parts[1]
	var day = date_parts[2]

	match current_language:
		"nl":
			return "%s-%s-%s" % [day, month, year]  # DD-MM-YYYY
		"en":
			return "%s/%s/%s" % [month, day, year]  # MM/DD/YYYY
		_:
			return date_string

func get_month_name(month_number: int) -> String:
	# Get localized month name
	var month_keys = [
		"", "month.january", "month.february", "month.march", "month.april",
		"month.may", "month.june", "month.july", "month.august",
		"month.september", "month.october", "month.november", "month.december"
	]

	if month_number < 1 or month_number > 12:
		return ""

	return tr(month_keys[month_number])

func get_party_name(party_id: String, fallback_name: String = "") -> String:
	# Get localized party name if available
	var key = "party." + party_id + ".name"
	var localized = tr(key)

	# If translation doesn't exist, tr() returns the key
	if localized == key:
		return fallback_name if fallback_name != "" else party_id
	else:
		return localized

func get_region_name(region_id: String, fallback_name: String = "") -> String:
	# Get localized region name if available
	var key = "region." + region_id + ".name"
	var localized = tr(key)

	# If translation doesn't exist, tr() returns the key
	if localized == key:
		return fallback_name if fallback_name != "" else region_id
	else:
		return localized

func get_policy_description(policy_key: String) -> String:
	# Get localized policy description
	var key = "policy." + policy_key + ".description"
	return tr(key)

func get_help_text(context: String) -> String:
	# Get context-sensitive help text
	var key = "help." + context
	return tr(key)

func validate_translations() -> Dictionary:
	# Validate that critical translations exist in both languages
	var validation_results = {
		"missing_english": [],
		"missing_dutch": [],
		"validation_passed": true
	}

	var critical_keys = [
		"main_menu.title",
		"dashboard.poll_percentage",
		"dashboard.projected_seats",
		"dashboard.funds",
		"dashboard.days_left",
		"tooltip.poll_explanation",
		"settings.language",
		"common.ok",
		"common.cancel"
	]

	# Check English translations
	set_language("en")
	for key in critical_keys:
		var translation = tr(key)
		if translation == key:  # Translation not found
			validation_results.missing_english.append(key)
			validation_results.validation_passed = false

	# Check Dutch translations
	set_language("nl")
	for key in critical_keys:
		var translation = tr(key)
		if translation == key:  # Translation not found
			validation_results.missing_dutch.append(key)
			validation_results.validation_passed = false

	return validation_results

func _load_translations() -> void:
	# Load translation files
	var en_translation = load("res://config/localization/strings_en.translation")
	var nl_translation = load("res://config/localization/strings_nl.translation")

	if en_translation == null:
		push_error("Failed to load English translations")
		return

	if nl_translation == null:
		push_error("Failed to load Dutch translations")
		return

	# Add translations to translation server
	TranslationServer.add_translation(en_translation)
	TranslationServer.add_translation(nl_translation)

	# Set initial locale
	TranslationServer.set_locale(current_language)
	translations_loaded = true

# Constitutional compliance helpers

func get_accessibility_text(key: String) -> String:
	# Get accessibility-specific text (for screen readers, etc.)
	var accessibility_key = "accessibility." + key
	var accessible_text = tr(accessibility_key)

	# If no specific accessibility text, use regular translation
	if accessible_text == accessibility_key:
		return tr(key)
	else:
		return accessible_text

func get_explanation_text(metric: String) -> String:
	# Get detailed explanation text for transparency
	var explanation_key = "explanation." + metric
	return tr(explanation_key)

func get_constitutional_text(requirement: String) -> String:
	# Get text related to constitutional requirements
	var const_key = "constitutional." + requirement
	return tr(const_key)

# Integration with UI state

func apply_to_ui_state(ui_state: UIState) -> void:
	# Update UI state with current language setting
	if ui_state != null:
		ui_state.language_setting = current_language

func load_from_ui_state(ui_state: UIState) -> void:
	# Load language setting from UI state
	if ui_state != null and ui_state.language_setting in supported_languages:
		set_language(ui_state.language_setting)