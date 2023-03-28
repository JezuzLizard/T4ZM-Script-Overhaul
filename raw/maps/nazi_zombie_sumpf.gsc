#include common_scripts\utility; 
#include maps\_utility;
#include maps\so\zm_common\_zm_utility;
#include maps\_music;
#include maps\nazi_zombie_sumpf_perks;
#include maps\nazi_zombie_sumpf_zone_management;
#include maps\nazi_zombie_sumpf_magic_box;
#include maps\nazi_zombie_sumpf_trap_pendulum;
//#include maps\nazi_zombie_sumpf_trap_electric;
//#include maps\nazi_zombie_sumpf_trap_propeller;
//#include maps\nazi_zombie_sumpf_trap_barrel;
#include maps\nazi_zombie_sumpf_bouncing_betties;
#include maps\nazi_zombie_sumpf_zipline;
#include maps\nazi_zombie_sumpf_bridge;
//#include maps\nazi_zombie_sumpf_ammo_box;
#include maps\nazi_zombie_sumpf_blockers;
#include maps\nazi_zombie_sumpf_trap_perk_electric;

main()
{
	// make sure we randomize things in the map once
	level.randomize_perks = false;
	
	// JMA - used to modify the percentages of pulls of ray gun and tesla gun in magic box
	level.pulls_since_last_ray_gun = 0;
	level.pulls_since_last_tesla_gun = 0;
	level.player_drops_tesla_gun = false;
	
	//Needs to be first for CreateFX
	maps\nazi_zombie_sumpf_fx::main();
	
	// enable for dog rounds
	if ( !isDefined( level.dogs_enabled ) )
	{
		level.dogs_enabled = true;
	}
	if ( !isDefined( level.use_legacy_dogs ) )
	{
		level.use_legacy_dogs = true;
	}
	// enable for zombie risers within active player zones
	level.zombie_rise_spawners = [];
	
	// JV contains zombies allowed to be on fire
	level.burning_zombies = [];
	
	// JV volume and bridge for bridge riser blocker
	//level.bridgeriser = undefined;
	//level.brVolume = undefined;

	level.use_zombie_heroes = true;
		
	level thread maps\_callbacksetup::SetupCallbacks();
	
	//precachestring(&"ZOMBIE_BETTY_ALREADY_PURCHASED");
	precachestring(&"ZOMBIE_BETTY_HOWTO");
//	precachestring(&"ZOMBIE_AMMO_BOX");
	
	//ESM - red and green lights for the traps
	precachemodel("zombie_zapper_cagelight_red");
	precachemodel("zombie_zapper_cagelight_green");
	precacheshellshock("electrocution");
	
	//JV - shellshock for player zipline damage
	precacheshellshock("death");

	// If you want to modify/add to the weapons table, please copy over the so\zm_common\_zm_weapons init_weapons() and paste it here.
	// I recommend putting it in it's own function...
	// If not a MOD, you may need to provide new localized strings to reflect the proper cost.	
	if ( isDefined( level.zm_custom_map_include_weapons ) )
	{
		level [[ level.zm_custom_map_include_weapons ]]();
	}
	else 
	{
		include_weapons();
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
		level.zm_custom_map_leaderboard_init = ::sumpf_init_zombie_leaderboard_data;
	}
	if ( !isDefined( level.zm_custom_map_weapon_add_func ) )
	{
		level.zm_custom_map_weapon_add_func = ::sumpf_add_weapons;
	}
	if ( !isDefined( level.zm_custom_map_perk_models ) )
	{
		level.zm_custom_map_perk_models = [];
	}
	level.zm_custom_map_perk_models[ "juggernog" ] = "zombie_vending_jugg_on_price";
	level.zm_custom_map_perk_models[ "revive" ] = "zombie_vending_revive_on_price";
	level.zm_custom_map_perk_models[ "doubletap" ] = "zombie_vending_doubletap_price";
	level.zm_custom_map_perk_models[ "sleight" ] = "zombie_vending_sleight_on_price";
	maps\so\zm_common\perks\_zm_perk_doubletap::enable_doubletap_perk_for_level();
	maps\so\zm_common\perks\_zm_perk_juggernog::enable_juggernog_perk_for_level();
	maps\so\zm_common\perks\_zm_perk_revive::enable_revive_perk_for_level();
	maps\so\zm_common\perks\_zm_perk_sleight::enable_sleight_perk_for_level();
	if ( isDefined( level.zm_custom_map_perk_machines_func ) )
	{
		level [[ level.zm_custom_map_perk_machines_func ]]();
	}
	maps\so\zm_common\powerups\_zm_powerup_double_points::enable_double_points_powerup_for_level();
	maps\so\zm_common\powerups\_zm_powerup_full_ammo::enable_full_ammo_powerup_for_level();
	maps\so\zm_common\powerups\_zm_powerup_insta_kill::enable_insta_kill_powerup_for_level();
	maps\so\zm_common\powerups\_zm_powerup_nuke::enable_nuke_powerup_for_level();
	maps\so\zm_common\_zm_spawner_sumpf::init();
	maps\so\zm_common\_zm::init_zm();
	maps\nazi_zombie_sumpf_blockers::init();
	maps\so\zm_common\_zm_ai_dogs::init();
	if ( !isDefined( level.use_legacy_tesla_gun ) )
	{
		level.use_legacy_tesla_gun = true;
	}
	maps\so\zm_common\_zm_weap_tesla_gun::init();

	if ( !isDefined( level.default_visionset ) )
	{
		level.default_visionset = "zombie_sumpf";
	}

	//init_sounds();
	init_zombie_sumpf();
	
	level thread toilet_useage();
	level thread radio_one();
	level thread radio_two();
	level thread radio_three();
	level thread radio_eggs();
	level thread battle_radio();
	level thread whisper_radio();
	level thread meteor_trigger();
	level thread book_useage();
	// JMA - make sure tesla gun gets added into magic box after round 5
//	maps\so\zm_common\_zm_weapons::add_limited_weapon( "tesla_gun", 0);
	
//	level thread add_tesla_gun();
	
	players = getPlayers(); 
	
	//initialize killstreak dialog	
	for( i = 0; i < players.size; i++ )
	{
		players[i] thread player_killstreak_timer();
		
		//initialize zombie behind vox 
		players[i] thread player_zombie_awareness();
	}		

}
add_tesla_gun()
{
	while(1)
	{
		level waittill( "between_round_over" );
		if(level.round_number >= 5)
		{
			maps\so\zm_common\_zm_weapons::add_limited_weapon( "tesla_gun", 1);
			break;	
		}
	}
}


sumpf_add_weapons()
{
	// Zombify
	PrecacheItem( "zombie_melee" );


	// Pistols
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "colt", 									&"ZOMBIE_WEAPON_COLT_50", 					50,		"vox_crappy", 8 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "colt_dirty_harry", 						&"ZOMBIE_WEAPON_COLT_DH_100", 				100,	"vox_357", 5 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "nambu", 								&"ZOMBIE_WEAPON_NAMBU_50", 					50, 	"vox_crappy", 8 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "sw_357", 								&"ZOMBIE_WEAPON_SW357_100", 				100, 	"vox_357", 5 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "tokarev", 								&"ZOMBIE_WEAPON_TOKAREV_50", 				50, 	"vox_crappy", 8 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "walther", 								&"ZOMBIE_WEAPON_WALTHER_50", 				50, 	"vox_crappy", 8 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_colt", 							&"ZOMBIE_WEAPON_ZOMBIECOLT_25", 			25, 	"vox_crappy", 8 );

	// Bolt Action                                      		
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "kar98k", 								&"ZOMBIE_WEAPON_KAR98K_200", 				200,	"", 0);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "kar98k_bayonet", 						&"ZOMBIE_WEAPON_KAR98K_B_200", 				200,	"", 0);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mosin_rifle", 							&"ZOMBIE_WEAPON_MOSIN_200", 				200,	"", 0); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mosin_rifle_bayonet", 					&"ZOMBIE_WEAPON_MOSIN_B_200", 				200,	"", 0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "springfield", 							&"ZOMBIE_WEAPON_SPRINGFIELD_200", 			200,	"", 0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "springfield_bayonet", 					&"ZOMBIE_WEAPON_SPRINGFIELD_B_200", 		200,	"", 0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_type99_rifle", 							&"ZOMBIE_WEAPON_TYPE99_200", 				200,	"", 0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type99_rifle_bayonet", 					&"ZOMBIE_WEAPON_TYPE99_B_200", 				200,	"", 0 );

	// Semi Auto                                        		
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_gewehr43", 								&"ZOMBIE_WEAPON_GEWEHR43_600", 				600,	"" , 0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_m1carbine", 							&"ZOMBIE_WEAPON_M1CARBINE_600",				600,	"" , 0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "m1carbine_bayonet", 					&"ZOMBIE_WEAPON_M1CARBINE_B_600", 			600,	"" , 0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_m1garand", 								&"ZOMBIE_WEAPON_M1GARAND_600", 				600,	"" , 0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "m1garand_bayonet", 						&"ZOMBIE_WEAPON_M1GARAND_B_600", 			600,	"" , 0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "svt40", 								&"ZOMBIE_WEAPON_SVT40_600", 				600,	"" , 0 );

	// Grenades                                         		
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "fraggrenade", 							&"ZOMBIE_WEAPON_FRAGGRENADE_250", 			250,	"" , 0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "molotov", 								&"ZOMBIE_WEAPON_MOLOTOV_200", 				200,	"vox_crappy", 8 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "molotov_zombie", 								&"ZOMBIE_WEAPON_MOLOTOV_200", 				200,	"vox_crappy", 8 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "stick_grenade", 						&"ZOMBIE_WEAPON_STICKGRENADE_250", 			250,	"" , 0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "stielhandgranate", 						&"ZOMBIE_WEAPON_STIELHANDGRANATE_250", 		250,	"" , 0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type97_frag", 							&"ZOMBIE_WEAPON_TYPE97FRAG_250", 			250,	"" , 0 );

	// Scoped
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "kar98k_scoped_zombie", 					&"ZOMBIE_WEAPON_KAR98K_S_750", 				750,	"vox_ppsh", 5);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "kar98k_scoped_bayonet_zombie", 			&"ZOMBIE_WEAPON_KAR98K_S_B_750", 			750,	"vox_ppsh", 5);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mosin_rifle_scoped_zombie", 			&"ZOMBIE_WEAPON_MOSIN_S_750", 				750,	"vox_ppsh", 5);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mosin_rifle_scoped_bayonet_zombie", 	&"ZOMBIE_WEAPON_MOSIN_S_B_750", 			750,	"vox_ppsh", 5);
	//maps\so\zm_common\_zm_weapons::add_zombie_weapon( "ptrs41_zombie", 						&"ZOMBIE_WEAPON_PTRS41_750", 				750,	"vox_ppsh", 5);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "springfield_scoped_zombie", 			&"ZOMBIE_WEAPON_SPRINGFIELD_S_750", 		750,	"vox_ppsh", 5);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "springfield_scoped_bayonet_zombie", 	&"ZOMBIE_WEAPON_SPRINGFIELD_S_B_750", 		750,	"vox_ppsh", 5);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type99_rifle_scoped_zombie", 			&"ZOMBIE_WEAPON_TYPE99_S_750", 				750,	"vox_ppsh", 5);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type99_rifle_scoped_bayonet_zombie", 	&"ZOMBIE_WEAPON_TYPE99_S_B_750", 			750,	"vox_ppsh", 5);

	// Full Auto                                                                                	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_mp40", 								&"ZOMBIE_WEAPON_MP40_1000", 				1000,	"vox_mp40", 2 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_ppsh", 								&"ZOMBIE_WEAPON_PPSH_2000", 				2000,	"vox_ppsh", 5 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_stg44", 							&"ZOMBIE_WEAPON_STG44_1200", 				1200,	"vox_mg", 9 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_thompson", 							&"ZOMBIE_WEAPON_THOMPSON_1200", 			1200,	"", 0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_type100_smg", 						&"ZOMBIE_WEAPON_TYPE100_1000", 				1000,	"", 0 );

	// Shotguns                                         	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_doublebarrel", 						&"ZOMBIE_WEAPON_DOUBLEBARREL_1200", 		1200,	"vox_shotgun", 6);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_doublebarrel_sawed", 			&"ZOMBIE_WEAPON_DOUBLEBARREL_SAWED_1200", 	1200,	"vox_shotgun", 6);
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_shotgun", 							&"ZOMBIE_WEAPON_SHOTGUN_1500", 				1500,	"vox_shotgun", 6);

	// Heavy Machineguns                                	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_30cal", 							&"ZOMBIE_WEAPON_30CAL_3000", 				3000,	"vox_mg", 9 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_bar", 								&"ZOMBIE_WEAPON_BAR_1800", 					1800,	"vox_bar", 5 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "dp28", 								&"ZOMBIE_WEAPON_DP28_2250", 				2250,	"vox_mg" , 9 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_fg42", 								&"ZOMBIE_WEAPON_FG42_1500", 				1500,	"vox_mg" , 9 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "fg42_scoped", 						&"ZOMBIE_WEAPON_FG42_S_1500", 				1500,	"vox_mg" , 9 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "zombie_mg42", 								&"ZOMBIE_WEAPON_MG42_3000", 				3000,	"vox_mg" , 9 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type99_lmg", 						&"ZOMBIE_WEAPON_TYPE99_LMG_1750", 			1750,	"vox_mg" , 9 ); 

	// Grenade Launcher                                 	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "m1garand_gl_zombie", 						&"ZOMBIE_WEAPON_M1GARAND_GL_1500", 	1500,	"", 0 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mosin_launcher_zombie", 					&"ZOMBIE_WEAPON_MOSIN_GL_1200", 	1200,	"", 0 );

	// Bipods                               				
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "30cal_bipod", 						&"ZOMBIE_WEAPON_30CAL_BIPOD_3500", 			3500,	"vox_mg", 5 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "bar_bipod", 						&"ZOMBIE_WEAPON_BAR_BIPOD_2500", 			2500,	"vox_bar", 5 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "dp28_bipod", 						&"ZOMBIE_WEAPON_DP28_BIPOD_2500", 			2500,	"vox_mg", 5 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "fg42_bipod", 						&"ZOMBIE_WEAPON_FG42_BIPOD_2000", 			2000,	"vox_mg", 5 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mg42_bipod", 						&"ZOMBIE_WEAPON_MG42_BIPOD_3250", 			3250,	"vox_mg", 5 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "type99_lmg_bipod", 					&"ZOMBIE_WEAPON_TYPE99_LMG_BIPOD_2250", 	2250,	"vox_mg", 5 ); 

	// Rocket Launchers
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "bazooka", 							&"ZOMBIE_WEAPON_BAZOOKA_2000", 				2000,	"", 0 ); 
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "panzerschrek_zombie", 						&"ZOMBIE_WEAPON_PANZERSCHREK_2000", 		2000,	"vox_panzer", 5 ); 

	// Flamethrower                                     	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "m2_flamethrower_zombie", 			&"ZOMBIE_WEAPON_M2_FLAMETHROWER_3000", 		3000,	"vox_flame", 7);	

	// Special                                          	
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mortar_round", 						&"ZOMBIE_WEAPON_MORTARROUND_2000", 			2000,	"" );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "satchel_charge", 					&"ZOMBIE_WEAPON_SATCHEL_2000", 				2000,	"" );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "ray_gun", 							&"ZOMBIE_WEAPON_RAYGUN_10000", 				10000,	"vox_raygun", 6 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "tesla_gun",							&"ZOMBIE_BUY_TESLA", 						10,		"vox_tesla", 5 );
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "mine_bouncing_betty",&"ZOMBIE_WEAPON_SATCHEL_2000", 2000 );		
	maps\so\zm_common\_zm_weapons::add_zombie_weapon( "ptrs41_zombie", 						&"ZOMBIE_WEAPON_PTRS41_750", 				750,	"vox_sniper", 5);	

	Precachemodel("zombie_teddybear");
	
	// ONLY 1 OF THE BELOW SHOULD BE ALLOWED
	maps\so\zm_common\_zm_weapons::add_limited_weapon( "m2_flamethrower_zombie", 1 );
	maps\so\zm_common\_zm_weapons::add_limited_weapon( "tesla_gun", 1);
}   

// Include the weapons that are only inr your level so that the cost/hints are accurate
// Also adds these weapons to the random treasure chest.
include_weapons()
{
	// Pistols
	include_weapon( "zombie_colt" );
	include_weapon( "sw_357" );
	
	// Semi Auto
	include_weapon( "zombie_m1carbine" );
	include_weapon( "zombie_m1garand" );
	include_weapon( "zombie_gewehr43" );
	//include_weapon( "kar98k" );	// replaced with type99_rifle
	include_weapon( "zombie_type99_rifle" );

	// Full Auto
	include_weapon( "zombie_stg44" );
	include_weapon( "zombie_thompson" );
	include_weapon( "zombie_mp40" );
	include_weapon( "zombie_type100_smg" );

	// Bolt Action
	//include_weapon( "springfield" );	// replaced with type99_rifle

	// Scoped
	include_weapon( "ptrs41_zombie" );
	//include_weapon( "kar98k_scoped_zombie" );	// replaced with type99_rifle_scoped
	//include_weapon( "type99_rifle_scoped_zombie" );	//
		
	// Grenade
	include_weapon( "molotov" );
	include_weapon( "stielhandgranate" );

	// Grenade Launcher	
	include_weapon( "m1garand_gl_zombie" );
	include_weapon( "m7_launcher_zombie" );
	
	// Flamethrower
	include_weapon( "m2_flamethrower_zombie" );
	
	// Shotgun
	include_weapon( "zombie_doublebarrel" );
	include_weapon( "zombie_doublebarrel_sawed" );
	include_weapon( "zombie_shotgun" );

	// Heavy MG
	include_weapon( "zombie_bar" );
	include_weapon( "zombie_30cal" );
	include_weapon( "zombie_fg42" );
	include_weapon( "zombie_mg42" );
	include_weapon( "zombie_ppsh" );
	
	// Rocket Launcher
	include_weapon( "panzerschrek_zombie" );

	// Special
	include_weapon( "ray_gun" );
	include_weapon( "tesla_gun" );
	
	//bouncing betties
	include_weapon("mine_bouncing_betty", false);
	
	// limited weapons
	maps\so\zm_common\_zm_weapons::add_limited_weapon( "zombie_colt", 0 );
	maps\so\zm_common\_zm_weapons::add_limited_weapon( "zombie_type99_rifle", 0 );
	maps\so\zm_common\_zm_weapons::add_limited_weapon( "zombie_gewehr43", 0 );
	maps\so\zm_common\_zm_weapons::add_limited_weapon( "zombie_m1garand", 0 );
	
	register_tactical_grenade_for_level( "molotov" );
	level.zombie_tactical_grenade_player_init = undefined;
	register_wonder_weapon_for_level( "tesla_gun" );
	register_wonder_weapon_for_level( "ray_gun" );
}
	
spawn_initial_outside_zombies( name )
{
	// don't spawn in zombies in dog rounds
	if(flag("dog_round"))
		return;
		
	// make sure we spawn zombies only during the round and not between them
	while(get_enemy_count() == 0)
	{
		wait(1);
	}

	spawn_points = [];			
	spawn_points = GetEntArray(name,"targetname");
	
   for( i = 0; i < spawn_points.size; i++)
   {
		ai = spawn_zombie( spawn_points[i] );
		
		// JMA - make sure spawn_zombie doesn't fail
		if( IsDefined( ai ) )
		{
			ai maps\so\zm_common\_zm_spawner_sumpf::zombie_setup_attack_properties();
			ai thread maps\so\zm_common\_zm_spawner_sumpf::find_flesh();
			wait_network_frame();
		}
	}
}	

activate_door_flags(door, key)
{
     purchase_trigs = getEntArray(door, key);

     for( i = 0; i < purchase_trigs.size; i++)
     {
          if( !isDefined( level.flag[purchase_trigs[i].script_flag]))
          {
               flag_init(purchase_trigs[i].script_flag);
          }          
     }     
}

init_zombie_sumpf()
{
	//activate the initial exterior goals for the center bulding
	level.exterior_goals = getstructarray("exterior_goal","targetname");	
	
	for(i=0;i<level.exterior_goals.size;i++)
	{
		level.exterior_goals[i].is_active = 1;
	}

	// Setup the magic box
	thread maps\nazi_zombie_sumpf_magic_box::magic_box_init();	
	
	//managed zones are areas in the map that have associated spawners/goals that are turned on/off 
	//depending on where the players are in the map
	maps\nazi_zombie_sumpf_zone_management::activate_building_zones("center_building_upstairs","targetname");	
	
	// combining upstairs and downstairs into one zone
	level thread maps\nazi_zombie_sumpf_zone_management::combine_center_building_zones();
	
	// JMA - keep track of when the weapon box moves
	level thread maps\nazi_zombie_sumpf_magic_box::magic_box_tracker();		
	
	//ESM - new electricity traps
	level thread maps\nazi_zombie_sumpf_trap_perk_electric::init_elec_trap_trigs();
	
	// JMA - setup zipline deactivated trigger
	zipHintDeactivated = getent("zipline_deactivated_hint_trigger", "targetname");
	zipHintDeactivated sethintstring(&"ZOMBIE_ZIPLINE_DEACTIVATED");
	zipHintDeactivated SetCursorHint("HINT_NOICON");
	
	// JMA - setup log trap clear debris hint string
	penBuyTrigger = getentarray("pendulum_buy_trigger","targetname");
	
	for(i = 0; i < penBuyTrigger.size; i++)
	{		
		penBuyTrigger[i] sethintstring( &"ZOMBIE_CLEAR_DEBRIS" );
		penBuyTrigger[i] setCursorHint( "HINT_NOICON" );
	}
	
	//turning on the lights for the pen trap
	level thread maps\nazi_zombie_sumpf::turnLightRed("pendulum_light");	
	
	// set up the hanging dead guy in the attic
	//level thread hanging_dead_guy();
}


//ESM - added for green light/red light functionality for traps
turnLightGreen(name)
{
	zapper_lights = getentarray(name,"targetname");
	for(i=0;i<zapper_lights.size;i++)
	{
		zapper_lights[i] setmodel("zombie_zapper_cagelight_green");	
		if (isDefined(zapper_lights[i].target))
		{
			old_light_effect = getent(zapper_lights[i].target, "targetname");
			light_effect = spawn("script_model",old_light_effect.origin);
			//light_effect = spawn("script_model",zapper_lights[i].origin);
			light_effect setmodel("tag_origin");	
			light_effect.angles = (0,270,0);
			light_effect.targetname = "effect_" + name + i;
			old_light_effect delete();
			zapper_lights[i].target = light_effect.targetname;
			playfxontag(level._effect["zapper_light_ready"],light_effect,"tag_origin");
		}
	}
}

turnLightRed(name)
{
	zapper_lights = getentarray(name,"targetname");
	for(i=0;i<zapper_lights.size;i++)
	{
		zapper_lights[i] setmodel("zombie_zapper_cagelight_red");	
		if (isDefined(zapper_lights[i].target))
		{
			old_light_effect = getent(zapper_lights[i].target, "targetname");
			light_effect = spawn("script_model",old_light_effect.origin);
			//light_effect = spawn("script_model",zapper_lights[i].origin);
			light_effect setmodel("tag_origin");	
			light_effect.angles = (0,270,0);
			light_effect.targetname = "effect_" + name + i;
			old_light_effect delete();
			zapper_lights[i].target = light_effect.targetname;
			playfxontag(level._effect["zapper_light_notready"],light_effect,"tag_origin");
		}
	}
}
book_useage()
{
	book_counter = 0;
	book_trig = getent("book_trig", "targetname");
	book_trig SetCursorHint( "HINT_NOICON" );
	book_trig UseTriggerRequireLookAt();

	if(IsDefined(book_trig))
	{
		maniac_l = getent("maniac_l", "targetname");
		maniac_r = getent("maniac_r", "targetname");
		
		book_trig waittill( "trigger", player );
		
		if(IsDefined(maniac_l))
		{
			maniac_l playsound("maniac_l");
			
		}
		if(IsDefined(maniac_r))
		{
			maniac_r playsound("maniac_r");
			
		}
		
	}	
}
	
	
toilet_useage()
{

	toilet_counter = 0;
	toilet_trig = getent("toilet", "targetname");
	toilet_trig SetCursorHint( "HINT_NOICON" );
	toilet_trig UseTriggerRequireLookAt();
	
//	off_the_hook = spawn ("script_origin", toilet_trig.origin);
	toilet_trig playloopsound ("phone_hook");
	
	if (!IsDefined (level.eggs))
	{
		level.eggs = 0;
	}	

	toilet_trig waittill( "trigger", player );
	toilet_trig stoploopsound(0.5);
	toilet_trig playloopsound("phone_dialtone");

	wait(0.5);

	toilet_trig waittill( "trigger", player );
	toilet_trig stoploopsound(0.5);
	toilet_trig playsound("dial_9", "sound_done");
	toilet_trig waittill("sound_done");

	toilet_trig waittill( "trigger", player );
	toilet_trig playsound("dial_1", "sound_done");
	toilet_trig waittill("sound_done");

	toilet_trig waittill( "trigger", player );
	toilet_trig playsound("dial_1");
	wait(0.5);
	toilet_trig playsound("riiing");
	wait(1);
	toilet_trig playsound("riiing");
	wait(1);			
	toilet_trig playsound ("toilet_flush", "sound_done");				
	toilet_trig waittill ("sound_done");				
	playsoundatposition ("cha_ching", toilet_trig.origin);
	level.eggs = 1;
	setmusicstate("eggs");
	
	index = maps\so\zm_common\_zm_weapons::get_player_index(player);
	player_index = "plr_" + index + "_";
	if(!IsDefined (self.vox_audio_secret))
	{
		num_variants = maps\so\zm_common\_zm_audio::get_number_variants(player_index + "vox_audio_secret");
		self.vox_audio_secret = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_audio_secret[self.vox_audio_secret.size] = "vox_audio_secret_" + i;	
		}
		self.vox_audio_secret_available = self.vox_audio_secret;
	}
	
	
	/#
		player iprintln( "'Dead Air' Achievement Earned" );
	#/

	player giveachievement_wrapper( "DLC2_ZOMBIE_SECRET"); 
	
	sound_to_play = random(self.vox_audio_secret_available);
	self.vox_audio_secret_available = array_remove(self.vox_audio_secret_available,sound_to_play);	
	player maps\so\zm_common\_zm_audio::do_player_playdialog(player_index, sound_to_play, 0);
	
	wait(292);	
	setmusicstate("WAVE_1");
	level.eggs = 0;				
}
play_radio_sounds()
{
	radio_one = getent("radio_one_origin", "targetname");
	radio_two = getent("radio_two_origin", "targetname");
	radio_three = getent("radio_three_origin", "targetname");
	
	pa_system = getent("speaker_in_attic", "targetname");
	
	radio_one stoploopsound(2);
	radio_two stoploopsound(2);
	radio_three stoploopsound(2);
	
	wait(0.05);
	pa_system playsound("secret_message", "message_complete");
	pa_system waittill("message_complete");
	
	radio_one playsound ("static");
	radio_two playsound ("static");
	radio_three playsound ("static");
}
radio_eggs()
{
	if(!IsDefined (level.radio_counter))
	{
		level.radio_counter = 0;	
	}
	while(level.radio_counter < 3)
	{
		wait(2);	
	}
	level thread play_radio_sounds();
	
	
}
battle_radio()
{
	if(!IsDefined (level.radio_counter))
	{
		level.radio_counter = 0;	
	}

	battle_radio_trig = getent ("battle_radio_trigger", "targetname");
	battle_radio_trig UseTriggerRequireLookAt();
	battle_radio_trig SetCursorHint( "HINT_NOICON" );
	battle_radio_origin = getent("battle_radio_origin", "targetname");
	
	battle_radio_trig waittill( "trigger", player);		
	battle_radio_origin playsound ("battle_message");

}
whisper_radio()
{
	if(!IsDefined (level.radio_counter))
	{
		level.radio_counter = 0;	
	}

	whisper_radio_trig = getent ("whisper_radio_trigger", "targetname");
	whisper_radio_trig UseTriggerRequireLookAt();
	whisper_radio_trig SetCursorHint( "HINT_NOICON" );
	whisper_radio_origin = getent("whisper_radio_origin", "targetname");
	
	whisper_radio_trig waittill( "trigger");		
	whisper_radio_origin playsound ("whisper_message");

}
radio_one()
{
	if(!IsDefined (level.radio_counter))
	{
		level.radio_counter = 0;	
	}
	players = getplayers();
	
	radio_one_trig = getent ("radio_one", "targetname");
	radio_one_trig UseTriggerRequireLookAt();
	radio_one_trig SetCursorHint( "HINT_NOICON" );
	radio_one = getent("radio_one_origin", "targetname");
	
	for(i=0;i<players.size;i++)
	{			
		radio_one_trig waittill( "trigger", players);
		
		level.radio_counter = level.radio_counter + 1;
		radio_one playloopsound ("static_loop");

	}	
}
radio_two()
{
	if(!IsDefined (level.radio_counter))
	{
		level.radio_counter = 0;	
	}
	players = getplayers();
	radio_two_trig = getent ("radio_two", "targetname");
	radio_two_trig UseTriggerRequireLookAt();
	radio_two_trig SetCursorHint( "HINT_NOICON" );
	radio_two = getent("radio_two_origin", "targetname");
	
	
	for(i=0;i<players.size;i++)
	{			
		radio_two_trig waittill( "trigger", players);
		level.radio_counter = level.radio_counter + 1;
		radio_two playloopsound ("static_loop");
	
	}	
}
radio_three()
{
	if(!IsDefined (level.radio_counter))
	{
		level.radio_counter = 0;	
	}
	players = getplayers();
	radio_three_trig = getent ("radio_three_trigger", "targetname");
	radio_three_trig UseTriggerRequireLookAt();
	radio_three_trig SetCursorHint( "HINT_NOICON" ); 
	radio_three = getent("radio_three_origin", "targetname");
	for(i=0;i<players.size;i++)
	{			
		radio_three_trig waittill( "trigger", players);
		level.radio_counter = level.radio_counter + 1;			
		radio_three playloopsound ("static_loop");
		
	}	
}

/*hanging_dead_guy()
{
	//grab the hanging dead guy model
	dead_guy = getent("hanging_dead_guy","targetname");

	if(!isdefined(dead_guy))
		return;
		
	dead_guy physicslaunch ( dead_guy.origin, (randomintrange(-20,20),randomintrange(-20,20),randomintrange(-20,20)) );
}*/

meteor_trigger()
{
	level endon("meteor_triggered");
	dmgtrig = GetEnt( "meteor", "targetname" );
	player = getplayers();
	for(i=0;i<player.size;i++)
	{	
		while(1)
		{
			dmgtrig waittill("trigger", player);
			if(distancesquared(player.origin, dmgtrig.origin) < 1096 * 1096)
			{
				player thread meteor_dialog();
				level notify ("meteor_triggered");
			}
			else
			{
				wait(0.1);	
			}
		}
	}	
	
}
meteor_dialog()
{
	index = maps\so\zm_common\_zm_weapons::get_player_index(self);
	player_index = "plr_" + index + "_";
	sound_to_play = "vox_gen_meteor_0";
	self maps\so\zm_common\_zm_audio::do_player_playdialog(player_index,sound_to_play, 0.25);
}
player_zombie_awareness()
{
	self endon("disconnect");
	self endon("death");
	players = getplayers();
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
					self thread play_oh_shit_dialog();	
				}
			}
		}
		
	}
}		
play_oh_shit_dialog()
{
	//player = getplayers();	
	index = maps\so\zm_common\_zm_weapons::get_player_index(self);
	
	player_index = "plr_" + index + "_";
	if(!IsDefined (self.vox_oh_shit))
	{
		num_variants = maps\so\zm_common\_zm_audio::get_number_variants(player_index + "vox_oh_shit");
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
			
	self maps\so\zm_common\_zm_audio::do_player_playdialog(player_index, sound_to_play, 0.25);


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

	//level.scr_anim["zombie"]["run4"] 	= %ai_zombie_run_v1;
	
	//level.scr_anim["zombie"]["run6"] 	= %ai_zombie_run_v4;

	level.scr_anim["zombie"]["sprint1"] = %ai_zombie_sprint_v1;
	level.scr_anim["zombie"]["sprint2"] = %ai_zombie_sprint_v2;
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

	level._zombie_melee = [];
	level._zombie_walk_melee = [];
	level._zombie_run_melee = [];


	if(level.script == "nazi_zombie_sumpf")
	{

		/*level.scr_anim["zombie"]["walk1"] 	= %ai_zombie_jap_walk_A;
		level.scr_anim["zombie"]["walk2"] 	= %ai_zombie_jap_walk_B;*/




		level._zombie_melee[0] 				= %ai_zombie_jap_attack_v6; 
		level._zombie_melee[1] 				= %ai_zombie_jap_attack_v5; 
		level._zombie_melee[2] 				= %ai_zombie_jap_attack_v1; 
		level._zombie_melee[3] 				= %ai_zombie_jap_attack_v2;	
		level._zombie_melee[4]				= %ai_zombie_jap_attack_v3;
		level._zombie_melee[5]				= %ai_zombie_jap_attack_v4;

		level._zombie_run_melee[0]				=	%ai_zombie_jap_run_attack_v1;
		level._zombie_run_melee[1]				=	%ai_zombie_jap_run_attack_v2;

	/*	level.scr_anim["zombie"]["run1"] 	= %ai_zombie_jap_run_v1;
		level.scr_anim["zombie"]["run2"] 	= %ai_zombie_jap_run_v2;
		level.scr_anim["zombie"]["run3"] 	= %ai_zombie_jap_run_v4;*/
		level.scr_anim["zombie"]["run4"] 	= %ai_zombie_jap_run_v1;
		level.scr_anim["zombie"]["run5"] 	= %ai_zombie_jap_run_v2;
		level.scr_anim["zombie"]["run6"] 	= %ai_zombie_jap_run_v5;

		level.scr_anim["zombie"]["walk5"] 	= %ai_zombie_jap_walk_v1;
		level.scr_anim["zombie"]["walk6"] 	= %ai_zombie_jap_walk_v2;
		level.scr_anim["zombie"]["walk7"] 	= %ai_zombie_jap_walk_v3;
		level.scr_anim["zombie"]["walk8"] 	= %ai_zombie_jap_walk_v4;

		level.scr_anim["zombie"]["sprint3"] = %ai_zombie_jap_run_v3;
		level.scr_anim["zombie"]["sprint4"] = %ai_zombie_jap_run_v6;


	
	}
	else
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
		level.scr_anim["zombie"]["walk5"] 	= %ai_zombie_walk_v6;
		level.scr_anim["zombie"]["walk6"] 	= %ai_zombie_walk_v7;
		level.scr_anim["zombie"]["walk7"] 	= %ai_zombie_walk_v8;
		level.scr_anim["zombie"]["walk8"] 	= %ai_zombie_walk_v9;


		level.scr_anim["zombie"]["run4"] 	= %ai_zombie_run_v2;
		level.scr_anim["zombie"]["run5"] 	= %ai_zombie_run_v4;


	}

	

	level._zombie_walk_melee[0]			= %ai_zombie_walk_attack_v1;
	level._zombie_walk_melee[1]			= %ai_zombie_walk_attack_v2;
	level._zombie_walk_melee[2]			= %ai_zombie_walk_attack_v3;
	level._zombie_walk_melee[3]			= %ai_zombie_walk_attack_v4;

	// melee in crawl
	level._zombie_melee_crawl = [];
	level._zombie_melee_crawl[0] 		= %ai_zombie_attack_crawl; 
	level._zombie_melee_crawl[1] 		= %ai_zombie_attack_crawl_lunge;

	level._zombie_stumpy_melee = [];
	level._zombie_stumpy_melee[0] = %ai_zombie_walk_on_hands_shot_a;
	level._zombie_stumpy_melee[1] = %ai_zombie_walk_on_hands_shot_b;
	//level._zombie_melee_crawl[2]		= %ai_zombie_crawl_attack_A;

	// tesla deaths
	level._zombie_tesla_death = [];
	level._zombie_tesla_death[0] = %ai_zombie_tesla_death_a;
	level._zombie_tesla_death[1] = %ai_zombie_tesla_death_b;
	level._zombie_tesla_death[2] = %ai_zombie_tesla_death_c;
	level._zombie_tesla_death[3] = %ai_zombie_tesla_death_d;
	level._zombie_tesla_death[4] = %ai_zombie_tesla_death_e;

	level._zombie_tesla_crawl_death = [];
	level._zombie_tesla_crawl_death[0] = %ai_zombie_tesla_crawl_death_a;
	level._zombie_tesla_crawl_death[1] = %ai_zombie_tesla_crawl_death_b;


	/*
	ground crawl
	*/

	// set up the arrays
	level._zombie_rise_anims = [];

	//level._zombie_rise_anims[1]["walk"][0]		= %ai_zombie_traverse_ground_v1_crawl;
	level._zombie_rise_anims[1]["walk"][0]		= %ai_zombie_traverse_ground_v1_walk;

	//level._zombie_rise_anims[1]["run"][0]		= %ai_zombie_traverse_ground_v1_crawlfast;
	level._zombie_rise_anims[1]["run"][0]		= %ai_zombie_traverse_ground_v1_run;

	level._zombie_rise_anims[1]["sprint"][0]	= %ai_zombie_traverse_ground_climbout_fast;

	//level._zombie_rise_anims[2]["walk"][0]		= %ai_zombie_traverse_ground_v2_walk;	//!broken
	level._zombie_rise_anims[2]["walk"][0]		= %ai_zombie_traverse_ground_v2_walk_altA;
	//level._zombie_rise_anims[2]["walk"][2]		= %ai_zombie_traverse_ground_v2_walk_altB;//!broken

	// ground crawl death
	level._zombie_rise_death_anims = [];

	level._zombie_rise_death_anims[1]["in"][0]		= %ai_zombie_traverse_ground_v1_deathinside;
	level._zombie_rise_death_anims[1]["in"][1]		= %ai_zombie_traverse_ground_v1_deathinside_alt;

	level._zombie_rise_death_anims[1]["out"][0]		= %ai_zombie_traverse_ground_v1_deathoutside;
	level._zombie_rise_death_anims[1]["out"][1]		= %ai_zombie_traverse_ground_v1_deathoutside_alt;

	level._zombie_rise_death_anims[2]["in"][0]		= %ai_zombie_traverse_ground_v2_death_low;
	level._zombie_rise_death_anims[2]["in"][1]		= %ai_zombie_traverse_ground_v2_death_low_alt;

	level._zombie_rise_death_anims[2]["out"][0]		= %ai_zombie_traverse_ground_v2_death_high;
	level._zombie_rise_death_anims[2]["out"][1]		= %ai_zombie_traverse_ground_v2_death_high_alt;
	
	//taunts
	level._zombie_run_taunt = [];
	level._zombie_board_taunt = [];
	
	//level._zombie_taunt[0] = %ai_zombie_taunts_1;
	//level._zombie_taunt[1] = %ai_zombie_taunts_4;
	//level._zombie_taunt[2] = %ai_zombie_taunts_5b;
	//level._zombie_taunt[3] = %ai_zombie_taunts_5c;
	//level._zombie_taunt[4] = %ai_zombie_taunts_5d;
	//level._zombie_taunt[5] = %ai_zombie_taunts_5e;
	//level._zombie_taunt[6] = %ai_zombie_taunts_5f;
	//level._zombie_taunt[7] = %ai_zombie_taunts_7;
	//level._zombie_taunt[8] = %ai_zombie_taunts_9;
	//level._zombie_taunt[8] = %ai_zombie_taunts_11;
	//level._zombie_taunt[8] = %ai_zombie_taunts_12;
	
	level._zombie_board_taunt[0] = %ai_zombie_taunts_4;
	level._zombie_board_taunt[1] = %ai_zombie_taunts_7;
	level._zombie_board_taunt[2] = %ai_zombie_taunts_9;
	level._zombie_board_taunt[3] = %ai_zombie_taunts_5b;
	level._zombie_board_taunt[4] = %ai_zombie_taunts_5c;
	level._zombie_board_taunt[5] = %ai_zombie_taunts_5d;
	level._zombie_board_taunt[6] = %ai_zombie_taunts_5e;
	level._zombie_board_taunt[7] = %ai_zombie_taunts_5f;

}
		
sumpf_init_zombie_leaderboard_data()
{
	level.zombieLeaderboardStatVariable["nazi_zombie_sumpf"]["highestwave"] = "nz_sumpf_highestwave";
	level.zombieLeaderboardStatVariable["nazi_zombie_sumpf"]["timeinwave"] = "nz_sumpf_timeinwave";
	level.zombieLeaderboardStatVariable["nazi_zombie_sumpf"]["totalpoints"] = "nz_sumpf_totalpoints";

	level.zombieLeaderboardNumber["nazi_zombie_sumpf"]["waves"] = 17;
	level.zombieLeaderboardNumber["nazi_zombie_sumpf"]["points"] = 18;
}

