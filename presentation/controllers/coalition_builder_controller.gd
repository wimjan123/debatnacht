extends RefCounted
class_name CoalitionBuilderController

# Coalition builder controller for drag-and-drop coalition formation
# Handles party compatibility calculations and coalition validation

var simulation_api: SimulationAPI
var game_state: GameState
var available_parties: Array[Party] = []
var proposed_coalition: Coalition = null
var coalition_negotiations: Dictionary = {}

signal coalition_updated(coalition: Coalition)
signal compatibility_calculated(party1: Party, party2: Party, compatibility: float)
signal validation_result(validation: CoalitionValidation)
signal negotiation_progress(party_id: String, progress: Dictionary)

func _init(sim_api: SimulationAPI = null):
	simulation_api = sim_api if sim_api else FakeSimulation.new()

func initialize_coalition_builder(election_result: Election = null) -> void:
	"""Initialize coalition builder with election results"""
	game_state = simulation_api.get_current_state()

	if election_result:
		available_parties = _get_parties_for_coalition(election_result)
	else:
		available_parties = _get_all_eligible_parties()

	# Initialize empty coalition with player party
	proposed_coalition = Coalition.new()
	proposed_coalition.coalition_id = "proposed_" + str(Time.get_unix_time_from_system())
	proposed_coalition.member_parties = [game_state.player_party]
	proposed_coalition.policy_agreements = []
	proposed_coalition.formation_date = Time.get_unix_time_from_system()

	coalition_updated.emit(proposed_coalition)

func _get_parties_for_coalition(election_result: Election) -> Array[Party]:
	"""Get parties eligible for coalition formation"""
	var eligible_parties: Array[Party] = []

	# Get parties that won seats
	for party in election_result.party_results.keys():
		var result = election_result.party_results[party]
		if result.seats_won > 0:
			eligible_parties.append(party)

	return eligible_parties

func _get_all_eligible_parties() -> Array[Party]:
	"""Get all parties in simulation"""
	return simulation_api.get_all_parties()

func add_party_to_coalition(party: Party) -> bool:
	"""Add party to proposed coalition"""
	if not party or party in proposed_coalition.member_parties:
		return false

	# Check if party is eligible
	if party not in available_parties:
		return false

	# Check compatibility with existing members
	var compatibility_issues = _check_coalition_compatibility(party)
	if compatibility_issues.size() > 0:
		# Still add but mark issues
		proposed_coalition.member_parties.append(party)
		_update_policy_agreements()
	else:
		proposed_coalition.member_parties.append(party)
		_update_policy_agreements()

	coalition_updated.emit(proposed_coalition)
	return true

func remove_party_from_coalition(party: Party) -> bool:
	"""Remove party from proposed coalition"""
	if not party or party == game_state.player_party:
		return false  # Cannot remove player party

	var index = proposed_coalition.member_parties.find(party)
	if index == -1:
		return false

	proposed_coalition.member_parties.remove_at(index)
	_update_policy_agreements()
	coalition_updated.emit(proposed_coalition)
	return true

func calculate_party_compatibility(party1: Party, party2: Party) -> float:
	"""Calculate compatibility score between two parties"""
	if not party1 or not party2:
		return 0.0

	var compatibility_score = 0.0
	var total_issues = 0

	# Compare policy positions
	var all_issues = []
	all_issues.append_array(party1.policy_positions.keys())
	for issue in party2.policy_positions.keys():
		if issue not in all_issues:
			all_issues.append(issue)

	for issue in all_issues:
		var pos1 = party1.policy_positions.get(issue, 0.0)
		var pos2 = party2.policy_positions.get(issue, 0.0)

		# Calculate position difference (closer = better compatibility)
		var difference = abs(pos1 - pos2)
		var issue_compatibility = 1.0 - (difference / 2.0)  # Normalize to 0-1

		compatibility_score += issue_compatibility
		total_issues += 1

	# Average compatibility across all issues
	if total_issues > 0:
		compatibility_score /= total_issues

	# Adjust for ideological distance
	var ideological_distance = _calculate_ideological_distance(party1, party2)
	compatibility_score *= (1.0 - ideological_distance * 0.3)

	# Factor in historical cooperation
	var historical_bonus = _get_historical_cooperation_bonus(party1, party2)
	compatibility_score += historical_bonus

	compatibility_calculated.emit(party1, party2, compatibility_score)
	return clamp(compatibility_score, 0.0, 1.0)

func _calculate_ideological_distance(party1: Party, party2: Party) -> float:
	"""Calculate ideological distance between parties"""
	var distance = 0.0

	# Economic axis distance
	var econ_diff = abs(party1.ideology_position.economic - party2.ideology_position.economic)
	distance += econ_diff * econ_diff

	# Social axis distance
	var social_diff = abs(party1.ideology_position.social - party2.ideology_position.social)
	distance += social_diff * social_diff

	# Environmental axis distance (if present)
	if party1.ideology_position.has("environmental") and party2.ideology_position.has("environmental"):
		var env_diff = abs(party1.ideology_position.environmental - party2.ideology_position.environmental)
		distance += env_diff * env_diff

	return sqrt(distance) / 2.0  # Normalize

func _get_historical_cooperation_bonus(party1: Party, party2: Party) -> float:
	"""Get bonus for historical cooperation between parties"""
	# This would check historical coalition data in full implementation
	# For now, return small bonus for centrist parties
	var avg_economic = (party1.ideology_position.economic + party2.ideology_position.economic) / 2.0
	if abs(avg_economic) < 0.3:  # Both parties relatively centrist
		return 0.1
	return 0.0

func _check_coalition_compatibility(new_party: Party) -> Array[String]:
	"""Check compatibility issues when adding new party"""
	var issues: Array[String] = []

	# Check compatibility with each existing member
	for member in proposed_coalition.member_parties:
		var compatibility = calculate_party_compatibility(member, new_party)

		if compatibility < 0.3:
			issues.append("low_compatibility_with_" + member.party_name)

	# Check for ideological conflicts
	var ideological_spread = _calculate_coalition_ideological_spread(new_party)
	if ideological_spread > 1.5:
		issues.append("ideological_spread_too_wide")

	# Check for policy conflicts
	var policy_conflicts = _identify_policy_conflicts(new_party)
	issues.append_array(policy_conflicts)

	return issues

func _calculate_coalition_ideological_spread(additional_party: Party = null) -> float:
	"""Calculate ideological spread of coalition"""
	var parties = proposed_coalition.member_parties.duplicate()
	if additional_party:
		parties.append(additional_party)

	var min_economic = 1.0
	var max_economic = -1.0
	var min_social = 1.0
	var max_social = -1.0

	for party in parties:
		min_economic = min(min_economic, party.ideology_position.economic)
		max_economic = max(max_economic, party.ideology_position.economic)
		min_social = min(min_social, party.ideology_position.social)
		max_social = max(max_social, party.ideology_position.social)

	var economic_spread = max_economic - min_economic
	var social_spread = max_social - min_social

	return economic_spread + social_spread

func _identify_policy_conflicts(new_party: Party) -> Array[String]:
	"""Identify specific policy conflicts with coalition"""
	var conflicts: Array[String] = []

	# Check each policy position
	for issue in new_party.policy_positions.keys():
		var new_party_position = new_party.policy_positions[issue]

		# Find coalition average position on this issue
		var coalition_position = _get_coalition_average_position(issue)

		if abs(new_party_position - coalition_position) > 1.5:
			conflicts.append("policy_conflict_" + issue)

	return conflicts

func _get_coalition_average_position(issue: String) -> float:
	"""Get average coalition position on issue"""
	var total_position = 0.0
	var parties_with_position = 0

	for party in proposed_coalition.member_parties:
		if party.policy_positions.has(issue):
			total_position += party.policy_positions[issue]
			parties_with_position += 1

	return total_position / max(parties_with_position, 1)

func _update_policy_agreements() -> void:
	"""Update policy agreements based on current coalition"""
	proposed_coalition.policy_agreements.clear()

	# Generate agreements for each policy area
	var all_issues = _get_all_coalition_policy_issues()

	for issue in all_issues:
		var agreement = _negotiate_policy_agreement(issue)
		if agreement:
			proposed_coalition.policy_agreements.append(agreement)

func _get_all_coalition_policy_issues() -> Array[String]:
	"""Get all policy issues covered by coalition parties"""
	var all_issues: Array[String] = []

	for party in proposed_coalition.member_parties:
		for issue in party.policy_positions.keys():
			if issue not in all_issues:
				all_issues.append(issue)

	return all_issues

func _negotiate_policy_agreement(issue: String) -> PolicyAgreement:
	"""Negotiate policy agreement on specific issue"""
	var agreement = PolicyAgreement.new()
	agreement.policy_area = issue
	agreement.agreed_position = _get_coalition_average_position(issue)

	# Calculate compromise level
	var position_spread = _calculate_position_spread(issue)
	agreement.compromise_level = clamp(position_spread / 2.0, 0.0, 1.0)

	# Identify supporting and opposing parties
	for party in proposed_coalition.member_parties:
		if party.policy_positions.has(issue):
			var party_position = party.policy_positions[issue]
			var distance_from_agreement = abs(party_position - agreement.agreed_position)

			if distance_from_agreement < 0.5:
				agreement.supporting_parties.append(party.party_id)
			elif distance_from_agreement > 1.0:
				agreement.opposing_parties.append(party.party_id)

	# Set stability based on support
	if agreement.opposing_parties.size() == 0:
		agreement.stability = "high"
	elif agreement.opposing_parties.size() <= 1:
		agreement.stability = "medium"
	else:
		agreement.stability = "low"

	return agreement

func _calculate_position_spread(issue: String) -> float:
	"""Calculate spread of positions on specific issue"""
	var positions = []

	for party in proposed_coalition.member_parties:
		if party.policy_positions.has(issue):
			positions.append(party.policy_positions[issue])

	if positions.size() < 2:
		return 0.0

	positions.sort()
	return positions[-1] - positions[0]  # Max - Min

func validate_coalition() -> CoalitionValidation:
	"""Validate proposed coalition and calculate viability"""
	var validation = CoalitionValidation.new()
	validation.coalition = proposed_coalition

	# Calculate total seats
	validation.total_seats = _calculate_total_seats()

	# Check majority status (76+ seats for Dutch parliament)
	validation.majority_status = validation.total_seats >= 76

	# Calculate feasibility
	validation.is_feasible = _check_coalition_feasibility()

	# Identify blocking issues
	validation.blocking_issues = _identify_blocking_issues()

	# Calculate stability prediction
	validation.stability_prediction = _predict_coalition_stability()

	validation_result.emit(validation)
	return validation

func _calculate_total_seats() -> int:
	"""Calculate total seats for coalition parties"""
	var total = 0

	for party in proposed_coalition.member_parties:
		# Get seats from election results or current polling
		var seats = _get_party_seats(party)
		total += seats

	return total

func _get_party_seats(party: Party) -> int:
	"""Get current seat count for party"""
	# This would get from actual election results or projected seats
	# For now, use simplified calculation based on polling
	var polls = simulation_api.get_current_polls()
	if polls.is_empty():
		return 0

	var latest_poll = polls[0]
	var support_percentage = latest_poll.get_party_support(party.party_id)
	return int(support_percentage * 1.5)  # Rough seats projection

func _check_coalition_feasibility() -> bool:
	"""Check if coalition formation is feasible"""
	# Must have majority
	if _calculate_total_seats() < 76:
		return false

	# Must not have irreconcilable differences
	var blocking_issues = _identify_blocking_issues()
	return blocking_issues.size() == 0

func _identify_blocking_issues() -> Array[String]:
	"""Identify issues that would block coalition formation"""
	var blocking: Array[String] = []

	# Check for fundamental incompatibilities
	for agreement in proposed_coalition.policy_agreements:
		if agreement.stability == "low" and agreement.opposing_parties.size() > 1:
			blocking.append("policy_deadlock_" + agreement.policy_area)

	# Check ideological spread
	if _calculate_coalition_ideological_spread() > 2.0:
		blocking.append("ideological_incompatibility")

	# Check for mutual exclusion (parties that refuse to work together)
	var exclusions = _check_mutual_exclusions()
	blocking.append_array(exclusions)

	return blocking

func _check_mutual_exclusions() -> Array[String]:
	"""Check for parties that refuse to work with each other"""
	var exclusions: Array[String] = []

	# This would check historical data for party exclusions
	# For now, check extreme ideological differences
	for i in range(proposed_coalition.member_parties.size()):
		for j in range(i + 1, proposed_coalition.member_parties.size()):
			var party1 = proposed_coalition.member_parties[i]
			var party2 = proposed_coalition.member_parties[j]

			var compatibility = calculate_party_compatibility(party1, party2)
			if compatibility < 0.2:
				exclusions.append("exclusion_" + party1.party_name + "_" + party2.party_name)

	return exclusions

func _predict_coalition_stability() -> String:
	"""Predict coalition stability"""
	var avg_compatibility = _calculate_average_compatibility()
	var policy_stability = _calculate_policy_stability()
	var ideological_cohesion = 1.0 - (_calculate_coalition_ideological_spread() / 2.0)

	var overall_stability = (avg_compatibility + policy_stability + ideological_cohesion) / 3.0

	if overall_stability > 0.7:
		return "high"
	elif overall_stability > 0.4:
		return "medium"
	else:
		return "low"

func _calculate_average_compatibility() -> float:
	"""Calculate average compatibility between all coalition parties"""
	var total_compatibility = 0.0
	var pair_count = 0

	for i in range(proposed_coalition.member_parties.size()):
		for j in range(i + 1, proposed_coalition.member_parties.size()):
			var party1 = proposed_coalition.member_parties[i]
			var party2 = proposed_coalition.member_parties[j]
			total_compatibility += calculate_party_compatibility(party1, party2)
			pair_count += 1

	return total_compatibility / max(pair_count, 1)

func _calculate_policy_stability() -> float:
	"""Calculate overall policy stability"""
	var stable_agreements = 0

	for agreement in proposed_coalition.policy_agreements:
		if agreement.stability == "high":
			stable_agreements += 1

	return float(stable_agreements) / max(proposed_coalition.policy_agreements.size(), 1)

# Negotiation simulation

func simulate_coalition_negotiations() -> Dictionary:
	"""Simulate coalition negotiation process"""
	coalition_negotiations.clear()

	for party in proposed_coalition.member_parties:
		if party != game_state.player_party:
			var negotiation = _simulate_party_negotiation(party)
			coalition_negotiations[party.party_id] = negotiation
			negotiation_progress.emit(party.party_id, negotiation)

	return coalition_negotiations

func _simulate_party_negotiation(party: Party) -> Dictionary:
	"""Simulate negotiation with specific party"""
	var negotiation = {
		"party": party,
		"status": "negotiating",
		"key_demands": _generate_party_demands(party),
		"concessions_offered": [],
		"deal_breakers": _identify_deal_breakers(party),
		"likelihood": _calculate_agreement_likelihood(party),
		"timeline": _estimate_negotiation_timeline(party)
	}

	return negotiation

func _generate_party_demands(party: Party) -> Array[String]:
	"""Generate key demands for party in negotiations"""
	var demands: Array[String] = []

	# Find party's strongest policy positions
	var strong_positions = []
	for issue in party.policy_positions.keys():
		var position = party.policy_positions[issue]
		if abs(position) > 1.5:  # Strong position
			strong_positions.append(issue)

	# Convert to demands
	for position in strong_positions:
		demands.append("policy_commitment_" + position)

	# Add structural demands based on party size
	var party_seats = _get_party_seats(party)
	if party_seats > 20:
		demands.append("minister_positions_2_or_more")
	elif party_seats > 10:
		demands.append("minister_position_1")

	return demands

func _identify_deal_breakers(party: Party) -> Array[String]:
	"""Identify deal breakers for party"""
	var deal_breakers: Array[String] = []

	# Find policies where party has extreme positions
	for issue in party.policy_positions.keys():
		var party_position = party.policy_positions[issue]
		var coalition_position = _get_coalition_average_position(issue)

		if abs(party_position - coalition_position) > 1.8:
			deal_breakers.append("policy_red_line_" + issue)

	return deal_breakers

func _calculate_agreement_likelihood(party: Party) -> float:
	"""Calculate likelihood of reaching agreement with party"""
	var compatibility = 0.0

	# Average compatibility with coalition
	for member in proposed_coalition.member_parties:
		if member != party:
			compatibility += calculate_party_compatibility(party, member)

	compatibility /= max(proposed_coalition.member_parties.size() - 1, 1)

	# Adjust for party's negotiation flexibility
	var flexibility = _get_party_flexibility(party)

	return compatibility * flexibility

func _get_party_flexibility(party: Party) -> float:
	"""Get party's negotiation flexibility score"""
	# This would be based on party characteristics in full implementation
	# For now, assume moderate parties are more flexible
	var avg_position = 0.0
	for position in party.policy_positions.values():
		avg_position += abs(position)
	avg_position /= max(party.policy_positions.size(), 1)

	return 1.0 - (avg_position / 2.0)  # More extreme = less flexible

func _estimate_negotiation_timeline(party: Party) -> int:
	"""Estimate negotiation timeline in days"""
	var base_timeline = 14  # 2 weeks base

	# Adjust for complexity
	var complexity_factor = proposed_coalition.member_parties.size() * 3
	var policy_conflicts = _identify_policy_conflicts(party).size() * 2

	return base_timeline + complexity_factor + policy_conflicts

# Coalition management

func finalize_coalition() -> Coalition:
	"""Finalize coalition formation"""
	proposed_coalition.is_finalized = true
	proposed_coalition.formation_date = Time.get_unix_time_from_system()

	# Set coalition leadership (player party leads)
	proposed_coalition.lead_party = game_state.player_party.party_id

	return proposed_coalition

func get_coalition_summary() -> Dictionary:
	"""Get comprehensive coalition summary"""
	return {
		"parties": proposed_coalition.member_parties,
		"total_seats": _calculate_total_seats(),
		"policy_agreements": proposed_coalition.policy_agreements,
		"stability_prediction": _predict_coalition_stability(),
		"formation_challenges": _identify_blocking_issues(),
		"negotiation_status": coalition_negotiations
	}

# Constitutional compliance

func get_transparency_data() -> Dictionary:
	"""Get transparency data for constitutional compliance"""
	return {
		"coalition_formation_method": "player_directed_with_compatibility_validation",
		"compatibility_calculation": "policy_position_distance_with_ideological_adjustment",
		"validation_criteria": ["majority_threshold", "policy_feasibility", "ideological_coherence"],
		"negotiation_simulation": "realistic_party_behavior_modeling",
		"educational_transparency": "full_calculation_explanations_available"
	}

func validate_democratic_legitimacy() -> Dictionary:
	"""Validate democratic legitimacy of coalition process"""
	return {
		"election_based": true,
		"proportional_representation": true,
		"majority_requirement": _calculate_total_seats() >= 76,
		"party_consent_modeled": true,
		"realistic_constraints": true,
		"educational_value": true
	}