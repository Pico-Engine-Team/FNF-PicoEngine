package funkin.substates;

import funkin.data.objects.AttachedText;
import funkin.data.objects.CheckboxThingie;
import funkin.states.options.config.*;
import funkin.states.options.config.Option.OptionType;

using StringTools;

class GameplayChangersSubState extends MusicBeatSubstate
{
	private var curSelected:Int = 0;
	private var optionsArray:Array<Dynamic> = [];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

	private var curOption(get, never):GameplayOption;
	function get_curOption()
	{
		if (optionsArray == null || optionsArray.length < 1) return null;
		if (curSelected < 0) curSelected = 0;
		if (curSelected >= optionsArray.length) curSelected = optionsArray.length - 1;
		return optionsArray[curSelected];
	}

	function getOptions()
	{
		var goption:GameplayOption = new GameplayOption('Scroll Type', 'scrolltype', STRING, 'multiplicative', ["multiplicative", "constant"]);
		optionsArray.push(goption);

		var option:GameplayOption = new GameplayOption('Scroll Speed', 'scrollspeed', FLOAT, 1);
		option.scrollSpeed = 2.0;
		option.minValue = 0;
		option.changeValue = 0.05;
		option.decimals = 2;
		var scrollType:Dynamic = null;
		try { scrollType = goption.getValue(); } catch (e:Dynamic) { scrollType = 'multiplicative'; }
		if (scrollType != "constant")
		{
			option.displayFormat = '%vX';
			option.maxValue = 3;
		}
		else
		{
			option.displayFormat = "%v";
			option.maxValue = 6;
		}
		optionsArray.push(option);

		#if FLX_PITCH
		var option:GameplayOption = new GameplayOption('Playback Rate', 'songspeed', FLOAT, 1);
		option.scrollSpeed = 1;
		option.minValue = 0.5;
		option.maxValue = 3.0;
		option.changeValue = 0.05;
		option.displayFormat = '%vX';
		option.decimals = 2;
		optionsArray.push(option);
		#end

		var option:GameplayOption = new GameplayOption('Health Gain Multiplier', 'healthgain', FLOAT, 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Loss Multiplier', 'healthloss', FLOAT, 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0.5;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		optionsArray.push(new GameplayOption('Instakill on Miss', 'instakill', BOOL, false));
		optionsArray.push(new GameplayOption('Practice Mode', 'practice', BOOL, false));
		optionsArray.push(new GameplayOption('Botplay', 'botplay', BOOL, false));
	}

	public function getOptionByName(name:String)
	{
		if (name == null) return null;
		for (i in optionsArray)
		{
			var opt:GameplayOption = i;
			if (opt != null && opt.name == name)
				return opt;
		}
		return null;
	}

	public function new() {
		super();
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		add(checkboxGroup);

		getOptions();

		for (i in 0...optionsArray.length)
		{
			var optionText:Alphabet = new Alphabet(150, 360, optionsArray[i].name, true);
			optionText.isMenuItem = true;
			optionText.setScale(0.8);
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (optionsArray[i].type == BOOL)
			{
				optionText.x += 60;
				optionText.startPosition.x += 60;
				optionText.snapToPosition();
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, optionsArray[i].getValue() == true);
				checkbox.sprTracker = optionText;
				checkbox.offsetX -= 20;
				checkbox.offsetY = -52;
				checkbox.ID = i;
				checkboxGroup.add(checkbox);
			}
			else
			{
				optionText.snapToPosition();
				var valueText:AttachedText = new AttachedText(Std.string(optionsArray[i].getValue()), optionText.width + 40, 0, true, 0.8);
				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;
				valueText.ID = i;
				grpTexts.add(valueText);
				optionsArray[i].setChild(valueText);
			}
			updateTextFrom(optionsArray[i]);
		}

		changeSelection();
		reloadCheckboxes();
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;
	override function update(elapsed:Float)
	{
		if (controls == null)
		{
			super.update(elapsed);
			return;
		}

		if (controls.UI_UP_P)
			changeSelection(-1);

		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.BACK)
		{
			close();
			try { Preferences.saveSettings(); } catch (e:Dynamic) {}
			try { FlxG.sound.play(Paths.sound('cancelMenu')); } catch (e:Dynamic) {}
		}

		if (nextAccept <= 0 && curOption != null)
		{
			var usesCheckbox:Bool = (curOption.type == BOOL);
			if (usesCheckbox)
			{
				if (controls.ACCEPT)
				{
					try { FlxG.sound.play(Paths.sound('scrollMenu')); } catch (e:Dynamic) {}
					curOption.setValue((curOption.getValue() == true) ? false : true);
					curOption.change();
					reloadCheckboxes();
				}
			}
			else
			{
				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
					if (holdTime > 0.5 || pressed)
					{
						if (pressed)
						{
							var add:Dynamic = null;
							if (curOption.type != STRING)
								add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;

							switch (curOption.type)
							{
								case INT, FLOAT, PERCENT:
									holdValue = curOption.getValue() + add;
									if (holdValue < curOption.minValue) holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

									switch (curOption.type)
									{
										case INT:
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);

										case FLOAT, PERCENT:
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);

										default:
									}

								case STRING:
									if (curOption.options == null || curOption.options.length < 1)
										return;
									var num:Int = curOption.curOption;
									if (controls.UI_LEFT_P) --num;
									else num++;

									if (num < 0)
										num = curOption.options.length - 1;
									else if (num >= curOption.options.length)
										num = 0;

									curOption.curOption = num;
									curOption.setValue(curOption.options[num]);

									if (curOption.name == "Scroll Type" || curOption.variable == 'scrolltype')
									{
										var oOption:GameplayOption = getOptionByName("Scroll Speed");
										if (oOption == null)
										{
											for (opt in optionsArray)
											{
												if (opt != null && opt.variable == 'scrollspeed')
												{
													oOption = opt;
													break;
												}
											}
										}
										if (oOption != null)
										{
											if (curOption.getValue() == "constant")
											{
												oOption.displayFormat = "%v";
												oOption.maxValue = 6;
											}
											else
											{
												oOption.displayFormat = "%vX";
												oOption.maxValue = 3;
												if (oOption.getValue() > 3) oOption.setValue(3);
											}
											updateTextFrom(oOption);
										}
									}

								default:
							}
							updateTextFrom(curOption);
							curOption.change();
							try { FlxG.sound.play(Paths.sound('scrollMenu')); } catch (e:Dynamic) {}
						}
						else if (curOption.type != STRING)
						{
							holdValue = Math.max(curOption.minValue, Math.min(curOption.maxValue, holdValue + curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1)));

							switch (curOption.type)
							{
								case INT:
									curOption.setValue(Math.round(holdValue));

								case FLOAT, PERCENT:
									var step:Float = curOption.changeValue;
									if (step == 0 || step != step) step = 0.01;
									var blah:Float = Math.max(curOption.minValue, Math.min(curOption.maxValue, holdValue + step - (holdValue % step)));
									curOption.setValue(FlxMath.roundDecimal(blah, curOption.decimals));

								default:
							}
							updateTextFrom(curOption);
							curOption.change();
						}
					}

					if (curOption.type != STRING)
						holdTime += elapsed;
				}
				else if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
					clearHold();
			}

			if (controls.RESET)
			{
				for (i in 0...optionsArray.length)
				{
					var leOption:GameplayOption = optionsArray[i];
					if (leOption == null) continue;
					leOption.setValue(leOption.defaultValue);
					if (leOption.type != BOOL)
					{
						if (leOption.type == STRING && leOption.options != null)
						{
							var idx:Int = leOption.options.indexOf(leOption.getValue());
							leOption.curOption = idx > -1 ? idx : 0;
						}

						updateTextFrom(leOption);
					}

					if (leOption.variable == 'scrollspeed' || leOption.name == 'Scroll Speed')
					{
						var scrollTypeOpt:GameplayOption = null;
						for (opt in optionsArray)
						{
							if (opt != null && (opt.variable == 'scrolltype' || opt.name == 'Scroll Type'))
							{
								scrollTypeOpt = opt;
								break;
							}
						}
						var isConstant:Bool = scrollTypeOpt != null && scrollTypeOpt.getValue() == 'constant';
						if (isConstant)
						{
							leOption.displayFormat = "%v";
							leOption.maxValue = 6;
						}
						else
						{
							leOption.displayFormat = "%vX";
							leOption.maxValue = 3;
							if (leOption.getValue() > 3)
								leOption.setValue(3);
						}
						updateTextFrom(leOption);
					}
					leOption.change();
				}
				try { FlxG.sound.play(Paths.sound('cancelMenu')); } catch (e:Dynamic) {}
				reloadCheckboxes();
			}
		}

		if (nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	function updateTextFrom(option:GameplayOption) {
		if (option == null) return;
		var text:String = option.displayFormat != null ? option.displayFormat : '%v';
		var val:Dynamic = option.getValue();
		if (option.type == PERCENT && val != null) val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', Std.string(val)).replace('%d', Std.string(def));
	}

	function clearHold()
	{
		if (holdTime > 0.5)
			try { FlxG.sound.play(Paths.sound('scrollMenu')); } catch (e:Dynamic) {}

		holdTime = 0;
	}

	function changeSelection(change:Int = 0)
	{
		if (optionsArray == null || optionsArray.length < 1) return;
		curSelected = FlxMath.wrap(curSelected + change, 0, optionsArray.length - 1);
		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			if (item.targetY == 0)
				item.alpha = 1;
		}
		for (text in grpTexts)
		{
			text.alpha = 0.6;
			if (text.ID == curSelected)
				text.alpha = 1;
		}
		try { FlxG.sound.play(Paths.sound('scrollMenu')); } catch (e:Dynamic) {}
	}

	function reloadCheckboxes() {
		for (checkbox in checkboxGroup) {
			if (checkbox == null || checkbox.ID < 0 || checkbox.ID >= optionsArray.length) continue;
			var opt:GameplayOption = optionsArray[checkbox.ID];
			checkbox.daValue = (opt != null && opt.getValue() == true);
		}
	}
}

class GameplayOption
{
	private var child:Alphabet;
	public var text(get, set):String;
	public var onChange:Void->Void = null;
	public var type:OptionType = BOOL;

	public var showBoyfriend:Bool = false;
	public var scrollSpeed:Float = 50;

	private var variable:String = null;
	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0;
	public var options:Array<String> = null;
	public var changeValue:Dynamic = 1;
	public var minValue:Dynamic = null;
	public var maxValue:Dynamic = null;
	public var decimals:Int = 1;

	public var displayFormat:String = '%v';
	public var name:String = 'Unknown';

	public function new(name:String, variable:String, type:OptionType, defaultValue:Dynamic = 'null variable value', ?options:Array<String> = null)
	{
		_name = name;
		try
		{
			this.name = Language.getPhrase('setting_$name', name);
		}
		catch (e:Dynamic)
		{
			this.name = name;
		}
		this.variable = variable;
		this.type = type;
		this.defaultValue = defaultValue;
		this.options = options;

		if (defaultValue == 'null variable value')
		{
			switch (type)
			{
				case BOOL:
					defaultValue = false;
				case INT, FLOAT:
					defaultValue = 0;
				case PERCENT:
					defaultValue = 1;
				case STRING:
					defaultValue = '';
					if (options != null && options.length > 0)
						defaultValue = options[0];

				default:
			}
			this.defaultValue = defaultValue;
		}

		if (getValue() == null)
			setValue(defaultValue);

		switch (type)
		{
			case STRING:
				if (options != null)
				{
					var num:Int = options.indexOf(getValue());
					if (num > -1)
						curOption = num;
				}

			case PERCENT:
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;

			default:
		}
	}

	public function change()
	{
		if (onChange != null)
			onChange();
	}

	public function getValue():Dynamic
	{
		try
		{
			if (Preferences.data == null || Preferences.data.gameplaySettings == null || variable == null)
				return defaultValue;
			return Preferences.data.gameplaySettings.get(variable);
		}
		catch (e:Dynamic)
		{
			return defaultValue;
		}
	}

	public function setValue(value:Dynamic)
	{
		try
		{
			if (Preferences.data == null) return;
			if (Preferences.data.gameplaySettings == null)
				Preferences.data.gameplaySettings = new Map<String, Dynamic>();
			if (variable != null)
				Preferences.data.gameplaySettings.set(variable, value);
		}
		catch (e:Dynamic) {}
	}

	public function setChild(child:Alphabet)
		this.child = child;

	var _name:String = null;
	var _text:String = null;
	private function get_text()
		return _text;

	private function set_text(newValue:String = '')
	{
		if (child != null)
		{
			_text = newValue;
			try
			{
				child.text = Language.getPhrase('setting_$_name-$_text', _text);
			}
			catch (e:Dynamic)
			{
				child.text = _text;
			}
			return _text;
		}
		return null;
	}
}
