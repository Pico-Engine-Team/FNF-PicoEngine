package funkin.data.cutscenes;

import funkin.states.PauseMenuState;
import flixel.FlxBasic;
import flixel.util.FlxSort;

typedef CutsceneEvent = {
	var time:Float;
	var func:Void->Void;
}

class CutsceneHandler extends FlxBasic
{
	public var timedEvents:Array<CutsceneEvent> = [];
	public var skipCallback:Void->Void = null;
	public var onStart:Void->Void = null;
	public var endTime:Float = 0;
	public var objects:Array<FlxSprite> = [];
	public var music:String = null;

	var musicObj:FlxSound = null;
	var pauseJustClosed:Bool = false;
	var pausedSounds:Array<FlxSound> = [];
	var disposed:Bool = false;

	final _timeToSkip:Float = 1;
	var _canSkip:Bool = false;
	public var holdingTime:Float = 0;
	public var finishCallback:Void->Void = null;

	public function new(canSkip:Bool = true)
	{
		super();

		timer(0, function()
		{
			if (disposed) return;
			if (music != null && music.length > 0)
			{
				try
				{
					FlxG.sound.playMusic(Paths.music(music), 0, false);
					musicObj = FlxG.sound.music;
					if (FlxG.sound.music != null)
						FlxG.sound.music.fadeIn();
				}
				catch (e:Dynamic)
				{
					trace('[CutsceneHandler] Failed to play music "$music": ' + e);
				}
			}
			if (onStart != null) onStart();
		});

		if (FlxG.state != null)
			FlxG.state.add(this);

		this._canSkip = canSkip;
	}

	private var cutsceneTime:Float = 0;
	private var firstFrame:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (disposed) return;

		// Skip first frame / leave if no longer on PlayState
		if (PlayState.instance == null || FlxG.state != PlayState.instance || !firstFrame)
		{
			firstFrame = true;
			return;
		}

		cutsceneTime += elapsed;

		// Fire timed events in order
		while (timedEvents != null && timedEvents.length > 0 && timedEvents[0] != null && timedEvents[0].time <= cutsceneTime)
		{
			var ev = timedEvents.shift();
			if (ev != null && ev.func != null)
			{
				try ev.func() catch (e:Dynamic) trace('[CutsceneHandler] timedEvent error: ' + e);
			}
		}

		// Pause → open PauseMenuState (CUTSCENE)
		// Parentheses required so (pause || BACK) is evaluated before && !pauseJustClosed
		if (_canSkip && cutsceneTime > 0.1 && !pauseJustClosed)
		{
			var pressedPause:Bool = false;
			try
			{
				if (Controls.instance != null)
					pressedPause = Controls.instance.pressed('pause');
			}
			catch (e:Dynamic) {}
			#if android
			try
			{
				if (FlxG.android != null && FlxG.android.justReleased.BACK)
					pressedPause = true;
			}
			catch (e:Dynamic) {}
			#end

			if (pressedPause)
			{
				var game = PlayState.instance;
				if (game == null) return;

				FlxG.camera.followLerp = 0;
				FlxG.state.persistentUpdate = false;
				FlxG.state.persistentDraw = true;

				// Pause music once (not inside the sound list loop)
				if (musicObj != null)
				{
					try musicObj.pause() catch (e:Dynamic) {}
				}

				pausedSounds = [];
				if (FlxG.sound != null && FlxG.sound.list != null)
				{
					FlxG.sound.list.forEach(function(s:FlxSound)
					{
						if (s != null && s.playing)
						{
							try
							{
								s.pause();
								pausedSounds.push(s);
							}
							catch (e:Dynamic) {}
						}
					});
				}

				if (FlxTween.globalManager != null)
					FlxTween.globalManager.forEach(function(t) if (t != null) t.active = false);

				var pauseState = new PauseMenuState(true, CUTSCENE);
				pauseState.cutsceneAllowSkipping = _canSkip;
				game.openSubState(pauseState);

				game.subStateClosed.addOnce(function(_)
				{
					pauseJustClosed = true;
					new FlxTimer().start(0.1, function(__) pauseJustClosed = false);

					switch (pauseState.specialAction)
					{
						case SKIP:
							trace('[CutsceneHandler] skipped cutscene');
							if (skipCallback != null)
							{
								try skipCallback() catch (e:Dynamic) {}
							}
							disposeCutscene();
						case RESUME:
							for (s in pausedSounds)
							{
								if (s != null)
								{
									try s.resume() catch (e:Dynamic) {}
								}
							}
							if (musicObj != null)
							{
								try musicObj.resume() catch (e:Dynamic) {}
							}
							pausedSounds = [];
							if (FlxTween.globalManager != null)
								FlxTween.globalManager.forEach(function(t) if (t != null) t.active = true);
						case NOTHING:
						case RESTART:
					}
				});

				#if DISCORD_ALLOWED
				try
				{
					@:privateAccess
					if (game.autoUpdateRPC)
					{
						var songLabel:String = (PlayState.SONG != null && PlayState.SONG.song != null) ? PlayState.SONG.song : 'Cutscene';
						var diffLabel:String = (game.storyDifficultyText != null) ? game.storyDifficultyText : '';
						var iconName:String = '';
						try
						{
							if (game.iconP2 != null)
								iconName = game.iconP2.getCharacter();
						}
						catch (e:Dynamic) {}
						DiscordClient.changePresence('Cutscene paused', songLabel + (diffLabel.length > 0 ? ' (' + diffLabel + ')' : ''), iconName);
					}
				}
				catch (e:Dynamic) {}
				#end
			}
		}

		// End of cutscene
		if (endTime > 0 && endTime <= cutsceneTime)
		{
			if (finishCallback != null)
			{
				try finishCallback() catch (e:Dynamic) trace('[CutsceneHandler] finishCallback error: ' + e);
			}
			disposeCutscene();
		}
	}

	function disposeCutscene()
	{
		if (disposed) return;
		disposed = true;

		if (objects != null)
		{
			for (spr in objects)
			{
				if (spr == null) continue;
				try
				{
					spr.kill();
					if (PlayState.instance != null)
						PlayState.instance.remove(spr);
					spr.destroy();
				}
				catch (e:Dynamic) {}
			}
			objects = [];
		}

		timedEvents = [];
		pausedSounds = [];
		finishCallback = null;
		skipCallback = null;
		onStart = null;

		try destroy() catch (e:Dynamic) {}

		if (PlayState.instance != null)
		{
			try PlayState.instance.remove(this) catch (e:Dynamic) {}
		}
		else if (FlxG.state != null)
		{
			try FlxG.state.remove(this) catch (e:Dynamic) {}
		}
	}

	public function push(spr:FlxSprite)
	{
		if (spr == null) return;
		if (objects == null) objects = [];
		objects.push(spr);
	}

	public function timer(time:Float, func:Void->Void)
	{
		if (func == null) return;
		if (timedEvents == null) timedEvents = [];
		timedEvents.push({time: time, func: func});
		timedEvents.sort(sortByTime);
	}

	function sortByTime(Obj1:CutsceneEvent, Obj2:CutsceneEvent):Int
	{
		if (Obj1 == null && Obj2 == null) return 0;
		if (Obj1 == null) return 1;
		if (Obj2 == null) return -1;
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.time, Obj2.time);
	}
}
