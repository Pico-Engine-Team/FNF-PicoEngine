package ffunkin.states.menus;

import funkin.states.AchievementsMenuState;
import flixel.FlxObject;
import flixel.effects.FlxFlicker;

class PlayMenuState extends MusicBeatState
{
	public static var PlayMenuVersion:String = '1.0';
	public static var curSelected:Int = 0;

	var options:Array<String> = ['story_mode', 'freeplay' #if ACHIEVEMENTS_ALLOWED, 'awards' #end];
	var cards:Array<FlxSprite> = [];
	var icons:Array<FlxSprite> = [];
	var labels:Array<FlxText> = [];
	var descriptions:Array<FlxText> = [];

	var selector:FlxText;
	var magenta:FlxSprite;
	var camFollow:FlxObject;

	var selectedSomethin:Bool = false;
	var allowMouse:Bool = true;
	var timeNotMoving:Float = 0;

	override function create()
	{
		super.create();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('In the Play Menu', null);
		#end

		persistentUpdate = persistentDraw = true;

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menus/bg/menuDesat'));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set(0.1, 0.1);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.color = 0xFF353535;
		add(magenta);

		camFollow = new FlxObject(FlxG.width * 0.5, FlxG.height * 0.5, 1, 1);
		add(camFollow);

		var title:FlxText = new FlxText(0, 56, FlxG.width, 'PLAY', 48);
		title.scrollFactor.set();
		title.setFormat(Paths.font('vcr.ttf'), 48, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(title);

		var subtitle:FlxText = new FlxText(0, 112, FlxG.width, 'Choose how you want to play', 18);
		subtitle.scrollFactor.set();
		subtitle.setFormat(Paths.font('vcr.ttf'), 18, 0xFFB8E2FF, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(subtitle);

		selector = new FlxText(146, 0, 40, '>', 34);
		selector.scrollFactor.set();
		selector.setFormat(Paths.font('vcr.ttf'), 34, 0xFF6AFF8B, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(selector);

		for (i in 0...options.length)
			createPlayItem(options[i], i);

		var versionText:FlxText = new FlxText(12, FlxG.height - 24, 0, 'Play Menu v' + PlayMenuVersion, 12);
		versionText.scrollFactor.set();
		versionText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.GREEN, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionText);

		changeItem(0, false);
		FlxG.camera.follow(camFollow, null, 0.12);
	}

	function createPlayItem(id:String, index:Int):Void
	{
		var cardX:Float = 190;
		var cardY:Float = 182 + (index * 104);
		var cardWidth:Int = 900;
		var cardHeight:Int = 82;

		var card:FlxSprite = new FlxSprite(cardX, cardY).makeGraphic(cardWidth, cardHeight, 0xCC101722);
		card.scrollFactor.set();
		cards.push(card);
		add(card);

		var accent:FlxSprite = new FlxSprite(cardX, cardY).makeGraphic(8, cardHeight, getOptionColor(id));
		accent.scrollFactor.set();
		add(accent);

		var icon:FlxSprite = new FlxSprite(cardX + 36, cardY + 12);
		icon.frames = Paths.getSparrowAtlas('menus/mainmenu/menu_$id');
		icon.animation.addByPrefix('idle', '$id idle', 24, true);
		icon.animation.addByPrefix('selected', '$id selected', 24, true);
		icon.animation.play('idle');
		icon.antialiasing = ClientPrefs.data.antialiasing;
		icon.scrollFactor.set();
		var iconScale:Float = Math.min(260 / icon.width, 58 / icon.height);
		icon.setGraphicSize(Std.int(icon.width * iconScale));
		icon.updateHitbox();
		icon.x = cardX + 180 - (icon.width * 0.5);
		icon.y = cardY + (cardHeight - icon.height) * 0.5;
		icons.push(icon);
		add(icon);

		var label:FlxText = new FlxText(cardX + 360, cardY + 14, 470, getOptionLabel(id), 26);
		label.scrollFactor.set();
		label.setFormat(Paths.font('vcr.ttf'), 26, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		labels.push(label);
		add(label);

		var desc:FlxText = new FlxText(cardX + 360, cardY + 48, 470, getOptionDescription(id), 15);
		desc.scrollFactor.set();
		desc.setFormat(Paths.font('vcr.ttf'), 15, 0xFFB8C6D8, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descriptions.push(desc);
		add(desc);
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
				changeItem(-1);
			if (controls.UI_DOWN_P)
				changeItem(1);

			var mouseActive:Bool = allowMouse && ((FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0) || FlxG.mouse.justPressed);
			if (mouseActive)
			{
				FlxG.mouse.visible = true;
				timeNotMoving = 0;

				for (i in 0...cards.length)
				{
					if (FlxG.mouse.overlaps(cards[i]))
					{
						if (curSelected != i)
						{
							curSelected = i;
							changeItem(0);
						}
						break;
					}
				}
			}
			else
			{
				timeNotMoving += elapsed;
				if (timeNotMoving > 2)
					FlxG.mouse.visible = false;
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}

			if (controls.ACCEPT || (FlxG.mouse.justPressed && FlxG.mouse.overlaps(cards[curSelected])))
				acceptSelection();

			#if desktop
			if (controls.justPressed('debug_0'))
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new funkin.states.editors.EditorsMenus());
			}
			#end
		}

		super.update(elapsed);
	}

	function acceptSelection():Void
	{
		var option:String = options[curSelected];
		selectedSomethin = true;
		FlxG.mouse.visible = false;
		FlxG.sound.play(Paths.sound('confirmMenu'));

		FlxFlicker.flicker(cards[curSelected], 1, 0.06, false, false);
		FlxFlicker.flicker(icons[curSelected], 1, 0.06, false, false, function(flick:FlxFlicker)
		{
			switch (option)
			{
				case 'story_mode':
					MusicBeatState.switchState(new StoryMenuState());
				case 'freeplay':
					MusicBeatState.switchState(new FreeplayMenuState());
				#if ACHIEVEMENTS_ALLOWED
				case 'awards':
					MusicBeatState.switchState(new AchievementsMenuState());
				#end
				default:
					selectedSomethin = false;
			}
		});

		for (i in 0...cards.length)
		{
			if (i == curSelected)
				continue;

			FlxTween.tween(cards[i], {alpha: 0}, 0.35, {ease: FlxEase.quadOut});
			FlxTween.tween(icons[i], {alpha: 0}, 0.35, {ease: FlxEase.quadOut});
			FlxTween.tween(labels[i], {alpha: 0}, 0.35, {ease: FlxEase.quadOut});
			FlxTween.tween(descriptions[i], {alpha: 0}, 0.35, {ease: FlxEase.quadOut});
		}
	}

	function changeItem(change:Int = 0, ?playSound:Bool = true):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		for (i in 0...cards.length)
		{
			var selected:Bool = i == curSelected;
			cards[i].alpha = selected ? 0.95 : 0.58;
			icons[i].alpha = selected ? 1 : 0.55;
			icons[i].animation.play(selected ? 'selected' : 'idle');
			labels[i].color = selected ? FlxColor.WHITE : 0xFFB8C6D8;
			descriptions[i].alpha = selected ? 1 : 0.65;
		}

		selector.y = cards[curSelected].y + 22;
		camFollow.y = cards[curSelected].getGraphicMidpoint().y;
	}

	function getOptionLabel(id:String):String
	{
		return switch (id)
		{
			case 'story_mode': 'Story Mode';
			case 'freeplay': 'Freeplay';
			case 'awards': 'Awards';
			default: id;
		}
	}

	function getOptionDescription(id:String):String
	{
		return switch (id)
		{
			case 'story_mode': 'Play weeks with story progress and week difficulties.';
			case 'freeplay': 'Pick any unlocked song, difficulty, or extra mix.';
			case 'awards': 'View achievements and completion progress.';
			default: '';
		}
	}

	function getOptionColor(id:String):Int
	{
		return switch (id)
		{
			case 'story_mode': 0xFFFF4D7D;
			case 'freeplay': 0xFF4DFFB8;
			case 'awards': 0xFFFFD34D;
			default: 0xFFFFFFFF;
		}
	}
}
