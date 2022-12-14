#include maps\so\zm_common\_zm_utility;

enable_doubletap_perk_for_level()
{
	if ( isDefined( level.zm_custom_map_perk_vox ) && isDefined( level.zm_custom_map_perk_vox[ "doubletap" ] ) )
	{
		vox = level.zm_custom_map_perk_vox[ "doubletap" ];
	}
	else 
	{
		vox = "vox_perk_doubletap_0";
	}
	maps\so\zm_common\_zm_perks::register_perk_basic_info( "specialty_rof", "doubletap", 2000, &"ZOMBIE_PERK_DOUBLETAP", "zombie_perk_bottle_doubletap", "specialty_doubletap_zombies", "mx_doubletap_jingle", "mx_doubletap_sting", vox );
	maps\so\zm_common\_zm_perks::register_perk_machine( "specialty_rof", ::turn_doubletap_on );
	maps\so\zm_common\_zm_perks::register_perk_precache_func( "specialty_rof", ::doubletap_precache );
	maps\so\zm_common\_zm_perks::register_perk_threads( "specialty_rof", ::doubletap_give, ::doubletap_take );
	if ( isDefined( level.zm_custom_map_perk_machine_loc_funcs ) && isDefined( level.zm_custom_map_perk_machine_loc_funcs[ "specialty_rof" ] ) )
	{
		level [[ level.zm_custom_map_perk_machine_loc_funcs[ "specialty_rof" ] ]]();
	}
}

turn_doubletap_on()
{
	machine = getentarray("vending_doubletap", "targetname");
	level waittill("doubletap_on");
	level._custom_perks[ "specialty_rof" ].powered_on = true;
	for( i = 0; i < machine.size; i++ )
	{
		if ( isDefined( level.zm_custom_map_perk_models ) && isDefined( level.zm_custom_map_perk_models[ "doubletap" ] ) )
		{
			machine[i] setmodel( level.zm_custom_map_perk_models[ "doubletap" ] );
		}
		else 
		{
			machine[i] setmodel("zombie_vending_doubletap_on");
		}
		
		machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
		machine[i] playsound("perks_power_on");
		machine[i] thread maps\so\zm_common\_zm_perks::perk_fx( "doubletap_light" );
	}
	level notify( "specialty_rof_power_on" );
}

doubletap_precache()
{
	PrecacheItem( "zombie_perk_bottle_doubletap" );
	PrecacheShader( "specialty_doubletap_zombies" );
	if ( isDefined( level.zm_custom_map_perk_models ) && isDefined( level.zm_custom_map_perk_models[ "doubletap" ] ) )
	{
		PrecacheModel( level.zm_custom_map_perk_models[ "doubletap" ] );
	}
	else 
	{
		PrecacheModel("zombie_vending_doubletap_on");
	}
	level._effect["doubletap_light"] = loadfx("misc/fx_zombie_cola_dtap_on");
	PrecacheString( &"ZOMBIE_PERK_DOUBLETAP" );
}

doubletap_give()
{

}

doubletap_take()
{
	
}