using System;

using Sandbox;

namespace AddonLogger
{

  /// <summary>
  /// Addon-friendly logging utility
  /// </summary>
  public static partial class LoggerExtension
  {
    public static void LogTrace(this Entity entity, params object[] args)
    {
      Log.Trace(Logger.CraftMessage(entity.ClassInfo.Title, args));
    }
    public static void LogInfo(this Entity entity, params object[] args)
    {
      Log.Info(Logger.CraftMessage(entity.ClassInfo.Title, args));
    }
    public static void LogWarning(this Entity entity, params object[] args)
    {
      Log.Warning(Logger.CraftMessage(entity.ClassInfo.Title, args));
    }
    public static void LogWarning(this Entity entity, Exception exception, params object[] args)
    {
      Log.Warning(exception, Logger.CraftMessage(entity.ClassInfo.Title, args));
    }
    public static void LogError(this Entity entity, params object[] args)
    {
      Log.Error(Logger.CraftMessage(entity.ClassInfo.Title, args));
    }
    public static void LogError(this Entity entity, Exception exception, params object[] args)
    {
      Log.Error(exception, Logger.CraftMessage(entity.ClassInfo.Title, args));
    }
  }
}
