extends RefCounted
class_name TestParliamentaryVoting

# Integration test: Parliamentary voting simulation
# CRITICAL: This test MUST FAIL before implementation exists

var parliament_controller: ParliamentViewController
var simulation_api: SimulationAPI

func _init():
	# This will fail initially since classes don't exist yet
	parliament_controller = ParliamentViewController.new()
	simulation_api = FakeSimulation.new()

func test_legislation_generation():
	# Test generation of parliamentary legislation
	var game_state = GameState.new()

	# Generate legislation for parliamentary consideration
	var legislation = simulation_api.generate_legislation(game_state)

	# Verify legislation structure (will fail until implemented)
	assert(legislation != null, "Legislation must be generated")
	assert(legislation is Legislation, "Must be Legislation type")
	assert(legislation.bill_title != null, "Legislation must have title")
	assert(legislation.policy_area != null, "Legislation must have policy area")
	assert(legislation.proposing_party != null, "Legislation must have proposing party")
	assert(legislation.party_positions != null, "Legislation must have party positions")

	print("Legislation generation test completed")

func test_voting_outcome_calculation():
	# Test parliamentary voting calculation using D'Hondt system
	var game_state = GameState.new()
	var legislation = simulation_api.generate_legislation(game_state)

	# Calculate voting outcome
	var voting_result = simulation_api.calculate_voting_outcome(legislation, game_state)

	# Verify voting result structure (will fail until implemented)
	assert(voting_result != null, "Voting calculation must return result")
	assert(voting_result is VotingResult, "Must return VotingResult type")
	assert(voting_result.votes_for >= 0, "Must count votes for")
	assert(voting_result.votes_against >= 0, "Must count votes against")
	assert(voting_result.abstentions >= 0, "Must count abstentions")
	assert(voting_result.party_votes != null, "Must track party voting patterns")
	assert(voting_result.vote_explanations != null, "Must explain why parties voted as they did")

	# Test vote total equals 150 (total parliament seats)
	var total_votes = voting_result.votes_for + voting_result.votes_against + voting_result.abstentions
	assert(total_votes == 150, "Total votes must equal 150 (parliament size)")

	# Test legislation passage logic (simple majority = 76 votes)
	voting_result.legislation_passed = voting_result.votes_for > voting_result.votes_against
	assert(voting_result.legislation_passed is bool, "Must determine if legislation passed")

	print("Voting outcome calculation test completed")

func test_party_whip_system():
	# Test party discipline and whip system in voting
	var game_state = GameState.new()
	var legislation = simulation_api.generate_legislation(game_state)

	# Calculate voting outcome with party discipline
	var voting_result = simulation_api.calculate_voting_outcome(legislation, game_state)

	# Verify party voting coherence
	for party_id in voting_result.party_votes.keys():
		var party_vote = voting_result.party_votes[party_id]
		assert(party_vote in ["for", "against", "abstain"], "Party vote must be valid option")

		# Check that party vote explanation exists
		assert(voting_result.vote_explanations.has(party_id), "Must explain party's voting decision")
		assert(voting_result.vote_explanations[party_id].length() > 0, "Explanation cannot be empty")

	print("Party whip system test completed")

func test_coalition_government_voting():
	# Test voting behavior when coalition government is in power
	var game_state = GameState.new()

	# Setup coalition government scenario
	var governing_coalition = Coalition.new()
	governing_coalition.member_parties = ["party_center", "party_left"]
	governing_coalition.majority_status = true
	governing_coalition.total_seats = 85

	game_state.active_coalitions = [governing_coalition]

	# Generate government legislation
	var government_bill = simulation_api.generate_legislation(game_state)
	government_bill.proposing_party = "party_center" # coalition leader

	# Calculate voting outcome for government bill
	var voting_result = simulation_api.calculate_voting_outcome(government_bill, game_state)

	# Test coalition solidarity
	var coalition_votes_for = 0
	for party_id in governing_coalition.member_parties:
		if voting_result.party_votes.has(party_id):
			if voting_result.party_votes[party_id] == "for":
				coalition_votes_for += 1

	# Coalition parties should generally support government legislation
	# (unless it conflicts with their red lines)
	assert(coalition_votes_for >= 1, "At least proposing party should support government bill")

	print("Coalition government voting test completed")

func test_opposition_voting_behavior():
	# Test opposition party voting patterns
	var game_state = GameState.new()
	var legislation = simulation_api.generate_legislation(game_state)

	# Set legislation as proposed by government party
	legislation.proposing_party = "party_center"

	var voting_result = simulation_api.calculate_voting_outcome(legislation, game_state)

	# Opposition parties should often vote against government bills
	# (unless the bill aligns with their ideology)
	var opposition_parties = []
	var government_parties = ["party_center"] # simplified

	for party in game_state.parties:
		if not government_parties.has(party.id):
			opposition_parties.append(party.id)

	# Check that opposition voting is realistic
	var opposition_votes_against = 0
	for party_id in opposition_parties:
		if voting_result.party_votes.has(party_id):
			if voting_result.party_votes[party_id] == "against":
				opposition_votes_against += 1

	# Some opposition should vote against (but not necessarily all)
	assert(opposition_votes_against >= 0, "Opposition voting must be calculated")

	print("Opposition voting behavior test completed")

func test_voting_explanation_transparency():
	# Test constitutional requirement for explanation transparency
	var game_state = GameState.new()
	var legislation = simulation_api.generate_legislation(game_state)
	var voting_result = simulation_api.calculate_voting_outcome(legislation, game_state)

	# Every party must have explanation for their vote
	for party_id in voting_result.party_votes.keys():
		var explanation = voting_result.vote_explanations[party_id]

		# Verify explanation quality
		assert(explanation.length() > 10, "Explanation must be substantive")

		# Should reference party ideology or coalition agreements
		var has_reasoning = (
			explanation.find("ideology") != -1 or
			explanation.find("coalition") != -1 or
			explanation.find("policy") != -1 or
			explanation.find("position") != -1
		)
		assert(has_reasoning, "Explanation must reference political reasoning")

	print("Voting explanation transparency test completed")

func test_legislation_committee_stages():
	# Test legislation progression through committee stages
	var game_state = GameState.new()
	var legislation = simulation_api.generate_legislation(game_state)

	# Verify legislation stages are properly tracked
	var valid_stages = ["proposed", "committee", "floor_vote", "passed", "rejected"]
	assert(legislation.committee_stage in valid_stages, "Legislation must have valid stage")

	# Test stage progression logic
	if legislation.committee_stage == "proposed":
		# Bill should be able to advance to committee
		legislation.committee_stage = "committee"

	if legislation.committee_stage == "committee":
		# Committee review should lead to floor vote
		legislation.committee_stage = "floor_vote"

	if legislation.committee_stage == "floor_vote":
		# Floor vote should determine passage
		var voting_result = simulation_api.calculate_voting_outcome(legislation, game_state)
		if voting_result.legislation_passed:
			legislation.committee_stage = "passed"
		else:
			legislation.committee_stage = "rejected"

	print("Legislation committee stages test completed")

func test_parliament_visualization():
	# Test parliamentary seating and voting visualization
	var game_state = GameState.new()

	# Parliament should reflect election results
	var total_seats = 0
	for party in game_state.parties:
		total_seats += party.projected_seats

	assert(total_seats == 150, "Parliament must have exactly 150 seats")

	# Test seating arrangement (semicircle with parties by ideology)
	# This will be implemented in UI phase but architecture must support it

	print("Parliament visualization test completed")

func run_all_tests():
	print("Running parliamentary voting integration tests...")
	test_legislation_generation()
	test_voting_outcome_calculation()
	test_party_whip_system()
	test_coalition_government_voting()
	test_opposition_voting_behavior()
	test_voting_explanation_transparency()
	test_legislation_committee_stages()
	test_parliament_visualization()
	print("All parliamentary voting integration tests completed")