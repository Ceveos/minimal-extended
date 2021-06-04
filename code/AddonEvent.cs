﻿using Sandbox;
using System.Collections.Generic;
using System.Linq;

[Library("addon-event")]
public class AddonEvent
{
	private bool _addons_loaded = false;
	private List<IAddon> _addons = new List<IAddon>();

	private AddonEvent()
	{
		
	}

	public static AddonEvent instance { get; } = new();

	public void Run( string eventName)
	{
		if ( !_addons_loaded )
		{
			Log.Info( "Loading addons" );
			LoadAddons();
		}

		Log.Info( $"Loaded: {_addons_loaded}" );
		Log.Info( $"Running event: {eventName}" );
		Event.Run( eventName );
	}

		public void Run<T>( string eventName, T arg0)
	{
		if ( !_addons_loaded )
		{
			Log.Info( "Loading addons" );
			LoadAddons();
		}

		Log.Info( $"Loaded: {_addons_loaded}" );
		Log.Info( $"Running event: {eventName}" );
		Event.Run( eventName, arg0 );
	}

	public void LoadAddons()
	{
		_addons.Clear();
		Library.GetAll<IAddon>().ToList().ForEach( x => _addons.Add( Library.Create<IAddon>( x ) ) );

		bool gameModeRegistered = false;
		_addons.ForEach( addon => {
			if ( addon is IGameMode )
			{
				if ( gameModeRegistered )
				{
					Log.Error( "Multiple gamemode addons detected!" );
				}
				gameModeRegistered = true;
			}
			addon.Register();
		} );

		_addons_loaded = true;
	}
}
