/**
* Name: SimpleSIR7
* Based on the internal empty template. 
* Author: kevinchapuis
* Tags: 
*/


model SimpleSIR7

global {
	
	// init
	int nb_initial_infected <- 3;
	bool limit_social_space <- true;
	bool lockdown <- true;
	int m <- limit_social_space ? 10 : 0 ;
	int nb_freeriders <- 10;// number freeriders
	bool quarantine <- true;
	
	// Epidemiological
	float contact_distance <- 2#m;
	int recovering_time <- 40;

	// Display
	map<string,rgb> state_colors <- ["S"::#green, "I"::#red, "R"::#blue];
	list<geometry> spaces <- lockdown ? split_geometry(world.shape, 50) : world;

	init {
		
		create people number:100;
		
		ask nb_freeriders among people {
			freerider <- true;
			social_space <- world;
		}	
		ask nb_initial_infected among people {
			state <- "I";
		}
		ask m among people - (people where each.freerider) {
			at_home <- true;
			social_space <- circle(3);
		}	
	}

	
	reflex sim_stop when:people none_matches (each.state="I") {
		do pause;
	}	
	
}

species people skills:[moving] {
	
	string state <- "S" among:["S","I","R"];
	
	int infected_at_cycle;
	bool at_home <- false;
	geometry social_space <- first(spaces overlapping(self));
	
	point target;
	bool freerider <- false;
	
	reflex move {
		if state != "I" or not quarantine or freerider{
			if target=nil {
				target <- any_location_in(social_space);
			}
			do goto target:target; 
			if target distance_to self < 1#m {
				location <- target;
				target <- nil; 
			}			
		}
 	}
 	
 	reflex infect when:state="I" {
 		ask people where (each.state="S") at_distance contact_distance { 
 			do infected;
 		}
 		if cycle-infected_at_cycle >= recovering_time { 
 			state <- "R";
 		}
 	}
	
	action infected {
		state <- "I";
		infected_at_cycle <- cycle;
	}
	
	aspect default {
		if at_home {
			draw social_space color:#yellow;
		}
		rgb border_color <- freerider ? #black : state_colors[state];
		draw circle(1) color:state_colors[state] border:border_color;
	}
}


experiment SIR_experiment type: gui {
	
	parameter "contamination distance" var:contact_distance min:1#m max:10#m slider:true;
	parameter "Quarantine" var:quarantine;
	parameter "Limiting social space" var:limit_social_space;
	parameter "Lockdown" var:lockdown;
	
	output {

		monitor "Nb infected" value:people count (each.state = "I");

		display main type:2d{
			
			species people;
			graphics lockdown_areas{
				loop i over:spaces {
					draw i color:#transparent border:#black ;
				}
			}
		}
		display chart type:2d{
			chart "state dynamic" type:series {
				loop stt over:["S","I","R"] {
					data stt value:people  count (each.state=stt) color:state_colors[stt];
//					data stt + " people in first area" value:(people where (length([first(spaces)] overlapping self) > 0)) count (each.state=stt) color:state_colors[stt];

				}
			}
		}
	}
}


