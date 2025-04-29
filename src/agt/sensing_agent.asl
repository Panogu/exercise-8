// sensing agent

/* Initial beliefs and rules */

/* Reasoning rules */
// Rule: Link roles to their ultimate goals via missions
role_goal(R, G) :-
   role_mission(R, _, M) & mission_goal(M, G).

can_achieve(G) :-
   .relevant_plans({+!G[scheme(_)]}, LP) & LP \== [].

// Rule: Determine if the agent is suitable for a role (can achieve ALL its goals)
having_plan_for_role(R) :-
   not (role_goal(R, G) & not can_achieve(G)). // Double negation as shown in the lecture
/* End reasoning rules */

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: Shows that the agent is active
*/
@start_plan
+!start : true <-
	.print("Sensing agent active").

/* Plan for reacting to org_created(OrgName) - Connects and focuses on Org Board */
@org_created_plan
+org_created(OrgName) : true <-
	joinWorkspace(OrgName);
	lookupArtifact(OrgName, OrgArtId);
	focus(OrgArtId); // Initial focus on Org Artifact is correct
	.println("I am now focused on the organization: ", OrgName);
	.

/*
 * Plan reacting to perception of a group artifact.
*/
@group_plan
+group(GroupId, GroupType, GroupArtId) : true <-
	.println("Perceived group: ", GroupId, " (ArtId: ", GroupArtId, "). Triggering scan.");
	focus(GroupArtId); // Focus on Group Artifact
	!scan_group_specification(GroupArtId);
	.

/* Plan to scan the group specification. */
@scan_group_specification_plan
+!scan_group_specification(GroupArtId) : specification(group_specification(GroupName,RolesList,_,_)) <-
	for ( .member(Role,RolesList) ) {
    !reasoning_for_role_adoption(Role);
	}
	.

/* Plan for reasoning about and potentially adopting a role. */
@reasoning_for_role_adoption_plan
+!reasoning_for_role_adoption(role(Role,_,_,MinCard,MaxCard,_,_))
  : having_plan_for_role(Role) <-
    .print("Suitable for role: ", Role, ". Adopting."); // Message based on example
    adoptRole(Role);
    .

/* Failure plan for when agent doesn't have a plan for the role */
@reasoning_for_role_adoption_plan_fail_not_suitable
+!reasoning_for_role_adoption(role(Role,_,_,MinCard,MaxCard,_,_)) 
  : true <-
    .print("Not adopting role: ", Role, " (Not suitable for this role).");
    .


/* 
 * Plan for reacting to the addition of the goal !read_temperature
 * Triggering event: addition of goal !read_temperature
 * Context: true (the plan is always applicable)
 * Body: reads the temperature using a weather station artifact and broadcasts the reading
*/
@read_temperature_plan
+!read_temperature : true <-
	.print("I will read the temperature");
	makeArtifact("weatherStation", "tools.WeatherStation", [], WeatherStationId); // creates a weather station artifact
	focus(WeatherStationId); // focuses on the weather station artifact
	readCurrentTemperature(47.42, 9.37, Celcius); // reads the current temperature using the artifact
	.print("Temperature Reading (Celcius): ", Celcius);
	.broadcast(tell, temperature(Celcius)). // broadcasts the temperature reading

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that react to organizational events
(if observing, i.e. being focused on the appropriate organization artifacts) */
{ include("inc/skills.asl") }