package funkin.data.objects;

class AttachedSprite extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var angleAdd:Float = 0;
	public var alphaMult:Float = 1;

	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyVisible:Bool = false;

	public function new(?file:String = null, ?anim:String = null, ?parentFolder:String = null, ?loop:Bool = false)
	{
		super();
		if (anim != null)
		{
			var atlas = null;
			try atlas = Paths.getSparrowAtlas(file, parentFolder) catch (e:Dynamic) {}
			if (atlas != null)
			{
				frames = atlas;
				animation.addByPrefix('idle', anim, 24, loop);
				animation.play('idle');
			}
			else
			{
				makeGraphic(1, 1, 0x00000000);
			}
		}
		else if (file != null)
		{
			var graphic = null;
			try graphic = Paths.image(file, parentFolder) catch (e:Dynamic) {}
			if (graphic != null)
				loadGraphic(graphic);
			else
				makeGraphic(1, 1, 0x00000000);
		}

		try
		{
			if (Preferences.data != null)
				antialiasing = Preferences.data.antialiasing;
		}
		catch (e:Dynamic) {}
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
		{
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			scrollFactor.set(sprTracker.scrollFactor.x, sprTracker.scrollFactor.y);

			if (copyAngle)
				angle = sprTracker.angle + angleAdd;

			if (copyAlpha)
				alpha = sprTracker.alpha * alphaMult;

			if (copyVisible)
				visible = sprTracker.visible;
		}
	}
}
