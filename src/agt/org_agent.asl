// organization agent

/* Initial beliefs and rules */
org_name("lab_monitoring_org"). // the agent beliefs that it can manage organizations with the id "lab_monitoting_org"
group_name("monitoring_team"). // the agent beliefs that it can manage groups with the id "monitoring_team"
sch_name("monitoring_scheme"). // the agent beliefs that it can manage schemes with the id "monitoring_scheme"

/* Reasoning for agents in role count */
has_enough_agents_for_role(R) :-
  role_cardinality(R,Min,Max) &
  .count(play(_,R,_),NP) &
  NP >= Min.
/* End reasoning for agents in role count */

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: Implemented for task 1
*/
@start_plan
+!start : org_name(OrgName) & group_name(GroupName) & sch_name(SchemeName) <-

  // Create and join the workspace
  .println("Creating new workspace: ", OrgName);
  createWorkspace(OrgName);
  joinWorkspace(OrgName, WspID1);

  // Make the organizational artifact
  .println("Creating new organizational artifact... ");
  makeArtifact(OrgName, "ora4mas.nopl.OrgBoard", ["src/org/org-spec.xml"], OrgBoardArtId)[wid(WspID1)];
  focus(OrgBoardArtId)[wid(WspID1)];

  // Create group and scheme boards
  .println("Creating new group and scheme boards... ");
  createGroup(GroupName, GroupName, GroupBoardArtId)[artifact_id(OrgBoardArtId)];
  focus(GroupBoardArtId)[wid(WspID1)];
  createScheme(SchemeName, SchemeName, SchemeBoardArtId)[artifact_id(OrgBoardArtId)];
  focus(SchemeBoardArtId)[wid(WspID1)];

  // Broadcast that a new organizational workspace is available
  .broadcast(tell, org_created(OrgName));

  // Inspect the Group and the Scheme
  !inspect(GroupBoardArtId)[wid(WorkspaceId)];
  !inspect(SchemeBoardArtId)[wid(WorkspaceId)];

  // Create the test-goal ?formationStatus(ok) to check if the group has been well-formed (wait for it)
  ?formationStatus(ok)[artifact_id(GroupBoardArtId)];
  .

  /* 
 * Plan for reacting to the addition of the test-goal ?formationStatus(ok)
 * Triggering event: addition of goal ?formationStatus(ok)
 * Context: the agent beliefs that there exists a group G whose formation status is being tested
 * Body: if the belief formationStatus(ok)[artifact_id(G)] is not already in the agents belief base
 * the agent waits until the belief is added in the belief base
*/
@test_formation_status_is_ok_plan
+?formationStatus(ok)[artifact_id(G)] : group(GroupName,_,G)[artifact_id(OrgName)] <-
  .print("Waiting for group ", GroupName," to become well-formed");
  .wait(15000); // Wait 15 seconds to then actively complete the group formation
  !actively_complete_group_formation(GroupName);
  .wait({+formationStatus(ok)[artifact_id(G)]}). // waits until the belief is added in the belief base

/* Plan for adding the Scheme to the group board if the group is well-formed */
@formation_status_is_ok_plan
+formationStatus(ok)[artifact_id(GroupBoardArtId)] : group(GroupName,_,GroupBoardArtId)[artifact_id(OrgName)] & scheme(SchemeName,SchemeType,SchemeBoardArtId) <-
  .print("Group ", GroupName, " is well-formed for the scheme.");
  addScheme(SchemeName)[artifact_id(GroupBoardArtId)];
  .

/* Plan for actively completing the group formation */
@actively_complete_group_formation_plan
+!actively_complete_group_formation(GroupName) : formationStatus(nok) & group(GroupName,GroupType,GroupArtId) & org_name(OrgName) & specification(group_specification(GroupName,RolesList,_,_)) <-
  .print("Group ", GroupName, " formation not completed after 15 seconds.");
  .print("Actively completing group formation for group ", GroupName);
  for (.member(Role,RolesList)) {
    !check_role_filled(Role);
  }
  .wait(15000);
  !actively_complete_group_formation(GroupName);
  .

@actively_complete_group_formation_plan_success
+!actively_complete_group_formation(GroupName) : formationStatus(ok) <-
  .print("Group ", GroupName, " formation completed successfully.");
  .

/* Plan for checking missing agents in a role */
@check_role_filled_plan
+!check_role_filled(role(Role,_,_,MinCard,MaxCard,_,_)) : not has_enough_agents_for_role(Role) & org_name(OrgName) & group_name(GroupName) <-
  .print("Agents missing for role: ", Role);
  .broadcast(tell, ask_fulfill_role(Role, GroupName, OrgName)).

/* Default plan (enough agents) */
@check_role_filled_plan_fail
+!check_role_filled(role(Role,_,_,MinCard,MaxCard,_,_)) : true <-
  true
  .

/* 
 * Plan for reacting to the addition of the goal !inspect(OrganizationalArtifactId)
 * Triggering event: addition of goal !inspect(OrganizationalArtifactId)
 * Context: true (the plan is always applicable)
 * Body: performs an action that launches a console for observing the organizational artifact 
 * identified by OrganizationalArtifactId
*/
@inspect_org_artifacts_plan
+!inspect(OrganizationalArtifactId) : true <-
  // performs an action that launches a console for observing the organizational artifact
  // the action is offered as an operation by the superclass OrgArt (https://moise.sourceforge.net/doc/api/ora4mas/nopl/OrgArt.html)
  debug(inspector_gui(on))[artifact_id(OrganizationalArtifactId)]. 

/* 
 * Plan for reacting to the addition of the belief play(Ag, Role, GroupId)
 * Triggering event: addition of belief play(Ag, Role, GroupId)
 * Context: true (the plan is always applicable)
 * Body: the agent announces that it observed that agent Ag adopted role Role in the group GroupId.
 * The belief is added when a Group Board artifact (https://moise.sourceforge.net/doc/api/ora4mas/nopl/GroupBoard.html)
 * emmits an observable event play(Ag, Role, GroupId)
*/
@play_plan
+play(Ag, Role, GroupId) : true <-
  .print("Agent ", Ag, " adopted the role ", Role, " in group ", GroupId).

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }