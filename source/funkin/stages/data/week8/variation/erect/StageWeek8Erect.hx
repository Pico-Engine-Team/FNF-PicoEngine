package funkin.stages;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxColor;

/**
 * Basement Erect stage logic (source-code version).
 * JSON data: assets/data/stages/basement-erect.json
 *
 * Call from PlayState after stage objects are loaded:
 *   BasementErectStage.init();
 * And each frame:
 *   BasementErectStage.update(elapsed);
 */
class StageWeek8Erect
{
	static var mist0:FlxBackdrop;
	static var mist1:FlxBackdrop;
	static var mist2:FlxBackdrop;
	static var mist3:FlxBackdrop;
	static var mist4:FlxBackdrop;
	static var mist5:FlxBackdrop;

	static var mistOffset:Float = 0;
	static var mistColor:Int = 0xFF114A17;
	static var timer:Float = 0;
	static var inited:Bool = false;

	public static function init():Void
	{
		if (inited) return;
		inited = true;
		timer = 0;
		applySongProps();
		createMist();
	}

	public static function reset():Void
	{
		inited = false;
		destroyMist();
	}

	public static function update(elapsed:Float):Void
	{
		if (!inited) return;
		timer += elapsed;

		if (mist0 != null) mist0.y = 660 + (Math.sin(timer * 0.35) * 70) + mistOffset;
		if (mist1 != null) mist1.y = 500 + (Math.sin(timer * 0.3) * 80) + mistOffset;
		if (mist2 != null) mist2.y = 540 + (Math.sin(timer * 0.4) * 60) + mistOffset;
		if (mist3 != null) mist3.y = 230 + (Math.sin(timer * 0.3) * 70) + mistOffset;
		if (mist4 != null) mist4.y = 170 + (Math.sin(timer * 0.35) * 50) + mistOffset;
		if (mist5 != null) mist5.y = -80 + (Math.sin(timer * 0.08) * 100) + mistOffset;

		if (mist0 != null) { mist0.alpha = 0.6; mist0.color = mistColor; }
		if (mist1 != null) { mist1.alpha = 0.6; mist1.color = mistColor; }
		if (mist2 != null) { mist2.alpha = 0.8; mist2.color = mistColor; }
		if (mist3 != null) { mist3.alpha = 0.5; mist3.color = mistColor; }
		if (mist4 != null) { mist4.alpha = 1; mist4.color = mistColor; }
		if (mist5 != null) { mist5.alpha = 1; mist5.color = mistColor; }
	}

	static function getProp(name:String):FlxSprite
	{
		if (PlayState.instance == null) return null;
		if (PlayState.instance.stageObjects != null && PlayState.instance.stageObjects.exists(name))
			return PlayState.instance.stageObjects.get(name);
		return null;
	}

	static function setPropVisible(name:String, vis:Bool):Void
	{
		var spr = getProp(name);
		if (spr != null) spr.visible = vis;
	}

	static function playPropAnim(name:String, anim:String, force:Bool = true):Void
	{
		var spr = getProp(name);
		if (spr == null || spr.animation == null) return;
		if (spr.animation.exists(anim))
			spr.animation.play(anim, force);
	}

	public static function applySongProps():Void
	{
		var songId:String = resolveSongId();
		switch (songId)
		{
			case 'doomsday':
				playPropAnim('tvs bg', 'idle-alt');
				setPropVisible('heart monitor pulse', false);
			case 'pumpkin-delight', 'pumpkin_delight':
				playPropAnim('tvs bg', 'idle-monster');
				setPropVisible('heart monitor pulse', true);
			default:
				playPropAnim('tvs bg', 'idle');
				setPropVisible('heart monitor pulse', true);
		}
	}

	static function resolveSongId():String
	{
		var songId:String = '';
		if (PlayState.SONG != null)
		{
			if (PlayState.SONG.song != null)
				songId = Std.string(PlayState.SONG.song).toLowerCase();
			try
			{
				if (Reflect.hasField(PlayState.SONG, 'songFileName') && Reflect.field(PlayState.SONG, 'songFileName') != null)
					songId = Std.string(Reflect.field(PlayState.SONG, 'songFileName')).toLowerCase();
			}
			catch (e:Dynamic) {}
		}
		return StringTools.replace(songId, ' ', '-');
	}

	static function createMist():Void
	{
		mist0 = makeMist('stages/mistMid', 1.2, 0.6, 172);
		mist1 = makeMist('stages/mistMid', 1.1, 0.6, 150);
		mist2 = makeMist('stages/mistBack', 1.2, 0.8, -80);
		mist3 = makeMist('stages/mistMid', 0.95, 0.5, -50, 0.8);
		mist4 = makeMist('stages/mistBack', 0.8, 1.0, 40, 0.7);
		mist5 = makeMist('stages/mistMid', 0.5, 1.0, 20, 1.1);
	}

	static function makeMist(img:String, scroll:Float, alpha:Float, velX:Float, scaleMul:Float = 1):FlxBackdrop
	{
		var mist:FlxBackdrop = null;
		try
		{
			mist = new FlxBackdrop(Paths.image(img), 0x01);
			mist.setPosition(-650, -100);
			mist.scrollFactor.set(scroll, scroll);
			mist.alpha = alpha;
			mist.color = mistColor;
			mist.velocity.x = velX;
			if (scaleMul != 1)
				mist.scale.set(scaleMul, scaleMul);
			if (PlayState.instance != null)
				PlayState.instance.add(mist);
		}
		catch (e:Dynamic)
		{
			trace('[BasementErectStage] mist asset missing: ' + img + ' — ' + e);
		}
		return mist;
	}

	static function destroyMist():Void
	{
		for (m in [mist0, mist1, mist2, mist3, mist4, mist5])
		{
			if (m != null)
			{
				m.kill();
				if (PlayState.instance != null)
					PlayState.instance.remove(m);
				m.destroy();
			}
		}
		mist0 = mist1 = mist2 = mist3 = mist4 = mist5 = null;
	}
}
