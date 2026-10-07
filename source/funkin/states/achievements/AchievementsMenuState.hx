package funkin.states.achievements;

import flixel.FlxObject;
import flixel.util.FlxSort;
import funkin.data.objects.Bar;

#if ACHIEVEMENTS_ALLOWED
/**
 * Achievements menu split into pages (like Credits categories):
 *   0 = Psych Engine Achievements
 *   1 = Pico Engine Achievements
 *   2 = Default Achievements
 *
 * Classification (first match wins):
 *   - data.category / data.engine: "psych" | "pico" | "default"
 *   - id starts with "pico_" or contains "_pico_" → pico
 *   - data.mod != null (mod achievement) → default
 *   - otherwise → psych
 *
 * Controls:
 *   LEFT / RIGHT  → move selection in row
 *   UP / DOWN     → move selection by row
 *   Q / E or SHIFT+LEFT/RIGHT → change page
 *   BACK          → exit
 */
class AchievementsMenuState extends MusicBeatState
{
	public var curSelected:Int = 0;
	public var curPage:Int = 0;

	public var options:Array<Dynamic> = [];
	public var pageOptions:Array<Dynamic> = [];

	public var grpOptions:FlxSpriteGroup;
	public var nameText:FlxText;
	public var descText:FlxText;
	public var progressTxt:FlxText;
	public var progressBar:Bar;
	public var pageText:FlxText;
	public var pageHintText:FlxText;

	var camFollow:FlxObject;
	var selectionBox:FlxSprite;
	var listBox:FlxSprite;

	var MAX_PER_ROW:Int = 4;

	public static final PAGE_IDS:Array<String> = ['psych', 'pico', 'default'];
	public static final PAGE_TITLES:Array<String> = ['Psych Engine Achievements', 'Pico Engine Achievements', 'Default Achievements'];

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Achievements Menu", null);
		#end

		// Full list once
		for (achievement => data in Achievements.achievements)
		{
			var unlocked:Bool = Achievements.isUnlocked(achievement);
			if(data.hidden != true || unlocked)
			{
				var entry:Dynamic = makeAchievement(achievement, data, unlocked, data.mod);
				entry.category = resolveCategory(achievement, data);
				options.push(entry);
			}
		}
		options.sort(sortByID);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/backgrounds/menuBGBlue'));
		menuBG.antialiasing = Preferences.data.antialiasing;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.scrollFactor.set();
		add(menuBG);

		pageText = new FlxText(0, 20, FlxG.width, '', 28);
		pageText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		pageText.borderSize = 2;
		pageText.scrollFactor.set();
		add(pageText);

		pageHintText = new FlxText(0, 52, FlxG.width, 'Q / E  or  SHIFT + LEFT / RIGHT  to change page', 14);
		pageHintText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		pageHintText.borderSize = 1;
		pageHintText.scrollFactor.set();
		pageHintText.alpha = 0.85;
		add(pageHintText);

		listBox = new FlxSprite(0, 70).makeGraphic(1, 1, FlxColor.BLACK);
		listBox.alpha = 0.6;
		listBox.scrollFactor.x = 0;
		add(listBox);

		grpOptions = new FlxSpriteGroup();
		grpOptions.scrollFactor.x = 0;
		add(grpOptions);

		var bottomBox:FlxSprite = new FlxSprite(0, 570).makeGraphic(1, 1, FlxColor.BLACK);
		bottomBox.scale.set(FlxG.width, FlxG.height - bottomBox.y);
		bottomBox.updateHitbox();
		bottomBox.alpha = 0.6;
		bottomBox.scrollFactor.set();
		add(bottomBox);

		nameText = new FlxText(50, bottomBox.y + 10, FlxG.width - 100, "", 32);
		nameText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		nameText.scrollFactor.set();

		descText = new FlxText(50, nameText.y + 38, FlxG.width - 100, "", 24);
		descText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();

		progressBar = new Bar(0, descText.y + 52);
		progressBar.screenCenter(X);
		progressBar.scrollFactor.set();
		progressBar.enabled = false;

		progressTxt = new FlxText(50, progressBar.y - 6, FlxG.width - 100, "", 32);
		progressTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		progressTxt.scrollFactor.set();
		progressTxt.borderSize = 2;

		add(progressBar);
		add(progressTxt);
		add(descText);
		add(nameText);

		rebuildPage(0);
		super.create();

		FlxG.camera.follow(camFollow, null, 0.15);
		FlxG.camera.scroll.y = -FlxG.height;
	}

	function resolveCategory(id:String, data:Dynamic):String
	{
		var raw:String = null;
		if(data != null)
		{
			if(Reflect.hasField(data, 'category') && Reflect.field(data, 'category') != null)
				raw = Std.string(Reflect.field(data, 'category'));
			else if(Reflect.hasField(data, 'engine') && Reflect.field(data, 'engine') != null)
				raw = Std.string(Reflect.field(data, 'engine'));
		}

		if(raw != null)
		{
			raw = raw.trim().toLowerCase();
			if(raw.indexOf('pico') >= 0) return 'pico';
			if(raw.indexOf('psych') >= 0) return 'psych';
			if(raw.indexOf('default') >= 0 || raw.indexOf('base') >= 0 || raw.indexOf('mod') >= 0)
				return 'default';
		}

		var key:String = id != null ? id.toLowerCase() : '';
		if(key.startsWith('pico_') || key.indexOf('_pico_') >= 0 || key.startsWith('picoengine'))
			return 'pico';

		// Mod-loaded achievements → Default page
		if(data != null && data.mod != null && Std.string(data.mod).trim().length > 0)
			return 'default';

		return 'psych';
	}

	function getPageAchievements(pageIndex:Int):Array<Dynamic>
	{
		var cat:String = PAGE_IDS[FlxMath.wrap(pageIndex, 0, PAGE_IDS.length - 1)];
		var list:Array<Dynamic> = [];
		for (opt in options)
		{
			if(opt.category == cat)
				list.push(opt);
		}
		return list;
	}

	function rebuildPage(pageIndex:Int):Void
	{
		curPage = FlxMath.wrap(pageIndex, 0, PAGE_IDS.length - 1);
		pageOptions = getPageAchievements(curPage);
		curSelected = 0;

		pageText.text = '<  ' + PAGE_TITLES[curPage] + '  >';
		if(pageOptions.length < 1)
			pageText.text += '  (empty)';

		while(grpOptions.members.length > 0)
		{
			var spr:FlxSprite = grpOptions.members[0];
			grpOptions.remove(spr, true);
			spr.destroy();
		}

		#if MODS_ALLOWED
		var prevMod:String = Mods.currentModDirectory;
		#end

		for (i in 0...pageOptions.length)
		{
			var option:Dynamic = pageOptions[i];
			var hasAntialias:Bool = Preferences.data.antialiasing;
			var graphic = null;

			if(option.unlocked)
			{
				#if MODS_ALLOWED Mods.currentModDirectory = option.mod; #end
				var image:String = 'achievements/' + option.name;
				if(Paths.fileExists('images/$image-pixel.png', IMAGE))
				{
					graphic = Paths.image('$image-pixel');
					hasAntialias = false;
				}
				else graphic = Paths.image(image);

				if(graphic == null) graphic = Paths.image('unknownMod');
			}
			else graphic = Paths.image('achievements/lockedachievement');

			var spr:FlxSprite = new FlxSprite(0, Math.floor(i / MAX_PER_ROW) * 180).loadGraphic(graphic);
			spr.scrollFactor.x = 0;
			spr.screenCenter(X);
			spr.x += 180 * ((i % MAX_PER_ROW) - MAX_PER_ROW / 2) + spr.width / 2 + 15;
			spr.y += 90;
			spr.ID = i;
			spr.antialiasing = hasAntialias;
			grpOptions.add(spr);
		}

		#if MODS_ALLOWED
		Mods.currentModDirectory = prevMod;
		if(Mods.currentModDirectory == null || Mods.currentModDirectory.length < 1)
			Mods.loadTopMod();
		#end

		if(grpOptions.members.length > 0)
		{
			listBox.scale.set(Math.max(grpOptions.width + 60, 200), Math.max(grpOptions.height + 60, 120));
			listBox.updateHitbox();
			listBox.screenCenter(X);
			listBox.y = 70;
		}
		else
		{
			listBox.scale.set(400, 120);
			listBox.updateHitbox();
			listBox.screenCenter(X);
			listBox.y = 70;
		}

		_changeSelection();
	}

	function changePage(delta:Int):Void
	{
		if(PAGE_IDS.length < 2) return;
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		rebuildPage(curPage + delta);
	}

	function makeAchievement(achievement:String, data:Achievement, unlocked:Bool, mod:String = null):Dynamic
	{
		return {
			name: achievement,
			displayName: unlocked ? Language.getPhrase('achievement_$achievement', data.name) : '???',
			description: Language.getPhrase('description_$achievement', data.description),
			curProgress: data.maxScore > 0 ? Achievements.getScore(achievement) : 0,
			maxProgress: data.maxScore > 0 ? data.maxScore : 0,
			decProgress: data.maxScore > 0 ? data.maxDecimals : 0,
			unlocked: unlocked,
			ID: data.ID,
			mod: mod,
			category: 'psych'
		};
	}

	public static function sortByID(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.ID, Obj2.ID);

	var goingBack:Bool = false;
	override function update(elapsed:Float)
	{
		if(!goingBack)
		{
			// Page switch
			if(FlxG.keys.justPressed.Q || (FlxG.keys.pressed.SHIFT && controls.UI_LEFT_P))
				changePage(-1);
			else if(FlxG.keys.justPressed.E || (FlxG.keys.pressed.SHIFT && controls.UI_RIGHT_P))
				changePage(1);

			if(pageOptions.length > 1)
			{
				var add:Int = 0;
				if(controls.UI_LEFT_P && !FlxG.keys.pressed.SHIFT) add = -1;
				else if(controls.UI_RIGHT_P && !FlxG.keys.pressed.SHIFT) add = 1;

				if(add != 0)
				{
					var oldRow:Int = Math.floor(curSelected / MAX_PER_ROW);
					var rowSize:Int = Std.int(Math.min(MAX_PER_ROW, pageOptions.length - oldRow * MAX_PER_ROW));

					curSelected += add;
					var curRow:Int = Math.floor(curSelected / MAX_PER_ROW);
					if(curSelected >= pageOptions.length) curRow++;

					if(curRow != oldRow)
					{
						if(curRow < oldRow) curSelected += rowSize;
						else curSelected -= rowSize;
					}
					_changeSelection();
				}

				if(pageOptions.length > MAX_PER_ROW)
				{
					var rowAdd:Int = 0;
					if(controls.UI_UP_P) rowAdd = -1;
					else if(controls.UI_DOWN_P) rowAdd = 1;

					if(rowAdd != 0)
					{
						var next:Int = curSelected + rowAdd * MAX_PER_ROW;
						if(next >= 0 && next < pageOptions.length)
						{
							curSelected = next;
							_changeSelection();
						}
					}
				}
			}
			else if(pageOptions.length == 1 && (controls.UI_LEFT_P || controls.UI_RIGHT_P || controls.UI_UP_P || controls.UI_DOWN_P))
			{
				// stay on 0
			}
		}

		if(controls.BACK)
		{
			goingBack = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}

	function _changeSelection()
	{
		if(pageOptions.length < 1)
		{
			nameText.text = 'No achievements in this category';
			descText.text = 'Switch page with Q / E';
			progressBar.visible = false;
			progressTxt.visible = false;
			camFollow.setPosition(FlxG.width / 2, 200);
			return;
		}

		curSelected = FlxMath.wrap(curSelected, 0, pageOptions.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var option:Dynamic = pageOptions[curSelected];
		nameText.text = option.displayName;
		descText.text = option.description;

		if(option.maxProgress > 0)
		{
			progressTxt.text = FlxStringUtil.formatMoney(option.curProgress, false) + ' / ' + FlxStringUtil.formatMoney(option.maxProgress, false);
			progressBar.visible = true;
			progressTxt.visible = true;
			progressBar.percent = Math.min(1, option.curProgress / option.maxProgress) * 100;
		}
		else
		{
			progressBar.visible = false;
			progressTxt.visible = false;
		}

		for (num => spr in grpOptions.members)
		{
			spr.alpha = (num == curSelected) ? 1 : 0.6;
			if(num == curSelected)
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
		}
	}
}
#else
class AchievementsMenuState extends MusicBeatState
{
	override function create()
	{
		super.create();
		MusicBeatState.switchState(new MainMenuState());
	}
}
#end
