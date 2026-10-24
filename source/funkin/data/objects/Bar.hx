package funkin.data.objects;

import flixel.math.FlxRect;

class Bar extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var leftBar:FlxSprite;
	public var rightBar:FlxSprite;

	public var valueFunction:Void->Float = null;
	public var percent(default, set):Float = 0;
	public var bounds:Dynamic = {min: 0, max: 1};
	public var leftToRight(default, set):Bool = true;

	public var barCenter(default, null):Float = 0;
	public var barWidth(default, set):Int = 1;
	public var barHeight(default, set):Int = 1;
	public var barOffset:FlxPoint = new FlxPoint(3, 3);

	public function new(x:Float, y:Float, image:String = 'ui/healthBar', valueFunction:Void->Float = null, boundX:Float = 0, boundY:Float = 1)
	{
		super(x, y);

		this.valueFunction = valueFunction;
		setBounds(boundX, boundY);

		var aa:Bool = true;
		try
		{
			if (Preferences.data != null)
				aa = Preferences.data.antialiasing;
		}
		catch (e:Dynamic) {}

		var graphic = null;
		try graphic = Paths.image(image) catch (e:Dynamic) {}
		bg = new FlxSprite();
		if (graphic != null)
			bg.loadGraphic(graphic);
		else
			bg.makeGraphic(600, 20, 0xFF000000);
		bg.antialiasing = aa;
		barWidth = Std.int(Math.max(1, bg.width - 6));
		barHeight = Std.int(Math.max(1, bg.height - 6));

		leftBar = new FlxSprite().makeGraphic(Std.int(Math.max(1, bg.width)), Std.int(Math.max(1, bg.height)), FlxColor.WHITE);
		leftBar.antialiasing = antialiasing = aa;

		rightBar = new FlxSprite().makeGraphic(Std.int(Math.max(1, bg.width)), Std.int(Math.max(1, bg.height)), FlxColor.WHITE);
		rightBar.color = FlxColor.BLACK;
		rightBar.antialiasing = aa;

		add(leftBar);
		add(rightBar);
		add(bg);
		regenerateClips();
	}

	public var enabled:Bool = true;
	override function update(elapsed:Float)
	{
		if (!enabled)
		{
			super.update(elapsed);
			return;
		}

		if (valueFunction != null)
		{
			var raw:Float = 0;
			try raw = valueFunction() catch (e:Dynamic) raw = 0;
			if (Math.isNaN(raw)) raw = 0;

			var min:Float = bounds.min;
			var max:Float = bounds.max;
			if (max == min) max = min + 1;

			var value:Float = FlxMath.remapToRange(FlxMath.bound(raw, min, max), min, max, 0, 100);
			percent = value;
		}
		else
		{
			percent = 0;
		}
		super.update(elapsed);
	}

	public function setBounds(min:Float, max:Float)
	{
		if (bounds == null) bounds = {min: 0, max: 1};
		bounds.min = min;
		bounds.max = max;
	}

	public function setColors(left:FlxColor = null, right:FlxColor = null)
	{
		if (left != null && leftBar != null)
			leftBar.color = left;
		if (right != null && rightBar != null)
			rightBar.color = right;
	}

	public function updateBar()
	{
		if (leftBar == null || rightBar == null || bg == null) return;

		leftBar.setPosition(bg.x, bg.y);
		rightBar.setPosition(bg.x, bg.y);

		var leftSize:Float = 0;
		if (leftToRight)
			leftSize = FlxMath.lerp(0, barWidth, percent / 100);
		else
			leftSize = FlxMath.lerp(0, barWidth, 1 - percent / 100);

		if (leftBar.clipRect == null)
			leftBar.clipRect = new FlxRect(0, 0, barWidth, barHeight);
		if (rightBar.clipRect == null)
			rightBar.clipRect = new FlxRect(0, 0, barWidth, barHeight);

		leftBar.clipRect.width = leftSize;
		leftBar.clipRect.height = barHeight;
		leftBar.clipRect.x = barOffset.x;
		leftBar.clipRect.y = barOffset.y;

		rightBar.clipRect.width = barWidth - leftSize;
		rightBar.clipRect.height = barHeight;
		rightBar.clipRect.x = barOffset.x + leftSize;
		rightBar.clipRect.y = barOffset.y;

		barCenter = leftBar.x + leftSize + barOffset.x;

		// Re-assign so Flixel picks up the change
		leftBar.clipRect = leftBar.clipRect;
		rightBar.clipRect = rightBar.clipRect;
	}

	public function regenerateClips()
	{
		if (bg == null) return;

		if (leftBar != null)
		{
			leftBar.setGraphicSize(Std.int(Math.max(1, bg.width)), Std.int(Math.max(1, bg.height)));
			leftBar.updateHitbox();
			leftBar.clipRect = new FlxRect(0, 0, Std.int(Math.max(1, bg.width)), Std.int(Math.max(1, bg.height)));
		}
		if (rightBar != null)
		{
			rightBar.setGraphicSize(Std.int(Math.max(1, bg.width)), Std.int(Math.max(1, bg.height)));
			rightBar.updateHitbox();
			rightBar.clipRect = new FlxRect(0, 0, Std.int(Math.max(1, bg.width)), Std.int(Math.max(1, bg.height)));
		}
		updateBar();
	}

	private function set_percent(value:Float)
	{
		if (Math.isNaN(value)) value = 0;
		var doUpdate:Bool = (value != percent);
		percent = value;
		if (doUpdate) updateBar();
		return value;
	}

	private function set_leftToRight(value:Bool)
	{
		leftToRight = value;
		updateBar();
		return value;
	}

	private function set_barWidth(value:Int)
	{
		barWidth = value < 1 ? 1 : value;
		regenerateClips();
		return barWidth;
	}

	private function set_barHeight(value:Int)
	{
		barHeight = value < 1 ? 1 : value;
		regenerateClips();
		return barHeight;
	}
}
