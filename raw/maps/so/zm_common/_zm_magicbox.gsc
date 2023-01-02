#include maps\_utility; 
#include common_scripts\utility;
#include maps\so\zm_common\_zm_weapons;
#include maps\so\zm_common\_zm_utility;

init_zm_magicbox()
{
	if ( !isDefined( level.magic_box_can_move ) )
	{
		level.magic_box_can_move = true;
	}
	treasure_chest_init();
	level.box_moved = false;
}

treasure_chest_init()
{
	flag_init("moving_chest_enabled");
	flag_init("moving_chest_now");
	
	level.chest_accessed = 0;
	level.chests = GetEntArray( "treasure_chest_use", "targetname" );

	if (level.chests.size > 1)
	{

		flag_set("moving_chest_enabled");
	
		while ( 1 )
		{
			level.chests = array_randomize(level.chests);

			if( isdefined( level.random_pandora_box_start ) )
				break;
	
			if ( !IsDefined( level.chests[0].script_noteworthy ) || ( level.chests[0].script_noteworthy != "start_chest" ) )
			{
				break;
			}

		}		
		
		level.chest_index = 0;

		while(level.chest_index < level.chests.size)
		{
				
			if( isdefined( level.random_pandora_box_start ) )
				break;

			if(level.chests[level.chest_index].script_noteworthy == "start_chest")
			{
				break;
			}
			
			level.chest_index++;     
		}

		//init time chest accessed amount.
		
		if(level.script == "nazi_zombie_sumpf" || level.script == "nazi_zombie_factory")
		{
			// Anchor target will grab the weapon spawn point inside the box, so the fx will be centered on it too
			anchor = GetEnt(level.chests[level.chest_index].target, "targetname");
			anchorTarget = GetEnt(anchor.target, "targetname");

			level.pandora_light = Spawn( "script_model", anchorTarget.origin );
			level.pandora_light.angles = anchorTarget.angles + (-90, 0, 0);
			//temp_fx_origin rotateto((-90, (box_origin.angles[1] * -1), 0), 0.05);
			level.pandora_light SetModel( "tag_origin" );
			playfxontag(level._effect["lght_marker"], level.pandora_light, "tag_origin");
		}
		
		//determine magic box starting location at random or normal
		init_starting_chest_location();
	
	}

	array_thread( level.chests, ::treasure_chest_think );

}

init_starting_chest_location()
{

	for( i = 0; i < level.chests.size; i++ )
	{

		if( isdefined( level.random_pandora_box_start ) && level.random_pandora_box_start == true )
		{
			if( i != 0 )
			{
				level.chests[i] hide_chest();	
			}
			else
			{
				level.chest_index = i;
				unhide_magic_box( i );
			}

		}
		else
		{
			if ( !IsDefined(level.chests[i].script_noteworthy ) || ( level.chests[i].script_noteworthy != "start_chest" ) )
			{
				level.chests[i] hide_chest();	
			}
			else
			{
				level.chest_index = i;
				unhide_magic_box( i );
			}
		}
	}


}

unhide_magic_box( index )
{
	
	//PI CHANGE - altered to allow for more than one piece of rubble
	rubble = getentarray( level.chests[index].script_noteworthy + "_rubble", "script_noteworthy" );
	if ( IsDefined( rubble ) )
	{
		for ( x = 0; x < rubble.size; x++ )
		{
			rubble[x] hide();
		}
		//END PI CHANGE
	}
	else
	{
		println( "^3Warning: No rubble found for magic box" );
	}
}

set_treasure_chest_cost( cost )
{
	level.zombie_treasure_chest_cost = cost;
}

hide_chest()
{
	pieces = self get_chest_pieces();

	for(i=0;i<pieces.size;i++)
	{
		pieces[i] disable_trigger();
		pieces[i] hide();
	}	
}

get_chest_pieces()
{
	// self = trigger

	lid = GetEnt(self.target, "targetname");
	org = GetEnt(lid.target, "targetname");
	box = GetEnt(org.target, "targetname");

	pieces = [];
	pieces[pieces.size] = self;
	pieces[pieces.size] = lid;
	pieces[pieces.size] = org;
	pieces[pieces.size] = box;

	return pieces;
}

play_crazi_sound()
{
	self playlocalsound("laugh_child");
}

show_magic_box()
{
	pieces = self get_chest_pieces();
	for(i=0;i<pieces.size;i++)
	{
		pieces[i] enable_trigger();
	}
	
	// PI_CHANGE_BEGIN - JMA - we want to play another effect on swamp
	anchor = GetEnt(self.target, "targetname");
	anchorTarget = GetEnt(anchor.target, "targetname");

	if(isDefined(level.script) && (level.script != "nazi_zombie_sumpf") && (level.script != "nazi_zombie_factory") )
	{
		playfx( level._effect["poltergeist"],pieces[0].origin);
	}
	else
	{		
		level.pandora_light.angles = (-90, anchorTarget.angles[1] + 180, 0);
		level.pandora_light moveto(anchorTarget.origin, 0.05);
		wait(1);	
		playfx( level._effect["lght_marker_flare"],level.pandora_light.origin );
//		playfxontag(level._effect["lght_marker_flare"], level.pandora_light, "tag_origin");
	}
	// PI_CHANGE_END
	
	playsoundatposition( "box_poof", pieces[0].origin );
	wait(.5);
	for(i=0;i<pieces.size;i++)
	{
		if( pieces[i].classname != "trigger_use" )
		{
			pieces[i] show();
		}
	}
	pieces[0] playsound ( "box_poof_land" );
	pieces[0] playsound( "couch_slam" );
}

treasure_chest_think()
{	
	cost = 950;
	if( IsDefined( level.zombie_treasure_chest_cost ) )
	{
		cost = level.zombie_treasure_chest_cost;
	}
	else
	{
		cost = self.zombie_cost;
	}

	self set_hint_string( self, "default_treasure_chest_" + cost );
	self setCursorHint( "HINT_NOICON" );

	//self thread decide_hide_show_chest_hint( "move_imminent" );

	// waittill someuses uses this
	user = undefined;
	while( 1 )
	{
		self waittill( "trigger", user ); 
		if( user in_revive_trigger() )
		{
			wait( 0.1 );
			continue;
		}
		if ( isDefineD( user.is_drinking ) && user.is_drinking > 0 )
		{
			wait 0.1;
			continue;
		}
		// make sure the user is a player, and that they can afford it
		if( is_player_valid( user ) && user.score >= cost )
		{
			user maps\so\zm_common\_zm_score::minus_to_player_score( cost ); 
			break; 
		}
		else if ( user.score < cost )
		{
			user thread maps\so\zm_common\_zm_audio::play_no_money_perk_dialog();
			continue;	
		}

		wait 0.05; 
	}

	// trigger_use->script_brushmodel lid->script_origin in radiant
	lid = getent( self.target, "targetname" ); 
	weapon_spawn_org = getent( lid.target, "targetname" ); 

	//open the lid
	lid thread treasure_chest_lid_open();

	// SRS 9/3/2008: added to help other functions know if we timed out on grabbing the item
	self.timedOut = false;

	self._box_open = true;
    self._box_opened_by_fire_sale = false;

    if ( is_true( level.zombie_vars["zombie_powerup_fire_sale_on"] ) )
        self._box_opened_by_fire_sale = true;

	// mario kart style weapon spawning
	weapon_spawn_org thread treasure_chest_weapon_spawn( self, user ); 

	// the glowfx	
	weapon_spawn_org thread treasure_chest_glowfx(); 

	// take away usability until model is done randomizing
	self disable_trigger(); 

	weapon_spawn_org waittill( "randomization_done" ); 

	if ( flag( "moving_chest_now" ) && !is_true( level.zombie_vars["zombie_powerup_fire_sale_on"] ) && !self._box_opened_by_fire_sale )
	{
		user thread treasure_chest_move_vo();
		self treasure_chest_move(lid);

	}
	else
	{
		// Let the player grab the weapon and re-enable the box //
		self.grab_weapon_hint = true;
		self.chest_user = user;
		self sethintstring( &"ZOMBIE_TRADE_WEAPONS" ); 
		self setCursorHint( "HINT_NOICON" ); 
		self setvisibletoplayer( user );

		// Limit its visibility to the player who bought the box
		self enable_trigger(); 
		self thread treasure_chest_timeout();

		// make sure the guy that spent the money gets the item
		// SRS 9/3/2008: ...or item goes back into the box if we time out
		while( 1 )
		{
			self waittill( "trigger", grabber ); 

			if( grabber == user || grabber == level )
			{

				if ( isdefined( grabber.is_drinking ) && grabber.is_drinking > 0 )
				{
					wait 0.1;
					continue;
				}
				if( grabber == user && is_player_valid( user ) && user GetCurrentWeapon() != "mine_bouncing_betty" )
				{
					bbPrint( "zombie_uses: playername %s playerscore %d round %d cost %d name %s x %f y %f z %f type magic_accept",
						user.playername, user.score, level.round_number, cost, weapon_spawn_org.weapon_string, self.origin );
					self notify( "user_grabbed_weapon" );
					user thread maps\so\zm_common\_zm_weapons::weapon_give( weapon_spawn_org.weapon_string );
					break; 
				}
				else if( grabber == level )
				{
					// it timed out
					self.timedOut = true;
					bbPrint( "zombie_uses: playername %s playerscore %d round %d cost %d name %s x %f y %f z %f type magic_reject",
						user.playername, user.score, level.round_number, cost, weapon_spawn_org.weapon_string, self.origin );
					break;
				}
			}

			wait 0.05; 
		}

		self.grab_weapon_hint = false;
		self.chest_user = undefined;

		weapon_spawn_org notify( "weapon_grabbed" );

		//increase counter of amount of time weapon grabbed.
		if ( !is_true( self._box_opened_by_fire_sale ) )
			level.chest_accessed += 1;
		// PI_CHANGE_BEGIN
		// JMA - we only update counters when it's available
		if( level.box_moved == true && isDefined(level.pulls_since_last_ray_gun) )
		{
			level.pulls_since_last_ray_gun += 1;
		}
		
		if( isDefined(level.pulls_since_last_tesla_gun) )
		{				
			level.pulls_since_last_tesla_gun += 1;
		}
		// PI_CHANGE_END
		self disable_trigger();

		// spend cash here...
		// give weapon here...
		lid thread treasure_chest_lid_close( self.timedOut );

		//Chris_P
		//magic box dissapears and moves to a new spot after a predetermined number of uses

		wait 3;
		self enable_trigger();
		self setvisibletoall();
	}

	flag_clear("moving_chest_now");
	self._box_open = false;
	self._box_opened_by_fire_sale = false;
	self thread treasure_chest_think();
}


//
//	Disable trigger if can't buy weapon and also if someone else is using the chest
decide_hide_show_chest_hint( endon_notify )
{
	if( isDefined( endon_notify ) )
	{
		self endon( endon_notify );
	}

	while( true )
	{
		players = getPlayers();
		for( i = 0; i < players.size; i++ )
		{
			// chest_user defined if someone bought a weapon spin, false when chest closed
			if ( (IsDefined(self.chest_user) && players[i] != self.chest_user ) ||
				!players[i] can_buy_weapon() )
			{
				self SetInvisibleToPlayer( players[i], true );
			}
			else
			{
				self SetInvisibleToPlayer( players[i], false );
			}
		}
		wait( 0.1 );
	}
}

treasure_chest_move_vo()
{

	self endon("disconnect");

	index = maps\so\zm_common\_zm_weapons::get_player_index(self);
	sound = undefined;

	if(!isdefined (level.player_is_speaking))
	{
		level.player_is_speaking = 0;
	}
	variation_count = 5;
	sound = "plr_" + index + "_vox_box_move" + "_" + randomintrange(0, variation_count);


	//This keeps multiple voice overs from playing on the same player (both killstreaks and headshots).
	if (level.player_is_speaking != 1 && isDefined(sound))
	{	
		level.player_is_speaking = 1;
		self playsound(sound, "sound_done");			
		self waittill("sound_done");
		level.player_is_speaking = 0;
	}

}


treasure_chest_move(lid)
{
	level waittill("weapon_fly_away_start");

	players = getPlayers();
	
	array_thread(players, ::play_crazi_sound);

	level waittill("weapon_fly_away_end");

	lid thread treasure_chest_lid_close(false);
	self setvisibletoall();

	fake_pieces = [];
	pieces = self get_chest_pieces();

	for(i=0;i<pieces.size;i++)
	{
		if(pieces[i].classname == "script_model")
		{
			fake_pieces[fake_pieces.size] = spawn("script_model",pieces[i].origin);
			fake_pieces[fake_pieces.size - 1].angles = pieces[i].angles;
			fake_pieces[fake_pieces.size - 1] setmodel(pieces[i].model);
			pieces[i] disable_trigger();
			pieces[i] hide();
		}
		else
		{
			pieces[i] disable_trigger();
			pieces[i] hide();
		}
	}

	anchor = spawn("script_origin",fake_pieces[0].origin);
	soundpoint = spawn("script_origin", anchor.origin);
	playfx( level._effect["poltergeist"],anchor.origin);

	anchor playsound("box_move");
	for(i=0;i<fake_pieces.size;i++)
	{
		fake_pieces[i] linkto(anchor);
	}

	playsoundatposition ("whoosh", soundpoint.origin );
	playsoundatposition ("ann_vox_magicbox", soundpoint.origin );


	anchor moveto(anchor.origin + (0,0,50),5);
	//anchor rotateyaw(360 * 10,5,5);
	if(level.chests[level.chest_index].script_noteworthy == "magic_box_south" || level.chests[level.chest_index].script_noteworthy == "magic_box_bathroom" || level.chests[level.chest_index].script_noteworthy == "magic_box_hallway")
	{
		anchor Vibrate( (50, 0, 0), 10, 0.5, 5 );
	}
	else if(level.script != "nazi_zombie_sumpf")
	{
		anchor Vibrate( (0, 50, 0), 10, 0.5, 5 );
	}
	else
	{
		//Get the normal of the box using the positional data of the box and lid
		direction = pieces[3].origin - pieces[1].origin;
		direction = (direction[1], direction[0], 0);
		
		if(direction[1] < 0 || (direction[0] > 0 && direction[1] > 0))
		{
				direction = (direction[0], direction[1] * -1, 0);
		}
		else if(direction[0] < 0)
		{
				direction = (direction[0] * -1, direction[1], 0);
		}
		anchor Vibrate( direction, 10, 0.5, 5);
	}
	
	//anchor thread rotateroll_box();
	anchor waittill("movedone");
	//players = getPlayers();
	//array_thread(players, ::play_crazi_sound);
	//wait(3.9);
	
	playfx(level._effect["poltergeist"], anchor.origin);
	
	//TUEY - Play the 'disappear' sound
	playsoundatposition ("box_poof", soundpoint.origin);
	for(i=0;i<fake_pieces.size;i++)
	{
		fake_pieces[i] delete();
	}


	//gzheng-Show the rubble
	//PI CHANGE - allow for more than one object of rubble per box
	rubble = getentarray(self.script_noteworthy + "_rubble", "script_noteworthy");
	
	if ( IsDefined( rubble ) )
	{
		for (i = 0; i < rubble.size; i++)
		{
			rubble[i] show();
		}
	}
	else
	{
		println( "^3Warning: No rubble found for magic box" );
	}

	wait(0.1);
	anchor delete();
	soundpoint delete();

	old_chest_index = level.chest_index;

	post_selection_wait_duration = 7;

	if ( is_true( level.zombie_vars["zombie_powerup_fire_sale_on"] ) )
	{
		current_sale_time = level.zombie_vars["zombie_powerup_fire_sale_time"];
		wait 0.1;
		self thread fire_sale_fix();
		level.zombie_vars["zombie_powerup_fire_sale_time"] = current_sale_time;

		while ( isDefined( level.zombie_vars["zombie_powerup_fire_sale_time"] ) && level.zombie_vars["zombie_powerup_fire_sale_time"] > 0 )
			wait 0.1;
	}
	else
		post_selection_wait_duration += 5;

	wait(5);
	//chest moving logic
	//PI CHANGE - for sumpf, this doesn't work because chest_index is always incremented twice (here and line 724) - while this would work with an odd number of chests, 
	//		     with an even number it skips half of the chest locations in the map

	level.verify_chest = false;
	//wait(3);
	//make sure level is asylum, factory, or sumpf and make magic box only appear in location player have open, it's off by default
	//also make sure box doesn't respawn in old location.
	//PI WJB: removed check on "magic_box_explore_only" dvar because it is only ever used here and when it is set in _zombiemode.gsc line 446
	// where it is declared and set to 0, causing this while loop to never happen because the check was to see if it was equal to 1
	if( is_true( level.magic_box_can_move ) )
	{
		level.chest_index++;

	/*	while(level.chests[level.chest_index].origin == level.chests[old_chest_index].origin)
		{	
			level.chest_index++;
		}*/

		if (level.chest_index >= level.chests.size)
		{
			//PI CHANGE - this way the chests won't move in the same order the second time around
			temp_chest_name = level.chests[level.chest_index - 1].script_noteworthy;
			level.chest_index = 0;
			level.chests = array_randomize(level.chests);
			//in case it happens to randomize in such a way that the chest_index now points to the same location
			// JMA - want to avoid an infinite loop, so we use an if statement
			if (temp_chest_name == level.chests[level.chest_index].script_noteworthy)
			{
				level.chest_index++;
			}
			//END PI CHANGE
		}

		//verify_chest_is_open();
		wait(0.01);
			
	}

	wait( post_selection_wait_duration );

	level.chests[level.chest_index] show_magic_box();
	
	//turn off magic box light.
	level notify("magic_box_light_switch");
	//PI CHANGE - altered to allow for more than one object of rubble per box
	unhide_magic_box( level.chest_index );
	
}

fire_sale_fix()
{
	self.old_cost = 950;
	self thread show_magic_box();
	self.zombie_cost = 10;
	wait 0.1;

	level waittill( "fire_sale_off" );

	while ( isdefined( self._box_open ) && self._box_open )
		wait 0.1;

	self.zombie_cost = self.old_cost;
}

rotateroll_box()
{
	angles = 40;
	angles2 = 0;
	//self endon("movedone");
	while(isdefined(self))
	{
		self RotateRoll(angles + angles2, 0.5);
		wait(0.7);
		angles2 = 40;
		self RotateRoll(angles * -2, 0.5);
		wait(0.7);
	}
	


}
//verify if that magic box is open to players or not.
verify_chest_is_open()
{

	//for(i = 0; i < 5; i++)
	//PI CHANGE - altered so that there can be more than 5 valid chest locations
	for (i = 0; i < level.open_chest_location.size; i++)
	{
		if(isdefined(level.open_chest_location[i]))
		{
			if(level.open_chest_location[i] == level.chests[level.chest_index].script_noteworthy)
			{
				level.verify_chest = true;
				return;		
			}
		}

	}

	level.verify_chest = false;


}


treasure_chest_timeout()
{
	self endon( "user_grabbed_weapon" );

	wait( 12 );
	self notify( "trigger", level ); 
}

treasure_chest_lid_open()
{
	openRoll = 105;
	openTime = 0.5;

	self RotateRoll( 105, openTime, ( openTime * 0.5 ) );

	play_sound_at_pos( "open_chest", self.origin );
	play_sound_at_pos( "music_chest", self.origin );
}

treasure_chest_lid_close( timedOut )
{
	closeRoll = -105;
	closeTime = 0.5;

	self RotateRoll( closeRoll, closeTime, ( closeTime * 0.5 ) );
	play_sound_at_pos( "close_chest", self.origin );
}

treasure_chest_ChooseRandomWeapon( player )
{

	keys = GetArrayKeys( level.zombie_weapons );

	// Filter out any weapons the player already has
	filtered = [];
	for( i = 0; i < keys.size; i++ )
	{
		if( !IsDefined( keys[i] ) )
		{
			continue;
		}

		if ( isDefined( level.magicbox_can_receive_weapon ) && !player [[ level.magicbox_can_receive_weapon ]]( keys[i] ) )
		{
			continue;
		}

		if( !get_is_in_box( keys[i] ) )
		{
			continue;
		}
		
		if( player has_weapon_or_upgrade( keys[i] ) )
		{
			continue;
		}

		filtered[filtered.size] = keys[i];
	}
	
	// Filter out the limited weapons
	if( IsDefined( level.limited_weapons ) )
	{
		keys2 = GetArrayKeys( level.limited_weapons );
		players = getPlayers();
		pap_triggers = GetEntArray("zombie_vending_upgrade", "targetname");
		for( q = 0; q < keys2.size; q++ )
		{
			count = 0;
			for( i = 0; i < players.size; i++ )
			{
				if( players[i] has_weapon_or_upgrade( keys2[q] ) )
				{
					count++;
				}
			}

			// Check the pack a punch machines to see if they are holding what we're looking for
			for ( k=0; k<pap_triggers.size; k++ )
			{
				if ( IsDefined(pap_triggers[k].current_weapon) && pap_triggers[k].current_weapon == keys2[q] )
				{
					count++;
				}
			}

			if( count >= level.limited_weapons[keys2[q]] )
			{
				filtered = array_remove( filtered, keys2[q] );
			}
		}
	}

	return filtered[RandomInt( filtered.size )];
}

treasure_chest_ChooseWeightedRandomWeapon( player )
{

	keys = GetArrayKeys( level.zombie_weapons );

	// Filter out any weapons the player already has
	filtered = [];
	for( i = 0; i < keys.size; i++ )
	{
		if( !IsDefined( keys[i] ) )
		{
			continue;
		}

		if ( isDefined( level.magicbox_can_receive_weapon ) && !player [[ level.magicbox_can_receive_weapon ]]( keys[i] ) )
		{
			continue;
		}

		if( !get_is_in_box( keys[i] ) )
		{
			continue;
		}
		
		if( player has_weapon_or_upgrade( keys[i] ) )
		{
			continue;
		}

		num_entries = [[ level.weapon_weighting_funcs[keys[i]] ]]();
		
		for( j = 0; j < num_entries; j++ )
		{
			filtered[filtered.size] = keys[i];
		}
	}
	
	// Filter out the limited weapons
	if( IsDefined( level.limited_weapons ) )
	{
		keys2 = GetArrayKeys( level.limited_weapons );
		players = getPlayers();
		pap_triggers = GetEntArray("zombie_vending_upgrade", "targetname");
		for( q = 0; q < keys2.size; q++ )
		{
			count = 0;
			for( i = 0; i < players.size; i++ )
			{
				if( players[i] has_weapon_or_upgrade( keys2[q] ) )
				{
					count++;
				}
			}

			// Check the pack a punch machines to see if they are holding what we're looking for
			for ( k=0; k<pap_triggers.size; k++ )
			{
				if ( IsDefined(pap_triggers[k].current_weapon) && pap_triggers[k].current_weapon == keys2[q] )
				{
					count++;
				}
			}

			if( count >= level.limited_weapons[keys2[q]] )
			{
				filtered = array_remove( filtered, keys2[q] );
			}
		}
	}
	/#
	if ( getDvar( "scr_force_mysterybox_weapon" ) != "" )
	{
		forced_weapon = getDvar( "scr_force_mysterybox_weapon" );
		setDvar( "scr_force_mysterybox_weapon", "" );
		return forced_weapon;
	}
	#/
	if ( isDefined( level.magicbox_force_weapon_func ) )
	{
		return player [[ level.magicbox_force_weapon_func ]]( filtered );
	}
	return filtered[RandomInt( filtered.size )];
}

treasure_chest_weapon_spawn( chest, player )
{
	assert(IsDefined(player));
	// spawn the model
	model = spawn( "script_model", self.origin ); 
	model.angles = self.angles +( 0, 90, 0 );

	floatHeight = 40;

	//move it up
	model moveto( model.origin +( 0, 0, floatHeight ), 3, 2, 0.9 ); 

	// rotation would go here

	// make with the mario kart
	modelname = undefined; 
	rand = undefined; 
	number_cycles = 40;
	for( i = 0; i < number_cycles; i++ )
	{

		if( i < 20 )
		{
			wait( 0.05 ); 
		}
		else if( i < 30 )
		{
			wait( 0.1 ); 
		}
		else if( i < 35 )
		{
			wait( 0.2 ); 
		}
		else if( i < 38 )
		{
			wait( 0.3 ); 
		}

		if( i+1 < number_cycles )
		{
			rand = treasure_chest_ChooseRandomWeapon( player );
		}
		else
		{
			rand = treasure_chest_ChooseWeightedRandomWeapon( player );
		}

		/#
		if( maps\so\zm_common\_zm_weap_tesla_gun::tesla_gun_exists() )	
		{
			if ( i == 39 && GetDvar( "scr_spawn_tesla" ) != "" )
			{
				SetDvar( "scr_spawn_tesla", "" );
				rand = "tesla_gun";
			}
		}
		#/

		modelname = GetWeaponModel( rand );
		model setmodel( modelname ); 


	}

	self.weapon_string = rand; // here's where the org get it's weapon type for the give function

	// random change of getting the joker that moves the box
	random = Randomint(100);

	if( !isdefined( level.chest_min_move_usage ) )
	{
		level.chest_min_move_usage = 4;
	}

	//increase the chance of joker appearing from 0-100 based on amount of the time chest has been opened.
	if ( is_true( level.magic_box_can_move ) && !is_true( chest._box_opened_by_fire_sale ) && !is_true( level.zombie_vars["zombie_powerup_fire_sale_on"] ) )
	{

		if(level.chest_accessed < level.chest_min_move_usage)
		{		
			// PI_CHANGE_BEGIN - JMA - RandomInt(100) can return a number between 0-99.  If it's zero and chance_of_joker is zero
			//									we can possibly have a teddy bear one after another.
			chance_of_joker = -1;
			// PI_CHANGE_END
		}
		else
		{
			chance_of_joker = level.chest_accessed + 20;
			
			// make sure teddy bear appears on the 8th pull if it hasn't moved from the initial spot
			if( (!isDefined(level.magic_box_first_move) || level.magic_box_first_move == false ) && level.chest_accessed >= 8)
			{
				chance_of_joker = 100;
			}
			
			// pulls 4 thru 8, there is a 15% chance of getting the teddy bear
			// NOTE:  this happens in all cases
			if( level.chest_accessed >= 4 && level.chest_accessed < 8 )
			{
				if( random < 15 )
				{
					chance_of_joker = 100;
				}
				else
				{
					chance_of_joker = -1;
				}
			}
			
			// after the first magic box move the teddy bear percentages changes
			if( isDefined(level.magic_box_first_move) && level.magic_box_first_move == true )
			{
				// between pulls 8 thru 12, the teddy bear percent is 30%
				if( level.chest_accessed >= 8 && level.chest_accessed < 13 )
				{
					if( random < 30 )
					{
						chance_of_joker = 100;
					}
					else
					{
						chance_of_joker = -1;
					}
				}
				
				// after 12th pull, the teddy bear percent is 50%
				if( level.chest_accessed >= 13 )
				{
					if( random < 50 )
					{
						chance_of_joker = 100;
					}
					else
					{
						chance_of_joker = -1;
					}
				}
			}
		}

		if (random <= chance_of_joker)
		{
			model SetModel("zombie_teddybear");
		//	model rotateto(level.chests[level.chest_index].angles, 0.01);
			//wait(1);
			model.angles = self.angles;		
			wait 1;
			flag_set("moving_chest_now");
			self notify( "move_imminent" );
			level.chest_accessed = 0;

			player maps\so\zm_common\_zm_score::add_to_player_score( 950 );

			//allow power weapon to be accessed.
			level.box_moved = true;
		}
	}

	self notify( "randomization_done" );

	if ( flag("moving_chest_now") && !is_true( level.zombie_vars["zombie_powerup_fire_sale_on"] ) )
	{
		wait .5;	// we need a wait here before this notify
		level notify("weapon_fly_away_start");
		wait 2;
		model MoveZ(500, 4, 3);
		model waittill("movedone");
		model delete();
		self notify( "box_moving" );
		level notify("weapon_fly_away_end");
	}
	else
	{

		//turn off power weapon, since player just got one
		if( rand == "tesla_gun" || rand == "ray_gun" )
		{
			// PI_CHANGE_BEGIN - JMA - reset the counters for tesla gun and ray gun pulls
			if( isDefined( level.script ) && (level.script == "nazi_zombie_sumpf" || level.script == "nazi_zombie_factory") )
			{
				if( rand == "ray_gun" )
				{
					level.box_moved = false;
					level.pulls_since_last_ray_gun = 0;
				}
				
				if( rand == "tesla_gun" )
				{
					level.pulls_since_last_tesla_gun = 0;
					level.player_seen_tesla_gun = true;
				}			
			}
			else
			{
				level.box_moved = false;
			}
			// PI_CHANGE_END			
		}

		model thread timer_til_despawn(floatHeight);
		self waittill( "weapon_grabbed" );

		if( !chest.timedOut )
		{
			model Delete();
		}


	}
}
timer_til_despawn(floatHeight)
{


	// SRS 9/3/2008: if we timed out, move the weapon back into the box instead of deleting it
	putBackTime = 12;
	self MoveTo( self.origin - ( 0, 0, floatHeight ), putBackTime, ( putBackTime * 0.5 ) );
	wait( putBackTime );

	if(isdefined(self))
	{	
		self Delete();
	}
}

treasure_chest_glowfx()
{
	fxObj = spawn( "script_model", self.origin +( 0, 0, 0 ) ); 
	fxobj setmodel( "tag_origin" ); 
	fxobj.angles = self.angles +( 90, 0, 0 ); 

	playfxontag( level._effect["chest_light"], fxObj, "tag_origin"  ); 

	self waittill_any( "weapon_grabbed", "box_moving" ); 

	fxobj delete(); 
}