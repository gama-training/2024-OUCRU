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

	// Display
	map<string,rgb> state_colors <- ["S"::#green,"I"::#red,"R"::#blue];

	init {
		// HERE: we initialize the social space as the whole world for everybody
		create people number:100 with:[social_space::world.shape];
		// Then a certain amount gets their social space limited
		ask (policy_target*length(people)) among people {
			social_space <- location;
		}
		
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
		if target=nil {
			target <- any_location_in(social_space);
		} 
		do goto target:target; 
		if target distance_to self < 1#m {
			target <- nil; location <- target;
		}
 	}
 	
 	reflex infect when:state="I" {
 		ask people where (each.state="S") at_distance contact_distance {
 			do infected;
 		}
 		if cycle-cycle_infect >= recovering_time { 
 			state <- "R";
 		}
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
		}
		display chart type:2d{
			chart "state dynamic" type:series {
				loop stt over:["S","I","R"] {data stt value:people count (each.state=stt) color:state_colors[stt];}
			}
		}
	}
}


