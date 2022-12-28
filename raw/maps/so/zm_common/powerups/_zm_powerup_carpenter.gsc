#include maps\_utility; 
#include common_scripts\utility;
#include maps\so\zm_common\_zm_utility;

enable_carpenter_powerup_for_level()
{
	maps\so\zm_common\_zm_powerups::register_powerup_basic_info( "carpenter", "zombie_carpenter", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_drop_carpenter, false, false, false );
	maps\so\zm_common\_zm_powerups::register_powerup_setup( "carpenter", ::carpenter_precache, ::carpenter_setup );
	maps\so\zm_common\_zm_powerups::register_powerup_grab_info( "carpenter", ::carpenter_grab, undefined, undefined );
}

func_should_drop_carpenter()
{
	return get_num_window_destroyed() < 5;
}

carpenter_precache()
{

}

carpenter_setup()
{

}

carpenter_grab( powerup, player )
{
	level thread start_carpenter( powerup.origin );
	player thread maps\so\zm_common\_zm_powerups::powerup_vo("carpenter");	
}

start_carpenter( origin )
{

	level thread maps\so\zm_common\_zm_powerups::play_devil_dialog("carp_vox");
	window_boards = getstructarray( "exterior_goal", "targetname" ); 
	total = level.exterior_goals.size;
	
	//COLLIN
	carp_ent = spawn("script_origin", (0,0,0));
	carp_ent playloopsound( "carp_loop" );
	
	while(true)
	{
		windows = get_closest_window_repair(window_boards, origin);
		if( !IsDefined( windows ) )
		{
			carp_ent stoploopsound( 1 );
			carp_ent playsound( "carp_end", "sound_done" );
			carp_ent waittill( "sound_done" );
			break;
		}
		
		else
			window_boards = array_remove(window_boards, windows);


		while(1)
		{
			if( all_chunks_intact( windows.barrier_chunks ) )
			{
				break;
			}

			chunk = get_random_destroyed_chunk( windows.barrier_chunks ); 

			if( !IsDefined( chunk ) )
				break;

			windows thread maps\so\zm_common\_zm_blockers::replace_chunk( chunk, false, true );
			windows.clip enable_trigger(); 
			windows.clip DisconnectPaths();
			wait_network_frame();
			wait(0.05);
		}
 

		wait_network_frame();
		
	}


	players = getPlayers();
	for(i = 0; i < players.size; i++)
	{
		players[i].score += 200;
		players[i].score_total += 200;
		players[i] maps\so\zm_common\_zm_score::set_player_score_hud(); 
	}


	carp_ent delete();


}
get_closest_window_repair( windows, origin )
{
	current_window = undefined;
	shortest_distance = undefined;
	for( i = 0; i < windows.size; i++ )
	{
		if( all_chunks_intact(windows[i].barrier_chunks ) )
			continue;

		if( !IsDefined( current_window ) )	
		{
			current_window = windows[i];
			shortest_distance = DistanceSquared( current_window.origin, origin );
			
		}
		else
		{
			if( DistanceSquared(windows[i].origin, origin) < shortest_distance )
			{

				current_window = windows[i];
				shortest_distance =  DistanceSquared( windows[i].origin, origin );
			}

		}

	}

	return current_window;


}

get_num_window_destroyed()
{
	num = 0;
	for( i = 0; i < level.exterior_goals.size; i++ )
	{
		/*targets = getentarray(level.exterior_goals[i].target, "targetname");

		barrier_chunks = []; 
		for( j = 0; j < targets.size; j++ )
		{
			if( IsDefined( targets[j].script_noteworthy ) )
			{
				if( targets[j].script_noteworthy == "clip" )
				{ 
					continue; 
				}
			}

			barrier_chunks[barrier_chunks.size] = targets[j];
		}*/


		if( all_chunks_destroyed( level.exterior_goals[i].barrier_chunks ) )
		{
			num += 1;
		}

	}

	return num;
}