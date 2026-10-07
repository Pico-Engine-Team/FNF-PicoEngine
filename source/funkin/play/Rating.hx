package funkin.play;

class Rating
{
	public var name:String = '';
	public var image:String = '';
	public var hitWindow:Null<Float> = 0.0;
	public var ratingMod:Float = 1;
	public var score:Int = 350;
	public var noteSplash:Bool = true;
	public var hits:Int = 0;

	public function new(name:String)
	{
		this.name = name;
		this.image = name;
		this.hitWindow = defaultHitWindow(name);

		var window:String = name == 'marvelous' ? 'epicRankings' : name + 'Window';
		try
		{
			var rawWindow:Dynamic = Reflect.field(Preferences.data, window);
			if(rawWindow == null && name == 'marvelous')
				rawWindow = Reflect.field(Preferences.data, 'marvelousWindow');
			if(rawWindow != null)
			{
				var parsedWindow:Float = Std.parseFloat(Std.string(rawWindow));
				if(!Math.isNaN(parsedWindow))
					this.hitWindow = parsedWindow;
			}
		}
		catch(e) FlxG.log.error(e);
	}

	public static function loadDefault():Array<Rating>
	{
		var ratingsData:Array<Rating> = [];
		var rating:Rating;

		if(Preferences.data.useEpicRankings)
		{
			rating = new Rating('marvelous');
			rating.ratingMod = 1;
			rating.score = 500;
			rating.noteSplash = true;
			ratingsData.push(rating);
		}

		rating = new Rating('sick');
		rating.ratingMod = 1;
		rating.score = 350;
		rating.noteSplash = true;
		ratingsData.push(rating);

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.67;
		rating.score = 199;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.34;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);

		normalizeHitWindows(ratingsData);
		return ratingsData;
	}

	static function defaultHitWindow(name:String):Float
	{
		return switch(name)
		{
			case 'marvelous': 20.0;
			case 'sick': 45.0;
			case 'good': 90.0;
			case 'bad': 135.0;
			default: 0.0;
		}
	}

	static function normalizeHitWindows(ratingsData:Array<Rating>)
	{
		var previousWindow:Float = -1;
		for(rating in ratingsData)
		{
			if(rating == null || rating.name == 'shit') continue;

			if(rating.hitWindow == null || Math.isNaN(rating.hitWindow))
				rating.hitWindow = defaultHitWindow(rating.name);

			if(rating.hitWindow <= previousWindow)
				rating.hitWindow = previousWindow + 1;

			previousWindow = rating.hitWindow;
		}
	}
}
