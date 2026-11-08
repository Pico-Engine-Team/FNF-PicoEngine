package funkin.stages.data.weekspecial.engine.mods;

class ExeClassic extends BaseStage
{
    var fireLeft:FlxSprite;
    var fireRight:FlxSprite;
     override function create()
    {
        var bg:BGSprite = new BGSprite('mariomadness/stagefront', -1000, -850);
        add(bg);

        var ground:BGSprite = new BGSprite('mariomadness/stageback', -1000, -850);
        add(ground);

        var trees:BGSprite = new BGSprite('mariomadness/stagetrees', -1000, -850);
        add(trees);

        var vignette:BGSprite = new BGSprite('mariomadness/smoke', 0, 0);
        add(vignette);

		fireLeft = new FlxSprite(-1200, 550);
		fireLeft.frames = Paths.getSparrowAtlas('mariomadness/fire');
		fireLeft.animation.addByPrefix("anim", "fire anim effects", 24);
        fireLeft.scale.set(0.7, 0.7);
        fireLeft.scrollFactor.set(0.6, 0.6);
		add(fireLeft);

        fireRight = new FlxSprite(1000, 550);
		fireRight.frames = Paths.getSparrowAtlas('mariomadness/fire');
		fireRight.animation.addByPrefix("anim", "fire anim effects", 24);
        fireRight.scale.set(0.7, 0.7);
        fireRight.scrollFactor.set(0.6, 0.6);
		add(fireRight);
    }
}