#include maps\_utility; 
#include common_scripts\utility; 
#include maps\so\zm_common\_zm_utility;

init()
{
	vending_triggers = GetEntArray( "zombie_vending", "targetname" );
	
	if ( vending_triggers.size < 1 )
	{
		return;
	}

	if( !isDefined( level.packapunch_timeout ) )
	{
		level.packapunch_timeout = 15;
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
	level.speed_jingle = 0;

	vending_upgrade_trigger = GetEntArray("zombie_vending_upgrade", "targetname");

	if ( vending_upgrade_trigger.size < 1 )
	{
		return;
	}
	PrecacheItem( "zombie_knuckle_crack" );
	precachemodel("zombie_vending_packapunch_on");
	level._effect["packapunch_fx"] = loadfx("maps/zombie/fx_zombie_packapunch");
	PrecacheString( &"ZOMBIE_PERK_PACKAPUNCH" );

	array_thread( vending_upgrade_trigger, ::vending_upgrade );
	level thread turn_PackAPunch_on();	

	level.packa_jingle = 0;
}

third_person_weapon_upgrade( current_weapon, origin, angles, packa_rollers, perk_machine )
{
	forward = anglesToForward( angles );
	interact_pos = origin + (forward*-25);
	
	worldgun = spawn( "script_model", interact_pos );
	worldgun.angles  = self.angles;
	worldgun setModel( GetWeaponModel( current_weapon ) );
	PlayFx( level._effect["packapunch_fx"], origin+(0,1,-34), forward );
	
	worldgun rotateto( angles+(0,90,0), 0.35, 0, 0 );
	wait( 0.5 );
	worldgun moveto( origin, 0.5, 0, 0 );
	packa_rollers playsound( "packa_weap_upgrade" );
	if( isDefined( perk_machine.wait_flag ) )
	{
		perk_machine.wait_flag rotateto( perk_machine.wait_flag.angles+(179, 0, 0), 0.25, 0, 0 );
	}
	wait( 0.35 );
	worldgun delete();
	wait( 3 );
	packa_rollers playsound( "packa_weap_ready" );
	worldgun = spawn( "script_model", origin );
	worldgun.angles  = angles+(0,90,0);
	worldgun setModel( GetWeaponModel( current_weapon+"_upgraded" ) );
	worldgun moveto( interact_pos, 0.5, 0, 0 );
	if( isDefined( perk_machine.wait_flag ) )
	{
		perk_machine.wait_flag rotateto( perk_machine.wait_flag.angles-(179, 0, 0), 0.25, 0, 0 );
	}
	wait( 0.5 );
	worldgun moveto( origin, level.packapunch_timeout, 0, 0);
	return worldgun;
}

vending_upgrade()
{
	perk_machine = GetEnt( self.target, "targetname" );
	if( isDefined( perk_machine.target ) )
	{
		perk_machine.wait_flag = GetEnt( perk_machine.target, "targetname" );
	}
	
	self UseTriggerRequireLookAt();
	self SetHintString( &"ZOMBIE_FLAMES_UNAVAILABLE" );
	self SetCursorHint( "HINT_NOICON" );
	level waittill("Pack_A_Punch_on");
	
	self thread maps\so\zm_common\_zm_weapons::decide_hide_show_hint();
	
	packa_rollers = spawn("script_origin", self.origin);
	packa_timer = spawn("script_origin", self.origin);
	packa_rollers playloopsound("packa_rollers_loop");
	
	self SetHintString( &"ZOMBIE_PERK_PACKAPUNCH" );
	cost = level.zombie_vars["zombie_perk_cost"];
	
	for( ;; )
	{
		self waittill( "trigger", player );
		index = maps\so\zm_common\_zm_weapons::get_player_index(player);	
		cost = 5000;
		plr = "plr_" + index + "_";
		
		if( !player maps\so\zm_common\_zm_weapons::can_buy_weapon() )
		{
			wait( 0.1 );
			continue;
		}
		
		if (player maps\_laststand::player_is_in_laststand() )
		{
			wait( 0.1 );
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
		
		current_weapon = player getCurrentWeapon();

		if( !IsDefined( level.zombie_include_weapons[current_weapon] ) || !IsDefined( level.zombie_include_weapons[current_weapon + "_upgraded"] ) )
		{
			continue;
		}

		if ( player.score < cost )
		{
			//player iprintln( "Not enough points to buy Perk: " + perk );
			self playsound("deny");
			player thread maps\so\zm_common\_zm_audio::play_no_money_perk_dialog();
			continue;
		}
		player maps\so\zm_common\_zm_score::minus_to_player_score( cost ); 
		self achievement_notify("perk_used");
		sound = "bottle_dispense3d";
		playsoundatposition(sound, self.origin);
		rand = randomintrange(1,100);
		
		if( rand <= 8 )
		{
			player thread play_packa_wait_dialog(plr);
		}
		
		self thread play_vendor_stings("mx_packa_sting");
		
		origin = self.origin;
		angles = self.angles;
		
		if( isDefined(perk_machine))
		{
			origin = perk_machine.origin+(0,0,35);
			angles = perk_machine.angles+(0,90,0);
		}
		
		self disable_trigger();
		
		player thread do_knuckle_crack();

		// Remember what weapon we have.  This is needed to check unique weapon counts.
		self.current_weapon = current_weapon;
											
		weaponmodel = player third_person_weapon_upgrade( current_weapon, origin, angles, packa_rollers, perk_machine );
		
		self enable_trigger();
		self SetHintString( &"ZOMBIE_GET_UPGRADED" );
		self setvisibletoplayer( player );
		
		self thread wait_for_player_to_take( player, current_weapon, packa_timer );
		self thread wait_for_timeout( packa_timer );
		
		self waittill_either( "pap_timeout", "pap_taken" );
		
		self.current_weapon = "";
		weaponmodel delete();
		self SetHintString( &"ZOMBIE_PERK_PACKAPUNCH" );
		self setvisibletoall();
	}
}

wait_for_player_to_take( player, weapon, packa_timer )
{
	index = maps\so\zm_common\_zm_weapons::get_player_index(player);
	plr = "plr_" + index + "_";
	
	self endon( "pap_timeout" );
	while( true )
	{
		packa_timer playloopsound( "ticktock_loop" );
		self waittill( "trigger", trigger_player );
		packa_timer stoploopsound(.05);
		if( trigger_player == player ) 
		{
			if( !player maps\_laststand::player_is_in_laststand() && !( isDefined( player.is_drinking ) && player.is_drinking > 0 ) && player getCurrentWeapon() != "mine_bouncing_betty" )
			{
				self notify( "pap_taken" );
				weapon_limit = get_player_weapon_limit( player );
				primaries = player GetWeaponsListPrimaries();
				if( isDefined( primaries ) && primaries.size >= weapon_limit )
				{
					player maps\so\zm_common\_zm_weapons::weapon_give( weapon+"_upgraded" );
				}
				else
				{
					player GiveWeapon( weapon+"_upgraded" );
					player GiveMaxAmmo( weapon+"_upgraded" );
				}
				
				player SwitchToWeapon( weapon+"_upgraded" );
				player achievement_notify( "DLC3_ZOMBIE_PAP_ONCE" );
				player achievement_notify( "DLC3_ZOMBIE_TWO_UPGRADED" );
				player thread play_packa_get_dialog(plr);
				return;
			}
		}
		wait( 0.05 );
	}
}

wait_for_timeout( packa_timer )
{
	self endon( "pap_taken" );
	
	wait( level.packapunch_timeout );
	
	self notify( "pap_timeout" );
	packa_timer stoploopsound(.05);
	packa_timer playsound( "packa_deny" );
}

do_knuckle_crack()
{
	gun = self upgrade_knuckle_crack_begin();
	self waittill_any( "fake_death", "death", "player_downed", "weapon_change_complete" );
	
	self upgrade_knuckle_crack_end( gun );
	self.is_drinking = undefined;
}

upgrade_knuckle_crack_begin()
{
	self increment_is_drinking();

	self AllowLean( false );
	self AllowAds( false );
	self AllowSprint( false );
	self AllowProne( false );		
	self AllowMelee( false );
	
	if ( self GetStance() == "prone" )
	{
		self SetStance( "crouch" );
	}

	primaries = self GetWeaponsListPrimaries();

	gun = self GetCurrentWeapon();
	weapon = "zombie_knuckle_crack";
	
	if ( gun != "none" && gun != "mine_bouncing_betty" )
	{
		self TakeWeapon( gun );
	}
	else
	{
		return;
	}

	if( primaries.size <= 1 )
	{
		self GiveWeapon( "zombie_colt" );
	}
	
	self GiveWeapon( weapon );
	self SwitchToWeapon( weapon );

	return gun;
}

upgrade_knuckle_crack_end( gun )
{
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
	weapon = "zombie_knuckle_crack";

	// TODO: race condition?
	if ( self maps\_laststand::player_is_in_laststand() )
	{
		self TakeWeapon(weapon);
		return;
	}

	self decrement_is_drinking();
	self TakeWeapon(weapon);
	primaries = self GetWeaponsListPrimaries();
	if ( isDefined( self.is_drinking ) && self.is_drinking > 0 )
		return;	
	else if( isDefined( primaries ) && primaries.size > 0 )
	{
		self SwitchToWeapon( primaries[0] );
	}
	else
	{
		self SwitchToWeapon( "zombie_colt" );
	}
}

// PI_CHANGE_BEGIN
// JMA - in order to have multiple Pack-A-Punch machines in a map we're going to have
//			to run a thread on each on.
//	NOTE:  In the .map, you'll have to make sure that each Pack-A-Punch machine has a unique targetname
turn_PackAPunch_on()
{
	level waittill("Pack_A_Punch_on");

	vending_upgrade_trigger = GetEntArray("zombie_vending_upgrade", "targetname");
	for(i=0; i<vending_upgrade_trigger.size; i++ )
	{
		perk = getent(vending_upgrade_trigger[i].target, "targetname");
		if(isDefined(perk))
		{
			perk thread activate_PackAPunch();
		}
	}
}

activate_PackAPunch()
{
	self setmodel("zombie_vending_packapunch_on");
	self playsound("perks_power_on");
	self vibrate((0,-100,0), 0.3, 0.4, 3);
	/*
	self.flag = spawn( "script_model", machine GetTagOrigin( "tag_flag" ) );
	self.angles = machine GetTagAngles( "tag_flag" );
	self.flag setModel( "zombie_sign_please_wait" );
	self.flag linkto( machine );
	self.flag.origin = (0, 40, 40);
	self.flag.angles = (0, 0, 0);
	*/
	timer = 0;
	duration = 0.05;

	level notify( "Carpenter_On" );
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
		players = get_players();
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

		self thread vending_trigger_post_think( player, perk );
	}
}

vending_trigger_post_think( player, perk )
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
	player.is_drinking = undefined;
	// TODO: race condition?
	if ( player maps\_laststand::player_is_in_laststand() )
	{
		continue;
	}
	if ( array_validate( level._custom_perks ) && isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].player_thread_give ) )
		self thread [[ level._custom_perks[perk].player_thread_give ]]();
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
			players = get_players();
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
			self sethintstring( level._custom_perks[perk].hint_string, level._custom_perks[perk].cost );
	}
}

perk_think( perk )
{
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
		self.maxhealth = 100;
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

	if ( !self maps\mp\zombies\_zm_laststand::player_is_in_laststand() && !( isdefined( self.intermission ) && self.intermission ) )
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
	//PI ESM - support for two level switches for Factory
	if (isDefined(level.script) && level.script == "nazi_zombie_factory" || level.script == "nazi_zombie_paris" || level.script == "nazi_zombie_coast")
	{
		level thread machine_watcher_factory("Pack_A_Punch_on");
		if ( array_validate( level._custom_perks ) )
		{
			keys = getArrayKeys( level._custom_perks );
			for ( i = 0; i < keys.size; i++ )
			{
				level thread machine_watcher_factory( level._custom_perks[ keys[ i ] ].alias + "_on", keys[ i ] );
			}
		}
	}
	else
	{		
		level waittill("master_switch_activated");
		array_thread(getentarray( "zombie_vending", "targetname" ), ::perks_a_cola_jingle);	
				
	}		
	
}

//PI ESM - added for support for two switches in factory
machine_watcher_factory(vending_name, perk)
{
	level waittill(vending_name);
	switch(vending_name)
	{
		case "Pack_A_Punch_on":
			temp_script_sound = "mx_packa_jingle";
			break;		
		default:
			if ( array_validate( level._custom_perks ) && isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].jingle ) )
			{
				temp_script_sound = level._custom_perks[ perk ].jingle;
			}
			break;
	}


	temp_machines = getstructarray("perksacola", "targetname");
	for (x = 0; x < temp_machines.size; x++)
	{
		if (temp_machines[x].script_sound == temp_script_sound)
			temp_machines[x] thread perks_a_cola_jingle();
	}

}

play_vendor_stings(sound)
{	
	if(!IsDefined (level.speed_jingle))
	{
		level.speed_jingle = 0;
	}
	if(!IsDefined (level.packa_jingle))
	{
		level.packa_jingle = 0;
	}
	if(!IsDefined (level.eggs))
	{
		level.eggs = 0;
	}
	if (level.eggs == 0)
	{
		if(sound == "mx_packa_sting" && level.packa_jingle == 0) 
		{
			level.packa_jingle = 1;
//			iprintlnbold("stinger packapunch:" + level.packa_jingle);
			temp_org_pack_s = spawn("script_origin", self.origin);		
			temp_org_pack_s playsound (sound, "sound_done");
			temp_org_pack_s waittill("sound_done");
			level.packa_jingle = 0;
			temp_org_pack_s delete();
//			iprintlnbold("stinger packapunch:"  + level.packa_jingle);
		}
		else if ( array_validate( level._custom_perks ) && isDefined( level._custom_perks[ self.script_noteworthy ] ) )
		{
			if ( sound == level._custom_perks[ self.script_noteworthy ].jingle && !level._custom_perks[ keys[ i ] ].jingle_active )
			{
				level._custom_perks[ self.script_noteworthy ].jingle_active = true;
				temp_sound = spawn("script_origin", self.origin);
				temp_sound playsound (self.script_sound, "sound_done");
				temp_sound waittill("sound_done");
				level._custom_perks[ self.script_noteworthy ].jingle_active = false;
				temp_sound delete();
			}
		}
	}
}

perks_a_cola_jingle()
{	
	self thread play_random_broken_sounds();
	if(!IsDefined(self.perk_jingle_playing))
	{
		self.perk_jingle_playing = 0;
	}
	if (!IsDefined (level.eggs))
	{
		level.eggs = 0;
	}
	while(1)
	{
		//wait(randomfloatrange(60, 120));
		wait(randomfloatrange(31,45));
		if(randomint(100) < 15 && level.eggs == 0)
		{
			level notify ("jingle_playing");
			//playfx (level._effect["electric_short_oneshot"], self.origin);
			playsoundatposition ("electrical_surge", self.origin);
			
			if(self.script_sound == "mx_packa_jingle" && level.packa_jingle == 0) 
			{
				level.packa_jingle = 1;
				temp_org_packa = spawn("script_origin", self.origin);
				temp_org_packa playsound (self.script_sound, "sound_done");
				temp_org_packa waittill("sound_done");
				level.packa_jingle = 0;
				temp_org_packa delete();
			}
			
			if ( array_validate( level._custom_perks ) && isDefined( level._custom_perks[ self.script_noteworthy ] ) )
			{
				if ( self.script_sound == level._custom_perks[ self.script_noteworthy ].jingle && !level._custom_perks[ keys[ i ] ].jingle_active )
				{
					level._custom_perks[ self.script_noteworthy ].jingle_active = true;
					temp_sound = spawn("script_origin", self.origin);
					temp_sound playsound (self.script_sound, "sound_done");
					temp_sound waittill("sound_done");
					level._custom_perks[ self.script_noteworthy ].jingle_active = false;
					temp_sound delete();
				}
			}

			self thread play_random_broken_sounds();
		}		
	}	
}

play_random_broken_sounds()
{
	level endon ("jingle_playing");
	if (!isdefined (self.script_sound))
	{
		self.script_sound = "null";
	}
	if (self.script_sound == "mx_revive_jingle")
	{
		while(1)
		{
			wait(randomfloatrange(7, 18));
			playsoundatposition ("broken_random_jingle", self.origin);
		//playfx (level._effect["electric_short_oneshot"], self.origin);
			playsoundatposition ("electrical_surge", self.origin);
	
		}
	}
	else
	{
		while(1)
		{
			wait(randomfloatrange(7, 18));
		// playfx (level._effect["electric_short_oneshot"], self.origin);
			playsoundatposition ("electrical_surge", self.origin);
		}
	}
}

play_packa_wait_dialog(player_index)
{
	waittime = 0.05;
	if(!IsDefined (self.vox_perk_packa_wait))
	{
		num_variants = maps\so\zm_common\_zm_audio::get_number_variants(player_index + "vox_perk_packa_wait");
		self.vox_perk_packa_wait = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_perk_packa_wait[self.vox_perk_packa_wait.size] = "vox_perk_packa_wait_" + i;
		}
		self.vox_perk_packa_wait_available = self.vox_perk_packa_wait;
	}
	if(!isdefined (level.player_is_speaking))
	{
		level.player_is_speaking = 0;
	}
	sound_to_play = random(self.vox_perk_packa_wait_available);
	self maps\so\zm_common\_zm_audio::do_player_playdialog(player_index, sound_to_play, waittime);
	self.vox_perk_packa_wait_available = array_remove(self.vox_perk_packa_wait_available,sound_to_play);
	
	if (self.vox_perk_packa_wait_available.size < 1 )
	{
		self.vox_perk_packa_wait_available = self.vox_perk_packa_wait;
	}
}

play_packa_get_dialog(player_index)
{
	waittime = 0.05;
	if(!IsDefined (self.vox_perk_packa_get))
	{
		num_variants = maps\so\zm_common\_zm_audio::get_number_variants(player_index + "vox_perk_packa_get");
		self.vox_perk_packa_get = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_perk_packa_get[self.vox_perk_packa_get.size] = "vox_perk_packa_get_" + i;
		}
		self.vox_perk_packa_get_available = self.vox_perk_packa_get;
	}
	if(!isdefined (level.player_is_speaking))
	{
		level.player_is_speaking = 0;
	}
	sound_to_play = random(self.vox_perk_packa_get_available);
	self maps\so\zm_common\_zm_audio::do_player_playdialog(player_index, sound_to_play, waittime);
	self.vox_perk_packa_get_available = array_remove(self.vox_perk_packa_get_available,sound_to_play);
	
	if (self.vox_perk_packa_get_available.size < 1 )
	{
		self.vox_perk_packa_get_available = self.vox_perk_packa_get;
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
}

register_perk_machine( str_perk, func_perk_machine_thread )
{
	assert( isdefined( str_perk ), "str_perk is a required argument for register_perk_machine!" );
	assert( isdefined( func_perk_machine_setup ), "func_perk_machine_setup is a required argument for register_perk_machine!" );
	assert( isdefined( func_perk_machine_thread ), "func_perk_machine_thread is a required argument for register_perk_machine!" );
	_register_undefined_perk( str_perk );

	if ( !isdefined( level._custom_perks[str_perk].perk_machine_thread ) )
		level._custom_perks[str_perk].perk_machine_thread = func_perk_machine_thread;
}

register_perk_precache_func( str_perk, func_precache )
{
	assert( isdefined( str_perk ), "str_perk is a required argument for register_perk_precache_func!" );
	assert( isdefined( func_precache ), "func_precache is a required argument for register_perk_precache_func!" );
	_register_undefined_perk( str_perk );

	if ( !isdefined( level._custom_perks[str_perk].precache_func ) )
		level._custom_perks[str_perk].precache_func = func_precache;
}

register_perk_threads( str_perk, func_give_player_perk, func_take_player_perk )
{
	assert( isdefined( str_perk ), "str_perk is a required argument for register_perk_threads!" );
	assert( isdefined( func_give_player_perk ), "func_give_player_perk is a required argument for register_perk_threads!" );
	_register_undefined_perk( str_perk );

	if ( !isdefined( level._custom_perks[str_perk].player_thread_give ) )
		level._custom_perks[str_perk].player_thread_give = func_give_player_perk;

	if ( isdefined( func_take_player_perk ) )
	{
		if ( !isdefined( level._custom_perks[str_perk].player_thread_take ) )
			level._custom_perks[str_perk].player_thread_take = func_take_player_perk;
	}
}

_register_undefined_perk( str_perk )
{
	if ( !isdefined( level._custom_perks ) )
		level._custom_perks = [];

	if ( !isdefined( level._custom_perks[str_perk] ) )
		level._custom_perks[str_perk] = spawnstruct();
}