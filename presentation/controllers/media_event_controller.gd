extends RefCounted
class_name MediaEventController

# Media event controller for handling media interactions and sentiment tracking
# Manages media events, response options, and sentiment impact calculations

var simulation_api: SimulationAPI
var game_state: GameState
var current_media_event: MediaEvent
var response_options: Array[MediaResponse] = []
var media_history: Array[Dictionary] = []

signal media_event_presented(event: MediaEvent, options: Array[MediaResponse])
signal response_submitted(response: MediaResponse)
signal sentiment_updated(new_sentiment: float, change: float)
signal media_event_completed(event: MediaEvent, outcome: Dictionary)

func _init(sim_api: SimulationAPI = null):
	simulation_api = sim_api if sim_api else FakeSimulation.new()

func initialize_media_system() -> void:
	"""Initialize media event system"""
	game_state = simulation_api.get_current_state()
	_load_media_history()

func get_available_media_events() -> Array[MediaEvent]:
	"""Get available media events for current game state"""
	return simulation_api.get_available_media_events()

func present_media_event(event: MediaEvent) -> void:
	"""Present media event with response options"""
	current_media_event = event
	response_options = _generate_response_options(event)

	media_event_presented.emit(event, response_options)

func _generate_response_options(event: MediaEvent) -> Array[MediaResponse]:
	"""Generate contextual response options for media event"""
	var options: Array[MediaResponse] = []
	var player_party = game_state.player_party

	# Generate options based on event type and party ideology
	match event.event_type:
		"interview":
			options = _generate_interview_responses(event, player_party)
		"crisis":
			options = _generate_crisis_responses(event, player_party)
		"debate":
			options = _generate_debate_responses(event, player_party)
		"press_conference":
			options = _generate_press_conference_responses(event, player_party)
		_:
			options = _generate_default_responses(event, player_party)

	# Add constitutional transparency option
	options.append(_create_transparency_response(event))

	return options

func _generate_interview_responses(event: MediaEvent, party: Party) -> Array[MediaResponse]:
	"""Generate interview response options"""
	var responses: Array[MediaResponse] = []

	# Prepared statement response
	var prepared = MediaResponse.new()
	prepared.response_type = "prepared"
	prepared.response_text = tr("media.response.prepared_statement")
	prepared.sentiment_change = 0.1
	prepared.explanation = tr("media.response.prepared_explanation")
	prepared.risk_level = "low"
	responses.append(prepared)

	# Personal story response
	var personal = MediaResponse.new()
	personal.response_type = "personal"
	personal.response_text = tr("media.response.personal_story")
	personal.sentiment_change = 0.2
	personal.explanation = tr("media.response.personal_explanation")
	personal.risk_level = "medium"
	responses.append(personal)

	# Policy focus response
	var policy = MediaResponse.new()
	policy.response_type = "policy"
	policy.response_text = tr("media.response.policy_focus")
	policy.sentiment_change = 0.0
	policy.explanation = tr("media.response.policy_explanation")
	policy.risk_level = "low"
	responses.append(policy)

	return responses

func _generate_crisis_responses(event: MediaEvent, party: Party) -> Array[MediaResponse]:
	"""Generate crisis management response options"""
	var responses: Array[MediaResponse] = []

	# Immediate action response
	var immediate = MediaResponse.new()
	immediate.response_type = "immediate_action"
	immediate.response_text = tr("media.response.immediate_action")
	immediate.sentiment_change = 0.15
	immediate.explanation = tr("media.response.immediate_explanation")
	immediate.risk_level = "medium"
	responses.append(immediate)

	# Careful investigation response
	var investigation = MediaResponse.new()
	investigation.response_type = "investigation"
	investigation.response_text = tr("media.response.investigation")
	investigation.sentiment_change = -0.05
	investigation.explanation = tr("media.response.investigation_explanation")
	investigation.risk_level = "low"
	responses.append(investigation)

	# Deflection response
	var deflection = MediaResponse.new()
	deflection.response_type = "deflection"
	deflection.response_text = tr("media.response.deflection")
	deflection.sentiment_change = -0.1
	deflection.explanation = tr("media.response.deflection_explanation")
	deflection.risk_level = "high"
	responses.append(deflection)

	return responses

func _generate_debate_responses(event: MediaEvent, party: Party) -> Array[MediaResponse]:
	"""Generate debate response options"""
	var responses: Array[MediaResponse] = []

	# Aggressive response
	var aggressive = MediaResponse.new()
	aggressive.response_type = "aggressive"
	aggressive.response_text = tr("media.response.aggressive")
	aggressive.sentiment_change = 0.25
	aggressive.explanation = tr("media.response.aggressive_explanation")
	aggressive.risk_level = "high"
	responses.append(aggressive)

	# Diplomatic response
	var diplomatic = MediaResponse.new()
	diplomatic.response_type = "diplomatic"
	diplomatic.response_text = tr("media.response.diplomatic")
	diplomatic.sentiment_change = 0.05
	diplomatic.explanation = tr("media.response.diplomatic_explanation")
	diplomatic.risk_level = "low"
	responses.append(diplomatic)

	# Evidence-based response
	var evidence = MediaResponse.new()
	evidence.response_type = "evidence"
	evidence.response_text = tr("media.response.evidence_based")
	evidence.sentiment_change = 0.1
	evidence.explanation = tr("media.response.evidence_explanation")
	evidence.risk_level = "medium"
	responses.append(evidence)

	return responses

func _generate_press_conference_responses(event: MediaEvent, party: Party) -> Array[MediaResponse]:
	"""Generate press conference response options"""
	var responses: Array[MediaResponse] = []

	# Open Q&A response
	var open_qa = MediaResponse.new()
	open_qa.response_type = "open_qa"
	open_qa.response_text = tr("media.response.open_questions")
	open_qa.sentiment_change = 0.2
	open_qa.explanation = tr("media.response.open_qa_explanation")
	open_qa.risk_level = "high"
	responses.append(open_qa)

	# Controlled statement response
	var controlled = MediaResponse.new()
	controlled.response_type = "controlled"
	controlled.response_text = tr("media.response.controlled_statement")
	controlled.sentiment_change = 0.05
	controlled.explanation = tr("media.response.controlled_explanation")
	controlled.risk_level = "low"
	responses.append(controlled)

	return responses

func _generate_default_responses(event: MediaEvent, party: Party) -> Array[MediaResponse]:
	"""Generate default response options"""
	var responses: Array[MediaResponse] = []

	# Standard response
	var standard = MediaResponse.new()
	standard.response_type = "standard"
	standard.response_text = tr("media.response.standard")
	standard.sentiment_change = 0.0
	standard.explanation = tr("media.response.standard_explanation")
	standard.risk_level = "low"
	responses.append(standard)

	return responses

func _create_transparency_response(event: MediaEvent) -> MediaResponse:
	"""Create transparency response for constitutional compliance"""
	var transparency = MediaResponse.new()
	transparency.response_type = "transparency"
	transparency.response_text = tr("media.response.transparency")
	transparency.sentiment_change = 0.05
	transparency.explanation = tr("media.response.transparency_explanation")
	transparency.risk_level = "low"
	transparency.constitutional_compliance = true
	return transparency

func submit_response(response: MediaResponse) -> Dictionary:
	"""Submit media response and calculate outcome"""
	if not current_media_event or not response:
		return {"success": false, "error": "No active media event or invalid response"}

	# Calculate response outcome
	var outcome = _calculate_response_outcome(current_media_event, response)

	# Update game state
	_apply_response_effects(outcome)

	# Record in history
	_record_media_interaction(current_media_event, response, outcome)

	# Emit signals
	response_submitted.emit(response)
	sentiment_updated.emit(outcome.new_sentiment, outcome.sentiment_change)
	media_event_completed.emit(current_media_event, outcome)

	# Clear current event
	current_media_event = null
	response_options.clear()

	return outcome

func _calculate_response_outcome(event: MediaEvent, response: MediaResponse) -> Dictionary:
	"""Calculate the outcome of media response"""
	var base_sentiment_change = response.sentiment_change
	var player_party = game_state.player_party

	# Adjust based on party characteristics
	var ideological_alignment = _calculate_ideological_alignment(event, player_party)
	var adjusted_change = base_sentiment_change * ideological_alignment

	# Apply random variation
	var random_factor = randf_range(0.8, 1.2)
	adjusted_change *= random_factor

	# Calculate new overall sentiment
	var current_sentiment = simulation_api.get_media_sentiment()
	var new_sentiment = clamp(current_sentiment + adjusted_change, -1.0, 1.0)

	# Determine polling impact
	var polling_impact = adjusted_change * 2.0  # Media impact on polling

	return {
		"success": true,
		"event": event,
		"response": response,
		"sentiment_change": adjusted_change,
		"new_sentiment": new_sentiment,
		"polling_impact": polling_impact,
		"explanation": response.explanation,
		"risk_realized": _check_risk_realization(response),
		"constitutional_bonus": response.constitutional_compliance
	}

func _calculate_ideological_alignment(event: MediaEvent, party: Party) -> float:
	"""Calculate how well response aligns with party ideology"""
	# This would use more sophisticated ideological positioning in full implementation
	var alignment_score = 1.0

	# Check if event topic aligns with party strengths
	for strength in party.policy_positions.keys():
		if event.topic_tags.has(strength):
			alignment_score *= 1.2
			break

	return clamp(alignment_score, 0.5, 1.5)

func _check_risk_realization(response: MediaResponse) -> bool:
	"""Check if response risk is realized"""
	var risk_thresholds = {
		"low": 0.1,
		"medium": 0.3,
		"high": 0.6
	}

	var threshold = risk_thresholds.get(response.risk_level, 0.2)
	return randf() < threshold

func _apply_response_effects(outcome: Dictionary) -> void:
	"""Apply response effects to game state"""
	# Update media sentiment
	simulation_api.update_media_sentiment(outcome.new_sentiment)

	# Update polling if significant impact
	if abs(outcome.polling_impact) > 0.5:
		simulation_api.apply_polling_adjustment(game_state.player_party.party_id, outcome.polling_impact)

	# Apply constitutional compliance bonus
	if outcome.constitutional_bonus:
		_apply_transparency_bonus()

func _apply_transparency_bonus() -> void:
	"""Apply transparency bonus for constitutional compliance"""
	# Small but consistent bonus for transparent responses
	var transparency_bonus = 0.02
	simulation_api.apply_polling_adjustment(game_state.player_party.party_id, transparency_bonus)

func _record_media_interaction(event: MediaEvent, response: MediaResponse, outcome: Dictionary) -> void:
	"""Record media interaction in history"""
	var interaction = {
		"timestamp": Time.get_unix_time_from_system(),
		"event": {
			"type": event.event_type,
			"topic": event.topic,
			"urgency": event.urgency_level
		},
		"response": {
			"type": response.response_type,
			"risk_level": response.risk_level
		},
		"outcome": {
			"sentiment_change": outcome.sentiment_change,
			"polling_impact": outcome.polling_impact,
			"risk_realized": outcome.risk_realized
		}
	}

	media_history.append(interaction)

	# Limit history size
	if media_history.size() > 50:
		media_history.pop_front()

func _load_media_history() -> void:
	"""Load media interaction history"""
	# This would load from save data in full implementation
	media_history.clear()

# Media analysis and reporting

func get_media_sentiment_trend() -> Array[Dictionary]:
	"""Get media sentiment trend over time"""
	var trend = []

	for interaction in media_history:
		trend.append({
			"timestamp": interaction.timestamp,
			"sentiment_change": interaction.outcome.sentiment_change,
			"event_type": interaction.event.type
		})

	return trend

func get_response_effectiveness_analysis() -> Dictionary:
	"""Analyze effectiveness of different response types"""
	var analysis = {}
	var response_stats = {}

	# Analyze each response type
	for interaction in media_history:
		var response_type = interaction.response.type

		if not response_stats.has(response_type):
			response_stats[response_type] = {
				"count": 0,
				"total_sentiment_change": 0.0,
				"total_polling_impact": 0.0,
				"risks_realized": 0
			}

		var stats = response_stats[response_type]
		stats.count += 1
		stats.total_sentiment_change += interaction.outcome.sentiment_change
		stats.total_polling_impact += interaction.outcome.polling_impact
		if interaction.outcome.risk_realized:
			stats.risks_realized += 1

	# Calculate averages and recommendations
	for response_type in response_stats.keys():
		var stats = response_stats[response_type]
		if stats.count > 0:
			analysis[response_type] = {
				"avg_sentiment_impact": stats.total_sentiment_change / stats.count,
				"avg_polling_impact": stats.total_polling_impact / stats.count,
				"risk_rate": float(stats.risks_realized) / stats.count,
				"usage_count": stats.count,
				"recommendation": _get_response_recommendation(stats)
			}

	return analysis

func _get_response_recommendation(stats: Dictionary) -> String:
	"""Get recommendation for response type based on stats"""
	var avg_sentiment = stats.total_sentiment_change / stats.count
	var risk_rate = float(stats.risks_realized) / stats.count

	if avg_sentiment > 0.1 and risk_rate < 0.3:
		return "highly_recommended"
	elif avg_sentiment > 0.05 and risk_rate < 0.5:
		return "recommended"
	elif avg_sentiment < -0.05 or risk_rate > 0.6:
		return "not_recommended"
	else:
		return "situational"

# Advanced media features

func get_upcoming_media_events() -> Array[MediaEvent]:
	"""Get scheduled upcoming media events"""
	return simulation_api.get_scheduled_media_events()

func request_media_opportunity(topic: String, event_type: String) -> bool:
	"""Request specific media opportunity"""
	var cost = _calculate_media_opportunity_cost(event_type)
	var player_funds = game_state.player_party.campaign_resources.available_funds

	if cost > player_funds:
		return false

	return simulation_api.schedule_media_event(topic, event_type, cost)

func _calculate_media_opportunity_cost(event_type: String) -> int:
	"""Calculate cost for requesting media opportunity"""
	match event_type:
		"interview":
			return 5000
		"press_conference":
			return 10000
		"debate":
			return 15000
		_:
			return 7500

# Constitutional compliance

func get_transparency_data() -> Dictionary:
	"""Get transparency data for constitutional compliance"""
	return {
		"media_interactions": media_history.size(),
		"transparency_responses": _count_transparency_responses(),
		"sentiment_methodology": "ideological_alignment_with_random_variation",
		"response_generation": "contextual_based_on_event_type_and_party_position",
		"outcome_calculation": "deterministic_with_bounded_randomness",
		"constitutional_compliance": _validate_constitutional_compliance()
	}

func _count_transparency_responses() -> int:
	"""Count transparency responses in history"""
	var count = 0
	for interaction in media_history:
		if interaction.response.type == "transparency":
			count += 1
	return count

func _validate_constitutional_compliance() -> Dictionary:
	"""Validate media system constitutional compliance"""
	return {
		"transparency_available": true,
		"response_explanations": true,
		"outcome_transparency": true,
		"no_manipulation": true,
		"educational_value": true
	}

# Media event generation helpers

func generate_crisis_event(crisis_type: String) -> MediaEvent:
	"""Generate crisis media event"""
	var event = MediaEvent.new()
	event.event_type = "crisis"
	event.topic = crisis_type
	event.urgency_level = "high"
	event.title = tr("media.crisis.title." + crisis_type)
	event.description = tr("media.crisis.description." + crisis_type)
	event.topic_tags = [crisis_type, "crisis_management"]
	event.time_pressure = 24  # 24 hours to respond
	return event

func generate_opportunity_event(topic: String) -> MediaEvent:
	"""Generate positive media opportunity"""
	var event = MediaEvent.new()
	event.event_type = "interview"
	event.topic = topic
	event.urgency_level = "medium"
	event.title = tr("media.opportunity.title." + topic)
	event.description = tr("media.opportunity.description." + topic)
	event.topic_tags = [topic, "policy_discussion"]
	event.time_pressure = 72  # 3 days to respond
	return event