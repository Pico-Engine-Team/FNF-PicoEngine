#if LUA_ALLOWED
package funkin.modding.scripting.psychlua;

class CallbackHandler
{
	public static inline function call(l:State, fname:String):Int
	{
		try
		{
			var cbf:Dynamic = Lua_helper.callbacks.get(fname);

			// Local functions have the lowest priority
			if (cbf == null)
			{
				var last:FunkinLuaProgramming = FunkinLuaProgramming.lastCalledScript;
				if (last == null || last.lua != l)
				{
					if (PlayState.instance != null && PlayState.instance.luaArray != null)
					{
						for (script in PlayState.instance.luaArray)
						{
							if (script != FunkinLuaProgramming.lastCalledScript && script != null && script.lua == l && script.callbacks != null)
							{
								cbf = script.callbacks.get(fname);
								break;
							}
						}
					}
				}
				else if (last.callbacks != null)
				{
					cbf = last.callbacks.get(fname);
				}
			}

			if (cbf == null) return 0;

			var nparams:Int = Lua.gettop(l);
			var args:Array<Dynamic> = [];

			for (i in 0...nparams)
			{
				args[i] = Convert.fromLua(l, i + 1);
			}

			var ret:Dynamic = Reflect.callMethod(null, cbf, args);

			if (ret != null)
			{
				Convert.toLua(l, ret);
				return 1;
			}
		}
		catch (e:haxe.Exception)
		{
			if (Lua_helper.sendErrorsToLua)
			{
				LuaL.error(l, 'CALLBACK ERROR! ${e.details()}');
				return 0;
			}
			throw e;
		}
		return 0;
	}
}
#end
