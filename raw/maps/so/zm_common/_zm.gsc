#include maps\_utility; 
#include common_scripts\utility;

#using_animtree( "generic_human" ); 

init()
{
	common_precache();

	init_strings();
	init_levelvars();
	init_animscripts();
	init_sounds();
	init_shellshocks();

	level.zombie_ai_limit = 24;
	SetAILimit( level.zombie_ai_limit );

	if( !IsDefined( level.init_zombie_spawner_name ) )
	{
		level.enemy_spawns = 		getEntArray( "zombie_spawner_init", 	"targetname" ); 
	}
	else
	{
		level.enemy_spawns = 		getEntArray( level.init_zombie_spawner_name, 	"targetname" ); 
	}

	level.zombie_rise_spawners = [];

	if ( !isDefined( level.custom_introscreen ) )
	{
		level.custom_introscreen = ::zombie_intro_screen; 
	}
	
	level.custom_intermission = ::player_intermission; 
	level.reset_clientdvars = ::onPlayerConnect_clientDvars;

	if ( isDefined( level.zm_custom_map_fx_init ) )
	{
		level [[ level.zm_custom_map_fx_init ]]();
	}

	maps\_load::main();

	level.hudelem_count = 0;

	maps\_zombiemode_weapons::init();
	maps\_zombiemode_blockers::init();
	maps\_zombiemode_spawner::init();
	maps\_zombiemode_powerups::init();
	//maps\_zombiemode_perks::init();
	if ( isDefined( level.zm_custom_map_script_func ) )
	{
		level [[ level.zm_custom_map_script_func ]]();
	}

	maps\_utility::registerClientSys("zombify");

	if ( isDefined( level.zm_custom_map_anim_init ) )
	{
		level [[ level.zm_custom_map_anim_init ]]();
	}

	if( isDefined( level.custom_ai_type ) )
	{
		for( i = 0; i < level.custom_ai_type.size; i++ )
		{
			[[ level.custom_ai_type[i] ]]();
		}
	}

	level.playerlaststand_func = ::player_laststand;
	level.global_damage_func = maps\_zombiemode_spawner::zombie_damage; 
	level.global_damage_func_ads = maps\_zombiemode_spawner::zombie_damage_ads;
	level.overridePlayerKilled = ::player_killed_override;
	level.overridePlayerDamage = ::player_damage_override;

	level.melee_miss_func = ::zombiemode_melee_miss;

	if( !IsDefined( level.Player_Spawn_func ) )
	{
		level.Player_Spawn_func = ::coop_player_spawn_placement;
	}
	
	level thread [[level.Player_Spawn_func]]();

	level.is_zombie_level = true; 
	level.player_becomes_zombie = ::zombify_player; 

	// so we dont get the uber colt when we're knocked out
	level.laststandpistol = "colt";

	level.round_start_time = 0;

	level thread onPlayerConnect(); 

	init_dvars();
	
	if ( isDefined( level.zm_custom_map_leaderboard_init ) )
	{
		level [[ level.zm_custom_map_leaderboard_init ]]();
	}

	level thread on_all_players_ready();
}

on_all_players_ready()
{
	flag_wait( "all_players_connected" );
	bbPrint( "sessions: mapname %s gametype zom isserver 1", level.script );
	level thread end_game();
	level thread round_start();
	level thread players_playing();

	//chrisp - adding spawning vo 
	level thread spawn_vo();
	
	//add ammo tracker for VO
	level thread track_players_ammo_count();

	//level thread prevent_near_origin();

	DisableGrenadeSuicide();

	level.startInvulnerableTime = GetDvarInt( "player_deathInvulnerableTime" );

	if(!IsDefined(level.eggs) )
	{
		level.eggs = 0;
	}
}

common_precache()
{
	PrecacheShader( "hud_chalk_1" );
	PrecacheShader( "hud_chalk_2" );
	PrecacheShader( "hud_chalk_3" );
	PrecacheShader( "hud_chalk_4" );
	PrecacheShader( "hud_chalk_5" );

	precachemodel( "char_ger_honorgd_zomb_behead" ); 
	precachemodel( "char_ger_zombieeye" ); 
	PrecacheModel( "tag_origin" );

	PrecacheItem( "fraggrenade" );
	PrecacheItem( "colt" );

	if ( isDefined( level.zm_custom_map_precache ) )
	{
		level [[ level.zm_custom_map_precache ]]();
	}
}

init_strings()
{
	PrecacheString( &"ZOMBIE_WEAPONCOSTAMMO" );
	PrecacheString( &"ZOMBIE_ROUND" );
	PrecacheString( &"SCRIPT_PLUS" );
	PrecacheString( &"ZOMBIE_GAME_OVER" );
	PrecacheString( &"ZOMBIE_SURVIVED_ROUND" );
	PrecacheString( &"ZOMBIE_SURVIVED_ROUNDS" );

	add_zombie_hint( "undefined", &"ZOMBIE_UNDEFINED" );

	// Random Treasure Chest
	add_zombie_hint( "default_treasure_chest_950", &"ZOMBIE_RANDOM_WEAPON_950" );

	// Barrier Pieces
	add_zombie_hint( "default_buy_barrier_piece_10", &"ZOMBIE_BUTTON_BUY_BACK_BARRIER_10" );
	add_zombie_hint( "default_buy_barrier_piece_20", &"ZOMBIE_BUTTON_BUY_BACK_BARRIER_20" );
	add_zombie_hint( "default_buy_barrier_piece_50", &"ZOMBIE_BUTTON_BUY_BACK_BARRIER_50" );
	add_zombie_hint( "default_buy_barrier_piece_100", &"ZOMBIE_BUTTON_BUY_BACK_BARRIER_100" );

	// REWARD Barrier Pieces
	add_zombie_hint( "default_reward_barrier_piece", &"ZOMBIE_BUTTON_REWARD_BARRIER" );
	add_zombie_hint( "default_reward_barrier_piece_10", &"ZOMBIE_BUTTON_REWARD_BARRIER_10" );
	add_zombie_hint( "default_reward_barrier_piece_20", &"ZOMBIE_BUTTON_REWARD_BARRIER_20" );
	add_zombie_hint( "default_reward_barrier_piece_30", &"ZOMBIE_BUTTON_REWARD_BARRIER_30" );
	add_zombie_hint( "default_reward_barrier_piece_40", &"ZOMBIE_BUTTON_REWARD_BARRIER_40" );
	add_zombie_hint( "default_reward_barrier_piece_50", &"ZOMBIE_BUTTON_REWARD_BARRIER_50" );

	// Debris
	add_zombie_hint( "default_buy_debris_100", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_100" );
	add_zombie_hint( "default_buy_debris_200", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_200" );
	add_zombie_hint( "default_buy_debris_250", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_250" );
	add_zombie_hint( "default_buy_debris_500", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_500" );
	add_zombie_hint( "default_buy_debris_750", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_750" );
	add_zombie_hint( "default_buy_debris_1000", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_1000" );
	add_zombie_hint( "default_buy_debris_1250", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_1250" );
	add_zombie_hint( "default_buy_debris_1500", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_1500" );
	add_zombie_hint( "default_buy_debris_1750", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_1750" );
	add_zombie_hint( "default_buy_debris_2000", &"ZOMBIE_BUTTON_BUY_CLEAR_DEBRIS_2000" );

	// Doors
	add_zombie_hint( "default_buy_door_100", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_100" );
	add_zombie_hint( "default_buy_door_200", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_200" );
	add_zombie_hint( "default_buy_door_250", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_250" );
	add_zombie_hint( "default_buy_door_500", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_500" );
	add_zombie_hint( "default_buy_door_750", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_750" );
	add_zombie_hint( "default_buy_door_1000", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_1000" );
	add_zombie_hint( "default_buy_door_1250", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_1250" );
	add_zombie_hint( "default_buy_door_1500", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_1500" );
	add_zombie_hint( "default_buy_door_1750", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_1750" );
	add_zombie_hint( "default_buy_door_2000", &"ZOMBIE_BUTTON_BUY_OPEN_DOOR_2000" );

	// Areas
	add_zombie_hint( "default_buy_area_100", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_100" );
	add_zombie_hint( "default_buy_area_200", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_200" );
	add_zombie_hint( "default_buy_area_250", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_250" );
	add_zombie_hint( "default_buy_area_500", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_500" );
	add_zombie_hint( "default_buy_area_750", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_750" );
	add_zombie_hint( "default_buy_area_1000", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_1000" );
	add_zombie_hint( "default_buy_area_1250", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_1250" );
	add_zombie_hint( "default_buy_area_1500", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_1500" );
	add_zombie_hint( "default_buy_area_1750", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_1750" );
	add_zombie_hint( "default_buy_area_2000", &"ZOMBIE_BUTTON_BUY_OPEN_AREA_2000" );
}

init_levelvars()
{
	level.intermission = false;
	level.dog_intermission = false;
	level.zombie_total = 0;
	level.no_laststandmissionfail = true;

	level.zombie_vars = [];

	// Default to not zombify the player till further support
	set_zombie_var( "zombify_player", 					false );

	set_zombie_var( "below_world_check", 				-1000 );

	// Respawn in the spectators in between rounds
	set_zombie_var( "spectators_respawn", 				true );

	// Round	
	set_zombie_var( "zombie_use_failsafe", 				true );
	set_zombie_var( "zombie_round_time", 				30 );
	set_zombie_var( "zombie_between_round_time", 		10 );
	set_zombie_var( "zombie_intermission_time", 		15 );

	// Spawning
	set_zombie_var( "zombie_spawn_delay", 				2 );

	

	// AI 
	set_zombie_var( "zombie_health_increase", 			100 );
	set_zombie_var( "zombie_health_increase_percent", 	10, 	100 );
	set_zombie_var( "zombie_health_start", 				150 );
	set_zombie_var( "zombie_max_ai", 					24 );
	set_zombie_var( "zombie_ai_per_player", 			6 );

	// Scoring
	set_zombie_var( "zombie_score_start", 				500 );
/#
	if( GetDvarInt( "zombie_cheat" ) >= 1 )
	{
		set_zombie_var( "zombie_score_start", 			100000 );
	}
#/
	set_zombie_var( "zombie_score_kill", 				50 );
	set_zombie_var( "zombie_score_damage", 				5 );
	set_zombie_var( "zombie_score_bonus_melee", 		80 );
	set_zombie_var( "zombie_score_bonus_head", 			50 );
	set_zombie_var( "zombie_score_bonus_neck", 			20 );
	set_zombie_var( "zombie_score_bonus_torso", 		10 );
	set_zombie_var( "zombie_score_bonus_burn", 			10 );

	set_zombie_var( "penalty_no_revive_percent", 		10, 	100 );
	set_zombie_var( "penalty_died_percent", 			0, 		100 );
	set_zombie_var( "penalty_downed_percent", 			5, 		100 );	

	set_zombie_var( "zombie_flame_dmg_point_delay",		500 );	

	if ( IsSplitScreen() )
	{
		set_zombie_var( "zombie_timer_offset", 			280 );	// hud offsets
	}
}

init_animscripts()
{
	// Setup the animscripts, then override them (we call this just incase an AI has not yet spawned)
	animscripts\init::firstInit();

	anim.idleAnimArray		["stand"] = [];
	anim.idleAnimWeights	["stand"] = [];
	anim.idleAnimArray		["stand"][0][0] 	= %ai_zombie_idle_v1_delta;
	anim.idleAnimWeights	["stand"][0][0] 	= 10;

	anim.idleAnimArray		["crouch"] = [];
	anim.idleAnimWeights	["crouch"] = [];	
	anim.idleAnimArray		["crouch"][0][0] 	= %ai_zombie_idle_crawl_delta;
	anim.idleAnimWeights	["crouch"][0][0] 	= 10;
}

init_sounds()
{
	add_sound( "end_of_round", "round_over" );
	add_sound( "end_of_game", "mx_game_over" ); //Had to remove this and add a music state switch so that we can add other musical elements.
	add_sound( "chalk_one_up", "chalk" );
	add_sound( "purchase", "cha_ching" );
	add_sound( "no_purchase", "no_cha_ching" );

	// Zombification
	// TODO need to vary these up
	add_sound( "playerzombie_usebutton_sound", "attack_vocals" );
	add_sound( "playerzombie_attackbutton_sound", "attack_vocals" );
	add_sound( "playerzombie_adsbutton_sound", "attack_vocals" );

	// Head gib
	add_sound( "zombie_head_gib", "zombie_head_gib" );

	// Blockers
	add_sound( "rebuild_barrier_piece", "repair_boards" );
	add_sound( "rebuild_barrier_hover", "boards_float" );
	add_sound( "debris_hover_loop", "couch_loop" );
	add_sound( "break_barrier_piece", "break_boards" );
	add_sound("blocker_end_move", "board_slam");
	add_sound( "barrier_rebuild_slam", "board_slam" );

	// Doors
	add_sound( "door_slide_open", "door_slide_open" );
	add_sound( "door_rotate_open", "door_slide_open" );

	// Debris
	add_sound( "debris_move", "weap_wall" );

	// Random Weapon Chest
	add_sound( "open_chest", "lid_open" );
	add_sound( "music_chest", "music_box" );
	add_sound( "close_chest", "lid_close" );

	// Weapons on walls
	add_sound( "weapon_show", "weap_wall" );

}

init_shellshocks()
{
	level.player_killed_shellshock = "zombie_death";
	PrecacheShellshock( level.player_killed_shellshock );
}

zombie_intro_screen( string1, string2, string3, string4, string5 )
{
	flag_wait( "all_players_connected" );
	wait( 1 );
	setmusicstate( "SPLASH_SCREEN" );
	wait (0.2);
}

player_intermission()
{
	self closeMenu();
	self closeInGameMenu();

	level endon( "stop_intermission" );
	self endon("disconnect");
	self endon("death");

	//Show total gained point for end scoreboard and lobby
	self.score = self.score_total;

	self.sessionstate = "intermission";
	self.spectatorclient = -1; 
	self.killcamentity = -1; 
	self.archivetime = 0; 
	self.psoffsettime = 0; 
	self.friendlydamage = undefined;

	points = getstructarray( "intermission", "targetname" );

	if( !IsDefined( points ) || points.size == 0 )
	{
		points = getentarray( "info_intermission", "classname" ); 
		if( points.size < 1 )
		{
			println( "NO info_intermission POINTS IN MAP" ); 
			return;
		}	
	}

	self.game_over_bg = NewClientHudelem( self );
	self.game_over_bg.horzAlign = "fullscreen";
	self.game_over_bg.vertAlign = "fullscreen";
	self.game_over_bg SetShader( "black", 640, 480 );
	self.game_over_bg.alpha = 1;

	org = undefined;
	while( 1 )
	{
		points = array_randomize( points );
		for( i = 0; i < points.size; i++ )
		{
			point = points[i];
			// Only spawn once if we are using 'moving' org
			// If only using info_intermissions, this will respawn after 5 seconds.
			if( !IsDefined( org ) )
			{
				self Spawn( point.origin, point.angles );
			}

			// Only used with STRUCTS
			if( IsDefined( points[i].target ) )
			{
				if( !IsDefined( org ) )
				{
					org = Spawn( "script_origin", self.origin + ( 0, 0, -60 ) );
				}

				self LinkTo( org, "", ( 0, 0, -60 ), ( 0, 0, 0 ) );
				self SetPlayerAngles( points[i].angles );
				org.origin = points[i].origin;

				speed = 20;
				if( IsDefined( points[i].speed ) )
				{
					speed = points[i].speed;
				}

				target_point = getstruct( points[i].target, "targetname" );
				dist = Distance( points[i].origin, target_point.origin );
				time = dist / speed;

				q_time = time * 0.25;
				if( q_time > 1 )
				{
					q_time = 1;
				}

				self.game_over_bg FadeOverTime( q_time );
				self.game_over_bg.alpha = 0;

				org MoveTo( target_point.origin, time, q_time, q_time );
				org RotateTo( target_point.angles, time, q_time, q_time );
				wait( time - q_time );

				self.game_over_bg FadeOverTime( q_time );
				self.game_over_bg.alpha = 1;

				wait( q_time );
			}
			else
			{
				self.game_over_bg FadeOverTime( 1 );
				self.game_over_bg.alpha = 0;

				wait( 5 );

				self.game_over_bg FadeOverTime( 1 );
				self.game_over_bg.alpha = 1;

				wait( 1 );
			}
		}
	}
}

onPlayerConnect_clientDvars()
{
	self SetClientDvars( "cg_deadChatWithDead", "1",
		"cg_deadChatWithTeam", "1",
		"cg_deadHearTeamLiving", "1",
		"cg_deadHearAllLiving", "1",
		"cg_everyoneHearsEveryone", "1",
		"compass", "0",
		"hud_showStance", "0",
		"cg_thirdPerson", "0",
		"cg_fov", "65",
		"cg_thirdPersonAngle", "0",
		"ammoCounterHide", "0",
		"miniscoreboardhide", "0",
		"ui_hud_hardcore", "0" );

	self SetDepthOfField( 0, 0, 512, 4000, 4, 0 );
}

player_laststand()
{
	self maps\_zombiemode_score::player_downed_penalty();

	if( IsDefined( self.intermission ) && self.intermission )
	{
		maps\_challenges_coop::doMissionCallback( "playerDied", self );

		level waittill( "forever" );
	}
}

player_killed_override()
{
}

player_damage_override( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime )
{
	/*	
	if(self hasperk("specialty_armorvest") && eAttacker != self)
	{
			iDamage = iDamage * 0.75;
			iprintlnbold(idamage);
	}*/
	
	if( sMeansOfDeath == "MOD_FALLING" )
	{
		sMeansOfDeath = "MOD_EXPLOSIVE";
	}

	if( isDefined( eAttacker ) )
	{
		if( isDefined( self.ignoreAttacker ) && self.ignoreAttacker == eAttacker ) 
		{
			return;
		}
		
		if( isDefined( eAttacker.is_zombie ) && eAttacker.is_zombie )
		{
			self.ignoreAttacker = eAttacker;
			self thread remove_ignore_attacker();
		}
		
		if( isDefined( eAttacker.damage_mult ) )
		{
			iDamage *= eAttacker.damage_mult;
		}
		eAttacker notify( "hit_player" );
	}
	finalDamage = iDamage;

	if( sMeansOfDeath == "MOD_PROJECTILE" || sMeansOfDeath == "MOD_PROJECTILE_SPLASH" || sMeansOfDeath == "MOD_GRENADE" || sMeansOfDeath == "MOD_GRENADE_SPLASH" )
	{
		if( self.health > 75 )
		{
			finalDamage = 75;
			self maps\_callbackglobal::finishPlayerDamageWrapper( eInflictor, eAttacker, finalDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime ); 
			return;
		}
	}

	if( iDamage < self.health )
	{
		if ( IsDefined( eAttacker ) )
		{
			eAttacker.sound_damage_player = self;
		}
		
		//iprintlnbold(iDamage);
		self maps\_callbackglobal::finishPlayerDamageWrapper( eInflictor, eAttacker, finalDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime ); 
		return;
	}
	if( level.intermission )
	{
		level waittill( "forever" );
	}

	players = get_players();
	count = 0;
	for( i = 0; i < players.size; i++ )
	{
		if( players[i] == self || players[i].is_zombie || players[i] maps\_laststand::player_is_in_laststand() || players[i].sessionstate == "spectator" )
		{
			count++;
		}
	}

	if( count < players.size )
	{
		self maps\_callbackglobal::finishPlayerDamageWrapper( eInflictor, eAttacker, finalDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime ); 
		return;
	}

	self.intermission = true;

	self thread maps\_laststand::PlayerLastStand( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime );
	self player_fake_death();

	if( count == players.size )
	{
		level notify( "end_game" );
	}
	else
	{
		self maps\_callbackglobal::finishPlayerDamageWrapper( eInflictor, eAttacker, finalDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime ); 
	}
}

remove_ignore_attacker()
{
	self notify( "new_ignore_attacker" );
	self endon( "new_ignore_attacker" );
	self endon( "disconnect" );
	
	if( !isDefined( level.ignore_enemy_timer ) )
	{
		level.ignore_enemy_timer = 0.4;
	}
	
	wait( level.ignore_enemy_timer );
	
	self.ignoreAttacker = undefined;
}

player_fake_death()
{
	level notify ("fake_death");
	self notify ("fake_death");

	self TakeAllWeapons();
	self AllowStand( false );
	self AllowCrouch( false );
	self AllowProne( true );

	self.ignoreme = true;
	self EnableInvulnerability();

	wait( 1 );
	self FreezeControls( true );
}

zombiemode_melee_miss()
{
	if( isDefined( self.enemy.curr_pay_turret ) )
	{
		self.enemy DoDamage( (60 / GetDvarFloat("player_damageMultiplier")), self.origin, self, self );
	}
}

coop_player_spawn_placement()
{
	structs = getstructarray( "initial_spawn_points", "targetname" ); 

	flag_wait( "all_players_connected" ); 

	//chrisp - adding support for overriding the default spawning method

	players = get_players(); 

	for( i = 0; i < players.size; i++ )
	{
		players[i] setorigin( structs[i].origin ); 
		players[i] setplayerangles( structs[i].angles ); 
		players[i].spectator_respawn = structs[i];
	}
}

zombify_player()
{
	self maps\_zombiemode_score::player_died_penalty(); 

	if( !IsDefined( level.zombie_vars["zombify_player"] ) || !level.zombie_vars["zombify_player"] )
	{
		self thread spawnSpectator(); 
		return; 
	}
}

onPlayerConnect()
{
	for( ;; )
	{
		level waittill( "connecting", player ); 

		player.entity_num = player GetEntityNumber(); 
		player thread onPlayerSpawned(); 
		player thread onPlayerDisconnect(); 
		player thread player_revive_monitor();

		//player thread watchGrenadeThrow();

		player.score = level.zombie_vars["zombie_score_start"]; 
		player.score_total = player.score; 
		player.old_score = player.score; 

		player.is_zombie = false; 
		player.initialized = false;
		player.zombification_time = 0;
	}
}

onPlayerSpawned()
{
	self endon( "disconnect" ); 

	for( ;; )
	{
		self waittill( "spawned_player" ); 

		

		self SetClientDvars( "cg_thirdPerson", "0", 
							 "cg_thirdPersonAngle", "0" );

		self SetDepthOfField( 0, 0, 512, 4000, 4, 0 );

		self maps\_zombiemode_utility::add_to_spectate_list();

		if( isdefined( self.initialized ) )
		{
			if( self.initialized == false )
			{
				self.initialized = true; 
				//				self maps\_zombiemode_score::create_player_score_hud(); 

				// set the initial score on the hud		
				self maps\_zombiemode_score::set_player_score_hud( true ); 
				self thread player_zombie_breadcrumb();

				//Init stat tracking variables
				self.stats["kills"] = 0;
				self.stats["score"] = 0;
				self.stats["downs"] = 0;
				self.stats["revives"] = 0;
				self.stats["perks"] = 0;
				self.stats["headshots"] = 0;
				self.stats["zombie_gibs"] = 0;
			}
		}
	}
}

player_zombie_breadcrumb()
{
	self endon( "disconnect" ); 
	self endon( "spawned_spectator" ); 
	level endon( "intermission" );

	self.zombie_breadcrumbs = []; 
	self.zombie_breadcrumb_distance = 24 * 24; // min dist (squared) the player must move to drop a crumb
	self.zombie_breadcrumb_area_num = 3;	   // the number of "rings" the area breadcrumbs use
	self.zombie_breadcrumb_area_distance = 16; // the distance between each "ring" of the area breadcrumbs

	self store_crumb( self.origin ); 
	last_crumb = self.origin;

	self thread debug_breadcrumbs(); 

	while( 1 )
	{
		wait_time = 0.1;
		
	/#
		if( self isnotarget() )
		{
			wait( wait_time ); 
			continue;
		}
	#/

		store_crumb = true; 
		airborne = false;
		crumb = self.origin;
		
		if ( !self IsOnGround() )
		{
			airborne = true;
			store_crumb = false; 
			wait_time = 0.05;
		}
		
		if( !airborne && DistanceSquared( crumb, last_crumb ) < self.zombie_breadcrumb_distance )
		{
			store_crumb = false; 
		}

		if ( airborne && self IsOnGround() )
		{
			// player was airborne, store crumb now that he's on the ground
			store_crumb = true;
			airborne = false;
		}

		// PI_CHANGE_BEGIN
		// JMA - we don't need to store new crumbs, the zipline will store our destination as a crumb
		if( (isDefined(level.script) && level.script == "nazi_zombie_sumpf" && (isDefined(self.on_zipline) && self.on_zipline == true)) )
		{
			airborne = false;
			store_crumb = false; 			
		}
		// PI_CHANGE_END

		if( store_crumb )
		{
			debug_print( "Player is storing breadcrumb " + crumb );
			last_crumb = crumb;
			self store_crumb( crumb );
		}

		wait( wait_time ); 
	}
}

store_crumb( origin )
{
	offsets = [];
	height_offset = 32;
	
	index = 0;
	for( j = 1; j <= self.zombie_breadcrumb_area_num; j++ )
	{
		offset = ( j * self.zombie_breadcrumb_area_distance );
		
		offsets[0] = ( origin[0] - offset, origin[1], origin[2] );
		offsets[1] = ( origin[0] + offset, origin[1], origin[2] );
		offsets[2] = ( origin[0], origin[1] - offset, origin[2] );
		offsets[3] = ( origin[0], origin[1] + offset, origin[2] );

		offsets[4] = ( origin[0] - offset, origin[1], origin[2] + height_offset );
		offsets[5] = ( origin[0] + offset, origin[1], origin[2] + height_offset );
		offsets[6] = ( origin[0], origin[1] - offset, origin[2] + height_offset );
		offsets[7] = ( origin[0], origin[1] + offset, origin[2] + height_offset );

		for ( i = 0; i < offsets.size; i++ )
		{
			self.zombie_breadcrumbs[index] = offsets[i];
			index++;
		}
	}
}

onPlayerDisconnect()
{
	self waittill( "disconnect" ); 
	self maps\_zombiemode_utility::remove_from_spectate_list();
}

player_revive_monitor()
{
	self endon( "disconnect" ); 

	while (1)
	{
		self waittill( "player_revived", reviver );	

		if ( IsDefined(reviver) )
		{
			// Check to see how much money you lost from being down.
			points = self.score_lost_when_downed;
			if ( points > 300 )
			{
				points = 300;
			}
			reviver maps\_zombiemode_score::add_to_player_score( points );
			self.score_lost_when_downed = 0;
		}
	}
}

init_dvars()
{
	level.zombiemode = true;

	//coder mod: tkeegan - new code dvar
	setSavedDvar( "zombiemode", "1" );
	SetDvar( "ui_gametype", "zom" );	
	setSavedDvar( "fire_world_damage", "0" );	
	setSavedDvar( "fire_world_damage_rate", "0" );	
	setSavedDvar( "fire_world_damage_duration", "0" );	

	if( GetDvar( "zombie_debug" ) == "" )
	{
		SetDvar( "zombie_debug", "0" );
	}

	if( GetDvar( "zombie_cheat" ) == "" )
	{
		SetDvar( "zombie_cheat", "0" );
	}
	
	if(getdvar("magic_chest_movable") == "")
	{
		SetDvar( "magic_chest_movable", "1" );
	}

	if(getdvar("magic_box_explore_only") == "")
	{
		SetDvar( "magic_box_explore_only", "1" );
	}

	SetDvar( "revive_trigger_radius", "60" ); 
}

init_flags()
{
    flag_init( "solo_game" );
    flag_init( "start_zombie_round_logic" );
    flag_init( "spawn_point_override" );
    flag_init( "power_on" );
    flag_init( "spawn_zombies", 1 );
    flag_init( "dog_round" );
    flag_init( "begin_spawning" );
    flag_init( "end_round_wait" );
    flag_init( "wait_and_revive" );
    flag_init( "instant_revive" );
    flag_init( "initial_blackscreen_passed" );
    flag_init( "initial_players_connected" );
}

end_game()
{
	level waittill ( "end_game" );

	level.intermission = true;

	update_leaderboards();

	game_over = NewHudElem();
	game_over.alignX = "center";
	game_over.alignY = "middle";
	game_over.horzAlign = "center";
	game_over.vertAlign = "middle";
	game_over.y -= 10;
	game_over.foreground = true;
	game_over.fontScale = 3;
	game_over.alpha = 0;
	game_over.color = ( 1.0, 1.0, 1.0 );
	game_over SetText( &"ZOMBIE_GAME_OVER" );

	game_over FadeOverTime( 1 );
	game_over.alpha = 1;

	survived = NewHudElem();
	survived.alignX = "center";
	survived.alignY = "middle";
	survived.horzAlign = "center";
	survived.vertAlign = "middle";
	survived.y += 20;
	survived.foreground = true;
	survived.fontScale = 2;
	survived.alpha = 0;
	survived.color = ( 1.0, 1.0, 1.0 );

	if( level.round_number < 2 )
	{
		survived SetText( &"ZOMBIE_SURVIVED_ROUND" );
	}
	else
	{
		survived SetText( &"ZOMBIE_SURVIVED_ROUNDS", level.round_number );
	}
	//TUEY had to change this since we are adding other musical elements
	setmusicstate("end_of_game");
	maps\_busing::setbusstate("default");

	survived FadeOverTime( 1 );
	survived.alpha = 1;

	wait( 1 );

	//play_sound_at_pos( "end_of_game", ( 0, 0, 0 ) );
	wait( 2 );
	intermission();

	wait( level.zombie_vars["zombie_intermission_time"] );

	level notify( "stop_intermission" );
	array_thread( get_players(), ::player_exit_level );

	bbPrint( "zombie_epilogs: rounds %d", level.round_number );

	wait( 1.5 );

	ExitLevel( false );

	// Let's not exit the function
	wait( 666 );
}

update_leaderboards()
{
	if( level.systemLink || IsSplitScreen() )
	{
		return; 
	}

	nazizombies_upload_highscore();
	nazizombies_set_new_zombie_stats();
}

nazizombies_upload_highscore()
{
	// Nazi Zombie Leaderboards
	// nazi_zombie_prototype_waves = 13
	// nazi_zombie_prototype_points = 14

	// this has gotta be the dumbest way of doing this, but at 1:33am in the morning my brain is fried!
	playersRank = 1;
	if( level.players_playing == 1 )
		playersRank = 4;
	else if( level.players_playing == 2 )
		playersRank = 3;
	else if( level.players_playing == 3 )
		playersRank = 2;

	map_name = GetDvar( "mapname" );

	if ( !isZombieLeaderboardAvailable( map_name, "waves" ) || !isZombieLeaderboardAvailable( map_name, "points" ) )
		return;

	players = get_players();		
	for( i = 0; i < players.size; i++ )
	{
		pre_highest_wave = players[i] playerZombieStatGet( map_name, "highestwave" ); 
		pre_time_in_wave = players[i] playerZombieStatGet( map_name, "timeinwave" );

		new_highest_wave = level.round_number + "" + playersRank;
		new_highest_wave = int( new_highest_wave );

		if( new_highest_wave >= pre_highest_wave )
		{
			if( players[i].zombification_time == 0 )
			{
				players[i].zombification_time = getTime();
			}

			player_survival_time = players[i].zombification_time - level.round_start_time; 
			player_survival_time = int( player_survival_time/1000 ); 			

			if( new_highest_wave > pre_highest_wave || player_survival_time > pre_time_in_wave )
			{
				rankNumber = makeRankNumber( level.round_number, playersRank, player_survival_time );

				leaderboard_number = getZombieLeaderboardNumber( map_name, "waves" );

				players[i] UploadScore( leaderboard_number, int(rankNumber), level.round_number, player_survival_time, level.players_playing ); 
				//players[i] UploadScore( leaderboard_number, int(rankNumber), level.round_number ); 

				players[i] playerZombieStatSet( map_name, "highestwave", new_highest_wave );
				players[i] playerZombieStatSet( map_name, "timeinwave", player_survival_time );	
			}
		}		

		pre_total_points = players[i] playerZombieStatGet( map_name, "totalpoints" ); 				
		if( players[i].score_total > pre_total_points )
		{
			leaderboard_number = getZombieLeaderboardNumber( map_name, "points" );

			players[i] UploadScore( leaderboard_number, players[i].score_total, players[i].kills, level.players_playing ); 

			players[i] playerZombieStatSet( map_name, "totalpoints", players[i].score_total );	
		}
	}
}

isZombieLeaderboardAvailable( map, type )
{
	if ( !isDefined( level.zombieLeaderboardNumber[map] ) )
		return 0;
	
	if ( !isDefined( level.zombieLeaderboardNumber[map][type] ) )
		return 0;

	return 1;
}

getZombieLeaderboardNumber( map, type )
{
	if ( !isDefined( level.zombieLeaderboardNumber[map][type] ) )
		assertMsg( "Unknown leaderboard number for map " + map + "and type " + type );
	
	return level.zombieLeaderboardNumber[map][type];
}

getZombieStatVariable( map, variable )
{
	if ( !isDefined( level.zombieLeaderboardStatVariable[map][variable] ) )
		assertMsg( "Unknown stat variable " + variable + " for map " + map );
		
	return level.zombieLeaderboardStatVariable[map][variable];
}

playerZombieStatGet( map, variable )
{
	stat_variable = getZombieStatVariable( map, variable );
	result = self zombieStatGet( stat_variable );

	return result;
}

playerZombieStatSet( map, variable, value )
{
	stat_variable = getZombieStatVariable( map, variable );
	self zombieStatSet( stat_variable, value );
}

nazizombies_set_new_zombie_stats()
{
	players = get_players();		
	for( i = 0; i < players.size; i++ )
	{
		//grab stat and add final totals
		total_kills = players[i] zombieStatGet( "zombie_kills" ) + players[i].stats["kills"];
		total_points = players[i] zombieStatGet( "zombie_points" ) + players[i].stats["score"];
		total_rounds = players[i] zombieStatGet( "zombie_rounds" ) + (level.round_number - 1); // rounds survived
		total_downs = players[i] zombieStatGet( "zombie_downs" ) + players[i].stats["downs"];
		total_revives = players[i] zombieStatGet( "zombie_revives" ) + players[i].stats["revives"];
		total_perks = players[i] zombieStatGet( "zombie_perks_consumed" ) + players[i].stats["perks"];
		total_headshots = players[i] zombieStatGet( "zombie_heashots" ) + players[i].stats["headshots"];
		total_zombie_gibs = players[i] zombieStatGet( "zombie_gibs" ) + players[i].stats["zombie_gibs"];

		//set zombie stats
		players[i] zombieStatSet( "zombie_kills", total_kills );
		players[i] zombieStatSet( "zombie_points", total_points );
		players[i] zombieStatSet( "zombie_rounds", total_rounds );
		players[i] zombieStatSet( "zombie_downs", total_downs );
		players[i] zombieStatSet( "zombie_revives", total_revives );
		players[i] zombieStatSet( "zombie_perks_consumed", total_perks );
		players[i] zombieStatSet( "zombie_heashots", total_headshots );
		players[i] zombieStatSet( "zombie_gibs", total_zombie_gibs );
	}
}

makeRankNumber( wave, players, time )
{
	if( time > 86400 ) 
		time = 86400; // cap it at like 1 day, need to cap cause you know some muppet is gonna end up trying it

	//pad out time
	padding = "";
	if ( 10 > time )
		padding += "0000";
	else if( 100 > time )
		padding += "000";
	else if( 1000 > time )
		padding += "00";
	else if( 10000 > time )
		padding += "0";

	rank = wave + "" + players + padding + time;

	return rank;
}


//CODER MOD: TOMMY K
/*
=============
statGet

Returns the value of the named stat
=============
*/
zombieStatGet( dataName )
{
	if( level.systemLink || true == IsSplitScreen() )
	{
		return; 
	}

	return self getStat( int(tableLookup( "mp/playerStatsTable.csv", 1, dataName, 0 )) );
}

//CODER MOD: TOMMY K
/*
=============
setStat

Sets the value of the named stat
=============
*/
zombieStatSet( dataName, value )
{
	if( level.systemLink || true == IsSplitScreen() )
	{
		return; 
	}

	self setStat( int(tableLookup( "mp/playerStatsTable.csv", 1, dataName, 0 )), value );	
}

intermission()
{
	level.intermission = true;
	level notify( "intermission" );

	players = get_players();
	for( i = 0; i < players.size; i++ )
	{
		setclientsysstate( "levelNotify", "zi", players[i] ); // Tell clientscripts we're in zombie intermission

		players[i] SetClientDvars( "cg_thirdPerson", "0",
			"cg_fov", "65" );

		players[i].health = 100; // This is needed so the player view doesn't get stuck
		players[i] thread [[level.custom_intermission]]();
	}

	wait( 0.25 );

	// Delay the last stand monitor so we are 100% sure the zombie intermission ("zi") is set on the cients
	players = get_players();
	for( i = 0; i < players.size; i++ )
	{
		setClientSysState( "lsm", "1", players[i] );
	}

	visionset = "zombie";
	if( IsDefined( level.zombie_vars["intermission_visionset"] ) )
	{
		visionset = level.zombie_vars["intermission_visionset"];
	}

	level thread maps\_utility::set_all_players_visionset( visionset, 2 );
	level thread zombie_game_over_death();
}

zombie_game_over_death()
{
	// Kill remaining zombies, in style!
	zombies = GetAiArray( "axis" );
	for( i = 0; i < zombies.size; i++ )
	{
		if( !IsAlive( zombies[i] ) )
		{
			continue;
		}

		zombies[i] SetGoalPos( zombies[i].origin );
	}

	for( i = 0; i < zombies.size; i++ )
	{
		if( !IsAlive( zombies[i] ) )
		{
			continue;
		}

		wait( 0.5 + RandomFloat( 2 ) );

		zombies[i] maps\_zombiemode_spawner::zombie_head_gib();
		zombies[i] DoDamage( zombies[i].health + 666, zombies[i].origin );
	}
}

round_start()
{
	level.zombie_health = level.zombie_vars["zombie_health_start"]; 
	level.round_number = 1; 
	level.first_round = true;

	players = get_players();
	for (i = 0; i < players.size; i++)
	{
		players[i] giveweapon( "stielhandgranate" );	
		players[i] setweaponammoclip( "stielhandgranate", 0);
	}

	level.chalk_hud1 = create_chalk_hud();
	level.chalk_hud2 = create_chalk_hud( 64 );

    flag_set( "begin_spawning" );

    if ( !isdefined( level.round_spawn_func ) )
        level.round_spawn_func = ::round_spawning;
/#
    if ( getdvarint( "zombie_rise_test" ) )
        level.round_spawn_func = ::round_spawning_test;
#/
    if ( !isdefined( level.round_wait_func ) )
        level.round_wait_func = ::round_wait;

    if ( !isdefined( level.round_think_func ) )
        level.round_think_func = ::round_think;

    level thread [[ level.round_think_func ]]();
}

round_spawning_test()
{
	while (true)
	{
		spawn_point = level.enemy_spawns[RandomInt( level.enemy_spawns.size )];	// grab a random spawner

		ai = spawn_zombie( spawn_point );
		ai waittill("death");

		wait 5;
	}
}

create_chalk_hud( x )
{
	if( !IsDefined( x ) )
	{
		x = 0;
	}

	hud = maps\_zombiemode_utility::create_simple_hud();
	hud.alignX = "left"; 
	hud.alignY = "bottom";
	hud.horzAlign = "left"; 
	hud.vertAlign = "bottom";
	hud.color = ( 0.423, 0.004, 0 );
	hud.x = x; 
	hud.alpha = 0;

	hud SetShader( "hud_chalk_1", 64, 64 );

	return hud;
}

spawn_vo_player(index,num)
{
	sound = "plr_" + index + "_vox_" + num +"play";
	self playsound(sound, "sound_done");			
	self waittill("sound_done");
}

round_spawning()
{
	level endon( "intermission" );
/#
	level endon( "kill_round" );
#/

	if( level.intermission )
	{
		return;
	}

	if( level.enemy_spawns.size < 1 )
	{
		ASSERTMSG( "No spawners with targetname zombie_spawner in map." ); 
		return; 
	}

/#
	if ( GetDVarInt( "zombie_cheat" ) == 2 || GetDVarInt( "zombie_cheat" ) >= 4 ) 
	{
		return;
	}
#/

	ai_calculate_health(); 

	count = 0; 

	//CODER MOD: TOMMY K
	players = get_players();
	for( i = 0; i < players.size; i++ )
	{
		players[i].zombification_time = 0;
	}

	max = level.zombie_vars["zombie_max_ai"];

	multiplier = level.round_number / 5;
	if( multiplier < 1 )
	{
		multiplier = 1;
	}

	// After round 10, exponentially have more AI attack the player
	if( level.round_number >= 10 )
	{
		multiplier *= level.round_number * 0.15;
	}

	player_num = get_players().size;

	if( player_num == 1 )
	{
		max += int( ( 0.5 * level.zombie_vars["zombie_ai_per_player"] ) * multiplier ); 
	}
	else
	{
		max += int( ( ( player_num - 1 ) * level.zombie_vars["zombie_ai_per_player"] ) * multiplier ); 
	}


	
	if(level.round_number < 3 && level.script == "nazi_zombie_asylum")
	{
		if(get_players().size > 1)
		{
			
			max = get_players().size * 3 + level.round_number;

		}
		else
		{

			max = 6;	

		}
	}
	else if ( level.first_round )
	{
		max = int( max * 0.2 );	
	}
	else if (level.round_number < 3)
	{
		max = int( max * 0.4 );
	}
	else if (level.round_number < 4)
	{
		max = int( max * 0.6 );
	}
	else if (level.round_number < 5)
	{
		max = int( max * 0.8 );
	}


	level.zombie_total = max;
	mixed_spawns = 0;	// Number of mixed spawns this round.  Currently means number of dogs in a mixed round

	// DEBUG HACK:	
	//max = 1;
	old_spawn = undefined;
	while( count < max )
	{

		spawn_point = level.enemy_spawns[RandomInt( level.enemy_spawns.size )]; 

		if( !IsDefined( old_spawn ) )
		{
				old_spawn = spawn_point;
		}
		else if( Spawn_point == old_spawn )
		{
				spawn_point = level.enemy_spawns[RandomInt( level.enemy_spawns.size )]; 
		}
		old_spawn = spawn_point;

	//	iPrintLn(spawn_point.targetname + " " + level.zombie_vars["zombie_spawn_delay"]);
		while( get_enemy_count() > 31 )
		{
			wait( 0.05 );
		}

		// MM Mix in dog spawns...
		if ( isDefined( level._custom_func_table ) && isDefined( level._custom_func_table[ "special_dog_spawn" ] ) && IsDefined( level.mixed_rounds_enabled ) && level.mixed_rounds_enabled == 1 )
		{
			spawn_dog = false;
			if ( level.round_number > 30 )
			{
				if ( RandomInt(100) < 3 )
				{
					spawn_dog = true;
				}
			}
			else if ( level.round_number > 25 && mixed_spawns < 3 )
			{
				if ( RandomInt(100) < 2 )
				{
					spawn_dog = true;
				}
			}
			else if ( level.round_number > 20 && mixed_spawns < 2 )
			{
				if ( RandomInt(100) < 2 )
				{
					spawn_dog = true;
				}
			}
			else if ( level.round_number > 15 && mixed_spawns < 1 )
			{
				if ( RandomInt(100) < 1 )
				{
					spawn_dog = true;
				}
			}

			if ( spawn_dog )
			{
				keys = GetArrayKeys( level.zones );
				for ( i=0; i<keys.size; i++ )
				{
					if ( level.zones[ keys[i] ].is_occupied )
					{
						akeys = GetArrayKeys( level.zones[ keys[i] ].adjacent_zones );
						for ( k=0; k<akeys.size; k++ )
						{
							if ( level.zones[ akeys[k] ].is_active &&
								 !level.zones[ akeys[k] ].is_occupied &&
								 level.zones[ akeys[k] ].dog_locations.size > 0 )
							{
								level [[ level._custom_func_table[ "special_dog_spawn" ] ]]( undefined, 1 );
								level.zombie_total--;
								wait_network_frame();
							}
						}
					}
				}
			}
		}

		ai = spawn_zombie( spawn_point ); 
		if( IsDefined( ai ) )
		{
			level.zombie_total--;
			ai thread round_spawn_failsafe();
			count++; 
		}
		wait( level.zombie_vars["zombie_spawn_delay"] ); 
		wait_network_frame();
	}

	if( level.round_number > 3 )
	{
		zombies = getaiarray( "axis" );
		while( zombies.size > 0 )
		{
			if( zombies.size == 1 && zombies[0].has_legs == true )
			{
				var = randomintrange(1, 4);
				zombies[0] set_run_anim( "sprint" + var );                       
				zombies[0].run_combatanim = level.scr_anim[zombies[0].animname]["sprint" + var];
			}
			wait(0.5);
			zombies = getaiarray("axis");
		}

	}

}

ai_calculate_health()
{
	// After round 10, get exponentially harder
	if( level.round_number >= 10 )
	{
		level.zombie_health += Int( level.zombie_health * level.zombie_vars["zombie_health_increase_percent"] ); 
		return;
	}

	if( level.round_number > 1 )
	{
		level.zombie_health = Int( level.zombie_health + level.zombie_vars["zombie_health_increase"] ); 
	}

}

round_spawn_failsafe()
{
	self endon("death");//guy just died

	//////////////////////////////////////////////////////////////
	//FAILSAFE "hack shit"  DT#33203
	//////////////////////////////////////////////////////////////
	prevorigin = self.origin;
	while(1)
	{
		if( !level.zombie_vars["zombie_use_failsafe"] )
		{
			return;
		}

		wait( 30 );

		//if i've torn a board down in the last 5 seconds, just 
		//wait 30 again.
		if ( isDefined(self.lastchunk_destroy_time) )
		{
			if ( (getTime() - self.lastchunk_destroy_time) < 5000 )
				continue; 
		}

		//fell out of world
		if ( self.origin[2] < level.zombie_vars["below_world_check"] )
		{
			self dodamage( self.health + 100, (0,0,0) );	
			break;
		}

		//hasnt moved 24 inches in 30 seconds?	
		if ( DistanceSquared( self.origin, prevorigin ) < 576 ) 
		{
			// DEBUG HACK
			self dodamage( self.health + 100, (0,0,0) );	
			break;
		}

		prevorigin = self.origin;
	}
	//////////////////////////////////////////////////////////////
	//END OF FAILSAFE "hack shit"
	//////////////////////////////////////////////////////////////
}

round_wait()
{
/#
	if (GetDVarInt("zombie_rise_test"))
	{
		level waittill("forever"); // TESTING: don't advance rounds
	}
#/

/#
	if ( GetDVarInt( "zombie_cheat" ) == 2 || GetDVarInt( "zombie_cheat" ) >= 4 )
	{
		level waittill("forever");
	}
#/

	wait( 1 );

	if( flag("dog_round" ) )
	{
		wait(7);
		while( level.dog_intermission )
		{
			wait(0.5);
		}
	}
	else
	{
		while( maps\_zombiemode_utility::get_enemy_count() > 0 || level.zombie_total > 0 || level.intermission)
		{
			wait( 0.5 );
		}
	}
}

round_think()
{
	for( ;; )
	{
		//////////////////////////////////////////
		//designed by prod DT#36173
		maxreward = 50 * level.round_number;
		if ( maxreward > 500 )
			maxreward = 500;
		level.zombie_vars["rebuild_barrier_cap_per_round"] = maxreward;
		//////////////////////////////////////////

		level.round_timer = level.zombie_vars["zombie_round_time"]; 

		maps\_zombiemode_utility::add_later_round_spawners();

		chalk_one_up();
		//		round_text( &"ZOMBIE_ROUND_BEGIN" );

		maps\_zombiemode_powerups::powerup_round_start();

		players = get_players();
		array_thread( players, maps\_zombiemode_blockers_new::rebuild_barrier_reward_reset );

		level thread award_grenades_for_survivors();

		bbPrint( "zombie_rounds: round %d player_count %d", level.round_number, players.size );

		level.round_start_time = getTime();
		level thread [[level.round_spawn_func]]();

		level [[ level.round_wait_func ]]();
		level.first_round = false;

		level thread spectators_respawn();

		//		round_text( &"ZOMBIE_ROUND_END" );
		level thread chalk_round_hint();

		wait( level.zombie_vars["zombie_between_round_time"] ); 

		// here's the difficulty increase over time area
			timer = level.zombie_vars["zombie_spawn_delay"];

		if( timer < 0.08 )
		{
			timer = 0.08; 
		}	

		level.zombie_vars["zombie_spawn_delay"] = timer * 0.95;

		// Increase the zombie move speed
		level.zombie_move_speed = level.round_number * 8;

		level.round_number++;

		level notify( "between_round_over" );
	}
}

chalk_one_up()
{
	
	if(!IsDefined(level.doground_nomusic))
	{
		level.doground_nomusic = 0;
	}
	if( level.first_round )
	{
		intro = true;
		//Play the intro sound at the beginning of the round
	 	//level thread play_intro_VO(); (commented out for Corky)

	}
	else
	{
		intro = false;
	}

	round = undefined;	
	if( intro )
	{
		round = maps\_zombiemode_utility::create_simple_hud();
		round.alignX = "center"; 
		round.alignY = "bottom";
		round.horzAlign = "center"; 
		round.vertAlign = "bottom";
		round.fontscale = 16;
		round.color = ( 1, 1, 1 );
		round.x = 0;
		round.y = -265;
		round.alpha = 0;
		round SetText( &"ZOMBIE_ROUND" );

		round FadeOverTime( 1 );
		round.alpha = 1;
		wait( 1 );

		round FadeOverTime( 3 );
		//		round.color = ( 0.8, 0, 0 );
		round.color = ( 0.423, 0.004, 0 );
	}

	hud = undefined;
	if( level.round_number < 6 || level.round_number > 10 )
	{
		hud = level.chalk_hud1;
		hud.fontscale = 32;
	}
	else if( level.round_number < 11 )
	{
		hud = level.chalk_hud2;
	}

	if( intro )
	{
		hud.alpha = 0;
		hud.horzAlign = "center";
		hud.x = -5;
		hud.y = -200;
	}

	hud FadeOverTime( 0.5 );
	hud.alpha = 0;

	if( level.round_number == 11 && IsDefined( level.chalk_hud2 ) )
	{
		level.chalk_hud2 FadeOverTime( 0.5 );
		level.chalk_hud2.alpha = 0;
	}

	wait( 0.5 );

	//	play_sound_at_pos( "chalk_one_up", ( 0, 0, 0 ) );

	if(IsDefined(level.eggs) && level.eggs !=1 )
	{
		if(level.doground_nomusic ==0 )
	{
		setmusicstate("round_begin");
	}

	}

	if( level.round_number == 11 && IsDefined( level.chalk_hud2 ) )
	{
		level.chalk_hud2 destroy_hud();
	}

	if( level.round_number > 10 )
	{
		hud SetValue( level.round_number );
	}

	hud FadeOverTime( 0.5 );
	hud.alpha = 1;

	if( intro )
	{
		wait( 3 );

		if( IsDefined( round ) )
		{
			round FadeOverTime( 1 );
			round.alpha = 0;
		}

		wait( 0.25 );

		level notify( "intro_hud_done" );
		hud MoveOverTime( 1.75 );
		hud.horzAlign = "left";
		//		hud.x = 0;
		hud.y = 0;
		wait( 2 );

		round destroy_hud();
	}

	if( level.round_number > 10 )
	{
	}
	else if( level.round_number > 5 )
	{
		hud SetShader( "hud_chalk_" + ( level.round_number - 5 ), 64, 64 );
	}
	else if( level.round_number > 1 )
	{
		hud SetShader( "hud_chalk_" + level.round_number, 64, 64 );
	}	
/*
	else 
	{
		setmusicstate("WAVE_1");
	}
*/	

	//	ReportMTU(level.round_number);	// In network debug instrumented builds, causes network spike report to generate.
}

award_grenades_for_survivors()
{
	players = get_players();

	for (i = 0; i < players.size; i++)
	{
		if (!players[i].is_zombie)
		{
			if( !players[i] HasWeapon( "stielhandgranate" ) )
			{
				players[i] GiveWeapon( "stielhandgranate" );	
				players[i] SetWeaponAmmoClip( "stielhandgranate", 0 );
			}

			if ( players[i] GetFractionMaxAmmo( "stielhandgranate") < .25 )
			{
				players[i] SetWeaponAmmoClip( "stielhandgranate", 2 );
			}
			else if (players[i] GetFractionMaxAmmo( "stielhandgranate") < .5 )
			{
				players[i] SetWeaponAmmoClip( "stielhandgranate", 3 );
			}
			else
			{
				players[i] SetWeaponAmmoClip( "stielhandgranate", 4 );
			}
		}
	}
}

spectators_respawn()
{
	level endon( "between_round_over" );

	if( !IsDefined( level.zombie_vars["spectators_respawn"] ) || !level.zombie_vars["spectators_respawn"] )
	{
		return;
	}

	if( !IsDefined( level.custom_spawnPlayer ) )
	{
		// Custom spawn call for when they respawn from spectator
		level.custom_spawnPlayer = ::spectator_respawn;
	}

	while( 1 )
	{
		players = get_players();
		for( i = 0; i < players.size; i++ )
		{
			if( players[i].sessionstate == "spectator" )
			{
				players[i] [[level.spawnPlayer]]();
				if( isDefined( players[i].has_altmelee ) && players[i].has_altmelee )
				{
					players[i] SetPerk( "specialty_altmelee" );
				}
				if (isDefined(level.script) && level.round_number > 6 && players[i].score < 1500)
				{
					players[i].old_score = players[i].score;
					players[i].score = 1500;
					players[i] maps\_zombiemode_score::set_player_score_hud();
				}
			}
		}

		wait( 1 );
	}
}

spectator_respawn()
{
	println( "*************************Respawn Spectator***" );
	assert( IsDefined( self.spectator_respawn ) );

	origin = self.spectator_respawn.origin;
	angles = self.spectator_respawn.angles;

	self setSpectatePermissions( false );

	new_origin = undefined;
	
	
	new_origin = check_for_valid_spawn_near_team( self );
	

	if( IsDefined( new_origin ) )
	{
		self Spawn( new_origin, angles );
	}
	else
	{
		self Spawn( origin, angles );
	}


	if( IsSplitScreen() )
	{
		last_alive = undefined;
		players = get_players();

		for( i = 0; i < players.size; i++ )
		{
			if( !players[i].is_zombie )
			{
				last_alive = players[i];
			}
		}

		share_screen( last_alive, false );
	}

	self.has_betties = undefined;
	self.is_burning = undefined;

	// The check_for_level_end looks for this
	self.is_zombie = false;
	self.ignoreme = false;

	setClientSysState("lsm", "0", self);	// Notify client last stand ended.
	self RevivePlayer();

	self notify( "spawned_player" );

	// Penalize the player when we respawn, since he 'died'
	self maps\_zombiemode_score::player_reduce_points( "died" );

	self thread player_zombie_breadcrumb();

	return true;
}

check_for_valid_spawn_near_team( revivee )
{

	players = get_players();
	spawn_points = getstructarray("player_respawn_point", "targetname");

	if( spawn_points.size == 0 )
		return undefined;

	for( i = 0; i < players.size; i++ )
	{
		if( is_player_valid( players[i] ) )
		{
			for( j = 0 ; j < spawn_points.size; j++ )
			{
				if( DistanceSquared( players[i].origin, spawn_points[j].origin ) < ( 1000 * 1000 ) && spawn_points[j].locked == false )
				{
					spawn_array = getstructarray( spawn_points[j].target, "targetname" );

					for( k = 0; k < spawn_array.size; k++ )
					{
						if( spawn_array[k].script_int == (revivee.entity_num + 1) )
						{
							return spawn_array[k].origin; 
						}
					}	

					return spawn_array[0].origin;
				}

			}

		}

	}

	return undefined;

}


get_players_on_team(exclude)
{

	teammates = [];

	players = get_players();
	for(i=0;i<players.size;i++)
	{		
		//check to see if other players on your team are alive and not waiting to be revived
		if(players[i].spawn_side == self.spawn_side && !isDefined(players[i].revivetrigger) && players[i] != exclude )
		{
			teammates[teammates.size] = players[i];
		}
	}

	return teammates;
}

chalk_round_hint()
{
	huds = [];
	huds[huds.size] = level.chalk_hud1;

	if( level.round_number > 5 && level.round_number < 11 )
	{
		huds[huds.size] = level.chalk_hud2;
	}

	time = level.zombie_vars["zombie_between_round_time"];
	for( i = 0; i < huds.size; i++ )
	{
		huds[i] FadeOverTime( time * 0.25 );
		huds[i].color = ( 1, 1, 1 );
	}
	if(IsDefined(level.eggs) && level.eggs !=1)
	{
		if(IsDefined(level.doground_nomusic  && level.doground_nomusic == 0 ))
		{
		setmusicstate("round_end");
		wait( time * 0.25 );
	}
		else if(IsDefined(level.doground_nomusic  && level.doground_nomusic == 1 ))
		{
			play_sound_2D( "bright_sting" );
				
		}
	}
	//	play_sound_at_pos( "end_of_round", ( 0, 0, 0 ) );



	// Pulse
	fade_time = 0.5;
	steps =  ( time * 0.5 ) / fade_time;
	for( q = 0; q < steps; q++ )
	{
		for( i = 0; i < huds.size; i++ )
		{
			if( !IsDefined( huds[i] ) )
			{
				continue;
			}

			huds[i] FadeOverTime( fade_time );
			huds[i].alpha = 0;
		}

		wait( fade_time );

		for( i = 0; i < huds.size; i++ )
		{
			if( !IsDefined( huds[i] ) )
			{
				continue;
			}

			huds[i] FadeOverTime( fade_time );
			huds[i].alpha = 1;		
		}

		wait( fade_time );
	}

	for( i = 0; i < huds.size; i++ )
	{
		if( !IsDefined( huds[i] ) )
		{
			continue;
		}

		huds[i] FadeOverTime( time * 0.25 );
		//		huds[i].color = ( 0.8, 0, 0 );
		huds[i].color = ( 0.423, 0.004, 0 );
		huds[i].alpha = 1;
	}
}

players_playing()
{
	// initialize level.players_playing
	players = get_players();
	level.players_playing = players.size;

	wait( 20 );

	players = get_players();
	level.players_playing = players.size;
}

spawn_vo()
{
	//not sure if we need this
	wait(1);
	
	players = getplayers();
	
	//just pick a random player for now and play some vo 
	if(players.size > 1)
	{
		player = random(players);
		index = maps\_zombiemode_weapons::get_player_index(player);
		player thread spawn_vo_player(index,players.size);
	}

}

track_players_ammo_count()
{
	self endon("disconnect");
	self endon("death");
	if(!IsDefined (level.player_ammo_low))	
	{
		level.player_ammo_low = 0;
	}	
	if(!IsDefined(level.player_ammo_out))
	{
		level.player_ammo_out = 0;
	}
	while(1)
	{
		players = get_players();
		for(i=0;i<players.size;i++)
		{
	
			weap = players[i] getcurrentweapon();
			//iprintln("current weapon: " + weap);
			//iprintlnbold(weap);
			//Excludes all Perk based 'weapons' so that you don't get low ammo spam.
			if(!isDefined(weap) || weap == "none" || weap == "zombie_perk_bottle_doubletap" || weap == "zombie_perk_bottle_jugg" || weap == "zombie_perk_bottle_revive" || weap == "zombie_perk_bottle_sleight" || weap == "mine_bouncing_betty" || weap == "syrette" || weap == "zombie_knuckle_crack" || weap == "zombie_bowie_flourish" )
			{
				continue;
			}
			//iprintln("checking ammo for " + weap);
			if ( players[i] GetAmmoCount( weap ) > 5)
			{
				continue;
			}		
			if ( players[i] maps\_laststand::player_is_in_laststand() )
			{				
				continue;
			}
			else if (players[i] GetAmmoCount( weap ) < 5 && players[i] GetAmmoCount( weap ) > 0)
			{
				if (level.player_ammo_low == 0)
				{
					level.player_ammo_low = 1;
					players[i] thread add_low_ammo_dialog();		
					players[i] thread ammo_dialog_timer();
					level waittill("send_dialog_reminder");
					level.player_ammo_low = 0;
				}
	
			}
			else if (players[i] GetAmmoCount( weap ) == 0)
			{	
				if(!isDefined(weap) || weap == "none")
				{
					continue;	
				}				
				level.player_ammo_out = 1;
				players[i] thread add_no_ammo_dialog( weap );
				//put in this wait to keep the game from spamming about being low on ammo.
				wait(20);
				level.player_ammo_out = 0;												
			}
			else
			{
				continue;
			}
		}
		wait(.5);
	}	
}
ammo_dialog_timer()
{
	level endon ("ammo_out");
	while(1)
	{
		wait(20);
		level notify ("send_dialog_reminder");	
		
	}	
	
}
add_low_ammo_dialog()
{
	index = maps\_zombiemode_weapons::get_player_index(self);	
	player_index = "plr_" + index + "_";
	if(!IsDefined (self.vox_ammo_low))
	{
		num_variants = maps\_zombiemode_spawner::get_number_variants(player_index + "vox_ammo_low");
		self.vox_ammo_low = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_ammo_low[self.vox_ammo_low.size] = "vox_ammo_low_" + i;	
		}
		self.vox_ammo_low_available = self.vox_ammo_low;		
	}	
	sound_to_play = random(self.vox_ammo_low_available);
	
	self.vox_ammo_low_available = array_remove(self.vox_ammo_low_available,sound_to_play);
	
	if (self.vox_ammo_low_available.size < 1 )
	{
		self.vox_ammo_low_available = self.vox_ammo_low;
	}
			
	self maps\_zombiemode_spawner::do_player_playdialog(player_index, sound_to_play, 0.25);	
	
	
	
}
add_no_ammo_dialog( weap )
{
	self endon( "disconnect" );

	// Let's pause here a couple of seconds to see if we're really out of ammo.
	// If you take a weapon, there's a second or two where your current weapon
	// will be set to no ammo while you switch to the new one.
	wait(2);

	curr_weap = self getcurrentweapon();
	if ( !IsDefined(curr_weap) || curr_weap != weap || self GetAmmoCount( curr_weap ) != 0 )
	{
		// False alarm
		return;
	}


	index = maps\_zombiemode_weapons::get_player_index(self);	
	player_index = "plr_" + index + "_";
	if(!IsDefined (self.vox_ammo_out))
	{
		num_variants = maps\_zombiemode_spawner::get_number_variants(player_index + "vox_ammo_out");
		self.vox_ammo_out = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_ammo_out[self.vox_ammo_out.size] = "vox_ammo_out_" + i;	
		}
		self.vox_ammo_out_available = self.vox_ammo_out;		
	}	
	sound_to_play = random(self.vox_ammo_out_available);
	
	self.vox_ammo_out_available = array_remove(self.vox_ammo_out_available,sound_to_play);
	
	if (self.vox_ammo_out_available.size < 1 )
	{
		self.vox_ammo_out_available = self.vox_ammo_out;
	}

	self maps\_zombiemode_spawner::do_player_playdialog(player_index, sound_to_play, 0.25);	
	
	
	
}

get_safe_breadcrumb_pos( player )
{
	players = get_players();
	valid_players = [];

	min_dist = 150 * 150;
	for( i = 0; i < players.size; i++ )
	{
		if( !is_player_valid( players[i] ) )
		{
			continue;
		}

		valid_players[valid_players.size] = players[i];
	}

	for( i = 0; i < valid_players.size; i++ )
	{
		count = 0;
		for( q = 1; q < player.zombie_breadcrumbs.size; q++ )
		{
			if( DistanceSquared( player.zombie_breadcrumbs[q], valid_players[i].origin ) < min_dist )
			{
				continue;
			}
			
			count++;
			if( count == valid_players.size )
			{
				return player.zombie_breadcrumbs[q];
			}
		}
	}

	return undefined;
}