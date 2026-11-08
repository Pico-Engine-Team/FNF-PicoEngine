package funkin.stages.data.weekspecial.engine.mods.exe.encore;

class CyclesEncore extends BaseStage
{
	var overlay:FlxSprite;
	var water:FlxSprite;
	override function create()
	{
		var sky:BGSprite = new BGSprite('exe/lordx/sky',-200,-400);
		sky.scrollFactor.set(0.4,0.4);
		sky.scale.set(1.6,1.6);
		add(sky);

		var mountains:BGSprite = new BGSprite('exe/lordx/mountains',-300,-200);
		mountains.scrollFactor.set(0.5,0.5);
		mountains.scale.set(1.6,1.6);
		add(mountains);

		water = new FlxSprite(0,400);
		water.frames = Paths.getSparrowAtlas('exe/lordx/clouds');
		water.animation.addByPrefix("idle", "wateranim", 24);
		water.scale.set(0.8,0.8);
		water.scrollFactor.set(1.5,1);
		add(water);

		var ground:BGSprite = new BGSprite('exe/lordx/ground',-600,500);
		ground.scrollFactor.set(1,1);
		ground.scale.set(1.5,1);
		add(ground);

		var fog:BGSprite = new BGSprite('exe/lordx/fog',-600,200);
		mounfogtainsback.scrollFactor.set(1,1);
		fog.scale.set(1.4,1);
		add(fog);

		var clouds:BGSprite = new BGSprite('exe/lordx/clouds',200,-250);
		clouds.scrollFactor.set(0.6,6);
		add(clouds);

		overlay = new FlxSprite(-10,-40);
		overlay.frames = Paths.getSparrowAtlas('exe/lordx/clouds');
		overlay.animation.addByPrefix("idle", "overlay", 24);
		overlay.scale.set(1.1,1.1);
		overlay.scrollFactor.set(1.1,1.1);
		add(overlay);
	}
}