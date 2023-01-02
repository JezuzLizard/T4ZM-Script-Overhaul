#include common_scripts\utility; 
#include maps\_utility;
#include maps\so\zm_common\_zm_utility; 
#include maps\so\zm_common\_zm_zonemgr; 
#include maps\nazi_zombie_factory_teleporter;
#include maps\_music;


main()
{
	// This has to be first for CreateFX -- Dale
	maps\nazi_zombie_factory_fx::main();
	
	// used to modify the percentages of pulls of ray gun and tesla gun in magic box
	level.pulls_since_last_ray_gun = 0;
	level.pulls_since_last_tesla_gun = 0;
	level.player_drops_tesla_gun = false;

	level.dogs_enabled = true;		//PI ESM - added for dog support
//	level.crawlers_enabled = true;		//MM - added for crawler support
	level.mixed_rounds_enabled = true;	// MM added support for mixed crawlers and dogs
	level.burning_zombies = [];		//JV max number of zombies that can be on fire
	level.traps = [];				//Contains all traps currently in this map
	level.zombie_rise_spawners = [];	// Zombie riser control
	level.max_barrier_search_dist_override = 400;

	level.door_dialog_function = maps\so\zm_common\_zm::play_door_dialog;
	level.achievement_notify_func = maps\so\zm_common\_zm_utility::achievement_notify;
	level.dog_spawn_func = maps\so\zm_common\_zm_ai_dogs::dog_spawn_factory_logic;

	// Animations needed for door initialization
	script_anims_init();

	level thread maps\_callbacksetup::SetupCallbacks();
	
	level.zombie_anim_override = maps\nazi_zombie_factory::anim_override_func;
	

	SetDvar( "perk_altMeleeDamage", 1000 ); // adjusts how much melee damage a player with the perk will do, needs only be set once

	precachestring(&"ZOMBIE_FLAMES_UNAVAILABLE");
	precachestring(&"ZOMBIE_ELECTRIC_SWITCH");

	precachestring(&"ZOMBIE_POWER_UP_TPAD");
	precachestring(&"ZOMBIE_TELEPORT_TO_CORE");
	precachestring(&"ZOMBIE_LINK_TPAD");
	precachestring(&"ZOMBIE_LINK_ACTIVE");
	precachestring(&"ZOMBIE_INACTIVE_TPAD");
	precachestring(&"ZOMBIE_START_TPAD");

	precacheshellshock("electrocution");
	precachemodel("zombie_zapper_cagelight_red");
	precachemodel("zombie_zapper_cagelight_green");
	precacheModel("lights_indlight_on" );
	precacheModel("lights_milit_lamp_single_int_on" );
	precacheModel("lights_tinhatlamp_on" );
	precacheModel("lights_berlin_subway_hat_0" );
	precacheModel("lights_berlin_subway_hat_50" );
	precacheModel("lights_berlin_subway_hat_100" );
	precachemodel("collision_geo_32x32x128");

	precachestring(&"ZOMBIE_BETTY_ALREADY_PURCHASED");
	precachestring(&"ZOMBIE_BETTY_HOWTO");
	
	if ( isDefined( level.zm_custom_map_include_weapons ) )
	{
		level [[ level.zm_custom_map_include_weapons ]]();
	}
	else 
	{
		include_weapons();
	}
	level.use_zombie_heroes = true;
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
		level.zm_custom_map_leaderboard_init = ::factory_init_zombie_leaderboard_data;
	}
	if ( !isDefined( level.zm_custom_map_weapon_add_func ) )
	{
		level.zm_custom_map_weapon_add_func = ::factory_add_weapons;
	}
	level.init_zombie_spawner_name = "receiver_zone_spawners";
	maps\so\zm_common\perks\_zm_perk_doubletap::enable_doubletap_perk_for_level();
	maps\so\zm_common\perks\_zm_perk_juggernog::enable_juggernog_perk_for_level();
	maps\so\zm_common\perks\_zm_perk_revive::enable_revive_perk_for_level();
	maps\so\zm_common\perks\_zm_perk_sleight::enable_sleight_perk_for_level();
	maps\so\zm_common\perks\_zm_packapunch::enable_packapunch_for_level();
	if ( isDefined( level.zm_custom_map_perk_machines_func ) )
	{
		level [[ level.zm_custom_map_perk_machines_func ]]();
	}
	maps\so\zm_common\powerups\_zm_powerup_double_points::enable_double_points_powerup_for_level();
	maps\so\zm_common\powerups\_zm_powerup_full_ammo::enable_full_ammo_powerup_for_level();
	maps\so\zm_common\powerups\_zm_powerup_insta_kill::enable_insta_kill_powerup_for_level();
	maps\so\zm_common\powerups\_zm_powerup_nuke::enable_nuke_powerup_for_level();
	maps\so\zm_common\powerups\_zm_powerup_carpenter::enable_carpenter_powerup_for_level();
	maps\so\zm_common\_zm_spawner::init();
	maps\so\zm_common\_zm::init_zm();
	maps\so\zm_common\_zm_ai_dogs::init();
	maps\_zombiemode_radio::init();	
	maps\so\zm_common\_zm_weap_tesla_gun::init();
	maps\_zombiemode_bowie::bowie_init();
	maps\so\zm_common\_zm_cymbal_monkey::init();
	maps\_zombiemode_betty::init();
	maps\_zombiemode_timer::init();
	maps\_zombiemode_auto_turret::init();
	init_sounds();
	init_achievement();
	//ESM - activate the initial exterior goals
	//level.exterior_goals = getstructarray("exterior_goal","targetname");		
	
	//for(i=0;i<level.exterior_goals.size;i++)
	//{
	//	level.exterior_goals[i].is_active = 1;
	//}
	//ESM - two electrice switches, everything inactive until the right one gets used
//	level thread wuen_electric_switch();
//	level thread warehouse_electric_switch();
//	level thread watch_bridge_halves();
	level thread power_electric_switch();
	
	level thread magic_box_init();

	// This controls when zones become active and start monitoring players so zombies can spawn
//	level thread setup_door_waits();

	// If you want to modify/add to the weapons table, please copy over the so\zm_common\_zm_weapons init_weapons() and paste it here.
	// I recommend putting it in it's own function...
	// If not a MOD, you may need to provide new localized strings to reflect the proper cost.	

	
	//ESM - time for electrocuting
	thread init_elec_trap_trigs();

	level.zone_manager_init_func = ::factory_zone_init;
	level thread maps\so\zm_common\_zm_zonemgr::manage_zones( "receiver_zone" );

	teleporter_init();
	
	//AUDIO: Initiating Killstreak Dialog and Zombie Behind Vocals
	players = getPlayers(); 
	
	for( i = 0; i < players.size; i++ )
	{
		players[i] thread player_killstreak_timer();
		players[i] thread player_zombie_awareness();
	}
	
	players[randomint(players.size)] thread level_start_vox(); //Plays a "Power's Out" Message from a random player at start

	level thread intro_screen();

	level thread jump_from_bridge();
	level lock_additional_player_spawner();

	level thread bridge_init();
	
	//AUDIO EASTER EGGS
	level thread phono_egg_init( "phono_one", "phono_one_origin" );
	level thread phono_egg_init( "phono_two", "phono_two_origin" );
	level thread phono_egg_init( "phono_three", "phono_three_origin" );
	level thread meteor_egg( "meteor_one" );
	level thread meteor_egg( "meteor_two" );
	level thread meteor_egg( "meteor_three" );
	level thread meteor_egg_play();
	level thread radio_egg_init( "radio_one", "radio_one_origin" );
	level thread radio_egg_init( "radio_two", "radio_two_origin" );
	level thread radio_egg_init( "radio_three", "radio_three_origin" );
	level thread radio_egg_init( "radio_four", "radio_four_origin" );
	level thread radio_egg_init( "radio_five", "radio_five_origin" );
	//level thread radio_egg_hanging_init( "radio_five", "radio_five_origin" );
	level.monk_scream_trig = getent( "monk_scream_trig", "targetname" );
	level thread play_giant_mythos_lines();
	level thread play_level_easteregg_vox( "vox_corkboard_1" );
	level thread play_level_easteregg_vox( "vox_corkboard_2" );
	level thread play_level_easteregg_vox( "vox_corkboard_3" );
	level thread play_level_easteregg_vox( "vox_teddy" );
	level thread play_level_easteregg_vox( "vox_fieldop" );
	level thread play_level_easteregg_vox( "vox_telemap" );
	level thread play_level_easteregg_vox( "vox_maxis" );
	level thread play_level_easteregg_vox( "vox_illumi_1" );
	level thread play_level_easteregg_vox( "vox_illumi_2" );

	// Special level specific settings
	set_zombie_var( "zombie_powerup_drop_max_per_round", 3 );	// lower this to make drop happen more often

	// Check under the machines for change
	trigs = GetEntArray( "audio_bump_trigger", "targetname" );
	for ( i=0; i<trigs.size; i++ )
	{
		if ( IsDefined(trigs[i].script_sound) && trigs[i].script_sound == "perks_rattle" )
		{
			trigs[i] thread check_for_change();
		}
	}

	trigs = GetEntArray( "trig_ee", "targetname" );
	array_thread( trigs, ::extra_events);

	level thread flytrap();
	level thread hanging_dead_guy( "hanging_dead_guy" );
	
	spawncollision("collision_geo_32x32x128","collider",(-5, 543, 112), (0, 348.6, 0));
}

init_achievement()
{
	include_achievement( "achievement_shiny" );
	include_achievement( "achievement_monkey_see" );
	include_achievement( "achievement_frequent_flyer" );
	include_achievement( "achievement_this_is_a_knife" );
	include_achievement( "achievement_martian_weapon" );
	include_achievement( "achievement_double_whammy" );
	include_achievement( "achievement_perkaholic" );
	include_achievement( "achievement_secret_weapon", "zombie_kar98k_upgraded" );
	include_achievement( "achievement_no_more_door" );
	include_achievement( "achievement_back_to_future" );

}

//
//	Create the zone information for zombie spawning
//
factory_zone_init()
{
	// Note this setup is based on a flag-centric view of setting up your zones.  A brief
	//	zone-centric example exists below in comments

	// Outside East Door
	add_adjacent_zone( "receiver_zone",		"outside_east_zone",	"enter_outside_east" );

	// Outside West Door
	add_adjacent_zone( "receiver_zone",		"outside_west_zone",	"enter_outside_west" );

	// Wnuen building ground floor
	add_adjacent_zone( "wnuen_zone",		"outside_east_zone",	"enter_wnuen_building" );

	// Wnuen stairway
	add_adjacent_zone( "wnuen_zone",		"wnuen_bridge_zone",	"enter_wnuen_loading_dock" );

	// Warehouse bottom 
	add_adjacent_zone( "warehouse_bottom_zone", "outside_west_zone",	"enter_warehouse_building" );

	// Warehosue top
	add_adjacent_zone( "warehouse_bottom_zone", "warehouse_top_zone",	"enter_warehouse_second_floor" );
	add_adjacent_zone( "warehouse_top_zone",	"bridge_zone",			"enter_warehouse_second_floor" );

	// TP East
	add_adjacent_zone( "tp_east_zone",			"wnuen_zone",			"enter_tp_east" );
	flag_array[0] = "enter_tp_east";
	flag_array[1] = "enter_wnuen_building";
	add_adjacent_zone( "tp_east_zone",			"outside_east_zone",	flag_array,			true );

	// TP South
	add_adjacent_zone( "tp_south_zone",			"outside_south_zone",	"enter_tp_south" );

	// TP West
	add_adjacent_zone( "tp_west_zone",			"warehouse_top_zone",	"enter_tp_west" );
	flag_array[0] = "enter_tp_west";
	flag_array[1] = "enter_warehouse_second_floor";
	add_adjacent_zone( "tp_west_zone",			"warehouse_bottom_zone", flag_array,		true );

	/*
	// A ZONE-centric example of initialization
	//	It's the same calls, sorted by zone, and made one-way to show connections on a per/zone basis

	// Receiver zone
	add_adjacent_zone( "receiver_zone",		"outside_east_zone",	"enter_outside_east",		true );
	add_adjacent_zone( "receiver_zone",		"outside_west_zone",	"enter_outside_west",		true );

	// Outside East Zone
	add_adjacent_zone( "outside_east_zone",	"receiver_zone",		"enter_outside_east",		true );
	add_adjacent_zone( "outside_east_zone",	"wnuen_zone",			"enter_wnuen_building",		true );

	// Wnuen Zone
	add_adjacent_zone( "wnuen_zone",		"tp_east_zone",			"enter_tp_east",			true );
	add_adjacent_zone( "wnuen_zone",		"wnuen_bridge_zone",	"enter_wnuen_loading_dock",	true );

	// TP East
	add_adjacent_zone( "tp_east_zone",		"wnuen_zone",			"enter_tp_east",			true );
	flag_array[0] = "enter_tp_east";
	flag_array[1] = "enter_wnuen_building";
	add_adjacent_zone( "tp_east_zone",		"outside_east",			flag_array,					true );
	*/
}


//
//	Intro Chyron!
intro_screen()
{

	flag_wait( "all_players_connected" );
	wait(2);
	level.intro_hud = [];
	for(i = 0;  i < 3; i++)
	{
		level.intro_hud[i] = newHudElem();
		level.intro_hud[i].x = 0;
		level.intro_hud[i].y = 0;
		level.intro_hud[i].alignX = "left";
		level.intro_hud[i].alignY = "bottom";
		level.intro_hud[i].horzAlign = "left";
		level.intro_hud[i].vertAlign = "bottom";
		level.intro_hud[i].foreground = true;

		if ( level.splitscreen && !level.hidef )
		{
			level.intro_hud[i].fontScale = 2.75;
		}
		else
		{
			level.intro_hud[i].fontScale = 1.75;
		}
		level.intro_hud[i].alpha = 0.0;
		level.intro_hud[i].color = (1, 1, 1);
		level.intro_hud[i].inuse = false;
	}
	level.intro_hud[0].y = -110;
	level.intro_hud[1].y = -90;
	level.intro_hud[2].y = -70;


	level.intro_hud[0] settext(&"ZOMBIE_INTRO_FACTORY_LEVEL_PLACE");
	level.intro_hud[1] settext("");
	level.intro_hud[2] settext("");
//	level.intro_hud[1] settext(&"ZOMBIE_INTRO_FACTORY_LEVEL_TIME");
//	level.intro_hud[2] settext(&"ZOMBIE_INTRO_FACTORY_LEVEL_DATE");

	for(i = 0 ; i < 3; i++)
	{
		level.intro_hud[i] FadeOverTime( 3.5 ); 
		level.intro_hud[i].alpha = 1;
		wait(1.5);
	}
	wait(1.5);
	for(i = 0 ; i < 3; i++)
	{
		level.intro_hud[i] FadeOverTime( 3.5 ); 
		level.intro_hud[i].alpha = 0;
		wait(1.5);
	}	
	//wait(1.5);
	for(i = 0 ; i < 3; i++)
	{
		level.intro_hud[i] destroy();
	}
}


//-------------------------------------------------------------------
//	Animation functions - need to be specified separately in order to use different animtrees
//-------------------------------------------------------------------
#using_animtree( "zombie_factory" );
script_anims_init()
{
	level.scr_anim[ "half_gate" ]			= %o_zombie_lattice_gate_half;
	level.scr_anim[ "full_gate" ]			= %o_zombie_lattice_gate_full;
	level.scr_anim[ "difference_engine" ]	= %o_zombie_difference_engine_ani;

	level.blocker_anim_func = ::factory_playanim;
}

factory_playanim( animname )
{
	self UseAnimTree(#animtree);
	self animscripted("door_anim", self.origin, self.angles, level.scr_anim[animname] );
}


#using_animtree( "generic_human" );
anim_override_func()
{
		level._zombie_melee[0] 				= %ai_zombie_attack_forward_v1; 
		level._zombie_melee[1] 				= %ai_zombie_attack_forward_v2; 
		level._zombie_melee[2] 				= %ai_zombie_attack_v1; 
		level._zombie_melee[3] 				= %ai_zombie_attack_v2;	
		level._zombie_melee[4]				= %ai_zombie_attack_v1;
		level._zombie_melee[5]				= %ai_zombie_attack_v4;
		level._zombie_melee[6]				= %ai_zombie_attack_v6;	

		level._zombie_run_melee[0]				=	%ai_zombie_run_attack_v1;
		level._zombie_run_melee[1]				=	%ai_zombie_run_attack_v2;
		level._zombie_run_melee[2]				=	%ai_zombie_run_attack_v3;

		level.scr_anim["zombie"]["run4"] 	= %ai_zombie_run_v2;
		level.scr_anim["zombie"]["run5"] 	= %ai_zombie_run_v4;
		level.scr_anim["zombie"]["run6"] 	= %ai_zombie_run_v3;

		level.scr_anim["zombie"]["walk5"] 	= %ai_zombie_walk_v6;
		level.scr_anim["zombie"]["walk6"] 	= %ai_zombie_walk_v7;
		level.scr_anim["zombie"]["walk7"] 	= %ai_zombie_walk_v8;
		level.scr_anim["zombie"]["walk8"] 	= %ai_zombie_walk_v9;
}

lock_additional_player_spawner()
{
	
	spawn_points = getstructarray("player_respawn_point", "targetname");
	for( i = 0; i < spawn_points.size; i++ )
	{

			spawn_points[i].locked = true;

	}
}

//-------------------------------------------------------------------------------
// handles lowering the bridge when power is turned on
//-------------------------------------------------------------------------------
bridge_init()
{
	flag_init( "bridge_down" );
	// raise bridge
	wnuen_bridge = getent( "wnuen_bridge", "targetname" );
	wnuen_bridge_coils = GetEntArray( "wnuen_bridge_coils", "targetname" );
	for ( i=0; i<wnuen_bridge_coils.size; i++ )
	{
		wnuen_bridge_coils[i] LinkTo( wnuen_bridge );
	}
	wnuen_bridge rotatepitch( 90, 1, .5, .5 );

	warehouse_bridge = getent( "warehouse_bridge", "targetname" );
	warehouse_bridge_coils = GetEntArray( "warehouse_bridge_coils", "targetname" );
	for ( i=0; i<warehouse_bridge_coils.size; i++ )
	{
		warehouse_bridge_coils[i] LinkTo( warehouse_bridge );
	}
	warehouse_bridge rotatepitch( -90, 1, .5, .5 );
	
	bridge_audio = getstruct( "bridge_audio", "targetname" );

	// wait for power
	flag_wait( "electricity_on" );

	// lower bridge
	wnuen_bridge rotatepitch( -90, 4, .5, 1.5 );
	warehouse_bridge rotatepitch( 90, 4, .5, 1.5 );
	
	if(isdefined( bridge_audio ) )
		playsoundatposition( "bridge_lower", bridge_audio.origin );

	wnuen_bridge connectpaths();
	warehouse_bridge connectpaths();

	exploder( 500 );

	// wait until the bridges are down.
	wnuen_bridge waittill( "rotatedone" );
	
	flag_set( "bridge_down" );
	if(isdefined( bridge_audio ) )
		playsoundatposition( "bridge_hit", bridge_audio.origin );

	wnuen_bridge_clip = getent( "wnuen_bridge_clip", "targetname" );
	wnuen_bridge_clip delete();

	warehouse_bridge_clip = getent( "warehouse_bridge_clip", "targetname" );
	warehouse_bridge_clip delete();

	maps\so\zm_common\_zm_zonemgr::connect_zones( "wnuen_bridge_zone", "bridge_zone" );
	maps\so\zm_common\_zm_zonemgr::connect_zones( "warehouse_top_zone", "bridge_zone" );
}


//
//
jump_from_bridge()
{
	trig = GetEnt( "trig_outside_south_zone", "targetname" );
	trig waittill( "trigger" );

	maps\so\zm_common\_zm_zonemgr::connect_zones( "outside_south_zone", "bridge_zone", true );
	maps\so\zm_common\_zm_zonemgr::connect_zones( "outside_south_zone", "wnuen_bridge_zone", true );
}


init_sounds()
{
	maps\so\zm_common\_zm_utility::add_sound( "break_stone", "break_stone" );
	maps\so\zm_common\_zm_utility::add_sound( "gate_door",	"open_door" );
	maps\so\zm_common\_zm_utility::add_sound( "heavy_door",	"open_door" );
}


factory_add_weapons()
{
	// Zombify
	PrecacheItem( "zombie_melee" );


	// Pistols
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "colt", 									&"ZOMBIE_WEAPON_COLT_50", 					50,		"vox_crappy",	8 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "colt_dirty_harry", 						&"ZOMBIE_WEAPON_COLT_DH_100", 				100,	"vox_357",		5 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "nambu", 								&"ZOMBIE_WEAPON_NAMBU_50", 					50, 	"vox_crappy",	8 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "sw_357", 								&"ZOMBIE_WEAPON_SW357_100", 				100, 	"vox_357",		5 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_sw_357", 						&"ZOMBIE_WEAPON_SW357_100", 				100, 	"vox_357",		5 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_sw_357_upgraded", 				&"ZOMBIE_WEAPON_SW357_100", 				100, 	"vox_357",		5 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "tokarev", 								&"ZOMBIE_WEAPON_TOKAREV_50", 				50, 	"vox_crappy",	8 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "walther", 								&"ZOMBIE_WEAPON_WALTHER_50", 				50, 	"vox_crappy",	8 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_colt", 							&"ZOMBIE_WEAPON_ZOMBIECOLT_25", 			25, 	"vox_crappy",	8 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_colt_upgraded", 					&"ZOMBIE_WEAPON_ZOMBIECOLT_25", 			25, 	"vox_crappy",	8 );

	// Bolt Action                                      		
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "kar98k", 								&"ZOMBIE_WEAPON_KAR98K_200", 				200,	"",				0);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_kar98k", 						&"ZOMBIE_WEAPON_KAR98K_200", 				200,	"",				0);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_kar98k_upgraded", 				&"ZOMBIE_WEAPON_KAR98K_200", 				200,	"",				0);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "kar98k_bayonet", 						&"ZOMBIE_WEAPON_KAR98K_B_200", 				200,	"",				0);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mosin_rifle", 							&"ZOMBIE_WEAPON_MOSIN_200", 				200,	"",				0); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mosin_rifle_bayonet", 					&"ZOMBIE_WEAPON_MOSIN_B_200", 				200,	"",				0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "springfield", 							&"ZOMBIE_WEAPON_SPRINGFIELD_200", 			200,	"",				0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_springfield", 					&"ZOMBIE_WEAPON_SPRINGFIELD_200", 			200,	"",				0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "springfield_bayonet", 					&"ZOMBIE_WEAPON_SPRINGFIELD_B_200", 		200,	"",				0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_type99_rifle", 					&"ZOMBIE_WEAPON_TYPE99_200", 				200,	"",				0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_type99_rifle_upgraded", 			&"ZOMBIE_WEAPON_TYPE99_200", 				200,	"",				0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type99_rifle_bayonet", 					&"ZOMBIE_WEAPON_TYPE99_B_200", 				200,	"",				0 );

	// Semi Auto                                        		
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_gewehr43", 						&"ZOMBIE_WEAPON_GEWEHR43_600", 				600,	"" ,			0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_gewehr43_upgraded", 				&"ZOMBIE_WEAPON_GEWEHR43_600", 				600,	"" ,			0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_m1carbine", 						&"ZOMBIE_WEAPON_M1CARBINE_600",				600,	"" ,			0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_m1carbine_upgraded", 			&"ZOMBIE_WEAPON_M1CARBINE_600",				600,	"" ,			0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "m1carbine_bayonet", 					&"ZOMBIE_WEAPON_M1CARBINE_B_600", 			600,	"" ,			0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_m1garand", 						&"ZOMBIE_WEAPON_M1GARAND_600", 				600,	"" ,			0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_m1garand_upgraded", 				&"ZOMBIE_WEAPON_M1GARAND_600", 				600,	"" ,			0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "m1garand_bayonet", 						&"ZOMBIE_WEAPON_M1GARAND_B_600", 			600,	"" ,			0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "svt40", 								&"ZOMBIE_WEAPON_SVT40_600", 				600,	"" ,			0 );

	// Grenades                                         		
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "fraggrenade", 							&"ZOMBIE_WEAPON_FRAGGRENADE_250", 			250,	"" ,			0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "molotov", 								&"ZOMBIE_WEAPON_MOLOTOV_200", 				200,	"vox_crappy",	8 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "molotov_zombie", 						&"ZOMBIE_WEAPON_MOLOTOV_200", 				200,	"vox_crappy",	8 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "stick_grenade", 						&"ZOMBIE_WEAPON_STICKGRENADE_250", 			250,	"" ,			0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "stielhandgranate", 						&"ZOMBIE_WEAPON_STIELHANDGRANATE_250", 		250,	"" ,			0, 250 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type97_frag", 							&"ZOMBIE_WEAPON_TYPE97FRAG_250", 			250,	"" ,			0 );

	// Scoped
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "kar98k_scoped_zombie", 					&"ZOMBIE_WEAPON_KAR98K_S_750", 				750,	"vox_ppsh",		5);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "kar98k_scoped_bayonet_zombie", 			&"ZOMBIE_WEAPON_KAR98K_S_B_750", 			750,	"vox_ppsh",		5);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mosin_rifle_scoped_zombie", 			&"ZOMBIE_WEAPON_MOSIN_S_750", 				750,	"vox_ppsh",		5);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mosin_rifle_scoped_bayonet_zombie", 	&"ZOMBIE_WEAPON_MOSIN_S_B_750", 			750,	"vox_ppsh",		5);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "ptrs41_zombie", 						&"ZOMBIE_WEAPON_PTRS41_750", 				750,	"vox_ppsh",		5);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "ptrs41_zombie_upgraded", 				&"ZOMBIE_WEAPON_PTRS41_750", 				750,	"vox_ppsh",		5);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "springfield_scoped_zombie", 			&"ZOMBIE_WEAPON_SPRINGFIELD_S_750", 		750,	"vox_ppsh",		5);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "springfield_scoped_bayonet_zombie", 	&"ZOMBIE_WEAPON_SPRINGFIELD_S_B_750", 		750,	"vox_ppsh",		5);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type99_rifle_scoped_zombie", 			&"ZOMBIE_WEAPON_TYPE99_S_750", 				750,	"vox_ppsh",		5);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type99_rifle_scoped_bayonet_zombie", 	&"ZOMBIE_WEAPON_TYPE99_S_B_750", 			750,	"vox_ppsh",		5);

	// Full Auto                                                                                	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_mp40", 							&"ZOMBIE_WEAPON_MP40_1000", 				1000,	"vox_mp40",		2 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_mp40_upgraded", 					&"ZOMBIE_WEAPON_MP40_1000", 				1000,	"vox_mp40",		2 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_ppsh", 							&"ZOMBIE_WEAPON_PPSH_2000", 				2000,	"vox_ppsh",		5 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_ppsh_upgraded", 					&"ZOMBIE_WEAPON_PPSH_2000", 				2000,	"vox_ppsh",		5 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_stg44", 							&"ZOMBIE_WEAPON_STG44_1200", 				1200,	"vox_mg",		9 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_stg44_upgraded", 				&"ZOMBIE_WEAPON_STG44_1200", 				1200,	"vox_mg",		9 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_thompson", 						&"ZOMBIE_WEAPON_THOMPSON_1200", 			1200,	"",				0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_thompson_upgraded", 				&"ZOMBIE_WEAPON_THOMPSON_1200", 			1200,	"",				0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_type100_smg", 					&"ZOMBIE_WEAPON_TYPE100_1000", 				1000,	"",				0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_type100_smg_upgraded", 			&"ZOMBIE_WEAPON_TYPE100_1000", 				1000,	"",				0 );

	// Shotguns                                         	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_doublebarrel", 					&"ZOMBIE_WEAPON_DOUBLEBARREL_1200", 		1200,	"vox_shotgun", 6);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_doublebarrel_upgraded", 			&"ZOMBIE_WEAPON_DOUBLEBARREL_1200", 		1200,	"vox_shotgun", 6);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_doublebarrel_sawed", 			&"ZOMBIE_WEAPON_DOUBLEBARREL_SAWED_1200", 	1200,	"vox_shotgun", 6);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_doublebarrel_sawed_upgraded",	&"ZOMBIE_WEAPON_DOUBLEBARREL_SAWED_1200", 	1200,	"vox_shotgun", 6);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_shotgun", 						&"ZOMBIE_WEAPON_SHOTGUN_1500", 				1500,	"vox_shotgun", 6);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_shotgun_upgraded", 				&"ZOMBIE_WEAPON_SHOTGUN_1500", 				1500,	"vox_shotgun", 6);

	// Heavy Machineguns                                	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_30cal", 							&"ZOMBIE_WEAPON_30CAL_3000", 				3000,	"vox_mg",		9 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_30cal_upgraded", 				&"ZOMBIE_WEAPON_30CAL_3000", 				3000,	"vox_mg",		9 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_bar", 							&"ZOMBIE_WEAPON_BAR_1800", 					1800,	"vox_bar",		5 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_bar_upgraded", 					&"ZOMBIE_WEAPON_BAR_1800", 					1800,	"vox_bar",		5 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "dp28", 									&"ZOMBIE_WEAPON_DP28_2250", 				2250,	"vox_mg" ,		9 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_fg42", 							&"ZOMBIE_WEAPON_FG42_1500", 				1500,	"vox_mg" ,		9 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_fg42_upgraded", 					&"ZOMBIE_WEAPON_FG42_1500", 				1500,	"vox_mg" ,		9 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "fg42_scoped", 							&"ZOMBIE_WEAPON_FG42_S_1500", 				1500,	"vox_mg" ,		9 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_mg42", 							&"ZOMBIE_WEAPON_MG42_3000", 				3000,	"vox_mg" ,		9 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_mg42_upgraded", 					&"ZOMBIE_WEAPON_MG42_3000", 				3000,	"vox_mg" ,		9 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type99_lmg", 							&"ZOMBIE_WEAPON_TYPE99_LMG_1750", 			1750,	"vox_mg" ,		9 ); 

	// Grenade Launcher                                 	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "m1garand_gl_zombie", 					&"ZOMBIE_WEAPON_M1GARAND_GL_1500", 			1500,	"",				0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "m1garand_gl_zombie_upgraded", 			&"ZOMBIE_WEAPON_M1GARAND_GL_1500", 			1500,	"",				0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mosin_launcher_zombie", 				&"ZOMBIE_WEAPON_MOSIN_GL_1200",				1200,	"",				0 );

	// Bipods                               				
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "30cal_bipod", 							&"ZOMBIE_WEAPON_30CAL_BIPOD_3500", 			3500,	"vox_mg",		5 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "bar_bipod", 							&"ZOMBIE_WEAPON_BAR_BIPOD_2500", 			2500,	"vox_bar",		5 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "dp28_bipod", 							&"ZOMBIE_WEAPON_DP28_BIPOD_2500", 			2500,	"vox_mg",		5 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "fg42_bipod", 							&"ZOMBIE_WEAPON_FG42_BIPOD_2000", 			2000,	"vox_mg",		5 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mg42_bipod", 							&"ZOMBIE_WEAPON_MG42_BIPOD_3250", 			3250,	"vox_mg",		5 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type99_lmg_bipod", 						&"ZOMBIE_WEAPON_TYPE99_LMG_BIPOD_2250", 	2250,	"vox_mg",		5 ); 

	// Rocket Launchers
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "bazooka", 								&"ZOMBIE_WEAPON_BAZOOKA_2000", 				2000,	"",				0 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "panzerschrek_zombie", 					&"ZOMBIE_WEAPON_PANZERSCHREK_2000", 		2000,	"vox_panzer",	5 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "panzerschrek_zombie_upgraded", 			&"ZOMBIE_WEAPON_PANZERSCHREK_2000", 		2000,	"vox_panzer",	5 ); 

	// Flamethrower                                     	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "m2_flamethrower_zombie", 				&"ZOMBIE_WEAPON_M2_FLAMETHROWER_3000", 		3000,	"vox_flame",	7);	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "m2_flamethrower_zombie_upgraded", 		&"ZOMBIE_WEAPON_M2_FLAMETHROWER_3000", 		3000,	"vox_flame",	7);	

	// Special                                          	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mine_bouncing_betty",					&"ZOMBIE_WEAPON_SATCHEL_2000",				2000,	"" );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mortar_round", 							&"ZOMBIE_WEAPON_MORTARROUND_2000", 			2000,	"" );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "satchel_charge", 						&"ZOMBIE_WEAPON_SATCHEL_2000", 				2000,	"vox_monkey",	3 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_cymbal_monkey",					&"ZOMBIE_WEAPON_SATCHEL_2000", 				2000,	"vox_monkey",	3 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "ray_gun", 								&"ZOMBIE_WEAPON_RAYGUN_10000", 				10000,	"vox_raygun",	6 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "ray_gun_upgraded", 						&"ZOMBIE_WEAPON_RAYGUN_10000", 				10000,	"vox_raygun",	6 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "tesla_gun",								&"ZOMBIE_BUY_TESLA", 						10,		"vox_tesla",	5 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "tesla_gun_upgraded",					&"ZOMBIE_BUY_TESLA", 						10,		"vox_tesla",	5 );

	if(level.script != "nazi_zombie_prototype")
	{
		Precachemodel("zombie_teddybear");
	}
	// ONLY 1 OF THE BELOW SHOULD BE ALLOWED
	maps\so\zm_common\_zm_weapons::add_limited_weapon( "m2_flamethrower_zombie", 1 );
	maps\so\zm_common\_zm_weapons::add_limited_weapon( "tesla_gun", 1);
}   

// Include the weapons that are only inr your level so that the cost/hints are accurate
// Also adds these weapons to the random treasure chest.
include_weapons()
{
	include_weapon( "zombie_colt" );
	include_weapon( "zombie_colt_upgraded", false );
	include_weapon( "zombie_sw_357" );
	include_weapon( "zombie_sw_357_upgraded", false );

	// Bolt Action
	include_weapon( "zombie_kar98k" );
	include_weapon( "zombie_kar98k_upgraded", false );
//	include_weapon( "springfield");		
//	include_weapon( "zombie_type99_rifle" );
//	include_weapon( "zombie_type99_rifle_upgraded", false );

	// Semi Auto
	include_weapon( "zombie_m1carbine" );
	include_weapon( "zombie_m1carbine_upgraded", false );
	include_weapon( "zombie_m1garand" );
	include_weapon( "zombie_m1garand_upgraded", false );
	include_weapon( "zombie_gewehr43" );
	include_weapon( "zombie_gewehr43_upgraded", false );

	// Full Auto
	include_weapon( "zombie_stg44" );
	include_weapon( "zombie_stg44_upgraded", false );
	include_weapon( "zombie_thompson" );
	include_weapon( "zombie_thompson_upgraded", false );
	include_weapon( "zombie_mp40" );
	include_weapon( "zombie_mp40_upgraded", false );
	include_weapon( "zombie_type100_smg" );
	include_weapon( "zombie_type100_smg_upgraded", false );

	// Scoped
	include_weapon( "ptrs41_zombie" );
	include_weapon( "ptrs41_zombie_upgraded", false );
//	include_weapon( "kar98k_scoped_zombie" );	// replaced with type99_rifle_scoped
//	include_weapon( "type99_rifle_scoped_zombie" );	//

	// Grenade
	include_weapon( "molotov" );
	include_weapon( "stielhandgranate" );

	// Grenade Launcher	
	include_weapon( "m1garand_gl_zombie" );
	include_weapon( "m1garand_gl_zombie_upgraded", false );
	include_weapon( "m7_launcher_zombie" );
	include_weapon( "m7_launcher_zombie_upgraded", false );

	// Flamethrower
	include_weapon( "m2_flamethrower_zombie" );
	include_weapon( "m2_flamethrower_zombie_upgraded", false );

	// Shotgun
	include_weapon( "zombie_doublebarrel" );
	include_weapon( "zombie_doublebarrel_upgraded", false );
	//include_weapon( "zombie_doublebarrel_sawed" );
	include_weapon( "zombie_shotgun" );
	include_weapon( "zombie_shotgun_upgraded", false );

	// Heavy MG
	include_weapon( "zombie_bar" );
	include_weapon( "zombie_bar_upgraded", false );
	include_weapon( "zombie_fg42" );
	include_weapon( "zombie_fg42_upgraded", false );

	include_weapon( "zombie_30cal" );
	include_weapon( "zombie_30cal_upgraded", false );
	include_weapon( "zombie_mg42" );
	include_weapon( "zombie_mg42_upgraded", false );
	include_weapon( "zombie_ppsh" );
	include_weapon( "zombie_ppsh_upgraded", false );

	// Rocket Launcher
	include_weapon( "panzerschrek_zombie" );
	include_weapon( "panzerschrek_zombie_upgraded", false );

	// Special
	include_weapon( "ray_gun", true, ::factory_ray_gun_weighting_func );
	include_weapon( "ray_gun_upgraded", false );
	include_weapon( "tesla_gun", true );
	include_weapon( "tesla_gun_upgraded", false );
	include_weapon( "zombie_cymbal_monkey", true, ::factory_cymbal_monkey_weighting_func );


	//bouncing betties
	include_weapon("mine_bouncing_betty", false);

	// limited weapons
	maps\so\zm_common\_zm_weapons::add_limited_weapon( "zombie_colt", 0 );
	//maps\so\zm_common\_zm_weapons::add_limited_weapon( "zombie_type99_rifle", 0 );
	maps\so\zm_common\_zm_weapons::add_limited_weapon( "zombie_gewehr43", 0 );
	maps\so\zm_common\_zm_weapons::add_limited_weapon( "zombie_m1garand", 0 );

	register_tactical_grenade_for_level( "molotov" );
	register_tactical_grenade_for_level( "zombie_cymbal_monkey" );
	level.zombie_tactical_grenade_player_init = undefined;
	register_wonder_weapon_for_level( "zombie_cymbal_monkey" );
	register_wonder_weapon_for_level( "tesla_gun" );
	register_wonder_weapon_for_level( "tesla_gun_upgraded" );
	register_wonder_weapon_for_level( "ray_gun" );
	register_wonder_weapon_for_level( "ray_gun_upgraded" );
}


factory_ray_gun_weighting_func()
{
	if( level.box_moved == true )
	{	
		num_to_add = 1;
		// increase the percentage of ray gun
		if( isDefined( level.pulls_since_last_ray_gun ) )
		{
			// after 12 pulls the ray gun percentage increases to 15%
			if( level.pulls_since_last_ray_gun > 11 )
			{
				num_to_add += int(level.zombie_include_weapons.size*0.1);
			}			
			// after 8 pulls the Ray Gun percentage increases to 10%
			else if( level.pulls_since_last_ray_gun > 7 )
			{
				num_to_add += int(.05 * level.zombie_include_weapons.size);
			}		
		}
		return num_to_add;	
	}
	else
	{
		return 0;
	}
}


//
//	Slightly elevate the chance to get it until someone has it, then make it even
factory_cymbal_monkey_weighting_func()
{
	players = getPlayers();
	count = 0;
	for( i = 0; i < players.size; i++ )
	{
		if( players[i] maps\so\zm_common\_zm_weapons::has_weapon_or_upgrade( "zombie_cymbal_monkey" ) )
		{
			count++;
		}
	}
	if ( count > 0 )
	{
		return 1;
	}
	else
	{
		if( level.round_number < 10 )
		{
			return 3;
		}
		else
		{
			return 5;
		}
	}
}

#using_animtree( "generic_human" ); 
force_zombie_crawler()
{
	if( !IsDefined( self ) )
	{
		return;
	}

	if( !self.gibbed )
	{
		refs = []; 

		refs[refs.size] = "no_legs"; 

		if( refs.size )
		{
			self.a.gib_ref = animscripts\death::get_random( refs ); 
		
			// Don't stand if a leg is gone
			self.has_legs = false; 
			self AllowedStances( "crouch" ); 
								
			which_anim = RandomInt( 5 ); 
			
			if( which_anim == 0 ) 
			{
				self.deathanim = %ai_zombie_crawl_death_v1;
				self set_run_anim( "death3" );
				self.run_combatanim = level.scr_anim["zombie"]["crawl1"];
				self.crouchRunAnim = level.scr_anim["zombie"]["crawl1"];
				self.crouchrun_combatanim = level.scr_anim["zombie"]["crawl1"];
			}
			else if( which_anim == 1 ) 
			{
				self.deathanim = %ai_zombie_crawl_death_v2;
				self set_run_anim( "death4" );
				self.run_combatanim = level.scr_anim["zombie"]["crawl2"];
				self.crouchRunAnim = level.scr_anim["zombie"]["crawl2"];
				self.crouchrun_combatanim = level.scr_anim["zombie"]["crawl2"];
			}
			else if( which_anim == 2 ) 
			{
				self.deathanim = %ai_zombie_crawl_death_v1;
				self set_run_anim( "death3" );
				self.run_combatanim = level.scr_anim["zombie"]["crawl3"];
				self.crouchRunAnim = level.scr_anim["zombie"]["crawl3"];
				self.crouchrun_combatanim = level.scr_anim["zombie"]["crawl3"];
			}
			else if( which_anim == 3 ) 
			{
				self.deathanim = %ai_zombie_crawl_death_v2;
				self set_run_anim( "death4" );
				self.run_combatanim = level.scr_anim["zombie"]["crawl4"];
				self.crouchRunAnim = level.scr_anim["zombie"]["crawl4"];
				self.crouchrun_combatanim = level.scr_anim["zombie"]["crawl4"];
			}
			else if( which_anim == 4 ) 
			{
				self.deathanim = %ai_zombie_crawl_death_v1;
				self set_run_anim( "death3" );
				self.run_combatanim = level.scr_anim["zombie"]["crawl5"];
				self.crouchRunAnim = level.scr_anim["zombie"]["crawl5"];
				self.crouchrun_combatanim = level.scr_anim["zombie"]["crawl5"];
			}								
		}

		if( self.health > 50 )
		{
			self.health = 50;
			
			// force gibbing if the zombie is still alive
			self thread animscripts\death::do_gib();
		}
	}
}


//
//	This initialitze the box spawn locations
//	You can disable boxes from appearing by not adding their script_noteworthy ID to the list
//
magic_box_init()
{
	//MM - all locations are valid.  If it goes somewhere you haven't opened, you need to open it.
	level.open_chest_location = [];
	level.open_chest_location[0] = "chest1";	// TP East
	level.open_chest_location[1] = "chest2";	// TP West
	level.open_chest_location[2] = "chest3";	// TP South
	level.open_chest_location[3] = "chest4";	// WNUEN
	level.open_chest_location[4] = "chest5";	// Warehouse bottom
	level.open_chest_location[5] = "start_chest";
}


/*------------------------------------
the electric switch under the bridge
once this is used, it activates other objects in the map
and makes them available to use
------------------------------------*/
power_electric_switch()
{
	trig = getent("use_power_switch","targetname");
	master_switch = getent("power_switch","targetname");	
	master_switch notsolid();
	//master_switch rotatepitch(90,1);
	trig sethintstring(&"ZOMBIE_ELECTRIC_SWITCH");
		
	//turn off the buyable door triggers for electric doors
// 	door_trigs = getentarray("electric_door","script_noteworthy");
// 	array_thread(door_trigs,::set_door_unusable);
// 	array_thread(door_trigs,::play_door_dialog);

	cheat = false;
	
/# 
	if( GetDvarInt( "zombie_cheat" ) >= 3 )
	{
		wait( 5 );
		cheat = true;
	}
#/	

	user = undefined;
	if ( cheat != true )
	{
		trig waittill("trigger",user);
	}
	
	// MM - turning on the power powers the entire map
// 	if ( IsDefined(user) )	// only send a notify if we weren't originally triggered through script
// 	{
// 		other_trig = getent("use_warehouse_switch","targetname");
// 		other_trig notify( "trigger", undefined );
// 
// 		wuen_trig = getent("use_wuen_switch", "targetname" );
// 		wuen_trig notify( "trigger", undefined );
// 	}

	master_switch rotateroll(-90,.3);

	//TO DO (TUEY) - kick off a 'switch' on client script here that operates similiarly to Berlin2 subway.
	master_switch playsound("switch_flip");
	flag_set( "electricity_on" );
	flag_set( "power_on" );
	wait_network_frame();
	clientnotify( "revive_on" );
	wait_network_frame();
	clientnotify( "fast_reload_on" );
	wait_network_frame();
	clientnotify( "doubletap_on" );
	wait_network_frame();
	clientnotify( "jugger_on" );
	wait_network_frame();
	level notify( "sleight_on" );
	wait_network_frame();
	level notify( "revive_on" );
	wait_network_frame();
	level notify( "doubletap_on" );
	wait_network_frame();
	level notify( "juggernog_on" );
	wait_network_frame();
	level notify( "Pack_A_Punch_on" );
	wait_network_frame();
	level notify( "specialty_armorvest_power_on" );
	wait_network_frame();
	level notify( "specialty_rof_power_on" );
	wait_network_frame();
	level notify( "specialty_quickrevive_power_on" );
	wait_network_frame();
	level notify( "specialty_fastreload_power_on" );
	wait_network_frame();

//	clientnotify( "power_on" );
	ClientNotify( "pl1" );	// power lights on
	exploder(600);

	trig delete();	
	
	playfx(level._effect["switch_sparks"] ,getstruct("power_switch_fx","targetname").origin);

	// Don't want east or west to spawn when in south zone, but vice versa is okay
	maps\so\zm_common\_zm_zonemgr::connect_zones( "outside_east_zone", "outside_south_zone" );
	maps\so\zm_common\_zm_zonemgr::connect_zones( "outside_west_zone", "outside_south_zone", true );
}


/**********************
Electrical trap
**********************/
init_elec_trap_trigs()
{
	//trap_trigs = getentarray("gas_access","targetname");
	//array_thread (trap_trigs,::electric_trap_think);
	//array_thread (trap_trigs,::electric_trap_dialog);

	// MM - traps disabled for now
	array_thread( getentarray("warehouse_electric_trap",	"targetname"), ::electric_trap_think, "enter_warehouse_building" );
	array_thread( getentarray("wuen_electric_trap",			"targetname"), ::electric_trap_think, "enter_wnuen_building" );
	array_thread( getentarray("bridge_electric_trap",		"targetname"), ::electric_trap_think, "bridge_down" );
}

electric_trap_dialog()
{

	self endon ("warning_dialog");
	level endon("switch_flipped");
	timer =0;
	while(1)
	{
		wait(0.5);
		players = getPlayers();
		for(i = 0; i < players.size; i++)
		{		
			dist = distancesquared(players[i].origin, self.origin );
			if(dist > 70*70)
			{
				timer = 0;
				continue;
			}
			if(dist < 70*70 && timer < 3)
			{
				wait(0.5);
				timer ++;
			}
			if(dist < 70*70 && timer == 3)
			{
				
				index = maps\so\zm_common\_zm_weapons::get_player_index(players[i]);
				plr = "plr_" + index + "_";
				//players[i] create_and_play_dialog( plr, "vox_level_start", 0.25 );
				wait(3);				
				self notify ("warning_dialog");
				//iprintlnbold("warning_given");
			}
		}
	}
}


/*------------------------------------
	This controls the electric traps in the level
		self = use trigger associated with the trap
------------------------------------*/
electric_trap_think( enable_flag )
{	
	self sethintstring(&"ZOMBIE_FLAMES_UNAVAILABLE");
	self.zombie_cost = 1000;
	
	self thread electric_trap_dialog();

	// get a list of all of the other triggers with the same name
	triggers = getentarray( self.targetname, "targetname" );
	flag_wait( "electricity_on" );

	// Get the damage trigger.  This is the unifying element to let us know it's been activated.
	self.zombie_dmg_trig = getent(self.target,"targetname");
	self.zombie_dmg_trig.in_use = 0;

	// Set buy string
	self sethintstring(&"ZOMBIE_BUTTON_NORTH_FLAMES");

	// Getting the light that's related is a little esoteric, but there isn't
	// a better way at the moment.  It uses linknames, which are really dodgy.
	light_name = "";	// scope declaration
	tswitch = getent(self.script_linkto,"script_linkname");
	switch ( tswitch.script_linkname )
	{
	case "10":	// wnuen
	case "11":
		light_name = "zapper_light_wuen";	
		break;

	case "20":	// warehouse
	case "21":
		light_name = "zapper_light_warehouse";
		break;

	case "30":	// Bridge
	case "31":
		light_name = "zapper_light_bridge";
		break;
	}

	// The power is now on, but keep it disabled until a certain condition is met
	//	such as opening the door it is blocking or waiting for the bridge to lower.
	if ( !flag( enable_flag ) )
	{
		self trigger_off();

		zapper_light_red( light_name );
		flag_wait( enable_flag );

		self trigger_on();
	}

	// Open for business!  
	zapper_light_green( light_name );

	while(1)
	{
		//valve_trigs = getentarray(self.script_noteworthy ,"script_noteworthy");		
	
		//wait until someone uses the valve
		self waittill("trigger",who);
		if( who in_revive_trigger() )
		{
			continue;
		}
		
		if( is_player_valid( who ) )
		{
			if( who.score >= self.zombie_cost )
			{				
				if(!self.zombie_dmg_trig.in_use)
				{
					self.zombie_dmg_trig.in_use = 1;

					//turn off the valve triggers associated with this trap until available again
					array_thread (triggers, ::trigger_off);

					play_sound_at_pos( "purchase", who.origin );
					self thread electric_trap_move_switch(self);
					//need to play a 'woosh' sound here, like a gas furnace starting up
					self waittill("switch_activated");
					//set the score
					who maps\so\zm_common\_zm_score::minus_to_player_score( self.zombie_cost );

					//this trigger detects zombies walking thru the flames
					self.zombie_dmg_trig trigger_on();

					//play the flame FX and do the actual damage
					self thread activate_electric_trap();					

					//wait until done and then re-enable the valve for purchase again
					self waittill("elec_done");
					
					clientnotify(self.script_string +"off");
										
					//delete any FX ents
					if(isDefined(self.fx_org))
					{
						self.fx_org delete();
					}
					if(isDefined(self.zapper_fx_org))
					{
						self.zapper_fx_org delete();
					}
					if(isDefined(self.zapper_fx_switch_org))
					{
						self.zapper_fx_switch_org delete();
					}
										
					//turn the damage detection trigger off until the flames are used again
			 		self.zombie_dmg_trig trigger_off();
					wait(25);

					array_thread (triggers, ::trigger_on);

					//COLLIN: Play the 'alarm' sound to alert players that the traps are available again (playing on a temp ent in case the PA is already in use.
					//speakerA = getstruct("loudspeaker", "targetname");
					//playsoundatposition("warning", speakera.origin);
					self notify("available");

					self.zombie_dmg_trig.in_use = 0;
				}
			}
		}
	}
}


//
//  it's a throw switch
electric_trap_move_switch(parent)
{
	light_name = "";	// scope declaration
	tswitch = getent(parent.script_linkto,"script_linkname");
	switch ( tswitch.script_linkname )
	{
	case "10":	// wnuen
	case "11":
		light_name = "zapper_light_wuen";	
		break;

	case "20":	// warehouse
	case "21":
		light_name = "zapper_light_warehouse";
		break;

	case "30":
	case "31":
		light_name = "zapper_light_bridge";
		break;
	}
	
	//turn the light above the door red
	zapper_light_red( light_name );
	tswitch rotatepitch(180,.5);
	tswitch playsound("amb_sparks_l_b");
	tswitch waittill("rotatedone");

	self notify("switch_activated");
	self waittill("available");
	tswitch rotatepitch(-180,.5);

	//turn the light back green once the trap is available again
	zapper_light_green( light_name );
}


//
//
activate_electric_trap()
{
	if(isDefined(self.script_string) && self.script_string == "warehouse")
	{
		clientnotify("warehouse");
	}
	else if(isDefined(self.script_string) && self.script_string == "wuen")
	{
		clientnotify("wuen");
	}
	else
	{
		clientnotify("bridge");
	}	
		
	clientnotify(self.target);
	
	fire_points = getstructarray(self.target,"targetname");
	
	for(i=0;i<fire_points.size;i++)
	{
		wait_network_frame();
		fire_points[i] thread electric_trap_fx(self);		
	}
	
	//do the damage
	self.zombie_dmg_trig thread elec_barrier_damage();
	
	// reset the zapper model
	level waittill("arc_done");
}


//
//
electric_trap_fx(notify_ent)
{
	self.tag_origin = spawn("script_model",self.origin);
	//self.tag_origin setmodel("tag_origin");

	//playfxontag(level._effect["zapper"],self.tag_origin,"tag_origin");

	self.tag_origin playsound("elec_start");
	self.tag_origin playloopsound("elec_loop");
	self thread play_electrical_sound();
	
	wait(25);
		
	self.tag_origin stoploopsound();
		
	self.tag_origin delete(); 
	notify_ent notify("elec_done");
	level notify ("arc_done");	
}


//
//
play_electrical_sound()
{
	level endon ("arc_done");
	while(1)
	{	
		wait(randomfloatrange(0.1, 0.5));
		playsoundatposition("elec_arc", self.origin);
	}
	

}


//
//
elec_barrier_damage()
{	
	while(1)
	{
		self waittill("trigger",ent);
		
		//player is standing electricity, dumbass
		if(isplayer(ent) )
		{
			ent thread player_elec_damage();
		}
		else
		{
			if(!isDefined(ent.marked_for_death))
			{
				ent.marked_for_death = true;
				ent thread zombie_elec_death( randomint(100) );
			}
		}
	}
}
play_elec_vocals()
{
	if(IsDefined (self)) 
	{
		org = self.origin;
		wait(0.15);
		playsoundatposition("elec_vocals", org);
		playsoundatposition("zombie_arc", org);
		playsoundatposition("exp_jib_zombie", org);
	}
}
player_elec_damage()
{	
	self endon("death");
	self endon("disconnect");
	
	if(!IsDefined (level.elec_loop))
	{
		level.elec_loop = 0;
	}	
	
	if( !isDefined(self.is_burning) && !self maps\_laststand::player_is_in_laststand() )
	{
		self.is_burning = 1;		
		self setelectrified(1.25);	
		shocktime = 2.5;			
		//Changed Shellshock to Electrocution so we can have different bus volumes.
		self shellshock("electrocution", shocktime);
		
		if(level.elec_loop == 0)
		{	
			elec_loop = 1;
			//self playloopsound ("electrocution");
			self playsound("zombie_arc");
		}
		if(!self hasperk("specialty_armorvest") || self.health - 100 < 1)
		{
			
			radiusdamage(self.origin,10,self.health + 100,self.health + 100);
			self.is_burning = undefined;

		}
		else
		{
			self dodamage(50, self.origin);
			wait(.1);
			//self playsound("zombie_arc");
			self.is_burning = undefined;
		}


	}

}


zombie_elec_death(flame_chance)
{
	self endon("death");
	
	//10% chance the zombie will burn, a max of 6 burning zombs can be goign at once
	//otherwise the zombie just gibs and dies
	if(flame_chance > 90 && level.burning_zombies.size < 6)
	{
		level.burning_zombies[level.burning_zombies.size] = self;
		self thread zombie_flame_watch();
		self playsound("ignite");
		self thread animscripts\death::flame_death_fx();
		wait(randomfloat(1.25));		
	}
	else
	{
		
		refs[0] = "guts";
		refs[1] = "right_arm"; 
		refs[2] = "left_arm"; 
		refs[3] = "right_leg"; 
		refs[4] = "left_leg"; 
		refs[5] = "no_legs";
		refs[6] = "head";
		self.a.gib_ref = refs[randomint(refs.size)];

		playsoundatposition("zombie_arc", self.origin);
		if( !self enemy_is_dog() && randomint(100) > 50 )
		{
			self thread electroctute_death_fx();
			self thread play_elec_vocals();
		}
		wait(randomfloat(1.25));
		self playsound("zombie_arc");
	}

	self dodamage(self.health + 666, self.origin);
	iprintlnbold("should be damaged");
}

zombie_flame_watch()
{
	self waittill("death");
	self stoploopsound();
	level.burning_zombies = array_remove_nokeys(level.burning_zombies,self);
}


//
//	Swaps a cage light model to the red one.
zapper_light_red( lightname )
{
	zapper_lights = getentarray( lightname, "targetname");
	for(i=0;i<zapper_lights.size;i++)
	{
		zapper_lights[i] setmodel("zombie_zapper_cagelight_red");	

		if(isDefined(zapper_lights[i].fx))
		{
			zapper_lights[i].fx delete();
		}

		zapper_lights[i].fx = maps\so\zm_common\_zm_network::network_safe_spawn( "trap_light_red", 2, "script_model", zapper_lights[i].origin );
		zapper_lights[i].fx setmodel("tag_origin");
		zapper_lights[i].fx.angles = zapper_lights[i].angles+(-90,0,0);
		playfxontag(level._effect["zapper_light_notready"],zapper_lights[i].fx,"tag_origin");
	}
}


//
//	Swaps a cage light model to the green one.
zapper_light_green( lightname )
{
	zapper_lights = getentarray( lightname, "targetname");
	for(i=0;i<zapper_lights.size;i++)
	{
		zapper_lights[i] setmodel("zombie_zapper_cagelight_green");	

		if(isDefined(zapper_lights[i].fx))
		{
			zapper_lights[i].fx delete();
		}

		zapper_lights[i].fx = maps\so\zm_common\_zm_network::network_safe_spawn( "trap_light_green", 2, "script_model", zapper_lights[i].origin );
		zapper_lights[i].fx setmodel("tag_origin");
		zapper_lights[i].fx.angles = zapper_lights[i].angles+(-90,0,0);
		playfxontag(level._effect["zapper_light_ready"],zapper_lights[i].fx,"tag_origin");
	}
}


//
//	
electroctute_death_fx()
{
	self endon( "death" );


	if (isdefined(self.is_electrocuted) && self.is_electrocuted )
	{
		return;
	}
	
	self.is_electrocuted = true;
	
	self thread electrocute_timeout();
		
	// JamesS - this will darken the burning body
	self StartTanning(); 

	if(self.team == "axis")
	{
		level.bcOnFireTime = gettime();
		level.bcOnFireOrg = self.origin;
	}
	
	
	PlayFxOnTag( level._effect["elec_torso"], self, "J_SpineLower" ); 
	self playsound ("elec_jib_zombie");
	wait 1;

	tagArray = []; 
	tagArray[0] = "J_Elbow_LE"; 
	tagArray[1] = "J_Elbow_RI"; 
	tagArray[2] = "J_Knee_RI"; 
	tagArray[3] = "J_Knee_LE"; 
	tagArray = array_randomize( tagArray ); 

	PlayFxOnTag( level._effect["elec_md"], self, tagArray[0] ); 
	self playsound ("elec_jib_zombie");

	wait 1;
	self playsound ("elec_jib_zombie");

	tagArray[0] = "J_Wrist_RI"; 
	tagArray[1] = "J_Wrist_LE"; 
	if( !IsDefined( self.a.gib_ref ) || self.a.gib_ref != "no_legs" )
	{
		tagArray[2] = "J_Ankle_RI"; 
		tagArray[3] = "J_Ankle_LE"; 
	}
	tagArray = array_randomize( tagArray ); 

	PlayFxOnTag( level._effect["elec_sm"], self, tagArray[0] ); 
	PlayFxOnTag( level._effect["elec_sm"], self, tagArray[1] );

}

electrocute_timeout()
{
	self endon ("death");
	self playloopsound("fire_manager_0");
	// about the length of the flame fx
	wait 12;
	self stoploopsound();
	if (isdefined(self) && isalive(self))
	{
		self.is_electrocuted = false;
		self notify ("stop_flame_damage");
	}
	
}

//*** AUDIO SECTION ***

player_zombie_awareness()
{
	self endon("disconnect");
	self endon("death");
	players = getplayers();
	index = maps\so\zm_common\_zm_weapons::get_player_index(self);
	while(1)
	{
		wait(1);		
		//zombie = get_closest_ai(self.origin,"axis");
		
		zombs = getaiarray("axis");
		for(i=0;i<zombs.size;i++)
		{
			if(DistanceSquared(zombs[i].origin, self.origin) < 200 * 200)
			{
				if(!isDefined(zombs[i]))
				{
					continue;
				}
				
				dist = 200;				
				switch(zombs[i].zombie_move_speed)
				{
					case "walk": dist = 200;break;
					case "run": dist = 250; break;
					case "sprint": dist = 275;break;
				}				
				if(distance2d(zombs[i].origin,self.origin) < dist)
				{				
					yaw = self animscripts\utility::GetYawToSpot(zombs[i].origin );
					//check to see if he's actually behind the player
					if(yaw < -95 || yaw > 95)
					{
						zombs[i] playsound ("behind_vocals");
					}
				}				
			}
		}
		if(players.size > 1)
		{
			//Plays 'teamwork' style dialog if there are more than 1 player...
			close_zombs = 0;
			for(i=0;i<zombs.size;i++)
			{
				if(DistanceSquared(zombs[i].origin, self.origin) < 250 * 250)
				{
					close_zombs ++;
				}
			}
			if(close_zombs > 4)
			{
				if(randomintrange(0,20) < 5)
				{
					plr = "plr_" + index + "_";
					self thread create_and_play_dialog( plr, "vox_oh_shit", .25, "resp_ohshit" );	
				}
			}
		}
	}
}		

/*
play_oh_shit_dialog()
{
	//player = getplayers();	
	index = maps\so\zm_common\_zm_weapons::get_player_index(self);
	
	player_index = "plr_" + index + "_";
	if(!IsDefined (self.vox_oh_shit))
	{
		num_variants = maps\so\zm_common\_zm_spawner::get_number_variants(player_index + "vox_oh_shit");
		self.vox_oh_shit = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_oh_shit[self.vox_oh_shit.size] = "vox_oh_shit_" + i;	
		}
		self.vox_oh_shit_available = self.vox_oh_shit;		
	}	
	sound_to_play = random(self.vox_oh_shit_available);
	
	self.vox_oh_shit_available = array_remove(self.vox_oh_shit_available,sound_to_play);
	
	if (self.vox_oh_shit_available.size < 1 )
	{
		self.vox_oh_shit_available = self.vox_oh_shit;
	}
	
	self maps\so\zm_common\_zm_spawner::do_player_playdialog(player_index, sound_to_play, 0.25);
}
*/

level_start_vox()
{
	index = maps\so\zm_common\_zm_weapons::get_player_index( self );
	plr = "plr_" + index + "_";
	wait( 6 );
	self thread create_and_play_dialog( plr, "vox_level_start", 0.25 );
}


check_for_change()
{
	while (1)
	{
		self waittill( "trigger", player );

		if ( player GetStance() == "prone" )
		{
			player maps\so\zm_common\_zm_score::add_to_player_score( 25 );
			play_sound_at_pos( "purchase", player.origin );
			break;
		}
	}
}

extra_events()
{
	self UseTriggerRequireLookAt();
	self SetCursorHint( "HINT_NOICON" ); 
	self waittill( "trigger" );

	targ = GetEnt( self.target, "targetname" );
	if ( IsDefined(targ) )
	{
		targ MoveZ( -10, 5 );
	}
}


//
//	Activate the flytrap!
flytrap()
{
	flag_init( "hide_and_seek" );
	level.flytrap_counter = 0;

	// Hide Easter Eggs...
	// Explosive Monkey
	level thread hide_and_seek_target( "ee_exp_monkey" );
	wait_network_frame();
	level thread hide_and_seek_target( "ee_bowie_bear" );
	wait_network_frame();
	level thread hide_and_seek_target( "ee_perk_bear" );
	wait_network_frame();
	
	trig_control_panel = GetEnt( "trig_ee_flytrap", "targetname" );

	// Wait for it to be hit by an upgraded weapon
	upgrade_hit = false;
	while ( !upgrade_hit )
	{
		trig_control_panel waittill( "damage", amount, inflictor, direction, point, type );

		weapon = inflictor getcurrentweapon();
		if ( maps\so\zm_common\_zm_weapons::is_weapon_upgraded( weapon ) )
		{
			upgrade_hit = true;
		}
	}

	trig_control_panel playsound( "flytrap_hit" );
	playsoundatposition( "flytrap_creeper", trig_control_panel.origin );
	thread play_sound_2d( "sam_fly_laugh" );
	//iprintlnbold( "Samantha Sez: Hahahahahaha" );

	// Float the objects
	level achievement_notify("DLC3_ZOMBIE_ANTI_GRAVITY");
	level ClientNotify( "ag1" );	// Anti Gravity ON
	wait(9.0);
	thread play_sound_2d( "sam_fly_act_0" );
	wait(6.0);
	
	thread play_sound_2d( "sam_fly_act_1" );
	//iprintlnbold( "Samantha Sez: Let's play Hide and Seek!" );

	//	Now find them!
	flag_set( "hide_and_seek" );

	flag_wait( "ee_exp_monkey" );
	flag_wait( "ee_bowie_bear" );
	flag_wait( "ee_perk_bear" );

	// Colin, play music here.
//	println( "Still Alive" );
}


//
//	Controls hide and seek object and trigger
hide_and_seek_target( target_name )
{
	flag_init( target_name );

	obj_array = GetEntArray( target_name, "targetname" );
	for ( i=0; i<obj_array.size; i++ )
	{
		obj_array[i] Hide();
	}

	trig = GetEnt( "trig_"+target_name, "targetname" );
	trig trigger_off();
	flag_wait( "hide_and_seek" );

	// Show yourself
	for ( i=0; i<obj_array.size; i++ )
	{
		obj_array[i] Show();
	}
	trig trigger_on();
	trig waittill( "trigger" );
	
	level.flytrap_counter = level.flytrap_counter +1;
	thread flytrap_samantha_vox();
	trig playsound( "object_hit" );

	for ( i=0; i<obj_array.size; i++ )
	{
		obj_array[i] Hide();
	}
	flag_set( target_name );
}

phono_egg_init( trigger_name, origin_name )
{
	if(!IsDefined (level.phono_counter))
	{
		level.phono_counter = 0;	
	}
	players = getplayers();
	phono_trig = getent ( trigger_name, "targetname");
	phono_origin = getent( origin_name, "targetname");
	
	if( ( !isdefined( phono_trig ) ) || ( !isdefined( phono_origin ) ) )
	{
		return;
	}
	
	phono_trig UseTriggerRequireLookAt();
	phono_trig SetCursorHint( "HINT_NOICON" ); 
	
	for(i=0;i<players.size;i++)
	{			
		phono_trig waittill( "trigger", players);
		level.phono_counter = level.phono_counter + 1;
		phono_origin play_phono_egg();
	}	
}

play_phono_egg()
{
	if(!IsDefined (level.phono_counter))
	{
		level.phono_counter = 0;	
	}
	
	if( level.phono_counter == 1 )
	{
		//iprintlnbold( "Phono Egg One Activated!" );
		self playsound( "phono_one" );
	}
	if( level.phono_counter == 2 )
	{
		//iprintlnbold( "Phono Egg Two Activated!" );
		self playsound( "phono_two" );
	}
	if( level.phono_counter == 3 )
	{
		//iprintlnbold( "Phono Egg Three Activated!" );
		self playsound( "phono_three" );
	}
}

radio_egg_init( trigger_name, origin_name )
{
	players = getplayers();
	radio_trig = getent( trigger_name, "targetname");
	radio_origin = getent( origin_name, "targetname");

	if( ( !isdefined( radio_trig ) ) || ( !isdefined( radio_origin ) ) )
	{
		return;
	}

	radio_trig UseTriggerRequireLookAt();
	radio_trig SetCursorHint( "HINT_NOICON" ); 
	radio_origin playloopsound( "radio_static" );

	for(i=0;i<players.size;i++)
	{			
		radio_trig waittill( "trigger", players);
		radio_origin stoploopsound( .1 );
		//iprintlnbold( "You activated " + trigger_name + ", playing off " + origin_name );
		radio_origin playsound( trigger_name );
	}	
}

/*
radio_egg_hanging_init( trigger_name, origin_name )
{
	radio_trig = getent( trigger_name, "targetname");
	radio_origin = getent( origin_name, "targetname");

	if( ( !isdefined( radio_trig ) ) || ( !isdefined( radio_origin ) ) )
	{
		return;
	}
	
	while(1)
	{
		radio_trig waittill( "trigger", player);
		dist = distancesquared(player.origin, radio_trig.origin);
		if( dist < 900 * 900)
		{
			radio_origin playsound( trigger_name );
			return;
		}
		else
		{
			wait(.05);
		}
	}	
}
*/

//Hanging dead guy
hanging_dead_guy( name )
{
	//grab the hanging dead guy model
	dead_guy = getent( name, "targetname");

	if( !isdefined(dead_guy) )
		return;

	dead_guy physicslaunch ( dead_guy.origin, (randomintrange(-20,20),randomintrange(-20,20),randomintrange(-20,20)) );
}

play_music_easter_egg()
{
	if (!IsDefined (level.eggs))
	{
		level.eggs = 0;
	}
	
	level.eggs = 1;
	setmusicstate("eggs");
	
	//player thread create_and_play_dialog( plr, "vox_audio_secret", .25);
	
	wait(270);	
	setmusicstate("WAVE_1");
	level.eggs = 0;
}

meteor_egg( trigger_name )
{
	while(1)
	{
		if(!IsDefined (level.meteor_counter))
		{
			level.meteor_counter = 0;	
		}
	
		meteor_trig = getent ( trigger_name, "targetname");

		if( !isdefined( meteor_trig ) )
		{
			return;
		}	
		meteor_trig UseTriggerRequireLookAt();
		meteor_trig SetCursorHint( "HINT_NOICON" ); 
			
		meteor_trig waittill( "trigger", player );
		player playsound( "meteor_affirm" );	
		level.meteor_counter = level.meteor_counter + 1;
		return;
	}
}

meteor_egg_play()
{
	while(1)
	{
		if(!IsDefined (level.meteor_counter))
		{
			level.meteor_counter = 0;	
		}

		if( level.meteor_counter == 3 )
		{
			thread play_music_easter_egg();
			return;
		}
		wait(0.05);
	}
}

flytrap_samantha_vox()
{
	if(!IsDefined (level.flytrap_counter))
	{
		level.flytrap_counter = 0;	
	}

	if( level.flytrap_counter == 1 )
	{
		//iprintlnbold( "Samantha Sez: Way to go!" );
		thread play_sound_2d( "sam_fly_first" );
	}
	if( level.flytrap_counter == 2 )
	{
		//iprintlnbold( "Samantha Sez: Two? WOW!" );
		thread play_sound_2d( "sam_fly_second" );
	}
	if( level.flytrap_counter == 3 )
	{
		//iprintlnbold( "Samantha Sez: And GAME OVER!" );		
		thread play_sound_2d( "sam_fly_last" );
		return;
	}
	wait(0.05);
}

play_giant_mythos_lines()
{
	round = 5; 
	
	wait(10);
	while(1)
	{
		vox_rand = randomintrange(1,100);
		
		if( level.round_number <= round )
		{
			if( vox_rand <= 2 )
			{
				players = getPlayers();
				p = randomint(players.size);
				index = maps\so\zm_common\_zm_weapons::get_player_index(players[p]);
				plr = "plr_" + index + "_";
				players[p] thread create_and_play_dialog( plr, "vox_gen_giant", .25 );
				//iprintlnbold( "Just played Gen Giant line off of player " + p );
			}
		}
		else if (level.round_number > round )
		{
			return;
		}
		wait(randomintrange(60,240));
	}
}

play_level_easteregg_vox( object )
{
	percent = 35;
	
	trig = getent( object, "targetname" );
	
	if(!isdefined( trig ) )
	{
		return;
	}
	
	trig UseTriggerRequireLookAt();
	trig SetCursorHint( "HINT_NOICON" ); 
	
	while(1)
	{
		trig waittill( "trigger", who );
		
		vox_rand = randomintrange(1,100);
			
		if( vox_rand <= percent )
		{
			index = maps\so\zm_common\_zm_weapons::get_player_index(who);
			plr = "plr_" + index + "_";
			
			switch( object )
			{
				case "vox_corkboard_1":
					//iprintlnbold( "Inside trigger " + object );
					who thread create_and_play_dialog( plr, "vox_resp_corkmap", .25 );
					break;
				case "vox_corkboard_2":
					//iprintlnbold( "Inside trigger " + object );
					who thread create_and_play_dialog( plr, "vox_resp_corkmap", .25 );
					break;
				case "vox_corkboard_3":
					//iprintlnbold( "Inside trigger " + object );
					who thread create_and_play_dialog( plr, "vox_resp_corkmap", .25 );
					break;
				case "vox_teddy":
					if( index != 2 )
					{
						//iprintlnbold( "Inside trigger " + object );
						who thread create_and_play_dialog( plr, "vox_resp_teddy", .25 );
					}
					break;
				case "vox_fieldop":
					if( (index != 1) && (index != 3) )
					{
						//iprintlnbold( "Inside trigger " + object );
						who thread create_and_play_dialog( plr, "vox_resp_fieldop", .25 );
					}
					break;
				case "vox_maxis":
					if( index == 3 )
					{
						//iprintlnbold( "Inside trigger " + object );
						who thread create_and_play_dialog( plr, "vox_resp_maxis", .25 );
					}
					break;
				case "vox_illumi_1":
					if( index == 3 )
					{
						//iprintlnbold( "Inside trigger " + object );
						who thread create_and_play_dialog( plr, "vox_resp_maxis", .25 );
					}
					break;
				case "vox_illumi_2":
					if( index == 3 )
					{
						//iprintlnbold( "Inside trigger " + object );
						who thread create_and_play_dialog( plr, "vox_resp_maxis", .25 );
					}
					break;
				default:
					return;
			}
		}
		else
		{
			index = maps\so\zm_common\_zm_weapons::get_player_index(who);
			plr = "plr_" + index + "_";
			
			who thread create_and_play_dialog( plr, "vox_gen_sigh", .25 );
		}
		wait(15);
	}
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
	level._effect["tesla_head_light"]		= Loadfx( "maps/zombie/fx_zombie_tesla_neck_spurt");

	level._effect["rise_burst_water"]		= LoadFx("maps/zombie/fx_zombie_body_wtr_burst");
	level._effect["rise_billow_water"]	= LoadFx("maps/zombie/fx_zombie_body_wtr_billowing");
	level._effect["rise_dust_water"]		= LoadFx("maps/zombie/fx_zombie_body_wtr_falling");

	level._effect["rise_burst"]		= LoadFx("maps/mp_maps/fx_mp_zombie_hand_dirt_burst");
	level._effect["rise_billow"]	= LoadFx("maps/mp_maps/fx_mp_zombie_body_dirt_billowing");
	level._effect["rise_dust"]		= LoadFx("maps/mp_maps/fx_mp_zombie_body_dust_falling");	

	// Flamethrower
	level._effect["character_fire_pain_sm"]              		= loadfx( "env/fire/fx_fire_player_sm_1sec" );
	level._effect["character_fire_death_sm"]             		= loadfx( "env/fire/fx_fire_player_md" );
	level._effect["character_fire_death_torso"] 				= loadfx( "env/fire/fx_fire_player_torso" );
}

// zombie specific anims
#using_animtree( "generic_human" ); 
init_standard_zombie_anims()
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
	level.scr_anim["zombie"]["run4"] 	= %ai_zombie_run_v2;
	level.scr_anim["zombie"]["run5"] 	= %ai_zombie_run_v4;
	level.scr_anim["zombie"]["run6"] 	= %ai_zombie_run_v3;
	//level.scr_anim["zombie"]["run4"] 	= %ai_zombie_run_v1;
	//level.scr_anim["zombie"]["run6"] 	= %ai_zombie_run_v4;

	level.scr_anim["zombie"]["sprint1"] = %ai_zombie_sprint_v1;
	level.scr_anim["zombie"]["sprint2"] = %ai_zombie_sprint_v2;
	level.scr_anim["zombie"]["sprint3"] = %ai_zombie_sprint_v1;
	level.scr_anim["zombie"]["sprint4"] = %ai_zombie_sprint_v2;
	//level.scr_anim["zombie"]["sprint3"] = %ai_zombie_sprint_v3;
	//level.scr_anim["zombie"]["sprint3"] = %ai_zombie_sprint_v4;
	//level.scr_anim["zombie"]["sprint4"] = %ai_zombie_sprint_v5;

	// run cycles in prone
	level.scr_anim["zombie"]["crawl1"] 	= %ai_zombie_crawl;
	level.scr_anim["zombie"]["crawl2"] 	= %ai_zombie_crawl_v1;
	level.scr_anim["zombie"]["crawl3"] 	= %ai_zombie_crawl_v2;
	level.scr_anim["zombie"]["crawl4"] 	= %ai_zombie_crawl_v3;
	level.scr_anim["zombie"]["crawl5"] 	= %ai_zombie_crawl_v4;
	level.scr_anim["zombie"]["crawl6"] 	= %ai_zombie_crawl_v5;
	level.scr_anim["zombie"]["crawl_hand_1"] = %ai_zombie_walk_on_hands_a;
	level.scr_anim["zombie"]["crawl_hand_2"] = %ai_zombie_walk_on_hands_b;



	
	level.scr_anim["zombie"]["crawl_sprint1"] 	= %ai_zombie_crawl_sprint;
	level.scr_anim["zombie"]["crawl_sprint2"] 	= %ai_zombie_crawl_sprint_1;
	level.scr_anim["zombie"]["crawl_sprint3"] 	= %ai_zombie_crawl_sprint_2;

	if( !isDefined( level._zombie_melee ) )
	{
		level._zombie_melee = [];
	}
	if( !isDefined( level._zombie_walk_melee ) )
	{
		level._zombie_walk_melee = [];
	}
	if( !isDefined( level._zombie_run_melee ) )
	{
		level._zombie_run_melee = [];
	}

	level._zombie_melee["zombie"] = [];
	level._zombie_walk_melee["zombie"] = [];
	level._zombie_run_melee["zombie"] = [];

	level._zombie_melee["zombie"][0] 				= %ai_zombie_attack_forward_v1; 
	level._zombie_melee["zombie"][1] 				= %ai_zombie_attack_forward_v2; 
	level._zombie_melee["zombie"][2] 				= %ai_zombie_attack_v1; 
	level._zombie_melee["zombie"][3] 				= %ai_zombie_attack_v2;	
	level._zombie_melee["zombie"][4]				= %ai_zombie_attack_v1;
	level._zombie_melee["zombie"][5]				= %ai_zombie_attack_v4;
	level._zombie_melee["zombie"][6]				= %ai_zombie_attack_v6;	
	level._zombie_run_melee["zombie"][0]				=	%ai_zombie_run_attack_v1;
	level._zombie_run_melee["zombie"][1]				=	%ai_zombie_run_attack_v2;
	level._zombie_run_melee["zombie"][2]				=	%ai_zombie_run_attack_v3;
	level.scr_anim["zombie"]["walk5"] 	= %ai_zombie_walk_v6;
	level.scr_anim["zombie"]["walk6"] 	= %ai_zombie_walk_v7;
	level.scr_anim["zombie"]["walk7"] 	= %ai_zombie_walk_v8;
	level.scr_anim["zombie"]["walk8"] 	= %ai_zombie_walk_v9;

	if( isDefined( level.zombie_anim_override ) )
	{
		[[ level.zombie_anim_override ]]();
	}

	level._zombie_walk_melee["zombie"][0]			= %ai_zombie_walk_attack_v1;
	level._zombie_walk_melee["zombie"][1]			= %ai_zombie_walk_attack_v2;
	level._zombie_walk_melee["zombie"][2]			= %ai_zombie_walk_attack_v3;
	level._zombie_walk_melee["zombie"][3]			= %ai_zombie_walk_attack_v4;

	// melee in crawl
	if( !isDefined( level._zombie_melee_crawl ) )
	{
		level._zombie_melee_crawl = [];
	}
	level._zombie_melee_crawl["zombie"] = [];
	level._zombie_melee_crawl["zombie"][0] 		= %ai_zombie_attack_crawl; 
	level._zombie_melee_crawl["zombie"][1] 		= %ai_zombie_attack_crawl_lunge;

	if( !isDefined( level._zombie_stumpy_melee ) )
	{
		level._zombie_stumpy_melee = [];
	}
	level._zombie_stumpy_melee["zombie"] = [];
	level._zombie_stumpy_melee["zombie"][0] = %ai_zombie_walk_on_hands_shot_a;
	level._zombie_stumpy_melee["zombie"][1] = %ai_zombie_walk_on_hands_shot_b;
	//level._zombie_melee_crawl["zombie"][2]		= %ai_zombie_crawl_attack_A;

	// tesla deaths
	if( !isDefined( level._zombie_tesla_death ) )
	{
		level._zombie_tesla_death = [];
	}
	level._zombie_tesla_death["zombie"] = [];
	level._zombie_tesla_death["zombie"][0] = %ai_zombie_tesla_death_a;
	level._zombie_tesla_death["zombie"][1] = %ai_zombie_tesla_death_b;
	level._zombie_tesla_death["zombie"][2] = %ai_zombie_tesla_death_c;
	level._zombie_tesla_death["zombie"][3] = %ai_zombie_tesla_death_d;
	level._zombie_tesla_death["zombie"][4] = %ai_zombie_tesla_death_e;

	if( !isDefined( level._zombie_tesla_crawl_death ) )
	{
		level._zombie_tesla_crawl_death = [];
	}
	level._zombie_tesla_crawl_death["zombie"] = [];
	level._zombie_tesla_crawl_death["zombie"][0] = %ai_zombie_tesla_crawl_death_a;
	level._zombie_tesla_crawl_death["zombie"][1] = %ai_zombie_tesla_crawl_death_b;

	// deaths
	if( !isDefined( level._zombie_deaths ) )
	{
		level._zombie_deaths = [];
	}
	level._zombie_deaths["zombie"] = [];
	level._zombie_deaths["zombie"][0] = %ch_dazed_a_death;
	level._zombie_deaths["zombie"][1] = %ch_dazed_b_death;
	level._zombie_deaths["zombie"][2] = %ch_dazed_c_death;
	level._zombie_deaths["zombie"][3] = %ch_dazed_d_death;

	/*
	ground crawl
	*/

	if( !isDefined( level._zombie_rise_anims ) )
	{
		level._zombie_rise_anims = [];
	}

	// set up the arrays
	level._zombie_rise_anims["zombie"] = [];

	//level._zombie_rise_anims["zombie"][1]["walk"][0]		= %ai_zombie_traverse_ground_v1_crawl;
	level._zombie_rise_anims["zombie"][1]["walk"][0]		= %ai_zombie_traverse_ground_v1_walk;

	//level._zombie_rise_anims["zombie"][1]["run"][0]		= %ai_zombie_traverse_ground_v1_crawlfast;
	level._zombie_rise_anims["zombie"][1]["run"][0]		= %ai_zombie_traverse_ground_v1_run;

	level._zombie_rise_anims["zombie"][1]["sprint"][0]	= %ai_zombie_traverse_ground_climbout_fast;

	//level._zombie_rise_anims["zombie"][2]["walk"][0]		= %ai_zombie_traverse_ground_v2_walk;	//!broken
	level._zombie_rise_anims["zombie"][2]["walk"][0]		= %ai_zombie_traverse_ground_v2_walk_altA;
	//level._zombie_rise_anims["zombie"][2]["walk"][2]		= %ai_zombie_traverse_ground_v2_walk_altB;//!broken

	// ground crawl death
	if( !isDefined( level._zombie_rise_death_anims ) )
	{
		level._zombie_rise_death_anims = [];
	}
	
	level._zombie_rise_death_anims["zombie"] = [];

	level._zombie_rise_death_anims["zombie"][1]["in"][0]		= %ai_zombie_traverse_ground_v1_deathinside;
	level._zombie_rise_death_anims["zombie"][1]["in"][1]		= %ai_zombie_traverse_ground_v1_deathinside_alt;

	level._zombie_rise_death_anims["zombie"][1]["out"][0]		= %ai_zombie_traverse_ground_v1_deathoutside;
	level._zombie_rise_death_anims["zombie"][1]["out"][1]		= %ai_zombie_traverse_ground_v1_deathoutside_alt;

	level._zombie_rise_death_anims["zombie"][2]["in"][0]		= %ai_zombie_traverse_ground_v2_death_low;
	level._zombie_rise_death_anims["zombie"][2]["in"][1]		= %ai_zombie_traverse_ground_v2_death_low_alt;

	level._zombie_rise_death_anims["zombie"][2]["out"][0]		= %ai_zombie_traverse_ground_v2_death_high;
	level._zombie_rise_death_anims["zombie"][2]["out"][1]		= %ai_zombie_traverse_ground_v2_death_high_alt;
	
	//taunts
	if( !isDefined( level._zombie_run_taunt ) )
	{
		level._zombie_run_taunt = [];
	}
	if( !isDefined( level._zombie_board_taunt ) )
	{
		level._zombie_board_taunt = [];
	}
	level._zombie_run_taunt["zombie"] = [];
	level._zombie_board_taunt["zombie"] = [];
	
	//level._zombie_taunt["zombie"][0] = %ai_zombie_taunts_1;
	//level._zombie_taunt["zombie"][1] = %ai_zombie_taunts_4;
	//level._zombie_taunt["zombie"][2] = %ai_zombie_taunts_5b;
	//level._zombie_taunt["zombie"][3] = %ai_zombie_taunts_5c;
	//level._zombie_taunt["zombie"][4] = %ai_zombie_taunts_5d;
	//level._zombie_taunt["zombie"][5] = %ai_zombie_taunts_5e;
	//level._zombie_taunt["zombie"][6] = %ai_zombie_taunts_5f;
	//level._zombie_taunt["zombie"][7] = %ai_zombie_taunts_7;
	//level._zombie_taunt["zombie"][8] = %ai_zombie_taunts_9;
	//level._zombie_taunt["zombie"][8] = %ai_zombie_taunts_11;
	//level._zombie_taunt["zombie"][8] = %ai_zombie_taunts_12;
	
	level._zombie_board_taunt["zombie"][0] = %ai_zombie_taunts_4;
	level._zombie_board_taunt["zombie"][1] = %ai_zombie_taunts_7;
	level._zombie_board_taunt["zombie"][2] = %ai_zombie_taunts_9;
	level._zombie_board_taunt["zombie"][3] = %ai_zombie_taunts_5b;
	level._zombie_board_taunt["zombie"][4] = %ai_zombie_taunts_5c;
	level._zombie_board_taunt["zombie"][5] = %ai_zombie_taunts_5d;
	level._zombie_board_taunt["zombie"][6] = %ai_zombie_taunts_5e;
	level._zombie_board_taunt["zombie"][7] = %ai_zombie_taunts_5f;
}

init_anims()
{
	init_standard_zombie_anims();
}

factory_init_zombie_leaderboard_data()
{
	level.zombieLeaderboardStatVariable["nazi_zombie_factory"]["highestwave"] = "nz_factory_highestwave";
	level.zombieLeaderboardStatVariable["nazi_zombie_factory"]["timeinwave"] = "nz_factory_timeinwave";
	level.zombieLeaderboardStatVariable["nazi_zombie_factory"]["totalpoints"] = "nz_factory_totalpoints";

	level.zombieLeaderboardNumber["nazi_zombie_factory"]["waves"] = 19;
	level.zombieLeaderboardNumber["nazi_zombie_factory"]["points"] = 20;
}