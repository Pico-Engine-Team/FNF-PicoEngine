package funkin.substates;

import funkin.states.TitleMenuState;
import funkin.states.menus.MainMenuState;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class OutdatedSubState extends MusicBeatSubstate
{
	var leftState:Bool = false;
	var bg:FlxSprite;
	var warnText:FlxText;

	public static var updateVersion:String = '';

	override function create()
	{
		super.create();

		try
		{
			updateVersion = CoolUtil.checkForUpdates();
		}
		catch (e:Dynamic)
		{
			updateVersion = '';
		}
		if (updateVersion == null) updateVersion = '';

		var currentVersion:String = '';
		try
		{
			currentVersion = MainMenuState.PicoVersion;
		}
		catch (e:Dynamic)
		{
			try { currentVersion = MainMenuState.psychEngineVersion; } catch (e2:Dynamic) { currentVersion = 'unknown'; }
		}
		if (currentVersion == null) currentVersion = 'unknown';

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.alpha = 0.0;
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width,
			'Sup bro, looks like you\'re running an outdated version of\nPico Engine (' + currentVersion + ')\n
			-----------------------------------------------\n
			Press ENTER to update to the latest version ' + updateVersion + '\n
			Press ESCAPE to proceed anyway.\n
			You can disable this warning by unchecking the
			"Check for Updates" setting in the Options Menu\n
			-----------------------------------------------\n
			Thank you for using the Engine!',
			32);
		try
		{
			warnText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		}
		catch (e:Dynamic)
		{
			warnText.setFormat(null, 32, FlxColor.WHITE, CENTER);
		}
		warnText.scrollFactor.set();
		warnText.screenCenter(Y);
		warnText.alpha = 0.0;
		add(warnText);

		FlxTween.tween(bg, { alpha: 0.8 }, 0.6, { ease: FlxEase.sineIn });
		FlxTween.tween(warnText, { alpha: 1.0 }, 0.6, { ease: FlxEase.sineIn });
	}

	override function update(elapsed:Float)
	{
		if (!leftState && controls != null)
		{
			if (controls.ACCEPT)
			{
				leftState = true;
				try
				{
					CoolUtil.browserLoad("https://github.com/Pico-Engine-Team/FNF-Pico-Engine/releases");
				}
				catch (e:Dynamic) {}
			}
			else if (controls.BACK)
			{
				leftState = true;
			}

			if (leftState)
			{
				try { FlxG.sound.play(Paths.sound('cancelMenu')); } catch (e:Dynamic) {}
				FlxTween.tween(bg, { alpha: 0.0 }, 0.9, { ease: FlxEase.sineOut });
				FlxTween.tween(warnText, {alpha: 0}, 1, {
					ease: FlxEase.sineOut,
					onComplete: function (twn:FlxTween) {
						FlxG.state.persistentUpdate = true;
						close();
					}
				});
			}
		}
		super.update(elapsed);
	}
}
