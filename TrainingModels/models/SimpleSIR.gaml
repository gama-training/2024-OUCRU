/**
* Name: SimpleSIR
* Based on ideas from https://www.washingtonpost.com/graphics/2020/world/corona-simulator/ 
* Author: kevinchapuis
* Tags: 
*/


model SimpleSIR

global {
	
	// Global
	int nb <- 100;
	
	// Epidemic
	float contact_distance <- 2#m;
	int recover_after <- 50;
	float i_prop_start <- 0.05;
	
	// Policy
	float social_distancing <- -1.0;
	float free_rider <- 0.2;
	
	int time_after_realeasing_policies <- 0;
	
	bool quarantine <- false;
	bool lockdown <- false;
	
	// Display
	map<string,rgb> state_colors <- ["S"::#green,"I"::#red,"R"::#blue];
	
	// Observer
	int state_s -> people count (each.state="S");
	int state_i -> people count (each.state="I");
	int state_r -> people count (each.state="R");
	
	init {
		create people number:nb;
		ask int(i_prop_start*nb) among people {do infected;}
		do define_social_space;
	}
	
	/*
	 * Define a personal zone of social contact for agent
	 * -1 = no social distancing
	 * 0 = perfect social distancing (no contact)
	 * 10 = a small area people can interact around them
	 */
	action define_social_space {
		list<people> free_riders <- (free_rider*nb) among people;
		ask free_riders {social_space <- world.shape;}
		ask people - free_riders {
			if social_distancing=0 {social_space <- nil;} 
			else {social_space <- social_distancing < 0 ? world.shape : self buffer social_distancing;}
		}
	}
	
	/*
	 * Build zones where agent are lock inside 
	 */
	action define_lockdown_space {
		list<geometry> lspace <- world.shape to_squares (4,false);
		ask people { allowed_area <- one_of(lspace); }
	}
	
	/*
	 * Releasing policy after "n" time step
	 */
	reflex realease_policy when:time_after_realeasing_policies > 0 and cycle = time_after_realeasing_policies {
		ask people { social_space <- world.shape; allowed_area <- world.shape; }
	}
	
}

species people skills:[moving] {
	
	// Epi
	string state <- "S" among:["S","I","R"];
	int cycle_infect;
	
	// Move
	point target;
	geometry social_space;
	geometry allowed_area;
	
	reflex move when: social_space!=nil {
		if target=nil {target <- any_location_in(social_space union allowed_area);} 
		do goto target:target;
		if target distance_to self < 1#m {target <- nil; location <- target;}
	}
	
	reflex infect when:state="I" { 
		if quarantine {social_space <- nil;}
		ask people where (each.state="S") at_distance contact_distance { do infected; }
		if cycle-cycle_infect >= recover_after { state <- "R"; if quarantine {social_space <- world.shape;} }
	}
	
	action infected {
		state <- "I";
		cycle_infect <- cycle;
	}
	
	aspect default {
		draw cross(1) color:state_colors[state];
		draw circle(contact_distance) color:blend(state_colors[state],#transparent,0.1);
	}
	
}

experiment base_exp {
	
	parameter "social distancing" var:social_distancing among:[-1.0,0.0,5.0,10.0,20.0] category:"policy";
	parameter "free rider" var:free_rider min:0.0 max:1.0 category:"policy";
	parameter "time_after_release" var:time_after_realeasing_policies min:0 category:"policy";
	
	parameter "quarantine" var:quarantine category:"policy";
	parameter "lockdown" var:lockdown category:"policy";
	
}

experiment xp parent:base_exp {
	
	
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

experiment xplo type:batch repeat:20 
	until: people none_matches (each.state="I") parent:base_exp {
		
	//parameter nb_people var:nb among:[100,500,1000,2000,5000];
	parameter 'social distancing' var:social_distancing among:[-1.0,0,5.0,20.0];
	parameter 'free rider' var:free_rider min:0.0 max:1.0 step:0.2;
	
	permanent {
		display main type:2d{
			chart "states" type:series x_serie_labels:string(social_distancing)+"\n"+string(with_precision(free_rider,1)) {
				data "Susceptible" value:mean(simulations collect (each.state_s)) color:state_colors["S"];
				data "Infected" value:mean(simulations collect (each.state_i)) color:state_colors["I"];
				data "Recovered" value:mean(simulations collect (each.state_r)) color:state_colors["R"];
			}
		}
	}
	
	reflex save_output {
		ask simulations {
			save [int(self),state_s,state_i,state_r] to:"../results/simple_explo" format:'csv' rewrite:false;
		}
	}
	
}
