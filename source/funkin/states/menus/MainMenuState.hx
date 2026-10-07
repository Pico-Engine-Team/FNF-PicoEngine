package funkin.states.menus;

import funkin.states.options.OptionsMenuState;
import funkin.states.editors.EditorsMenus;
import funkin.states.achievements.AchievementsMenuState;
import funkin.utils.engines.pico.EnginePerformance;
import funkin.utils.engines.pico.AntiPiracy;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import lime.app.Application;

enum MainMenuColumn {
	LEFT;
	CENTER;
	RIGHT;
	CREDITS;
}

class MainMenuState extends MusicBeatState
{
	public static var PicoVersion:String = '2.26.8 (Pre Release)';
	public static var FunkinVersion:String = '0.8.7';
	public static var PsychVersion:String = '1.0.4';
	public static var curSelected:Int = 0;
	public static var curColumn:MainMenuColumn = CENTER;

	var allowMouse:Bool = true;
	var menuItems:FlxTypedGroup<FlxSprite>;
	var leftItem:FlxSprite;
	var rightItem:FlxSprite;

	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods' #end
	];

	var leftOption:String = #if ACHIEVEMENTS_ALLOWED 'achievements' #else null #end;
	var rightOption:String = 'options';
	/** Credits on the right side (mid), separate from bottom Options. */
	var creditsOption:String = 'credits';
	var creditsItem:FlxSprite;

	var magenta:FlxSprite;
	var camFollow:FlxObject;

	static var showOutdatedWarning:Bool = true;
	override function create()
	{
		super.create();
		try { EnginePerformance.flushPendingCleanup(); } catch(e:Dynamic) {}

		// EditorsMenus sets bgColor black — restore for main menu
		FlxG.camera.bgColor = FlxColor.BLACK;
		try { FlxG.camera.followLerp = 0.15; } catch(e:Dynamic) {}

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In Main Menu", null);
		#end

		// Anti-piracy: mod license + GameBanana/GameJolt source check
		try
		{
			if(AntiPiracy.openIfNeeded(false))
				return;
		}
		catch(e:Dynamic) { trace('[MainMenu] AntiPiracy check failed: ' + e); }

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = 0.25;
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menus/backgrounds/menuBG'));
		bg.antialiasing = Preferences.data.antialiasing;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menus/backgrounds/menuDesat'));
		magenta.antialiasing = Preferences.data.antialiasing;
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (num => option in optionShit)
		{
			var item:FlxSprite = createMenuItem(option, 0, (num * 140) + 90);
			item.y += (4 - optionShit.length) * 70; // Offsets for when you have anything other than 4 items
			item.screenCenter(X);
		}

		if (leftOption != null)
			leftItem = createMenuItem(leftOption, 60, 490);
		if (rightOption != null)
		{
			rightItem = createMenuItem(rightOption, FlxG.width - 60, 490);
			rightItem.x -= rightItem.width;
		}
		// Credits — right side (mid), matching the red-marked area on the main menu layout
		if (creditsOption != null)
		{
			creditsItem = createMenuItem(creditsOption, FlxG.width - 60, 280);
			creditsItem.x -= creditsItem.width;
		}

		#if mobile
		var mobileVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Pico Engine Mobile v" + Application.current.meta.get('version'), 12);
		mobileVer.scrollFactor.set();
		mobileVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.GREEN, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(mobileVer);
		#end

		var psychVer:FlxText = new FlxText(0, FlxG.height - 18, FlxG.width, 'Friday Night Funkin v${FunkinVersion}', 12);
		var fnfVer:FlxText = new FlxText(0, FlxG.height - 18, FlxG.width, 'v${PicoVersion}', 12);

		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		fnfVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		psychVer.scrollFactor.set();
		fnfVer.scrollFactor.set();
		add(psychVer);
		add(fnfVer);

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		#if CHECK_FOR_UPDATES
		if (showOutdatedWarning && Preferences.data.checkForUpdates && funkin.substates.OutdatedSubState.updateVersion != null && funkin.substates.OutdatedSubState.updateVersion.length > 0 && funkin.substates.OutdatedSubState.updateVersion != PicoVersion) {
			persistentUpdate = false;
			showOutdatedWarning = false;
			openSubState(new funkin.substates.OutdatedSubState());
		}
		#end

		FlxG.camera.follow(camFollow, null, 0.15);

		// Ensure a valid selection after coming back from editors
		curColumn = CENTER;
		if(curSelected < 0 || curSelected >= optionShit.length)
			curSelected = 0;
		changeItem();
	}

	function createMenuItem(name:String, x:Float, y:Float):FlxSprite
	{
		var menuItem:FlxSprite = new FlxSprite(x, y);
		var atlas = null;
		try { atlas = Paths.getSparrowAtlas('menus/menu_$name'); } catch(e:Dynamic) { atlas = null; }
		if(atlas != null)
		{
			menuItem.frames = atlas;
			menuItem.animation.addByPrefix('idle', '$name idle', 24, true);
			menuItem.animation.addByPrefix('selected', '$name selected', 24, true);
			if(menuItem.animation.exists('idle'))
				menuItem.animation.play('idle');
		}
		else
		{
			// Fallback graphic so draw never hits null frames
			menuItem.makeGraphic(150, 150, 0x33FFFFFF);
			trace('[MainMenuState] Missing atlas: menus/menu_$name');
		}
		menuItem.updateHitbox();
		menuItem.antialiasing = Preferences.data.antialiasing;
		menuItem.scrollFactor.set();
		menuItems.add(menuItem);
		return menuItem;
	}

	var selectedSomethin:Bool = false;
	var timeNotMoving:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			var allowMouse:Bool = allowMouse;
			if (allowMouse && ((FlxG.mouse.deltaScreenX != 0 && FlxG.mouse.deltaScreenY != 0) || FlxG.mouse.justPressed)) //FlxG.mouse.deltaScreenX/Y checks is more accurate than FlxG.mouse.justMoved
			{
				allowMouse = false;
				FlxG.mouse.visible = true;
				timeNotMoving = 0;

				var selectedItem:FlxSprite;
				switch(curColumn)
				{
					case CENTER:
						selectedItem = menuItems.members[curSelected];
					case LEFT:
						selectedItem = leftItem;
					case RIGHT:
						selectedItem = rightItem;
					case CREDITS:
						selectedItem = creditsItem;
				}

				if(leftItem != null && FlxG.mouse.overlaps(leftItem))
				{
					allowMouse = true;
					if(selectedItem != leftItem)
					{
						curColumn = LEFT;
						changeItem();
					}
				}
				else if(creditsItem != null && FlxG.mouse.overlaps(creditsItem))
				{
					allowMouse = true;
					if(selectedItem != creditsItem)
					{
						curColumn = CREDITS;
						changeItem();
					}
				}
				else if(rightItem != null && FlxG.mouse.overlaps(rightItem))
				{
					allowMouse = true;
					if(selectedItem != rightItem)
					{
						curColumn = RIGHT;
						changeItem();
					}
				}
				else
				{
					var dist:Float = -1;
					var distItem:Int = -1;
					for (i in 0...optionShit.length)
					{
						var memb:FlxSprite = menuItems.members[i];
						if(FlxG.mouse.overlaps(memb))
						{
							var distance:Float = Math.sqrt(Math.pow(memb.getGraphicMidpoint().x - FlxG.mouse.screenX, 2) + Math.pow(memb.getGraphicMidpoint().y - FlxG.mouse.screenY, 2));
							if (dist < 0 || distance < dist)
							{
								dist = distance;
								distItem = i;
								allowMouse = true;
							}
						}
					}

					if(distItem != -1 && selectedItem != menuItems.members[distItem])
					{
						curColumn = CENTER;
						curSelected = distItem;
						changeItem();
					}
				}
			}
			else
			{
				timeNotMoving += elapsed;
				if(timeNotMoving > 2) FlxG.mouse.visible = false;
			}

			switch(curColumn)
			{
				case CENTER:
					if(controls.UI_LEFT_P && leftOption != null)
					{
						curColumn = LEFT;
						changeItem();
					}
					else if(controls.UI_RIGHT_P)
					{
						// Prefer credits (mid-right), then options (bottom-right)
						if(creditsOption != null && creditsItem != null)
							curColumn = CREDITS;
						else if(rightOption != null)
							curColumn = RIGHT;
						changeItem();
					}
				case LEFT:
					if(controls.UI_RIGHT_P)
					{
						curColumn = CENTER;
						changeItem();
					}
				case CREDITS:
					if(controls.UI_LEFT_P)
					{
						curColumn = CENTER;
						changeItem();
					}
					else if(controls.UI_DOWN_P && rightOption != null)
					{
						curColumn = RIGHT;
						changeItem();
					}
				case RIGHT:
					if(controls.UI_LEFT_P)
					{
						curColumn = CENTER;
						changeItem();
					}
					else if(controls.UI_UP_P && creditsOption != null && creditsItem != null)
					{
						curColumn = CREDITS;
						changeItem();
					}
				}
			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleMenuState());
			}
			if (controls.ACCEPT || (FlxG.mouse.justPressed && allowMouse))
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				selectedSomethin = true;
				FlxG.mouse.visible = false;

				if (Preferences.data.flashing)
					FlxFlicker.flicker(magenta, 1.1, 0.15, false);

				var item:FlxSprite;
				var option:String;
				switch(curColumn)
				{
					case CENTER:
						option = optionShit[curSelected];
						item = menuItems.members[curSelected];

					case LEFT:
						option = leftOption;
						item = leftItem;

					case RIGHT:
						option = rightOption;
						item = rightItem;

					case CREDITS:
						option = creditsOption;
						item = creditsItem;
				}
				if(item == null || option == null)
				{
					selectedSomethin = false;
					return;
				}

				FlxFlicker.flicker(item, 1, 0.06, false, false, function(flick:FlxFlicker)
				{
					switch (option)
					{
						case 'story_mode':
							MusicBeatState.switchState(new funkin.states.menus.StoryModeMenuState());
						case 'freeplay':
							MusicBeatState.switchState(new funkin.states.menus.freeplay.FreeplayMenuState());
						#if MODS_ALLOWED
						case 'mods':
							MusicBeatState.switchState(new funkin.modding.ModsMenuState());
						#end
						#if ACHIEVEMENTS_ALLOWED
						case 'achievements':
							MusicBeatState.switchState(new funkin.states.achievements.AchievementsMenuState());
						#end
						case 'credits':
							MusicBeatState.switchState(new funkin.states.CreditsMenuState());
						case 'options':
							MusicBeatState.switchState(new funkin.states.options.OptionsMenuState());
							OptionsMenuState.onPlayState = false;
							if (PlayState.SONG != null)
							{
								PlayState.SONG.arrowSkin = null;
								PlayState.SONG.splashSkin = null;
								PlayState.stageUI = 'normal';
							}
						case 'donate':
							CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
							selectedSomethin = false;
							item.visible = true;
						default:
							trace('Menu Item ${option} doesn\'t do anything');
							selectedSomethin = false;
							item.visible = true;
					}
				});
				
				for (memb in menuItems)
				{
					if(memb == item)
						continue;

					FlxTween.tween(memb, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
				}
				for (side in [leftItem, rightItem, creditsItem])
				{
					if(side != null && side != item)
						FlxTween.tween(side, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
				}
			}
			#if desktop
			if (controls.justPressed('master_menu_Key'))
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new EditorsMenus());
			}
			#end
		}

		super.update(elapsed);
	}

	function changeItem(change:Int = 0)
	{
		if(change != 0) curColumn = CENTER;
		if(optionShit == null || optionShit.length < 1) return;
		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		for (item in menuItems)
		{
			if(item == null) continue;
			playItemAnim(item, 'idle');
		}

		var selectedItem:FlxSprite = null;
		switch(curColumn)
		{
			case CENTER:
				if(curSelected >= 0 && curSelected < menuItems.length)
					selectedItem = menuItems.members[curSelected];
			case LEFT:
				selectedItem = leftItem;
			case RIGHT:
				selectedItem = rightItem;
			case CREDITS:
				selectedItem = creditsItem;
		}
		if(selectedItem == null) return;

		if(leftItem != null && selectedItem != leftItem) playItemAnim(leftItem, 'idle');
		if(rightItem != null && selectedItem != rightItem) playItemAnim(rightItem, 'idle');
		if(creditsItem != null && selectedItem != creditsItem) playItemAnim(creditsItem, 'idle');
		playItemAnim(selectedItem, 'selected');
		selectedItem.centerOffsets();
		if(camFollow != null)
			camFollow.y = selectedItem.getGraphicMidpoint().y;
	}

	function playItemAnim(item:FlxSprite, anim:String):Void
	{
		if(item == null || item.animation == null) return;
		if(item.animation.exists(anim))
		{
			item.animation.play(anim);
			item.centerOffsets();
		}
	}
}
