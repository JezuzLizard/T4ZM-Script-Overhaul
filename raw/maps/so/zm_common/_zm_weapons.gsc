#include maps\_utility; 
#include common_scripts\utility;
#include maps\so\zm_common\_zm_utility;

init_zm_weapons()
{
	if ( isDefined( level.zm_custom_map_weapon_add_func ) )
	{
		level [[ level.zm_custom_map_weapon_add_func ]]();
	}
	init_weapon_upgrade();
	init_weapon_cabinet();
}

include_zombie_weapon( weapon_name, in_box, weighting_func )
{
	if( !IsDefined( level.zombie_include_weapons ) )
	{
		level.zombie_include_weapons = [];
	}
	if( !isDefined( in_box ) )
	{
		in_box = true;
	}

	level.zombie_include_weapons[weapon_name] = in_box;
	
	if( !isDefined( weighting_func ) )
	{
		level.weapon_weighting_funcs[weapon_name] = ::default_weighting_func;
	}
	else
	{
		level.weapon_weighting_funcs[weapon_name] = weighting_func;
	}
}

add_zombie_weapon( weapon_name, hint, cost, weaponVO, variation_count, ammo_cost  )
{
	if( IsDefined( level.zombie_include_weapons ) && !IsDefined( level.zombie_include_weapons[weapon_name] ) )
	{
		return;
	}
	
	add_weapon_to_sound_array(weaponVO,variation_count);

	// Check the table first
	table = "mp/zombiemode.csv";
	table_cost = TableLookUp( table, 0, weapon_name, 1 );
	table_ammo_cost = TableLookUp( table, 0, weapon_name, 2 );

	if( IsDefined( table_cost ) && table_cost != "" )
	{
		cost = round_up_to_ten( int( table_cost ) );
	}

	if( IsDefined( table_ammo_cost ) && table_ammo_cost != "" )
	{
		ammo_cost = round_up_to_ten( int( table_ammo_cost ) );
	}

	PrecacheItem( weapon_name );
	PrecacheString( hint );

	struct = SpawnStruct();

	if( !IsDefined( level.zombie_weapons ) )
	{
		level.zombie_weapons = [];
	}

	struct.weapon_name = weapon_name;
	struct.weapon_classname = "weapon_" + weapon_name;
	struct.hint = hint;
	struct.cost = cost;
	struct.sound = weaponVO;
	struct.variation_count = variation_count;
	struct.is_in_box = level.zombie_include_weapons[weapon_name];

	if( !IsDefined( ammo_cost ) )
	{
		ammo_cost = round_up_to_ten( int( cost * 0.5 ) );
	}

	struct.ammo_cost = ammo_cost;

	level.zombie_weapons[weapon_name] = struct;
}

add_limited_weapon( weapon_name, amount )
{
	if( !IsDefined( level.limited_weapons ) )
	{
		level.limited_weapons = [];
	}

	level.limited_weapons[weapon_name] = amount;
}          

init_weapon_upgrade()
{
	weapon_spawns = [];
	weapon_spawns = GetEntArray( "weapon_upgrade", "targetname" ); 

	for( i = 0; i < weapon_spawns.size; i++ )
	{
		hint_string = get_weapon_hint( weapon_spawns[i].zombie_weapon_upgrade ); 

		weapon_spawns[i] SetHintString( hint_string ); 
		weapon_spawns[i] setCursorHint( "HINT_NOICON" ); 
		weapon_spawns[i] UseTriggerRequireLookAt();

		weapon_spawns[i] thread weapon_spawn_think(); 
		model = getent( weapon_spawns[i].target, "targetname" ); 
		model hide(); 
	}
}

// weapon cabinets which open on use
init_weapon_cabinet()
{
	// the triggers which are targeted at doors
	weapon_cabs = GetEntArray( "weapon_cabinet_use", "targetname" ); 

	for( i = 0; i < weapon_cabs.size; i++ )
	{

		weapon_cabs[i] SetHintString( &"ZOMBIE_CABINET_OPEN_1500" ); 
		weapon_cabs[i] setCursorHint( "HINT_NOICON" ); 
		weapon_cabs[i] UseTriggerRequireLookAt();
	}

	array_thread( weapon_cabs, ::weapon_cabinet_think ); 
}

decide_hide_show_hint( endon_notify )
{
	if( isDefined( endon_notify ) )
	{
		self endon( endon_notify );
	}

	while( true )
	{
		players = get_players();
		for( i = 0; i < players.size; i++ )
		{
			if( players[i] can_buy_weapon() )
			{
				self SetInvisibleToPlayer( players[i], false );
			}
			else
			{
				self SetInvisibleToPlayer( players[i], true );
			}
		}
		wait( 0.1 );
	}
}

weapon_cabinet_think()
{
	weapons = getentarray( "cabinet_weapon", "targetname" ); 

	doors = getentarray( self.target, "targetname" );
	for( i = 0; i < doors.size; i++ )
	{
		doors[i] NotSolid();
	}

	self.has_been_used_once = false; 

	self decide_hide_show_hint();

	while( 1 )
	{
		self waittill( "trigger", player );

		if( !player can_buy_weapon() )
		{
			wait( 0.1 );
			continue;
		}

		cost = 1500;
		if( self.has_been_used_once )
		{
			cost = get_weapon_cost( self.zombie_weapon_upgrade );
		}
		else
		{
			if( IsDefined( self.zombie_cost ) )
			{
				cost = self.zombie_cost;
			}
		}

		ammo_cost = get_ammo_cost( self.zombie_weapon_upgrade );

		if( !is_player_valid( player ) )
		{
			player thread ignore_triggers( 0.5 );
			continue;
		}

		if( self.has_been_used_once )
		{
			player_has_weapon = player has_weapon_or_upgrade( self.zombie_weapon_upgrade );
			/*
			player_has_weapon = false;
			weapons = player GetWeaponsList(); 
			if( IsDefined( weapons ) )
			{
				for( i = 0; i < weapons.size; i++ )
				{
					if( weapons[i] == self.zombie_weapon_upgrade )
					{
						player_has_weapon = true; 
					}
				}
			}
			*/

			if( !player_has_weapon )
			{
				if( player.score >= cost )
				{
					self play_sound_on_ent( "purchase" );
					player maps\so\zm_common\_zm_score::minus_to_player_score( cost ); 
					player weapon_give( self.zombie_weapon_upgrade ); 
				}
				else // not enough money
				{
					play_sound_on_ent( "no_purchase" );
					player thread maps\so\zm_common\_zm_audio::play_no_money_perk_dialog();
				}			
			}
			else if ( player.score >= ammo_cost )
			{
				ammo_given = player ammo_give( self.zombie_weapon_upgrade ); 
				if( ammo_given )
				{
					self play_sound_on_ent( "purchase" );
					player maps\so\zm_common\_zm_score::minus_to_player_score( ammo_cost ); // this give him ammo to early
				}
			}
			else // not enough money
			{
				play_sound_on_ent( "no_purchase" );
				player thread maps\so\zm_common\_zm_audio::play_no_money_perk_dialog();
			}
		}
		else if( player.score >= cost ) // First time the player opens the cabinet
		{
			self.has_been_used_once = true;

			self play_sound_on_ent( "purchase" ); 

			self SetHintString( &"ZOMBIE_WEAPONCOSTAMMO", cost, ammo_cost ); 
			//		self SetHintString( get_weapon_hint( self.zombie_weapon_upgrade ) );
			self setCursorHint( "HINT_NOICON" ); 
			player maps\so\zm_common\_zm_score::minus_to_player_score( self.zombie_cost ); 

			doors = getentarray( self.target, "targetname" ); 

			for( i = 0; i < doors.size; i++ )
			{
				if( doors[i].model == "dest_test_cabinet_ldoor_dmg0" )
				{
					doors[i] thread weapon_cabinet_door_open( "left" ); 
				}
				else if( doors[i].model == "dest_test_cabinet_rdoor_dmg0" )
				{
					doors[i] thread weapon_cabinet_door_open( "right" ); 
				}
			}

			player_has_weapon = player has_weapon_or_upgrade( self.zombie_weapon_upgrade ); 
			/*
			player_has_weapon = false;
			weapons = player GetWeaponsList(); 
			if( IsDefined( weapons ) )
			{
				for( i = 0; i < weapons.size; i++ )
				{
					if( weapons[i] == self.zombie_weapon_upgrade )
					{
						player_has_weapon = true; 
					}
				}
			}
			*/

			if( !player_has_weapon )
			{
				player weapon_give( self.zombie_weapon_upgrade ); 
			}
			else
			{
				if( player has_upgrade( self.zombie_weapon_upgrade ) )
				{
					player ammo_give( self.zombie_weapon_upgrade+"_upgraded" ); 
				}
				else
				{
					player ammo_give( self.zombie_weapon_upgrade ); 
				}
			}	
		}
		else // not enough money
		{
			play_sound_on_ent( "no_purchase" );
			player thread maps\so\zm_common\_zm_audio::play_no_money_perk_dialog();
		}		
	}
}

// returns the trigger hint string for the given weapon
get_weapon_hint( weapon_name )
{
	AssertEx( IsDefined( level.zombie_weapons[weapon_name] ), weapon_name + " was not included or is not part of the zombie weapon list." );

	return level.zombie_weapons[weapon_name].hint;
}

get_weapon_cost( weapon_name )
{
	AssertEx( IsDefined( level.zombie_weapons[weapon_name] ), weapon_name + " was not included or is not part of the zombie weapon list." );

	return level.zombie_weapons[weapon_name].cost;
}

get_ammo_cost( weapon_name )
{
	AssertEx( IsDefined( level.zombie_weapons[weapon_name] ), weapon_name + " was not included or is not part of the zombie weapon list." );

	return level.zombie_weapons[weapon_name].ammo_cost;
}

get_is_in_box( weapon_name )
{
	AssertEx( IsDefined( level.zombie_weapons[weapon_name] ), weapon_name + " was not included or is not part of the zombie weapon list." );
	
	return level.zombie_weapons[weapon_name].is_in_box;
}

is_weapon_upgraded( weaponname )
{
	if( !isdefined( weaponname ) )
	{
		return false;
	}

	weaponname = ToLower( weaponname );

	upgraded = issubstr( weaponname, "_upgraded" );

	return upgraded;

}

has_upgrade( weaponname )
{
	has_upgrade = false;
	if( IsDefined( level.zombie_include_weapons[weaponname+"_upgraded"] ) )
	{
		has_upgrade = self HasWeapon( weaponname+"_upgraded" );
	}
	return has_upgrade;
}

has_weapon_or_upgrade( weaponname )
{
	has_weapon = false;
	if (self maps\_laststand::player_is_in_laststand())
	{
		for( m = 0; m < self.weaponInventory.size; m++ )
		{
			if (self.weaponInventory[m] == weaponname || self.weaponInventory[m] == weaponname+"_upgraded" )
			{
				has_weapon = true;
			}
		}
	}
	else
	{
		// If the weapon you're checking doesn't exist, it will return undefined
		if( IsDefined( level.zombie_include_weapons[weaponname] ) )
		{
			has_weapon = self HasWeapon( weaponname );
		}
	
		if( !has_weapon && isdefined( level.zombie_include_weapons[weaponname+"_upgraded"] ) )
		{
			has_weapon = self HasWeapon( weaponname+"_upgraded" );
		}
	}

	return has_weapon;
}

using_weapon_or_upgrade( weaponname )
{
	if( self GetCurrentWeapon() == weaponname || self GetCurrentWeapon() == weaponname+"_upgraded" )
	{
		return true;
	}
	return false;
}

default_weighting_func()
{
	return 1;
}

default_tesla_weighting_func()
{
	num_to_add = 1;
	if( isDefined( level.pulls_since_last_tesla_gun ) )
	{
		// player has dropped the tesla for another weapon, so we set all future polls to 20%
		if( isDefined(level.player_drops_tesla_gun) && level.player_drops_tesla_gun == true )
		{						
			num_to_add += int(.2 * level.zombie_include_weapons.size);		
		}
		
		// player has not seen tesla gun in late rounds
		if( !isDefined(level.player_seen_tesla_gun) || level.player_seen_tesla_gun == false )
		{
			// after round 10 the Tesla gun percentage increases to 20%
			if( level.round_number > 10 )
			{
				num_to_add += int(.2 * level.zombie_include_weapons.size);
			}		
			// after round 5 the Tesla gun percentage increases to 15%
			else if( level.round_number > 5 )
			{
				// calculate the number of times we have to add it to the array to get the desired percent
				num_to_add += int(.15 * level.zombie_include_weapons.size);
			}						
		}
	}
	return num_to_add;
}

default_ray_gun_weighting_func()
{
	if( level.box_moved == true )
	{	
		num_to_add = 1;
		// increase the percentage of ray gun
		if( isDefined( level.pulls_since_last_ray_gun ) )
		{
			// after 12 pulls the ray gun percentage increases to 15%
			if( level.pulls_since_last_ray_gun > 11 )
			{
				num_to_add += int(level.zombie_include_weapons.size*0.15);			
			}			
			// after 8 pulls the Ray Gun percentage increases to 10%
			else if( level.pulls_since_last_ray_gun > 7 )
			{
				num_to_add += int(.1 * level.zombie_include_weapons.size);
			}		
		}
		return num_to_add;	
	}
	else
	{
		return 0;
	}
}


//
//	Slightly elevate the chance to get it until someone has it, then make it even
default_cymbal_monkey_weighting_func()
{
	players = get_players();
	count = 0;
	for( i = 0; i < players.size; i++ )
	{
		if( players[i] has_weapon_or_upgrade( "zombie_cymbal_monkey" ) )
		{
			count++;
		}
	}
	if ( count > 0 )
	{
		return 1;
	}
	else
	{
		if( level.round_number < 10 )
		{
			return 3;
		}
		else
		{
			return 5;
		}
	}
}

can_buy_weapon()
{
	if( isDefined( self.is_drinking ) && self.is_drinking )
	{
		return false;
	}
	if( self GetCurrentWeapon() == "mine_bouncing_betty" )
	{
		return false;
	}
	if( self in_revive_trigger() )
	{
		return false;
	}
	return true;
}

weapon_cabinet_door_open( left_or_right )
{
	if( left_or_right == "left" )
	{
		self rotateyaw( 120, 0.3, 0.2, 0.1 ); 	
	}
	else if( left_or_right == "right" )
	{
		self rotateyaw( -120, 0.3, 0.2, 0.1 ); 	
	}	
}

weapon_spawn_think()
{
	cost = get_weapon_cost( self.zombie_weapon_upgrade );
	ammo_cost = get_ammo_cost( self.zombie_weapon_upgrade );
	is_grenade = (WeaponType( self.zombie_weapon_upgrade ) == "grenade");
	if(is_grenade)
	{
		ammo_cost = cost;
	}

	self thread decide_hide_show_hint();

	self.first_time_triggered = false; 
	for( ;; )
	{
		self waittill( "trigger", player ); 		
		// if not first time and they have the weapon give ammo

		if( !is_player_valid( player ) )
		{
			player thread ignore_triggers( 0.5 );
			continue;
		}

		if( !player can_buy_weapon() )
		{
			wait( 0.1 );
			continue;
		}

		// Allow people to get ammo off the wall for upgraded weapons
		player_has_weapon = player has_weapon_or_upgrade( self.zombie_weapon_upgrade ); 
		/*
		player_has_weapon = false;
		weapons = player GetWeaponsList(); 
		if( IsDefined( weapons ) )
		{
			for( i = 0; i < weapons.size; i++ )
			{
				if( weapons[i] == self.zombie_weapon_upgrade )
				{
					player_has_weapon = true; 
				}
			}
		}		
		*/

		if( !player_has_weapon )
		{
			// else make the weapon show and give it
			if( player.score >= cost )
			{
				if( self.first_time_triggered == false )
				{
					model = getent( self.target, "targetname" ); 
					//					model show(); 
					model thread weapon_show( player ); 
					self.first_time_triggered = true; 

					if(!is_grenade)
					{
						self SetHintString( &"ZOMBIE_WEAPONCOSTAMMO", cost, ammo_cost ); 
					}
				}

				player maps\so\zm_common\_zm_score::minus_to_player_score( cost ); 

				bbPrint( "zombie_uses: playername %s playerscore %d round %d cost %d name %s x %f y %f z %f type weapon",
						player.playername, player.score, level.round_number, cost, self.zombie_weapon_upgrade, self.origin );

				player weapon_give( self.zombie_weapon_upgrade ); 
			}
			else
			{
				player play_sound_on_ent( "no_purchase" );
				player thread maps\so\zm_common\_zm_audio::play_no_money_purchase_dialog();		
			}
		}
		else
		{
			// MM - need to check and see if the player has an upgraded weapon.  If so, the ammo cost is much higher
			if ( player has_upgrade( self.zombie_weapon_upgrade ) )
			{
				ammo_cost = 4500;
			}
			else
			{
				ammo_cost = get_ammo_cost( self.zombie_weapon_upgrade );
			}

			// if the player does have this then give him ammo.
			if( player.score >= ammo_cost )
			{
				if( self.first_time_triggered == false )
				{
					model = getent( self.target, "targetname" ); 
					//					model show(); 
					model thread weapon_show( player ); 
					self.first_time_triggered = true;
					if(!is_grenade)
					{ 
						self SetHintString( &"ZOMBIE_WEAPONCOSTAMMO", cost, get_ammo_cost( self.zombie_weapon_upgrade ) ); 
					}
				}

				if( player HasWeapon( self.zombie_weapon_upgrade ) && player has_upgrade( self.zombie_weapon_upgrade ) )
				{
					ammo_given = player ammo_give( self.zombie_weapon_upgrade, true ); 
				}
				else if( player has_upgrade( self.zombie_weapon_upgrade ) )
				{
					ammo_given = player ammo_give( self.zombie_weapon_upgrade+"_upgraded" ); 
				}
				else
				{
					ammo_given = player ammo_give( self.zombie_weapon_upgrade ); 
				}
				
				if( ammo_given )
				{
						player maps\so\zm_common\_zm_score::minus_to_player_score( ammo_cost ); // this give him ammo to early

					bbPrint( "zombie_uses: playername %s playerscore %d round %d cost %d name %s x %f y %f z %f type ammo",
						player.playername, player.score, level.round_number, ammo_cost, self.zombie_weapon_upgrade, self.origin );
				}
			}
			else
			{
				play_sound_on_ent( "no_purchase" );
			}
		}
	}
}

weapon_show( player )
{
	player_angles = VectorToAngles( player.origin - self.origin ); 

	player_yaw = player_angles[1]; 
	weapon_yaw = self.angles[1]; 

	yaw_diff = AngleClamp180( player_yaw - weapon_yaw ); 

	if( yaw_diff > 0 )
	{
		yaw = weapon_yaw - 90; 
	}
	else
	{
		yaw = weapon_yaw + 90; 
	}

	self.og_origin = self.origin; 
	self.origin = self.origin +( AnglesToForward( ( 0, yaw, 0 ) ) * 8 ); 

	wait( 0.05 ); 
	self Show(); 

	play_sound_at_pos( "weapon_show", self.origin, self );

	time = 1; 
	self MoveTo( self.og_origin, time ); 
}

weapon_give( weapon, is_upgrade )
{
	primaryWeapons = self GetWeaponsListPrimaries(); 
	current_weapon = undefined; 

	//if is not an upgraded perk purchase
	if( !IsDefined( is_upgrade ) )
	{
		is_upgrade = false;
	}

	weapon_limit = get_player_weapon_limit( self );

	// This should never be true for the first time.
	if( primaryWeapons.size >= weapon_limit ) // he has two weapons
	{
		current_weapon = self getCurrentWeapon(); // get his current weapon

		if ( current_weapon == "mine_bouncing_betty" )
		{
			current_weapon = undefined;
		}

		if( isdefined( current_weapon ) )
		{
			if( !( weapon == "fraggrenade" || weapon == "stielhandgranate" || weapon == "molotov" || weapon == "zombie_cymbal_monkey" ) )
			{
				self TakeWeapon( current_weapon ); 
			}
		} 
	}

	if( weapon == "zombie_cymbal_monkey" )
	{
		// PI_CHANGE_BEGIN
		// JMA 051409 sanity check to see if we have the weapon before we remove it	
		has_weapon = self HasWeapon( "molotov" );
		if( isDefined(has_weapon) && has_weapon )
		{
			self TakeWeapon( "molotov" );
		}

		if( isDefined(level.zombie_weapons) && isDefined(level.zombie_weapons["molotov_zombie"]) )
		{		
			has_weapon = self HasWeapon( "molotov_zombie" );
			if( isDefined(has_weapon) && has_weapon )
			{
				self TakeWeapon( "molotov_zombie" );
			}
		}
		// PI_CHANGE_END
		if ( isDefined( level._zm_cymbal_monkey_funcs ) && isDefined( level._zm_cymbal_monkey_funcs[ "player_give_cymbal_monkey" ] ) )
		{
			self [[ level._zm_cymbal_monkey_funcs[ "player_give_cymbal_monkey" ] ]]();
		}
		play_weapon_vo( weapon );
		return;
	}
	if( (weapon == "molotov" || weapon == "molotov_zombie") )
	{
			self TakeWeapon( "zombie_cymbal_monkey" );
	}

	self play_sound_on_ent( "purchase" );
	self GiveWeapon( weapon, 0 ); 
	self GiveMaxAmmo( weapon ); 
	self SwitchToWeapon( weapon );
	 
	play_weapon_vo(weapon);
}
play_weapon_vo(weapon)
{
	index = get_player_index(self);
	if(!IsDefined (level.zombie_weapons[weapon].sound))
	{
		return;
	}	
	
	if( level.zombie_weapons[weapon].sound == "vox_monkey" )
	{
		plr = "plr_" + index + "_";
		create_and_play_dialog( plr, "vox_monkey", .25, "resp_monk" );
		return;
	}
	//	iprintlnbold (index);
	if( level.zombie_weapons[weapon].sound != "" )
	{
		weap = level.zombie_weapons[weapon].sound;
//		iprintlnbold("Play_Weap_VO_" + weap);
		switch(weap)
		{
			case "vox_crappy":
				if (level.vox_crappy_available.size < 1 )
				{
					level.vox_crappy_available = level.vox_crappy;
				}
				sound_to_play = random(level.vox_crappy_available);
				level.vox_crappy_available = array_remove(level.vox_crappy_available,sound_to_play);
				break;

			case "vox_mg":
				if (level.vox_mg_available.size < 1 )
				{
					level.vox_mg_available = level.vox_mg;
				}
				sound_to_play = random(level.vox_mg_available);
				level.vox_mg_available = array_remove(level.vox_mg_available,sound_to_play);
				break;
			case "vox_shotgun":
				if (level.vox_shotgun_available.size < 1 )
				{
					level.vox_shotgun_available = level.vox_shotgun;
				}
				sound_to_play = random(level.vox_shotgun_available);
				level.vox_shotgun_available = array_remove(level.vox_shotgun_available,sound_to_play);
				break;
			case "vox_357":
				if (level.vox_357_available.size < 1 )
				{
					level.vox_357_available = level.vox_357;
				}
				sound_to_play = random(level.vox_357_available);
				level.vox_357_available = array_remove(level.vox_357_available,sound_to_play);
				break;
			case "vox_bar":
				if (level.vox_bar_available.size < 1 )
				{
					level.vox_bar_available = level.vox_bar;
				}
				sound_to_play = random(level.vox_bar_available);
				level.vox_bar_available = array_remove(level.vox_bar_available,sound_to_play);
				break;
			case "vox_flame":
				if (level.vox_flame_available.size < 1 )
				{
					level.vox_flame_available = level.vox_flame;
				}
				sound_to_play = random(level.vox_flame_available);
				level.vox_flame_available = array_remove(level.vox_flame_available,sound_to_play);
				break;
			case "vox_raygun":
				if (level.vox_raygun_available.size < 1 )
				{
					level.vox_raygun_available = level.vox_raygun;
				}
				sound_to_play = random(level.vox_raygun_available);
				level.vox_raygun_available = array_remove(level.vox_raygun_available,sound_to_play);
				break;
			case "vox_tesla":
				if (level.vox_tesla_available.size < 1 )
				{
					level.vox_tesla_available = level.vox_tesla;
				}
				sound_to_play = random(level.vox_tesla_available);
				level.vox_tesla_available = array_remove(level.vox_tesla_available,sound_to_play);
				break;
			case "vox_sticky":
				if (level.vox_sticky_available.size < 1 )
				{
					level.vox_sticky_available = level.vox_sticky;
				}
				sound_to_play = random(level.vox_sticky_available);
				level.vox_sticky_available = array_remove(level.vox_sticky_available,sound_to_play);
				break;
			case "vox_ppsh":
				if (level.vox_ppsh_available.size < 1 )
				{
					level.vox_ppsh_available = level.vox_ppsh;
				}
				sound_to_play = random(level.vox_ppsh_available);
				level.vox_ppsh_available = array_remove(level.vox_ppsh_available,sound_to_play);
				break;
			case "vox_mp40":
			if (level.vox_mp40_available.size < 1 )
				{
					level.vox_mp40_available = level.vox_mp40;
				}
				sound_to_play = random(level.vox_mp40_available);
				level.vox_mp40_available = array_remove(level.vox_mp40_available,sound_to_play);
				break;					
			
			default: 
				sound_var = randomintrange(0, level.zombie_weapons[weapon].variation_count);
				sound_to_play = level.zombie_weapons[weapon].sound + "_" + sound_var;
				
		}

		plr = "plr_" + index + "_";
		self maps\so\zm_common\_zm_audio::do_player_playdialog(plr, sound_to_play, 0.05);
	}
}
do_player_weap_dialog(player_index, sound_to_play, waittime)
{
	if(!IsDefined (level.player_is_speaking))
	{
		level.player_is_speaking = 0;
	}
	if(level.player_is_speaking != 1)
	{
		level.player_is_speaking = 1;
		self playsound(player_index + sound_to_play, "sound_done" + sound_to_play);			
		self waittill("sound_done" + sound_to_play);
		wait(waittime);		
		level.player_is_speaking = 0;
	}
	
}
get_player_index(player)
{
	assert( IsPlayer( player ) );
	assert( IsDefined( player.entity_num ) );
/#
	// used for testing to switch player's VO in-game from devgui
	if( player.entity_num == 0 && GetDVar( "zombie_player_vo_overwrite" ) != "" )
	{
		new_vo_index = GetDVarInt( "zombie_player_vo_overwrite" );
		return new_vo_index;
	}
#/
	return player.entity_num;
}

ammo_give( weapon, also_has_upgrade )
{
	// We assume before calling this function we already checked to see if the player has this weapon...

	if( !isDefined( also_has_upgrade ) )
	{
		also_has_upgrade = false;
	}

	// Should we give ammo to the player
	give_ammo = false; 

	// Check to see if ammo belongs to a primary weapon
	if( weapon != "fraggrenade" && weapon != "stielhandgranate" && weapon != "molotov" )
	{
		if( isdefined( weapon ) )  
		{
			// get the max allowed ammo on the current weapon
			stockMax = WeaponMaxAmmo( weapon ); 
			if( also_has_upgrade ) 
			{
				stockMax += WeaponMaxAmmo( weapon+"_upgraded" );
			}

			// Get the current weapon clip count
			clipCount = self GetWeaponAmmoClip( weapon ); 

			currStock = self GetAmmoCount( weapon );

			// compare it with the ammo player actually has, if more or equal just dont give the ammo, else do
			if( ( currStock - clipcount ) >= stockMax )	
			{
				give_ammo = false; 
			}
			else
			{
				give_ammo = true; // give the ammo to the player
			}
		}
	}
	else
	{
		// Ammo belongs to secondary weapon
		if( self has_weapon_or_upgrade( weapon ) )
		{
			// Check if the player has less than max stock, if no give ammo
			if( self getammocount( weapon ) < WeaponMaxAmmo( weapon ) )
			{
				// give the ammo to the player
				give_ammo = true; 					
			}
		}		
	}	

	if( give_ammo )
	{
		self playsound( "cha_ching" ); 
		self GivemaxAmmo( weapon ); 
		if( also_has_upgrade )
		{
			self GiveMaxAmmo( weapon+"_upgraded" );
		}
		return true;
	}

	if( !give_ammo )
	{
		return false;
	}
}
add_weapon_to_sound_array(vo,num)
{
	if(!isDefined(vo))
	{
		return;
	}
	player = getplayers();
	for(i=0;i<player.size;i++)
	{
		index = get_player_index(player);
		player_index = "plr_" + index + "_";
		num = maps\so\zm_common\_zm_audio::get_number_variants(player_index + vo);
	}
//	iprintlnbold(vo);

	switch(vo)
	{
		case "vox_crappy":
			if(!isDefined(level.vox_crappy))
			{
				level.vox_crappy = [];
				for(i=0;i<num;i++)
				{
					level.vox_crappy[level.vox_crappy.size] = "vox_crappy_" + i;						
				}				
			}
			level.vox_crappy_available = level.vox_crappy;
			break;

		case "vox_mg":
			if(!isDefined(level.vox_mg))
			{
				level.vox_mg = [];
				for(i=0;i<num;i++)
				{
					level.vox_mg[level.vox_mg.size] = "vox_mg_" + i;						
				}				
			}
			level.vox_mg_available = level.vox_mg;
			break;
		case "vox_shotgun":
			if(!isDefined(level.vox_shotgun))
			{
				level.vox_shotgun = [];
				for(i=0;i<num;i++)
				{
					level.vox_shotgun[level.vox_shotgun.size] = "vox_shotgun_" + i;						
				}				
			}
			level.vox_shotgun_available = level.vox_shotgun;
			break;
		case "vox_357":
			if(!isDefined(level.vox_357))
			{
				level.vox_357 = [];
				for(i=0;i<num;i++)
				{
					level.vox_357[level.vox_357.size] = "vox_357_" + i;						
				}				
			}
			level.vox_357_available = level.vox_357;
			break;
		case "vox_bar":
			if(!isDefined(level.vox_bar))
			{
				level.vox_bar = [];
				for(i=0;i<num;i++)
				{
					level.vox_bar[level.vox_bar.size] = "vox_bar_" + i;						
				}				
			}
			level.vox_bar_available = level.vox_bar;
			break;
		case "vox_flame":
			if(!isDefined(level.vox_flame))
			{
				level.vox_flame = [];
				for(i=0;i<num;i++)
				{
					level.vox_flame[level.vox_flame.size] = "vox_flame_" + i;						
				}				
			}
			level.vox_flame_available = level.vox_flame;
			break;

		case "vox_raygun":
			if(!isDefined(level.vox_raygun))
			{
				level.vox_raygun = [];
				for(i=0;i<num;i++)
				{
					level.vox_raygun[level.vox_raygun.size] = "vox_raygun_" + i;						
				}				
			}
			level.vox_raygun_available = level.vox_raygun;
			break;
		case "vox_tesla":
			if(!isDefined(level.vox_tesla))
			{
				level.vox_tesla = [];
				for(i=0;i<num;i++)
				{
					level.vox_tesla[level.vox_tesla.size] = "vox_tesla_" + i;						
				}				
			}
			level.vox_tesla_available = level.vox_tesla;
			break;
		case "vox_sticky":
			if(!isDefined(level.vox_sticky))
			{
				level.vox_sticky = [];
				for(i=0;i<num;i++)
				{
					level.vox_sticky[level.vox_sticky.size] = "vox_sticky_" + i;						
				}				
			}
			level.vox_sticky_available = level.vox_sticky;
			break;
		case "vox_ppsh":
			if(!isDefined(level.vox_ppsh))
			{
				level.vox_ppsh = [];
				for(i=0;i<num;i++)
				{
					level.vox_ppsh[level.vox_ppsh.size] = "vox_ppsh_" + i;						
				}				
			}
			level.vox_ppsh_available = level.vox_ppsh;
			break;		
		case "vox_mp40":
			if(!isDefined(level.vox_mp40))
			{
				level.vox_mp40 = [];
				for(i=0;i<num;i++)
				{
					level.vox_mp40[level.vox_mp40.size] = "vox_mp40_" + i;						
				}				
			}
			level.vox_mp40_available = level.vox_mp40;
			break;
		case "vox_monkey":
			if(!isDefined(level.vox_monkey))
			{
				level.vox_monkey = [];
				for(i=0;i<num;i++)
				{
					level.vox_monkey[level.vox_monkey.size] = "vox_monkey_" + i;						
				}				
			}
			level.vox_monkey_available = level.vox_monkey;
			break;	
	}

}