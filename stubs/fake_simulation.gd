extends SimulationAPI
class_name FakeSimulation

# Fake simulation implementation with seeded random data generation
# This stub provides realistic data for UI development and testing

var rng: RandomNumberGenerator

func _init():
	rng = RandomNumberGenerator.new()
	rng.seed = 12345  # Default test seed

## Game State Management ##

func initialize_game(scenario_id: String, rng_seed: int) -> GameState:
	rng.seed = rng_seed

	var game_state = GameState.new()
	game_state.active_scenario = scenario_id
	game_state.rng_seed = rng_seed
	game_state.player_party_id = "player_party"

	# Create sample parties
	var parties = _create_sample_parties()
	game_state.parties = parties

	# Set initial polls
	game_state.current_polls = _generate_initial_polls(parties)

	# Create regions
	game_state.regions = _create_sample_regions()

	return game_state

func load_game(save_data: Dictionary) -> GameState:
	var game_state = GameState.new()
	game_state.current_date = save_data.get("current_date", Time.get_date_string_from_system())
	game_state.rng_seed = save_data.get("rng_seed", 12345)
	rng.seed = game_state.rng_seed

	# Load basic state from save data
	game_state.player_party_id = save_data.get("player_party_id", "player_party")
	game_state.active_scenario = save_data.get("scenario", "default")
	game_state.total_play_time = save_data.get("play_time", 0)

	# Recreate game objects (in real implementation would restore from save)
	game_state.parties = _create_sample_parties()
	game_state.current_polls = _generate_initial_polls(game_state.parties)
	game_state.regions = _create_sample_regions()

	return game_state

func save_game(current_state: GameState) -> Dictionary:
	return {
		"version": current_state.save_version,
		"current_date": current_state.current_date,
		"rng_seed": current_state.rng_seed,
		"player_party_id": current_state.player_party_id,
		"scenario": current_state.active_scenario,
		"play_time": current_state.total_play_time,
		"created": Time.get_date_string_from_system()
	}

## Campaign Management ##

func execute_campaign_action(action: CampaignAction, current_state: GameState) -> ActionResult:
	var result = ActionResult.new()
	result.success = true
	result.cost_paid = action.cost

	# Simulate action effects
	var poll_change = rng.randf_range(-2.0, 3.0)  # Rally can boost or backfire
	var fund_change = -action.cost

	result.effects = {
		"polls": poll_change,
		"funds": fund_change
	}

	if action.action_type == "rally":
		result.explanation = "Rally in %s generated %+.1f%% poll change" % [action.target_region, poll_change]
	elif action.action_type == "advertisement":
		result.explanation = "TV advertisement campaign reached voters, %+.1f%% poll change" % [poll_change]
	else:
		result.explanation = "Campaign action completed with %+.1f%% poll change" % [poll_change]

	# Create updated state (simplified)
	result.new_state = current_state

	return result

func get_available_actions(party_id: String, current_state: GameState) -> Array[CampaignAction]:
	var actions: Array[CampaignAction] = []

	# Rally action
	var rally = CampaignAction.new("rally", 5000, 4, "Rally in key region to boost local support")
	rally.expected_effects = {"polls": 1.5, "regional_support": 3.0}
	actions.append(rally)

	# TV Advertisement
	var tv_ad = CampaignAction.new("advertisement", 15000, 2, "Television advertisement campaign")
	tv_ad.expected_effects = {"polls": 2.0, "name_recognition": 5.0}
	actions.append(tv_ad)

	# Media Interview
	var interview = CampaignAction.new("interview", 0, 3, "Media interview opportunity")
	interview.expected_effects = {"polls": 1.0, "media_sentiment": 2.0}
	actions.append(interview)

	return actions

func calculate_current_polls(current_state: GameState) -> OpinionPoll:
	var poll = OpinionPoll.new()
	poll.poll_date = Time.get_date_string_from_system()
	poll.sample_size = 1200
	poll.margin_of_error = 2.8

	# Generate realistic party standings that sum to ~100%
	var total_percentage = 0.0
	for party in current_state.parties:
		var base_support = rng.randf_range(3.0, 25.0)
		poll.party_standings[party.id] = base_support
		total_percentage += base_support

	# Normalize to sum to 100%
	for party_id in poll.party_standings.keys():
		poll.party_standings[party_id] = (poll.party_standings[party_id] / total_percentage) * 100.0

	poll.volatility_index = rng.randf_range(0.3, 0.8)

	return poll

## Geographic Data ##

func get_regional_data(filter_type: String, filter_value: String, current_state: GameState) -> Dictionary:
	var regional_data = {}

	for region in current_state.regions:
		match filter_type:
			"party_support":
				regional_data[region.region_id] = rng.randf_range(0.1, 0.4)
			"issue_salience":
				regional_data[region.region_id] = rng.randf_range(0.2, 0.8)
			"turnout":
				regional_data[region.region_id] = rng.randf_range(0.65, 0.85)
			"demographics":
				regional_data[region.region_id] = rng.randf_range(0.15, 0.35)

	return regional_data

func get_region_tooltip_data(region_id: String, current_state: GameState) -> RegionTooltipData:
	var tooltip = RegionTooltipData.new()
	tooltip.region_name = region_id.capitalize()
	tooltip.turnout_prediction = rng.randf_range(0.70, 0.85)

	# Generate party support for this region
	for party in current_state.parties:
		tooltip.party_support[party.id] = rng.randf_range(0.05, 0.35)

	# Key issues for this region
	var issues = ["Healthcare", "Education", "Environment", "Economy", "Immigration", "Housing"]
	for i in range(3):
		tooltip.key_issues.append(issues[rng.randi() % issues.size()])

	# Demographic breakdown
	tooltip.demographic_info = {
		"age_18_34": rng.randf_range(0.20, 0.35),
		"age_35_54": rng.randf_range(0.30, 0.40),
		"age_55plus": rng.randf_range(0.25, 0.35),
		"high_education": rng.randf_range(0.25, 0.45),
		"urban": rng.randf_range(0.40, 0.80)
	}

	return tooltip

## Media Events ##

func generate_media_event(event_type: String, current_state: GameState) -> MediaEvent:
	var event = MediaEvent.new()
	event.event_type = event_type
	event.base_sentiment = rng.randf_range(-0.2, 0.2)

	match event_type:
		"tv_interview":
			event.event_title = "Prime Time TV Interview"
			event.audience_reach = rng.randi_range(800000, 1500000)
		"radio_interview":
			event.event_title = "Morning Radio Interview"
			event.audience_reach = rng.randi_range(200000, 500000)
		"debate":
			event.event_title = "Party Leaders Debate"
			event.audience_reach = rng.randi_range(1200000, 2500000)
			event.participant_parties = ["player_party", "opposition_1", "opposition_2"]

	# Generate questions
	var questions = _generate_media_questions(event_type)
	event.questions = questions

	return event

func process_media_response(response: ResponseOption, question: MediaQuestion, current_state: GameState) -> MediaResponse:
	var media_response = MediaResponse.new()

	# Calculate sentiment based on response tone and risk
	var base_sentiment = rng.randf_range(-0.3, 0.4)
	var risk_penalty = response.risk_level * rng.randf_range(0.0, 0.5)

	media_response.sentiment_change = base_sentiment - risk_penalty
	media_response.reach_multiplier = rng.randf_range(0.8, 1.3)

	# Calculate poll effects
	var poll_effect = media_response.sentiment_change * rng.randf_range(0.5, 2.0)
	media_response.poll_effects[current_state.player_party_id] = poll_effect

	# Generate explanation
	if media_response.sentiment_change > 0.1:
		media_response.explanation = "Your %s response resonated well with the audience" % response.tone
	elif media_response.sentiment_change < -0.1:
		media_response.explanation = "Your %s response created some negative reactions" % response.tone
	else:
		media_response.explanation = "Your response had a neutral reception from the audience"

	return media_response

## Coalition Building ##

func calculate_coalition_compatibility(party_a_id: String, party_b_id: String, current_state: GameState) -> CoalitionCompatibility:
	var compatibility = CoalitionCompatibility.new()

	# Find parties
	var party_a: Party = null
	var party_b: Party = null
	for party in current_state.parties:
		if party.id == party_a_id:
			party_a = party
		elif party.id == party_b_id:
			party_b = party

	if party_a == null or party_b == null:
		compatibility.compatibility_score = 0.0
		compatibility.explanation = "One or both parties not found"
		return compatibility

	# Calculate ideological distance
	var ideological_distance = party_a.ideology_position.distance_to(party_b.ideology_position)
	compatibility.compatibility_score = max(0.0, 1.0 - (ideological_distance / 2.83))  # max distance is sqrt(8) ≈ 2.83

	# Generate policy areas
	var all_policies = ["Healthcare", "Education", "Environment", "Economy", "Immigration", "Defense"]
	var conflicts = []
	var agreements = []

	for policy in all_policies:
		if rng.randf() < (1.0 - compatibility.compatibility_score):
			conflicts.append(policy)
		else:
			agreements.append(policy)

	compatibility.policy_conflicts = conflicts
	compatibility.shared_positions = agreements

	if compatibility.compatibility_score > 0.7:
		compatibility.explanation = "High compatibility - shared ideological positions"
	elif compatibility.compatibility_score > 0.4:
		compatibility.explanation = "Moderate compatibility - some shared ground"
	else:
		compatibility.explanation = "Low compatibility - significant ideological differences"

	return compatibility

func validate_coalition(party_ids: Array[String], current_state: GameState) -> CoalitionValidation:
	var validation = CoalitionValidation.new()

	var total_seats = 0
	var coalition_parties = []

	# Find parties and calculate seats
	for party_id in party_ids:
		for party in current_state.parties:
			if party.id == party_id:
				coalition_parties.append(party)
				total_seats += party.projected_seats
				break

	validation.total_seats = total_seats
	validation.majority_status = total_seats >= 76

	# Calculate stability based on compatibility
	var avg_compatibility = 0.0
	var compatibility_count = 0

	for i in range(coalition_parties.size()):
		for j in range(i + 1, coalition_parties.size()):
			var compat = calculate_coalition_compatibility(coalition_parties[i].id, coalition_parties[j].id, current_state)
			avg_compatibility += compat.compatibility_score
			compatibility_count += 1

			# Check for blocking issues
			if compat.compatibility_score < 0.3:
				validation.blocking_issues.append("Fundamental disagreement on " + compat.policy_conflicts[0] if compat.policy_conflicts.size() > 0 else "ideology")

	if compatibility_count > 0:
		validation.stability_score = avg_compatibility / compatibility_count

	validation.is_feasible = validation.majority_status and validation.blocking_issues.size() == 0

	return validation

## Parliamentary Voting ##

func generate_legislation(current_state: GameState) -> Legislation:
	var legislation = Legislation.new()

	var bill_topics = [
		"Climate Action Bill",
		"Healthcare Reform Act",
		"Education Funding Bill",
		"Immigration Policy Reform",
		"Tax Reform Legislation"
	]

	legislation.bill_title = bill_topics[rng.randi() % bill_topics.size()]
	legislation.policy_area = legislation.bill_title.split(" ")[0].to_lower()
	legislation.proposing_party = current_state.parties[rng.randi() % current_state.parties.size()].id
	legislation.public_opinion = rng.randf_range(0.3, 0.7)

	# Set party positions
	for party in current_state.parties:
		var positions = ["for", "against", "abstain"]
		legislation.party_positions[party.id] = positions[rng.randi() % positions.size()]

	return legislation

func calculate_voting_outcome(legislation: Legislation, current_state: GameState) -> VotingResult:
	var result = VotingResult.new()

	# Calculate votes based on party positions and seat counts
	for party in current_state.parties:
		var position = legislation.party_positions.get(party.id, "abstain")
		var seats = party.projected_seats

		match position:
			"for":
				result.votes_for += seats
			"against":
				result.votes_against += seats
			"abstain":
				result.abstentions += seats

		result.party_votes[party.id] = position

		# Generate explanations
		match position:
			"for":
				result.vote_explanations[party.id] = "Party supports this legislation based on their platform"
			"against":
				result.vote_explanations[party.id] = "Party opposes this legislation due to ideological differences"
			"abstain":
				result.vote_explanations[party.id] = "Party abstains pending further committee review"

	result.legislation_passed = result.votes_for > result.votes_against

	return result

## Election Simulation ##

func simulate_election(current_state: GameState) -> Election:
	var election = Election.new()
	election.election_date = Time.get_date_string_from_system()
	election.calculation_method = "D'Hondt"
	election.turnout_rate = rng.randf_range(0.70, 0.85)

	# Use current polls as basis for election results with some variance
	var polls = calculate_current_polls(current_state)

	for party_id in polls.party_standings.keys():
		var poll_percentage = polls.party_standings[party_id]
		var variance = rng.randf_range(-3.0, 3.0)  # Election day variance
		var final_percentage = max(0.0, poll_percentage + variance)

		election.final_results[party_id] = final_percentage

		# Calculate seats using simplified D'Hondt
		var seats = int((final_percentage / 100.0) * 150)
		election.seat_distribution[party_id] = seats

	# Generate coalition possibilities
	var viable_coalitions = []
	# Simplified: find combinations that exceed 76 seats
	# Real implementation would be more sophisticated

	return election

func analyze_election_outcome(election: Election, campaign_history: Array[CampaignAction]) -> ElectionAnalysis:
	var analysis = ElectionAnalysis.new()

	# Analyze seat changes (simplified - would compare to previous election)
	for party_id in election.seat_distribution.keys():
		var seats = election.seat_distribution[party_id]
		analysis.seat_changes[party_id] = rng.randi_range(-5, 8)  # Simulated change

	# Key factors
	analysis.key_factors = [
		"Economic concerns dominated voter decisions",
		"Climate change was a significant issue",
		"Coalition negotiations influenced late deciders",
		"Regional variations in turnout affected results"
	]

	# Campaign effectiveness
	for action in campaign_history:
		if not analysis.campaign_effectiveness.has(action.action_type):
			analysis.campaign_effectiveness[action.action_type] = rng.randf_range(0.3, 0.8)

	return analysis

## Explanation System ##

func explain_metric(metric_type: String, metric_value: Variant, context: Dictionary) -> TooltipData:
	var tooltip = TooltipData.new()

	match metric_type:
		"poll_percentage":
			tooltip.title = "Poll Percentage"
			tooltip.current_value = "%.1f%%" % metric_value
			tooltip.explanation = "Your party's current polling percentage based on recent surveys and campaign activities"
			tooltip.contributing_factors = ["Recent rally effects", "Media coverage", "National trends", "Local issues"]
			tooltip.trend_direction = "stable"

		"projected_seats":
			tooltip.title = "Projected Seats"
			tooltip.current_value = "%d seats" % metric_value
			tooltip.explanation = "Projected seat count in parliament based on current polling using the D'Hondt method"
			tooltip.contributing_factors = ["Current polls", "Electoral system", "Regional variations"]
			tooltip.trend_direction = "increasing"

		"campaign_funds":
			tooltip.title = "Campaign Funds"
			tooltip.current_value = "€%s" % String.num(metric_value, 0)
			tooltip.explanation = "Available campaign funds for activities like rallies, advertisements, and media appearances"
			tooltip.contributing_factors = ["Initial funding", "Donation income", "Campaign spending"]
			tooltip.trend_direction = "decreasing"

		_:
			tooltip.title = "Unknown Metric"
			tooltip.current_value = str(metric_value)
			tooltip.explanation = "Information about this metric is not available"
			tooltip.contributing_factors = []
			tooltip.trend_direction = "unknown"

	return tooltip

func get_detailed_explanation(calculation_type: String, inputs: Dictionary, result: Variant) -> ExplanationPanel:
	var panel = ExplanationPanel.new()
	panel.calculation_name = calculation_type
	panel.confidence_level = "medium"

	match calculation_type:
		"seat_projection":
			panel.step_by_step = [
				"1. Current poll percentage: %.1f%%" % inputs.get("poll_percentage", 0),
				"2. Apply D'Hondt divisor method",
				"3. Account for regional variations",
				"4. Final projected seats: %d" % result
			]
			panel.assumptions = [
				"Current polling trends continue",
				"Voter turnout similar to previous elections",
				"No major campaign events before election"
			]

		"coalition_stability":
			panel.step_by_step = [
				"1. Calculate ideological compatibility: %.2f" % inputs.get("compatibility", 0),
				"2. Assess policy agreement overlap: %d areas" % inputs.get("agreements", 0),
				"3. Factor in historical coalition patterns",
				"4. Final stability score: %.2f" % result
			]
			panel.assumptions = [
				"Party leaders maintain current positions",
				"No external political crises",
				"Normal parliamentary procedures"
			]

		_:
			panel.step_by_step = ["Calculation details not available for " + calculation_type]
			panel.assumptions = ["Standard political modeling assumptions"]

	panel.input_values = inputs

	return panel

## Helper Methods ##

func _create_sample_parties() -> Array[Party]:
	var parties: Array[Party] = []

	# Create diverse political spectrum
	var party_data = [
		{"id": "player_party", "name": "Your Party", "ideology": Vector2(0.0, 0.0), "seats": 25},
		{"id": "center_party", "name": "Center Party", "ideology": Vector2(0.1, 0.0), "seats": 35},
		{"id": "left_party", "name": "Social Democrats", "ideology": Vector2(-0.6, 0.3), "seats": 28},
		{"id": "right_party", "name": "Conservative Party", "ideology": Vector2(0.7, -0.2), "seats": 22},
		{"id": "green_party", "name": "Green Party", "ideology": Vector2(-0.3, 0.8), "seats": 15},
		{"id": "liberal_party", "name": "Liberal Democrats", "ideology": Vector2(0.4, 0.6), "seats": 18},
		{"id": "populist_party", "name": "People's Party", "ideology": Vector2(0.2, -0.7), "seats": 7}
	]

	for data in party_data:
		var party = Party.new(data.id, data.name, data.ideology)
		party.projected_seats = data.seats
		party.current_polls = (data.seats / 150.0) * 100.0  # Convert seats to rough percentage
		party.campaign_funds = rng.randi_range(75000, 200000)
		parties.append(party)

	return parties

func _generate_initial_polls(parties: Array[Party]) -> OpinionPoll:
	var poll = OpinionPoll.new()

	for party in parties:
		poll.party_standings[party.id] = party.current_polls

	poll.margin_of_error = 2.5
	poll.sample_size = 1200
	poll.volatility_index = 0.45

	return poll

func _create_sample_regions() -> Array[GeographicRegion]:
	var regions: Array[GeographicRegion] = []

	# Dutch provinces
	var province_names = [
		"Noord-Holland", "Zuid-Holland", "Utrecht", "Noord-Brabant",
		"Gelderland", "Overijssel", "Limburg", "Groningen",
		"Friesland", "Drenthe", "Flevoland", "Zeeland"
	]

	for province_name in province_names:
		var region = GeographicRegion.new(province_name.to_lower().replace("-", "_"), province_name, "province")
		region.population = rng.randi_range(200000, 3800000)  # Realistic Dutch province populations
		region.turnout_rate = rng.randf_range(0.72, 0.87)

		# Add key issues for each region
		var possible_issues = ["Healthcare", "Education", "Environment", "Economy", "Housing", "Infrastructure"]
		for i in range(3):
			region.key_issues.append(possible_issues[rng.randi() % possible_issues.size()])

		regions.append(region)

	return regions

func _generate_media_questions(event_type: String) -> Array[MediaQuestion]:
	var questions: Array[MediaQuestion] = []

	var question_pools = {
		"tv_interview": [
			"What is your party's position on healthcare reform?",
			"How will your party address the housing crisis?",
			"What are your plans for climate change action?"
		],
		"radio_interview": [
			"How does your party plan to strengthen the economy?",
			"What is your stance on immigration policy?",
			"How will you address educational inequality?"
		],
		"debate": [
			"Why should voters choose your party over the alternatives?",
			"How will your party work with others in coalition?",
			"What is your response to recent polling numbers?"
		]
	}

	var pool = question_pools.get(event_type, question_pools.tv_interview)

	for i in range(min(3, pool.size())):  # Generate 3 questions max
		var question = MediaQuestion.new()
		question.question_text = pool[i]
		question.topic_category = ["healthcare", "housing", "environment", "economy", "immigration"][i % 5]
		question.difficulty_level = rng.randi_range(2, 4)
		question.time_limit = 45

		# Generate response options
		question.response_options = _generate_response_options(question.topic_category)

		questions.append(question)

	return questions

func _generate_response_options(topic: String) -> Array[ResponseOption]:
	var options: Array[ResponseOption] = []

	var response_templates = [
		{"tone": "diplomatic", "text": "We believe in a balanced approach to %s that considers all stakeholders", "risk": 0.2},
		{"tone": "aggressive", "text": "It's time for decisive action on %s - no more half-measures", "risk": 0.6},
		{"tone": "populist", "text": "The people deserve better on %s - we'll deliver real change", "risk": 0.4},
		{"tone": "technocratic", "text": "Our evidence-based policy on %s will deliver measurable results", "risk": 0.3}
	]

	for template in response_templates:
		var option = ResponseOption.new()
		option.option_text = template.text % topic
		option.tone = template.tone
		option.risk_level = template.risk
		option.stance_position = Vector2(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5))

		# Generate audience appeal
		option.audience_appeal = {
			"young_voters": rng.randf_range(0.3, 0.8),
			"older_voters": rng.randf_range(0.2, 0.7),
			"urban": rng.randf_range(0.4, 0.9),
			"rural": rng.randf_range(0.3, 0.8),
			"high_education": rng.randf_range(0.3, 0.8)
		}

		options.append(option)

	return options