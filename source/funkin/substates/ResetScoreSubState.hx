package funkin.substates;

import funkin.data.WeekData;
import funkin.data.objects.HealthIcon;

import funkin.play.Highscore;
import funkin.play.Difficulty;

import funkin.utils.Paths;
import flixel.FlxSubState;

class ResetScoreSubState extends MusicBeatSubstate
{
	var bg:FlxSprite;
	var alphabetArray:Array<Alphabet> = [];
	var icon:HealthIcon;
	var onYes:Bool = false;
	var yesText:Alphabet;
	var noText:Alphabet;

	var song:String;
	var difficulty:Int;
	var week:Int;
	var freeplay:Bool;
	var character:String;

	public function new(song:String, difficulty:Int, character:String, week:Int = -1, ?freeplay:Bool = false)
	{
		super();
		this.song = song != null ? song : '';
		this.difficulty = difficulty;
		this.week = week;
		this.freeplay = freeplay == true;
		this.character = character != null ? character : 'face';

		var name:String = this.song;
		if (week > -1)
		{
			try
			{
				if (WeekData.weeksList != null && week < WeekData.weeksList.length)
				{
					var weekKey:String = WeekData.weeksList[week];
					var weekData:WeekData = WeekData.weeksLoaded != null ? WeekData.weeksLoaded.get(weekKey) : null;
					if (weekData != null && weekData.weekName != null && weekData.weekName.length > 0)
						name = weekData.weekName;
					else if (weekKey != null)
						name = weekKey;
				}
			}
			catch (e:Dynamic) {}
		}

		var diffLabel:String = '';
		try { diffLabel = Difficulty.getString(difficulty); } catch (e:Dynamic) { diffLabel = Std.string(difficulty); }
		if (diffLabel == null) diffLabel = '';
		name += ' (' + diffLabel + ')?';

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var tooLong:Float = (name.length > 18) ? 0.8 : 1;
		var text:Alphabet = new Alphabet(0, 180, Language.getPhrase('reset_score', 'Reset the score of'), true);
		text.screenCenter(X);
		alphabetArray.push(text);
		text.alpha = 0;
		add(text);
		var text2:Alphabet = new Alphabet(0, text.y + 90, name, true);
		text2.scaleX = tooLong;
		text2.screenCenter(X);
		if (week == -1) text2.x += 60 * tooLong;
		alphabetArray.push(text2);
		text2.alpha = 0;
		add(text2);
		if (week == -1)
		{
			try
			{
				icon = new HealthIcon(this.character);
				icon.setGraphicSize(Std.int(icon.width * tooLong));
				icon.updateHitbox();
				icon.setPosition(text2.x - icon.width + (10 * tooLong), text2.y - 30);
				icon.alpha = 0;
				add(icon);
			}
			catch (e:Dynamic)
			{
				icon = null;
			}
		}

		yesText = new Alphabet(0, text2.y + 150, Language.getPhrase('Yes'), true);
		yesText.screenCenter(X);
		yesText.x -= 200;
		add(yesText);

		noText = new Alphabet(0, text2.y + 150, Language.getPhrase('No'), true);
		noText.screenCenter(X);
		noText.x += 200;
		add(noText);

		if (yesText.letters != null)
		{
			for (letter in yesText.letters)
				if (letter != null) letter.color = FlxColor.RED;
		}
		updateOptions();
	}

	override function update(elapsed:Float)
	{
		bg.alpha += elapsed * 1.5;
		if (bg.alpha > 0.6) bg.alpha = 0.6;

		for (i in 0...alphabetArray.length)
		{
			var spr = alphabetArray[i];
			if (spr != null)
				spr.alpha += elapsed * 2.5;
		}
		if (week == -1 && icon != null)
			icon.alpha += elapsed * 2.5;

		if (controls == null)
		{
			super.update(elapsed);
			return;
		}

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			try { FlxG.sound.play(Paths.sound('scrollMenu'), 1); } catch (e:Dynamic) {}
			onYes = !onYes;
			updateOptions();
		}
		if (controls.BACK)
		{
			try { FlxG.sound.play(Paths.sound('cancelMenu'), 1); } catch (e:Dynamic) {}
			close();
		}
		else if (controls.ACCEPT)
		{
			if (onYes)
			{
				try
				{
					if (freeplay)
					{
						var weekData:WeekData = null;
						if (week >= 0 && WeekData.weeksList != null && week < WeekData.weeksList.length)
							weekData = WeekData.weeksLoaded.get(WeekData.weeksList[week]);
						Highscore.resetSong(song, difficulty, null, weekData, true);
					}
					else if (week == -1)
					{
						Highscore.resetSong(song, difficulty);
					}
					else if (WeekData.weeksList != null && week >= 0 && week < WeekData.weeksList.length)
					{
						Highscore.resetWeek(WeekData.weeksList[week], difficulty);
					}
				}
				catch (e:Dynamic)
				{
					trace('[ResetScoreSubState] reset failed: ' + e);
				}
			}
			try { FlxG.sound.play(Paths.sound('cancelMenu'), 1); } catch (e:Dynamic) {}
			close();
		}
		super.update(elapsed);
	}

	function updateOptions()
	{
		var scales:Array<Float> = [0.75, 1];
		var alphas:Array<Float> = [0.6, 1.25];
		var confirmInt:Int = onYes ? 1 : 0;

		if (yesText != null)
		{
			yesText.alpha = alphas[confirmInt];
			yesText.scale.set(scales[confirmInt], scales[confirmInt]);
		}
		if (noText != null)
		{
			noText.alpha = alphas[1 - confirmInt];
			noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
		}
		if (week == -1 && icon != null && icon.animation != null && icon.animation.curAnim != null)
			icon.animation.curAnim.curFrame = confirmInt;
	}
}
