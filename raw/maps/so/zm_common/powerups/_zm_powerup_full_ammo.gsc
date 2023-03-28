#include maps\_utility; 
#include common_scripts\utility;
#include maps\so\zm_common\_zm_utility;

enable_full_ammo_powerup_for_level()
{
	maps\so\zm_common\_zm_powerups::register_powerup_basic_info( "full_ammo", "zombie_ammocan", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_always_drop, false, false, false );
	maps\so\zm_common\_zm_powerups::register_powerup_setup( "full_ammo", ::full_ammo_precache, ::full_ammo_setup );
	maps\so\zm_common\_zm_powerups::register_powerup_grab_info( "full_ammo", ::full_ammo_grab, undefined, undefined );
}

func_should_always_drop()
{
	return true;
}

full_ammo_precache()
{

}

full_ammo_setup()
{
	level.max_ammo_refill_clips = false;
}

full_ammo_grab( powerup, player )
{
	level thread full_ammo_powerup( powerup );
	player thread maps\so\zm_common\_zm_powerups::powerup_vo("full_ammo");
}

full_ammo_powerup( drop_item )
{
	players = getPlayers();

	for (i = 0; i < players.size; i++)
	{
		primaryWeapons = players[i] GetWeaponsList(); 

		for( x = 0; x < primaryWeapons.size; x++ )
		{
			players[i] GiveMaxAmmo( primaryWeapons[x] );
			if ( level.max_ammo_refill_clips )
			{
				players[ i ] setWeaponAmmoClip( primaryWeapons[ x ], weaponClipSize( primaryWeapons[ x ] ) );
			}
		}
	}
	//	array_thread (players, ::full_ammo_on_hud, drop_item);
	level thread full_ammo_on_hud( drop_item );
}

full_ammo_on_hud( drop_item )
{
	self endon ("disconnect");

	// set up the hudelem
	hudelem = maps\_hud_util::createFontString( "objective", 2 );
	hudelem maps\_hud_util::setPoint( "TOP", undefined, 0, level.zombie_vars["zombie_timer_offset"] - (level.zombie_vars["zombie_timer_offset_interval"] * 2));
	hudelem.sort = 0.5;
	hudelem.alpha = 0;
	hudelem fadeovertime(0.5);
	hudelem.alpha = 1;
	hudelem.label = drop_item.hint;

	// set time remaining for insta kill
	hudelem thread full_ammo_move_hud();		

	// offset in case we get another powerup
	//level.zombie_timer_offset -= level.zombie_timer_offset_interval;
}

full_ammo_move_hud()
{

	players = getPlayers();
	if ( !is_true( level.use_legacy_powerup_system ) )
	{
		level thread maps\so\zm_common\_zm_powerups::play_devil_dialog("ma_vox");
	}
	for (i = 0; i < players.size; i++)
	{
		players[i] playsound ("full_ammo");
	}

	wait 0.5;
	move_fade_time = 1.5;

	self FadeOverTime( move_fade_time ); 
	self MoveOverTime( move_fade_time );
	self.y = 270;
	self.alpha = 0;

	wait move_fade_time;

	self maps\_hud_util::destroyelem();
}