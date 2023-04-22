#include maps\_utility; 
#include common_scripts\utility;
#include maps\so\zm_common\_zm_utility;

enable_insta_kill_powerup_for_level()
{
	maps\so\zm_common\_zm_powerups::register_powerup_basic_info( "insta_kill", "zombie_skull", &"ZOMBIE_POWERUP_INSTA_KILL", ::func_should_always_drop, false, false, false );
	maps\so\zm_common\_zm_powerups::register_powerup_setup( "insta_kill", ::insta_kill_precache, ::insta_kill_setup );
	maps\so\zm_common\_zm_powerups::register_powerup_grab_info( "insta_kill", ::insta_kill_grab, undefined, undefined );
	maps\so\zm_common\_zm_powerups::register_powerup_hud_info( "insta_kill", "specialty_instakill_zombies", "zombie_powerup_insta_kill_time", "zombie_powerup_insta_kill_on" );
	maps\so\zm_common\_zm_powerups::register_powerup_player_setup( "insta_kill", ::insta_kill_player_setup );
}

func_should_always_drop()
{
	return true;
}

insta_kill_precache()
{
	if ( !is_true( level.use_legacy_powerup_system ) )
	{
		PrecacheShader( "specialty_instakill_zombies" );
	}
}

insta_kill_setup()
{
	level.insta_kill_duration = 30;
	set_zombie_var( "zombie_insta_kill", 				0 );
	set_zombie_var( "zombie_powerup_insta_kill_on", 	false );
	set_zombie_var( "zombie_powerup_insta_kill_time", 	level.insta_kill_duration );	// length of insta kill
}

insta_kill_player_setup()
{
	if ( !is_true( level.use_legacy_powerup_system ) )
	{
		self maps\so\zm_common\_zm_powerups::register_powerup_hud_player_info( "insta_kill" );
	}
}

insta_kill_grab( powerup, player )
{
	level thread insta_kill_powerup( powerup );
	player thread maps\so\zm_common\_zm_powerups::powerup_vo("insta_kill");
}

insta_kill_powerup( drop_item )
{
	level notify( "powerup instakill" );
	level endon( "powerup instakill" );

		
	//	array_thread (players, ::insta_kill_on_hud, drop_item);
	level thread insta_kill_on_hud( drop_item );

	level.zombie_vars["zombie_insta_kill"] = 1;
	wait( level.insta_kill_duration );
	level.zombie_vars["zombie_insta_kill"] = 0;
	players = getPlayers();
	for(i = 0; i < players.size; i++)
	{
		players[i] notify("insta_kill_over");

	}

}

insta_kill_on_hud( drop_item )
{
	// check to see if this is on or not
	if ( level.zombie_vars["zombie_powerup_insta_kill_on"] )
	{
		// reset the time and keep going
		level.zombie_vars["zombie_powerup_insta_kill_time"] = level.insta_kill_duration;
		return;
	}

	level.zombie_vars["zombie_powerup_insta_kill_on"] = true;

	// set up the hudelem
	if ( is_true( level.use_legacy_powerup_system ) )
	{
		hudelem = maps\_hud_util::createFontString( "objective", 2 );
		hudelem maps\_hud_util::setPoint( "TOP", undefined, 0, level.zombie_vars["zombie_timer_offset"] + level.zombie_vars["zombie_timer_offset_interval"]);
		hudelem.sort = 0.5;
		hudelem.alpha = 0;
		hudelem fadeovertime(0.5);
		hudelem.alpha = 1;
		hudelem.label = drop_item.hint;
		hudelem thread time_remaning_on_insta_kill_powerup();
	} 
	else 
	{
		// set time remaining for insta kill
		level thread time_remaning_on_insta_kill_powerup();	
	}

	// offset in case we get another powerup
	//level.zombie_timer_offset -= level.zombie_timer_offset_interval;
}

time_remaning_on_insta_kill_powerup()
{
	if ( !is_true( level.use_legacy_powerup_system ) )
	{
		level thread maps\so\zm_common\_zm_powerups::play_devil_dialog("insta_vox");
	}
	else 
	{
		self setvalue( level.zombie_vars["zombie_powerup_insta_kill_time"] );
	}
	temp_enta = spawn_temp_entity_delete_after_notify( "script_origin", (0, 0, 0), undefined, "time_remaning_on_insta_kill_powerup", "time_remaning_on_insta_kill_powerup_delete" );
	temp_enta playloopsound("insta_kill_loop");	

	/*
	players = getPlayers();
	for (i = 0; i < players.size; i++)
	{
	players[i] playloopsound ("insta_kill_loop");
	}
	*/


	// time it down!
	while ( level.zombie_vars["zombie_powerup_insta_kill_time"] >= 0)
	{
		if ( !is_true( level.use_legacy_powerup_system ) )
		{
			wait 0.1;
			level.zombie_vars["zombie_powerup_insta_kill_time"] = level.zombie_vars["zombie_powerup_insta_kill_time"] - 0.1;
		}
		else 
		{
			wait 1;
			level.zombie_vars["zombie_powerup_insta_kill_time"] = level.zombie_vars["zombie_powerup_insta_kill_time"] - 1;
			self setvalue( level.zombie_vars["zombie_powerup_insta_kill_time"] );
		}
	}

	players = getPlayers();
	for (i = 0; i < players.size; i++)
	{
		//players[i] stoploopsound (2);

		players[i] playsound("insta_kill");

	}

	temp_enta stoploopsound(2);
	// turn off the timer
	level.zombie_vars["zombie_powerup_insta_kill_on"] = false;

	// remove the offset to make room for new powerups, reset timer for next time
	level.zombie_vars["zombie_powerup_insta_kill_time"] = level.insta_kill_duration;
	//level.zombie_timer_offset += level.zombie_timer_offset_interval;
	if ( is_true( level.use_legacy_powerup_system ) )
	{
		self maps\_hud_util::destroyelem();
	}
	temp_enta delete();
}