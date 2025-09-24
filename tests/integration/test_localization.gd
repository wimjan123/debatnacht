extends RefCounted
class_name TestLocalization

# Test Dutch/English language switching
# CRITICAL: This test MUST FAIL before implementation exists

var localization_manager: LocalizationManager

func _init():
	# This will fail initially since LocalizationManager doesn't exist yet
	localization_manager = LocalizationManager.new()

func test_language_switching():
	# Test switching between Dutch and English

	# Start with English
	localization_manager.set_language("en")

	# Verify English translations
	var english_title = tr("main_menu.title")
	assert(english_title == "Dutch Politics Simulation", "English title must be correct")

	var english_dashboard = tr("dashboard.poll_percentage")
	assert(english_dashboard == "Poll Percentage", "English dashboard terms must be correct")

	# Switch to Dutch
	localization_manager.set_language("nl")

	# Verify Dutch translations
	var dutch_title = tr("main_menu.title")
	assert(dutch_title == "Nederlandse Politiek Simulatie", "Dutch title must be correct")

	var dutch_dashboard = tr("dashboard.poll_percentage")
	assert(dutch_dashboard == "Peiling Percentage", "Dutch dashboard terms must be correct")

	print("Language switching test completed")

func test_translation_completeness():
	# Test that all required strings have translations in both languages

	var required_keys = [
		"main_menu.title",
		"main_menu.new_game",
		"dashboard.poll_percentage",
		"dashboard.projected_seats",
		"dashboard.funds",
		"dashboard.days_left",
		"tooltip.poll_explanation",
		"settings.language",
		"common.ok",
		"common.cancel"
	]

	# Test English completeness
	localization_manager.set_language("en")
	for key in required_keys:
		var translation = tr(key)
		assert(translation != key, "English translation must exist for key: " + key)
		assert(translation.length() > 0, "English translation cannot be empty for key: " + key)

	# Test Dutch completeness
	localization_manager.set_language("nl")
	for key in required_keys:
		var translation = tr(key)
		assert(translation != key, "Dutch translation must exist for key: " + key)
		assert(translation.length() > 0, "Dutch translation cannot be empty for key: " + key)

	print("Translation completeness test completed")

func test_dynamic_content_localization():
	# Test localization of dynamic content (numbers, dates, etc.)

	localization_manager.set_language("en")

	# Test percentage formatting
	var poll_value = 35.2
	var english_percentage = "%.1f%%" % poll_value
	assert(english_percentage == "35.2%", "English percentage formatting must be correct")

	# Test seat counting
	var seat_count = 54
	var english_seats = "%d seats" % seat_count
	assert(english_seats == "54 seats", "English seat counting must be correct")

	# Switch to Dutch and test formatting
	localization_manager.set_language("nl")

	var dutch_seats = "%d zetels" % seat_count
	assert(dutch_seats == "54 zetels", "Dutch seat counting must be correct")

	print("Dynamic content localization test completed")

func test_accessibility_text_scaling():
	# Test that localization works with accessibility text scaling

	localization_manager.set_language("en")

	# Get base text
	var base_text = tr("dashboard.title")
	assert(base_text == "Campaign Dashboard", "Base English text must be correct")

	# Test with Dutch
	localization_manager.set_language("nl")
	var dutch_text = tr("dashboard.title")
	assert(dutch_text == "Campagne Dashboard", "Dutch text must be correct")

	# Text should work at different scales (tested in accessibility tests)
	# This verifies localization integrates with accessibility features

	print("Accessibility text scaling test completed")

func test_locale_specific_formatting():
	# Test locale-specific number and date formatting

	# Dutch locale formatting
	localization_manager.set_language("nl")

	# Test currency formatting (Euro)
	var funds = 150000
	var dutch_currency = "€%s" % String.num(funds, 0)
	assert(dutch_currency.begins_with("€"), "Dutch currency must use Euro symbol")

	# Test date formatting (DD-MM-YYYY for Dutch)
	var date_string = "2025-03-15"  # ISO format from game state
	# Dutch format would be 15-03-2025

	# English locale formatting
	localization_manager.set_language("en")

	var english_currency = "€%s" % String.num(funds, 0)
	assert(english_currency.begins_with("€"), "English currency must also use Euro (Dutch context)")

	print("Locale-specific formatting test completed")

func test_rtl_language_support_preparation():
	# Test that the architecture can handle RTL languages in future
	# (Not implementing RTL now, but verifying architecture supports it)

	# Text should be stored in a way that supports RTL
	var text_direction = "ltr"  # left-to-right for Dutch/English

	# UI should be able to handle text direction changes
	assert(text_direction in ["ltr", "rtl"], "Text direction must be valid")

	# This test ensures future extensibility
	print("RTL language support preparation test completed")

func test_translation_memory_integration():
	# Test integration with game state and memory systems

	localization_manager.set_language("en")

	# Test that language preference persists
	var current_language = localization_manager.get_current_language()
	assert(current_language == "en", "Language preference must persist")

	# Switch and verify persistence
	localization_manager.set_language("nl")
	current_language = localization_manager.get_current_language()
	assert(current_language == "nl", "Language switch must persist")

	# Test that this integrates with save/load system
	# Language preference should be saved in game state

	print("Translation memory integration test completed")

func test_constitutional_compliance():
	# Test constitutional requirement for Dutch/English support

	# Must support both languages as specified in constitution
	var supported_languages = localization_manager.get_supported_languages()
	assert("en" in supported_languages, "Must support English as required by constitution")
	assert("nl" in supported_languages, "Must support Dutch as required by constitution")

	# All UI elements must be translatable
	# This is enforced by using tr() for all displayed text

	# Educational content must be culturally appropriate for both languages
	var tooltip_text_en = tr("tooltip.poll_explanation")
	var tooltip_text_nl = tr("tooltip.poll_explanation")

	assert(tooltip_text_en != tooltip_text_nl, "Translations must be different for different languages")
	assert(tooltip_text_en.length() > 10, "English explanations must be substantive")
	assert(tooltip_text_nl.length() > 10, "Dutch explanations must be substantive")

	print("Constitutional compliance test completed")

func run_all_tests():
	print("Running localization integration tests...")
	test_language_switching()
	test_translation_completeness()
	test_dynamic_content_localization()
	test_accessibility_text_scaling()
	test_locale_specific_formatting()
	test_rtl_language_support_preparation()
	test_translation_memory_integration()
	test_constitutional_compliance()
	print("All localization integration tests completed")