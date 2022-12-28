#include common_scripts\utility; 
#include maps\_utility;
#include maps\_music; 
#include maps\so\zm_common\_zm_utility;
#include maps\so\zm_common\_zm_weapons;

main()
{	
	setDvar( "magic_chest_movable", "0" );
	maps\_destructible_opel_blitz::init();
	level.startInvulnerableTime = GetDvarInt( "player_deathInvulnerableTime" );

	if ( isDefined( level.zm_custom_map_include_weapons ) )
	{
		level [[ level.zm_custom_map_include_weapons ]]();
	}
	else 
	{
		include_weapons();
	}
	if ( isDefined( level.zm_custom_map_include_powerups ) )
	{
		level [[ level.zm_custom_map_include_powerups ]]();
	}
	else 
	{
		include_powerups();
	}
	
	if( !isdefined( level.startInvulnerableTime ) )
		level.startInvulnerableTime = GetDvarInt( "player_deathInvulnerableTime" );

	maps\nazi_zombie_prototype_fx::main();

	//Check if its defined first so mods can override it
	if ( !isDefined( level.zm_custom_map_precache ) )
	{
		level.zm_custom_map_precache = ::prototype_precache_func;
	}
	if ( !isDefined( level.custom_introscreen ) )
	{
		level.custom_introscreen = ::prototype_custom_intro_screen;
	}
	if ( !isDefined( level.zm_custom_map_fx_init ) )
	{
		level.zm_custom_map_fx_init = ::init_fx;
	}
	if ( !isDefined( level.zm_custom_map_anim_init ) )
	{
		level.zm_custom_map_anim_init = ::init_anims;
	}
	if ( !isDefined( level.zm_custom_map_leaderboard_init ) )
	{
		level.zm_custom_map_leaderboard_init = ::prototype_init_zombie_leaderboard_data;
	}
	if ( !isDefined( level.zm_custom_map_weapon_add_func ) )
	{
		level.zm_custom_map_weapon_add_func = ::prototype_add_weapons;
	}
	if ( !isDefined( level.use_legacy_sound_playing ) )
	{
		level.use_legacy_sound_playing = true;
	}
	if ( !isDefined( level.use_legacy_powerup_system ) )
	{
		level.use_legacy_powerup_system = true;
	}
	if ( !isDefined( level.no_player_dialog ) )
	{
		level.no_player_dialog = true;
	}
	if ( isDefined( level.zm_custom_map_perk_machines_func ) )
	{
		level [[ level.zm_custom_map_perk_machines_func ]]();
	}
	maps\so\zm_common\powerups\_zm_powerup_double_points::enable_double_points_powerup_for_level();
	maps\so\zm_common\powerups\_zm_powerup_full_ammo::enable_full_ammo_powerup_for_level();
	maps\so\zm_common\powerups\_zm_powerup_insta_kill::enable_insta_kill_powerup_for_level();
	maps\so\zm_common\powerups\_zm_powerup_nuke::enable_nuke_powerup_for_level();
	maps\so\zm_common\_zm_spawner_prototype::init();
	maps\so\zm_common\_zm::init_zm();
	maps\so\zm_common\_zm_utility::add_sound( "break_stone", "break_stone" );

	if ( !is_true( level.dont_use_map_glitch_patches ) )
	{
		thread bad_area_fixes();

		thread above_couches_death();
		thread above_roof_death();
		thread below_ground_death();
	}
}


bad_area_fixes()
{
	thread disable_stances_in_zones();
}


// do point->distance checks and volume checks
disable_stances_in_zones()
{ 	
	players = getPlayers();
	
	for (i = 0; i < players.size; i++)
	{
		players[i] thread fix_hax();
		players[i] thread fix_couch_stuckspot();
		//players[i] thread in_bad_zone_watcher();	
		players[i] thread out_of_bounds_watcher();
	}
}




//Chris_P - added additional checks for some hax/exploits on the stairs, by the grenade bag and on one of the columns/pillars
fix_hax()
{
	self endon("disconnect");
	self endon("death");
	
	check = 15;
	check1 = 10;
	
	while(1)
	{
	
		//stairs
		wait(.5);
		if( distance2d(self.origin,( 101, -100, 40)) < check )
		{
			self setorigin ( (101, -90, self.origin[2]));
		}
		
		//crates/boxes
		else if( distance2d(self.origin, ( 816, 645, 12) ) < check )
		{
			self setorigin ( (816, 666, self.origin[2]) );
		
		}
		
		else if( distance2d( self.origin, (376, 643, 184) ) < check )
		{
			self setorigin( (376, 665, self.origin[2]) );
		}
		
		//by grandfather clock
		else	if(distance2d(self.origin,(519 ,765, 155)) < check1) 
		{
			self setorigin( (516, 793,self.origin[2]) );
		}
		
		//broken pillar
		else if( distance2d(self.origin,(315 ,346, 79))<check1)
		{
			self setorigin( (317, 360, self.origin[2]) );
		}
	
		//rubble by pillar
		else if( distance2d(self.origin,(199, 133, 18))<check)
		{
			self setorigin( (172, 123, self.origin[2]) );
		}
		
		//nook in curved stairs
		else if( distance2d(self.origin,(142 ,-100 ,91))<check1)
		{
			self setorigin( (139 ,-87, self.origin[2]) );
		}
		
		//by sawed off shotty				
		else if( distance2d(self.origin,(192, 369 ,185))<check1)
		{
			self setorigin( (195, 400 ,self.origin[2]) );
		}
		
		//rubble pile in the corner
		else if( distance2d(self.origin,(-210, 641, 247)) < check)
		{
			self setorigin( (-173 ,677,self.origin[2] ) );
		}
	}
}



fix_couch_stuckspot()
{
	self endon("disconnect");
	self endon("death");
	level endon("upstairs_blocker_purchased");

	while(1)
	{
		wait(.5);

		if( distance2d(self.origin, ( 181, 161, 206) ) < 10 )
		{
			self setorigin ( (175, 175 , self.origin[2]) );
		
		}		
		
	}

}




in_bad_zone_watcher()
{
	self endon ("disconnect");
	level endon ("fake_death");
	
	no_prone_and_crouch_zones = [];
	
	// grenade wall
	no_prone_and_crouch_zones[0]["min"] = (-205, -128, 144);
	no_prone_and_crouch_zones[0]["max"] = (-89, -90, 269);

	no_prone_zones = [];
	
	// grenade wall
	no_prone_zones[0]["min"] = (-205, -128, 144);
	no_prone_zones[0]["max"] = (-55, 30, 269);

	// near the sawed off
	no_prone_zones[1]["min"] = (88, 305, 144);
	no_prone_zones[1]["max"] = (245, 405, 269);
	
	while (1)
	{	
		array_check = 0;
		
		if ( no_prone_and_crouch_zones.size > no_prone_zones.size)
		{
			array_check = no_prone_and_crouch_zones.size;
		}
		else
		{
			array_check = no_prone_zones.size;
		}
		
		for(i = 0; i < array_check; i++)
		{
			if (isdefined(no_prone_and_crouch_zones[i]) && 
				self is_within_volume(no_prone_and_crouch_zones[i]["min"][0], no_prone_and_crouch_zones[i]["max"][0], 
											no_prone_and_crouch_zones[i]["min"][1], no_prone_and_crouch_zones[i]["max"][1],
											no_prone_and_crouch_zones[i]["min"][2], no_prone_and_crouch_zones[i]["max"][2]))
			{
				self allowprone(false);
				self allowcrouch(false);	
				break;
			}
			else if (isdefined(no_prone_zones[i]) && 
				self is_within_volume(no_prone_zones[i]["min"][0], no_prone_zones[i]["max"][0], 
											no_prone_zones[i]["min"][1], no_prone_zones[i]["max"][1],
											no_prone_zones[i]["min"][2], no_prone_zones[i]["max"][2]))
			{
				self allowprone(false);
				break;
			}
			else
			{
				self allowprone(true);
				self allowcrouch(true);
			}
			
			
		}		
		wait 0.05;
	}	
}


is_within_volume(min_x, max_x, min_y, max_y, min_z, max_z)
{
	if (self.origin[0] > max_x || self.origin[0] < min_x)
	{
		return false;
	}
	else if (self.origin[1] > max_y || self.origin[1] < min_y)
	{
		return false;
	}
	else if (self.origin[2] > max_z || self.origin[2] < min_z)
	{
		return false;
	}	
	
	return true;
}

// Include the weapons that are only inr your level so that the cost/hints are accurate
// Also adds these weapons to the random treasure chest.
include_weapons()
{
	// Pistols
	//include_weapon( "colt" );
	//include_weapon( "colt_dirty_harry" );
	//include_weapon( "walther" );
	include_weapon( "sw_357" );
	
	// Semi Auto
	include_weapon( "m1carbine" );
	include_weapon( "m1garand" );
	include_weapon( "gewehr43" );

	// Full Auto
	include_weapon( "stg44" );
	include_weapon( "thompson" );
	include_weapon( "mp40" );
	
	// Bolt Action

	include_weapon( "kar98k" );
	include_weapon( "springfield" );

	// Scoped
	include_weapon( "ptrs41_zombie" );
	include_weapon( "kar98k_scoped_zombie" );
		
	// Grenade
	include_weapon( "molotov" );
	// JESSE: lets go all german grenades for consistency and to reduce annoyance factor
	//	include_weapon( "fraggrenade" );
	include_weapon( "stielhandgranate" );

	// Grenade Launcher
	include_weapon( "m1garand_gl" );
	include_weapon( "m7_launcher" );
	
	// Flamethrower
	include_weapon( "m2_flamethrower_zombie" );
	
	// Shotgun
	include_weapon( "doublebarrel" );
	include_weapon( "doublebarrel_sawed_grip" );
	include_weapon( "shotgun" );
	
	// Bipod
	include_weapon( "fg42_bipod" );
	include_weapon( "mg42_bipod" );
	include_weapon( "30cal_bipod" );

	// Heavy MG
	include_weapon( "bar" );

	// Rocket Launcher
	include_weapon( "panzerschrek" );

	// Special
	include_weapon( "ray_gun" );
}

prototype_add_weapons()
{
	// Zombify
	PrecacheItem( "zombie_melee" );
	
	// Pistols
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "colt", 									&"ZOMBIE_WEAPON_COLT_50", 					50 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "colt_dirty_harry", 						&"ZOMBIE_WEAPON_COLT_DH_100", 				100 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "nambu", 								&"ZOMBIE_WEAPON_NAMBU_50", 					50 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "sw_357", 								&"ZOMBIE_WEAPON_SW357_100", 				100 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "tokarev", 								&"ZOMBIE_WEAPON_TOKAREV_50", 				50 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "walther", 								&"ZOMBIE_WEAPON_WALTHER_50", 				50 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_colt", 							&"ZOMBIE_WEAPON_ZOMBIECOLT_25", 			25 );
                                                        		
	// Bolt Action                                      		
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "kar98k", 								&"ZOMBIE_WEAPON_KAR98K_200", 				200 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "kar98k_bayonet", 						&"ZOMBIE_WEAPON_KAR98K_B_200", 				200 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mosin_rifle", 							&"ZOMBIE_WEAPON_MOSIN_200", 				200 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mosin_rifle_bayonet", 					&"ZOMBIE_WEAPON_MOSIN_B_200", 				200 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "springfield", 							&"ZOMBIE_WEAPON_SPRINGFIELD_200", 			200 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "springfield_bayonet", 					&"ZOMBIE_WEAPON_SPRINGFIELD_B_200", 		200 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type99_rifle", 							&"ZOMBIE_WEAPON_TYPE99_200", 				200 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type99_rifle_bayonet", 					&"ZOMBIE_WEAPON_TYPE99_B_200", 				200 );
                                                        		
	// Semi Auto                                        		
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "gewehr43", 								&"ZOMBIE_WEAPON_GEWEHR43_600", 				600 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "m1carbine", 							&"ZOMBIE_WEAPON_M1CARBINE_600",				600 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "m1carbine_bayonet", 					&"ZOMBIE_WEAPON_M1CARBINE_B_600", 			600 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "m1garand", 								&"ZOMBIE_WEAPON_M1GARAND_600", 				600 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "m1garand_bayonet", 						&"ZOMBIE_WEAPON_M1GARAND_B_600", 			600 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "svt40", 								&"ZOMBIE_WEAPON_SVT40_600", 				600 );
                                                        		
	// Grenades                                         		
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "fraggrenade", 							&"ZOMBIE_WEAPON_FRAGGRENADE_250", 			250 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "molotov", 								&"ZOMBIE_WEAPON_MOLOTOV_200", 				200 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "stick_grenade", 						&"ZOMBIE_WEAPON_STICKGRENADE_250", 			250 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "stielhandgranate", 						&"ZOMBIE_WEAPON_STIELHANDGRANATE_250", 		250 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type97_frag", 							&"ZOMBIE_WEAPON_TYPE97FRAG_250", 			250 );

	// Scoped
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "kar98k_scoped_zombie", 					&"ZOMBIE_WEAPON_KAR98K_S_750", 				750 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "kar98k_scoped_bayonet_zombie", 			&"ZOMBIE_WEAPON_KAR98K_S_B_750", 			750 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mosin_rifle_scoped_zombie", 			&"ZOMBIE_WEAPON_MOSIN_S_750", 				750 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mosin_rifle_scoped_bayonet_zombie", 	&"ZOMBIE_WEAPON_MOSIN_S_B_750", 			750 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "ptrs41_zombie", 						&"ZOMBIE_WEAPON_PTRS41_750", 				750 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "springfield_scoped_zombie", 			&"ZOMBIE_WEAPON_SPRINGFIELD_S_750", 		750 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "springfield_scoped_bayonet_zombie", 	&"ZOMBIE_WEAPON_SPRINGFIELD_S_B_750", 		750 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type99_rifle_scoped_zombie", 			&"ZOMBIE_WEAPON_TYPE99_S_750", 				750 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type99_rifle_scoped_bayonet_zombie", 	&"ZOMBIE_WEAPON_TYPE99_S_B_750", 			750 );
                                                                                                	
	// Full Auto                                                                                	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mp40", 								&"ZOMBIE_WEAPON_MP40_1000", 				1000 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "ppsh", 								&"ZOMBIE_WEAPON_PPSH_2000", 				2000 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "stg44", 							&"ZOMBIE_WEAPON_STG44_1200", 				1200 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "thompson", 							&"ZOMBIE_WEAPON_THOMPSON_1500", 			1500 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type100_smg", 						&"ZOMBIE_WEAPON_TYPE100_1000", 				1000 );
                                                        	
	// Shotguns                                         	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "doublebarrel", 						&"ZOMBIE_WEAPON_DOUBLEBARREL_1200", 		1200 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "doublebarrel_sawed_grip", 			&"ZOMBIE_WEAPON_DOUBLEBARREL_SAWED_1200", 	1200 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "shotgun", 							&"ZOMBIE_WEAPON_SHOTGUN_1500", 				1500 );
                                                        	
	// Heavy Machineguns                                	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "30cal", 							&"ZOMBIE_WEAPON_30CAL_3000", 				3000 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "bar", 								&"ZOMBIE_WEAPON_BAR_1800", 					1800 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "dp28", 								&"ZOMBIE_WEAPON_DP28_2250", 				2250 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "fg42", 								&"ZOMBIE_WEAPON_FG42_1200", 				1500 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "fg42_scoped", 						&"ZOMBIE_WEAPON_FG42_S_1200", 				1500 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mg42", 								&"ZOMBIE_WEAPON_MG42_1200", 				3000 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type99_lmg", 						&"ZOMBIE_WEAPON_TYPE99_LMG_1750", 			1750 );
                                                        	
	// Grenade Launcher                                 	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "m1garand_gl", 						&"ZOMBIE_WEAPON_M1GARAND_GL_1200", 			1200 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mosin_launcher", 					&"ZOMBIE_WEAPON_MOSIN_GL_1200", 			1200 );
	                                        				
	// Bipods                               				
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "30cal_bipod", 						&"ZOMBIE_WEAPON_30CAL_BIPOD_3500", 			3500 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "bar_bipod", 						&"ZOMBIE_WEAPON_BAR_BIPOD_2500", 			2500 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "dp28_bipod", 						&"ZOMBIE_WEAPON_DP28_BIPOD_2500", 			2500 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "fg42_bipod", 						&"ZOMBIE_WEAPON_FG42_BIPOD_2000", 			2000 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mg42_bipod", 						&"ZOMBIE_WEAPON_MG42_BIPOD_3250", 			3250 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type99_lmg_bipod", 					&"ZOMBIE_WEAPON_TYPE99_LMG_BIPOD_2250", 	2250 );
	
	// Rocket Launchers
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "bazooka", 							&"ZOMBIE_WEAPON_BAZOOKA_2000", 				2000 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "panzerschrek", 						&"ZOMBIE_WEAPON_PANZERSCHREK_2000", 		2000 );
	                                                    	
	// Flamethrower                                     	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "m2_flamethrower_zombie", 			&"ZOMBIE_WEAPON_M2_FLAMETHROWER_3000", 		3000 );	
                                                        	
	// Special                                          	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mortar_round", 						&"ZOMBIE_WEAPON_MORTARROUND_2000", 			2000 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "satchel_charge", 					&"ZOMBIE_WEAPON_SATCHEL_2000", 				2000 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "ray_gun", 							&"ZOMBIE_WEAPON_RAYGUN_10000", 				10000 );

	// ONLY 1 OF THE BELOW SHOULD BE ALLOWED
	maps\so\zm_common\_zm_weapons::add_limited_weapon( "m2_flamethrower_zombie", 1 );
}

include_powerups()
{
	include_powerup( "nuke" );
	include_powerup( "insta_kill" );
	include_powerup( "double_points" );
	include_powerup( "full_ammo" );
}

above_couches_death()
{
	level endon ("junk purchased");
	
	while (1)
	{
		wait 0.2;
				
		players = getPlayers();
		
		for (i = 0; i < players.size; i++)
		{
			if (players[i].origin[2] > 145)
			{
				setsaveddvar("player_deathInvulnerableTime", 0);
				players[i] DoDamage( players[i].health + 1000, players[i].origin, undefined, undefined, "riflebullet" );
				setsaveddvar("player_deathInvulnerableTime", level.startInvulnerableTime);	
			}
		}
	}
}

above_roof_death()
{
	while (1)
	{
		wait 0.2;
		
		players = getPlayers();
		
		for (i = 0; i < players.size; i++)
		{
			if (players[i].origin[2] > 235)
			{
				setsaveddvar("player_deathInvulnerableTime", 0);
				players[i] DoDamage( players[i].health + 1000, players[i].origin, undefined, undefined, "riflebullet" );
				setsaveddvar("player_deathInvulnerableTime", level.startInvulnerableTime);	
			}
		}
	}
}

below_ground_death()
{
	while (1)
	{
		wait 0.2;
		
		players = getPlayers();
		
		for (i = 0; i < players.size; i++)
		{
			if (players[i].origin[2] < -11)
			{
				setsaveddvar("player_deathInvulnerableTime", 0);
				players[i] DoDamage( players[i].health + 1000, players[i].origin, undefined, undefined, "riflebullet" );
				setsaveddvar("player_deathInvulnerableTime", level.startInvulnerableTime);	
			}
		}
	}
}


out_of_bounds_watcher()
{
	self endon ("disconnect");
	
	outside_of_map = [];
	
	outside_of_map[0]["min"] = (361, 591, -11);
	outside_of_map[0]["max"] = (1068, 1031, 235);
	
	outside_of_map[1]["min"] = (-288, 591, -11);
	outside_of_map[1]["max"] = (361, 1160, 235);
	
	outside_of_map[2]["min"] = (-272, 120, -11);
	outside_of_map[2]["max"] = (370, 591, 235);

	outside_of_map[3]["min"] = (-272, -912, -11);
	outside_of_map[3]["max"] = (273, 120, 235);
		
	while (1)
	{	
		array_check = outside_of_map.size;
		
		kill_player = true;
		for(i = 0; i < array_check; i++)
		{
			if (self is_within_volume(	outside_of_map[i]["min"][0], outside_of_map[i]["max"][0], 
										outside_of_map[i]["min"][1], outside_of_map[i]["max"][1],
										outside_of_map[i]["min"][2], outside_of_map[i]["max"][2]))
			{
				kill_player = false;

			} 			
		}		
		
		if (kill_player)
		{
			setsaveddvar("player_deathInvulnerableTime", 0);
			self DoDamage( self.health + 1000, self.origin, undefined, undefined, "riflebullet" );
			setsaveddvar("player_deathInvulnerableTime", level.startInvulnerableTime);	
		}
		
		wait 0.2;
	}	
}

prototype_precache_func()
{
	precacheshader( "nazi_intro" ); 
	precacheshader( "zombie_intro" );	
}

// Handles the intro screen
prototype_custom_intro_screen( string1, string2, string3, string4, string5 )
{
	flag_wait( "all_players_connected" );

	wait( 1 );

	//TUEY Set music state to Splash Screencompass
	setmusicstate( "SPLASH_SCREEN" );
	wait (0.2);
	//TUEY Set music state to WAVE_1
	setmusicstate("WAVE_1");
}

init_fx()
{
	level._effect["wood_chunk_destory"]	 	= loadfx( "impacts/large_woodhit" );

	level._effect["edge_fog"]			 	= LoadFx( "env/smoke/fx_fog_zombie_amb" ); 
	level._effect["chest_light"]		 	= LoadFx( "env/light/fx_ray_sun_sm_short" ); 

	level._effect["eye_glow"]			 	= LoadFx( "misc/fx_zombie_eye_single" ); 
	
	level._effect["zombie_grain"]			= LoadFx( "misc/fx_zombie_grain_cloud" );
	
	level._effect["headshot"] 				= LoadFX( "impacts/flesh_hit_head_fatal_lg_exit" );
	level._effect["headshot_nochunks"] 		= LoadFX( "misc/fx_zombie_bloodsplat" );
	level._effect["bloodspurt"] 			= LoadFX( "misc/fx_zombie_bloodspurt" );
	
	// Flamethrower
	level._effect["character_fire_pain_sm"]              		= loadfx( "env/fire/fx_fire_player_sm_1sec" );
	level._effect["character_fire_death_sm"]             		= loadfx( "env/fire/fx_fire_player_md" );
	level._effect["character_fire_death_torso"] 				= loadfx( "env/fire/fx_fire_player_torso" );
}

#using_animtree( "generic_human" ); 

init_anims()
{
	// deaths
	level.scr_anim["zombie"]["death1"] 	= %ai_zombie_death_v1; 
	level.scr_anim["zombie"]["death2"] 	= %ai_zombie_death_v2; 
	level.scr_anim["zombie"]["death3"] 	= %ai_zombie_crawl_death_v1; 
	level.scr_anim["zombie"]["death4"] 	= %ai_zombie_crawl_death_v2; 

	// run cycles
	level.scr_anim["zombie"]["walk1"] 	= %ai_zombie_walk_v1; 	
	level.scr_anim["zombie"]["walk2"] 	= %ai_zombie_walk_v2; 
	level.scr_anim["zombie"]["walk3"] 	= %ai_zombie_walk_v3; 
	level.scr_anim["zombie"]["walk4"] 	= %ai_zombie_walk_v4; 
	level.scr_anim["zombie"]["run1"] 	= %ai_zombie_walk_fast_v1; 
	level.scr_anim["zombie"]["run2"] 	= %ai_zombie_walk_fast_v2; 
	level.scr_anim["zombie"]["run3"] 	= %ai_zombie_walk_fast_v3; 
	level.scr_anim["zombie"]["sprint1"] = %ai_zombie_sprint_v1; 
	level.scr_anim["zombie"]["sprint2"] = %ai_zombie_sprint_v2; 	
	
	// run cycles in prone
	level.scr_anim["zombie"]["crawl1"] 	= %ai_zombie_crawl; 
	level.scr_anim["zombie"]["crawl2"] 	= %ai_zombie_crawl_v1; 
	level.scr_anim["zombie"]["crawl3"] 	= %ai_zombie_crawl_sprint; 
		
	level._zombie_melee = []; 
	level._zombie_melee[0] 				= %ai_zombie_attack_forward_v1; 
	level._zombie_melee[1] 				= %ai_zombie_attack_forward_v2; 
	level._zombie_melee[2] 				= %ai_zombie_attack_v1; 
	level._zombie_melee[3] 				= %ai_zombie_attack_v2; 

	// melee in crawl
	level._zombie_melee_crawl[0] 		= %ai_zombie_attack_crawl; 
	level._zombie_melee_crawl[1] 		= %ai_zombie_attack_crawl_lunge; 
}

prototype_init_zombie_leaderboard_data()
{
	// Initializing Leaderboard Stat Variables
	level.zombieLeaderboardStatVariable["nazi_zombie_prototype"]["highestwave"] = "nz_prototype_highestwave";
	level.zombieLeaderboardStatVariable["nazi_zombie_prototype"]["timeinwave"] = "nz_prototype_timeinwave";
	level.zombieLeaderboardStatVariable["nazi_zombie_prototype"]["totalpoints"] = "nz_prototype_totalpoints";
	// Initializing Leaderboard Number
	level.zombieLeaderboardNumber["nazi_zombie_prototype"]["waves"] = 13;
	level.zombieLeaderboardNumber["nazi_zombie_prototype"]["points"] = 14;
}