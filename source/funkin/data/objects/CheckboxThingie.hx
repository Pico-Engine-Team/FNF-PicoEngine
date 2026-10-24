package funkin.data.objects;

class CheckboxThingie extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var daValue(default, set):Bool;
	public var copyAlpha:Bool = true;
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public function new(x:Float = 0, y:Float = 0, ?checked = false)
	{
		super(x, y);

		var atlas = null;
		try atlas = Paths.getSparrowAtlas('menus/options_menu/Checkboxs_Thingie') catch (e:Dynamic) {}
		if (atlas == null)
		{
			try atlas = Paths.getSparrowAtlas('checkboxanim') catch (e:Dynamic) {}
		}
		if (atlas != null)
		{
			frames = atlas;
			animation.addByPrefix("unchecked", "checkbox0", 24, false);
			animation.addByPrefix("unchecking", "checkbox anim reverse", 24, false);
			animation.addByPrefix("checking", "checkbox anim0", 24, false);
			animation.addByPrefix("checked", "checkbox finish", 24, false);
		}
		else
		{
			makeGraphic(40, 40, 0xFF888888);
		}

		try
		{
			if (Preferences.data != null)
				antialiasing = Preferences.data.antialiasing;
		}
		catch (e:Dynamic) {}

		setGraphicSize(Std.int(0.9 * width));
		updateHitbox();

		animationFinished(checked ? 'checking' : 'unchecking');
		if (animation != null)
			animation.finishCallback = animationFinished;
		daValue = checked;
	}

	override function update(elapsed:Float)
	{
		if (sprTracker != null)
		{
			setPosition(sprTracker.x - 130 + offsetX, sprTracker.y + 30 + offsetY);
			if (copyAlpha)
				alpha = sprTracker.alpha;
		}
		super.update(elapsed);
	}

	private function set_daValue(check:Bool):Bool
	{
		if (animation == null || animation.curAnim == null)
		{
			// No atlas loaded — still store the value
			return check;
		}

		var curName:String = animation.curAnim.name;
		if (check)
		{
			if (curName != 'checked' && curName != 'checking')
			{
				animation.play('checking', true);
				offset.set(34, 25);
			}
		}
		else if (curName != 'unchecked' && curName != 'unchecking')
		{
			animation.play("unchecking", true);
			offset.set(25, 28);
		}
		return check;
	}

	private function animationFinished(name:String)
	{
		if (animation == null) return;
		switch (name)
		{
			case 'checking':
				animation.play('checked', true);
				offset.set(3, 12);
			case 'unchecking':
				animation.play('unchecked', true);
				offset.set(0, 2);
		}
	}
}
