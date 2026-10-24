package funkin.modding.scripting.psychlua;

#if flxanimate
class ModchartAnimateSprite extends FlxAnimate
{
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		try
		{
			if (Preferences.data != null)
				antialiasing = Preferences.data.antialiasing;
		}
		catch (e:Dynamic) {}
	}

	public function playAnim(name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
	{
		if (anim == null || name == null) return;
		anim.play(name, forced, reverse, startFrame);

		if (animOffsets.exists(name))
		{
			var daOffset = animOffsets.get(name);
			if (daOffset != null && daOffset.length >= 2)
				offset.set(daOffset[0], daOffset[1]);
		}
	}

	public function addOffset(name:String, x:Float, y:Float)
	{
		if (name == null) return;
		animOffsets.set(name, [x, y]);
	}
}
#end
