package funkin.data.objects.game.note.config;

import funkin.data.shaders.RGBPalette;
import funkin.data.objects.game.note.data.Note;
import funkin.data.objects.game.note.NoteState as NoteData;
import funkin.data.shaders.RGBPalette.RGBShaderReference;
import funkin.utils.engines.psych.PsychAnimationController;

class StrumNote extends FlxSprite
{
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	private var player:Int;
	
	public var texture(default, set):String = null;
	var noteSkinConfig:Dynamic;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public var useRGBShader:Bool = true;
	public function new(x:Float, y:Float, leData:Int, player:Int)
	{
		animation = new PsychAnimationController(this);

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;

		// RGB controlado por noteStyle.allowRGB (disableNoteRGB removido)
		
		var arr:Array<FlxColor> = Preferences.data.arrowRGB[leData];
		if(Note.noteStyleUsesPixel())
			arr = Preferences.data.arrowRGBPixel[leData];
		
		if(arr != null && leData > -1 && leData <= arr.length)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}

		noteData = leData;
		this.player = player;
		this.noteData = leData;
		this.ID = noteData;
		super(x, y);

		var skin:String = Note.songArrowSkinForMustPress(player == 1);
		if(skin == null || skin.length < 1)
			skin = Note.defaultSongNoteStyle();

		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		texture = skin; //Load texture and anims
		scrollFactor.set();
		playAnim('static');
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		noteSkinConfig = NoteData.notestyles.config(texture);
		if(Note.noteStyleUsesPixel())
		{
			var assetType:String = 'noteStrumlinePixel';
			var assetPath:String = NoteData.notestyles.noteStrumline(texture, true);
			if(Note.noteSkinAtlasExists(assetPath))
			{
				frames = Note.getNoteSkinAtlas(assetPath);
			}
			else
			{
				if(!Note.noteSkinImageExists(assetPath))
					assetPath = 'noteSkins/pixel/NOTE_assets';
				var graphic = Note.getNoteSkinGraphic(assetPath);
				if(graphic == null)
					return;

				var columns:Int = Note.noteSkinColumns(noteSkinConfig, assetType);
				var rows:Int = Note.noteSkinRows(noteSkinConfig, assetType);
				if(columns < 1) columns = 1;
				if(rows < 1) rows = 1;
				loadGraphic(graphic, true, Math.floor(graphic.width / columns), Math.floor(graphic.height / rows));
			}

			antialiasing = false;
			// Pixel strums: Psych uses daPixelZoom
			var sc:Float = PlayState.daPixelZoom;
			try {
				var isPlayer:Bool = (player > 0);
				var fromStyle:Float = NoteData.noteStyle.strumScale(texture, sc, isPlayer);
				if (fromStyle > 1.0) sc = fromStyle;
			} catch(e:Dynamic) {}
			if (sc != sc || sc <= 0) sc = PlayState.daPixelZoom;
			setGraphicSize(Std.int(width * sc));

			// Agora também respeita o allowRGB no pixel
			if(noteSkinConfig != null && !noteSkinConfig.allowRGB)
				useRGBShader = false;
		}
		else
		{
			var assetPath:String = NoteData.notestyles.noteStrumline(texture);
			if(!Note.noteSkinAtlasExists(assetPath))
				assetPath = 'noteSkins/NOTE_assets';
			frames = Note.noteSkinAtlasExists(assetPath) ? Note.getNoteSkinAtlas(assetPath) : null;
			if(frames == null)
				return;

			antialiasing = Preferences.data.antialiasing;
			if(noteSkinConfig != null && !noteSkinConfig.allowRGB)
				useRGBShader = false;
			// Psych StrumNote: setGraphicSize(Std.int(width * 0.7));
			var sc2:Float = 0.7;
			try {
				var isPlayer2:Bool = (player > 0);
				var fromStyle:Float = NoteData.noteStyle.strumScale(texture, 0.7, isPlayer2);
				if (fromStyle > 0 && fromStyle <= 1.5) sc2 = fromStyle;
			} catch(e:Dynamic) {}
			if (sc2 != sc2 || sc2 <= 0) sc2 = 0.7;
			setGraphicSize(Std.int(width * sc2));
		}

		// Psych Engine style (source/objects/StrumNote.hx)
		// Prefer noteStyle JSON via addAnimationFromConfig; fall back to hardcoded Psych prefixes.
		function psychStrum(name:String, prefix:String, fps:Int = 24, loop:Bool = false):Void
		{
			if (!Note.addAnimationFromConfig(animation, name, noteSkinConfig, name))
			{
				// Also try static0/pressed0 keys from noteStyle
				var altKey:String = name;
				if (name == 'static') altKey = 'static' + (Math.abs(noteData) % 4);
				else if (name == 'pressed') altKey = 'pressed' + (Math.abs(noteData) % 4);
				else if (name == 'confirm') altKey = 'confirm' + (Math.abs(noteData) % 4);
				if (!Note.addAnimationFromConfig(animation, name, noteSkinConfig, altKey))
					animation.addByPrefix(name, prefix, fps, loop);
			}
		}

		Note.addAnimationFromConfig(animation, 'green', noteSkinConfig, 'green');
		Note.addAnimationFromConfig(animation, 'blue', noteSkinConfig, 'blue');
		Note.addAnimationFromConfig(animation, 'purple', noteSkinConfig, 'purple');
		Note.addAnimationFromConfig(animation, 'red', noteSkinConfig, 'red');
		if (!animation.exists('green')) animation.addByPrefix('green', 'arrowUP');
		if (!animation.exists('blue')) animation.addByPrefix('blue', 'arrowDOWN');
		if (!animation.exists('purple')) animation.addByPrefix('purple', 'arrowLEFT');
		if (!animation.exists('red')) animation.addByPrefix('red', 'arrowRIGHT');

		switch (Math.abs(noteData) % 4)
		{
			case 0:
				psychStrum('static', 'arrowLEFT');
				psychStrum('pressed', 'left press', 24, false);
				psychStrum('confirm', 'left confirm', 24, false);
			case 1:
				psychStrum('static', 'arrowDOWN');
				psychStrum('pressed', 'down press', 24, false);
				psychStrum('confirm', 'down confirm', 24, false);
			case 2:
				psychStrum('static', 'arrowUP');
				psychStrum('pressed', 'up press', 24, false);
				psychStrum('confirm', 'up confirm', 24, false);
			case 3:
				psychStrum('static', 'arrowRIGHT');
				psychStrum('pressed', 'right press', 24, false);
				psychStrum('confirm', 'right confirm', 24, false);
		}
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function playerPosition()
	{
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		if(animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
		if(useRGBShader) rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
	}
}