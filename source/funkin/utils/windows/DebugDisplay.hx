package funkin.utils.windows;

import funkin.states.PlayState;
import funkin.states.MusicBeatState;
import funkin.states.menus.MainMenuState;

import funkin.data.Preferences;
import funkin.play.Conductor;

import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.display.Sprite;

import lime.graphics.opengl.GL;
import lime.utils.Int32Array;
import flixel.FlxG;

class DebugDisplay extends Sprite
{
	var updating:Bool = true;
	var leftText:TextField;
	var rightText:TextField;
	var underlay:Bitmap;
	var rightUnderlay:Bitmap;

	public var currentFPS(default, null):Int;
	public var memoryMegas(get, never):Float;
	public var memoryPeak:Float = 0;

	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		underlay = new Bitmap();
		underlay.bitmapData = new BitmapData(1, 1, true, 0xFF000000);
		addChild(underlay);

		rightUnderlay = new Bitmap();
		rightUnderlay.bitmapData = new BitmapData(1, 1, true, 0xFF000000);
		addChild(rightUnderlay);

		leftText = new TextField();
		addChild(leftText);

		currentFPS = 0;
		leftText.selectable = false;
		leftText.mouseEnabled = false;
		leftText.defaultTextFormat = new TextFormat("Monsterrat", 14, color);
		leftText.autoSize = LEFT;
		leftText.multiline = true;
		leftText.text = "FPS: ";

		rightText = new TextField();
		addChild(rightText);

		rightText.selectable = false;
		rightText.mouseEnabled = false;
		rightText.defaultTextFormat = new TextFormat("Monsterrat", 14, color);
		rightText.autoSize = LEFT;
		rightText.multiline = true;
		rightText.text = "Chart info: ";

		rightText.visible = false;
		rightUnderlay.visible = false;
		times = [];
		FlxG.signals.postStateSwitch.add(() -> updateText = __updateTxt);

		try
		{
			if (Preferences.data != null)
			{
				if (Preferences.data.fpsDisplay != null)
					updateDebugType(Preferences.data.fpsDisplay);
				updateBackgroundAlpha(Preferences.data.debugDisplayBG);
			}
		}
		catch (e:Dynamic) {}
	}

	public function updateBackgroundAlpha(value:Float):Void
	{
		if (value > 1)
			value *= 0.01;
		var alpha:Float = Math.max(0, Math.min(1, value));
		if (underlay != null) underlay.alpha = alpha;
		if (rightUnderlay != null) rightUnderlay.alpha = alpha;
	}

	var deltaTimeout:Float = 0.0;

	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times.length > 0 && times[0] < now - 1000)
			times.shift();

		// prevents the overlay from updating every frame
		if (deltaTimeout < 100)
		{
			deltaTimeout += deltaTime;
			return;
		}

		var targetFps:Int = Std.int(Math.max(1, FlxG.updateFramerate));
		currentFPS = times.length < targetFps ? times.length : targetFps;
		updateText();

		if (underlay != null && leftText != null)
		{
			if (Preferences.data != null && (Preferences.data.fpsDisplay == "FPS Only" || Preferences.data.fpsDisplay == "FPS and Memory"))
				underlay.width = leftText.width + 3;
			else
				underlay.width = 370;
			underlay.height = leftText.height;
		}

		if (rightUnderlay != null && rightText != null)
		{
			rightUnderlay.width = rightText.width + 3;
			rightUnderlay.height = rightText.height;
			rightUnderlay.visible = rightText.visible;
		}
		deltaTimeout = 0.0;
	}

	dynamic function updateText():Void
	{
		__updateTxt();
	}

	function __updateTxt()
	{
		if (!updating) return;
		if (memoryMegas > memoryPeak) memoryPeak = memoryMegas;

		updateLeftText();
		updateRightText();

		if (leftText != null)
		{
			leftText.textColor = 0xFFFFFFFF;
			if (currentFPS < FlxG.drawFramerate * 0.5)
				leftText.textColor = 0xFFFF0000;
		}
	}

	function updateLeftText()
	{
		if (leftText == null) return;

		var gpuStr:String = "";
		try
		{
			var renderer = GL.getString(GL.RENDERER);
			if (renderer != null)
				gpuStr = 'GPU: ${renderer.split("/")[0]}';
		}
		catch (e:Dynamic)
		{
			gpuStr = "";
		}

		var ramText:String = 'RAM: ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)} (Peak: ${flixel.util.FlxStringUtil.formatBytes(memoryPeak)})';

		try
		{
			var ext = GL.getString(GL.EXTENSIONS);
			if (ext != null && ext.indexOf("GL_NVX_gpu_memory_info") != -1)
			{
				var vram = get_vramMegas();
				if (vram >= 0)
					ramText += ' | VRAM: ${flixel.util.FlxStringUtil.formatBytes(vram * 1024)}';
			}
		}
		catch (e:Dynamic) {}

		var version:String = '';
		try
		{
			if (MainMenuState.PicoVersion != null)
				version = MainMenuState.PicoVersion;
		}
		catch (e:Dynamic) {}

		var stateName:String = '';
		try
		{
			if (FlxG.state != null)
				stateName = Type.getClassName(Type.getClass(FlxG.state));
		}
		catch (e:Dynamic) {}

		switch (debugType)
		{
			case 'FPS Only':
				leftText.text = 'FPS: $currentFPS';
			case 'FPS and Memory':
				leftText.text = 'FPS: $currentFPS\nPico Engine v${version}\n${ramText}';
			case 'Everything':
				leftText.text = 'FPS: $currentFPS\nPico Engine v${version}\nState: ${stateName}\n${ramText}\n${gpuStr}';
			default:
				leftText.text = 'FPS: $currentFPS';
		}
	}

	function updateRightText()
	{
		if (rightText == null) return;

		try
		{
			if (Std.isOfType(FlxG.state, PlayState) && PlayState.chartingMode == true)
			{
				var curState = MusicBeatState.getState();
				@:privateAccess
				rightText.text = 'Chart info:\nStep: ${curState.curStep}\nBeat: ${curState.curBeat}\nSection: ${curState.curSection}\nBPM: ${Conductor.bpm}';
				rightText.visible = true;
			}
			else
			{
				rightText.visible = false;
			}
		}
		catch (e:Dynamic)
		{
			rightText.visible = false;
		}

		try
		{
			var stageW:Float = Lib.current != null && Lib.current.stage != null ? Lib.current.stage.stageWidth : FlxG.width;
			rightText.x = stageW - rightText.width - 20;
			if (rightUnderlay != null)
				rightUnderlay.x = rightText.x;
		}
		catch (e:Dynamic) {}
	}

	inline function get_memoryMegas():Float
	{
		#if cpp
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
		#elseif (openfl >= "9.4.0")
		return cast(openfl.system.System.totalMemoryNumber, UInt);
		#else
		return cast(openfl.system.System.totalMemory, UInt);
		#end
	}

	static inline var totalVram = 0x9048;
	static inline var curAvailableVram = 0x9049;

	function get_vramMegas():Float
	{
		try
		{
			var total = new Int32Array(1);
			var free = new Int32Array(1);

			GL.getIntegerv(totalVram, total);
			GL.getIntegerv(curAvailableVram, free);

			return (total[0] - free[0]);
		}
		catch (e:Dynamic) {}

		return -1;
	}

	var debugType:String = 'Disabled';
	public function updateDebugType(type:String):Void
	{
		updating = true;
		if (type == null) type = 'Disabled';
		switch (type)
		{
			case 'FPS Only':
				debugType = 'FPS Only';
			case 'FPS and Memory':
				debugType = 'FPS and Memory';
			case 'Everything':
				debugType = 'Everything';
			default:
				updating = false;
				debugType = 'Disabled';
		}
	}
}
