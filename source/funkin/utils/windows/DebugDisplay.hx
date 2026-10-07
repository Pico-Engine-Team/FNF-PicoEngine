package funkin.utils.windows;

// New Folder for Source Code
import funkin.states.PlayState;
import funkin.states.MusicBeatState;
import funkin.states.menus.MainMenuState;

import funkin.Preferences;
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

		if (Preferences.data.fpsDisplay != null)
		updateDebugType(Preferences.data.fpsDisplay);
			updateBackgroundAlpha(Preferences.data.debugDisplayBG);
	}

	public function updateBackgroundAlpha(value:Float):Void
	{
		if(value > 1)
			value *= 0.01;
		var alpha:Float = Math.max(0, Math.min(1, value));
		underlay.alpha = alpha;
		rightUnderlay.alpha = alpha;
	}
	var deltaTimeout:Float = 0.0;
	
	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000)
			times.shift();
			
		// prevents the overlay from updating every frame, why would you need to anyways @crowplexus
		if (deltaTimeout < 100)
		{
			deltaTimeout += deltaTime;
			return;
		}
		
		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
		updateText();
		if (Preferences.data.fpsDisplay == "FPS Only" || Preferences.data.fpsDisplay == "FPS and Memory") underlay.width = leftText.width + 3;
		else underlay.width = 370;
		underlay.height = leftText.height;

		rightUnderlay.width = rightText.width + 3;
		rightUnderlay.height = rightText.height;
		rightUnderlay.visible = rightText.visible;
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

		leftText.textColor = 0xFFFFFFFF;
		if (currentFPS < FlxG.drawFramerate * 0.5) leftText.textColor = 0xFFFF0000;
	}

	function updateLeftText() {
        var gpuStr:String = "";

        try {
            gpuStr = 'GPU: ${GL.getString(GL.RENDERER).split("/")[0]}';
        } catch (e) {
            gpuStr = "";
        }

        var ramText:String = 'RAM: ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)} (Peak: ${flixel.util.FlxStringUtil.formatBytes(memoryPeak)})';

        var ext = GL.getString(GL.EXTENSIONS);
        if (ext != null && ext.indexOf("GL_NVX_gpu_memory_info") != -1) {  // i don't have a AMD/Intel gpu to test this
            ramText += ' | VRAM: ${flixel.util.FlxStringUtil.formatBytes(get_vramMegas() * 1024)}';
        }

		switch(debugType)
		{
			case 'FPS Only':
				leftText.text = 'FPS: $currentFPS';
			case 'FPS and Memory':
				leftText.text = 'FPS: $currentFPS\nPico Engine v${MainMenuState.PicoVersion}\n${ramText}';
			case 'Everything':
				leftText.text = 'FPS: $currentFPS\nPico Engine v${MainMenuState.PicoVersion}\nState: ${Type.getClassName(Type.getClass(FlxG.state))}\n${ramText}\n${gpuStr}';
		}
	}

	function updateRightText() {
		if (Std.isOfType(FlxG.state, PlayState) && PlayState.chartingMode == true) {
			var curState = MusicBeatState.getState();
			@:privateAccess
			rightText.text = 'Chart info:\nStep: ${curState.curStep}\nBeat: ${curState.curBeat}\nSection: ${curState.curSection}\nBPM: ${Conductor.bpm}';
			rightText.visible = true;
		} else {
			rightText.visible = false;
		}
		rightUnderlay.x = rightText.x = Lib.current.stage.stageWidth - rightText.width - 20;
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

    function get_vramMegas():Float // some times works, some times does this: https://prnt.sc/CYl54ZKOvPN5
    {
        try {
            var total = new Int32Array(1);
            var free  = new Int32Array(1);

            GL.getIntegerv(totalVram, total);
            GL.getIntegerv(curAvailableVram, free);

            return (total[0] - free[0]);
        } catch (e) {}

        return -1;
    }
	
	var debugType:String = 'Disabled';
	public function updateDebugType(type:String):Void
	{
		updating = true;
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
		}
	}
}