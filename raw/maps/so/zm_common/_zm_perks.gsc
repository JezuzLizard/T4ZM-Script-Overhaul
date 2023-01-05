#include maps\_utility; 
#include common_scripts\utility; 
#include maps\so\zm_common\_zm_utility;

init()
{
	set_zombie_var( "zombie_perk_cost",					2000 );

	spawn_and_link_perk_kvps();

	vending_triggers = GetEntArray( "zombie_vending", "targetname" );
	
	if ( vending_triggers.size < 1 )
	{
		return;
	}

	if ( array_validate( level._custom_perks ) )
	{
		a_keys = getarraykeys( level._custom_perks );

		for ( i = 0; i < a_keys.size; i++ )
		{
			if ( isdefined( level._custom_perks[a_keys[i]].precache_func ) )
				level [[ level._custom_perks[a_keys[i]].precache_func ]]();
		}
	}

	// this map uses atleast 1 perk machine
	array_thread( vending_triggers, ::vending_trigger_think );
	array_thread( vending_triggers, ::electric_perks_dialog);

	if ( array_validate( level._custom_perks ) )
	{
		a_keys = getarraykeys( level._custom_perks );

		for ( i = 0; i < a_keys.size; i++ )
		{
			if ( isdefined( level._custom_perks[a_keys[i]].perk_machine_thread ) )
				level thread [[ level._custom_perks[a_keys[i]].perk_machine_thread ]]();
		}
	}	
		
	level thread machine_watcher();

	spawn_and_link_packapunch_kvps();

	vending_upgrade_trigger = GetEntArray("zombie_vending_upgrade", "targetname");

	if ( vending_upgrade_trigger.size < 1 )
	{
		return;
	}

	if ( isDefined( level._custom_packapunch ) && isDefined( level._custom_packapunch.precache_func ) )
	{
		level thread [[ level._custom_packapunch.precache_func ]]();
	}

	array_thread( vending_upgrade_trigger, maps\so\zm_common\perks\_zm_packapunch::vending_upgrade );
	if ( isDefined( level._custom_packapunch ) && isDefined( level._custom_packapunch.machine_thread ) )
	{
		level thread [[ level._custom_packapunch.machine_thread ]]();
	}
}

// PI_CHANGE_END

perk_fx( fx )
{
	wait(3);
	playfxontag( level._effect[ fx ], self, "tag_origin" );
}




electric_perks_dialog()
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
				
				players[i] thread do_player_vo("vox_start", 5);	
				wait(3);				
				self notify ("warning_dialog");
				iprintlnbold("warning_given");
			}
		}
	}
}
vending_trigger_think()
{

	//self thread turn_cola_off();
	perk = self.script_noteworthy;
	

	self SetHintString( &"ZOMBIE_FLAMES_UNAVAILABLE" );

	self SetCursorHint( "HINT_NOICON" );
	self UseTriggerRequireLookAt();

	notify_name = perk + "_power_on";
	level waittill( notify_name );
	
	perk_hum = spawn("script_origin", self.origin);
	perk_hum playloopsound("perks_machine_loop");

	self thread check_player_has_perk(perk);
	
	self vending_set_hintstring(perk);
	
	for( ;; )
	{
		self waittill( "trigger", player );
		index = maps\so\zm_common\_zm_weapons::get_player_index(player);
		
		cost = level.zombie_vars["zombie_perk_cost"];
		if ( array_validate( level._custom_perks ) && isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].cost ) )
			cost = level._custom_perks[perk].cost;
		if (player maps\_laststand::player_is_in_laststand() )
		{
			wait 0.1;
			continue;
		}

		if(player in_revive_trigger())
		{
			wait 0.1;
			continue;
		}
		
		if( player isThrowingGrenade() )
		{
			wait( 0.1 );
			continue;
		}
		
		if( player isSwitchingWeapons() )
		{
			wait(0.1);
			continue;
		}

		if ( isDefined( player.is_drinking ) && player.is_drinking > 0 )
		{
			wait 0.1;
			continue;
		}

		if ( player HasPerk( perk ) )
		{
			cheat = false;

			/#
			if ( GetDVarInt( "zombie_cheat" ) >= 5 )
			{
				cheat = true;
			}
			#/

			if ( cheat != true )
			{
				//player iprintln( "Already using Perk: " + perk );
				self playsound("deny");
				player thread maps\so\zm_common\_zm_audio::play_no_money_perk_dialog();

				
				continue;
			}
		}

		if ( player.score < cost )
		{
			//player iprintln( "Not enough points to buy Perk: " + perk );
			self playsound("deny");
			player thread maps\so\zm_common\_zm_audio::play_no_money_perk_dialog();
			continue;
		}

		self thread vending_trigger_post_think( player, perk, cost );
	}
}

vending_trigger_post_think( player, perk, cost )
{
	level endon( "end_game" );
	player endon( "disconnect" );
	sound = "bottle_dispense3d";
	player achievement_notify( "perk_used" );
	playsoundatposition(sound, self.origin);
	player maps\so\zm_common\_zm_score::minus_to_player_score( cost ); 
	///bottle_dispense
	if ( array_validate( level._custom_perks ) && isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].stinger ) )
	{
		sound = level._custom_perks[ perk ].stinger;
	}
	self thread play_vendor_stings(sound);

	//		self waittill("sound_done");


	// do the drink animation
	gun = player perk_give_bottle_begin( perk );
	player waittill_any( "fake_death", "death", "player_downed", "weapon_change_complete" );

	// restore player controls and movement
	player perk_give_bottle_end( gun, perk );
	// TODO: race condition?
	if ( player maps\_laststand::player_is_in_laststand() )
	{
		return;
	}
	if ( array_validate( level._custom_perks ) && isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].player_thread_give ) )
		player thread [[ level._custom_perks[perk].player_thread_give ]]();
	player SetPerk( perk );
	player thread perk_vo(perk);
	player setblur( 4, 0.1 );
	wait(0.1);
	player setblur(0, 0.1);
	//earthquake (0.4, 0.2, self.origin, 100);

	player perk_hud_create( perk );

	//stat tracking
	player.stats["perks"]++;

	//player iprintln( "Bought Perk: " + perk );
	bbPrint( "zombie_uses: playername %s playerscore %d round %d cost %d name %s x %f y %f z %f type perk",
		player.playername, player.score, level.round_number, cost, perk, self.origin );

	player thread perk_think( perk );
}

check_player_has_perk(perk)
{
	/#
		if ( GetDVarInt( "zombie_cheat" ) >= 5 )
		{
			return;
		}
#/

		dist = 128 * 128;
		while(true)
		{
			players = getPlayers();
			for( i = 0; i < players.size; i++ )
			{
				if(DistanceSquared( players[i].origin, self.origin ) < dist)
				{
					if(!players[i] hasperk(perk) && !(players[i] in_revive_trigger()))
					{
						//PI CHANGE: this change makes it so that if there are multiple players within the trigger for the perk machine, the hint string is still 
						//                   visible to all of them, rather than the last player this check is done for
						if (IsDefined(level.script) && level.script == "nazi_zombie_theater")
							self setinvisibletoplayer(players[i], false);
						else
							self setvisibletoplayer(players[i]);
						//END PI CHANGE
						//iprintlnbold("turn it off to player");

					}
					else
					{
						self SetInvisibleToPlayer(players[i]);
						//iprintlnbold(players[i].health);
					}
				}


			}

			wait(0.1);

		}

}

vending_set_hintstring( perk )
{
	if ( array_validate( level._custom_perks ) )
	{
		if ( isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].cost ) && isdefined( level._custom_perks[perk].hint_string ) )
			self sethintstring( level._custom_perks[perk].hint_string );
	}
}

//rewrite to use for loop TODO
perk_think( perk )
{
	self endon( "disconnect" );
	/#
		if ( GetDVarInt( "zombie_cheat" ) >= 5 )
		{
			if ( IsDefined( self.perk_hud[ perk ] ) )
			{
				return;
			}
		}
#/

	self waittill_any( "fake_death", "death", "player_downed" );

	if ( array_validate( level._custom_perks ) && isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].player_thread_take ) )
		self thread [[ level._custom_perks[perk].player_thread_take ]]();
	self UnsetPerk( perk );
	self perk_hud_destroy( perk );
	//self iprintln( "Perk Lost: " + perk );
}


perk_hud_create( perk )
{
	if ( !IsDefined( self.perk_hud ) )
	{
		self.perk_hud = [];
	}

/#
	if ( GetDVarInt( "zombie_cheat" ) >= 5 )
	{
		if ( IsDefined( self.perk_hud[ perk ] ) )
		{
			return;
		}
	}
#/
	shader = "";
	if ( array_validate( level._custom_perks ) && isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].shader ) )
	{
		shader = level._custom_perks[ perk ].shader;
	}
	hud = create_simple_hud( self );
	hud.foreground = true; 
	hud.sort = 1; 
	hud.hidewheninmenu = false; 
	hud.alignX = "left"; 
	hud.alignY = "bottom";
	hud.horzAlign = "left"; 
	hud.vertAlign = "bottom";
	hud.x = self.perk_hud.size * 30; 
	hud.y = hud.y - 70; 
	hud.alpha = 1;
	hud SetShader( shader, 24, 24 );

	self.perk_hud[ perk ] = hud;
}


perk_hud_destroy( perk )
{
	self.perk_hud[ perk ] destroy_hud();
	self.perk_hud[ perk ] = undefined;
}

perk_give_bottle_begin( perk )
{
	self endon( "disconnect" );
	self increment_is_drinking();

	self AllowLean( false );
	self AllowAds( false );
	self AllowSprint( false );
	self AllowProne( false );		
	self AllowMelee( false );

	wait( 0.05 );

	if ( self GetStance() == "prone" )
	{
		self SetStance( "crouch" );
	}

	gun = self GetCurrentWeapon();
	weapon = "";

	if ( array_validate( level._custom_perks ) && isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].perk_bottle ) )
		weapon = level._custom_perks[perk].perk_bottle;
	self GiveWeapon( weapon );
	self SwitchToWeapon( weapon );

	return gun;
}


perk_give_bottle_end( gun, perk )
{
	self endon( "disconnect" );
	assert( gun != "zombie_perk_bottle_doubletap" );
	assert( gun != "zombie_perk_bottle_revive" );
	assert( gun != "zombie_perk_bottle_jugg" );
	assert( gun != "zombie_perk_bottle_sleight" );
	assert( gun != "syrette" );

	self AllowLean( true );
	self AllowAds( true );
	self AllowSprint( true );
	self AllowProne( true );		
	self AllowMelee( true );
	weapon = "";
	if ( array_validate( level._custom_perks ) && isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].perk_bottle ) )
		weapon = level._custom_perks[perk].perk_bottle;
	// TODO: race condition?
	if ( self maps\_laststand::player_is_in_laststand() )
	{
		self TakeWeapon(weapon);
		return;
	}

	self takeweapon( weapon );

	if ( self is_multiple_drinking() )
	{
		self decrement_is_drinking();
		return;
	}
	else if ( gun != "none" && gun != "mine_bouncing_betty" )
	{
		self switchtoweapon( gun );
	}
	else
	{
		primaryweapons = self getweaponslistprimaries();

		if ( isdefined( primaryweapons ) && primaryweapons.size > 0 )
			self switchtoweapon( primaryweapons[0] );
	}

	self waittill( "weapon_change_complete" );

	if ( !self maps\_laststand::player_is_in_laststand() && !( isdefined( self.intermission ) && self.intermission ) )
		self decrement_is_drinking();
}

perk_vo(type)
{
	self endon("death");
	self endon("disconnect");

	index = maps\so\zm_common\_zm_weapons::get_player_index(self);
	sound_to_play = undefined;

	if(!isdefined (level.player_is_speaking))
	{
		level.player_is_speaking = 0;
	}
	
	wait(1.0);
	if ( !is_true( level.use_legacy_perk_system ) )
	{
		player_index = "plr_" + index + "_";
		//TUEY We need to eventually store the dialog in an array so you can add multiple variants...but we only have 1 now anyway.
		if ( array_validate( level._custom_perks ) && isDefined( level._custom_perks[ type ] ) && isDefined( level._custom_perks[ type ].dialog ) )
		{
			sound_to_play = level._custom_perks[ type ].dialog;
		}
		self maps\so\zm_common\_zm_audio::do_player_playdialog(player_index, sound_to_play, 0.25);
	}
	else 
	{
		player_index = "plr_" + index + "_";
		if ( array_validate( level._custom_perks ) && isDefined( level._custom_perks[ type ] ) && isDefined( level._custom_perks[ type ].dialog ) )
		{
			sound_to_play = player_index + level._custom_perks[ type ].dialog;
		}
		if (level.player_is_speaking != 1 && isDefined(sound_to_play))
		{	
			level.player_is_speaking = 1;
			self playsound(sound_to_play, "sound_done");			
			self waittill("sound_done");
			level.player_is_speaking = 0;
		}	
	}
}
machine_watcher()
{
	level thread perks_a_cola_jingle();
}

//rewrite to use for loop TODO
play_vendor_stings(sound)
{	
	if(!IsDefined (level.eggs))
	{
		level.eggs = 0;
	}
	if (level.eggs == 0)
	{
		if ( isDefined( level._custom_packapunch ) && sound == level._custom_packapunch.stinger && !level._custom_packapunch.jingle_active ) 
		{
			level._custom_packapunch.jingle_active = true;
//			iprintlnbold("stinger packapunch:" + level.packa_jingle);
			temp_org_pack_s = spawn("script_origin", self.origin);		
			temp_org_pack_s playsound (sound, "sound_done");
			temp_org_pack_s waittill("sound_done");
			level._custom_packapunch.jingle_active = false;
			temp_org_pack_s delete();
//			iprintlnbold("stinger packapunch:"  + level.packa_jingle);
		}
		else if ( array_validate( level._custom_perks ) && isDefined( level._custom_perks[ self.script_noteworthy ] ) )
		{
			if ( sound == level._custom_perks[ self.script_noteworthy ].stinger && !level._custom_perks[ self.script_noteworthy ].jingle_active )
			{
				level._custom_perks[ self.script_noteworthy ].jingle_active = true;
				temp_sound = spawn("script_origin", self.origin);
				temp_sound playsound (sound, "sound_done");
				temp_sound waittill("sound_done");
				level._custom_perks[ self.script_noteworthy ].jingle_active = false;
				temp_sound delete();
			}
		}
	}
}

//rewrite to use for loop TODO
perks_a_cola_jingle()
{	
	flag_wait( "power_on" );
	packapunch = getEnt( "specialty_weapupgrade", "script_noteworthy" );
	if ( isDefined( packapunch ) )
	{
		packapunch thread play_random_broken_sounds();
	}
	perk_keys = getArrayKeys( level._custom_perks );
	for ( i = 0; i < perk_keys.size; i++ )
	{
		perk = getEnt( perk_keys[ i ], "script_noteworthy" );
		perk thread play_random_broken_sounds();
	}
	if (!IsDefined (level.eggs))
	{
		level.eggs = 0;
	}
	while ( true )
	{
		wait ( randomfloatrange( 31,45 ) );
		if ( level.eggs == 1 )
		{
			continue;
		}
		if ( randomint( 100 ) > 15 )
		{
			continue;
		}
		level notify( "jingle_playing" );
		random_perk_keys = array_randomize( getArrayKeys( level._custom_perks ) );
		if ( isDefined( level._custom_packapunch ) && level._custom_packapunch.powered_on && randomInt( random_perk_keys.size + 1 ) == 0 )
		{
			packapunch = getEnt( "specialty_weapupgrade", "script_noteworthy" );
			level._custom_packapunch.jingle_active = true;
			temp_org_packa = spawn( "script_origin", packapunch.origin );
			temp_org_packa playsound( level._custom_packapunch.jingle, "sound_done" );
			temp_org_packa waittill( "sound_done" );
			level._custom_packapunch.jingle_active = false;
			temp_org_packa delete();
			packapunch thread play_random_broken_sounds();
		}
		else if ( level._custom_perks[ random_perk_keys[ 0 ] ].powered_on )
		{
			perk = getEnt( random_perk_keys[ 0 ], "script_noteworthy" );
			level._custom_perks[ perk.script_noteworthy ].jingle_active = true;
			temp_sound = spawn( "script_origin", perk.origin );
			temp_sound playsound( level._custom_perks[ perk.script_noteworthy ].jingle, "sound_done" );
			temp_sound waittill( "sound_done" );
			level._custom_perks[ perk.script_noteworthy ].jingle_active = false;
			temp_sound delete();
		}
		for ( i = 0; i < random_perk_keys.size; i++ )
		{
			perk = getEnt( random_perk_keys[ i ], "script_noteworthy" );
			perk thread play_random_broken_sounds();
		}
	}
}

play_random_broken_sounds()
{
	level endon( "jingle_playing" );
	//assert( isDefined( self.jingle ) || isDefined( self.jingle.script_sound ), self.script_noteworthy + " has no jingle defined" );
	if ( isDefined( level._custom_perks[ self.script_noteworthy ] ) && level._custom_perks[ self.script_noteworthy ].jingle == "mx_revive_jingle")
	{
		while ( true )
		{
			wait ( randomfloatrange( 7, 18 ) );
			playsoundatposition ("broken_random_jingle", self.origin);
		//playfx (level._effect["electric_short_oneshot"], self.origin);
			playsoundatposition ("electrical_surge", self.origin);
	
		}
	}
	else
	{
		while ( true )
		{
			wait ( randomfloatrange( 7, 18 ) );
		// playfx (level._effect["electric_short_oneshot"], self.origin);
			playsoundatposition ("electrical_surge", self.origin);
		}
	}
}

register_packapunch_basic_info( str_alias, str_hint_string, n_packapunch_cost, str_packapunch_jingle, str_packapunch_stinger )
{
	_register_undefined_packapunch();
	level._custom_packapunch.alias = str_alias;
	level._custom_packapunch.hint = str_hint_string;
	level._custom_packapunch.cost = n_packapunch_cost;
	level._custom_packapunch.jingle = str_packapunch_jingle;
	level._custom_packapunch.stinger = str_packapunch_stinger;
	level._custom_packapunch.jingle_active = false;
	level._custom_packapunch.script_noteworthy = "specialty_weapupgrade";
	level._custom_packapunch.powered_on = false;
}

register_packapunch_machine( func_packapunch_machine_thread )
{
	_register_undefined_packapunch();
	level._custom_packapunch.machine_thread = func_packapunch_machine_thread;
}

register_packapunch_precache_func( func_precache )
{
	_register_undefined_packapunch();
	level._custom_packapunch.precache_func = func_precache;
}

register_packapunch_location( origin, angles, model )
{
	_register_undefined_packapunch();
	level._custom_packapunch.origin = origin;
	level._custom_packapunch.angles = angles;
	level._custom_packapunch.model = model;
	level._custom_packapunch.dynamically_spawned = true;
}

_register_undefined_packapunch()
{
	if ( !isDefined( level._custom_packapunch ) )
	{
		level._custom_packapunch = spawnStruct();
	}
}

register_perk_basic_info( str_perk, str_perk_alias, n_perk_cost, str_hint_string, str_perk_bottle_weapon, str_perk_shader, str_perk_jingle, str_perk_stinger, str_perk_dialog )
{
	assert( isdefined( str_perk ), "str_perk is a required argument for register_perk_basic_info!" );
	assert( isdefined( n_perk_cost ), "n_perk_cost is a required argument for register_perk_basic_info!" );
	assert( isdefined( str_hint_string ), "str_hint_string is a required argument for register_perk_basic_info!" );
	assert( isdefined( str_perk_bottle_weapon ), "str_perk_bottle_weapon is a required argument for register_perk_basic_info!" );
	_register_undefined_perk( str_perk );
	level._custom_perks[str_perk].alias = str_perk_alias;
	level._custom_perks[str_perk].cost = n_perk_cost;
	level._custom_perks[str_perk].hint_string = str_hint_string;
	level._custom_perks[str_perk].perk_bottle = str_perk_bottle_weapon;
	level._custom_perks[str_perk].shader = str_perk_shader;
	level._custom_perks[str_perk].jingle = str_perk_jingle;
	level._custom_perks[str_perk].jingle_active = false;
	level._custom_perks[str_perk].stinger = str_perk_stinger;
	level._custom_perks[str_perk].dialog = str_perk_dialog;
	level._custom_perks[str_perk].powered_on = false;
}

register_perk_machine( str_perk, func_perk_machine_thread )
{
	assert( isdefined( str_perk ), "str_perk is a required argument for register_perk_machine!" );
	assert( isdefined( func_perk_machine_thread ), "func_perk_machine_thread is a required argument for register_perk_machine!" );
	_register_undefined_perk( str_perk );

	level._custom_perks[str_perk].perk_machine_thread = func_perk_machine_thread;
}

register_perk_precache_func( str_perk, func_precache )
{
	assert( isdefined( str_perk ), "str_perk is a required argument for register_perk_precache_func!" );
	assert( isdefined( func_precache ), "func_precache is a required argument for register_perk_precache_func!" );
	_register_undefined_perk( str_perk );

	level._custom_perks[str_perk].precache_func = func_precache;
}

register_perk_threads( str_perk, func_give_player_perk, func_take_player_perk )
{
	assert( isdefined( str_perk ), "str_perk is a required argument for register_perk_threads!" );
	assert( isdefined( func_give_player_perk ), "func_give_player_perk is a required argument for register_perk_threads!" );
	_register_undefined_perk( str_perk );

	level._custom_perks[str_perk].player_thread_give = func_give_player_perk;

	if ( isdefined( func_take_player_perk ) )
	{
		level._custom_perks[str_perk].player_thread_take = func_take_player_perk;
	}
}

register_perk_location( str_perk, origin, angles, model )
{
	_register_undefined_perk( str_perk );
	level._custom_perks[str_perk].origin = origin;
	level._custom_perks[str_perk].angles = angles;
	level._custom_perks[str_perk].script_noteworthy = str_perk;
	level._custom_perks[str_perk].model = model;
	level._custom_perks[str_perk].dynamically_spawned = true;
}

_register_undefined_perk( str_perk )
{
	if ( !isdefined( level._custom_perks ) )
		level._custom_perks = [];

	if ( !isdefined( level._custom_perks[str_perk] ) )
		level._custom_perks[str_perk] = spawnstruct();
}

spawn_and_link_perk_kvps()
{
	if ( !isDefined( level._custom_perks ) || level._custom_perks.size <= 0 )
	{
		return;
	}
	if ( is_true( level.zm_custom_map_respawn_mapents_perks ) )
	{
		old_bump_triggers = getEntArray( "audio_bump_trigger", "targetname" );
		if ( isDefined( old_bump_triggers ) )
		{
			for ( i = 0; i < old_bump_triggers.size; i++ )
			{
				if ( isDefined( old_bump_triggers[ i ].script_sound ) && old_bump_triggers[ i ].script_sound == "perks_rattle" )
				{
					old_bump_triggers[ i ] delete();
				}
			}
		}
	}
	keys = getArrayKeys( level._custom_perks );
	for ( i = 0; i < keys.size; i++ )
	{
		if ( is_true( level._custom_perks[ keys[ i ] ].dynamically_spawned ) )
		{
			assert( isDefined( level._custom_perks[ keys[ i ] ].origin ), "origin is required to dynamically spawn a perk" );
			assert( isDefined( level._custom_perks[ keys[ i ] ].angles ), "angles is required to dynamically spawn a perk" );
			assert( isDefined( level._custom_perks[ keys[ i ] ].model ), "model is required to dynamically spawn a perk" );
			assert( isDefined( level._custom_perks[ keys[ i ] ].alias ), "alias is required to dynamically spawn a perk" );
			assert( isDefined( level._custom_perks[ keys[ i ] ].origin ), "origin is required to dynamically spawn a perk" );
			assert( isDefined( level._custom_perks[ keys[ i ] ].jingle ), "jingle is required to dynamically spawn a perk" );
			old_trigger = getEnt( keys[ i ], "script_noteworthy" );
			if ( isDefined( old_trigger ) )
			{
				old_machine = getEnt( old_trigger.target, "targetname" );
				if ( isDefined( old_machine ) )
				{
					old_machine delete();
				}
				old_trigger delete();
			}
			trigger = spawn( "trigger_radius", level._custom_perks[ keys[ i ] ].origin + ( 0, 0, 30 ), 0, 20, 70 );
			trigger.script_noteworthy = keys[ i ];
			trigger.targetname = "zombie_vending";
			trigger.target = "vending_" + level._custom_perks[ keys[ i ] ].alias;

			machine = spawn( "script_model", level._custom_perks[ keys[ i ] ].origin );
			machine.angles = level._custom_perks[ keys[ i ] ].angles;
			machine setModel( level._custom_perks[ keys[ i ] ].model );
			trigger.machine = machine;

			clip = spawnCollision( "collision_geo_32x32x128", "collider", level._custom_perks[ keys[ i ] ].origin - ( 0, 0, -64 ), level._custom_perks[ keys[ i ] ].angles );
			trigger.clip = clip;

			bump_trigger = spawn( "trigger_radius", level._custom_perks[ keys[ i ] ].origin, 0, 35, 64 );
			bump_trigger.targetname = "audio_bump_trigger";
			bump_trigger.script_sound = "perks_rattle";
			trigger.bump = bump_trigger;

			jingle = spawnStruct();
			jingle.origin = level._custom_perks[ keys[ i ] ].origin;
			jingle.angles = level._custom_perks[ keys[ i ] ].angles;
			jingle.script_sound = level._custom_perks[ keys[ i ] ].jingle;
			trigger.jingle = jingle;
		}
		else if ( is_true( level.zm_custom_map_respawn_mapents_perks ) )
		{
			assert( isDefined( level._custom_perks[ keys[ i ] ].jingle ), "jingle is required to respawn a perk" );
			old_trigger = getEnt( keys[ i ], "script_noteworthy" );
			if ( !isDefined( old_trigger ) )
			{
				continue;
			}
			old_trigger_origin = old_trigger.origin;
			old_trigger_angles = old_trigger.angles;
			old_trigger_target = old_trigger.target;
			old_trigger delete();

			new_trigger = spawn( "trigger_radius", old_trigger_origin, 0, 20, 70 );
			new_trigger.script_noteworthy = keys[ i ];
			new_trigger.targetname = "zombie_vending";
			new_trigger.target = old_trigger_target;

			old_machine = getEnt( old_trigger_target, "targetname" );
			old_machine_origin = old_machine.origin;
			old_machine_angles = old_machine.angles;
			old_machine_model = old_machine.model;

			new_machine = spawn( "script_model", old_machine_origin );
			new_machine.angles = old_machine_angles;
			new_machine setModel( old_machine_model );
			new_trigger.machine = new_machine;

			new_bump_trigger = spawn( "trigger_radius", old_trigger_origin, 0, 35, 64 );
			new_bump_trigger.targetname = "audio_bump_trigger";
			new_bump_trigger.script_sound = "perks_rattle";
			new_trigger.bump = new_bump_trigger;

			jingle = spawnStruct();
			jingle.origin = new_trigger.origin;
			jingle.angles = new_trigger.angles;
			jingle.script_sound = level._custom_perks[ keys[ i ] ].jingle;
			new_trigger.jingle = jingle;
		}
	}
}

spawn_and_link_packapunch_kvps()
{
	if ( !isDefined( level._custom_packapunch ) )
	{
		return;
	}
	if ( is_true( level._custom_packapunch.dynamically_spawned ) )
	{
		assert( isDefined( level._custom_packapunch.origin ), "origin is required to dynamically spawn packapunch" );
		assert( isDefined( level._custom_packapunch.angles ), "angles is required to dynamically spawn packapunch" );
		assert( isDefined( level._custom_packapunch.model ), "model is required to dynamically spawn packapunch" );
		assert( isDefined( level._custom_packapunch.alias ), "alias is required to dynamically spawn packapunch" );
		assert( isDefined( level._custom_packapunch.origin ), "origin is required to dynamically spawn packapunch" );
		assert( isDefined( level._custom_packapunch.jingle ), "jingle is required to dynamically spawn packapunch" );
		old_trigger = getEnt( level._custom_packapunch.script_noteworthy, "script_noteworthy" );
		if ( isDefined( old_trigger ) )
		{
			old_machine = getEnt( old_trigger.target, "targetname" );
			if ( isDefined( old_machine ) )
			{
				old_flag = GetEnt( old_machine.target, "targetname" );
				if ( isDefined( old_flag ) )
				{
					old_flag delete();
				}
				old_machine delete();
			}
			old_trigger delete();
		}
		trigger = spawn( "trigger_radius", level._custom_packapunch.origin + ( 0, 0, 30 ), 0, 20, 70 );
		trigger.script_noteworthy = "specialty_weapupgrade";
		trigger.targetname = "zombie_vending";
		trigger.target = "vending_" + level._custom_packapunch.alias;

		machine = spawn( "script_model", level._custom_packapunch.origin );
		machine.angles = level._custom_packapunch.angles;
		machine setModel( level._custom_packapunch.model );
		trigger.machine = machine;

		flag = spawn( "script_model", ( 0, 0, 0 ) );
		flag.targetname = "weapupgrade_flag_targ";
		flag setModel( "zombie_sign_please_wait" );
		flag.angles = level._custom_packapunch.angles + ( 0, 180, 180 );
		flag.origin = level._custom_packapunch.origin + ( anglesToForward( level._custom_packapunch.angles ) * 29 ) + ( anglesToRight( level._custom_packapunch.angles ) * -13.5 ) + ( anglesToUp( level._custom_packapunch.angles ) * 49.5 );
		machine.target = flag.targetname;

		clip = spawnCollision( "collision_geo_32x32x128", "collider", level._custom_packapunch.origin - ( 0, 0, -64 ), level._custom_packapunch.angles );
		trigger.clip = clip;

		jingle = spawnStruct();
		jingle.origin = level._custom_packapunch.origin;
		jingle.angles = level._custom_packapunch.angles;
		jingle.script_sound = level._custom_packapunch.jingle;
		trigger.jingle = jingle;

	}
	else if ( is_true( level.zm_custom_map_respawn_mapents_perks ) )
	{
		assert( isDefined( level._custom_packapunch.jingle ), "jingle is required to respawn packapunch" );
		old_trigger = getEnt( level._custom_packapunch.script_noteworthy, "script_noteworthy" );
		if ( !isDefined( old_trigger ) )
		{
			return;
		}
		old_trigger_origin = old_trigger.origin;
		old_trigger_angles = old_trigger.angles;
		old_trigger_target = old_trigger.target;
		old_trigger delete();

		new_trigger = spawn( "trigger_radius", old_trigger_origin, 0, 20, 70 );
		new_trigger.script_noteworthy = level._custom_packapunch.script_noteworthy;
		new_trigger.targetname = "zombie_vending";
		new_trigger.target = old_trigger_target;

		old_machine = getEnt( old_trigger_target, "targetname" );
		old_machine_origin = old_machine.origin;
		old_machine_angles = old_machine.angles;
		old_machine_model = old_machine.model;
		if ( isDefined( old_machine ) )
		{
			old_machine delete();
		}

		new_machine = spawn( "script_model", old_machine_origin );
		new_machine.angles = old_machine_angles;
		new_machine setModel( old_machine_model );
		new_trigger.machine = new_machine;

		flag = spawn( "script_model", ( 0, 0, 0 ) );
		flag.targetname = "weapupgrade_flag_targ";
		flag setModel( "zombie_sign_please_wait" );
		flag.angles = old_machine_angles + ( 0, 180, 180 );
		flag.origin = old_machine_origin + ( anglesToForward( old_machine_angles ) * 29 ) + ( anglesToRight( old_machine_angles ) * -13.5 ) + ( anglesToUp( old_machine_angles ) * 49.5 );
		new_machine.target = flag.targetname;

		jingle = spawnStruct();
		jingle.origin = new_trigger.origin;
		jingle.angles = new_trigger.angles;
		jingle.script_sound = level._custom_packapunch.jingle;
		new_trigger.jingle = jingle;
	}
}

delete_perk( str_perk )
{
	trigger = getEnt( str_perk, "script_noteworthy" );
	if ( !isDefined( trigger ) )
	{
		return;
	}
	if ( isDefined( trigger.clip ) )
	{
		trigger.clip delete();
	}
	if ( isDefined( trigger.machine ) )
	{
		trigger.machine delete();
	}
	if ( isDefined( trigger.bump ) )
	{
		trigger.bump delete();
	}
	trigger delete();
}

move_perk( str_perk, origin, angles )
{
	trigger = getEnt( str_perk, "script_noteworthy" );
	if ( !isDefined( trigger ) )
	{
		return;
	}
	if ( isDefined( trigger.clip ) )
	{
		trigger.clip.origin = origin;
		trigger.clip.angles = angles;
	}
	if ( isDefined( trigger.machine ) )
	{
		trigger.machine.origin = origin;
		trigger.machine.angles = angles;
	}
	if ( isDefined( trigger.bump ) )
	{
		trigger.bump.origin = origin;
		trigger.bump.angles = angles;
	}
	trigger.origin = origin;
	trigger.angles = angles;	
}