package funkin.stages.data.weekspecial.engine.mods;

import funkin.data.shaders.RainShader;
import openfl.display.BlendMode;

class RonStage extends BaseStage
{
    var sky:BGSprite;
    var mountains:BGSprite;
    var mountainsback:BGSprite;
    var hillfront:BGSprite;
    var graadienter:FlxSprite;
    var street:BGSprite;
    var bgLol:BGSprite;
    var rainShader:RainShader;
	override function create()
    {
        sky = new BGSprite('ron/sky', -100, 20);
		sky.screenCenter();
		sky.scrollFactor.set(0.1, 0.1);
		add(sky);

	    mountainsback = new BGSprite('ron/mountainsback', -100, 20);
	    mountainsback.screenCenter();
        mountainsback.scrollFactor.set(0.3, 0.3);
		mountainsback.y -= 60;
	    add(mountainsback);

	    mountains = new BGSprite('ron/mountains', -100, 20);
		mountains.screenCenter();
	    mountains.scrollFactor.set(0.3, 0.3);
		mountains.y -= 60;
		add(mountains);

		hillfront = new BGSprite('ron/hillfront', -100, 20);
		hillfront.screenCenter();
	    hillfront.scrollFactor.set(0.4, 0.4);
	    hillfront.y -= 60;
		add(hillfront);

		graadienter = new FlxSprite(-100,10).loadGraphic(Paths.image('ron/gradient'));
	    graadienter.updateHitbox();
		graadienter.screenCenter();
		graadienter.active = false;
		graadienter.antialiasing = true;
		graadienter.visible = false;
		graadienter.blend = BlendMode.ADD;
		add(graadienter);

		street = new BGSprite('ron/street', -100, 40);
		street.screenCenter();
		add(street);

		bgLol = new BGSprite('ron/streetNoLight', -100, 40);
		bgLol.screenCenter();
		add(bgLol);

		if (Preferences.data.shaders)
		{
			rainShader = new RainShader();
			rainShader.scale = FlxG.height / 200;
			rainShader.intensity = 0.2;
			FlxG.camera.setFilters([new openfl.filters.ShaderFilter(rainShader)]);
		}
    }

	override function update(elapsed:Float)
	{
		if (rainShader != null)
		{
			rainShader.updateViewInfo(FlxG.width, FlxG.height, FlxG.camera);
			rainShader.update(elapsed);
		}
		super.update(elapsed);
	}
}
