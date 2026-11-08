package funkin.stages.data.weekspecial.engine.mods.exe.encore;

class CyclesEncore extends BaseStage
{
	var
	var
	override function create()
	{
		var sky:BGSprite = new BGSprite('exe/lordx/stagefront', -1100, -500);
		add(sky);

		var mountains:BGSprite = new BGSprite('exe/lordx/stageback', -1100, -500);
		add(mountains);

		var water:BGSprite = new BGSprite('exe/lordx/stageback', -1100, -500);
		add(water);

		var ground:BGSprite = new BGSprite('exe/lordx/stageback', -1100, -500);
		add(ground);

		var fog:BGSprite = new BGSprite('exe/lordx/stageback', -1100, -500);
		add(clouds);

		var bg:BGSprite = new BGSprite('exe/lordx/stageback', -1100, -500);
		add(clouds);

		overlay = new BGSprite('exe/lordx/stageback', -1100, -500);
		add(overlay);
	}
}