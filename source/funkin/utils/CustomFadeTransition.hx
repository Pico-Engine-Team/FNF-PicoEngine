package funkin.utils;

import flixel.util.FlxGradient;

class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	var isTransIn:Bool = false;
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	var duration:Float;
	public function new(duration:Float, isTransIn:Bool)
	{
		this.duration = duration > 0 ? duration : 0.001;
		this.isTransIn = isTransIn;
		super();
	}

	override function create()
	{
		if (FlxG.cameras.list.length < 1)
		{
			super.create();
			close();
			return;
		}

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		var zoom:Float = Math.max(camera != null ? camera.zoom : 1, 0.001);
		var width:Int = Std.int(FlxG.width / zoom);
		var height:Int = Std.int(FlxG.height / zoom);

		transGradient = FlxGradient.createGradientFlxSprite(1, height, (isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0]));
		transGradient.scale.x = width;
		transGradient.updateHitbox();
		transGradient.scrollFactor.set();
		transGradient.screenCenter(X);
		add(transGradient);

		transBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		transBlack.scale.set(width, height + 400);
		transBlack.updateHitbox();
		transBlack.scrollFactor.set();
		transBlack.screenCenter(X);
		add(transBlack);

		if (isTransIn)
			transGradient.y = transBlack.y - transBlack.height;
		else
			transGradient.y = -transGradient.height;

		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (transGradient == null || transBlack == null) return;

		final zoom:Float = Math.max(camera != null ? camera.zoom : 1, 0.001);
		final height:Float = FlxG.height * zoom;
		final targetPos:Float = transGradient.height + 50 * zoom;

		if (duration > 0)
			transGradient.y += (height + targetPos) * elapsed / duration;
		else
			transGradient.y = targetPos;

		if (isTransIn)
			transBlack.y = transGradient.y + transGradient.height;
		else
			transBlack.y = transGradient.y - transBlack.height;

		if (transGradient.y >= targetPos)
		{
			close();
		}
	}

	// Don't delete this
	override function close():Void
	{
		super.close();

		if (finishCallback != null)
		{
			var cb = finishCallback;
			finishCallback = null;
			cb();
		}
	}
}
