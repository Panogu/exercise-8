// acting agent

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://ci.mines-stetienne.fr/kg/ontology#PhantomX
robot_td("https://raw.githubusercontent.com/Interactions-HSG/example-tds/main/tds/leubot1.ttl").

/* Initial beliefs and rules */

/* Reasoning rules */
// Rule: Link roles to their ultimate goals via missions
role_goal(R, G) :-
   role_mission(R, _, M) & mission_goal(M, G).

// Rule: Check if the agent has a plan for a specific goal
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
 * Context: true (the plan is always applicable)
 * Body: announces the agent is active and ready
*/
@start_plan
+!start : true <-
	.print("Acting agent active").

/* 
 * Plan for handling direct role invitation
 * This is used as a fallback if the organizational reasoning doesn't trigger
 */
@ask_fulfill_role_plan
+ask_fulfill_role(Role, GroupName, OrgName) : true <-
    .print("Received direct invitation for role: ", Role, " in group: ", GroupName);
    
    joinWorkspace(OrgName);
	lookupArtifact(OrgName, OrgArtId);
	focus(OrgArtId);
	lookupArtifact(GroupName, GroupArtId);
	focus(GroupArtId);
    
    // Only adopt if we have a plan for this role
    if (having_plan_for_role(Role)) {
        .print("I can fulfill this role. Adopting role: ", Role);
        adoptRole(Role);
    } else {
        .print("I am not suitable for role: ", Role);
    }
    .

/* 
 * Plan for receiving temperature broadcasts from the sensing agent
 */
+temperature(Celsius) : true <-
    .print("Received temperature reading: ", Celsius, "°C");
    .

/* 
 * Plan for reacting to the addition of the goal !manifest_temperature
 * Triggering event: addition of goal !manifest_temperature
 * Context: the agent believes that there is a temperature in Celsius and
 * that a WoT TD of an onto:PhantomX is located at Location
 * Body: converts the temperature from Celsius to binary degrees that are compatible with the 
 * movement of the robotic arm. Then, manifests the temperature with the robotic arm
*/
@manifest_temperature_plan 
+!manifest_temperature : temperature(Celsius) & robot_td(Location) <-
	.print("I will manifest the temperature: ", Celsius);
	makeArtifact("converter", "tools.Converter", [], ConverterId); // creates a converter artifact
	convert(Celsius, -20.00, 20.00, 200.00, 830.00, Degrees)[artifact_id(ConverterId)]; // converts Celsius to binary degress based on the input scale
	.print("Temperature Manifesting (moving robotic arm to): ", Degrees);

	/* 
	 * If you want to test with the real robotic arm, 
	 * follow the instructions here: https://github.com/HSG-WAS-FS25/exercise-8/blob/main/README.md#test-with-the-real-phantomx-reactor-robot-arm
	 */
	// creates a ThingArtifact based on the TD of the robotic arm
	makeArtifact("leubot1", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [Location, true], Leubot1Id); 
	
	// sets the API key for controlling the robotic arm as an authenticated user
	//setAPIKey("77d7a2250abbdb59c6f6324bf1dcddb5")[artifact_id(Leubot1Id)];

	// invokes the action onto:SetWristAngle for manifesting the temperature with the wrist of the robotic arm
	invokeAction("https://ci.mines-stetienne.fr/kg/ontology#SetWristAngle", ["https://www.w3.org/2019/wot/json-schema#IntegerSchema"], [Degrees])[artifact_id(Leubot1Id)].

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that react to organizational events */
{ include("inc/skills.asl") }