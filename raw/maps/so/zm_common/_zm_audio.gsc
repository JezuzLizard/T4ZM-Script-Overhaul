#include maps\_utility;
#include common_scripts\utility;
#include maps\so\zm_common\_zm_utility;

designate_rival_hero(player, hero, rival)
{
	players = getplayers();

//		iprintlnbold("designating_rival");

	playHero = isdefined(players[hero]);
	playRival = isdefined(players[rival]);
	
	if(playHero && playRival)
	{
		if(randomfloatrange(0,1) < .5)
		{
			playRival = false;
		}
		else
		{
			playHero = false;
		}
	}	
	if(playHero)
	{		
		if( distance (player.origin, players[hero].origin) < 400)
		{
			player_responder = "plr_" + hero+"_";
			players[hero] play_headshot_response_hero(player_responder);
		}
	}		
	
	if(playRival)
	{
		if( distance (player.origin, players[rival].origin) < 400)
		{
			player_responder = "plr_" + rival+"_";
			players[rival] play_headshot_response_rival(player_responder);
		}
	}
}
play_death_vo(hit_location, player,mod,zombie)
{
	if ( is_true( level.no_player_dialog ) )
	{
		return;
	}
	// CHRISP - adding some modifiers here so that it doens't play 100% of the time 
	// and takes into account the damage type. 
	//	default is 10% chance of saying something
	//iprintlnbold(mod);
	
	//iprintlnbold(player);
	
	if( getdvar("zombie_death_vo_freq") == "" )
	{
		setdvar("zombie_death_vo_freq","100"); //TUEY moved to 50---We can take this out\tweak this later.
	}
	
	chance = getdvarint("zombie_death_vo_freq");
	
	weapon = player GetCurrentWeapon();
	//iprintlnbold (weapon);
	
	sound = undefined;
	//just return and don't play a sound if the chance is not there
	if(chance < randomint(100) )
	{
		return;
	}

	//TUEY - this funciton allows you to play a voice over when you kill a zombie and its last hit spot was something specific (like Headshot).
	//players = getplayers();
	index = maps\so\zm_common\_zm_weapons::get_player_index(player);
	
	players = getplayers();

	if(!isdefined (level.player_is_speaking))
	{
		level.player_is_speaking = 0;
	}
	if(!isdefined(level.zombie_vars["zombie_insta_kill"] ))
	{
		level.zombie_vars["zombie_insta_kill"] = 0;
	}
	if(hit_location == "head" && level.zombie_vars["zombie_insta_kill"] != 1   )
	{
		//no VO for non bullet headshot kills
		if( mod != "MOD_PISTOL_BULLET" &&	mod != "MOD_RIFLE_BULLET" )
		{
			return;
		}					
		//chrisp - far headshot sounds
		if(distance(player.origin,zombie.origin) > 450)
		{
			//sound = "plr_" + index + "_vox_kill_headdist" + "_" + randomintrange(0, 11);
			plr = "plr_" + index + "_";
			player thread play_headshot_dialog (plr);

			if(index == 0)
			{	//DEMPSEY gets a headshot, response hero Tenko, rival The Doc
			
				designate_rival_hero(player,2,3);	
			}
			if(index == 1)	
			{		
				//Nickolai gets a headshot, response hero Dempsey, rival Tenko
				designate_rival_hero(player,3,2);
			}		
			if(index == 2)
			{
				//Tenko gets a headshot, response hero The Doctor, rival Nickolai
				designate_rival_hero(player,0,1);	
			}
			if(index == 3)
			{
				//The Doc gets a headshot, response hero Nickolai, rival Dempsey
				designate_rival_hero(player,1,0);	
			}
			return;

		}	
		//remove headshot sounds for instakill
		if (level.zombie_vars["zombie_insta_kill"] != 0)
		{			
			sound = undefined;
		}

	}
	if(weapon == "ray_gun")
	{
		//Ray Gun Kills
		if(distance(player.origin,zombie.origin) > 348 && level.zombie_vars["zombie_insta_kill"] == 0)
		{
			rand = randomintrange(0, 100);
			if(rand < 28)
			{
				plr = "plr_" + index + "_";
				player play_raygun_dialog(plr);
				
			}
			
		}	
		return;
	}
	if(weapon == "ray_gun")
	{
		//Ray Gun Kills
		if(distance(player.origin,zombie.origin) > 348 && level.zombie_vars["zombie_insta_kill"] == 0)
		{
			rand = randomintrange(0, 100);
			if(rand < 28)
			{
				plr = "plr_" + index + "_";
				player play_raygun_dialog(plr);
				
			}
			
		}	
		return;
	}
	if( mod == "MOD_BURNED" )
	{
		//TUEY play flamethrower death sounds
		
		//	iprintlnbold(mod);
		plr = "plr_" + index + "_";
		player play_flamethrower_dialog (plr);
		return;
	}	
	//check for close range kills, and play a special sound, unless instakill is on 
	
	if( mod != "MOD_MELEE" && hit_location != "head" && level.zombie_vars["zombie_insta_kill"] == 0 && !zombie.has_legs )
	{
		rand = randomintrange(0, 100);
		if(rand < 15)
		{
			plr = "plr_" + index + "_";
			player create_and_play_dialog ( plr, "vox_crawl_kill", 0.25 );
		}
		return;
	}
	
	if( player HasPerk( "specialty_altmelee" ) && mod == "MOD_MELEE" && level.zombie_vars["zombie_insta_kill"] == 0 )
	{
		rand = randomintrange(0, 100);
		if(rand < 25)
		{
			plr = "plr_" + index + "_";
			player create_and_play_dialog ( plr, "vox_kill_bowie", 0.25 );
		}
		return;
	}
	
	//special case for close range melee attacks while insta-kill is on
	if (level.zombie_vars["zombie_insta_kill"] != 0)
	{
		if( mod == "MOD_MELEE" || mod == "MOD_BAYONET" || mod == "MOD_UNKNOWN" && distance(player.origin,zombie.origin) < 64)
		{
			plr = "plr_" + index + "_";
			player play_insta_melee_dialog(plr);
			//sound = "plr_" + index + "_vox_melee_insta" + "_" + randomintrange(0, 5); 
			return;
		}
	}
	
	//Explosive Kills
	if((mod == "MOD_GRENADE_SPLASH" || mod == "MOD_GRENADE") && level.zombie_vars["zombie_insta_kill"] == 0 )
	{
		//Plays explosion dialog
		if( zombie.damageweapon	== "zombie_cymbal_monkey" )
		{
			plr = "plr_" + index + "_";
			player create_and_play_dialog( plr, "vox_kill_monkey", 0.25 );
			return;
		}
		else
		{
			plr = "plr_" + index + "_";
			player play_explosion_dialog(plr);
			return;
		}
	}
	
	if( mod == "MOD_PROJECTILE")
	{	
		//Plays explosion dialog
		plr = "plr_" + index + "_";
		player play_explosion_dialog(plr);
	}
	
	if(IsDefined(zombie) && distance(player.origin,zombie.origin) < 64 && level.zombie_vars["zombie_insta_kill"] == 0 && mod != "MOD_BURNED" )
	{
		rand = randomintrange(0, 100);
		if(rand < 40)
		{
			plr = "plr_" + index + "_";
			player play_closekill_dialog (plr);				
		}	
		return;
	
	}	
	
/*
	//This keeps multiple voice overs from playing on the same player (both killstreaks and headshots).
	if (level.player_is_speaking != 1 && isDefined(sound) && level.zombie_vars["zombie_insta_kill"] != 0)
	{	
		level.player_is_speaking = 1;
		player playsound(sound, "sound_done");			
		player waittill("sound_done");
		//This ensures that there is at least 2 seconds waittime before playing another VO.
		wait(2);		
		level.player_is_speaking = 0;
	}
	//This allows us to play VO's faster if the player is in Instakill and killing at a short distance.
	else if (level.player_is_speaking != 1 && isDefined(sound) && level.zombie_vars["zombie_insta_kill"] == 0)
	{
		level.player_is_speaking = 1;
		player playsound(sound, "sound_done");			
		player waittill("sound_done");
		//This ensures that there is at least 3 seconds waittime before playing another VO.
		wait(0.5);		
		level.player_is_speaking = 0;

	}	
*/
}

play_headshot_response_hero(player_index)
{
	if ( is_true( level.no_player_dialog ) )
	{
		return;
	}	
	waittime = 0;
	if(!IsDefined( self.one_at_a_time_hero))
	{
		self.one_at_a_time_hero = 0;
	}
	if(!IsDefined (self.vox_resp_hr_headdist))
	{
		num_variants = get_number_variants(player_index + "vox_resp_hr_headdist");
	//	iprintlnbold(num_variants);
		self.vox_resp_hr_headdist = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_resp_hr_headdist[self.vox_resp_hr_headdist.size] = "vox_resp_hr_headdist_" + i;	
		}
		self.vox_resp_hr_headdist_available = self.vox_resp_hr_headdist;
	}
	if ( self.one_at_a_time_hero == 0 && self.vox_resp_hr_headdist_available.size > 0 )
	{
		self.one_at_a_time_hero = 1;
		sound_to_play = random(self.vox_resp_hr_headdist_available);
	//	iprintlnbold(player_index + "_" + sound_to_play);
	
		wait(2);
		self do_player_playdialog(player_index, sound_to_play, waittime);
		self.vox_resp_hr_headdist_available = array_remove(self.vox_resp_hr_headdist_available,sound_to_play);			
		if (self.vox_resp_hr_headdist_available.size < 1 )
		{
			self.vox_resp_hr_headdist_available = self.vox_resp_hr_headdist;
		}
		self.one_at_a_time_hero = 0;
	}
}
play_headshot_response_rival(player_index)
{
	if ( is_true( level.no_player_dialog ) )
	{
		return;
	}	
	waittime = 0;
	if(!IsDefined( self.one_at_a_time_rival))
	{
		self.one_at_a_time_rival = 0;
	}
	if(!IsDefined (self.vox_resp_riv_headdist))
	{
		num_variants = get_number_variants(player_index + "vox_resp_riv_headdist");
		self.vox_resp_riv_headdist = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_resp_riv_headdist[self.vox_resp_riv_headdist.size] = "vox_resp_riv_headdist_" + i;	
		}
		self.vox_resp_riv_headdist_available = self.vox_resp_riv_headdist;
	}
	if ( self.one_at_a_time_rival == 0 && self.vox_resp_riv_headdist_available.size > 0 )
	{
		self.one_at_a_time_rival = 1;
		sound_to_play = random(self.vox_resp_riv_headdist_available);
	//	iprintlnbold(player_index + "_" + sound_to_play);
		self.vox_resp_riv_headdist_available = array_remove(self.vox_resp_riv_headdist_available,sound_to_play);	
		wait(2);		
		self do_player_playdialog(player_index, sound_to_play, waittime);
		if (self.vox_resp_riv_headdist_available.size < 1 )
		{
			self.vox_resp_riv_headdist_available = self.vox_resp_riv_headdist;
		}
		self.one_at_a_time_rival = 0;
	}
}
play_projectile_dialog(player_index)
{
	if ( is_true( level.no_player_dialog ) )
	{
		return;
	}	
	waittime = 1;
	if(!IsDefined( self.one_at_a_time))
	{
		self.one_at_a_time = 0;
	}
	if(!IsDefined (self.vox_kill_explo))
	{
		num_variants = get_number_variants(player_index + "vox_kill_explo");
		self.vox_kill_explo = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_kill_explo[self.vox_kill_explo.size] = "vox_kill_explo_" + i;	
		}
		self.vox_kill_explo_available = self.vox_kill_explo;
	}
	if ( self.one_at_a_time == 0 && self.vox_kill_explo_available.size > 0 )
	{
		self.one_at_a_time = 1;
		sound_to_play = random(self.vox_kill_explo_available);
//		iprintlnbold(player_index + "_" + sound_to_play);
		self.vox_kill_explo_available = array_remove(self.vox_kill_explo_available,sound_to_play);			
		self do_player_playdialog(player_index, sound_to_play, waittime);
		if (self.vox_kill_explo_available.size < 1 )
		{
			self.vox_kill_explo_available = self.vox_kill_explo;
		}
		self.one_at_a_time = 0;
	}
}
play_explosion_dialog(player_index)
{
	if ( is_true( level.no_player_dialog ) )
	{
		return;
	}	
	waittime = 0.25;
	if(!IsDefined( self.one_at_a_time))
	{
		self.one_at_a_time = 0;
	}
	if(!IsDefined (self.vox_kill_explo))
	{
		num_variants = get_number_variants(player_index + "vox_kill_explo");
		self.vox_kill_explo = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_kill_explo[self.vox_kill_explo.size] = "vox_kill_explo_" + i;	
		}
		self.vox_kill_explo_available = self.vox_kill_explo;
	}
	if ( self.one_at_a_time == 0 && self.vox_kill_explo_available.size > 0 )
	{
		self.one_at_a_time = 1;
		sound_to_play = random(self.vox_kill_explo_available);
//			iprintlnbold(player_index + "_" + sound_to_play);
		self.vox_kill_explo_available = array_remove(self.vox_kill_explo_available,sound_to_play);			
		self do_player_playdialog(player_index, sound_to_play, waittime);
		if (self.vox_kill_explo_available.size < 1 )
		{
			self.vox_kill_explo_available = self.vox_kill_explo;
		}
		self.one_at_a_time = 0;
	}
}

play_flamethrower_dialog(player_index)
{
	if ( is_true( level.no_player_dialog ) )
	{
		return;
	}	
	waittime = 0.5;
	if(!IsDefined( self.one_at_a_time))
	{
		self.one_at_a_time = 0;
	}
	if(!IsDefined (self.vox_kill_flame))
	{
		num_variants = get_number_variants(player_index + "vox_kill_flame");
		self.vox_kill_flame = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_kill_flame[self.vox_kill_flame.size] = "vox_kill_flame_" + i;	
		}
		self.vox_kill_flame_available = self.vox_kill_flame;
	}
	if ( self.one_at_a_time == 0 && self.vox_kill_flame_available.size > 0 )
	{
		self.one_at_a_time = 1;
		sound_to_play = random(self.vox_kill_flame_available);
		self.vox_kill_flame_available = array_remove(self.vox_kill_flame_available,sound_to_play);			

		self do_player_playdialog(player_index, sound_to_play, waittime);
		if (self.vox_kill_flame_available.size < 1 )
		{
			self.vox_kill_flame_available = self.vox_kill_flame;
		}
		self.one_at_a_time = 0;
	}
}
play_closekill_dialog(player_index)
{
	if ( is_true( level.no_player_dialog ) )
	{
		return;
	}
	waittime = 1;
	if(!IsDefined( self.one_at_a_time))
	{
		self.one_at_a_time = 0;
	}
	if(!IsDefined (self.vox_close))
	{
		num_variants = get_number_variants(player_index + "vox_close");
		self.vox_close = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_close[self.vox_close.size] = "vox_close_" + i;	
		}
		self.vox_close_available = self.vox_close;
	}
	if(self.one_at_a_time == 0)
	{
		self.one_at_a_time = 1;
		if (self.vox_close_available.size >= 1)
		{
			sound_to_play = random(self.vox_close_available);
			self.vox_close_available = array_remove(self.vox_close_available,sound_to_play);
			self do_player_playdialog(player_index, sound_to_play, waittime);
		}

		if (self.vox_close_available.size < 1 )
		{
			self.vox_close_available = self.vox_close;
		}
		self.one_at_a_time = 0;
	}
}
get_number_variants(aliasPrefix)
{
		for(i=0; i<100; i++)
		{
			if( !SoundExists( aliasPrefix + "_" + i) )
			{
				//iprintlnbold(aliasPrefix +"_" + i);
				return i;
			}
		}
}	
play_headshot_dialog(player_index)
{
	if ( is_true( level.no_player_dialog ) )
	{
		return;
	}	
	waittime = 0.25;
	if(!IsDefined (self.vox_kill_headdist))
	{
		num_variants = get_number_variants(player_index + "vox_kill_headdist");
		//iprintlnbold(num_variants);
		self.vox_kill_headdist = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_kill_headdist[self.vox_kill_headdist.size] = "vox_kill_headdist_" + i;
			//iprintlnbold("vox_kill_headdist_" + i);	
		}
		self.vox_kill_headdist_available = self.vox_kill_headdist;
	}
	if ( self.vox_kill_headdist_available.size > 0 )
	{
		sound_to_play = random(self.vox_kill_headdist_available);
		//iprintlnbold("LINE:" + player_index + sound_to_play);
		self do_player_playdialog(player_index, sound_to_play, waittime);
		self.vox_kill_headdist_available = array_remove(self.vox_kill_headdist_available,sound_to_play);

		if (self.vox_kill_headdist_available.size < 1 )
		{
			self.vox_kill_headdist_available = self.vox_kill_headdist;
		}
	}
}
play_tesla_dialog(player_index)
{
	if ( is_true( level.no_player_dialog ) )
	{
		return;
	}	
	waittime = 0.25;
	if(!IsDefined (self.vox_kill_tesla))
	{
		num_variants = get_number_variants(player_index + "vox_kill_tesla");
		//iprintlnbold(num_variants);
		self.vox_kill_tesla = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_kill_tesla[self.vox_kill_tesla.size] = "vox_kill_tesla_" + i;
			//iprintlnbold("vox_kill_tesla_" + i);	
		}
		self.vox_kill_tesla_available = self.vox_kill_tesla;
	}

	if(!isdefined (level.player_is_speaking))
	{
		level.player_is_speaking = 0;
	}
	if ( self.vox_kill_tesla_available.size > 0 )
	{
		sound_to_play = random(self.vox_kill_tesla_available);
		//iprintlnbold("LINE:" + player_index + sound_to_play);
		self do_player_playdialog(player_index, sound_to_play, waittime);
		self.vox_kill_tesla_available = array_remove(self.vox_kill_tesla_available,sound_to_play);

		if (self.vox_kill_tesla_available.size < 1 )
		{
			self.vox_kill_tesla_available = self.vox_kill_tesla;
		}
	}
}
play_raygun_dialog(player_index)
{
	if ( is_true( level.no_player_dialog ) )
	{
		return;
	}	
	waittime = 0.05;
	if(!IsDefined (self.vox_kill_ray))
	{
		num_variants = get_number_variants(player_index + "vox_kill_ray");
		//iprintlnbold(num_variants);
		self.vox_kill_ray = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_kill_ray[self.vox_kill_ray.size] = "vox_kill_ray_" + i;
			//iprintlnbold("vox_kill_ray_" + i);	
		}
		self.vox_kill_ray_available = self.vox_kill_ray;
	}

	if(!isdefined (level.player_is_speaking))
	{
		level.player_is_speaking = 0;
	}
	if ( self.vox_kill_ray_available.size > 0 )
	{
		sound_to_play = random(self.vox_kill_ray_available);
	//	iprintlnbold("LINE:" + player_index + sound_to_play);
		self do_player_playdialog(player_index, sound_to_play, waittime);
		self.vox_kill_ray_available = array_remove(self.vox_kill_ray_available,sound_to_play);

		if (self.vox_kill_ray_available.size < 1 )
		{
			self.vox_kill_ray_available = self.vox_kill_ray;
		}
	}
}
play_insta_melee_dialog(player_index)
{
	if ( is_true( level.no_player_dialog ) )
	{
		return;
	}	
	waittime = 0.25;
	if(!IsDefined( self.one_at_a_time))
	{
		self.one_at_a_time = 0;
	}
	if(!IsDefined (self.vox_insta_melee))
	{
		num_variants = get_number_variants(player_index + "vox_insta_melee");
		self.vox_insta_melee = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_insta_melee[self.vox_insta_melee.size] = "vox_insta_melee_" + i;	
		}
		self.vox_insta_melee_available = self.vox_insta_melee;
	}
	if ( self.one_at_a_time == 0 && self.vox_insta_melee_available.size > 0 )
	{
		self.one_at_a_time = 1;
		sound_to_play = random(self.vox_insta_melee_available);
		self.vox_insta_melee_available = array_remove(self.vox_insta_melee_available,sound_to_play);
		if (self.vox_insta_melee_available.size < 1 )
		{
			self.vox_insta_melee_available = self.vox_insta_melee;
		}
		self do_player_playdialog(player_index, sound_to_play, waittime);
		//self playsound(player_index + sound_to_play, "sound_done" + sound_to_play);			
		//self waittill("sound_done" + sound_to_play);
		wait(waittime);
		self.one_at_a_time = 0;

	}
	//This ensures that there is at least 3 seconds waittime before playing another VO.

}
do_player_playdialog(player_index, sound_to_play, waittime, response)
{
	if ( is_true( level.no_player_dialog ) )
	{
		return;
	}
	index = maps\so\zm_common\_zm_weapons::get_player_index(self);
	
	if(!IsDefined(level.player_is_speaking))
	{
		level.player_is_speaking = 0;	
	}
	if(level.player_is_speaking != 1)
	{
		level.player_is_speaking = 1;
		//iprintlnbold(sound_to_play);
		self playsound(player_index + sound_to_play, "sound_done" + sound_to_play);			
		self waittill("sound_done" + sound_to_play);
		wait(waittime);		
		level.player_is_speaking = 0;
		if( isdefined( response ) )
		{
			level thread setup_response_line( self, index, response ); 
		}
	}
}

play_no_money_purchase_dialog()
{
	if ( is_true( level.no_player_dialog ) )
	{
		return;
	}
	index = maps\so\zm_common\_zm_weapons::get_player_index(self);
	
	player_index = "plr_" + index + "_";
	if(!IsDefined (self.vox_gen_sigh))
	{
		num_variants = get_number_variants(player_index + "vox_gen_sigh");
		self.vox_gen_sigh = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_gen_sigh[self.vox_gen_sigh.size] = "vox_gen_sigh_" + i;	
		}
		self.vox_gen_sigh_available = self.vox_gen_sigh;		
	}
	rand = randomintrange(0,6);
	if ( rand < 3 && self.vox_gen_sigh_available.size > 0 )
	{
		sound_to_play = random(self.vox_gen_sigh_available);		
		self.vox_gen_sigh_available = array_remove(self.vox_gen_sigh_available,sound_to_play);
		if (self.vox_gen_sigh_available.size < 1 )
		{
			self.vox_gen_sigh_available = self.vox_gen_sigh;
		}
		wait(0.25);
		self do_player_playdialog(player_index, sound_to_play, 0.25);
	}	
}

play_no_money_perk_dialog()
{
	if ( is_true( level.no_player_dialog ) )
	{
		return;
	}
	index = maps\so\zm_common\_zm_weapons::get_player_index(self);
	
	player_index = "plr_" + index + "_";
	if(!IsDefined (self.vox_nomoney_perk))
	{
		num_variants = get_number_variants(player_index + "vox_nomoney_perk");
		self.vox_nomoney_perk = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_nomoney_perk[self.vox_nomoney_perk.size] = "vox_nomoney_perk_" + i;	
		}
		self.vox_nomoney_perk_available = self.vox_nomoney_perk;		
	}	
	sound_to_play = random(self.vox_nomoney_perk_available);
	
	self.vox_nomoney_perk_available = array_remove(self.vox_nomoney_perk_available,sound_to_play);
	
	if (self.vox_nomoney_perk_available.size < 1 )
	{
		self.vox_nomoney_perk_available = self.vox_nomoney_perk;
	}
			
	self do_player_playdialog(player_index, sound_to_play, 0.25);
}