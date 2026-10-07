package funkin.utils.engines.pico;

import funkin.modding.Mods;
import funkin.states.AntiPiracyScreenState;

/**
 * Anti-piracy license / download-source checks for Pico Engine.
 *
 * A loaded mod is flagged when:
 *  1) Its download / homepage URL is NOT GameBanana or GameJolt, OR
 *  2) Its license is missing / not in the allowed list.
 *
 * Base game (no mod directory) always passes.
 *
 * meta_mod.json fields (any alias accepted):
 *   mod_License / license / licence
 *   mod_Download / downloadUrl / download / sourceUrl / homepage / url
 *
 * Usage:
 *   if(AntiPiracy.shouldBlock())
 *     AntiPiracy.openScreen(fromPlayState, weekName);
 */
class AntiPiracy
{
	/** Fingerprints shared with AntiPiracyScreenState — do not change. */
	public static inline var INTEGRITY_CORE:String = 'PICO-AP-CORE-v1';
	public static inline var INTEGRITY_SCREEN:String = 'PICO-AP-SCREEN-v1';

	/** Hosts considered official for mod downloads. */
	public static var allowedHosts:Array<String> = [
		'gamebanana.com',
		'www.gamebanana.com',
		'gamejolt.com',
		'www.gamejolt.com'
	];

	/**
	 * Licenses accepted as legitimate.
	 * Anything else (or empty, when strictEmptyLicense) triggers the screen.
	 */
	public static var allowedLicenses:Array<String> = [
		'apache', 'apache-2.0', 'apache 2.0',
		'mit',
		'cc-by', 'cc-by-4.0', 'cc-by-sa', 'cc-by-sa-4.0',
		'cc0', 'public domain',
		'freeware', 'free',
		'official', 'all rights reserved', 'arr',
		'gpl', 'gpl-3.0', 'gplv3',
		'lgpl',
		'custom-allowed'
	];

	/** If true, missing license on a mod also blocks. */
	public static var strictEmptyLicense:Bool = true;

	/** If true, missing download URL on a mod also blocks. */
	public static var strictEmptyUrl:Bool = true;

	/** Skip checks entirely (debug / offline builds). */
	public static var disabled:Bool = false;

	/** Once acknowledged this session, don't re-prompt for the same mod. */
	static var acknowledgedMods:Map<String, Bool> = new Map();

	public static function markAcknowledged(?modFolder:String):Void
	{
		var key:String = (modFolder != null && modFolder.length > 0) ? modFolder : Mods.getCurrent();
		if(key == null || key.length < 1) key = '__base__';
		acknowledgedMods.set(key, true);
	}

	public static function isAcknowledged(?modFolder:String):Bool
	{
		var key:String = (modFolder != null && modFolder.length > 0) ? modFolder : Mods.getCurrent();
		if(key == null || key.length < 1) key = '__base__';
		return acknowledgedMods.exists(key) && acknowledgedMods.get(key) == true;
	}

	/**
	 * Result of a check.
	 * ok = true → safe to continue
	 */
	public static function checkCurrentMod():{ok:Bool, reason:String, mod:String, license:String, url:String}
	{
		return checkMod(Mods.getCurrent());
	}

	public static function checkMod(modFolder:String):{ok:Bool, reason:String, mod:String, license:String, url:String}
	{
		if(disabled)
			return {ok: true, reason: '', mod: '', license: '', url: ''};

		var folder:String = modFolder != null ? modFolder.trim() : '';
		// Base game — no mod loaded
		if(folder.length < 1)
			return {ok: true, reason: '', mod: '', license: '', url: ''};

		if(isAcknowledged(folder))
			return {ok: true, reason: 'acknowledged', mod: folder, license: '', url: ''};

		var license:String = '';
		var url:String = '';
		try
		{
			var info = Mods.getPackInfo(folder);
			if(info != null)
			{
				license = extractLicense(info);
				url = extractDownloadUrl(info);
			}
		}
		catch(e:Dynamic)
		{
			trace('[AntiPiracy] getPackInfo failed for ' + folder + ': ' + e);
		}

		// Also try reading meta_mod.json fields directly from raw
		try
		{
			if((license == null || license.length < 1) || (url == null || url.length < 1))
			{
				var info2 = Mods.getPackInfo(folder);
				if(info2 != null && info2.raw != null)
				{
					if(license == null || license.length < 1)
						license = rawLicense(info2.raw);
					if(url == null || url.length < 1)
						url = rawUrl(info2.raw);
				}
			}
		}
		catch(e:Dynamic) {}

		license = license != null ? license.trim() : '';
		url = url != null ? url.trim() : '';

		var reasons:Array<String> = [];

		if(strictEmptyUrl && url.length < 1)
			reasons.push('Missing download / source URL');
		else if(url.length > 0 && !isAllowedHost(url))
			reasons.push('Download source is not GameBanana or GameJolt (' + url + ')');

		if(strictEmptyLicense && license.length < 1)
			reasons.push('Missing mod license');
		else if(license.length > 0 && !isAllowedLicense(license))
			reasons.push('License not allowed (' + license + ')');

		if(reasons.length > 0)
		{
			return {
				ok: false,
				reason: reasons.join(' · '),
				mod: folder,
				license: license,
				url: url
			};
		}

		return {ok: true, reason: '', mod: folder, license: license, url: url};
	}

	public static function shouldBlock(?modFolder:String = null):Bool
	{
		var r = (modFolder != null && modFolder.length > 0) ? checkMod(modFolder) : checkCurrentMod();
		return !r.ok;
	}

	/**
	 * Open AntiPiracyScreenState if the current mod fails checks.
	 * @return true if screen was opened (caller should stop normal flow)
	 */
	public static function openIfNeeded(?fromPlayState:Bool = false, ?weekName:String = null, ?dialogueFile:String = null):Bool
	{
		var r = checkCurrentMod();
		if(r.ok) return false;
		openScreen(fromPlayState, weekName, dialogueFile, r.reason, r.mod);
		return true;
	}

	public static function openScreen(?fromPlayState:Bool = false, ?weekName:String = null, ?dialogueFile:String = null, ?reason:String = null, ?modName:String = null):Void
	{
		var state = new AntiPiracyScreenState(fromPlayState, dialogueFile);
		state.blockReason = reason != null ? reason : '';
		state.modFolderName = modName != null ? modName : Mods.getCurrent();
		state.weekName = weekName != null ? weekName : '';
		MusicBeatState.switchState(state);
	}

	// ---- helpers ----

	static function isAllowedHost(url:String):Bool
	{
		if(url == null || url.length < 1) return false;
		var lower:String = url.toLowerCase();
		// strip protocol
		var host:String = lower;
		for (prefix in ['https://', 'http://'])
		{
			if(StringTools.startsWith(host, prefix))
				host = host.substr(prefix.length);
		}
		// strip path
		var slash:Int = host.indexOf('/');
		if(slash >= 0) host = host.substr(0, slash);

		for (allowed in allowedHosts)
		{
			if(host == allowed || StringTools.endsWith(host, '.' + allowed))
				return true;
		}
		// also accept bare domain inside longer string
		if(lower.indexOf('gamebanana.com') >= 0) return true;
		if(lower.indexOf('gamejolt.com') >= 0) return true;
		return false;
	}

	static function isAllowedLicense(license:String):Bool
	{
		if(license == null) return false;
		var key:String = license.trim().toLowerCase();
		for (allowed in allowedLicenses)
		{
			if(key == allowed || key.indexOf(allowed) >= 0)
				return true;
		}
		return false;
	}

	static function extractLicense(info:Dynamic):String
	{
		if(info == null) return '';
		// Typed fields if present on ModPackInfo
		try
		{
			var lic:Dynamic = Reflect.field(info, 'license');
			if(lic != null && Std.string(lic).trim().length > 0)
				return Std.string(lic).trim();
		}
		catch(e:Dynamic) {}
		if(info.raw != null) return rawLicense(info.raw);
		return '';
	}

	static function extractDownloadUrl(info:Dynamic):String
	{
		if(info == null) return '';
		try
		{
			for (f in ['downloadUrl', 'sourceUrl', 'homepage', 'url'])
			{
				var v:Dynamic = Reflect.field(info, f);
				if(v != null && Std.string(v).trim().length > 0)
					return Std.string(v).trim();
			}
		}
		catch(e:Dynamic) {}
		if(info.raw != null) return rawUrl(info.raw);
		return '';
	}

	static function rawLicense(data:Dynamic):String
	{
		if(data == null) return '';
		var modData:Dynamic = Reflect.field(data, 'mod_data');
		var v:String = fieldStr(modData, ['mod_License', 'license', 'licence', 'License']);
		if(v.length > 0) return v;
		return fieldStr(data, ['mod_License', 'license', 'licence', 'License']);
	}

	static function rawUrl(data:Dynamic):String
	{
		if(data == null) return '';
		var modData:Dynamic = Reflect.field(data, 'mod_data');
		var assts:Dynamic = Reflect.field(data, 'mod_assts');
		if(assts == null) assts = Reflect.field(data, 'mod_assets');
		var v:String = fieldStr(modData, ['mod_Download', 'downloadUrl', 'download', 'sourceUrl', 'homepage', 'url']);
		if(v.length > 0) return v;
		v = fieldStr(assts, ['mod_Download', 'downloadUrl', 'download', 'sourceUrl', 'homepage', 'url']);
		if(v.length > 0) return v;
		return fieldStr(data, ['mod_Download', 'downloadUrl', 'download', 'sourceUrl', 'homepage', 'url', 'website']);
	}

	static function fieldStr(obj:Dynamic, names:Array<String>):String
	{
		if(obj == null) return '';
		for (n in names)
		{
			if(!Reflect.hasField(obj, n)) continue;
			var v:Dynamic = Reflect.field(obj, n);
			if(v == null) continue;
			var s:String = Std.string(v).trim();
			if(s.length > 0 && s.toLowerCase() != 'null') return s;
		}
		return '';
	}
}
