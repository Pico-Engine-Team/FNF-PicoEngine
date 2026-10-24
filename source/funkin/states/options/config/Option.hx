package funkin.states.options.config;

typedef Keybind = {
	keyboard:String,
	gamepad:String
}

// Bool will use checkboxes, Everything else will use a text
enum OptionType {
	BOOL;
	INT;
	FLOAT;
	PERCENT;
	STRING;
	KEYBIND;
}

class Option
{
	public var child:Alphabet;
	public var text(get, set):String;
	public var onChange:Void->Void = null; //Pressed enter (on Bool type options) or pressed/held left/right (on other types)
	public var type:OptionType = BOOL;

	public var scrollSpeed:Float = 50; //Only works on int/float, defines how fast it scrolls per second while holding left/right
	public var variable(default, null):String = null; //Variable from Preferences.hx
	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0; //Don't change this
	public var options:Array<String> = null; //Only used in string type
	public var changeValue:Dynamic = 1; //Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic = null; //Only used in int/float/percent type
	public var maxValue:Dynamic = null; //Only used in int/float/percent type
	public var decimals:Int = 1; //Only used in float/percent type

	public var displayFormat:String = '%v'; //How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value
	public var description:String = '';
	public var name:String = 'Unknown';

	public var defaultKeys:Keybind = null; //Only used in keybind type
	public var keys:Keybind = null; //Only used in keybind type

	/** Resolve Preferences (new) or ClientPrefs (legacy) static data bag */
	static function prefsData():Dynamic
	{
		try
		{
			var p:Dynamic = Type.resolveClass('funkin.data.Preferences');
			if(p == null) p = Type.resolveClass('Preferences');
			if(p != null && Reflect.hasField(p, 'data'))
				return Reflect.field(p, 'data');
		}
		catch(e:Dynamic) {}
		try
		{
			var c:Dynamic = Type.resolveClass('funkin.data.ClientPrefs');
			if(c == null) c = Type.resolveClass('ClientPrefs');
			if(c != null && Reflect.hasField(c, 'data'))
				return Reflect.field(c, 'data');
		}
		catch(e:Dynamic) {}
		// Compile-time direct access (preferred when class is imported)
		try return Preferences.data catch(e:Dynamic) {}
		try return ClientPrefs.data catch(e:Dynamic) {}
		return null;
	}

	static function prefsDefaultData():Dynamic
	{
		try
		{
			var p:Dynamic = Type.resolveClass('funkin.data.Preferences');
			if(p == null) p = Type.resolveClass('Preferences');
			if(p != null && Reflect.hasField(p, 'defaultData'))
				return Reflect.field(p, 'defaultData');
		}
		catch(e:Dynamic) {}
		try
		{
			var c:Dynamic = Type.resolveClass('funkin.data.ClientPrefs');
			if(c == null) c = Type.resolveClass('ClientPrefs');
			if(c != null && Reflect.hasField(c, 'defaultData'))
				return Reflect.field(c, 'defaultData');
		}
		catch(e:Dynamic) {}
		try return Preferences.defaultData catch(e:Dynamic) {}
		try return ClientPrefs.defaultData catch(e:Dynamic) {}
		return null;
	}

	static function hasPrefField(obj:Dynamic, field:String):Bool
	{
		if(obj == null || field == null || field.length < 1) return false;
		try
		{
			if(Reflect.hasField(obj, field)) return true;
		}
		catch(e:Dynamic) {}
		// @:structInit / anonymous: hasField can be false even when property exists
		try
		{
			var fields = Reflect.fields(obj);
			if(fields != null && fields.indexOf(field) >= 0) return true;
		}
		catch(e:Dynamic) {}
		// Last resort: Type.getInstanceFields for class instances
		try
		{
			var cls = Type.getClass(obj);
			if(cls != null)
			{
				var inst = Type.getInstanceFields(cls);
				if(inst != null && inst.indexOf(field) >= 0) return true;
			}
		}
		catch(e:Dynamic) {}
		return false;
	}

	public function new(name:String, description:String = '', variable:String, type:OptionType = BOOL, ?options:Array<String> = null, ?translation:String = null)
	{
		_name = name;
		_translationKey = translation != null ? translation : _name;
		this.name = Language.getPhrase('setting_$_translationKey', name);
		this.description = Language.getPhrase('description_$_translationKey', description);
		this.variable = variable;
		this.type = type;
		this.options = options;

		if(this.type != KEYBIND)
		{
			var defs = prefsDefaultData();
			if(variable != null && defs != null && hasPrefField(defs, variable))
				this.defaultValue = Reflect.getProperty(defs, variable);
		}
		switch(type)
		{
			case BOOL:
				if(defaultValue == null) defaultValue = false;
			case INT, FLOAT:
				if(defaultValue == null) defaultValue = 0;
			case PERCENT:
				if(defaultValue == null) defaultValue = 1;
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;
			case STRING:
				if(options != null && options.length > 0)
					defaultValue = options[0];
				if(defaultValue == null)
					defaultValue = '';

			case KEYBIND:
				defaultValue = '';
				defaultKeys = {gamepad: 'NONE', keyboard: 'NONE'};
				keys = {gamepad: 'NONE', keyboard: 'NONE'};
		}

		try
		{
			if(getValue() == null)
				setValue(defaultValue);
	
			switch(type)
			{
				case STRING:
					if(options != null)
					{
						var num:Int = options.indexOf(getValue());
						if(num > -1) curOption = num;
					}

				default:
			}
		}
		catch(e) {}
	}

	public function change()
	{
		//nothing lol
		if(onChange != null)
			onChange();
	}

	dynamic public function getValue():Dynamic
	{
		if(variable == null || variable.length < 1) return defaultValue;
		var data = prefsData();
		if(data == null) return defaultValue;
		if(!hasPrefField(data, variable))
			return defaultValue;
		var value = Reflect.getProperty(data, variable);
		if(type == KEYBIND)
		{
			if(value == null) return 'NONE';
			var usePad:Bool = Controls.instance != null && Controls.instance.controllerMode;
			var key:Dynamic = usePad ? Reflect.field(value, 'gamepad') : Reflect.field(value, 'keyboard');
			return key != null ? key : 'NONE';
		}
		return value;
	}

	dynamic public function setValue(value:Dynamic)
	{
		if(variable == null || variable.length < 1) return value;
		var data = prefsData();
		if(data == null)
		{
			trace('[Option] Preferences/ClientPrefs data is null — cannot set ' + variable);
			return value;
		}
		if(!hasPrefField(data, variable))
		{
			// Try to create the field so the menu still works after renames / new options
			try
			{
				Reflect.setProperty(data, variable, value);
				return value;
			}
			catch(e:Dynamic)
			{
				trace('[Option] Missing Preferences.data field: ' + variable);
				return value;
			}
		}
		if(type == KEYBIND)
		{
			var keys:Dynamic = Reflect.getProperty(data, variable);
			if(keys == null)
			{
				keys = {keyboard: 'NONE', gamepad: 'NONE'};
				try Reflect.setProperty(data, variable, keys) catch(e:Dynamic) {}
			}
			if(Controls.instance != null && Controls.instance.controllerMode)
				Reflect.setField(keys, 'gamepad', value);
			else
				Reflect.setField(keys, 'keyboard', value);
			return value;
		}
		return Reflect.setProperty(data, variable, value);
	}

	var _name:String = null;
	var _text:String = null;
	var _translationKey:String = null;
	private function get_text()
		return _text;

	private function set_text(newValue:String = '')
	{
		if(child != null)
		{
			_text = newValue;
			child.text = Language.getPhrase('setting_$_translationKey-${getValue()}', _text);
			return _text;
		}
		return null;
	}
}
