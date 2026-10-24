package funkin.states;

import funkin.data.WeekData;
import funkin.data.objects.CharactersData as Character;

import funkin.states.menus.StoryModeMenuState;
import funkin.states.menus.freeplay.FreeplayMenuState;

import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;

class GameOverState extends MusicBeatSubstate
{
	var camFollow:FlxObject;
	var stagePostfix:String = "";

	public var boyfriend:Character;
	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';
	public static var deathDelay:Float = 0;

	public static var instance:GameOverState;
	public function new(?playStateBoyfriend:Character = null)
	{
		if(playStateBoyfriend != null && playStateBoyfriend.curCharacter == characterName) //Avoids spawning a second boyfriend cuz animate atlas is laggy
		{
			this.boyfriend = playStateBoyfriend;
		}
		super();
	}

	public static function resetVariables()
	{
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
		deathDelay = 0;

		var playerCharacter:Character = PlayState.instance != null ? PlayState.instance.boyfriend : null;
		if(playerCharacter != null)
		{
			if(playerCharacter.gameOverChar != null && playerCharacter.gameOverChar.trim().length > 0) characterName = playerCharacter.gameOverChar;
			if(playerCharacter.gameOverSound != null && playerCharacter.gameOverSound.trim().length > 0) deathSoundName = playerCharacter.gameOverSound;
			if(playerCharacter.gameOverLoop != null && playerCharacter.gameOverLoop.trim().length > 0) loopSoundName = playerCharacter.gameOverLoop;
			if(playerCharacter.gameOverEnd != null && playerCharacter.gameOverEnd.trim().length > 0) endSoundName = playerCharacter.gameOverEnd;
		}
	}

	var charX:Float = 0;
	var charY:Float = 0;

	var overlay:FlxSprite;
	var overlayConfirmOffsets:FlxPoint = FlxPoint.get();
	override function create()
	{
		instance = this;

		Conductor.songPosition = 0;

		if(boyfriend == null)
		{
			var px:Float = 0;
			var py:Float = 0;
			var ox:Float = 0;
			var oy:Float = 0;
			if(PlayState.instance != null && PlayState.instance.boyfriend != null)
			{
				var bf = PlayState.instance.boyfriend;
				try
				{
					var sp = bf.getScreenPosition();
					px = sp.x;
					py = sp.y;
				}
				catch(e:Dynamic)
				{
					px = bf.x;
					py = bf.y;
				}
				if(bf.positionArray != null && bf.positionArray.length >= 2)
				{
					ox = bf.positionArray[0];
					oy = bf.positionArray[1];
				}
			}
			boyfriend = new Character(px, py, characterName, true);
			if(boyfriend.positionArray != null && boyfriend.positionArray.length >= 2)
			{
				boyfriend.x += boyfriend.positionArray[0] - ox;
				boyfriend.y += boyfriend.positionArray[1] - oy;
			}
		}
		boyfriend.skipDance = true;
		add(boyfriend);

		try FlxG.sound.play(Paths.sound(deathSoundName)) catch(e:Dynamic) {}
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		try boyfriend.playAnim('firstDeath') catch(e:Dynamic) {}

		camFollow = new FlxObject(0, 0, 1, 1);
		var camX:Float = boyfriend.getGraphicMidpoint().x;
		var camY:Float = boyfriend.getGraphicMidpoint().y;
		if(boyfriend.cameraPosition != null && boyfriend.cameraPosition.length >= 2)
		{
			camX += boyfriend.cameraPosition[0];
			camY += boyfriend.cameraPosition[1];
		}
		camFollow.setPosition(camX, camY);
		FlxG.camera.focusOn(new FlxPoint(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2)));
		FlxG.camera.follow(camFollow, LOCKON, 0.01);
		add(camFollow);

		if(PlayState.instance != null)
		{
			try PlayState.instance.setOnScripts('inGameOver', true) catch(e:Dynamic) {}
			try PlayState.instance.callOnScripts('onGameOverStart', []) catch(e:Dynamic) {}
		}
		// loadEmbedded requires an existing FlxSound.music — create/play safely
		try
		{
			var loopMusic = Paths.music(loopSoundName);
			if(loopMusic != null)
			{
				if(FlxG.sound.music != null)
					FlxG.sound.music.loadEmbedded(loopMusic, true);
				else
					FlxG.sound.playMusic(loopMusic, 1, true);
				if(FlxG.sound.music != null)
					FlxG.sound.music.pause();
			}
		}
		catch(e:Dynamic)
		{
			trace('[GameOver] loop music load failed: ' + e);
		}

		if(characterName == 'pico-dead')
		{
			overlay = new FlxSprite(boyfriend.x + 205, boyfriend.y - 80);
			overlay.frames = Paths.getSparrowAtlas('Pico_Death_Retry');
			overlay.animation.addByPrefix('deathLoop', 'Retry Text Loop', 24, true);
			overlay.animation.addByPrefix('deathConfirm', 'Retry Text Confirm', 24, false);
			overlay.antialiasing = Preferences.data.antialiasing;
			overlayConfirmOffsets.set(250, 200);
			overlay.visible = false;
			add(overlay);

			boyfriend.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int)
			{
				switch(name)
				{
					case 'firstDeath':
						if(frameNumber >= 36 - 1)
						{
							overlay.visible = true;
							overlay.animation.play('deathLoop');
							boyfriend.animation.callback = null;
						}
					default:
						boyfriend.animation.callback = null;
				}
			}

			if(PlayState.instance.gf != null && PlayState.instance.gf.curCharacter == 'nene')
			{
				var neneKnife:FlxSprite = new FlxSprite(boyfriend.x - 450, boyfriend.y - 250);
				neneKnife.frames = Paths.getSparrowAtlas('NeneKnifeToss');
				neneKnife.animation.addByPrefix('anim', 'knife toss', 24, false);
				neneKnife.antialiasing = Preferences.data.antialiasing;
				neneKnife.animation.finishCallback = function(_)
				{
					remove(neneKnife);
					neneKnife.destroy();
				}
				insert(0, neneKnife);
				neneKnife.animation.play('anim', true);
			}
		}

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(PlayState.instance != null)
			PlayState.instance.callOnScripts('onUpdate', [elapsed]);

		var justPlayedLoop:Bool = false;
		if (!boyfriend.isAnimationNull() && boyfriend.getAnimationName() == 'firstDeath' && boyfriend.isAnimationFinished())
		{
			boyfriend.playAnim('deathLoop');
			if(overlay != null && overlay.animation.exists('deathLoop'))
			{
				overlay.visible = true;
				overlay.animation.play('deathLoop');
			}
			justPlayedLoop = true;
		}

		if(!isEnding)
		{
			if (controls.ACCEPT)
			{
				endBullshit();
			}
			else if (controls.BACK)
			{
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
				FlxG.camera.visible = false;
				if(FlxG.sound.music != null) FlxG.sound.music.stop();
				PlayState.deathCounter = 0;
				PlayState.seenCutscene = false;
				PlayState.chartingMode = false;
	
				Mods.loadTopMod();
				if (PlayState.isStoryMode)
					MusicBeatState.switchState(new StoryModeMenuState());
				else
					MusicBeatState.switchState(new FreeplayMenuState());
	
				FlxG.sound.playMusic(Paths.music('menu/freakyMenu'));
				if(PlayState.instance != null) PlayState.instance.callOnScripts('onGameOverConfirm', [false]);
			}
			else if (justPlayedLoop)
			{
				switch(PlayState.SONG.stage)
				{
					case 'tank':
						coolStartDeath(0.2);
						
						var exclude:Array<Int> = [];
						//if(!Preferences.cursing) exclude = [1, 3, 8, 13, 17, 21];
	
						FlxG.sound.play(Paths.sound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25, exclude)), 1, false, null, true, function() {
							if(!isEnding)
							{
								FlxG.sound.music.fadeIn(0.2, 1, 4);
							}
						});

					default:
						coolStartDeath();
				}
			}
			
			if (FlxG.sound.music != null && FlxG.sound.music.playing)
			{
				Conductor.songPosition = FlxG.sound.music.time;
			}
		}
		if(PlayState.instance != null)
			PlayState.instance.callOnScripts('onUpdatePost', [elapsed]);
	}

	var isEnding:Bool = false;
	function coolStartDeath(?volume:Float = 1):Void
	{
		if(FlxG.sound.music == null) return;
		FlxG.sound.music.play(true);
		FlxG.sound.music.volume = volume;
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			if(boyfriend.hasAnimation('deathConfirm'))
				boyfriend.playAnim('deathConfirm', true);
			else if(boyfriend.hasAnimation('deathLoop'))
				boyfriend.playAnim('deathLoop', true);

			if(overlay != null && overlay.animation.exists('deathConfirm'))
			{
				overlay.visible = true;
				overlay.animation.play('deathConfirm');
				overlay.offset.set(overlayConfirmOffsets.x, overlayConfirmOffsets.y);
			}
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					MusicBeatState.resetState();
				});
			});
			if(PlayState.instance != null) PlayState.instance.callOnScripts('onGameOverConfirm', [true]);
		}
	}

	override function destroy()
	{
		instance = null;
		super.destroy();
	}
}