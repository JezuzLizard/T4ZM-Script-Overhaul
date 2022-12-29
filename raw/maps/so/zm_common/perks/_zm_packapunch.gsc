#include maps\_utility; 
#include common_scripts\utility; 
#include maps\so\zm_common\_zm_utility;

enable_packapunch_for_level()
{
	if( !isDefined( level.packapunch_timeout ) )
	{
		level.packapunch_timeout = 15;
	}
	maps\so\zm_common\_zm_perks::register_packapunch_basic_info( "Pack_A_Punch", &"ZOMBIE_PERK_PACKAPUNCH", 5000, "mx_packa_jingle", "mx_packa_sting" );
	maps\so\zm_common\_zm_perks::register_packapunch_machine( ::turn_PackAPunch_on );
	maps\so\zm_common\_zm_perks::register_packapunch_precache_func( ::packapunch_precache );
	if ( isDefined( level.zm_custom_map_perk_machine_loc_funcs ) && isDefined( level.zm_custom_map_perk_machine_loc_funcs[ "specialty_weapupgrade" ] ) )
	{
		level [[ level.zm_custom_map_perk_machine_loc_funcs[ "specialty_weapupgrade" ] ]]();
	}
}

packapunch_precache()
{
	PrecacheItem( "zombie_knuckle_crack" );
	precachemodel("zombie_vending_packapunch_on");
	level._effect["packapunch_fx"] = loadfx("maps/zombie/fx_zombie_packapunch");
	PrecacheString( &"ZOMBIE_PERK_PACKAPUNCH" );	
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
	
	self SetHintString( level._custom_packapunch.hint );
	for( ;; )
	{
		self waittill( "trigger", player );
		index = maps\so\zm_common\_zm_weapons::get_player_index(player);	
		cost = level._custom_packapunch.cost;
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
		self maps\so\zm_common\_zm_utility::achievement_notify("perk_used");
		sound = "bottle_dispense3d";
		playsoundatposition(sound, self.origin);
		rand = randomintrange(1,100);
		
		if( rand <= 8 )
		{
			player thread play_packa_wait_dialog(plr);
		}
		
		self thread maps\so\zm_common\_zm_perks::play_vendor_stings("mx_packa_sting");
		
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
		self SetHintString( level._custom_packapunch.hint );
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
				weapon_limit = 2;

				if ( isDefined( level.get_player_weapon_limit_func ) )
				{
					weapon_limit = [[ level.get_player_weapon_limit_func ]]( player );
				}
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
	level._custom_packapunch.powered_on = true;
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