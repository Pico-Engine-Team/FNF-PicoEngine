package funkin.data.objects.game.notes.config;

import funkin.data.shaders.RGBPalette;
import funkin.data.objects.game.notes.data.Note;
import funkin.data.objects.game.notes.NoteData;
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
			var sc:Float = Note.noteSkinScale(noteSkinConfig, assetType);
			try { sc = NoteData.noteStyle.strumScale(texture, sc); } catch(e:Dynamic) {}
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
			var sc2:Float = Note.noteSkinScale(noteSkinConfig, 'noteStrumline');
			try { sc2 = NoteData.noteStyle.strumScale(texture, sc2); } catch(e:Dynamic) {}
			setGraphicSize(Std.int(width * sc2));
		}

		Note.addAnimationFromConfig(animation, 'green', noteSkinConfig, 'green');
		Note.addAnimationFromConfig(animation, 'blue', noteSkinConfig, 'blue');
		Note.addAnimationFromConfig(animation, 'purple', noteSkinConfig, 'purple');
		Note.addAnimationFromConfig(animation, 'red', noteSkinConfig, 'red');

		switch (Math.abs(noteData) % 4)
		{
			case 0:
				Note.addAnimationFromConfig(animation, 'static', noteSkinConfig, 'static0');
				Note.addAnimationFromConfig(animation, 'pressed', noteSkinConfig, 'pressed0');
				Note.addAnimationFromConfig(animation, 'confirm', noteSkinConfig, 'confirm0');
			case 1:
				Note.addAnimationFromConfig(animation, 'static', noteSkinConfig, 'static1');
				Note.addAnimationFromConfig(animation, 'pressed', noteSkinConfig, 'pressed1');
				Note.addAnimationFromConfig(animation, 'confirm', noteSkinConfig, 'confirm1');
			case 2:
				Note.addAnimationFromConfig(animation, 'static', noteSkinConfig, 'static2');
				Note.addAnimationFromConfig(animation, 'pressed', noteSkinConfig, 'pressed2');
				Note.addAnimationFromConfig(animation, 'confirm', noteSkinConfig, 'confirm2');
			case 3:
				Note.addAnimationFromConfig(animation, 'static', noteSkinConfig, 'static3');
				Note.addAnimationFromConfig(animation, 'pressed', noteSkinConfig, 'pressed3');
				Note.addAnimationFromConfig(animation, 'confirm', noteSkinConfig, 'confirm3');
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