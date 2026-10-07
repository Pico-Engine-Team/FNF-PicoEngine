package funkin.states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.sound.FlxSound;

import funkin.data.dialogue.DialogueBoxPsych;
import funkin.data.objects.Alphabet;
import funkin.states.menus.MainMenuState;
import funkin.utils.engines.pico.AntiPiracy;

/**
 * Theatrical anti-piracy sequence (Pico Engine).
 *
 * Inspired by classic console "unauthorized copy" lock screens
 * (the style popularized in anti-piracy screen compilations):
 *
 *   Phase 0 — optional mid-song dialogue
 *   Phase 1 — VERIFYING COPY...
 *   Phase 2 — UNAUTHORIZED SOFTWARE DETECTED
 *   Phase 3 — full lock panel (menuDesat black + Alphabet)
 *   Phase 4 — fake Windows BSOD then app exit (Quit only)
 *
 * Runs on every PC that has this build. Triggered by AntiPiracy
 * license / GameBanana-GameJolt checks — not tied to any remote author.
 *
 * Integrity markers must match AntiPiracy.hx; if this file is partially
 * edited and recompiled with broken markers, the hard path is forced.
 * Full source removal on GitHub still possible (open-source limit).
 */
class AntiPiracyScreenState extends MusicBeatState
{
	public static inline var INTEGRITY_MARKER:String = 'PICO-AP-SCREEN-v1';

	public var fromPlayState:Bool = false;
	public var blockReason:String = '';
	public var modFolderName:String = '';
	public var weekName:String = '';
	/** Dialogue JSON name under assets/anti-piracy/dialogue/ (no .json). */
	public var dialogueFileName:String = 'antipiracy';

	/**
	 * Asset layout:
	 *
	 *   menuDesat → Paths.image('menus/backgrounds/menuDesat')
	 *               = Paths.getFolderPath('images/menus/backgrounds/menuDesat.png', 'shared')
	 *   confirm   → Paths.sound('confirmMenu')
	 *               = sounds/ under shared (Paths.getFolderPath)
	 *
	 * Optional anti-piracy pack under:
	 *   assets/anti-piracy/images/
	 *   assets/anti-piracy/music/
	 *   assets/anti-piracy/sounds/
	 *   assets/anti-piracy/dialogue/
	 */
	public static inline var ASSET_ROOT:String = 'anti-piracy';

	public var musicKey:String = 'antiPiracy';
	/** Shared sounds/ keys (Paths.sound → assets/shared/sounds/...). */
	public var confirmSound:String = 'confirmMenu';
	public var cancelSound:String = 'cancelMenu';
	public var scrollSound:String = 'scrollMenu';
	public var warningSound:String = 'cancelMenu';
	/** Shared images key (Paths.image prepends images/). */
	public var backgroundKey:String = 'menus/backgrounds/menuDesat';

	/** Classic FNF Alphabet headline on the lock panel. */
	public var varPiracyText:Alphabet;

	var bg:FlxSprite;
	var desatBg:FlxSprite;
	var blackOverlay:FlxSprite;

	var phaseLabel:FlxText;
	var warningTitle:FlxText;
	var warningBody:FlxText;
	var errorCodeText:FlxText;
	var tipText:FlxText;

	var options:Array<String> = ['Acknowledge', 'Quit Game'];
	var optionGroup:FlxTypedGroup<FlxText>;
	var curSelected:Int = 0;
	var canSelect:Bool = false;

	var dialogueBox:DialogueBoxPsych = null;
	var inDialogue:Bool = false;
	var dialogueDone:Bool = false;
	var onPiracyPanel:Bool = false;
	var showingBsod:Bool = false;
	var integrityFailed:Bool = false;
	var phaseBusy:Bool = false;

	var ambientSound:FlxSound = null;

	// Typewriter / phase helpers
	var builtinLines:Array<String> = [];
	var builtinIndex:Int = 0;
	var builtinText:FlxText;
	var builtinHint:FlxText;
	var lineReady:Bool = false;

	public function new(?fromPlayState:Bool = false, ?dialogueFile:String = null)
	{
		super();
		this.fromPlayState = fromPlayState == true;
		if(dialogueFile != null && dialogueFile.trim().length > 0)
			this.dialogueFileName = dialogueFile.trim();
	}

	override function create()
	{
		super.create();

		persistentUpdate = false;
		persistentDraw = true;
		FlxG.mouse.visible = false;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Anti-Piracy Warning", null);
		#end

		integrityFailed = !verifyIntegrity();
		if(integrityFailed)
		{
			blockReason = (blockReason != null && blockReason.length > 0)
				? blockReason + ' · Integrity check failed'
				: 'Integrity check failed — AntiPiracy code was modified';
		}

		if(fromPlayState)
			stopGameplayAudio();

		buildBackground();
		buildTexts();
		buildOptions();

		tipText = new FlxText(0, FlxG.height - 32, FlxG.width,
			'Support official releases · GameBanana / GameJolt only', 14);
		tipText.setFormat(Paths.font('vcr.ttf'), 14, 0xFF888888, CENTER);
		tipText.scrollFactor.set();
		tipText.alpha = 0;
		add(tipText);

		// Opening red flash (classic "caught" feel)
		var flash:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.RED);
		flash.alpha = 0.4;
		flash.scrollFactor.set();
		add(flash);
		FlxTween.tween(flash, {alpha: 0}, 0.55, {
			onComplete: function(_)
			{
				flash.destroy();
				if(integrityFailed)
					runVerifyPhase(true);
				else if(fromPlayState)
					startDialogueFlow();
				else
					runVerifyPhase(false);
			}
		});

		playWarningSound();
		startMusic();
	}

	// =====================================================================
	//  Background — black + menuDesat tinted black
	// =====================================================================

	function buildBackground():Void
	{
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.scrollFactor.set();
		add(bg);

		desatBg = new FlxSprite();
		try
		{
			// Paths.getFolderPath('images/menus/backgrounds/menuDesat.png', 'shared')
			// Paths.image adds images/ automatically
			var graphic = Paths.image(backgroundKey);
			if(graphic == null)
				graphic = Paths.image('menus/backgrounds/menuDesat');
			if(graphic != null)
			{
				desatBg.loadGraphic(graphic);
			}
			else
			{
				var file:String = Paths.getFolderPath('images/menus/backgrounds/menuDesat.png', 'shared');
				#if MODS_ALLOWED
				if(sys.FileSystem.exists(file))
					desatBg.loadGraphic(file);
				else
				#end
					desatBg.makeGraphic(FlxG.width, FlxG.height, 0xFF050505);
			}
			desatBg.setGraphicSize(FlxG.width, FlxG.height);
			desatBg.updateHitbox();
			desatBg.screenCenter();
			desatBg.color = FlxColor.BLACK;
			desatBg.alpha = 0.5;
		}
		catch(e:Dynamic)
		{
			desatBg.makeGraphic(FlxG.width, FlxG.height, 0xFF050505);
			trace('[AntiPiracy] menuDesat load failed: ' + e);
		}
			desatBg.scrollFactor.set();
		add(desatBg);

		blackOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackOverlay.alpha = 0.75;
		blackOverlay.scrollFactor.set();
		add(blackOverlay);
	}

	function buildTexts():Void
	{
		phaseLabel = new FlxText(0, 40, FlxG.width, '', 18);
		phaseLabel.setFormat(Paths.font('vcr.ttf'), 18, 0xFFFF6666, CENTER, OUTLINE, FlxColor.BLACK);
		phaseLabel.borderSize = 2;
		phaseLabel.scrollFactor.set();
		phaseLabel.alpha = 0;
		add(phaseLabel);

		warningTitle = new FlxText(0, 90, FlxG.width - 80, '', 32);
		warningTitle.setFormat(Paths.font('vcr.ttf'), 32, 0xFFFF2222, CENTER, OUTLINE, FlxColor.BLACK);
		warningTitle.borderSize = 3;
		warningTitle.screenCenter(X);
		warningTitle.scrollFactor.set();
		warningTitle.alpha = 0;
		add(warningTitle);

		warningBody = new FlxText(60, 160, FlxG.width - 120, '', 18);
		warningBody.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		warningBody.borderSize = 1.5;
		warningBody.scrollFactor.set();
		warningBody.alpha = 0;
		add(warningBody);

		errorCodeText = new FlxText(0, FlxG.height - 200, FlxG.width, '', 16);
		errorCodeText.setFormat(Paths.font('vcr.ttf'), 16, 0xFFAAAAAA, CENTER);
		errorCodeText.scrollFactor.set();
		errorCodeText.alpha = 0;
		add(errorCodeText);
	}

	function buildOptions():Void
	{
		optionGroup = new FlxTypedGroup<FlxText>();
		add(optionGroup);
	}

	function stopGameplayAudio():Void
	{
		try { if(FlxG.sound.music != null) FlxG.sound.music.stop(); } catch(e:Dynamic) {}
		try
		{
			if(PlayState.instance != null)
			{
				if(PlayState.instance.vocals != null) PlayState.instance.vocals.stop();
				if(PlayState.instance.opponentVocals != null) PlayState.instance.opponentVocals.stop();
			}
		}
		catch(e:Dynamic) {}
	}

	// =====================================================================
	//  PHASE 1 — VERIFYING (like console copy-check)
	// =====================================================================

	function runVerifyPhase(forceHard:Bool):Void
	{
		phaseBusy = true;
		canSelect = false;
		hideOptions();

		phaseLabel.text = 'SYSTEM CHECK';
		phaseLabel.alpha = 1;
		warningTitle.text = 'VERIFYING COPY...';
		warningTitle.alpha = 1;
		warningBody.text = 'Please wait.\nDo not turn off the power.';
		warningBody.alpha = 1;
		errorCodeText.text = '';
		errorCodeText.alpha = 0;

		var dots:Int = 0;
		var steps:Int = 0;
		new FlxTimer().start(0.35, function(t:FlxTimer)
		{
			steps++;
			dots = (dots + 1) % 4;
			var d:String = '';
			for (i in 0...dots) d += '.';
			warningTitle.text = 'VERIFYING COPY' + d;

			if(steps >= 6)
			{
				t.cancel();
				runDetectedPhase(forceHard);
			}
		}, 0);
	}

	// =====================================================================
	//  PHASE 2 — UNAUTHORIZED DETECTED
	// =====================================================================

	function runDetectedPhase(forceHard:Bool):Void
	{
		playWarningSound();

		phaseLabel.text = 'WARNING';
		warningTitle.text = 'UNAUTHORIZED SOFTWARE DETECTED';
		warningTitle.color = 0xFFFF2222;

		var body:String = [
			'This copy of Pico Engine / the loaded mod failed verification.',
			'',
			'Unauthorized redistribution is a violation of copyright.',
			'Please obtain a legitimate copy from an official source',
			'(GameBanana or GameJolt for mods).',
			'',
			'This session cannot continue normally.'
		].join('\n');

		if(modFolderName != null && modFolderName.length > 0)
			body = 'Mod: ' + modFolderName + '\n\n' + body;
		if(weekName != null && weekName.length > 0)
			body = 'Context: ' + weekName + '\n' + body;
		if(blockReason != null && blockReason.length > 0)
			body += '\n\nDetail: ' + blockReason;

		warningBody.text = body;
		warningBody.alpha = 1;

		errorCodeText.text = 'Stop code: UNAUTHORIZED_COPY  ·  Error: 0xP1C0';
		errorCodeText.alpha = 1;

		// Red pulse
		var pulse:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFFF0000);
		pulse.alpha = 0.25;
		pulse.scrollFactor.set();
		add(pulse);
		FlxTween.tween(pulse, {alpha: 0}, 0.8, {
			onComplete: function(_)
			{
				pulse.destroy();
				new FlxTimer().start(1.4, function(_)
				{
					showLockPanel(forceHard);
				});
			}
		});
	}

	// =====================================================================
	//  PHASE 3 — LOCK PANEL (Alphabet + black board)
	// =====================================================================

	function showLockPanel(forceHard:Bool):Void
	{
		phaseBusy = false;
		onPiracyPanel = true;

		if(blackOverlay != null)
			FlxTween.tween(blackOverlay, {alpha: 0.9}, 0.3);

		phaseLabel.text = 'COPY PROTECTION';
		phaseLabel.alpha = 1;

		// Alphabet headline
		if(varPiracyText != null)
		{
			remove(varPiracyText);
			varPiracyText.destroy();
			varPiracyText = null;
		}

		var headline:String = forceHard ? 'COPY PROTECTION' : 'ILLEGAL COPY';
		try
		{
			varPiracyText = new Alphabet(0, 0, headline, true);
			varPiracyText.screenCenter(X);
			varPiracyText.y = 70;
			varPiracyText.scrollFactor.set();
			add(varPiracyText);
			warningTitle.visible = false;
		}
		catch(e:Dynamic)
		{
			trace('[AntiPiracy] Alphabet failed: ' + e);
			warningTitle.text = headline;
			warningTitle.visible = true;
			warningTitle.alpha = 1;
		}

		warningBody.text = getLockBody();
		warningBody.y = 180;
		warningBody.alpha = 1;

		errorCodeText.text = '0xP1C0  ·  PIRACY IS NOT A VICTIMLESS CRIME';
		errorCodeText.alpha = 1;

		showOptions(forceHard);
	}

	function getLockBody():String
	{
		var lines:Array<String> = [
			'An unofficial or improperly licensed copy was detected.',
			'',
			'Please power off and obtain this software from an official source.',
			'Mods must include a valid license and a GameBanana or GameJolt page.',
			'',
			'Support the people who make the content you enjoy.'
		];
		if(modFolderName != null && modFolderName.length > 0)
			lines.insert(0, 'Mod folder: ' + modFolderName);
		if(weekName != null && weekName.length > 0)
			lines.insert(0, 'Was playing: ' + weekName);
		if(blockReason != null && blockReason.length > 0)
			lines.push('\nReason: ' + blockReason);
		return lines.join('\n');
	}

	// =====================================================================
	//  Dialogue (mid-song only) → then verify sequence
	// =====================================================================

	function startDialogueFlow():Void
	{
		var tried:Array<String> = [];
		if(weekName != null && weekName.length > 0)
			tried.push('antipiracy-week');
		tried.push(dialogueFileName);
		tried.push('antipiracy');
		for (name in tried)
		{
			dialogueFileName = name;
			if(tryStartPsychDialogue())
				return;
		}
		startBuiltinDialogue();
	}

	function tryStartPsychDialogue():Bool
	{
		try
		{
			// Prefer assets/anti-piracy/dialogue/<name>.json
			var path:String = resolveDialoguePath(dialogueFileName);
			var raw:String = null;
			#if MODS_ALLOWED
			if(sys.FileSystem.exists(path))
				raw = sys.io.File.getContent(path);
			#end
			if(raw == null)
			{
				try raw = openfl.utils.Assets.getText(path) catch(e:Dynamic) {}
			}
			if(raw == null || raw.trim().length < 1)
				return false;

			var file:DialogueFile = cast haxe.Json.parse(raw);
			if(file == null || file.dialogue == null || file.dialogue.length < 1)
				return false;

			inDialogue = true;
			dialogueBox = new DialogueBoxPsych(file, null);
			dialogueBox.finishThing = onDialogueFinished;
			dialogueBox.cameras = [FlxG.camera];
			add(dialogueBox);
			return true;
		}
		catch(e:Dynamic)
		{
			trace('[AntiPiracy] DialogueBoxPsych failed: ' + e);
			return false;
		}
	}

	function startBuiltinDialogue():Void
	{
		inDialogue = true;
		dialogueDone = false;
		builtinIndex = 0;
		builtinLines = [
			'Hold on.',
			'This copy failed the license / source check.',
			'You were in the middle of a song when verification ran.'
		];
		if(weekName != null && weekName.length > 0)
			builtinLines.push('Week / song: ' + weekName);
		if(modFolderName != null && modFolderName.length > 0)
			builtinLines.push('Mod: ' + modFolderName);
		if(blockReason != null && blockReason.length > 0)
			builtinLines.push(blockReason);
		builtinLines.push('Official sources only: GameBanana or GameJolt.');
		builtinLines.push('Piracy is not a victimless crime.');

		builtinText = new FlxText(80, FlxG.height * 0.52, FlxG.width - 160, '', 22);
		builtinText.setFormat(Paths.font('vcr.ttf'), 22, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		builtinText.borderSize = 2;
		builtinText.scrollFactor.set();
		add(builtinText);

		builtinHint = new FlxText(0, FlxG.height - 70, FlxG.width, 'Press ACCEPT to continue', 16);
		builtinHint.setFormat(Paths.font('vcr.ttf'), 16, 0xFFCCCCCC, CENTER);
		builtinHint.scrollFactor.set();
		add(builtinHint);

		showBuiltinLine();
	}

	function showBuiltinLine():Void
	{
		lineReady = false;
		if(builtinIndex >= builtinLines.length)
		{
			onDialogueFinished();
			return;
		}
		var full:String = builtinLines[builtinIndex];
		builtinText.text = '';
		var i:Int = 0;
		new FlxTimer().start(0.02, function(t:FlxTimer)
		{
			if(builtinText == null) return;
			i++;
			builtinText.text = full.substr(0, i);
			if(i >= full.length)
			{
				lineReady = true;
				t.cancel();
			}
		}, 0);
		playScrollSound(0.25);
	}

	function advanceBuiltinDialogue():Void
	{
		if(!lineReady)
		{
			if(builtinIndex < builtinLines.length)
			{
				builtinText.text = builtinLines[builtinIndex];
				lineReady = true;
			}
			return;
		}
		builtinIndex++;
		showBuiltinLine();
	}

	function onDialogueFinished():Void
	{
		inDialogue = false;
		dialogueDone = true;

		if(dialogueBox != null)
		{
			remove(dialogueBox);
			dialogueBox.destroy();
			dialogueBox = null;
		}
		if(builtinText != null)
		{
			builtinText.visible = false;
			if(builtinHint != null) builtinHint.visible = false;
		}

		// After dialogue → same theatrical sequence as menus
		runVerifyPhase(integrityFailed);
	}

	// =====================================================================
	//  Options
	// =====================================================================

	function hideOptions():Void
	{
		canSelect = false;
		while(optionGroup.length > 0)
		{
			var t = optionGroup.members[0];
			optionGroup.remove(t, true);
			if(t != null) t.destroy();
		}
	}

	function showOptions(hardMode:Bool):Void
	{
		hideOptions();
		options = hardMode ? ['Quit Game'] : ['Acknowledge', 'Quit Game'];

		for (i in 0...options.length)
		{
			var opt:FlxText = new FlxText(0, FlxG.height - 150 + (i * 40), FlxG.width, options[i], 26);
			opt.setFormat(Paths.font('vcr.ttf'), 26, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			opt.borderSize = 2;
			opt.ID = i;
			opt.scrollFactor.set();
			opt.alpha = 0;
			optionGroup.add(opt);
			FlxTween.tween(opt, {alpha: 1}, 0.25, {ease: FlxEase.quadOut});
		}

		FlxTween.tween(tipText, {alpha: 1}, 0.35);
		canSelect = true;
		curSelected = 0;
		changeSelection(0, false);
	}

	function changeSelection(change:Int = 0, playSound:Bool = true):Void
	{
		if(!canSelect || showingBsod || phaseBusy) return;
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
		if(playSound) playScrollSound();

		for (opt in optionGroup)
		{
			if(opt.ID == curSelected)
			{
				opt.color = 0xFFFFEE88;
				opt.alpha = 1;
			}
			else
			{
				opt.color = FlxColor.WHITE;
				opt.alpha = 0.55;
			}
		}
	}

	function accept():Void
	{
		if(!canSelect || showingBsod || phaseBusy) return;
		canSelect = false;
		playConfirmSound();

		switch(options[curSelected])
		{
			case 'Acknowledge':
				if(integrityFailed)
					startFakeBsod();
				else
					leaveToMenus();
			case 'Quit Game':
				startFakeBsod();
			default:
				startFakeBsod();
		}
	}

	function leaveToMenus():Void
	{
		try AntiPiracy.markAcknowledged(modFolderName) catch(e:Dynamic) {}
		try
		{
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.chartingMode = false;
		}
		catch(e:Dynamic) {}

		stopMusic();
		MusicBeatState.switchState(new MainMenuState());
	}

	// =====================================================================
	//  PHASE 4 — Fake BSOD (visual only — does NOT reboot Windows)
	// =====================================================================

	function startFakeBsod():Void
	{
		if(showingBsod) return;
		showingBsod = true;
		canSelect = false;
		stopMusic();

		for (m in members)
			if(m != null) m.visible = false;

		var bsodBg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF0078D7);
		bsodBg.scrollFactor.set();
		add(bsodBg);

		var face:FlxText = new FlxText(80, 70, FlxG.width - 160, ':(', 96);
		face.setFormat(Paths.font('vcr.ttf'), 96, FlxColor.WHITE, LEFT);
		face.scrollFactor.set();
		add(face);

		var msg:String = [
			'Your PC ran into a problem and needs to restart. We\'re just',
			'collecting some error info, and then we\'ll restart for you.',
			'',
			'Pico Engine Anti-Piracy',
			'Stop code: UNAUTHORIZED_COPY',
			''
		].join('\n');
		if(modFolderName != null && modFolderName.length > 0)
			msg += 'Mod: ' + modFolderName + '\n';
		if(blockReason != null && blockReason.length > 0)
			msg += blockReason + '\n';

		var body:FlxText = new FlxText(80, 190, FlxG.width - 160, msg, 20);
		body.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, LEFT);
		body.scrollFactor.set();
		add(body);

		var percent:FlxText = new FlxText(80, FlxG.height - 110, FlxG.width - 160, '0% complete', 22);
		percent.setFormat(Paths.font('vcr.ttf'), 22, FlxColor.WHITE, LEFT);
		percent.scrollFactor.set();
		add(percent);

		var p:Int = 0;
		new FlxTimer().start(0.08, function(t:FlxTimer)
		{
			p += FlxG.random.int(1, 4);
			if(p > 100) p = 100;
			percent.text = p + '% complete';
			if(p >= 100)
			{
				t.cancel();
				new FlxTimer().start(0.55, function(_) quitGame());
			}
		}, 0);
	}

	function quitGame():Void
	{
		stopMusic();
		#if (sys || desktop)
		Sys.exit(1);
		#else
		leaveToMenus();
		#end
	}

	// =====================================================================
	//  Integrity
	// =====================================================================

	function verifyIntegrity():Bool
	{
		try
		{
			if(INTEGRITY_MARKER != AntiPiracy.INTEGRITY_SCREEN)
				return false;
			if(AntiPiracy.INTEGRITY_CORE != 'PICO-AP-CORE-v1')
				return false;
			var hostsOk:Bool = false;
			for (h in AntiPiracy.allowedHosts)
			{
				var lower:String = h.toLowerCase();
				if(lower.indexOf('gamebanana') >= 0 || lower.indexOf('gamejolt') >= 0)
				{
					hostsOk = true;
					break;
				}
			}
			return hostsOk;
		}
		catch(e:Dynamic)
		{
			return false;
		}
	}

	// =====================================================================
	//  Audio
	// =====================================================================

	function startMusic():Void
	{
		// 1) assets/anti-piracy/music/<key>
		for (key in [musicKey, 'antiPiracy', 'warning'])
		{
			try
			{
				var snd = resolveMusic(key);
				if(snd != null)
				{
					FlxG.sound.playMusic(snd, 0.5, true);
					return;
				}
			}
			catch(e:Dynamic) {}
		}
		// 2) Legacy engine music fallbacks
		for (key in ['pauseMenu/breakfast', 'menu/freakyMenu', 'freakyMenu'])
		{
			try
			{
				var snd = Paths.music(key);
				if(snd != null)
				{
					FlxG.sound.playMusic(snd, 0.5, true);
					return;
				}
			}
			catch(e:Dynamic) {}
		}
	}

	function stopMusic():Void
	{
		try
		{
			if(FlxG.sound.music != null)
				FlxG.sound.music.fadeOut(0.3, 0);
		}
		catch(e:Dynamic) {}
		if(ambientSound != null)
		{
			ambientSound.stop();
			ambientSound = null;
		}
	}

	function playWarningSound():Void
		playApSound(warningSound, 0.7, 'cancelMenu');

	function playConfirmSound():Void
		playApSound(confirmSound, 0.7, 'confirmMenu');

	function playScrollSound(?vol:Float = 0.4):Void
		playApSound(scrollSound, vol, 'scrollMenu');

	function playApSound(key:String, vol:Float, legacyFallback:String):Void
	{
		try
		{
			var s = resolveSound(key);
			if(s != null)
			{
				FlxG.sound.play(s, vol);
				return;
			}
		}
		catch(e:Dynamic) {}
		try FlxG.sound.play(Paths.sound(legacyFallback), vol) catch(e:Dynamic) {}
	}

	// =====================================================================
	//  Update
	// =====================================================================

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(showingBsod || phaseBusy)
			return;

		if(inDialogue && dialogueBox == null)
		{
			if(controls.ACCEPT || controls.UI_RIGHT_P)
				advanceBuiltinDialogue();
			if(controls.BACK)
			{
				playScrollSound();
				onDialogueFinished();
			}
			return;
		}
		if(inDialogue)
			return;

		if(!canSelect) return;

		if(controls.UI_UP_P) changeSelection(-1);
		if(controls.UI_DOWN_P) changeSelection(1);
		if(controls.ACCEPT) accept();
		if(controls.BACK)
		{
			curSelected = 0;
			accept();
		}
	}


	// =====================================================================
	//  Asset resolve
	//  menuDesat / confirm → Paths.getFolderPath (shared images/ + sounds/)
	//  optional pack       → assets/anti-piracy/{images,music,sounds,dialogue}/
	// =====================================================================

	/** Optional image under assets/anti-piracy/images/<rel> */
	function resolveApImage(rel:String):Dynamic
	{
		try
		{
			var g = Paths.image(ASSET_ROOT + '/images/' + rel);
			if(g != null) return g;
		}
		catch(e:Dynamic) {}
		try
		{
			var file:String = Paths.getFolderPath('images/' + rel + '.png', ASSET_ROOT);
			#if MODS_ALLOWED
			if(sys.FileSystem.exists(file))
				return file;
			#end
		}
		catch(e:Dynamic) {}
		return null;
	}

	/**
	 * Music: assets/anti-piracy/music/<name>
	 * Paths.getFolderPath('music/<name>.ogg', 'anti-piracy') via Paths.music
	 */
	function resolveMusic(name:String):Dynamic
	{
		for (key in [ASSET_ROOT + '/music/' + name, ASSET_ROOT + '/' + name])
		{
			try
			{
				var s = Paths.music(key);
				if(s != null) return s;
			}
			catch(e:Dynamic) {}
		}
		return null;
	}

	/**
	 * Sounds:
	 *  1) assets/anti-piracy/sounds/<name> (optional override)
	 *  2) Paths.sound(name) → shared sounds/ (confirmMenu, etc.)
	 */
	function resolveSound(name:String):Dynamic
	{
		for (key in [ASSET_ROOT + '/sounds/' + name, ASSET_ROOT + '/' + name])
		{
			try
			{
				var s = Paths.sound(key);
				if(s != null) return s;
			}
			catch(e:Dynamic) {}
		}
		try
		{
			var s2 = Paths.sound(name);
			if(s2 != null) return s2;
		}
		catch(e:Dynamic) {}
		return null;
	}

	/** dialogue: assets/anti-piracy/dialogue/<name>.json then data/dialogue/ */
	function resolveDialoguePath(name:String):String
	{
		try
		{
			var file:String = Paths.getFolderPath('dialogue/' + name + '.json', ASSET_ROOT);
			#if MODS_ALLOWED
			if(sys.FileSystem.exists(file)) return file;
			#end
			try
			{
				if(openfl.utils.Assets.exists(file)) return file;
			}
			catch(e:Dynamic) {}
		}
		catch(e:Dynamic) {}

		try
		{
			return Paths.getPath(ASSET_ROOT + '/dialogue/' + name + '.json', TEXT);
		}
		catch(e:Dynamic) {}

		return Paths.getPath('data/dialogue/' + name + '.json', TEXT);
	}


	override function destroy()
	{
		stopMusic();
		super.destroy();
	}
}
