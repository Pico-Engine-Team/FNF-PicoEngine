package funkin.stages;

class BGSprite extends FlxSprite
{
	private var idleAnim:String;
	public function new(image:String, x:Float = 0, y:Float = 0, ?scrollX:Float = 1, ?scrollY:Float = 1, ?animArray:Array<String> = null, ?loop:Bool = false) {
		super(x, y);

		if (animArray != null) {
			var atlas = Paths.getSparrowAtlas(image);
			if(atlas != null)
			{
				frames = atlas;
				for (i in 0...animArray.length) {
					var anim:String = animArray[i];
					if(anim == null || anim.length < 1) continue;
					animation.addByPrefix(anim, anim, 24, loop);
					if(idleAnim == null) {
						idleAnim = anim;
						animation.play(anim);
					}
				}
			}
			else
			{
				// Missing atlas — fall back to static graphic if possible
				var graphic = Paths.image(image);
				if(graphic != null) loadGraphic(graphic);
				active = false;
			}
		} else {
			if(image != null) {
				var graphic = Paths.image(image);
				if(graphic != null)
					loadGraphic(graphic);
			}
			active = false;
		}
		scrollFactor.set(scrollX, scrollY);
		antialiasing = Preferences.data.antialiasing;
	}

	public function dance(?forceplay:Bool = false) {
		if(idleAnim != null) {
			animation.play(idleAnim, forceplay);
		}
	}

	public function makePixel() {
		scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
		updateHitbox();
		antialiasing = false;
	}
}