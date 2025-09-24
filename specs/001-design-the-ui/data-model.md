# Data Model: Dutch Politics Simulation UI

## Core Entities

### GameState
**Purpose**: Top-level game session state and metadata
**Attributes**:
- `current_date`: String (ISO date format)
- `game_phase`: Enum (campaign, election, coalition, parliament)
- `active_scenario`: String (scenario identifier)
- `player_party_id`: String (references Party.id)
- `rng_seed`: Integer (for deterministic simulation)
- `save_version`: String (for backward compatibility)
- `total_play_time`: Integer (seconds)

**State Transitions**:
- campaign → election (when campaign period ends)
- election → coalition (when voting completes)
- coalition → parliament (when government formed)
- parliament → campaign (when term ends)

### Party
**Purpose**: Political party with ideology, resources, and electoral position
**Attributes**:
- `id`: String (unique identifier)
- `display_name`: String (localized name)
- `ideology_position`: Vector2 (economic_axis, social_axis)
- `current_polls`: Float (percentage 0-100)
- `projected_seats`: Integer (0-150)
- `campaign_funds`: Integer (euros)
- `red_lines`: Array[String] (non-negotiable policies)
- `ministry_preferences`: Array[String] (desired cabinet positions)
- `compatibility_scores`: Dictionary[String, Float] (party_id → score)

**Validation**:
- ideology_position coordinates between -1.0 and 1.0
- current_polls sum across all parties ≤ 100.0
- projected_seats sum across all parties = 150

### CampaignAction
**Purpose**: Time-limited activities that affect party metrics
**Attributes**:
- `action_type`: Enum (rally, advertisement, interview, social_media, debate)
- `cost`: Integer (campaign funds required)
- `duration_hours`: Integer (how long action takes)
- `target_region`: String (optional, for regional effects)
- `expected_effects`: Dictionary[String, Float] (metric → change)
- `actual_results`: Dictionary[String, Float] (recorded after completion)
- `timestamp`: String (when action was taken)

### OpinionPoll
**Purpose**: Regular measurement of voter sentiment with demographic breakdown
**Attributes**:
- `poll_date`: String (ISO date)
- `party_standings`: Dictionary[String, Float] (party_id → percentage)
- `margin_of_error`: Float (polling uncertainty)
- `sample_size`: Integer (survey respondents)
- `demographic_breakdown`: Dictionary[String, Dictionary] (age/region → party preferences)
- `issue_salience`: Dictionary[String, Float] (policy topic → importance)
- `volatility_index`: Float (likelihood of vote switching)

### GeographicRegion
**Purpose**: Dutch provinces/municipalities with unique voter characteristics
**Attributes**:
- `region_id`: String (CBS statistical code)
- `display_name`: String (localized region name)
- `region_type`: Enum (province, municipality, constituency)
- `population`: Integer (eligible voters)
- `turnout_rate`: Float (historical voting participation)
- `party_support`: Dictionary[String, Float] (party_id → support percentage)
- `key_issues`: Array[String] (top local political concerns)
- `demographic_profile`: Dictionary[String, Float] (age/income/education breakdowns)

### MediaEvent
**Purpose**: Interactive interviews, debates, and media appearances
**Attributes**:
- `event_type`: Enum (tv_interview, radio_interview, debate, press_conference)
- `event_title`: String (localized event name)
- `audience_reach`: Integer (estimated viewers/listeners)
- `questions`: Array[MediaQuestion] (interview content)
- `participant_parties`: Array[String] (party IDs involved)
- `sentiment_tracking`: Dictionary[String, Float] (real-time audience response)
- `outcome_effects`: Dictionary[String, Float] (post-event poll changes)

### MediaQuestion
**Purpose**: Individual questions within media events with response options
**Attributes**:
- `question_text`: String (localized question)
- `response_options`: Array[ResponseOption] (available answers)
- `topic_category`: String (policy area this question addresses)
- `difficulty_level`: Integer (1-5, affects potential impact)
- `time_limit`: Integer (seconds for player response)

### ResponseOption
**Purpose**: Player response choices in media events
**Attributes**:
- `option_text`: String (localized response text)
- `tone`: Enum (aggressive, diplomatic, populist, technocratic)
- `stance_position`: Vector2 (where this response places party on ideology map)
- `audience_appeal`: Dictionary[String, Float] (demographic → appeal rating)
- `risk_level`: Float (chance of negative consequences)

### Coalition
**Purpose**: Multi-party governing arrangement with shared agreements
**Attributes**:
- `member_parties`: Array[String] (party IDs in coalition)
- `total_seats`: Integer (combined seat count)
- `majority_status`: Boolean (≥76 seats)
- `policy_agreements`: Array[PolicyAgreement] (shared positions)
- `ministry_allocations`: Dictionary[String, String] (ministry → party_id)
- `stability_score`: Float (likelihood of government survival)
- `formation_date`: String (when coalition was formed)

### PolicyAgreement
**Purpose**: Specific policy positions agreed upon by coalition partners
**Attributes**:
- `policy_topic`: String (subject area)
- `agreed_position`: String (compromise stance)
- `supporting_parties`: Array[String] (parties that agreed)
- `implementation_priority`: Integer (1-10 urgency ranking)
- `public_support`: Float (polling on this specific policy)

### Legislation
**Purpose**: Parliamentary bills with voting records and effects
**Attributes**:
- `bill_title`: String (localized legislation name)
- `policy_area`: String (subject category)
- `proposing_party`: String (party that introduced bill)
- `committee_stage`: Enum (proposed, committee, floor_vote, passed, rejected)
- `party_positions`: Dictionary[String, Enum] (party_id → for/against/abstain)
- `vote_tally`: Dictionary[String, Integer] (for/against/abstain → count)
- `predicted_effects`: Dictionary[String, Float] (policy area → impact)
- `public_opinion`: Float (polling support for legislation)

### Election
**Purpose**: Culminating electoral event with D'Hondt seat calculation
**Attributes**:
- `election_date`: String (voting day)
- `final_results`: Dictionary[String, Float] (party_id → vote percentage)
- `seat_distribution`: Dictionary[String, Integer] (party_id → seats won)
- `turnout_rate`: Float (actual voter participation)
- `regional_breakdown`: Dictionary[String, Dictionary] (region_id → party results)
- `calculation_method`: String (D'Hondt for proportional representation)
- `coalition_possibilities`: Array[Array[String]] (viable government combinations)

### UIState
**Purpose**: Interface-specific state and display preferences
**Attributes**:
- `active_screen`: Enum (menu, dashboard, map, media, coalition, parliament, social, results, settings)
- `language_setting`: Enum (english, dutch)
- `accessibility_mode`: Enum (default, high_contrast, large_text)
- `tooltip_preferences`: Dictionary[String, Boolean] (which tooltips to show)
- `map_filter_state`: Dictionary[String, Any] (current map view settings)
- `notification_queue`: Array[NotificationMessage] (pending UI notifications)

### NotificationMessage
**Purpose**: Non-blocking UI notifications for player feedback
**Attributes**:
- `message_text`: String (localized notification content)
- `message_type`: Enum (info, warning, success, error)
- `display_duration`: Float (seconds to show notification)
- `action_required`: Boolean (whether user must acknowledge)
- `related_screen`: String (which screen this notification relates to)

## Entity Relationships

### Primary Relationships
- GameState → Party (one-to-many: game contains multiple parties)
- Party → CampaignAction (one-to-many: party performs multiple actions)
- OpinionPoll → Party (many-to-many: polls track all parties over time)
- GeographicRegion → Party (many-to-many: regions have support for multiple parties)
- Coalition → Party (many-to-many: coalitions contain multiple parties)
- Legislation → Party (many-to-many: parties have positions on multiple bills)

### Secondary Relationships
- MediaEvent → MediaQuestion (one-to-many: events contain multiple questions)
- MediaQuestion → ResponseOption (one-to-many: questions have multiple response choices)
- Coalition → PolicyAgreement (one-to-many: coalitions have multiple agreed positions)
- Election → GeographicRegion (one-to-many: elections have results per region)

## Data Volume Estimates

**Small Scale** (MVP):
- Parties: 8-12 (major Dutch political spectrum representation)
- Regions: 12 provinces + 20 key municipalities
- Media Events: 15-20 per campaign cycle
- Legislation: 30-50 bills per parliamentary term

**Full Scale** (complete simulation):
- Parties: 15-20 (including smaller parties)
- Regions: 12 provinces + 355 municipalities + 150 constituencies
- Media Events: 50-75 per campaign cycle
- Legislation: 100-200 bills per parliamentary term

## Validation Rules

### Constitutional Compliance
- All numerical calculations must be deterministic with seeded RNG
- All text content must have Dutch and English translations
- All UI elements must have accessibility labels and keyboard navigation
- All configuration must be in human-readable JSON format

### Data Integrity
- Party poll percentages across all parties sum to ≤100.0
- Projected seats across all parties sum to exactly 150
- Coalition seat totals must match sum of member party seats
- Geographic region population totals must be realistic (16.8M for Netherlands)
- Campaign funds must be non-negative integers
- All probability values must be between 0.0 and 1.0