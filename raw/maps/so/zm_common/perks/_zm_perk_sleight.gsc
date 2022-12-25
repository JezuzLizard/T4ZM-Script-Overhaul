#include maps\so\zm_common\_zm_utility;

enable_sleight_perk_for_level()
{
	if ( isDefined( level.custom_map_perk_vox ) && isDefined( level.custom_map_perk_vox[ "sleight" ] ) )
	{
		vox = level.custom_map_perk_vox[ "sleight" ];
	}
	else 
	{
		vox = "vox_perk_speed_0";
	}
	maps\so\zm_common\_zm_perks::register_perk_basic_info( "specialty_fastreload", "sleight", 3000, &"ZOMBIE_PERK_FASTRELOAD", "zombie_perk_bottle_sleight", "specialty_fastreload_zombies", "mx_speed_jingle", "mx_speed_sting", vox );
	maps\so\zm_common\_zm_perks::register_perk_machine( "specialty_fastreload", ::turn_sleight_on );
	maps\so\zm_common\_zm_perks::register_perk_precache_func( "specialty_fastreload", ::sleight_precache );
	maps\so\zm_common\_zm_perks::register_perk_threads( "specialty_fastreload", ::sleight_give, ::sleight_take );
	if ( isDefined( level.zm_custom_map_perk_machine_loc_funcs ) && isDefined( level.zm_custom_map_perk_machine_loc_funcs[ "specialty_fastreload" ] ) )
	{
		level [[ level.zm_custom_map_perk_machine_loc_funcs[ "specialty_fastreload" ] ]]();
	}
}

turn_sleight_on()
{
	machine = getentarray("vending_sleight", "targetname");
	level waittill("sleight_on");

	for( i = 0; i < machine.size; i++ )
	{
		machine[i] setmodel("zombie_vending_sleight_on");
		machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
		machine[i] playsound("perks_power_on");
		machine[i] thread maps\so\zm_common\_zm_perks::perk_fx( "sleight_light" );
	}

	level notify( "specialty_fastreload_power_on" );
}

sleight_precache()
{
	PrecacheItem( "zombie_perk_bottle_sleight" );
	PrecacheShader( "specialty_fastreload_zombies" );
	if ( isDefined( level.custom_map_perk_models ) && isDefined( level.custom_map_perk_models[ "sleight" ] ) )
	{
		PrecacheModel( level.custom_map_perk_models[ "sleight" ] );
	}
	else 
	{
		PrecacheModel("zombie_vending_sleight_on");
	}
	level._effect["sleight_light"] = loadfx("misc/fx_zombie_cola_on");
	PrecacheString( &"ZOMBIE_PERK_FASTRELOAD" );
}

sleight_give()
{

}

sleight_take()
{

}