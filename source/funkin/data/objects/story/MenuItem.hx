package funkin.data.objects.story;

class MenuItem extends FlxSprite
{
	public var targetY:Float = 0;
	public var weekName:String = '';

	public function new(x:Float, y:Float, weekName:String = '')
	{
		super(x, y);
		this.weekName = weekName != null ? weekName : '';

		var loaded:Bool = false;
		var candidates:Array<String> = [];

		if (this.weekName.length > 0)
		{
			// Pico / new layout
			candidates.push('storyMode/weekTitles/' + this.weekName);
			candidates.push('storyMode/titles/' + this.weekName);
			// Legacy Psych
			candidates.push('storymenu/titles/' + this.weekName);
			candidates.push('storymenu/weekTitles/' + this.weekName);
		}
		candidates.push('storyMode/weekTitles/week1');
		candidates.push('storymenu/titles/week1');

		for (path in candidates)
		{
			var graphic = null;
			try graphic = Paths.image(path) catch (e:Dynamic) {}
			if (graphic != null)
			{
				loadGraphic(graphic);
				loaded = true;
				break;
			}
		}

		if (!loaded)
			makeGraphic(400, 60, 0xFF333333);

		try
		{
			if (Preferences.data != null)
				antialiasing = Preferences.data.antialiasing;
		}
		catch (e:Dynamic) {}
	}

	public var isFlashing(default, set):Bool = false;
	private var _flashingElapsed:Float = 0;
	final _flashColor = 0xFF33FFFF;
	final flashes_ps:Int = 6;

	public function set_isFlashing(value:Bool = true):Bool
	{
		isFlashing = value;
		_flashingElapsed = 0;
		color = (isFlashing) ? _flashColor : FlxColor.WHITE;
		return isFlashing;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (isFlashing)
		{
			_flashingElapsed += elapsed;
			var rate:Float = FlxG.updateFramerate;
			if (rate <= 0) rate = 60;
			color = (Math.floor(_flashingElapsed * rate * flashes_ps) % 2 == 0) ? _flashColor : FlxColor.WHITE;
		}
	}
}
