package funkin.data.cutscenes;

import funkin.states.PauseMenuState;
import flixel.addons.display.FlxPieDial;

#if hxvlc
import hxvlc.flixel.FlxVideoSprite;
#end
#if hxCodec
import hxcodec.flixel.FlxVideoSprite;
#end
#if html5
import objects.WebVideoSprite as FlxVideoSprite;
#end

class VideoSprite extends FlxSpriteGroup
{
	#if VIDEOS_ALLOWED

	public var finishCallback:Void->Void = null;
	public var onSkip:Void->Void = null;

	final _timeToSkip:Float = 1;
	public var holdingTime:Float = 0;
	public var videoSprite:FlxVideoSprite;
	public var cover:FlxSprite;
	public var canSkip:Bool = false;

	public var waiting:Bool = false;
	public var didPlay:Bool = false;

	private var videoName:String;
	private var doWeLoop:Bool = false; // for hxCodec

	var pauseJustClosed:Bool = false;
	var alreadyDestroyed:Bool = false;

	public function new(videoName:String, isWaiting:Bool, canSkip:Bool = false, shouldLoop:Dynamic = false)
	{
		super();

		this.doWeLoop = shouldLoop == true;
		this.videoName = videoName != null ? videoName : '';
		scrollFactor.set();

		if (FlxG.cameras != null && FlxG.cameras.list != null && FlxG.cameras.list.length > 0)
			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		waiting = isWaiting;
		if (!waiting)
		{
			cover = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			cover.scale.set(FlxG.width + 100, FlxG.height + 100);
			cover.screenCenter();
			cover.scrollFactor.set();
			add(cover);
		}

		// initialize video sprite
		videoSprite = new FlxVideoSprite();
		try
		{
			if (Preferences.data != null)
				videoSprite.antialiasing = Preferences.data.antialiasing;
		}
		catch (e:Dynamic) {}
		add(videoSprite);
		this.canSkip = canSkip;

		// end / format callbacks
		#if web
		if (!this.doWeLoop)
			videoSprite.finishCallback = finishVideo;
		#else
		if (!this.doWeLoop && videoSprite.bitmap != null)
			videoSprite.bitmap.onEndReached.add(finishVideo);

		#if hxvlc
		if (videoSprite.bitmap != null)
		{
			videoSprite.bitmap.onFormatSetup.add(function()
			{
				if (videoSprite == null) return;
				videoSprite.setGraphicSize(FlxG.initialWidth);
				videoSprite.updateHitbox();
				videoSprite.screenCenter();
			});
		}
		videoSprite.load(this.videoName, this.doWeLoop ? ['input-repeat=65545'] : null);
		#else
		if (videoSprite.bitmap != null)
		{
			videoSprite.bitmap.onTextureSetup.add(function()
			{
				if (videoSprite == null) return;
				videoSprite.setGraphicSize(FlxG.initialWidth);
				videoSprite.updateHitbox();
				videoSprite.screenCenter();
			});
		}
		#end
		#end
	}

	override function destroy()
	{
		if (alreadyDestroyed)
			return;
		alreadyDestroyed = true;

		trace('[VideoSprite] destroyed');
		if (cover != null)
		{
			try
			{
				remove(cover);
				cover.destroy();
			}
			catch (e:Dynamic) {}
			cover = null;
		}

		finishCallback = null;
		onSkip = null;

		if (FlxG.state != null)
		{
			try
			{
				if (FlxG.state.members != null && FlxG.state.members.contains(this))
					FlxG.state.remove(this);
			}
			catch (e:Dynamic) {}

			try
			{
				if (FlxG.state.subState != null && FlxG.state.subState.members != null && FlxG.state.subState.members.contains(this))
					FlxG.state.subState.remove(this);
			}
			catch (e:Dynamic) {}
		}

		super.destroy();
	}

	override function update(elapsed:Float)
	{
		// Parentheses required: (pause || BACK) && !pauseJustClosed && PlayState alive
		if (!alreadyDestroyed && !pauseJustClosed && PlayState.instance != null)
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
				if (game != null)
				{
					FlxG.camera.followLerp = 0;
					FlxG.state.persistentUpdate = false;
					FlxG.state.persistentDraw = true;
					pause();
					game.paused = true;

					var pauseState = new PauseMenuState(true, VIDEO);
					pauseState.cutsceneAllowSkipping = canSkip;
					pauseState.cutsceneHardReset = false;
					pauseJustClosed = true; // prevent double-pausing
					game.openSubState(pauseState);

					game.subStateClosed.addOnce(function(_)
					{
						switch (pauseState.specialAction)
						{
							case SKIP:
								trace('[VideoSprite] Skip Video');
								if (onSkip != null)
								{
									try onSkip() catch (e:Dynamic) {}
								}
								#if web
								try
								{
									if (videoSprite != null)
										videoSprite.finishVideo();
								}
								catch (e:Dynamic) {}
								#else
								try
								{
									if (videoSprite != null && videoSprite.bitmap != null && videoSprite.bitmap.onEndReached != null)
										videoSprite.bitmap.onEndReached.dispatch();
								}
								catch (e:Dynamic)
								{
									// Fallback: just finish
									finishVideo();
								}
								#end
								if (PlayState.instance != null)
								{
									try PlayState.instance.remove(this) catch (e:Dynamic) {}
								}
							case RESUME:
								resume();
								new FlxTimer().start(0.4, function(__) pauseJustClosed = false);
							case NOTHING:
								finishCallback = null;
							case RESTART:
								#if web
								try
								{
									if (videoSprite != null)
										videoSprite.restartVideo();
								}
								catch (e:Dynamic) {}
								#else
								try
								{
									if (videoSprite != null && videoSprite.bitmap != null)
										videoSprite.bitmap.time = 0;
								}
								catch (e:Dynamic) {}
								#end
								resume();
								new FlxTimer().start(0.4, function(__) pauseJustClosed = false);
						}
					});
				}
			}
		}

		super.update(elapsed);
	}

	function finishVideo()
	{
		if (alreadyDestroyed) return;
		if (finishCallback != null)
		{
			try finishCallback() catch (e:Dynamic) {}
		}
		destroy();
	}

	public function resume()
	{
		if (videoSprite != null)
		{
			try videoSprite.resume() catch (e:Dynamic) {}
		}
	}

	public function pause()
	{
		if (videoSprite != null)
		{
			try videoSprite.pause() catch (e:Dynamic) {}
		}
	}

	public function setSpeed(playbackRate:Float)
	{
		if (videoSprite == null) return;
		#if web
		try
		{
			if (videoSprite.netStream != null)
				videoSprite.netStream.speed = playbackRate;
		}
		catch (e:Dynamic) {}
		#else
		try
		{
			if (videoSprite.bitmap != null)
				videoSprite.bitmap.rate = playbackRate;
		}
		catch (e:Dynamic) {}
		#end
	}

	public function play()
	{
		if (videoSprite == null) return;
		didPlay = true;
		#if hxvlc
		try videoSprite.play() catch (e:Dynamic) {}
		#elseif web
		try
		{
			if (videoSprite.netStream != null)
				videoSprite.netStream.play(videoName);
		}
		catch (e:Dynamic) {}
		#else
		try videoSprite.play(videoName, doWeLoop) catch (e:Dynamic) {}
		if (FlxG.autoPause)
		{
			try
			{
				FlxG.signals.focusGained.remove(videoSprite.resume);
				FlxG.signals.focusLost.remove(videoSprite.pause);
			}
			catch (e:Dynamic) {}
		}
		#end
	}

	#end
}
