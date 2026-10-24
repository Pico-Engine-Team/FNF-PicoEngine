package funkin.utils;

class TypedAlphabet extends Alphabet
{
	public var onFinish:Void->Void = null;
	public var finishedText:Bool = false;
	public var delay:Float = 0.05;
	public var sound:String = 'dialogue';
	public var volume:Float = 1;

	public function new(x:Float, y:Float, text:String = "", ?delay:Float = 0.05, ?bold:Bool = false)
	{
		super(x, y, text, bold);

		this.delay = delay > 0 ? delay : 0.05;
	}

	override private function set_text(newText:String)
	{
		super.set_text(newText);

		resetDialogue();
		return newText;
	}

	private var _curLetter:Int = -1;
	private var _timeToUpdate:Float = 0;
	override function update(elapsed:Float)
	{
		if (!finishedText && letters != null && letters.length > 0)
		{
			var playedSound:Bool = false;
			_timeToUpdate += elapsed;
			while (_timeToUpdate >= delay)
			{
				showCharacterUpTo(_curLetter + 1);
				if (!playedSound && sound != null && sound != '' && (delay > 0.025 || _curLetter % 2 == 0))
				{
					try
					{
						var s = Paths.sound(sound);
						if (s != null) FlxG.sound.play(s, volume);
					}
					catch (e:Dynamic) {}
				}
				playedSound = true;

				_curLetter++;
				if (_curLetter >= letters.length - 1)
				{
					finishedText = true;
					if (onFinish != null) onFinish();
					_timeToUpdate = 0;
					break;
				}
				_timeToUpdate = 0;
			}
		}

		super.update(elapsed);
	}

	public function showCharacterUpTo(upTo:Int)
	{
		if (letters == null) return;
		var start:Int = _curLetter;
		if (start < 0) start = 0;
		if (upTo >= letters.length) upTo = letters.length - 1;

		for (i in start...(upTo + 1))
		{
			if (letters[i] != null) letters[i].visible = true;
		}
	}

	public function resetDialogue()
	{
		_curLetter = -1;
		finishedText = false;
		_timeToUpdate = 0;
		if (letters != null)
		{
			for (letter in letters)
			{
				if (letter != null) letter.visible = false;
			}
		}
	}

	public function finishText()
	{
		if (finishedText) return;

		if (letters != null && letters.length > 0)
			showCharacterUpTo(letters.length - 1);

		if (sound != null && sound != '')
		{
			try
			{
				var s = Paths.sound(sound);
				if (s != null) FlxG.sound.play(s, volume);
			}
			catch (e:Dynamic) {}
		}
		finishedText = true;

		if (onFinish != null) onFinish();
		_timeToUpdate = 0;
	}
}
