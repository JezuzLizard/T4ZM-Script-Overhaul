#include maps\so\zm_common\_zm_utility;

enable_revive_perk_for_level()
{
	if ( isDefined( level.custom_map_perk_vox ) && isDefined( level.custom_map_perk_vox[ "revive" ] ) )
	{
		vox = level.custom_map_perk_vox[ "revive" ];
	}
	else 
	{
		vox = "vox_perk_revive_0";
	}
	maps\so\zm_common\_zm_perks::register_perk_basic_info( "specialty_quickrevive", "revive", 1500, &"ZOMBIE_PERK_QUICKREVIVE", "zombie_perk_bottle_revive", "specialty_quickrevive_zombies", "mx_revive_jingle", "mx_revive_sting", vox );
	maps\so\zm_common\_zm_perks::register_perk_machine( "specialty_quickrevive", ::turn_revive_on );
	maps\so\zm_common\_zm_perks::register_perk_precache_func( "specialty_quickrevive", ::revive_precache );
	maps\so\zm_common\_zm_perks::register_perk_threads( "specialty_quickrevive", ::revive_give, ::revive_take );
	if ( isDefined( level.zm_custom_map_perk_machine_loc_funcs ) && isDefined( level.zm_custom_map_perk_machine_loc_funcs[ "specialty_quickrevive" ] ) )
	{
		level [[ level.zm_custom_map_perk_machine_loc_funcs[ "specialty_quickrevive" ] ]]();
	}
}

turn_revive_on()
{
	machine = getentarray("vending_revive", "targetname");
	level waittill("revive_on");

	level._custom_perks[ "specialty_quickrevive" ].powered_on = true;
	for( i = 0; i < machine.size; i++ )
	{
		if ( isDefined( level.custom_map_perk_models ) && isDefined( level.custom_map_perk_models[ "revive" ] ) )
		{
			machine[i] setmodel( level.custom_map_perk_models[ "revive" ] );
		}
		else 
		{
			machine[i] setmodel("zombie_vending_revive_on");
		}
		machine[i] playsound("perks_power_on");
		machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
		machine[i] thread maps\so\zm_common\_zm_perks::perk_fx( "revive_light" );
	}
	
	level notify( "specialty_quickrevive_power_on" );
}

revive_precache()
{
	PrecacheItem( "zombie_perk_bottle_revive" );
	PrecacheShader( "specialty_quickrevive_zombies" );
	if ( isDefined( level.custom_map_perk_models ) && isDefined( level.custom_map_perk_models[ "revive" ] ) )
	{
		PrecacheModel( level.custom_map_perk_models[ "revive" ] );
	}
	else 
	{
		PrecacheModel("zombie_vending_revive_on");
	}
	level._effect["revive_light"] = loadfx("misc/fx_zombie_cola_revive_on");
	PrecacheString( &"ZOMBIE_PERK_QUICKREVIVE" );
}

revive_give()
{

}

revive_take()
{
	
}