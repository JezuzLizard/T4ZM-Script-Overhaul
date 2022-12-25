#include maps\so\zm_common\_zm_utility;

enable_juggernog_perk_for_level()
{
	set_zombie_var( "zombie_perk_cost",					2000 );
	set_zombie_var( "zombie_perk_juggernaut_health",	160 );
	if ( isDefined( level.custom_map_perk_vox ) && isDefined( level.custom_map_perk_vox[ "juggernog" ] ) )
	{
		vox = level.custom_map_perk_vox[ "juggernog" ];
	}
	else 
	{
		vox = "vox_perk_jugga_0";
	}
	maps\so\zm_common\_zm_perks::register_perk_basic_info( "specialty_armorvest", "juggernog", 2500, &"ZOMBIE_PERK_JUGGERNAUT", "zombie_perk_bottle_jugg", "specialty_juggernaut_zombies", "mx_jugger_jingle", "mx_jugger_sting", vox );
	maps\so\zm_common\_zm_perks::register_perk_machine( "specialty_armorvest", ::turn_jugger_on );
	maps\so\zm_common\_zm_perks::register_perk_precache_func( "specialty_armorvest", ::juggernog_precache );
	maps\so\zm_common\_zm_perks::register_perk_threads( "specialty_armorvest", ::give_jugg, ::take_jugg );
	if ( isDefined( level.zm_custom_map_perk_machine_loc_funcs ) && isDefined( level.zm_custom_map_perk_machine_loc_funcs[ "specialty_armorvest" ] ) )
	{
		level [[ level.zm_custom_map_perk_machine_loc_funcs[ "specialty_armorvest" ] ]]();
	}
}

turn_jugger_on()
{
	machine = getentarray("vending_jugg", "targetname");
	//temp until I can get the wire to jugger.
	level waittill("juggernog_on");

	for( i = 0; i < machine.size; i++ )
	{
		machine[i] setmodel("zombie_vending_jugg_on");
		machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
		machine[i] playsound("perks_power_on");
		machine[i] thread maps\so\zm_common\_zm_perks::perk_fx( "jugger_light" );
		
	}
	level notify( "specialty_armorvest_power_on" );
	
}

juggernog_precache()
{
	PrecacheItem( "zombie_perk_bottle_jugg" );
	PrecacheShader( "specialty_juggernaut_zombies" );
	if ( isDefined( level.custom_map_perk_models ) && isDefined( level.custom_map_perk_models[ "juggernog" ] ) )
	{
		PrecacheModel( level.custom_map_perk_models[ "juggernog" ] );
	}
	else 
	{
		PrecacheModel("zombie_vending_jugg_on");
	}
	level._effect["jugger_light"] = loadfx("misc/fx_zombie_cola_jugg_on");
	PrecacheString( &"ZOMBIE_PERK_JUGGERNAUT" );
}

give_jugg()
{
	self.maxhealth = level.zombie_vars["zombie_perk_juggernaut_health"];
	self.health = level.zombie_vars["zombie_perk_juggernaut_health"];
	//player.health = 160;
}

take_jugg()
{
	
}