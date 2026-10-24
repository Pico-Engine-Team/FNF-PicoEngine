package funkin.modding;

import funkin.modding.Mods;
import funkin.states.menus.freeplay.FreeplayMenuState;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;

import openfl.display.BitmapData;
import openfl.geom.Rectangle;

/**
 * V-Slice Mods Menu
 * Layout: DISABLED (left) | ENABLED (right)
 * Title: CHOOSE YOUR MODS
 * Bottom: OPEN MOD FOLDER + DONE
 *
 * Backend: Mods.saveList / apiVersion / meta_mod (hybrid V-Slice)
 *
 * Controls:
 *   UI_UP / UI_DOWN  — navigate cards in current column
 *   UI_LEFT / UI_RIGHT — switch column focus
 *   ACCEPT / SPACE   — move selected mod to the other column
 *   BACK             — same as DONE (save + exit)
 */
class ModsMenuState extends MusicBeatState
{
	var bg:FlxSprite;
	var charArt:FlxSprite;

	var titleTxt:Alphabet;
	var subtitleTxt:FlxText;

	var disabledPanel:FlxSprite;
	var enabledPanel:FlxSprite;
	var disabledLabel:FlxText;
	var enabledLabel:FlxText;

	var disabledCards:FlxTypedGroup<ModCard>;
	var enabledCards:FlxTypedGroup<ModCard>;

	var buttonOpenFolder:PillButton;
	var buttonDone:PillButton;
	var backArrow:FlxSprite;

	var modsList:ModsList;
	var modsDirty:Bool = false;
	var waitingToRestart:Bool = false;

	/** 0 = disabled column, 1 = enabled column */
	var focusColumn:Int = 1;
	var curDisabled:Int = 0;
	var curEnabled:Int = 0;

	var startMod:String = null;
	var tipTxt:FlxText;

	public function new(startMod:String = null)
	{
		this.startMod = startMod;
		super();
	}

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		persistentUpdate = false;
		FlxG.mouse.visible = true;

		modsList = Mods.parseList();
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Mods Menu", "Choose Your Mods");
		#end

		// Background
		bg = new FlxSprite().loadGraphic(Paths.image('menus/bg/menuDesat'));
		if (bg.graphic == null)
			bg.makeGraphic(FlxG.width, FlxG.height, 0xFF2A1A40);
		bg.color = 0xFF5A3A7A;
		bg.antialiasing = antialiasingPref();
		bg.screenCenter();
		add(bg);

		// Soft character / decor on the right (optional art)
		charArt = new FlxSprite(FlxG.width - 420, 40);
		var artPath:String = Paths.image('menus/mods/modsMenuArt');
		if (artPath != null && Paths.fileExists('images/menus/mods/modsMenuArt.png', IMAGE))
		{
			charArt.loadGraphic(artPath);
			charArt.antialiasing = antialiasingPref();
			charArt.setGraphicSize(0, Std.int(FlxG.height * 0.95));
			charArt.updateHitbox();
			charArt.x = FlxG.width - charArt.width - 10;
			charArt.y = FlxG.height - charArt.height;
			charArt.alpha = 0.85;
			add(charArt);
		}
		else
		{
			charArt.visible = false;
		}

		// Back arrow
		backArrow = new FlxSprite(24, 18);
		if (Paths.fileExists('images/menus/mods/backArrow.png', IMAGE))
			backArrow.loadGraphic(Paths.image('menus/mods/backArrow'));
		else
		{
			backArrow.makeGraphic(48, 36, FlxColor.TRANSPARENT);
			// simple chevron via text fallback handled by tip
		}
		backArrow.antialiasing = antialiasingPref();
		add(backArrow);

		var backHit:FlxText = new FlxText(20, 12, 60, '<', 40);
		backHit.setFormat(Paths.font('vcr.ttf'), 40, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		backHit.borderSize = 3;
		add(backHit);

		// Title
		titleTxt = new Alphabet(0, 28, 'CHOOSE YOUR MODS', true);
		titleTxt.scaleX = titleTxt.scaleY = 0.85;
		titleTxt.screenCenter(X);
		add(titleTxt);

		subtitleTxt = new FlxText(0, 88, FlxG.width, 'DRAG PACKS ONTO THIS WINDOW TO ADD NEW STUFF', 18);
		subtitleTxt.setFormat(Paths.font('vcr.ttf'), 18, 0xFFDDDDEE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		subtitleTxt.borderSize = 1;
		add(subtitleTxt);

		// Panels
		var panelW:Int = 420;
		var panelH:Int = 420;
		var panelY:Int = 130;
		var leftX:Int = 60;
		var rightX:Int = 520;

		disabledPanel = makePanel(leftX, panelY, panelW, panelH);
		enabledPanel = makePanel(rightX, panelY, panelW, panelH);
		add(disabledPanel);
		add(enabledPanel);

		disabledLabel = makeColumnLabel(leftX, panelY + 12, panelW, 'DISABLED');
		enabledLabel = makeColumnLabel(rightX, panelY + 12, panelW, 'ENABLED');
		add(disabledLabel);
		add(enabledLabel);

		disabledCards = new FlxTypedGroup<ModCard>();
		enabledCards = new FlxTypedGroup<ModCard>();
		add(disabledCards);
		add(enabledCards);

		rebuildCards();

		// Focus start mod if provided
		if (startMod != null && startMod.length > 0)
		{
			if (modsList.enabled.contains(startMod))
			{
				focusColumn = 1;
				curEnabled = Std.int(Math.max(0, modsList.enabled.indexOf(startMod)));
			}
			else if (modsList.disabled.contains(startMod))
			{
				focusColumn = 0;
				curDisabled = Std.int(Math.max(0, modsList.disabled.indexOf(startMod)));
			}
		}

		// Bottom buttons
		buttonOpenFolder = new PillButton(80, FlxG.height - 90, 360, 56, 'OPEN MOD FOLDER', openModFolder);
		buttonDone = new PillButton(FlxG.width - 380, FlxG.height - 90, 300, 56, 'DONE', doneAndExit);
		add(buttonOpenFolder);
		add(buttonDone);

		tipTxt = new FlxText(0, FlxG.height - 28, FlxG.width,
			'SPACE / ACCEPT = move mod   |   LEFT / RIGHT = column   |   UP / DOWN = select   |   BACK = done', 14);
		tipTxt.setFormat(Paths.font('vcr.ttf'), 14, 0xFFAAAAAA, CENTER);
		add(tipTxt);

		refreshSelectionVisuals();
		super.create();
	}

	function makePanel(x:Float, y:Float, w:Int, h:Int):FlxSprite
	{
		var s = FlxSpriteUtil.drawRoundRect(
			new FlxSprite(x, y).makeGraphic(w, h, FlxColor.TRANSPARENT),
			0, 0, w, h, 18, 18, 0xFF15151C
		);
		s.alpha = 0.92;
		return s;
	}

	function makeColumnLabel(x:Float, y:Float, w:Int, text:String):FlxText
	{
		var t = new FlxText(x, y, w, text, 22);
		t.setFormat(Paths.font('vcr.ttf'), 22, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		t.borderSize = 2;
		return t;
	}

	function antialiasingPref():Bool
	{
		try
		{
			#if (Preferences)
			return Preferences.data.antialiasing;
			#else
			return ClientPrefs.data.antialiasing;
			#end
		}
		catch (e:Dynamic)
		{
			try return ClientPrefs.data.antialiasing catch (e2:Dynamic) return true;
		}
	}

	function rebuildCards():Void
	{
		disabledCards.clear();
		enabledCards.clear();

		var i:Int = 0;
		for (folder in modsList.disabled)
		{
			if (folder == null || folder.trim().length < 1) continue;
			var card = new ModCard(folder, false);
			card.ID = i;
			disabledCards.add(card);
			i++;
		}
		i = 0;
		for (folder in modsList.enabled)
		{
			if (folder == null || folder.trim().length < 1) continue;
			var card = new ModCard(folder, true);
			card.ID = i;
			enabledCards.add(card);
			i++;
		}

		layoutCards();
	}

	function layoutCards():Void
	{
		var startY:Float = disabledPanel.y + 52;
		var gap:Float = 8;
		var cardH:Float = 78;

		for (i in 0...disabledCards.length)
		{
			var c = disabledCards.members[i];
			if (c == null) continue;
			c.setPosition(disabledPanel.x + 12, startY + i * (cardH + gap));
			c.visible = (c.y + cardH < disabledPanel.y + disabledPanel.height - 8);
		}
		for (i in 0...enabledCards.length)
		{
			var c = enabledCards.members[i];
			if (c == null) continue;
			c.setPosition(enabledPanel.x + 12, startY + i * (cardH + gap));
			c.visible = (c.y + cardH < enabledPanel.y + enabledPanel.height - 8);
		}
	}

	function refreshSelectionVisuals():Void
	{
		for (i in 0...disabledCards.length)
		{
			var c = disabledCards.members[i];
			if (c != null) c.setSelected(focusColumn == 0 && i == curDisabled);
		}
		for (i in 0...enabledCards.length)
		{
			var c = enabledCards.members[i];
			if (c != null) c.setSelected(focusColumn == 1 && i == curEnabled);
		}

		// Tint bg toward selected mod color
		var sel = getSelectedCard();
		if (sel != null)
			FlxTween.color(bg, 0.35, bg.color, FlxColor.interpolate(0xFF5A3A7A, sel.bgColor, 0.45));
	}

	function getSelectedCard():ModCard
	{
		if (focusColumn == 0)
		{
			if (disabledCards.length < 1) return null;
			curDisabled = FlxMath.wrap(curDisabled, 0, disabledCards.length - 1);
			return disabledCards.members[curDisabled];
		}
		else
		{
			if (enabledCards.length < 1) return null;
			curEnabled = FlxMath.wrap(curEnabled, 0, enabledCards.length - 1);
			return enabledCards.members[curEnabled];
		}
	}

	function changeSelection(delta:Int):Void
	{
		if (focusColumn == 0)
		{
			if (disabledCards.length < 1) return;
			curDisabled = FlxMath.wrap(curDisabled + delta, 0, disabledCards.length - 1);
		}
		else
		{
			if (enabledCards.length < 1) return;
			curEnabled = FlxMath.wrap(curEnabled + delta, 0, enabledCards.length - 1);
		}
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
		refreshSelectionVisuals();
	}

	function switchColumn(dir:Int):Void
	{
		if (dir < 0) focusColumn = 0;
		else if (dir > 0) focusColumn = 1;
		else focusColumn = focusColumn == 0 ? 1 : 0;

		if (focusColumn == 0 && disabledCards.length < 1 && enabledCards.length > 0)
			focusColumn = 1;
		if (focusColumn == 1 && enabledCards.length < 1 && disabledCards.length > 0)
			focusColumn = 0;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		refreshSelectionVisuals();
	}

	/** Move selected card to the other column. */
	function toggleSelectedMod():Void
	{
		var card = getSelectedCard();
		if (card == null) return;
		var folder:String = card.folder;

		if (modsList.enabled.contains(folder))
		{
			// → disable
			modsList.enabled.remove(folder);
			if (!modsList.disabled.contains(folder))
				modsList.disabled.push(folder);
			focusColumn = 0;
			curDisabled = modsList.disabled.indexOf(folder);
		}
		else
		{
			// → enable
			modsList.disabled.remove(folder);
			if (!modsList.enabled.contains(folder))
				modsList.enabled.push(folder);
			// keep order in all
			focusColumn = 1;
			curEnabled = modsList.enabled.indexOf(folder);
		}

		// rebuild all order list
		syncAllOrder();
		if (card.mustRestart) waitingToRestart = true;
		modsDirty = true;

		rebuildCards();
		refreshSelectionVisuals();
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
	}

	function syncAllOrder():Void
	{
		// all = enabled (priority order) then disabled
		var all:Array<String> = [];
		for (m in modsList.enabled)
			if (m != null && m.length > 0 && !all.contains(m)) all.push(m);
		for (m in modsList.disabled)
			if (m != null && m.length > 0 && !all.contains(m)) all.push(m);
		// keep any stray from previous all
		for (m in modsList.all)
			if (m != null && m.length > 0 && !all.contains(m))
			{
				all.push(m);
				if (!modsList.disabled.contains(m) && !modsList.enabled.contains(m))
					modsList.disabled.push(m);
			}
		modsList.all = all;
	}

	function openModFolder():Void
	{
		#if sys
		var modFolder = Paths.mods();
		if (!FileSystem.exists(modFolder))
			FileSystem.createDirectory(modFolder);
		CoolUtil.openFolder(modFolder);
		#else
		trace('[ModsMenu] Open folder not available on this target');
		#end
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
	}

	function saveTxt():Void
	{
		syncAllOrder();
		Mods.saveList(modsList);
		modsDirty = false;
	}

	function doneAndExit():Void
	{
		saveTxt();
		FlxG.sound.play(Paths.sound('cancelMenu'));

		if (waitingToRestart || modsDirty)
		{
			// After apply always safe restart when enable list changed
			waitingToRestart = true;
		}

		if (waitingToRestart)
		{
			try
			{
				TitleMenuState.initialized = false;
				TitleMenuState.closedState = false;
			}
			catch (e:Dynamic)
			{
				try
				{
					TitleState.initialized = false;
					TitleState.closedState = false;
				}
				catch (e2:Dynamic) {}
			}
			if (FlxG.sound.music != null) FlxG.sound.music.fadeOut(0.3);
			if (FreeplayMenuState.vocals != null)
			{
				FreeplayMenuState.vocals.fadeOut(0.3);
				FreeplayMenuState.vocals = null;
			}
			persistentUpdate = false;
			FlxG.mouse.visible = false;
			FlxG.camera.fade(FlxColor.BLACK, 0.45, false, FlxG.resetGame, false);
		}
		else
		{
			persistentUpdate = false;
			FlxG.mouse.visible = false;
			MusicBeatState.switchState(new funkin.states.menus.MainMenuState());
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.BACK)
		{
			doneAndExit();
			return;
		}

		if (controls.UI_UP_P) changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);
		if (controls.UI_LEFT_P) switchColumn(-1);
		if (controls.UI_RIGHT_P) switchColumn(1);

		if (controls.ACCEPT || FlxG.keys.justPressed.SPACE)
			toggleSelectedMod();

		// Mouse: click cards
		if (FlxG.mouse.justPressed)
		{
			// back arrow zone
			if (FlxG.mouse.x < 80 && FlxG.mouse.y < 70)
			{
				doneAndExit();
				return;
			}

			var hit:Bool = false;
			for (i in 0...disabledCards.length)
			{
				var c = disabledCards.members[i];
				if (c != null && c.visible && FlxG.mouse.overlaps(c))
				{
					focusColumn = 0;
					if (curDisabled == i)
						toggleSelectedMod();
					else
					{
						curDisabled = i;
						refreshSelectionVisuals();
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
					}
					hit = true;
					break;
				}
			}
			if (!hit)
			{
				for (i in 0...enabledCards.length)
				{
					var c = enabledCards.members[i];
					if (c != null && c.visible && FlxG.mouse.overlaps(c))
					{
						focusColumn = 1;
						if (curEnabled == i)
							toggleSelectedMod();
						else
						{
							curEnabled = i;
							refreshSelectionVisuals();
							FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
						}
						hit = true;
						break;
					}
				}
			}
		}

		buttonOpenFolder.updateHover();
		buttonDone.updateHover();
	}
}

/**
 * Single mod row card (icon + title + description).
 */
class ModCard extends FlxSpriteGroup
{
	public var folder:String;
	public var bgColor:FlxColor = 0xFF665AFF;
	public var mustRestart:Bool = false;
	public var apiVersion:String = '';
	public var modFormat:String = '';

	var bgBox:FlxSprite;
	var selectBox:FlxSprite;
	var icon:FlxSprite;
	var nameTxt:FlxText;
	var descTxt:FlxText;
	var statusTxt:FlxText;

	public function new(folder:String, enabled:Bool)
	{
		super();
		this.folder = folder;

		var packInfo = Mods.getPackInfo(folder);

		bgBox = FlxSpriteUtil.drawRoundRect(
			new FlxSprite().makeGraphic(396, 74, FlxColor.TRANSPARENT),
			0, 0, 396, 74, 12, 12, 0xFF2A2A35
		);
		add(bgBox);

		selectBox = FlxSpriteUtil.drawRoundRect(
			new FlxSprite().makeGraphic(396, 74, FlxColor.TRANSPARENT),
			0, 0, 396, 74, 12, 12, 0xFF6688FF
		);
		selectBox.alpha = 0;
		add(selectBox);

		icon = new FlxSprite(8, 7);
		icon.antialiasing = true;
		add(icon);

		var iconName:String = (packInfo != null) ? packInfo.icon : null;
		var file:String = Mods.resolveModIconPath(folder, iconName);
		var bmp:BitmapData = null;
		var isPixel:Bool = false;
		if (file != null && StringTools.endsWith(file.toLowerCase(), '-pixel.png'))
			isPixel = true;
		#if sys
		if (file != null && FileSystem.exists(file))
			bmp = BitmapData.fromFile(file);
		#end
		if (bmp != null)
		{
			icon.loadGraphic(Paths.cacheBitmap(file, bmp), true, 150, 150);
			if (isPixel) icon.antialiasing = false;
		}
		else
		{
			try icon.loadGraphic(Paths.image('menus/mods/unknownMod'), true, 150, 150)
			catch (e:Dynamic) icon.makeGraphic(60, 60, 0xFF444444);
		}
		icon.setGraphicSize(60, 60);
		icon.updateHitbox();

		var displayName:String = folder;
		var desc:String = 'No description provided.';
		if (packInfo != null)
		{
			if (packInfo.name != null && packInfo.name.length > 0) displayName = packInfo.name;
			if (packInfo.description != null && packInfo.description.length > 0) desc = packInfo.description;
			if (packInfo.color != null && packInfo.color.length >= 3)
				bgColor = FlxColor.fromRGB(packInfo.color[0], packInfo.color[1], packInfo.color[2]);
			mustRestart = packInfo.restart;
			if (packInfo.apiVersion != null) apiVersion = packInfo.apiVersion;
			if (packInfo.format != null) modFormat = packInfo.format;
		}

		nameTxt = new FlxText(78, 8, 300, displayName.toUpperCase(), 18);
		nameTxt.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		nameTxt.borderSize = 1;
		add(nameTxt);

		descTxt = new FlxText(78, 32, 300, desc, 12);
		descTxt.setFormat(Paths.font('vcr.ttf'), 12, 0xFFCCCCCC, LEFT);
		add(descTxt);

		var apiStatus:String = Mods.getApiStatus(folder);
		statusTxt = new FlxText(78, 52, 300, '', 11);
		statusTxt.setFormat(Paths.font('vcr.ttf'), 11, apiStatus == 'INCOMPATIBLE' ? 0xFFFF6666 : 0xFF88AACC, LEFT);
		if (apiVersion != null && apiVersion.length > 0)
			statusTxt.text = 'API ' + apiVersion + (apiStatus == 'INCOMPATIBLE' ? '  [INCOMPATIBLE]' : '');
		else if (modFormat != null && modFormat.length > 0)
			statusTxt.text = modFormat.toUpperCase();
		add(statusTxt);

		if (!enabled)
		{
			icon.color = 0xFFCCCCCC;
			nameTxt.alpha = 0.95;
		}
	}

	public function setSelected(sel:Bool):Void
	{
		selectBox.alpha = sel ? 0.35 : 0;
		bgBox.color = sel ? 0xFF3A3A55 : 0xFFFFFFFF;
		scale.set(sel ? 1.02 : 1, sel ? 1.02 : 1);
	}
}

/**
 * Rounded pill button (OPEN MOD FOLDER / DONE).
 */
class PillButton extends FlxSpriteGroup
{
	var bg:FlxSprite;
	var label:FlxText;
	var onClick:Void->Void;
	var w:Int;
	var h:Int;
	public var hovered:Bool = false;

	public function new(x:Float, y:Float, w:Int, h:Int, text:String, onClick:Void->Void)
	{
		super(x, y);
		this.w = w;
		this.h = h;
		this.onClick = onClick;

		bg = FlxSpriteUtil.drawRoundRect(
			new FlxSprite().makeGraphic(w, h, FlxColor.TRANSPARENT),
			0, 0, w, h, 28, 28, 0xFF2A2A38
		);
		add(bg);

		label = new FlxText(0, 0, w, text, 22);
		label.setFormat(Paths.font('vcr.ttf'), 22, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		label.borderSize = 2;
		label.y = (h - label.height) * 0.5;
		add(label);
	}

	public function updateHover():Void
	{
		hovered = FlxG.mouse.overlaps(bg) || FlxG.mouse.overlaps(this);
		bg.color = hovered ? 0xFF4A4A68 : 0xFFFFFFFF;
		if (hovered && FlxG.mouse.justPressed && onClick != null)
			onClick();
	}
}
'''
