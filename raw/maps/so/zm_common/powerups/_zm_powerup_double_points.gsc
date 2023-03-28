#include maps\_utility; 
#include common_scripts\utility;
#include maps\so\zm_common\_zm_utility;

enable_double_points_powerup_for_level()
{
	maps\so\zm_common\_zm_powerups::register_powerup_basic_info( "double_points", "zombie_x2_icon", &"ZOMBIE_POWERUP_DOUBLE_POINTS", ::func_should_always_drop, false, false, false );
	maps\so\zm_common\_zm_powerups::register_powerup_setup( "double_points", ::double_points_precache, ::double_points_setup );
	maps\so\zm_common\_zm_powerups::register_powerup_grab_info( "double_points", ::double_points_grab, undefined, undefined );
	maps\so\zm_common\_zm_powerups::register_powerup_hud_info( "double_points", "specialty_doublepoints_zombies", "zombie_powerup_point_doubler_time", "zombie_powerup_point_doubler_on" );
	maps\so\zm_common\_zm_powerups::register_powerup_player_setup( "double_points", ::double_points_player_setup );
}

func_should_always_drop()
{
	return true;
}

double_points_precache()
{
	if ( !is_true( level.use_legacy_powerup_system ) )
	{
		PrecacheShader( "specialty_doublepoints_zombies" );	
	}
}

double_points_setup()
{
	level.double_points_duration = 30;
	set_zombie_var( "zombie_powerup_point_doubler_on", 	false );
	set_zombie_var( "zombie_powerup_point_doubler_time", level.double_points_duration );	// length of point doubler
}

double_points_player_setup()
{
	if ( !is_true( level.use_legacy_powerup_system ) )
	{
		self maps\so\zm_common\_zm_powerups::register_powerup_hud_player_info( "double_points" );
	}
}

double_points_grab( powerup, player )
{
	level thread double_points_powerup( powerup );
	player thread maps\so\zm_common\_zm_powerups::powerup_vo("double_points");
}

// double the points
double_points_powerup( drop_item )
{
	level notify ("powerup points scaled");
	level endon ("powerup points scaled");

	//	players = getPlayers();	
	//	array_thread(level,::point_doubler_on_hud, drop_item);
	level thread point_doubler_on_hud( drop_item );

	level.zombie_vars["zombie_point_scalar"] = 2;
	wait level.double_points_duration;

	level.zombie_vars["zombie_point_scalar"] = 1;
}

point_doubler_on_hud( drop_item )
{
	self endon ("disconnect");

	// check to see if this is on or not
	if ( level.zombie_vars["zombie_powerup_point_doubler_on"] )
	{
		// reset the time and keep going
		level.zombie_vars["zombie_powerup_point_doubler_time"] = level.double_points_duration;
		return;
	}

	level.zombie_vars["zombie_powerup_point_doubler_on"] = true;
	//level.powerup_hud_array[0] = true;
	// set up the hudelem
	if ( is_true( level.use_legacy_powerup_system ) )
	{
		hudelem = maps\_hud_util::createFontString( "objective", 2 );
		hudelem maps\_hud_util::setPoint( "TOP", undefined, 0, level.zombie_vars["zombie_timer_offset"] );
		hudelem.sort = 0.5;
		hudelem.alpha = 0;
		hudelem fadeovertime( 0.5 );
		hudelem.alpha = 1;
		hudelem.label = drop_item.hint;
		hudelem thread time_remaining_on_point_doubler_powerup();
	}
	else 
	{
		// set time remaining for point doubler
		level thread time_remaining_on_point_doubler_powerup();	
	}
	

	// offset in case we get another powerup
	//level.zombie_timer_offset -= level.zombie_timer_offset_interval;
}

time_remaining_on_point_doubler_powerup()
{
	if ( !is_true( level.use_legacy_powerup_system ) )
	{
		level thread maps\so\zm_common\_zm_powerups::play_devil_dialog("dp_vox");
	}
	else 
	{
		self setvalue( level.zombie_vars["zombie_powerup_point_doubler_time"] );
	}
	temp_ent = spawn("script_origin", (0,0,0));
	temp_ent playloopsound ("double_point_loop");
	
	
	
	
	// time it down!
	while ( level.zombie_vars["zombie_powerup_point_doubler_time"] >= 0)
	{
		if ( !is_true( level.use_legacy_powerup_system ) )
		{
			wait 0.1;
			level.zombie_vars["zombie_powerup_point_doubler_time"] = level.zombie_vars["zombie_powerup_point_doubler_time"] - 0.1;
			
		}
		else
		{
			wait 1;
			level.zombie_vars["zombie_powerup_point_doubler_time"] = level.zombie_vars["zombie_powerup_point_doubler_time"] - 1;
			self setvalue( level.zombie_vars["zombie_powerup_point_doubler_time"] );
		}
	}

	// turn off the timer
	level.zombie_vars["zombie_powerup_point_doubler_on"] = false;
	players = getPlayers();
	for (i = 0; i < players.size; i++)
	{
		//players[i] stoploopsound("double_point_loop", 2);
		players[i] playsound("points_loop_off");
	}
	temp_ent stoploopsound(2);


	// remove the offset to make room for new powerups, reset timer for next time
	level.zombie_vars["zombie_powerup_point_doubler_time"] = level.double_points_duration;
	//level.zombie_timer_offset += level.zombie_timer_offset_interval;
	if ( is_true( level.use_legacy_powerup_system ) )
	{
		self maps\_hud_util::destroyelem();
	}
	temp_ent delete();
}