package funkin.stages.data.week1;

import funkin.stages.objects.levels.week1.*;
import funkin.data.objects.game.characters.Character;

class StageWeek1 extends BaseStage
{
	static inline var WEEK_ASSET_FOLDER:String = 'week1';
	static inline var STAGE_ASSET_PATH:String = 'stages/weeks/week1';

	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleFog:DadBattleFog;
	override function create()
	{
		var bg:BGSprite = new BGSprite('', -600, -200, 0.9, 0.9);
		bg.loadGraphic(Paths.image('$STAGE_ASSET_PATH/stageback'));
		add(bg);

		var stageFront:BGSprite = new BGSprite('', -650, 600, 0.9, 0.9);
		stageFront.loadGraphic(Paths.image('$STAGE_ASSET_PATH/stagefront'));
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		add(stageFront);

		if(!Preferences.isLowQuality)
		{
			var stageLight:BGSprite = new BGSprite('', -125, -100, 0.9, 0.9);
			stageLight.loadGraphic(Paths.image('stage_light', WEEK_ASSET_FOLDER));
			stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
			stageLight.updateHitbox();
			add(stageLight);
			var stageLight:BGSprite = new BGSprite('', 1225, -100, 0.9, 0.9);
			stageLight.loadGraphic(Paths.image('stage_light', WEEK_ASSET_FOLDER));
			stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
			stageLight.updateHitbox();
			stageLight.flipX = true;
			add(stageLight);

			var stageCurtains:BGSprite = new BGSprite('', -500, -300, 1.3, 1.3);
			stageCurtains.loadGraphic(Paths.image('$STAGE_ASSET_PATH/stagecurtains'));
			stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
			stageCurtains.updateHitbox();
			add(stageCurtains);
		}
	}

	override function eventPushed(event:funkin.data.objects.game.notes.data.Note.EventNote)
	{
		switch(event.event)
		{
			case "Dadbattle Spotlight":
				dadbattleBlack = new BGSprite('', -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				add(dadbattleBlack);

				dadbattleLight = new BGSprite('', 400, -400);
				dadbattleLight.loadGraphic(Paths.image('spotlight', WEEK_ASSET_FOLDER));
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;
				add(dadbattleLight);

				dadbattleFog = new DadBattleFog();
				dadbattleFog.visible = false;
				add(dadbattleFog);
		}
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case "Dadbattle Spotlight":
				if(flValue1 == null) flValue1 = 0;
				var val:Int = Math.round(flValue1);

				switch(val)
				{
					case 1, 2, 3: //enable and target dad
						if(val == 1) //enable
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleFog.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if(val > 2) who = boyfriend;
						//2 only targets dad
						dadbattleLight.alpha = 0;
						new FlxTimer().start(0.12, function(tmr:FlxTimer) {
							dadbattleLight.alpha = 0.375;
						});
						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);
						FlxTween.tween(dadbattleFog, {alpha: 0.7}, 1.5, {ease: FlxEase.quadInOut});

					default:
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= 0.12;
						FlxTween.tween(dadbattleFog, {alpha: 0}, 0.7, {onComplete: function(twn:FlxTween) dadbattleFog.visible = false});
			}
		}
	}
}