#include maps\_utility; 
#include common_scripts\utility;
#include maps\so\zm_common\_zm_utility;

init()
{
	PrecacheShader( "black" ); 

	if ( isDefined( level._custom_powerups ) && level._custom_powerups.size > 0 )
	{
		keys = getArrayKeys( level._custom_powerups );
		for ( i = 0; i < keys.size; i++ )
		{
			level [[ level._custom_powerups[ keys[ i ] ].precache_func ]]();
		}
	}
	// powerup Vars
	set_zombie_var( "zombie_point_scalar", 				1 );
	set_zombie_var( "zombie_drop_item", 				0 );
	set_zombie_var( "zombie_timer_offset", 				350 );	// hud offsets
	set_zombie_var( "zombie_timer_offset_interval", 	30 );
	set_zombie_var( "zombie_powerup_drop_increment", 	2000 );	// lower this to make drop happen more often
	set_zombie_var( "zombie_powerup_drop_max_per_round", 4 );	// lower this to make drop happen more often

	// powerups
	level._effect["powerup_on"] 				= loadfx( "misc/fx_zombie_powerup_on" );
	level._effect["powerup_grabbed"] 			= loadfx( "misc/fx_zombie_powerup_grab" );
	level._effect["powerup_grabbed_wave"] 		= loadfx( "misc/fx_zombie_powerup_wave" );
	if ( isDefined( level._custom_powerups ) && level._custom_powerups.size > 0 )
	{
		keys = getArrayKeys( level._custom_powerups );
		for ( i = 0; i < keys.size; i++ )
		{
			level [[ level._custom_powerups[ keys[ i ] ].setup_func ]]();
		}
	}
	init_powerups();
	level thread on_player_connect_powerup_init();
	thread watch_for_drop();
}

on_player_connect_powerup_init()
{
	while ( true )
	{
		level waittill( "connected", player );
		if ( isDefined( level._custom_powerups ) && level._custom_powerups.size > 0 )
		{
			keys = getArrayKeys( level._custom_powerups );
			for ( i = 0; i < keys.size; i++ )
			{
				if ( isDefined( level._custom_powerups[ keys[ i ] ].player_setup_func ) )
				{
					player [[ level._custom_powerups[ keys[ i ] ].player_setup_func ]]();
				}
			}
		}		
	}
}

init_powerups()
{
	// Random Drops
	//	add_zombie_special_powerup( "monkey" );

	// additional special "drops"
//	add_zombie_special_drop( "nothing" );
	add_zombie_special_drop( "dog" );

	// Randomize the order
	randomize_powerups();

	level.zombie_powerup_index = 0;
	randomize_powerups();
	if ( !is_true( level.use_legacy_powerup_system ) )
	{
		level thread powerup_hud_monitor();
	}
}

func_should_always_drop()
{
	return true;
}

powerup_hud_monitor()
{
	flag_wait( "start_zombie_round_logic" );

	flashing_timers = [];
	flashing_values = [];
	flashing_timer = 10;
	flashing_delta_time = 0;
	flashing_is_on = 0;
	flashing_value = 3;
	flashing_min_timer = 0.15;

	while ( flashing_timer >= flashing_min_timer )
	{
		if ( flashing_timer < 5 )
			flashing_delta_time = 0.1;
		else
			flashing_delta_time = 0.2;

		if ( flashing_is_on )
		{
			flashing_timer = flashing_timer - flashing_delta_time - 0.05;
			flashing_value = 2;
		}
		else
		{
			flashing_timer -= flashing_delta_time;
			flashing_value = 3;
		}

		flashing_timers[flashing_timers.size] = flashing_timer;
		flashing_values[flashing_values.size] = flashing_value;
		flashing_is_on = !flashing_is_on;
	}

	powerup_hud_fields = [];
	powerup_keys = getarraykeys( level._custom_powerups );

	for ( powerup_key_index = 0; powerup_key_index < powerup_keys.size; powerup_key_index++ )
	{
		if ( isdefined( level._custom_powerups[powerup_keys[powerup_key_index]].shader ) )
		{
			powerup_name = powerup_keys[powerup_key_index];
			powerup_hud_fields[powerup_name] = spawnstruct();
			powerup_hud_fields[powerup_name].shader = level._custom_powerups[powerup_name].shader;
			powerup_hud_fields[powerup_name].solo = level._custom_powerups[powerup_name].solo;
			powerup_hud_fields[powerup_name].time_name = level._custom_powerups[powerup_name].time_name;
			powerup_hud_fields[powerup_name].on_name = level._custom_powerups[powerup_name].on_name;
		}
	}

	powerup_hud_field_keys = getarraykeys( powerup_hud_fields );

	while ( true )
	{
		wait 0.05;
		waittillframeend;
		players = getPlayers();

		for ( playerindex = 0; playerindex < players.size; playerindex++ )
		{
			for ( powerup_hud_field_key_index = 0; powerup_hud_field_key_index < powerup_hud_field_keys.size; powerup_hud_field_key_index++ )
			{
				player = players[playerindex];

				if ( !isDefined( player.powerup_hud ) )
				{
					player.powerup_hud = [];
				}
/#
				if ( isdefined( player.pers["isBot"] ) && player.pers["isBot"] )
					continue;
#/
				if ( isdefined( level.powerup_player_valid ) )
				{
					if ( ![[ level.powerup_player_valid ]]( player ) )
						continue;
				}

				time_name = powerup_hud_fields[powerup_hud_field_keys[powerup_hud_field_key_index]].time_name;
				on_name = powerup_hud_fields[powerup_hud_field_keys[powerup_hud_field_key_index]].on_name;
				powerup_timer = undefined;
				powerup_on = undefined;

				if ( powerup_hud_fields[powerup_hud_field_keys[powerup_hud_field_key_index]].solo )
				{
					if ( isdefined( player._show_solo_hud ) && player._show_solo_hud == 1 )
					{
						powerup_timer = player.zombie_vars[time_name];
						powerup_on = player.zombie_vars[on_name];
					}
				}
				else if ( isdefined( level.zombie_vars[time_name] ) )
				{
					powerup_timer = level.zombie_vars[time_name];
					powerup_on = level.zombie_vars[on_name];
				}

				if ( isdefined( powerup_timer ) && isdefined( powerup_on ) )
				{
					if ( !is_true( player.powerup_hud[ powerup_hud_field_keys[ powerup_hud_field_key_index ] ].flashing ) )
					{
						player.powerup_hud[ powerup_hud_field_keys[ powerup_hud_field_key_index ] ] thread set_hud_powerups( powerup_timer, powerup_on );
					}
					continue;
				}

				player.powerup_hud[ powerup_hud_field_keys[ powerup_hud_field_key_index ] ].alpha = 0;
			}
		}
	}
}

set_hud_powerups( powerup_timer, powerup_on )
{
	self.flashing = true;
	if ( powerup_on )
	{
		if ( powerup_timer < 10 )
		{
			if ( powerup_timer < 5 )
			{
				wait 0.1;
				self.alpha = 0;
				wait 0.1;
				self.alpha = 1;
			}
			else 
			{
				wait 0.2;
				self.alpha = 0;
				wait 0.18;
				self.alpha = 1;
			}
		}
		else
			self.alpha = 1;
	}
	else
		self.alpha = 0;

	self.flashing = false;
}

randomize_powerups()
{
	level.zombie_powerup_array = array_randomize( level.zombie_powerup_array );
}

get_next_powerup()
{
	powerup = level.zombie_powerup_array[level.zombie_powerup_index];
	level.zombie_powerup_index++;

	if ( level.zombie_powerup_index >= level.zombie_powerup_array.size )
	{
		level.zombie_powerup_index = 0;
		randomize_powerups();
	}

	return powerup;
}

get_valid_powerup()
{
	powerup = get_next_powerup();
	while ( true )
	{
		if ( ![[ level._custom_powerups[powerup].func_should_drop_with_regular_powerups ]]() )
		{
			powerup = get_next_powerup();
			continue;
		}

		return powerup;
	}
}

watch_for_drop()
{
	players = getPlayers();
	score_to_drop = ( players.size * level.zombie_vars["zombie_score_start"] ) + level.zombie_vars["zombie_powerup_drop_increment"];

	while (1)
	{
		players = getPlayers();

		curr_total_score = 0;

		for (i = 0; i < players.size; i++)
		{
			curr_total_score += players[i].score_total;
		}

		if (curr_total_score > score_to_drop )
		{
			level.zombie_vars["zombie_powerup_drop_increment"] *= 1.14;
			score_to_drop = curr_total_score + level.zombie_vars["zombie_powerup_drop_increment"];
			level.zombie_vars["zombie_drop_item"] = 1;
		}

		wait( 0.5 );
	}
}

// special powerup list for the teleporter drop
add_zombie_special_drop( powerup_name )
{
	level.zombie_special_drop_array[ level.zombie_special_drop_array.size ] = powerup_name;
}

include_zombie_powerup( powerup_name )
{
	if( !IsDefined( level.zombie_include_powerups ) )
	{
		level.zombie_include_powerups = [];
	}

	level.zombie_include_powerups[powerup_name] = true;
}

powerup_round_start()
{
	level.powerup_drop_count = 0;
}

powerup_drop(drop_point)
{
	rand_drop = randomint(100);

	if( level.powerup_drop_count >= level.zombie_vars["zombie_powerup_drop_max_per_round"] )
	{
		println( "^3POWERUP DROP EXCEEDED THE MAX PER ROUND!" );
		return;
	}
	
	if( !isDefined(level.zombie_include_powerups) || level.zombie_include_powerups.size == 0 )
	{
		return;
	}

	// some guys randomly drop, but most of the time they check for the drop flag
	if (rand_drop > 2)
	{
		if (!level.zombie_vars["zombie_drop_item"])
		{
			return;
		}

		debug = "score";
	}
	else
	{
		debug = "random";
	}	

	// never drop unless in the playable area
	playable_area = getentarray("playable_area","targetname");

	powerup = maps\so\zm_common\_zm_network::network_safe_spawn( "powerup", 1, "script_model", drop_point + (0,0,40));
	
	//chris_p - fixed bug where you could not have more than 1 playable area trigger for the whole map
	valid_drop = false;

	for (i = 0; i < playable_area.size; i++)
	{
		if (powerup istouching(playable_area[i]))
		{
			valid_drop = true;
			//jezuzlizard - small optimization stop checking if we already know the drop is valid
			break;
		}
	}
	
	if(!valid_drop)
	{
		powerup delete();
		return;
	}

	powerup powerup_setup();
	level.powerup_drop_count++;

	print_powerup_drop( powerup.powerup_name, debug );

	powerup thread powerup_timeout();
	powerup thread powerup_wobble();
	powerup thread powerup_grab();

	level.zombie_vars["zombie_drop_item"] = 0;


	//powerup = powerup_setup(); 


	// if is !is touching trig
	// return

	// spawn the model, do a ground trace and place above
	// start the movement logic, spawn the fx
	// start the time out logic
	// start the grab logic
}


//
//	Special power up drop - done outside of the powerup system.
special_powerup_drop(drop_point)
{
// 	if( level.powerup_drop_count == level.zombie_vars["zombie_powerup_drop_max_per_round"] )
// 	{
// 		println( "^3POWERUP DROP EXCEEDED THE MAX PER ROUND!" );
// 		return;
// 	}

	if( !isDefined(level.zombie_include_powerups) || level.zombie_include_powerups.size == 0 )
	{
		return;
	}

	powerup = spawn ("script_model", drop_point + (0,0,40));

	// never drop unless in the playable area
	playable_area = getentarray("playable_area","targetname");
	//chris_p - fixed bug where you could not have more than 1 playable area trigger for the whole map
	valid_drop = false;
	for (i = 0; i < playable_area.size; i++)
	{
		if (powerup istouching(playable_area[i]))
		{
			valid_drop = true;
			break;
		}
	}

	if(!valid_drop)
	{
		powerup Delete();
		return;
	}

	powerup special_drop_setup();
}


//
//	Pick the next powerup in the list
powerup_setup()
{
	powerup = get_valid_powerup();

	struct = level._custom_powerups[powerup];
	self SetModel( struct.model_name );

	//TUEY Spawn Powerup
	playsoundatposition("spawn_powerup", self.origin);

	self.powerup_name = struct.powerup_name;
	self.hint = struct.hint;
	self.solo = struct.solo;
	self.caution = struct.caution;
	self.zombie_grabbable = struct.zombie_grabbable;
	self.func_should_drop_with_regular_powerups = struct.func_should_drop_with_regular_powerups;

	if( IsDefined( struct.fx ) )
	{
		self.fx = struct.fx;
	}
	
	self PlayLoopSound("spawn_powerup_loop");
}


//
//	Get the special teleporter drop
special_drop_setup()
{
	powerup = undefined;
	is_powerup = true;
	// Always give something at lower rounds or if a player is in last stand mode.
	if ( level.round_number <= 10 || maps\_laststand::player_num_in_laststand() )
	{
		powerup = get_valid_powerup();
	}
	// Gets harder now
	else
	{
		powerup = level.zombie_special_drop_array[ RandomInt(level.zombie_special_drop_array.size) ];
		if ( level.round_number > 15 &&
			 ( RandomInt(100) < (level.round_number - 15)*5 ) )
		{
			powerup = "nothing";
		}
	}
	//MM test  Change this if you want the same thing to keep spawning
//	powerup = "dog";
	switch ( powerup )
	{
	// Don't need to do anything special
	case "nuke":
	case "insta_kill":
	case "double_points":
	case "carpenter":
		break;

	// Limit max ammo drops because it's too powerful
	case "full_ammo":
		if ( level.round_number > 10 &&
			 ( RandomInt(100) < (level.round_number - 10)*5 ) )
		{
			// Randomly pick another one
			powerup = level.zombie_powerup_array[ RandomInt(level.zombie_powerup_array.size) ];
		}
		break;

	case "dog":
		if ( isDefined( level.ai_dogs_special_dog_spawn_func ) && level.round_number >= 15 )
		{
			is_powerup = false;
			dog_spawners = GetEntArray( "special_dog_spawner", "targetname" );
			level [[ level.ai_dogs_special_dog_spawn_func ]]( dog_spawners, 1 );
			//iprintlnbold( "Samantha Sez: No Powerup For You!" );
			thread play_sound_2d( "sam_nospawn" );
		}
		else
		{
			powerup = get_valid_powerup();
		}
		break;

	// Nothing drops!!
	default:	// "nothing"
		is_powerup = false;
		Playfx( level._effect["lightning_dog_spawn"], self.origin );
		playsoundatposition( "pre_spawn", self.origin );
		wait( 1.5 );
		playsoundatposition( "bolt", self.origin );

		Earthquake( 0.5, 0.75, self.origin, 1000);
		PlayRumbleOnPosition("explosion_generic", self.origin);
		playsoundatposition( "spawn", self.origin );

		wait( 1.0 );
		//iprintlnbold( "Samantha Sez: No Powerup For You!" );
		thread play_sound_2d( "sam_nospawn" );
		self Delete();
	}

	if ( is_powerup )
	{
		Playfx( level._effect["lightning_dog_spawn"], self.origin );
		playsoundatposition( "pre_spawn", self.origin );
		wait( 1.5 );
		playsoundatposition( "bolt", self.origin );

		Earthquake( 0.5, 0.75, self.origin, 1000);
		PlayRumbleOnPosition("explosion_generic", self.origin);
		playsoundatposition( "spawn", self.origin );

//		wait( 0.5 );

		struct = level._custom_powerups[powerup];
		self SetModel( struct.model_name );

		//TUEY Spawn Powerup
		playsoundatposition("spawn_powerup", self.origin);

		self.powerup_name 	= struct.powerup_name;
		self.hint 			= struct.hint;

		if( IsDefined( struct.fx ) )
		{
			self.fx = struct.fx;
		}

		self PlayLoopSound("spawn_powerup_loop");

		self thread powerup_timeout();
		self thread powerup_wobble();
		self thread powerup_grab();
	}
}

powerup_grab()
{
	self endon ("powerup_timedout");
	self endon ("powerup_grabbed");

	while (isdefined(self))
	{
		wait 0.1;
		players = getPlayers();

		for (i = 0; i < players.size; i++)
		{	
			if ( isDefined( level._custom_powerups ) && level._custom_powerups.size > 0 )
			{
				if ( isDefined( level._custom_powerups[ self.powerup_name ] ) && isDefined( level._custom_powerups[ self.powerup_name ].pre_grab_check_func ) )
				{
					can_grab = level [[ level._custom_powerups[ self.powerup_name ].pre_grab_check_func ]]( self, players[i] );
					if ( !can_grab )
					{
						continue;
					}
				}
			}
			if (distance (players[i].origin, self.origin) < 64)
			{
				if ( isdefined( level._powerup_global_grab_check ) )
				{
					if ( !level [[ level._powerup_global_grab_check ]]( self, players[i] ) )
						continue;
				}
				if ( isDefined( level._custom_powerups ) && level._custom_powerups.size > 0 )
				{
					if ( isDefined( level._custom_powerups[ self.powerup_name ] ) && isDefined( level._custom_powerups[ self.powerup_name ].grab_check_func ) )
					{
						can_grab = level [[ level._custom_powerups[ self.powerup_name ].grab_check_func ]]( self, players[i] );
						if ( !can_grab )
						{
							continue;
						}
					}
				}
				playfx (level._effect["powerup_grabbed"], self.origin);
				playfx (level._effect["powerup_grabbed_wave"], self.origin);	

				if( IsDefined( level.zombie_powerup_grab_func ) )
				{
					level thread [[level.zombie_powerup_grab_func]]();
				}
				else
				{
					if ( isDefined( level._custom_powerups ) && level._custom_powerups.size > 0 )
					{
						if ( isDefined( level._custom_powerups[ self.powerup_name ] ) && isDefined( level._custom_powerups[ self.powerup_name ].grab_func ) )
						{
							level thread [[ level._custom_powerups[ self.powerup_name ].grab_func ]]( self, players[i] );
						}
					}
				}

				wait( 0.1 );

				playsoundatposition("powerup_grabbed", self.origin);
				self stoploopsound();

				self delete();
				self notify ("powerup_grabbed");
			}
		}
	}	
}

powerup_vo(type)
{
	self endon("death");
	self endon("disconnect");
	
	index = maps\so\zm_common\_zm_weapons::get_player_index(self);
	sound = undefined;
	rand = randomintrange(0,3);
	vox_rand = randomintrange(1,100);  //RARE: This is to setup the Rare devil response lines
	percentage = 1;  //What percent chance the rare devil response line has to play
	
	if(!isdefined (level.player_is_speaking))
	{
		level.player_is_speaking = 0;
	}
	
	wait(randomfloatrange(1,2));
		
	switch(type)
	{
		case "nuke":
			if( vox_rand <= percentage )
			{
				//sound = "plr_" + index + "_vox_resp_dev_rare_" + rand;
				//iprintlnbold( "Whoopdedoo, rare Devil Response line" );
			}
			else
			{
				sound = "plr_" + index + "_vox_powerup_nuke_" + rand;
			}
			break;
		case "insta_kill":
			if( vox_rand <= percentage )
			{
				//sound = "plr_" + index + "_vox_resp_dev_rare_" + rand;
				//iprintlnbold( "Whoopdedoo, rare Devil Response line" );
			}
			else
			{
				sound = "plr_" + index + "_vox_powerup_insta_" + rand;
			}
			break;
		case "full_ammo":
			if( vox_rand <= percentage )
			{
				//sound = "plr_" + index + "_vox_resp_dev_rare_" + rand;
				//iprintlnbold( "Whoopdedoo, rare Devil Response line" );
			}
			else
			{
				sound = "plr_" + index + "_vox_powerup_ammo_" + rand;
			}
			break;
		case "double_points":
			if( vox_rand <= percentage )
			{
				//sound = "plr_" + index + "_vox_resp_dev_rare_" + rand;
				//iprintlnbold( "Whoopdedoo, rare Devil Response line" );
			}
			else
			{
				sound = "plr_" + index + "_vox_powerup_double_" + rand;
			}
			break; 		
		case "carpenter":
			if( vox_rand <= percentage )
			{
				//sound = "plr_" + index + "_vox_resp_dev_rare_" + rand;
				//iprintlnbold( "Whoopdedoo, rare Devil Response line" );
			}
			else
			{
				sound = "plr_" + index + "_vox_powerup_carp_" + rand;
			}
			break;
	}
	
	//This keeps multiple voice overs from playing on the same player (both killstreaks and headshots).
	if (level.player_is_speaking != 1 && isDefined(sound))
	{	
		level.player_is_speaking = 1;
		self playsound(sound, "sound_done");			
		self waittill("sound_done");
		level.player_is_speaking = 0;
	}	
	
	
}

powerup_wobble()
{
	self endon ("powerup_grabbed");
	self endon ("powerup_timedout");

	if (isdefined(self))
	{
		playfxontag (level._effect["powerup_on"], self, "tag_origin");
	}

	while (isdefined(self))
	{
		waittime = randomfloatrange(2.5, 5);
		yaw = RandomInt( 360 );
		if( yaw > 300 )
		{
			yaw = 300;
		}
		else if( yaw < 60 )
		{
			yaw = 60;
		}
		yaw = self.angles[1] + yaw;
		self rotateto ((-60 + randomint(120), yaw, -45 + randomint(90)), waittime, waittime * 0.5, waittime * 0.5);
		wait randomfloat (waittime - 0.1);
	}
}

powerup_timeout()
{
	self endon ("powerup_grabbed");

	wait 15;

	for (i = 0; i < 40; i++)
	{
		// hide and show
		if (i % 2)
		{
			self hide();
		}
		else
		{
			self show();
		}

		if (i < 15)
		{
			wait 0.5;
		}
		else if (i < 25)
		{
			wait 0.25;
		}
		else
		{
			wait 0.1;
		}
	}

	self notify ("powerup_timedout");
	self delete();
}

check_for_instakill( player )
{
	if( IsDefined( player ) && IsAlive( player ) && level.zombie_vars["zombie_insta_kill"])
	{
		if( is_magic_bullet_shield_enabled( self ) )
		{
			return;
		}

		if( self.animname == "boss_zombie" )
		{
			return;
		}

		if(player.use_weapon_type == "MOD_MELEE")
		{
			player.last_kill_method = "MOD_MELEE";
		}
		else
		{
			player.last_kill_method = "MOD_UNKNOWN";

		}

		if( flag( "dog_round" ) )
		{
			self DoDamage( self.health + 666, self.origin, player );
			player notify("zombie_killed");
		}
		else
		{
			if ( isDefined( level._zm_spawner_funcs ) && isDefined( level._zm_spawner_funcs[ "zombie_head_gib" ] ) )
			{
				self [[ level._zm_spawner_funcs[ "zombie_head_gib" ] ]]();
			}
			self DoDamage( self.health + 666, self.origin, player );
			player notify("zombie_killed");
			
		}
	}
}

play_devil_dialog(sound_to_play)
{
	if(!IsDefined(level.devil_is_speaking))
	{
		level.devil_is_speaking = 0;
	}
	if(level.devil_is_speaking == 0)
	{
		level.devil_is_speaking = 1;
		play_sound_2D( sound_to_play );
		wait 2.0;
		level.devil_is_speaking =0;
	}
	
}

//
// DEBUG
//

print_powerup_drop( powerup, type )
{
	/#
		if( !IsDefined( level.powerup_drop_time ) )
		{
			level.powerup_drop_time = 0;
			level.powerup_random_count = 0;
			level.powerup_score_count = 0;
		}

		time = ( GetTime() - level.powerup_drop_time ) * 0.001;
		level.powerup_drop_time = GetTime();

		if( type == "random" )
		{
			level.powerup_random_count++;
		}
		else
		{
			level.powerup_score_count++;
		}

		println( "========== POWER UP DROPPED ==========" );
		println( "DROPPED: " + powerup );
		println( "HOW IT DROPPED: " + type );
		println( "--------------------" );
		println( "Drop Time: " + time );
		println( "Random Powerup Count: " + level.powerup_random_count );
		println( "Random Powerup Count: " + level.powerup_score_count );
		println( "======================================" );
#/
}

register_powerup_basic_info( powerup, model, hint, func_should_drop_with_regular_powerups, solo, caution, zombie_grabbable, fx )
{
	_register_undefined_powerup( powerup );
	precachemodel( model );
	precachestring( hint );
	level._custom_powerups[ powerup ].powerup_name = powerup;
	level._custom_powerups[ powerup ].model_name = model;
	level._custom_powerups[ powerup ].hint = hint;
	level._custom_powerups[ powerup ].func_should_drop_with_regular_powerups = func_should_drop_with_regular_powerups;
	level._custom_powerups[ powerup ].solo = solo;
	level._custom_powerups[ powerup ].caution = caution;
	level._custom_powerups[ powerup ].zombie_grabbable = zombie_grabbable;
	if ( isDefined( fx ) )
		level._custom_powerups[ powerup ].fx = loadfx( fx );
	level._custom_powerups[ powerup ].weapon_classname = "script_model";
	level.zombie_powerup_array[ level.zombie_powerup_array.size ] = powerup;
	level.zombie_special_drop_array[level.zombie_special_drop_array.size] = powerup;
}

register_powerup_setup( powerup, precache_func, setup_func )
{
	_register_undefined_powerup( powerup );
	level._custom_powerups[ powerup ].precache_func = precache_func;
	level._custom_powerups[ powerup ].setup_func = setup_func;
}

register_powerup_hud_info( powerup, shader, time, on )
{
	_register_undefined_powerup( powerup );
	level._custom_powerups[ powerup ].shader = shader;
	level._custom_powerups[ powerup ].time_name = time;
	level._custom_powerups[ powerup ].on_name = on;
	if ( !isDefined( level.hud_powerups ) )
	{
		level.hud_powerups = [];
	}
	level.hud_powerups[ level.hud_powerups.size ] = powerup;
}

register_powerup_hud_player_info( powerup )
{
	hudelem = newClientHudelem( self );
	hudelem.foreground = true; 
	hudelem.sort = 2; 
	hudelem.hidewheninmenu = false; 
	hudelem.alignX = "center"; 
	hudelem.alignY = "bottom";
	hudelem.horzAlign = "center"; 
	hudelem.vertAlign = "bottom";
	hudelem.x = -32 + ( level.hud_powerups.size * 15); 
	hudelem.y = hudelem.y - 35; 
	hudelem.alpha = 0;
	hudelem.flashing = false;
	hudelem setshader( level._custom_powerups[ powerup ].shader, 32, 32);
	self.powerup_hud[ powerup ] = hudelem;
}

register_powerup_grab_info( powerup, grab_func, pre_grab_check_func, grab_check_func )
{
	_register_undefined_powerup( powerup );
	level._custom_powerups[ powerup ].grab_func = grab_func;
	if ( isDefined( pre_grab_check_func ) )
	{
		level._custom_powerups[ powerup ].pre_grab_check_func = pre_grab_check_func;
	}
	if ( isDefined( grab_check_func ) )
	{
		level._custom_powerups[ powerup ].grab_check_func = grab_check_func;
	}
}

register_powerup_player_setup( powerup, player_setup_func )
{
	_register_undefined_powerup( powerup );
	level._custom_powerups[ powerup ].player_setup_func = player_setup_func;
}

_register_undefined_powerup( str_powerup )
{
	if ( !isDefined( level._custom_powerups ) )
		level._custom_powerups = [];

	if( !IsDefined( level.zombie_powerup_array ) )
		level.zombie_powerup_array = [];
	if ( !IsDefined( level.zombie_special_drop_array ) )
		level.zombie_special_drop_array = [];

	if ( !isDefined( level._custom_powerups[ str_powerup ] ) )
		level._custom_powerups[ str_powerup ] = spawnstruct();
}