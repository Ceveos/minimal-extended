using System;
using System.Collections.Generic;
using MinimalExtended;
using Sandbox;

namespace SandboxGame
{
  [Library( "sandbox-info" )]
  public class AddonInfo : IAddonInfo
  {
    public string Name => "Sandbox";

    public string Description => "Sample playground gamemode";

    public string Author => "Garry";

    public double Version => 1.0;

    public List<AddonDependency> Dependencies => new()
    {
      new AddonDependency()
      {
        Name = "Logger",
        MinVersion = 1.0
      }
    };
    public Dictionary<string, string> Metadata => new();
    public Type MainClass => typeof( SandboxGame );
    public static IAddonInfo Instance => new AddonInfo();
  }
}