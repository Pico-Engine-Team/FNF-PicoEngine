package funkin.play;

import funkin.play.Song;
import funkin.play.Rating;
import funkin.data.objects.game.note.data.Note;

typedef BPMChangeEvent ={
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	@:optional var stepCrochet:Float;
}

class Conductor
{
	public static var bpm(default, set):Float = 100;
	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4;
	public static var songPosition:Float = 0;
	public static var offset:Float = 0;
	public static var safeZoneOffset:Float = 0; // is calculated in create(), is safeFrames in milliseconds
	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public static function judgeNote(arr:Array<Rating>, diff:Float=0):Rating // die
	{
		if(arr == null || arr.length < 1)
			return null;

		var data:Array<Rating> = arr;
		for(i in 0...data.length-1) //skips last window (Shit)
		{
			var rating:Rating = data[i];
			if (rating != null && rating.hitWindow != null && diff <= rating.hitWindow)
				return data[i];
		}

		return data[data.length - 1];
	}

	public static function getCrotchetAtTime(time:Float){
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepCrochet*4;
	}

	public static function getBPMFromSeconds(time:Float){
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}
		if(bpmChangeMap != null)
		{
			for (i in 0...bpmChangeMap.length)
			{
				var ev = bpmChangeMap[i];
				if(ev != null && time >= ev.songTime)
					lastChange = ev;
			}
		}
		if(lastChange.stepCrochet == null || Math.isNaN(lastChange.stepCrochet) || lastChange.stepCrochet <= 0)
			lastChange.stepCrochet = calculateCrochet(lastChange.bpm > 0 ? lastChange.bpm : bpm) / 4;

		return lastChange;
	}

	public static function getBPMFromStep(step:Float){
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}
		if(bpmChangeMap != null)
		{
			for (i in 0...bpmChangeMap.length)
			{
				var ev = bpmChangeMap[i];
				if(ev != null && ev.stepTime <= step)
					lastChange = ev;
			}
		}
		if(lastChange.stepCrochet == null || Math.isNaN(lastChange.stepCrochet) || lastChange.stepCrochet <= 0)
			lastChange.stepCrochet = calculateCrochet(lastChange.bpm > 0 ? lastChange.bpm : bpm) / 4;

		return lastChange;
	}

	public static function beatToSeconds(beat:Float): Float{
		var step = beat * 4;
		var lastChange = getBPMFromStep(step);
		var b:Float = lastChange.bpm;
		if(b == null || Math.isNaN(b) || b <= 0) b = bpm > 0 ? bpm : 100;
		return lastChange.songTime + ((step - lastChange.stepTime) / (b / 60)/4) * 1000;
	}

	public static function getStep(time:Float){
		var lastChange = getBPMFromSeconds(time);
		var sc:Float = lastChange.stepCrochet;
		if(sc == null || Math.isNaN(sc) || sc == 0) sc = stepCrochet != 0 ? stepCrochet : 150;
		return lastChange.stepTime + (time - lastChange.songTime) / sc;
	}

	public static function getStepRounded(time:Float){
		var lastChange = getBPMFromSeconds(time);
		var sc:Float = lastChange.stepCrochet;
		if(sc == null || Math.isNaN(sc) || sc == 0) sc = stepCrochet != 0 ? stepCrochet : 150;
		return lastChange.stepTime + Math.floor(time - lastChange.songTime) / sc;
	}

	public static function getBeat(time:Float){
		return getStep(time)/4;
	}

	public static function getBeatRounded(time:Float):Int{
		return Math.floor(getStepRounded(time)/4);
	}

	public static function mapBPMChanges(song:SwagSong)
	{
		bpmChangeMap = [];
		if(song == null || song.notes == null) return;

		var curBPM:Float = (song.bpm == null || Math.isNaN(song.bpm) || song.bpm <= 0) ? bpm : song.bpm;
		if(curBPM <= 0) curBPM = 100;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length)
		{
			if(song.notes[i] == null) continue;
			if(song.notes[i].changeBPM && song.notes[i].bpm != null && song.notes[i].bpm > 0 && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					stepCrochet: calculateCrochet(curBPM)/4
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = Math.round(getSectionBeats(song, i) * 4);
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
		trace("new BPM map BUDDY " + bpmChangeMap);
	}

	static function getSectionBeats(song:SwagSong, section:Int)
	{
		var val:Null<Float> = null;
		if(song.notes[section] != null) val = song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}

	inline public static function calculateCrochet(bpm:Float){
		return (60/bpm)*1000;
	}

	public static function set_bpm(newBPM:Float):Float {
		var safe:Float = (newBPM == null || Math.isNaN(newBPM) || newBPM <= 0) ? 100 : newBPM;
		crochet = calculateCrochet(safe);
		stepCrochet = crochet / 4;
		// Assign once — Haxe stores without re-entering the setter from inside set_bpm
		return bpm = safe;
	}
}