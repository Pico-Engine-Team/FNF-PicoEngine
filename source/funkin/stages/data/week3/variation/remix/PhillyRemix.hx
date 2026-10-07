package funkin.stages.data.week3.variation.remix;

import funkin.data.objects.game.characters.Character;
import funkin.stages.objects.levels.week3.PhillyRemixLights;

class PhillyRemix extends BaseStage
{
	var lights:FlxSprite;
	var lightController:PhillyRemixLights;
	override function create()
	{
		PlayState.SONG.splashSkin = 'noteSplashes/noteSplashes-Godot';

		add(godotSprite('stages/week3/remix/sky', 641, 30, 0.1, 0.1));
		add(godotSprite('stages/week3/remix/city_2', 653, 315, 0.3, 0.3));
		add(godotSprite('stages/week3/remix/city_1', 629, 622, 0.45, 0.45));

		lights = godotSprite('stages/week3/remix/Lights', 592, 303, 0.45, 0.45);
		add(lights);
		lightController = new PhillyRemixLights(lights);

		add(godotSprite('stages/week3/remix/buildings_2', 431, 426, 0.65, 0.65));
		add(godotSprite('stages/week3/remix/buildings_1', 585, 66, 0.75, 0.75));
		add(godotSprite('stages/week3/remix/rooftop', 760, 766, 1, 1));

		var foreground:FlxSprite = godotSprite('stages/week3/remix/foreground', 496, 1256, 1.15, 1.15);
		foreground.y -= 85;
		add(foreground);

		var nene:Character = new Character(325, 702, 'nene-dot');
		nene.visible = (songName == 'blammed-remix');
		add(nene);

		var darnell:Character = new Character(830, 703, 'darnell-dot');
		darnell.visible = (songName == 'blammed-remix');
		add(darnell);

		lightController.setColor();
	}

	override function beatHit()
	{
		if(lightController != null)
			lightController.beatHit(curBeat);
	}

	override function destroy()
	{
		if(lightController != null)
			lightController.destroy();
		lightController = null;
		super.destroy();
	}

	function godotSprite(image:String, centerX:Float, centerY:Float, scrollX:Float = 1, scrollY:Float = 1):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.antialiasing = Preferences.data.antialiasing;
		spr.scrollFactor.set(scrollX, scrollY);
		spr.setPosition(centerX - spr.width * 0.5, centerY - spr.height * 0.5);
		return spr;
	}
}