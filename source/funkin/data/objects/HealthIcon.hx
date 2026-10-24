package funkin.data.objects;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;
	private var char:String = '';

	public function new(char:String = 'face', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String, ?allowGPU:Bool = true)
	{
		if (char == null || char.length < 1)
			char = 'face';

		if (this.char == char)
			return;

		var name:String = 'icons/base-game/' + char;
		if (!Paths.fileExists('images/' + name + '.png', IMAGE))
			name = 'icons/base-game/icon-' + char; // Older Versions of pico engine support
		if (!Paths.fileExists('images/' + name + '.png', IMAGE))
			name = 'icons/icon-' + char;
		if (!Paths.fileExists('images/' + name + '.png', IMAGE))
			name = 'icons/icon-face'; // Prevents crash from missing icon

		var graphic = null;
		try graphic = Paths.image(name, allowGPU) catch (e:Dynamic) {}
		if (graphic == null)
		{
			try graphic = Paths.image('icons/icon-face', allowGPU) catch (e:Dynamic) {}
		}
		if (graphic == null)
		{
			// Last resort placeholder so callers never crash
			makeGraphic(150, 150, 0xFF333333);
			this.char = char;
			return;
		}

		var iSize:Float = 1;
		if (graphic.height > 0)
			iSize = Math.max(1, Math.round(graphic.width / graphic.height));

		loadGraphic(graphic, true, Math.floor(graphic.width / iSize), Math.floor(graphic.height));
		iconOffsets[0] = (width - 150) / iSize;
		iconOffsets[1] = (height - 150) / iSize;
		updateHitbox();

		var frameCount:Int = (frames != null && frames.frames != null) ? frames.frames.length : 1;
		if (frameCount < 1) frameCount = 1;
		animation.add(char, [for (i in 0...frameCount) i], 0, false, isPlayer);
		animation.play(char);
		this.char = char;

		if (char.endsWith('-pixel'))
			antialiasing = false;
		else
		{
			try
			{
				if (Preferences.data != null)
					antialiasing = Preferences.data.antialiasing;
			}
			catch (e:Dynamic) {}
		}
	}

	public var autoAdjustOffset:Bool = true;
	override function updateHitbox()
	{
		super.updateHitbox();
		if (autoAdjustOffset)
		{
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		}
	}

	public function getCharacter():String
	{
		return char;
	}

	public function updateHealthState(healthPercent:Float, isOpponent:Bool = false):Void
	{
		// Preserved for compatibility with older gameplay code.
		// Typically: frame 0 = healthy, frame 1 = dying when healthPercent is low.
		if (animation == null || animation.curAnim == null) return;
		if (animation.curAnim.numFrames < 2) return;

		var dying:Bool = isOpponent ? (healthPercent > 80) : (healthPercent < 20);
		animation.curAnim.curFrame = dying ? 1 : 0;
	}
}
