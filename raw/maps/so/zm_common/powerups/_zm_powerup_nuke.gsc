#include maps\_utility; 
#include common_scripts\utility;
#include maps\so\zm_common\_zm_utility;

enable_nuke_powerup_for_level()
{
	maps\so\zm_common\_zm_powerups::register_powerup_basic_info( "nuke", "zombie_bomb", &"ZOMBIE_POWERUP_NUKE", ::func_should_always_drop, false, false, false, "misc/fx_zombie_mini_nuke" );
	maps\so\zm_common\_zm_powerups::register_powerup_setup( "nuke", ::nuke_precache, ::nuke_setup );
	maps\so\zm_common\_zm_powerups::register_powerup_grab_info( "nuke", ::nuke_grab, undefined, undefined );
}

func_should_always_drop()
{
	return true;
}

nuke_precache()
{

}

nuke_setup()
{
	level.nuke_points_awarded = 400;
}

nuke_grab( powerup, player )
{
	level thread nuke_powerup( powerup );
	
	//chrisp - adding powerup VO sounds
	player thread maps\so\zm_common\_zm_powerups::powerup_vo("nuke");
	zombies = getaiarray("axis");
	player.zombie_nuked = get_array_of_closest( powerup.origin, zombies );
	player notify("nuke_triggered");
}

// kill them all!
nuke_powerup( drop_item )
{
	zombies = getaispeciesarray("axis");

	PlayFx( drop_item.fx, drop_item.origin );
	//	players = getPlayers();
	//	array_thread (players, ::nuke_flash);
	level thread nuke_flash();

	

	zombies = get_array_of_closest( drop_item.origin, zombies );

	for (i = 0; i < zombies.size; i++)
	{
		wait (randomfloatrange(0.1, 0.7));
		if( !IsDefined( zombies[i] ) )
		{
			continue;
		}
		
		if( zombies[i].animname == "boss_zombie" )
		{
			continue;
		}

		if( is_magic_bullet_shield_enabled( zombies[i] ) )
		{
			continue;
		}

		if( i < 5 && !( zombies[i] enemy_is_dog() ) )
		{
			zombies[i] thread animscripts\death::flame_death_fx();

		}

		if( !( zombies[i] enemy_is_dog() ) )
		{
			if ( isDefined( level._zm_spawner_funcs ) && isDefined( level._zm_spawner_funcs[ "zombie_head_gib" ] ) )
			{
				zombies[ i ] [[ level._zm_spawner_funcs[ "zombie_head_gib" ] ]]();
			}
		}

		zombies[i] dodamage( zombies[i].health + 666, zombies[i].origin );
		playsoundatposition( "nuked", zombies[i].origin );
	}

	players = getPlayers();
	for(i = 0; i < players.size; i++)
	{
		players[i].score += level.nuke_points_awarded;
		players[i].score_total += level.nuke_points_awarded;
		players[i] maps\so\zm_common\_zm_score::set_player_score_hud(); 
	}

}

nuke_flash()
{
	if ( !is_true( level.use_legacy_powerup_system ) )
	{
		players = getplayers();	
		for(i=0; i<players.size; i ++)
		{
			players[i] play_sound_2d("nuke_flash");
		}
		level thread devil_dialog_delay();
	}
	else 
	{
		playsoundatposition("nuke_flash", (0,0,0));
	}
	fadetowhite = newhudelem();

	fadetowhite.x = 0; 
	fadetowhite.y = 0; 
	fadetowhite.alpha = 0; 

	fadetowhite.horzAlign = "fullscreen"; 
	fadetowhite.vertAlign = "fullscreen"; 
	fadetowhite.foreground = true; 
	fadetowhite SetShader( "white", 640, 480 ); 

	// Fade into white
	fadetowhite FadeOverTime( 0.2 ); 
	fadetowhite.alpha = 0.8; 

	wait 0.5;
	fadetowhite FadeOverTime( 1.0 ); 
	fadetowhite.alpha = 0; 

	wait 1.1;
	fadetowhite destroy();
}

devil_dialog_delay()
{
	wait(1.8);
	level thread maps\so\zm_common\_zm_powerups::play_devil_dialog("nuke_vox");
	
}