package funkin.data.objects;

class HealthIcon extends FlxSprite
{
	private var char:String = '';
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;

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
		var icon:String = char != null ? char.trim() : '';
		if(icon.length < 1) icon = 'face';

		if(this.char != icon)
		{
			var name:String = getIconPath(icon);
			var graphic = Paths.image(name, null, allowGPU);
			if(graphic == null && name != 'icons/icon-face')
				graphic = Paths.image('icons/icon-face', null, allowGPU);
			if(graphic == null) return;

			var iSize:Float = Math.max(1, Math.round(graphic.width / graphic.height));
			loadGraphic(graphic, true, Math.floor(graphic.width / iSize), Math.floor(graphic.height));
			iconOffsets[0] = (width - 150) / iSize;
			iconOffsets[1] = (height - 150) / iSize;
			updateHitbox();

			animation.add(icon, [for(i in 0...frames.frames.length) i], 0, false, isPlayer);
			animation.play(icon);
			this.char = icon;

			if(icon.endsWith('-pixel'))
				antialiasing = false;
			else
				antialiasing = Preferences.data.antialiasing;
		}
	}

	function getIconPath(icon:String):String
	{
		var paths:Array<String> = [
			'icons/$icon',
			'icons/baseGame/$icon',
			'icons/baseGame/icon-$icon',
			'icons/freeplay/extra/$icon',
			'icons/freeplay/extra/icon-$icon',
			'icons/icon-$icon',
			'icons/icon-face'
		];

		for(path in paths)
			if(Paths.fileExists('images/$path.png', IMAGE))
				return path;

		return 'icons/icon-face';
	}

	public function updateHealthState(healthPercent:Float, opponent:Bool = false):Void
	{
		if(animation == null || animation.curAnim == null) return;

		var frame:Int = (opponent ? healthPercent > 80 : healthPercent < 20) ? 1 : 0;
		if(animation.curAnim.frames != null && animation.curAnim.frames.length > frame)
			animation.curAnim.curFrame = frame;
	}

	public var autoAdjustOffset:Bool = true;
	override function updateHitbox()
	{
		super.updateHitbox();
		if(autoAdjustOffset)
		{
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		}
	}

	public function getCharacter():String {
		return char;
	}
}