/**
* Name: SimpleSIR4
* Based on the internal empty template. 
* Author: kevinchapuis
* Tags: 
*/


model SimpleSIR4

global {
	
	// init
	int n <- 2;
	
	// Epidemiological
	float contact_distance <- 2#m;
	int recovering_time <- 40;

	// Policies
	float policy_target <- 0.4;
	list<geometry> locked_areas;
	bool quarantine;

	// Display
	map<string,rgb> state_colors <- ["S"::#green,"I"::#red,"R"::#blue];

	init {
		create people number:100 with:[social_space::world.shape];
		ask (policy_target*length(people)) among people {social_space <- location;}
		locked_areas <- world.shape to_squares (4,true);
		ask people { if not (social_space is point) { social_space <- locked_areas first_with (each overlaps self); }}
		ask n among people {state <- "I";}
	}
	
	reflex sim_stop when:people none_matches (each.state="I") {
		do pause;
	}	
	
}

species people skills:[moving] {
	
	string state <- "S" among:["S","I","R"];
	int cycle_infect;
	
	point target;
	geometry social_space;
	
	reflex move {
		if target=nil {target <- any_location_in(social_space);} 
		do goto target:target; 
		if target distance_to self < 1#m {target <- nil; location <- target;}
 	}
 	
 	reflex infect when:state="I" {
 		if quarantine {social_space <- location;}
 		ask people where (each.state="S") at_distance contact_distance { do infected; }
 		if cycle-cycle_infect >= recovering_time { state <- "R"; if quarantine {social_space <- world.shape;} }
 	}
	
	action infected {
		state <- "I";
		cycle_infect <- cycle;
	}
	
	aspect default {
		draw circle(1) color:state_colors[state];
	}
}

experiment NewModel1 type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display main {
			species people;
			graphics areas { loop area over:locked_areas {draw area color:#transparent border:#black;} }
		}
		display chart type:2d{
			chart "state dynamic" type:series {
				loop stt over:["S","I","R"] {data stt value:people count (each.state=stt) color:state_colors[stt];}
			}
		}
	}
}


