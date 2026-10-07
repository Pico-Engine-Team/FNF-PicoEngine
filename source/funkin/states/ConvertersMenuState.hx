package funkin.states;

import funkin.play.Song;
import funkin.stages.StageData;
import funkin.states.editors.components.VSlice;
import funkin.states.editors.components.FileDialogHandler;
import funkin.utils.engines.psych.PsychJsonPrinter;

import flash.net.FileFilter;
import haxe.Json;
import haxe.Exception;

class ConvertersMenuState extends MusicBeatState
{
	static inline var PAGE_MAIN:String = 'main';
	static inline var PAGE_PSYCH:String = 'psych';
	static inline var PAGE_NIGHTMAREVISION:String = 'nightmarevision';
	static inline var PAGE_CODENAME:String = 'codename';
	static inline var PAGE_VSLICE:String = 'vslice';

	static inline var SOURCE_PSYCH:String = 'psych';
	static inline var SOURCE_GODOT:String = 'godot';
	static inline var SOURCE_CODENAME:String = 'codename';
	static inline var SOURCE_NIGHTMAREVISION:String = 'nightmarevision';
	static inline var SOURCE_VSLICE:String = 'vslice';
	static inline var SOURCE_FOREVER:String = 'forever';
	static inline var STAGE_FILTER_ALL:Int = 3;

	var bg:FlxSprite;
	var title:FlxText;
	var description:FlxText;
	var statusText:FlxText;
	var versionText:FlxText;
	var grpOptions:FlxTypedGroup<Alphabet>;
	var selectorLeft:Alphabet;
	var options:Array<String> = [];
	var page:String = PAGE_MAIN;
	var curSelected:Int = 0;
	var fileDialog:FileDialogHandler = new FileDialogHandler();

	override function create()
	{
		super.create();
		FlxG.camera.bgColor = FlxColor.BLACK;
		bg = new FlxSprite().loadGraphic(Paths.image('menus/backgrounds/menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF3F4F70;
		add(bg);

		title = new FlxText(0, 42, FlxG.width, '', 32);
		title.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER);
		title.scrollFactor.set();
		add(title);

		description = new FlxText(45, FlxG.height - 140, FlxG.width - 90, '', 18);
		description.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, CENTER);
		description.scrollFactor.set();
		add(description);

		statusText = new FlxText(45, FlxG.height - 62, FlxG.width - 90, '', 16);
		statusText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.YELLOW, CENTER);
		statusText.scrollFactor.set();
		add(statusText);

		versionText = new FlxText(12, FlxG.height - 28, FlxG.width - 24, 'Converters Menu v1.0.0  |  F1 Help  |  BACK to go back', 16);
		versionText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT);
		versionText.scrollFactor.set();
		versionText.alpha = 0.7;
		add(versionText);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		selectorLeft = new Alphabet(0, 0, '>', true);
		selectorLeft.scrollFactor.set();
		add(selectorLeft);
		setPage(PAGE_MAIN, false);
	}

	var helpVisible:Bool = false;
	var helpBg:FlxSprite;
	var helpText:FlxText;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Help overlay
		if(FlxG.keys.justPressed.F1)
			toggleHelp();

		if(helpVisible)
		{
			if(controls.BACK || FlxG.keys.justPressed.F1 || controls.ACCEPT)
				toggleHelp(false);
			return;
		}

		// Navigation — same mapping as other menus (Controls / Psych controls)
		if(controls.UI_UP_P) changeSelection(-1);
		if(controls.UI_DOWN_P) changeSelection(1);
		if(controls.UI_LEFT_P) changeSelection(-1);
		if(controls.UI_RIGHT_P) changeSelection(1);
		if(controls.ACCEPT) accept();
		if(controls.BACK) back();

		// Keep '>' selector locked to the selected Alphabet item while it lerps
		if(selectorLeft != null && grpOptions != null && grpOptions.members.length > 0)
		{
			var item:Alphabet = grpOptions.members[curSelected];
			if(item != null)
			{
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
			}
		}
	}

	function toggleHelp(?force:Null<Bool> = null)
	{
		helpVisible = force != null ? force : !helpVisible;
		if(helpBg == null)
		{
			helpBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			helpBg.scale.set(FlxG.width, FlxG.height);
			helpBg.updateHitbox();
			helpBg.scrollFactor.set();
			helpBg.alpha = 0.82;
			add(helpBg);

			helpText = new FlxText(40, 40, FlxG.width - 80, '', 18);
			helpText.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, LEFT);
			helpText.scrollFactor.set();
			add(helpText);
		}
		helpBg.visible = helpVisible;
		helpText.visible = helpVisible;
		if(helpVisible)
		{
			helpText.text = [
				'CONVERTERS MENU — HELP',
				'',
				'How to use:',
				'1. Choose an engine (Psych, NightmareVision, Codename, V-Slice).',
				'2. Pick Chart / Character / Stage Converter.',
				'3. Select the source file(s) in the file dialog.',
				'4. Save the converted JSON where you want.',
				'',
				'Controls:',
				'  UI UP / UI DOWN     — Move selection',
				'  UI LEFT / UI RIGHT  — Move selection (same)',
				'  ACCEPT             — Open converter / confirm',
				'  BACK               — Go back (sub-menu → main → Editors)',
				'  F1                 — Toggle this help',
				'',
				'Tips:',
				'  Codename charts need chart.json + meta.json.',
				'  V-Slice charts need chart.json + metadata.json.',
				'  NightmareVision stages use data.json (+ optional script.hx).',
				'',
				'Press BACK or F1 to close help.'
			].join('\n');
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}
	}

	function setPage(newPage:String, playSound:Bool = true)
	{
		page = newPage;
		curSelected = 0;

		options = switch(page)
		{
			case PAGE_PSYCH: ['Chart Converter', 'Character Converter'];
			case PAGE_NIGHTMAREVISION: ['Chart Converter', 'Character Converter', 'Stage Converter'];
			case PAGE_CODENAME: ['Chart Converter', 'Character Converter', 'Stage Converter'];
			case PAGE_VSLICE: ['Chart Converter', 'Character Converter', 'Stage Converter'];
			default: ['Psych Engine', 'NightmareVision Engine', 'Codename Engine', 'VSlice Engine'];
		}
		title.text = switch(page)
		{
			case PAGE_MAIN: 'Converters Menu';
			case PAGE_PSYCH: 'Psych Engine Converters';
			case PAGE_NIGHTMAREVISION: 'NightmareVision Engine Converters';
			case PAGE_CODENAME: 'Codename Engine Converters';
			case PAGE_VSLICE: 'VSlice Engine Converters';
			default: 'Converters Menu';
		}

		rebuildMenuItems();
		changeSelection(0, playSound);
	}

	function rebuildMenuItems()
	{
		if(grpOptions == null) return;
		grpOptions.clear();

		for (i in 0...options.length)
		{
			var item:Alphabet = new Alphabet(90, 320, options[i], true);
			item.isMenuItem = true;
			item.targetY = i;
			item.snapToPosition();
			grpOptions.add(item);
		}
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if(options.length < 1) return;
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		for (i in 0...grpOptions.members.length)
		{
			var item:Alphabet = grpOptions.members[i];
			item.targetY = i - curSelected;
			item.alpha = 0.45;
			if(i == curSelected)
			{
				item.alpha = 1;
				if(selectorLeft != null)
				{
					selectorLeft.x = item.x - 63;
					selectorLeft.y = item.y;
				}
			}
		}

		description.text = getDescription(options[curSelected]);
	}

	function getDescription(option:String):String
	{
		// Engine pages share option labels — resolve by current page.
		if(option == 'Chart Converter')
		{
			return switch(page)
			{
				case PAGE_PSYCH: 'Convert a Psych Engine chart JSON into Pico Engine chart format.';
				case PAGE_NIGHTMAREVISION: 'Convert one NightmareVision chart JSON.';
				case PAGE_CODENAME: 'Open Codename chart.json + meta.json, then export one Pico chart JSON.';
				case PAGE_VSLICE: 'Open a VSlice chart.json + metadata.json, then export chart JSON files.';
				default: 'Convert a chart JSON.';
			}
		}
		if(option == 'Character Converter')
		{
			return switch(page)
			{
				case PAGE_PSYCH: 'Convert a Psych Engine character JSON into Pico character format.';
				case PAGE_NIGHTMAREVISION: 'Convert a NightmareVision character JSON into Pico character format.';
				case PAGE_CODENAME: 'Convert one Codename Engine character XML or JSON (anims still use .png + .xml).';
				case PAGE_VSLICE: 'Convert one Friday Night Funkin V-Slice character JSON.';
				default: 'Convert a character file.';
			}
		}
		if(option == 'Stage Converter')
		{
			return switch(page)
			{
				case PAGE_NIGHTMAREVISION: 'Convert NightmareVision stage data.json (+ optional script.hx) into Pico stage JSON.';
				case PAGE_CODENAME: 'Convert one Codename Engine stage XML into Pico stage JSON.';
				case PAGE_VSLICE: 'Convert one V-Slice stage JSON (props/characters format) into Pico stage JSON.';
				default: 'Convert a stage file.';
			}
		}

		return switch(option)
		{
			case 'Psych Engine': 'Psych Engine chart and character converters.';
			case 'NightmareVision Engine': 'NightmareVision chart, character and stage converters.';
			case 'Codename Engine': 'Codename Engine chart, character (XML) and stage (XML) converters.';
			case 'VSlice Engine': 'V-Slice chart, character and stage (props) converters.';
			default: 'Select an option. Press BACK to go back. Press F1 for Help.';
		}
	}

	function accept()
	{
		var option = options[curSelected];
		switch(option)
		{
			case 'Psych Engine': setPage(PAGE_PSYCH);
			case 'NightmareVision Engine': setPage(PAGE_NIGHTMAREVISION);
			case 'Codename Engine': setPage(PAGE_CODENAME);
			case 'VSlice Engine': setPage(PAGE_VSLICE);
			case 'Chart Converter':
				switch(page)
				{
					case PAGE_PSYCH: openPsychChartToPico();
					case PAGE_NIGHTMAREVISION: openNightmareVisionChartToPico();
					case PAGE_CODENAME: openCodenameChartToPico();
					case PAGE_VSLICE: openVSliceChartToPico();
					default: back();
				}
			case 'Character Converter':
				switch(page)
				{
					case PAGE_PSYCH: openCharacter(SOURCE_PSYCH);
					case PAGE_NIGHTMAREVISION: openCharacter(SOURCE_NIGHTMAREVISION);
					case PAGE_CODENAME: openCharacter(SOURCE_CODENAME);
					case PAGE_VSLICE: openCharacter(SOURCE_VSLICE);
					default: back();
				}
			case 'Stage Converter':
				switch(page)
				{
					case PAGE_NIGHTMAREVISION: openNightmareVisionStageToPico();
					case PAGE_CODENAME: openStage(SOURCE_CODENAME);
					case PAGE_VSLICE: openStage(SOURCE_VSLICE);
					default: back();
				}
			default: back();
		}
	}

	function openPsychChartToPico()
	{
		fileDialog.open('song.json', 'Open Psych Chart JSON', null, function()
		{
			try
			{
				var filePath = fileDialog.path.replace('\\', '/');
				var converted = convertPsychChart(fileDialog.data, getFileBase(filePath));
				fileDialog.save(Paths.formatToSongPath(getFileBase(filePath)) + '.json', converted, function()
				{
					setStatus('Saved converted Psych chart to: ${fileDialog.path}');
				}, onCancel, onError);
			}
			catch(e:Exception)
			{
				setStatus('Failed to convert Psych chart: ${e.message}', true);
			}
			catch(e:Dynamic)
			{
				setStatus('Failed to convert Psych chart: $e', true);
			}
		}, onCancel, onError);
	}

	function openNightmareVisionStageToPico()
	{
		// NightmareVision stages: data.json (+ optional script.hx beside it)
		fileDialog.open('data.json', 'Open NightmareVision stage data.json', [new FileFilter('Stage data JSON', 'json')], function()
		{
			try
			{
				var dataPath = fileDialog.path.replace('\\', '/');
				var dataRaw = fileDialog.data;
				var folder = dataPath.contains('/') ? dataPath.substr(0, dataPath.lastIndexOf('/')) : '.';
				var scriptRaw:String = null;
				var scriptName:String = null;
				// Prefer script.hx next to data.json
				for (candidate in ['script.hx', 'stage.hx', 'Script.hx'])
				{
					var full = folder + '/' + candidate;
					if(FileSystem.exists(full) && !FileSystem.isDirectory(full))
					{
						scriptRaw = File.getContent(full);
						scriptName = candidate;
						break;
					}
				}

				var converted = convertNightmareVisionStage(dataRaw, getFileBase(dataPath), scriptName);
				var saveName = Paths.formatToSongPath(getFileBase(dataPath));
				if(saveName == 'data' || saveName.length < 1)
					saveName = 'stage';

				fileDialog.save(saveName + '.json', converted, function()
				{
					var extra = scriptName != null ? ' (linked $scriptName)' : ' (no script.hx found beside data.json)';
					setStatus('Saved converted NightmareVision stage to: ${fileDialog.path}' + extra);

					// Also offer saving script.hx copy if present
					if(scriptRaw != null && scriptName != null)
					{
						try
						{
							var outFolder = fileDialog.path.replace('\\', '/');
							if(outFolder.contains('/'))
								outFolder = outFolder.substr(0, outFolder.lastIndexOf('/'));
							File.saveContent(outFolder + '/' + scriptName, scriptRaw);
						}
						catch(e:Dynamic) {}
					}
				}, onCancel, onError);
			}
			catch(e:Exception)
			{
				setStatus('Failed to convert NightmareVision stage: ${e.message}', true);
			}
			catch(e:Dynamic)
			{
				setStatus('Failed to convert NightmareVision stage: $e', true);
			}
		}, onCancel, onError);
	}

	function openGodotChartToPico()
	{
		fileDialog.open('song.json', 'Open Godot Chart JSON', null, function()
		{
			try
			{
				var filePath = fileDialog.path.replace('\\', '/');
				var converted = convertGodotChart(fileDialog.data, getFileBase(filePath));
				fileDialog.save(Paths.formatToSongPath(getFileBase(filePath)) + '.json', converted, function()
				{
					setStatus('Saved converted Godot chart to: ${fileDialog.path}');
				}, onCancel, onError);
			}
			catch(e:Exception)
			{
				setStatus('Failed to convert Godot chart: ${e.message}', true);
			}
			catch(e:Dynamic)
			{
				setStatus('Failed to convert Godot chart: $e', true);
			}
		}, onCancel, onError);
	}

	function openNightmareVisionChartToPico()
	{
		fileDialog.open('song.json', 'Open NightmareVision Chart JSON', null, function()
		{
			try
			{
				var filePath = fileDialog.path.replace('\\', '/');
				var converted = convertNightmareVisionChart(fileDialog.data, getFileBase(filePath));
				fileDialog.save(Paths.formatToSongPath(getFileBase(filePath)) + '.json', converted, function()
				{
					setStatus('Saved converted NightmareVision chart to: ${fileDialog.path}');
				}, onCancel, onError);
			}
			catch(e:Exception)
			{
				setStatus('Failed to convert NightmareVision chart: ${e.message}', true);
			}
			catch(e:Dynamic)
			{
				setStatus('Failed to convert NightmareVision chart: $e', true);
			}
		}, onCancel, onError);
	}

	function openCodenameChartToPico()
	{
		fileDialog.open('chart.json', 'Open Codename chart.json', null, function()
		{
			var chartRaw:String = fileDialog.data;
			var chartPath:String = fileDialog.path.replace('\\', '/');

			fileDialog.open('meta.json', 'Open Codename meta.json', null, function()
			{
				try
				{
					var convertedSong:SwagSong = parseCodenameChart(chartRaw, fileDialog.data, chartPath);
					var saveName:String = Paths.formatToSongPath(convertedSong.song);
					if(saveName.length < 1) saveName = Paths.formatToSongPath(getFileBase(chartPath));

					fileDialog.save(saveName + '.json', PsychJsonPrinter.print(convertedSong, ['sectionNotes', 'events']), function()
					{
						setStatus('Saved converted Codename chart to: ${fileDialog.path}');
					}, onCancel, onError);
				}
				catch(e:Exception)
				{
					setStatus('Failed to convert Codename chart: ${e.message}', true);
				}
				catch(e:Dynamic)
				{
					setStatus('Failed to convert Codename chart: $e', true);
				}
			}, onCancel, onError);
		}, onCancel, onError);
	}

	function openGodotChartFolderToPico()
	{
		fileDialog.openDirectory('Open Godot Charts Folder', function()
		{
			var folder = fileDialog.path.replace('\\', '/');
			var outFolder = folder + '/converted-pico';
			try
			{
				if(!FileSystem.exists(outFolder)) FileSystem.createDirectory(outFolder);

				var convertedCount = 0;
				var skippedCount = 0;
				for (file in FileSystem.readDirectory(folder))
				{
					if(!file.toLowerCase().endsWith('.json')) continue;

					var fullPath = folder + '/' + file;
					if(FileSystem.isDirectory(fullPath)) continue;

					var baseName = getFileBase(file);
					try
					{
						File.saveContent(outFolder + '/' + Paths.formatToSongPath(baseName) + '.json', convertGodotChart(File.getContent(fullPath), baseName));
						convertedCount++;
					}
					catch(e:Dynamic)
					{
						skippedCount++;
						trace('Skipped Godot chart "$file": $e');
					}
				}

				setStatus('Converted $convertedCount Godot chart(s) into: $outFolder' + (skippedCount > 0 ? ' ($skippedCount skipped)' : ''));
			}
			catch(e:Exception)
			{
				setStatus('Failed to convert Godot chart folder: ${e.message}', true);
			}
			catch(e:Dynamic)
			{
				setStatus('Failed to convert Godot chart folder: $e', true);
			}
		}, onCancel, onError);
	}

	function openVSliceChartToPico()
	{
		fileDialog.open('chart.json', 'Open V-Slice Chart JSON', null, function()
		{
			try
			{
				var chart:VSliceChart = cast Json.parse(fileDialog.data);
				if(chart == null || chart.notes == null || chart.scrollSpeed == null)
				{
					setStatus('Loaded file is not a valid V-Slice chart.', true);
					return;
				}

				fileDialog.open('metadata.json', 'Open V-Slice Metadata JSON', null, function()
				{
					try
					{
						var metadata:VSliceMetadata = cast Json.parse(fileDialog.data);
						if(metadata == null || metadata.playData == null || metadata.songName == null || metadata.timeChanges == null || metadata.timeChanges.length < 1)
						{
							setStatus('Loaded file is not a valid V-Slice metadata.', true);
							return;
						}

						var pack:PsychPackage = VSlice.convertToPsych(chart, metadata);
						fileDialog.openDirectory('Save Converted Chart JSONs', function()
						{
							try
							{
								var path = cleanFolderPath(fileDialog.path);
								var defaultDiff = Paths.formatToSongPath(Difficulty.getDefault());
								var saved = 0;

								for (diffName in pack.difficulties.keys())
								{
									var chartData = pack.difficulties.get(diffName);
									if(chartData == null) continue;

									var diffPostfix = diffName != defaultDiff ? '-$diffName' : '';
									var chartName = Paths.formatToSongPath(chartData.song) + diffPostfix + '.json';
									File.saveContent('$path/$chartName', PsychJsonPrinter.print(chartData, ['sectionNotes', 'events']));
									saved++;
								}

								if(pack.events != null)
								{
									File.saveContent('$path/events.json', PsychJsonPrinter.print(pack.events, ['events']));
									saved++;
								}

								setStatus('Saved $saved chart JSON file(s) to: $path');
							}
							catch(e:Exception)
							{
								setStatus('Failed to save chart files: ${e.message}', true);
							}
							catch(e:Dynamic)
							{
								setStatus('Failed to save chart files: $e', true);
							}
						}, onCancel, onError);
					}
					catch(e:Exception)
					{
						setStatus('Failed to convert V-Slice chart: ${e.message}', true);
					}
					catch(e:Dynamic)
					{
						setStatus('Failed to convert V-Slice chart: $e', true);
					}
				}, onCancel, onError);
			}
			catch(e:Exception)
			{
				setStatus('Failed to load V-Slice chart: ${e.message}', true);
			}
			catch(e:Dynamic)
			{
				setStatus('Failed to load V-Slice chart: $e', true);
			}
		}, onCancel, onError);
	}

	function openCharacter(source:String)
	{
		var defaultName = source == SOURCE_CODENAME ? 'character.xml' : 'character.json';
		fileDialog.open(defaultName, 'Open ${sourceLabel(source)} Character', characterFilter(source), function()
		{
			try
			{
				var sourcePath = fileDialog.path.replace('\\', '/');
				var converted = convertCharacter(fileDialog.data, getFileBase(sourcePath), source);
				var saveName = Paths.formatToSongPath(getFileBase(sourcePath)) + '.json';
				fileDialog.save(saveName, converted, function()
				{
					setStatus('Saved converted character to: ${fileDialog.path}');
				}, onCancel, onError);
			}
			catch(e:Exception)
			{
				setStatus('Failed to convert character: ${e.message}', true);
			}
			catch(e:Dynamic)
			{
				setStatus('Failed to convert character: $e', true);
			}
		}, onCancel, onError);
	}

	function openStage(source:String)
	{
		var defaultName = (source == SOURCE_VSLICE || source == SOURCE_NIGHTMAREVISION) ? 'stage.json' : 'stage.xml';
		var label = (source == SOURCE_VSLICE || source == SOURCE_NIGHTMAREVISION) ? 'Stage JSON' : 'Stage XML';
		fileDialog.open(defaultName, 'Open ${sourceLabel(source)} $label', stageFilter(source), function()
		{
			try
			{
				var sourcePath = fileDialog.path.replace('\\', '/');
				var converted = convertStage(fileDialog.data, getFileBase(sourcePath), source);
				var saveName = Paths.formatToSongPath(getFileBase(sourcePath)) + '.json';
				fileDialog.save(saveName, converted, function()
				{
					setStatus('Saved converted stage to: ${fileDialog.path}');
				}, onCancel, onError);
			}
			catch(e:Exception)
			{
				setStatus('Failed to convert stage: ${e.message}', true);
			}
			catch(e:Dynamic)
			{
				setStatus('Failed to convert stage: $e', true);
			}
		}, onCancel, onError);
	}

	function openCharacterFolder(source:String)
	{
		fileDialog.openDirectory('Open ${sourceLabel(source)} Characters Folder', function()
		{
			var folder = fileDialog.path.replace('\\', '/');
			var outFolder = folder + '/converted-pico';
			try
			{
				if(!FileSystem.exists(outFolder)) FileSystem.createDirectory(outFolder);

				var convertedCount = 0;
				for (file in FileSystem.readDirectory(folder))
				{
					var lower = file.toLowerCase();
					if(!isCharacterFileForSource(lower, source)) continue;

					var fullPath = folder + '/' + file;
					if(FileSystem.isDirectory(fullPath)) continue;

					var baseName = getFileBase(file);
					File.saveContent(outFolder + '/' + Paths.formatToSongPath(baseName) + '.json', convertCharacter(File.getContent(fullPath), baseName, source));
					convertedCount++;
				}

				setStatus('Converted $convertedCount character file(s) into: $outFolder');
			}
			catch(e:Exception)
			{
				setStatus('Failed to convert folder: ${e.message}', true);
			}
			catch(e:Dynamic)
			{
				setStatus('Failed to convert folder: $e', true);
			}
		}, onCancel, onError);
	}

	static function convertCharacter(raw:String, fileName:String, source:String):String
	{
		if(source == SOURCE_CODENAME && raw.trim().startsWith('<'))
			return convertCodenameXmlCharacter(raw, fileName);
		if(source == SOURCE_GODOT)
			return convertGodotCharacter(raw, fileName);

		return convertGenericCharacter(raw, fileName, source);
	}

	static function convertStage(raw:String, fileName:String, source:String):String
	{
		if(source == SOURCE_VSLICE)
			return convertVSliceJsonStage(raw, fileName);
		if(source == SOURCE_NIGHTMAREVISION)
			return convertNightmareVisionStage(raw, fileName, null);

		return convertXmlStage(raw, fileName, source);
	}

	static function convertXmlStage(raw:String, fileName:String, source:String):String
	{
		var xml = Xml.parse(raw);
		var root = firstStageXmlElement(xml);
		if(root == null)
			throw new Exception('Could not find a stage XML root.');

		var defaultStage = StageData.dummy();
		var gfNode = findStageCharacterNode(root, ['gf', 'girlfriend']);
		var dadNode = findStageCharacterNode(root, ['dad', 'opponent', 'enemy']);
		var bfNode = findStageCharacterNode(root, ['bf', 'boyfriend', 'player']);

		var hideGF:Bool = xmlBoolAny(root, ['hide_girlfriend', 'hideGirlfriend', 'hideGF'], defaultStage.hide_girlfriend);
		if(gfNode != null && xmlHasAny(gfNode, ['visible']))
			hideGF = !xmlBoolAny(gfNode, ['visible'], true);

		var objects:Array<Dynamic> = [];
		collectStageObjects(root, objects, 0);

		var stage:Dynamic = {
			directory: xmlStringAny(root, ['directory', 'folder', 'assetFolder', 'library', 'week'], defaultStage.directory),
			defaultZoom: xmlFloatAny(root, ['defaultZoom', 'zoom', 'camZoom', 'cameraZoom', 'stageZoom', 'startCamZoom'], defaultStage.defaultZoom),
			stageUI: xmlStringAny(root, ['stageUI', 'uiStyle', 'ui', 'uiType'], defaultStage.stageUI),

			boyfriend: xmlStagePoint(root, bfNode, ['boyfriend', 'bf', 'player'], defaultStage.boyfriend),
			girlfriend: xmlStagePoint(root, gfNode, ['girlfriend', 'gf'], defaultStage.girlfriend),
			opponent: xmlStagePoint(root, dadNode, ['opponent', 'dad', 'enemy'], defaultStage.opponent),
			hide_girlfriend: hideGF,

			camera_boyfriend: xmlStageCameraPoint(root, bfNode, ['boyfriend', 'bf', 'player'], defaultStage.camera_boyfriend),
			camera_opponent: xmlStageCameraPoint(root, dadNode, ['opponent', 'dad', 'enemy'], defaultStage.camera_opponent),
			camera_girlfriend: xmlStageCameraPoint(root, gfNode, ['girlfriend', 'gf'], defaultStage.camera_girlfriend),
			camera_speed: xmlFloatAny(root, ['camera_speed', 'cameraSpeed', 'camSpeed', 'followSpeed'], defaultStage.camera_speed),

			_editorMeta: {
				boyfriend: xmlCharacterName(bfNode, 'bf'),
				gf: xmlCharacterName(gfNode, 'gf'),
				dad: xmlCharacterName(dadNode, 'dad')
			}
		};

		if(xmlHasAny(root, ['isPixelStage', 'pixelStage', 'isPixel']))
			Reflect.setField(stage, 'isPixelStage', xmlBoolAny(root, ['isPixelStage', 'pixelStage', 'isPixel'], false));
		appendStageCharacterObjects(objects);
		var preload = buildStagePreload(objects);
		if(preload != null)
			Reflect.setField(stage, 'preload', preload);
		Reflect.setField(stage, 'objects', objects);

		return PsychJsonPrinter.print(stage, ['boyfriend', 'girlfriend', 'opponent', 'camera_boyfriend', 'camera_opponent', 'camera_girlfriend', 'scale', 'scroll', 'offsets', 'indices']);
	}

	static function convertVSliceJsonStage(raw:String, fileName:String):String
	{
		var data:Dynamic = Json.parse(raw);
		if(data == null)
			throw new Exception('Could not parse V-Slice stage JSON.');

		var defaultStage = StageData.dummy();
		var characters:Dynamic = optionalField(data, ['characters', 'characterData', 'charData']);
		var bfData = vSliceCharacterData(characters, data, ['bf', 'boyfriend', 'player']);
		var gfData = vSliceCharacterData(characters, data, ['gf', 'girlfriend']);
		var dadData = vSliceCharacterData(characters, data, ['dad', 'opponent', 'enemy']);

		var objects:Array<Dynamic> = [];
		var props:Array<Dynamic> = dynamicArray(optionalField(data, ['props', 'objects', 'sprites', 'layers', 'stageProps']));
		if(props != null)
		{
			for (index in 0...props.length)
			{
				if(props[index] == null) continue;
				objects.push(convertVSliceStageObject(props[index], objects, index));
			}
		}

		var stage:Dynamic = {
			directory: vSliceString(data, ['directory', 'folder', 'assetFolder', 'library', 'week'], defaultStage.directory),
			defaultZoom: vSliceFloat(data, ['defaultZoom', 'cameraZoom', 'camZoom', 'zoom', 'stageZoom'], defaultStage.defaultZoom),
			stageUI: vSliceString(data, ['stageUI', 'uiStyle', 'ui', 'uiType'], defaultStage.stageUI),

			boyfriend: vSlicePoint(bfData, ['position', 'pos', 'offset', 'offsets'], [770.0, 100.0]),
			girlfriend: vSlicePoint(gfData, ['position', 'pos', 'offset', 'offsets'], [400.0, 130.0]),
			opponent: vSlicePoint(dadData, ['position', 'pos', 'offset', 'offsets'], [100.0, 100.0]),
			hide_girlfriend: vSliceBool(data, ['hide_girlfriend', 'hideGirlfriend', 'hideGF'], false),

			camera_boyfriend: vSlicePoint(bfData, ['cameraOffsets', 'cameraOffset', 'camera_position', 'cameraPosition', 'camera', 'cam', 'camOffset'], defaultStage.camera_boyfriend),
			camera_opponent: vSlicePoint(dadData, ['cameraOffsets', 'cameraOffset', 'camera_position', 'cameraPosition', 'camera', 'cam', 'camOffset'], defaultStage.camera_opponent),
			camera_girlfriend: vSlicePoint(gfData, ['cameraOffsets', 'cameraOffset', 'camera_position', 'cameraPosition', 'camera', 'cam', 'camOffset'], defaultStage.camera_girlfriend),
			camera_speed: vSliceFloat(data, ['camera_speed', 'cameraSpeed', 'camSpeed', 'followSpeed'], defaultStage.camera_speed),

			_editorMeta: {
				boyfriend: vSliceCharacterName(bfData, 'bf'),
				gf: vSliceCharacterName(gfData, 'gf'),
				dad: vSliceCharacterName(dadData, 'dad')
			}
		};

		if(vSliceHasAny(data, ['isPixelStage', 'pixelStage', 'isPixel']))
			Reflect.setField(stage, 'isPixelStage', vSliceBool(data, ['isPixelStage', 'pixelStage', 'isPixel'], false));
		appendStageCharacterObjects(objects);
		var preload = buildStagePreload(objects);
		if(preload != null)
			Reflect.setField(stage, 'preload', preload);
		Reflect.setField(stage, 'objects', objects);

		return PsychJsonPrinter.print(stage, ['boyfriend', 'girlfriend', 'opponent', 'camera_boyfriend', 'camera_opponent', 'camera_girlfriend', 'scale', 'scroll', 'offsets', 'indices']);
	}

	static function convertVSliceStageObject(data:Dynamic, objects:Array<Dynamic>, index:Int):Dynamic
	{
		var typeName = Paths.formatToSongPath(vSliceString(data, ['type', 'kind'], 'sprite'));
		var image = normalizeStageImagePath(vSliceString(data, ['assetPath', 'image', 'texture', 'sprite', 'path', 'src', 'file'], vSliceString(data, ['name', 'id'], 'sprite$index')));
		var name = uniqueStageObjectName(vSliceString(data, ['name', 'id', 'tag'], getFileBase(image)), objects);
		var animations = vSliceStageAnimations(data);
		var isSquare = ['square', 'rect', 'solid'].contains(typeName);
		var animated = !isSquare && (typeName.contains('animated') || typeName == 'sparrow' || animations.length > 0 || vSliceBool(data, ['animated'], false));
		var type = isSquare ? 'square' : (animated ? 'animatedSprite' : 'sprite');

		var pos = vSlicePoint(data, ['position', 'pos'], [0, 0]);
		var obj:Dynamic = {
			type: type,
			name: name,
			x: pos[0],
			y: pos[1],
			scale: vSlicePair(data, ['scale'], ['scaleX', 'sx'], ['scaleY', 'sy'], [1, 1]),
			scroll: vSlicePair(data, ['scroll', 'scrollFactor', 'parallax'], ['scrollX', 'scrollFactorX', 'parallaxX'], ['scrollY', 'scrollFactorY', 'parallaxY'], [1, 1]),
			alpha: vSliceFloat(data, ['alpha', 'opacity'], 1),
			angle: vSliceFloat(data, ['angle', 'rotation'], 0),
			color: normalizeStageColor(vSliceString(data, ['color', 'tint'], 'FFFFFF')),
			filters: vSliceStageFilters(data)
		};
		if(vSliceHasAny(data, ['zIndex', 'z', 'depth']))
			Reflect.setField(obj, 'zIndex', Std.int(vSliceFloat(data, ['zIndex', 'z', 'depth'], 0)));
		if(vSliceHasAny(data, ['isPixel', 'pixel', 'isPixelStage']))
			Reflect.setField(obj, 'isPixel', vSliceBool(data, ['isPixel', 'pixel', 'isPixelStage'], false));

		if(type != 'square')
		{
			Reflect.setField(obj, 'flipX', vSliceBool(data, ['flipX', 'flip_x'], false));
			Reflect.setField(obj, 'flipY', vSliceBool(data, ['flipY', 'flip_y'], false));
			Reflect.setField(obj, 'image', image);
			Reflect.setField(obj, 'antialiasing', vSliceBool(data, ['antialiasing', 'antialias', 'aa'], true));
		}

		if(type == 'animatedSprite')
		{
			Reflect.setField(obj, 'animations', animations);
			if(animations.length > 0)
				Reflect.setField(obj, 'firstAnimation', Reflect.field(animations[0], 'anim'));
		}

		return obj;
	}

	static function vSliceStageAnimations(data:Dynamic):Array<Dynamic>
	{
		var output:Array<Dynamic> = [];
		var animations = dynamicArray(optionalField(data, ['animations', 'anims']));
		if(animations == null) return output;

		for (animData in animations)
		{
			if(animData == null) continue;
			var anim = normalizeAnimName(animationId(animData, SOURCE_VSLICE));
			var prefix = animationPrefix(animData, SOURCE_VSLICE, anim);
			var offsets = intPoint(vSlicePoint(animData, ['offsets', 'offset'], [0, 0]));
			var fps = intField(animData, ['fps', 'FPS', 'frameRate', 'framerate', 'frame_rate'], 24);
			var loop = boolField(animData, ['loop', 'looped'], anim == 'idle');
			output.push(makeAnimation(anim, prefix, offsets, fps, loop));
		}
		return output;
	}

	public static function convertGodotChart(raw:String, fileName:String):String
	{
		var songData = parseGodotChart(raw, fileName);
		return PsychJsonPrinter.print(songData, ['sectionNotes', 'events']);
	}

	public static function convertPsychChart(raw:String, fileName:String):String
	{
		// Psych chart is already close to Pico — normalize song wrapper + keep notes/events.
		var parsed:Dynamic = Json.parse(raw);
		if(parsed == null)
			throw new Exception('Could not parse Psych chart JSON.');

		var songData:Dynamic = Reflect.hasField(parsed, 'song') ? Reflect.field(parsed, 'song') : parsed;
		if(songData == null)
			throw new Exception('Psych chart is missing song data.');

		// Ensure song name
		if(!Reflect.hasField(songData, 'song') || Std.string(Reflect.field(songData, 'song')).trim().length < 1)
			Reflect.setField(songData, 'song', fileName);

		return PsychJsonPrinter.print(songData, ['sectionNotes', 'events', 'notes']);
	}

	/** NightmareVision stage: data.json (+ optional script.hx name). */
	public static function convertNightmareVisionStage(raw:String, fileName:String, scriptName:String):String
	{
		var data:Dynamic = Json.parse(raw);
		if(data == null)
			throw new Exception('Could not parse NightmareVision stage data.json.');

		var defaultStage = StageData.dummy();
		var bfPos = parsePoint(optionalField(data, ['boyfriend', 'bf', 'player']), [770.0, 100.0]);
		var gfPos = parsePoint(optionalField(data, ['girlfriend', 'gf']), [400.0, 130.0]);
		var dadPos = parsePoint(optionalField(data, ['opponent', 'dad', 'enemy']), [100.0, 100.0]);
		var camBf = parsePoint(optionalField(data, ['camera_boyfriend', 'cameraBoyfriend', 'bfCamera']), defaultStage.camera_boyfriend);
		var camDad = parsePoint(optionalField(data, ['camera_opponent', 'cameraOpponent', 'dadCamera']), defaultStage.camera_opponent);
		var camGf = parsePoint(optionalField(data, ['camera_girlfriend', 'cameraGirlfriend', 'gfCamera']), defaultStage.camera_girlfriend);

		var stage:Dynamic = {
			directory: vSliceString(data, ['directory', 'folder', 'assetFolder', 'library', 'week'], defaultStage.directory),
			defaultZoom: vSliceFloat(data, ['defaultZoom', 'cameraZoom', 'camZoom', 'zoom', 'stageZoom'], defaultStage.defaultZoom),
			stageUI: vSliceString(data, ['stageUI', 'uiStyle', 'ui', 'uiType'], defaultStage.stageUI),

			boyfriend: bfPos != null ? bfPos : [770.0, 100.0],
			girlfriend: gfPos != null ? gfPos : [400.0, 130.0],
			opponent: dadPos != null ? dadPos : [100.0, 100.0],
			hide_girlfriend: vSliceBool(data, ['hide_girlfriend', 'hideGirlfriend', 'hideGF'], false),

			camera_boyfriend: camBf != null ? camBf : defaultStage.camera_boyfriend,
			camera_opponent: camDad != null ? camDad : defaultStage.camera_opponent,
			camera_girlfriend: camGf != null ? camGf : defaultStage.camera_girlfriend,
			camera_speed: vSliceFloat(data, ['camera_speed', 'cameraSpeed', 'camSpeed', 'followSpeed'], defaultStage.camera_speed),

			_editorMeta: {
				boyfriend: 'bf',
				gf: 'gf',
				dad: 'dad'
			}
		};

		if(vSliceHasAny(data, ['isPixelStage', 'pixelStage', 'isPixel']))
			Reflect.setField(stage, 'isPixelStage', vSliceBool(data, ['isPixelStage', 'pixelStage', 'isPixel'], false));

		// Z-index from NV data.json
		var objects:Array<Dynamic> = [];
		appendStageCharacterObjects(objects);
		// Stamp zIndex onto character objects when provided
		var zMap:Map<String, Int> = [
			'dad' => Std.int(vSliceFloat(data, ['dadZIndex', 'opponentZIndex'], 200)),
			'boyfriend' => Std.int(vSliceFloat(data, ['bfZIndex', 'boyfriendZIndex'], 300)),
			'gf' => Std.int(vSliceFloat(data, ['gfZIndex', 'girlfriendZIndex'], 100))
		];
		for (obj in objects)
		{
			var t = Std.string(Reflect.field(obj, 'type'));
			if(zMap.exists(t))
				Reflect.setField(obj, 'zIndex', zMap.get(t));
		}
		Reflect.setField(stage, 'objects', objects);

		if(scriptName != null && scriptName.trim().length > 0)
			Reflect.setField(stage, 'script', scriptName.trim());

		return PsychJsonPrinter.print(stage, ['boyfriend', 'girlfriend', 'opponent', 'camera_boyfriend', 'camera_opponent', 'camera_girlfriend', 'scale', 'scroll', 'offsets', 'indices']);
	}

	public static function convertNightmareVisionChart(raw:String, fileName:String):String
	{
		var songData = parseNightmareVisionChart(raw, fileName);
		return PsychJsonPrinter.print(songData, ['sectionNotes', 'events']);
	}

	static function parseGodotChart(raw:String, fileName:String):SwagSong
	{
		var songData:SwagSong = null;
		try { songData = Song.parseJSON(raw, fileName); } catch(e:Dynamic) { songData = null; }
		if(songData == null || songData.notes == null)
		{
			// Fallback: raw Psych-like / Godot-wrapped JSON
			try
			{
				var parsed:Dynamic = Json.parse(raw);
				if(parsed != null)
				{
					var root:Dynamic = Reflect.hasField(parsed, 'song') ? Reflect.field(parsed, 'song') : parsed;
					if(root != null && (Reflect.hasField(root, 'notes') || Reflect.hasField(root, 'sectionNotes')))
					{
						songData = cast root;
						if(songData.notes == null && Reflect.hasField(root, 'sectionNotes'))
							songData.notes = cast Reflect.field(root, 'sectionNotes');
					}
				}
			}
			catch(e2:Dynamic) {}
		}
		if(songData == null || songData.notes == null)
			throw new Exception('File is not a valid Godot/Psych chart. Expected JSON with song.notes sections.');

		if(songData.song == null || songData.song.trim().length < 1)
			songData.song = getReadableSongName(fileName);
		if(songData.events == null)
			songData.events = [];
		if(!Reflect.hasField(songData, 'needsVoices') || Reflect.field(songData, 'needsVoices') == null)
			songData.needsVoices = true;
		if(!Reflect.hasField(songData, 'speed') || Reflect.field(songData, 'speed') == null)
			songData.speed = 1;
		if(!Reflect.hasField(songData, 'bpm') || Reflect.field(songData, 'bpm') == null)
			songData.bpm = firstSectionBpm(songData.notes, 100);

		songData.player = normalizeGodotChartCharacter(songData.player, 'bf');
		songData.girlfriend = normalizeGodotChartCharacter(songData.girlfriend, 'gf');
		songData.opponent = normalizeGodotChartCharacter(songData.opponent, 'dad');
		if(songData.stage != null && songData.stage.trim().length > 0)
			songData.stage = normalizeGodotChartStage(songData.stage);
		else
			songData.stage = normalizeGodotChartStage('stage');

		songData.format = 'psych_v1_godot_convert';

		Reflect.deleteField(songData, 'validScore');
		Reflect.deleteField(songData, 'isPixelStage');
		Reflect.deleteField(songData, 'two opponents');
		Reflect.deleteField(songData, 'player3');

		cleanGodotSections(songData.notes);
		return songData;
	}

	static function parseNightmareVisionChart(raw:String, fileName:String):SwagSong
	{
		return parseGodotChart(raw, fileName);
	}

	public static function convertCodenameChart(chartRaw:String, metaRaw:String, chartPath:String):String
	{
		var songData:SwagSong = parseCodenameChart(chartRaw, metaRaw, chartPath);
		return PsychJsonPrinter.print(songData, ['sectionNotes', 'events']);
	}

	static function parseCodenameChart(chartRaw:String, metaRaw:String, chartPath:String):SwagSong
	{
		var chart:Dynamic = Json.parse(chartRaw);
		var meta:Dynamic = Json.parse(metaRaw);
		if(chart == null || meta == null)
			throw new Exception('chart.json or meta.json is empty.');

		var songName:String = codenameChartString(meta, ['name', 'songName', 'displayName', 'song'], codenameChartPathBase(chartPath));
		var bpm:Float = codenameChartFloat(meta, ['bpm', 'BPM'], codenameChartFloat(chart, ['bpm', 'BPM'], 100));
		if(Math.isNaN(bpm) || bpm <= 0) bpm = 100;

		var converted:SwagSong =
		{
			song: songName,
			notes: [],
			events: [],
			bpm: bpm,
			needsVoices: codenameChartBool(meta, ['needsVoices', 'needVoices', 'hasVoices', 'voices'], true),
			speed: codenameChartFloat(chart, ['scrollSpeed', 'speed'], codenameChartFloat(meta, ['scrollSpeed', 'speed'], 1)),
			offset: codenameChartFloat(meta, ['offset', 'songOffset'], 0),
			player: normalizeGodotChartCharacter(codenameChartString(meta, ['player', 'bf', 'boyfriend'], 'bf'), 'bf'),
			girlfriend: normalizeGodotChartCharacter(codenameChartString(meta, ['girlfriend', 'gf'], 'gf'), 'gf'),
			opponent: normalizeGodotChartCharacter(codenameChartString(meta, ['opponent', 'dad'], 'dad'), 'dad'),
			stage: normalizeGodotChartStage(codenameChartString(chart, ['stage', 'stageName'], codenameChartString(meta, ['stage', 'stageName'], 'stage'))),
			format: 'psych_v1_codename_convert'
		};

		var strumLines:Array<Dynamic> = codenameChartArray(chart, ['strumLines', 'strumlines', 'strums']);
		if(strumLines != null && strumLines.length > 0)
		{
			for (lineIndex in 0...strumLines.length)
			{
				var line:Dynamic = strumLines[lineIndex];
				var lineKind:String = codenameChartLineKind(line, lineIndex);
				var lineCharacter:String = codenameChartLineCharacter(line);
				if(lineCharacter.length > 0)
				{
					switch(lineKind)
					{
						case 'player': converted.player = normalizeGodotChartCharacter(lineCharacter, converted.player);
						case 'gf': converted.girlfriend = normalizeGodotChartCharacter(lineCharacter, converted.girlfriend);
						default: converted.opponent = normalizeGodotChartCharacter(lineCharacter, converted.opponent);
					}
				}

				var lineNotes:Array<Dynamic> = codenameChartArray(line, ['notes', 'chart']);
				if(lineNotes == null) continue;
				for (note in lineNotes)
					addCodenameChartNote(converted, note, lineKind, bpm);
			}
		}
		else
		{
			var rootNotes:Array<Dynamic> = codenameChartArray(chart, ['notes', 'chart']);
			if(rootNotes == null)
				throw new Exception('chart.json needs "strumLines" or "notes".');
			for (note in rootNotes)
				addCodenameChartNote(converted, note, 'player', bpm);
		}

		var chartEvents:Array<Dynamic> = codenameChartArray(chart, ['events']);
		if(chartEvents != null)
		{
			for (event in chartEvents)
				addCodenameChartEvent(converted, event, bpm);
		}

		if(converted.notes.length < 1)
			converted.notes.push(makeCodenameChartSection());

		finalizeCodenameSections(converted);
		return converted;
	}

	/** Fix camera focus: opponent/GF-only sections get mustHitSection=false and lanes remapped. */
	static function finalizeCodenameSections(song:SwagSong):Void
	{
		if(song == null || song.notes == null) return;
		for (section in song.notes)
		{
			if(section == null || section.sectionNotes == null) continue;
			var hasPlayer:Bool = false;
			var hasOpponent:Bool = false;
			for (n in section.sectionNotes)
			{
				if(n == null || !Std.isOfType(n, Array)) continue;
				var arr:Array<Dynamic> = cast n;
				if(arr.length < 2) continue;
				var nd:Int = Std.int(codenameChartToFloat(arr[1], 0));
				if(nd >= 4) hasOpponent = true;
				else hasPlayer = true;
			}

			// Opponent/GF only → camera on opponent, remap 4-7 → 0-3
			if(hasOpponent && !hasPlayer)
			{
				section.mustHitSection = false;
				for (n in section.sectionNotes)
				{
					if(n == null || !Std.isOfType(n, Array)) continue;
					var arr:Array<Dynamic> = cast n;
					if(arr.length < 2) continue;
					var nd:Int = Std.int(codenameChartToFloat(arr[1], 0));
					if(nd >= 4) arr[1] = nd - 4;
					else arr[1] = nd + 4;
				}
			}
			else
			{
				section.mustHitSection = true;
			}
		}
	}

	static function addCodenameChartNote(song:SwagSong, note:Dynamic, lineKind:String, bpm:Float):Void
	{
		var strumTime:Float = codenameChartNoteTime(note, bpm);
		var lane:Int = codenameChartNoteLane(note);
		if(lane < 0) return;

		// Psych with mustHitSection=true:
		//   noteData 0-3 = player side, 4-7 = opponent side
		var noteData:Int = lane % 4;
		switch(lineKind)
		{
			case 'player':
				// player stays 0-3
			case 'gf':
				// GF sits on opponent side of the grid (4-7) + gfSection
				noteData += 4;
			default:
				// opponent 4-7
				noteData += 4;
		}

		var sustain:Float = codenameChartNoteSustain(note, bpm);
		var noteType:String = codenameChartNoteType(note);
		var noteDataArray:Array<Dynamic> = [strumTime, noteData, sustain];
		if(noteType.length > 0) noteDataArray.push(noteType);

		var section:SwagSection = getCodenameChartSection(song, strumTime, bpm);
		if(lineKind == 'gf') section.gfSection = true;
		section.sectionNotes.push(noteDataArray);
	}

	static function addCodenameChartEvent(song:SwagSong, event:Dynamic, bpm:Float):Void
	{
		var strumTime:Float = codenameChartEventTime(event, bpm);
		var eventName:String = codenameChartEventName(event);
		if(eventName.length < 1) return;

		var values:Array<Dynamic> = codenameChartEventValues(event);
		var value1:Dynamic = values.length > 0 ? values[0] : '';
		var value2:Dynamic = values.length > 1 ? values[1] : '';
		if(values.length > 2) value2 = values.slice(1).join(',');
		song.events.push([strumTime, [[eventName, value1, value2]]]);
	}

	static function getCodenameChartSection(song:SwagSong, strumTime:Float, bpm:Float):SwagSection
	{
		var sectionLength:Float = (60000 / bpm) * 4;
		var sectionIndex:Int = Std.int(Math.max(0, Math.floor(strumTime / sectionLength)));
		while(song.notes.length <= sectionIndex)
			song.notes.push(makeCodenameChartSection());
		return song.notes[sectionIndex];
	}

	static function makeCodenameChartSection():SwagSection
	{
		return {
			sectionNotes: [],
			sectionBeats: 4,
			mustHitSection: true,
			altAnim: false,
			gfSection: false,
			changeBPM: false
		};
	}

	static function codenameChartLineKind(line:Dynamic, index:Int):String
	{
		var position:String = codenameChartString(line, ['position', 'pos', 'side', 'type'], '').toLowerCase();
		if(position.contains('gf') || position.contains('girl')) return 'gf';
		if(position.contains('bf') || position.contains('boyfriend') || position.contains('player')) return 'player';
		if(position.contains('dad') || position.contains('opponent') || position.contains('enemy')) return 'opponent';

		var typeValue:Dynamic = Reflect.field(line, 'type');
		var typeId:Int = Std.int(codenameChartToFloat(typeValue, index));
		if(typeId == 1) return 'player';
		if(typeId == 2) return 'gf';
		return index == 1 ? 'player' : 'opponent';
	}

	static function codenameChartLineCharacter(line:Dynamic):String
	{
		var chars:Array<Dynamic> = codenameChartArray(line, ['characters', 'chars']);
		if(chars != null)
		{
			for (char in chars)
			{
				var name:String = Std.isOfType(char, String) ? Std.string(char) : codenameChartString(char, ['name', 'character', 'id'], '');
				name = Paths.formatToSongPath(name);
				if(name.length > 0) return name;
			}
		}
		return Paths.formatToSongPath(codenameChartString(line, ['character', 'char', 'name'], ''));
	}

	static function codenameChartNoteTime(note:Dynamic, bpm:Float):Float
	{
		if(Std.isOfType(note, Array))
		{
			var arr:Array<Dynamic> = cast note;
			return arr.length > 0 ? codenameChartToFloat(arr[0], 0) : 0;
		}
		var time:Float = codenameChartFloat(note, ['time', 'strumTime', 't'], -1);
		if(time >= 0) return time;
		var beat:Float = codenameChartFloat(note, ['beat', 'beats'], -1);
		if(beat >= 0) return beat * (60000 / bpm);
		var step:Float = codenameChartFloat(note, ['step', 'steps'], -1);
		return step >= 0 ? step * (60000 / bpm) / 4 : 0;
	}

	static function codenameChartNoteLane(note:Dynamic):Int
	{
		if(Std.isOfType(note, Array))
		{
			var arr:Array<Dynamic> = cast note;
			return arr.length > 1 ? Std.int(codenameChartToFloat(arr[1], 0)) : 0;
		}
		return Std.int(codenameChartFloat(note, ['id', 'lane', 'data', 'noteData', 'direction'], 0));
	}

	static function codenameChartNoteSustain(note:Dynamic, bpm:Float = 100):Float
	{
		var raw:Float = 0;
		if(Std.isOfType(note, Array))
		{
			var arr:Array<Dynamic> = cast note;
			raw = arr.length > 2 ? codenameChartToFloat(arr[2], 0) : 0;
		}
		else
		{
			raw = codenameChartFloat(note, ['sustainLength', 'length', 'sLen', 'slen', 'duration', 'hold', 'sus'], 0);
		}
		if(raw <= 0) return 0;

		// Codename often stores sustain in steps; if value is small treat as steps → ms
		// Heuristic: values under 200 are likely steps/beats, not milliseconds.
		if(raw < 200)
		{
			var stepMs:Float = (60000 / (bpm > 0 ? bpm : 100)) / 4;
			// Prefer steps (Codename default); if field name was beat-like, still close enough
			return raw * stepMs;
		}
		return raw;
	}

	static function codenameChartNoteType(note:Dynamic):String
	{
		if(Std.isOfType(note, Array))
		{
			var arr:Array<Dynamic> = cast note;
			return arr.length > 3 && arr[3] != null ? Std.string(arr[3]) : '';
		}
		return codenameChartString(note, ['type', 'noteType', 'kind'], '');
	}

	static function codenameChartEventTime(event:Dynamic, bpm:Float):Float
	{
		if(Std.isOfType(event, Array))
		{
			var arr:Array<Dynamic> = cast event;
			return arr.length > 0 ? codenameChartToFloat(arr[0], 0) : 0;
		}
		var time:Float = codenameChartFloat(event, ['time', 'strumTime', 't'], -1);
		if(time >= 0) return time;
		var beat:Float = codenameChartFloat(event, ['beat', 'beats'], -1);
		return beat >= 0 ? beat * (60000 / bpm) : 0;
	}

	static function codenameChartEventName(event:Dynamic):String
	{
		if(Std.isOfType(event, Array))
		{
			var arr:Array<Dynamic> = cast event;
			return arr.length > 1 && arr[1] != null ? Std.string(arr[1]) : '';
		}
		return codenameChartString(event, ['name', 'event', 'eventName'], '');
	}

	static function codenameChartEventValues(event:Dynamic):Array<Dynamic>
	{
		if(Std.isOfType(event, Array))
		{
			var arr:Array<Dynamic> = cast event;
			return arr.length > 2 ? arr.slice(2) : [];
		}

		var params:Array<Dynamic> = codenameChartArray(event, ['params', 'parameters', 'values']);
		if(params != null) return params.copy();

		var values:Array<Dynamic> = [];
		var value1:Dynamic = Reflect.field(event, 'value1');
		var value2:Dynamic = Reflect.field(event, 'value2');
		if(value1 != null) values.push(value1);
		if(value2 != null) values.push(value2);
		return values;
	}

	static function codenameChartString(data:Dynamic, names:Array<String>, fallback:String):String
	{
		if(data == null) return fallback;
		for (name in names)
		{
			var value:Dynamic = Reflect.field(data, name);
			if(value == null) continue;
			var text:String = Std.string(value);
			if(text.length > 0) return text;
		}
		return fallback;
	}

	static function codenameChartBool(data:Dynamic, names:Array<String>, fallback:Bool):Bool
	{
		if(data == null) return fallback;
		for (name in names)
		{
			var value:Dynamic = Reflect.field(data, name);
			if(value == null) continue;
			if(Std.isOfType(value, Bool)) return cast value;
			var text:String = Std.string(value).toLowerCase();
			if(text == 'true' || text == '1' || text == 'yes') return true;
			if(text == 'false' || text == '0' || text == 'no') return false;
		}
		return fallback;
	}

	static function codenameChartFloat(data:Dynamic, names:Array<String>, fallback:Float):Float
	{
		if(data == null) return fallback;
		for (name in names)
		{
			var value:Dynamic = Reflect.field(data, name);
			if(value == null) continue;
			var parsed:Float = codenameChartToFloat(value, fallback);
			if(!Math.isNaN(parsed)) return parsed;
		}
		return fallback;
	}

	static function codenameChartArray(data:Dynamic, names:Array<String>):Array<Dynamic>
	{
		if(data == null) return null;
		for (name in names)
		{
			var value:Dynamic = Reflect.field(data, name);
			if(value == null) continue;
			if(Std.isOfType(value, Array)) return cast value;

			var fields:Array<String> = Reflect.fields(value);
			if(fields.length > 0)
			{
				var output:Array<Dynamic> = [];
				for (field in fields)
					output.push(Reflect.field(value, field));
				return output;
			}
		}
		return null;
	}

	static function codenameChartToFloat(value:Dynamic, fallback:Float):Float
	{
		if(value == null) return fallback;
		var parsed:Float = Std.parseFloat(Std.string(value));
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	static function codenameChartPathBase(path:String):String
	{
		if(path == null || path.length < 1) return 'codename-song';
		var clean:String = path.replace('\\', '/');
		if(clean.contains('/')) clean = clean.substr(0, clean.lastIndexOf('/'));
		if(clean.contains('/')) clean = clean.substr(clean.lastIndexOf('/') + 1);
		if(clean.length < 1) clean = 'codename-song';
		return Paths.formatToSongPath(clean);
	}

	static function cleanGodotSections(sections:Array<SwagSection>)
	{
		if(sections == null) return;

		for (section in sections)
		{
			if(section == null) continue;

			if(!Reflect.hasField(section, 'sectionBeats') || Reflect.field(section, 'sectionBeats') == null)
				section.sectionBeats = floatField(section, ['lengthInSteps'], 16) / 4;
			if(section.sectionNotes == null)
				section.sectionNotes = [];

			for (note in section.sectionNotes)
			{
				if(note == null || !Std.isOfType(note, Array)) continue;

				var noteData:Array<Dynamic> = cast note;
				if(noteData.length > 0) noteData[0] = Std.parseFloat(Std.string(noteData[0]));
				if(noteData.length > 1) noteData[1] = Std.int(Std.parseFloat(Std.string(noteData[1])));
				if(noteData.length > 2) noteData[2] = Std.parseFloat(Std.string(noteData[2]));
				while(noteData.length > 3 && noteData[noteData.length - 1] == null)
					noteData.pop();
			}

			Reflect.deleteField(section, 'lengthInSteps');
			Reflect.deleteField(section, 'typeOfSection');
		}
	}

	static function normalizeGodotChartCharacter(character:String, fallback:String):String
	{
		if(character == null || character.trim().length < 1) return fallback;

		return switch(Paths.formatToSongPath(character))
		{
			case 'boyfriend-remake':
				'bf-remake';
			case 'picoremake' | 'pico-remake':
				'pico-remake';
			case 'girlfriend-remake':
				'gf';
			case 'boyfriend-dead-remake':
				'bf-dead';
			case 'spooky-kids-remake':
				'spooky';
			case 'daddydearest-remake':
				'dad';
			case 'tankman-remake':
				'tankman';
			default:
				Paths.formatToSongPath(character);
		}
	}

	static function normalizeGodotChartStage(stage:String):String
	{
		return switch(Paths.formatToSongPath(stage))
		{
			case 'stage' | 'stage-remix':
				'mainStage';
			case 'spooky-mansion' | 'spooky-mansion-remix':
				'spookyMansion';
			case 'philly':
				'philly';
			case 'philly-remix':
				'philly_remix';
			case 'limo':
				'limoRide';
			case 'mall':
				'mall';
			case 'evil-mall':
				'mallEvil';
			case 'school' | 'school-remix':
				'school';
			case 'school-evil' | 'school-evil-remix':
				'schoolEvil';
			case 'battlefield' | 'battlefield-remix':
				'tank';
			default:
				Paths.formatToSongPath(stage);
		}
	}

	static function firstSectionBpm(sections:Array<SwagSection>, fallback:Float):Float
	{
		if(sections != null)
		{
			for (section in sections)
			{
				if(section == null) continue;
				var bpm:Dynamic = Reflect.field(section, 'bpm');
				if(bpm == null) continue;

				var parsed = Std.parseFloat(Std.string(bpm));
				if(!Math.isNaN(parsed) && parsed > 0) return parsed;
			}
		}
		return fallback;
	}

	static function getReadableSongName(fileName:String):String
	{
		var base = getFileBase(fileName);
		var formatted = Paths.formatToSongPath(base);
		for (diff in ['easy', 'normal', 'hard', 'remix'])
		{
			var suffix = '-$diff';
			if(formatted.endsWith(suffix))
			{
				formatted = formatted.substr(0, formatted.length - suffix.length);
				break;
			}
		}
		return formatted;
	}

	public static function convertGodotCharacter(raw:String, fileName:String):String
	{
		var godot:Dynamic = Json.parse(raw);
		var baseName = Paths.formatToSongPath(fileName);
		var poses:Array<Dynamic> = cast Reflect.field(godot, 'Poses');
		var animations:Array<Dynamic> = [];

		if(poses != null)
		{
			for (pose in poses)
			{
				var sourceAnim = stringField(pose, ['Anim'], 'idle');
				var anim = normalizeGodotAnim(sourceAnim);
				var name = stringField(pose, ['Name'], sourceAnim);
				var offsets = pointField(pose, ['Offset'], [0, 0]);
				var loop = anim == 'idle' && boolField(godot, ['LoopAnim', 'loopAnim'], true);

				animations.push(makeAnimation(anim, name, intPoint(offsets), intField(pose, ['fps', 'FPS'], 24), loop));
			}
		}

		var isPlayer = boolField(godot, ['isPlayer'], false);
		var color = colorField(godot, ['HealthBarColor'], [161, 161, 161]);
		var camera = pointField(godot, ['cameraPos'], [0, 0]);
		var scale = pointField(godot, ['scale'], [1, 1]);
		var godotFlipX = boolField(godot, ['FlipX'], false);

		return printCharacter({
			animations: animations,
			image: 'characters/dot/$baseName',
			scale: scale.length > 0 ? scale[0] : 1,
			sing_duration: floatField(godot, ['anim time', 'Anim Time'], 4),
			healthicon: iconField(godot, ['HealthIcon', 'healthIcon'], baseName),
			position: [0, 0],
			camera_position: intPoint(camera),
			flip_x: godotFlipX,
			no_antialiasing: false,
			healthbar_colors: color,
			vocals_file: '',
			characterType: isPlayer ? 'Player' : 'Opponent',
			_editor_isPlayer: isPlayer
		});
	}

	static function convertCodenameXmlCharacter(raw:String, fileName:String):String
	{
		var doc = Xml.parse(raw);
		var root = firstXmlElement(doc, 'character');
		if(root == null) throw new Exception('Could not find <character> root.');

		var baseName = Paths.formatToSongPath(fileName);
		var isPlayer = xmlBool(root, 'isPlayer', predictCharacterType(baseName) == 'Player');
		var visualFlipX = xmlBool(root, 'flipX', false);
		var animations:Array<Dynamic> = [];

		for (animNode in root.elementsNamed('anim'))
		{
			var anim = normalizeAnimName(xmlString(animNode, 'name', 'idle'));
			var prefix = xmlString(animNode, 'anim', anim);
			var fps = Std.int(xmlFloat(animNode, 'fps', 24));
			var loop = xmlBool(animNode, 'loop', false);
			var offsets = [Std.int(xmlFloat(animNode, 'x', 0)), Std.int(xmlFloat(animNode, 'y', 0))];
			animations.push(makeAnimation(anim, prefix, offsets, fps, loop));
		}

		var characterType:String = isPlayer ? 'Player' : predictCharacterType(baseName);
		// Preserve visual flipX from XML; Psych also stores editor player flag separately
		return printCharacter({
			animations: animations,
			image: normalizeAssetPath(xmlString(root, 'sprite', baseName), baseName),
			scale: xmlFloat(root, 'scale', 1),
			sing_duration: xmlFloat(root, 'singTime', 4),
			healthicon: xmlString(root, 'icon', baseName),
			position: [Std.int(xmlFloat(root, 'x', 0)), Std.int(xmlFloat(root, 'y', 0))],
			camera_position: [Std.int(xmlFloat(root, 'camx', 0)), Std.int(xmlFloat(root, 'camy', 0))],
			flip_x: visualFlipX,
			no_antialiasing: !xmlBool(root, 'antialiasing', true),
			healthbar_colors: colorArrayField(xmlString(root, 'color', '#A1A1A1')),
			vocals_file: '',
			characterType: characterType,
			_editor_isPlayer: isPlayer || characterType == 'Player'
		});
	}

	static function convertGenericCharacter(raw:String, fileName:String, source:String):String
	{
		var data:Dynamic = Json.parse(raw);
		var baseName = Paths.formatToSongPath(fileName);
		var characterType = normalizeCharacterType(stringField(data, ['characterType', 'character_type', 'type'], predictCharacterType(baseName)));
		var isPlayer = boolField(data, ['isPlayer', 'is_player', '_editor_isPlayer'], characterType == 'Player');
		if(isPlayer) characterType = 'Player';

		var animations:Array<Dynamic> = [];
		var sourceAnimations:Array<Dynamic> = cast firstField(data, ['animations', 'anims', 'Poses']);
		if(sourceAnimations != null)
		{
			for (animData in sourceAnimations)
			{
				var anim = normalizeAnimName(animationId(animData, source));
				var prefix = animationPrefix(animData, source, anim);
				var offsets = intPoint(pointField(animData, ['offsets', 'offset', 'Offset'], [0, 0]));
				var fps = intField(animData, ['fps', 'FPS', 'frameRate', 'framerate', 'frame_rate'], 24);
				var loop = boolField(animData, ['loop', 'looped', 'LoopAnim', 'loopAnim'], false);
				animations.push(makeAnimation(anim, prefix, offsets, fps, loop));
			}
		}

		var image = normalizeAssetPath(stringField(data, ['image', 'assetPath', 'sprite', 'spritesheet', 'texture', 'asset'], baseName), baseName);
		var visualFlipX = boolField(data, ['flipX', 'FlipX', 'flip_x'], false);
		var position = pointField(data, source == SOURCE_VSLICE ? ['offsets', 'position', 'globalOffset'] : ['position', 'globalOffset', 'positionOffset', 'offsets'], [0, 0]);
		var camera = pointField(data, ['camera_position', 'cameraPosition', 'cameraOffsets', 'cameraOffset', 'camera'], [0, 0]);

		return printCharacter({
			animations: animations,
			image: image,
			scale: floatField(data, ['scale'], 1),
			sing_duration: floatField(data, ['sing_duration', 'singTime', 'sing_time', 'holdTime'], 4),
			healthicon: iconField(data, ['healthicon', 'healthIcon', 'icon', 'iconName'], baseName),
			position: intPoint(position),
			camera_position: intPoint(camera),
			flip_x: visualFlipX,
			no_antialiasing: boolField(data, ['no_antialiasing', 'noAntialiasing'], !boolField(data, ['antialiasing', 'antialias'], true)),
			healthbar_colors: colorField(data, ['healthbar_colors', 'healthBarColor', 'healthbarColor', 'HealthBarColor', 'healthColor', 'color'], [161, 161, 161]),
			vocals_file: stringField(data, ['vocals_file', 'vocalsFile'], ''),
			characterType: characterType,
			_editor_isPlayer: isPlayer || characterType == 'Player'
		});
	}

	static function makeAnimation(anim:String, name:String, offsets:Array<Int>, fps:Int, loop:Bool):Dynamic
	{
		return {
			anim: anim,
			name: name,
			fps: fps,
			loop: loop,
			indices: [],
			offsets: offsets
		};
	}

	static function printCharacter(character:Dynamic):String
	{
		return PsychJsonPrinter.print(character, ['offsets', 'position', 'healthbar_colors', 'camera_position', 'indices']);
	}

	static function animationId(animData:Dynamic, source:String):String
	{
		return switch(source)
		{
			case SOURCE_CODENAME:
				stringField(animData, ['name', 'anim', 'id'], 'idle');
			case SOURCE_VSLICE:
				stringField(animData, ['name', 'id', 'anim'], 'idle');
			default:
				stringField(animData, ['anim', 'name', 'id'], 'idle');
		}
	}

	static function animationPrefix(animData:Dynamic, source:String, fallback:String):String
	{
		return switch(source)
		{
			case SOURCE_CODENAME:
				stringField(animData, ['anim', 'prefix', 'name'], fallback);
			case SOURCE_VSLICE:
				stringField(animData, ['prefix', 'name', 'anim'], fallback);
			default:
				stringField(animData, ['name', 'prefix', 'anim'], fallback);
		}
	}

	static function normalizeGodotAnim(anim:String):String
	{
		return switch(Paths.formatToSongPath(anim))
		{
			case 'idle' | 'idle-dance':
				'idle';
			case 'singleft' | 'sing-left':
				'singLEFT';
			case 'singdown' | 'sing-down':
				'singDOWN';
			case 'singup' | 'sing-up':
				'singUP';
			case 'singright' | 'sing-right':
				'singRIGHT';
			case 'singleft-miss' | 'singleftmiss' | 'sing-left-miss':
				'singLEFTmiss';
			case 'singdown-miss' | 'singdownmiss' | 'sing-down-miss':
				'singDOWNmiss';
			case 'singup-miss' | 'singupmiss' | 'sing-up-miss':
				'singUPmiss';
			case 'singright-miss' | 'singrightmiss' | 'sing-right-miss':
				'singRIGHTmiss';
			default:
				anim;
		}
	}

	static function normalizeAnimName(anim:String):String
	{
		return switch(Paths.formatToSongPath(anim))
		{
			case 'idle' | 'idle-dance':
				'idle';
			case 'singleft' | 'sing-left':
				'singLEFT';
			case 'singdown' | 'sing-down':
				'singDOWN';
			case 'singup' | 'sing-up':
				'singUP';
			case 'singright' | 'sing-right':
				'singRIGHT';
			case 'singleftmiss' | 'singleft-miss' | 'sing-left-miss':
				'singLEFTmiss';
			case 'singdownmiss' | 'singdown-miss' | 'sing-down-miss':
				'singDOWNmiss';
			case 'singupmiss' | 'singup-miss' | 'sing-up-miss':
				'singUPmiss';
			case 'singrightmiss' | 'singright-miss' | 'sing-right-miss':
				'singRIGHTmiss';
			default:
				anim;
		}
	}

	static function normalizeAssetPath(path:String, fileName:String):String
	{
		var clean = path == null || path.trim().length < 1 ? fileName : path.trim();
		clean = clean.replace('\\', '/');
		if(clean.contains(':')) clean = clean.substr(clean.lastIndexOf(':') + 1);
		if(clean.startsWith('assets/'))
		{
			var imageIndex = clean.indexOf('/images/');
			if(imageIndex > -1) clean = clean.substr(imageIndex + 8);
		}
		if(clean.startsWith('images/')) clean = clean.substr(7);
		if(clean.endsWith('.png') || clean.endsWith('.xml') || clean.endsWith('.json'))
			clean = clean.substr(0, clean.lastIndexOf('.'));
		if(!clean.contains('/')) clean = 'characters/$clean';
		return clean;
	}

	static function normalizeCharacterType(type:String):String
	{
		if(type == null) return 'Opponent';
		return switch(Paths.formatToSongPath(type.trim()))
		{
			case 'player' | 'playable' | 'bf' | 'boyfriend':
				'Player';
			case 'additional' | 'addtinal' | 'extra' | 'gf' | 'girlfriend':
				'Additional';
			default:
				'Opponent';
		}
	}

	static function predictCharacterType(name:String):String
	{
		var formatted = Paths.formatToSongPath(name);
		if(formatted == 'gf' || formatted.startsWith('gf-') || formatted.endsWith('-gf') || formatted.endsWith('-speaker') || formatted == 'none')
			return 'Additional';
		if(formatted == 'bf' || formatted.startsWith('bf-') || formatted.endsWith('-player') || formatted.endsWith('-playable') || formatted.endsWith('-dead') || formatted.endsWith('-death'))
			return 'Player';
		return 'Opponent';
	}

	static function firstField(data:Dynamic, names:Array<String>):Dynamic
	{
		for (name in names)
		{
			var value:Dynamic = Reflect.field(data, name);
			if(value != null) return value;
		}
		return null;
	}

	static function stringField(data:Dynamic, names:Array<String>, fallback:String):String
	{
		for (name in names)
		{
			var value:Dynamic = Reflect.field(data, name);
			if(value == null) continue;
			if(Std.isOfType(value, String)) return Std.string(value);
		}
		return fallback;
	}

	static function iconField(data:Dynamic, names:Array<String>, fallback:String):String
	{
		for (name in names)
		{
			var value:Dynamic = Reflect.field(data, name);
			if(value == null) continue;
			if(Std.isOfType(value, String)) return Std.string(value);

			var id:Dynamic = Reflect.field(value, 'id');
			if(id != null) return Std.string(id);
			var iconName:Dynamic = Reflect.field(value, 'name');
			if(iconName != null) return Std.string(iconName);
		}
		return fallback;
	}

	static function boolField(data:Dynamic, names:Array<String>, fallback:Bool):Bool
	{
		for (name in names)
		{
			var value:Dynamic = Reflect.field(data, name);
			if(value == null) continue;
			if(Std.isOfType(value, Bool)) return cast value;

			var clean = Std.string(value).toLowerCase().trim();
			if(clean == 'true') return true;
			if(clean == 'false') return false;
		}
		return fallback;
	}

	static function intField(data:Dynamic, names:Array<String>, fallback:Int):Int
	{
		return Std.int(floatField(data, names, fallback));
	}

	static function floatField(data:Dynamic, names:Array<String>, fallback:Float):Float
	{
		for (name in names)
		{
			var value:Dynamic = Reflect.field(data, name);
			if(value == null) continue;

			var parsed = Std.parseFloat(Std.string(value));
			if(!Math.isNaN(parsed)) return parsed;
		}
		return fallback;
	}

	static function pointField(data:Dynamic, names:Array<String>, fallback:Array<Float>):Array<Float>
	{
		for (name in names)
		{
			var value:Dynamic = Reflect.field(data, name);
			var parsed = parsePoint(value, fallback);
			if(parsed != null) return parsed;
		}
		return fallback.copy();
	}

	static function parsePoint(value:Dynamic, fallback:Array<Float>):Array<Float>
	{
		if(value == null) return null;

		if(Std.isOfType(value, Array))
		{
			var arr:Array<Dynamic> = cast value;
			if(arr.length < 1) return null;

			var output:Array<Float> = [];
			for (item in arr)
			{
				var parsed = Std.parseFloat(Std.string(item));
				output.push(Math.isNaN(parsed) ? 0 : parsed);
			}
			while(output.length < fallback.length) output.push(fallback[output.length]);
			return output;
		}

		var x:Dynamic = Reflect.field(value, 'x');
		var y:Dynamic = Reflect.field(value, 'y');
		if(x != null || y != null)
		{
			var parsedX = x == null ? fallback[0] : Std.parseFloat(Std.string(x));
			var parsedY = y == null ? fallback[1] : Std.parseFloat(Std.string(y));
			return [Math.isNaN(parsedX) ? fallback[0] : parsedX, Math.isNaN(parsedY) ? fallback[1] : parsedY];
		}

		return null;
	}

	static function intPoint(point:Array<Float>):Array<Int>
	{
		return [Std.int(point[0]), Std.int(point[1])];
	}

	static function colorField(data:Dynamic, names:Array<String>, fallback:Array<Int>):Array<Int>
	{
		for (name in names)
		{
			var value:Dynamic = Reflect.field(data, name);
			if(value == null) continue;

			if(Std.isOfType(value, Array))
			{
				var arr:Array<Dynamic> = cast value;
				if(arr.length >= 3) return [
					Std.int(Std.parseFloat(Std.string(arr[0]))),
					Std.int(Std.parseFloat(Std.string(arr[1]))),
					Std.int(Std.parseFloat(Std.string(arr[2])))
				];
			}

			return colorArrayField(Std.string(value));
		}
		return fallback.copy();
	}

	static function colorArrayField(hex:String):Array<Int>
	{
		if(hex == null) return [161, 161, 161];
		var clean = hex.trim();
		if(clean.startsWith('#')) clean = clean.substr(1);
		if(clean.startsWith('0x')) clean = clean.substr(2);
		if(clean.length < 6) return [161, 161, 161];

		return [
			parseHexByte(clean.substr(0, 2)),
			parseHexByte(clean.substr(2, 2)),
			parseHexByte(clean.substr(4, 2))
		];
	}

	static function parseHexByte(value:String):Int
	{
		var parsed:Null<Int> = Std.parseInt('0x' + value);
		return parsed == null ? 0 : parsed;
	}

	static function firstXmlElement(xml:Xml, name:String):Xml
	{
		if(xml.nodeType == Xml.Element && xml.nodeName == name) return xml;
		for (child in xml.elements())
		{
			var found = firstXmlElement(child, name);
			if(found != null) return found;
		}
		return null;
	}

	static function xmlString(xml:Xml, name:String, fallback:String):String
	{
		var value = xml.get(name);
		return value == null ? fallback : value;
	}

	static function xmlBool(xml:Xml, name:String, fallback:Bool):Bool
	{
		var value = xml.get(name);
		if(value == null) return fallback;
		var clean = value.toLowerCase().trim();
		if(clean == 'true') return true;
		if(clean == 'false') return false;
		return fallback;
	}

	static function xmlFloat(xml:Xml, name:String, fallback:Float):Float
	{
		var value = xml.get(name);
		if(value == null) return fallback;
		var parsed = Std.parseFloat(value);
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	static function firstStageXmlElement(xml:Xml):Xml
	{
		if(xml.nodeType == Xml.Element)
		{
			var name = xml.nodeName.toLowerCase();
			if(name != 'textureatlas' && name != 'subtexture')
				return xml;
		}

		for (child in xml.elements())
		{
			var found = firstStageXmlElement(child);
			if(found != null) return found;
		}
		return null;
	}

	static function findStageCharacterNode(root:Xml, aliases:Array<String>):Xml
	{
		if(root == null) return null;

		for (child in root.elements())
		{
			var nodeName = Paths.formatToSongPath(child.nodeName);
			if(aliases.contains(nodeName)) return child;

			var role = Paths.formatToSongPath(xmlStringAny(child, ['role', 'target', 'characterType'], ''));
			if(role.length > 0 && aliases.contains(role)) return child;

			var found = findStageCharacterNode(child, aliases);
			if(found != null) return found;
		}
		return null;
	}

	static function collectStageObjects(root:Xml, objects:Array<Dynamic>, startIndex:Int):Int
	{
		var index = startIndex;
		for (child in root.elements())
		{
			if(isStageObjectNode(child))
			{
				objects.push(convertXmlStageObject(child, objects, index));
				index++;
			}
			else if(!isStageCharacterNode(child) && !isStageAnimationNode(child))
			{
				index = collectStageObjects(child, objects, index);
			}
		}
		return index;
	}

	static function isStageCharacterNode(xml:Xml):Bool
	{
		var nodeName = Paths.formatToSongPath(xml.nodeName);
		return ['gf', 'girlfriend', 'dad', 'opponent', 'enemy', 'bf', 'boyfriend', 'player'].contains(nodeName);
	}

	static function isStageAnimationNode(xml:Xml):Bool
	{
		var nodeName = Paths.formatToSongPath(xml.nodeName);
		return nodeName == 'anim' || nodeName == 'animation';
	}

	static function isStageObjectNode(xml:Xml):Bool
	{
		var nodeName = Paths.formatToSongPath(xml.nodeName);
		if(['sprite', 'animatedsprite', 'animated-sprite', 'sparrow', 'object', 'prop', 'image', 'graphic', 'background', 'foreground', 'square', 'rect', 'solid'].contains(nodeName))
			return true;

		var typeName = Paths.formatToSongPath(xmlStringAny(xml, ['type', 'kind'], ''));
		return ['sprite', 'animatedsprite', 'animated-sprite', 'sparrow', 'object', 'prop', 'image', 'graphic', 'background', 'foreground', 'square', 'rect', 'solid', 'beat', 'loop', 'onbeat', 'dance', 'none'].contains(typeName);
	}

	static function convertXmlStageObject(xml:Xml, objects:Array<Dynamic>, index:Int):Dynamic
	{
		var nodeName = Paths.formatToSongPath(xml.nodeName);
		var typeName = Paths.formatToSongPath(xmlStringAny(xml, ['type', 'kind'], nodeName));
		var isSquare = ['square', 'rect', 'solid'].contains(typeName) || ['square', 'rect', 'solid'].contains(nodeName);
		// Codename: type="beat" / "loop" / "onbeat" = animated; type="none" = static
		var danceType = Paths.formatToSongPath(xmlStringAny(xml, ['type', 'kind', 'animType', 'dance'], ''));
		var animated = !isSquare && (
			typeName.contains('animated') || typeName == 'sparrow' || typeName == 'beat' || typeName == 'loop' || typeName == 'onbeat' || typeName == 'dance' ||
			nodeName.contains('animated') || nodeName == 'sparrow' ||
			danceType == 'beat' || danceType == 'loop' || danceType == 'onbeat' || danceType == 'dance' || danceType == 'sparrow' ||
			xmlBoolAny(xml, ['animated'], false) || xmlHasAnimationChildren(xml)
		);
		var type = isSquare ? 'square' : (animated ? 'animatedSprite' : 'sprite');
		var rawImage = xmlStringAny(xml, ['image', 'sprite', 'graphic', 'texture', 'asset', 'path', 'src', 'file'], '');
		var fallbackName = rawImage.length > 0 ? getFileBase(rawImage) : 'sprite$index';
		var name = uniqueStageObjectName(xmlStringAny(xml, ['name', 'id', 'tag'], fallbackName), objects);

		var obj:Dynamic = {
			type: type,
			name: name,
			x: xmlFloatAny(xml, ['x', 'posX', 'positionX'], 0),
			y: xmlFloatAny(xml, ['y', 'posY', 'positionY'], 0),
			scale: xmlPair(xml, ['scaleX', 'sx', 'scalex'], ['scaleY', 'sy', 'scaley', 'scale_y'], ['scale'], [1.0, 1.0]),
			scroll: xmlPair(xml, ['scrollX', 'scrollFactorX', 'parallaxX', 'scrollx'], ['scrollY', 'scrollFactorY', 'parallaxY', 'scrolly', 'scroll_y'], ['scroll', 'scrollFactor', 'parallax'], [1.0, 1.0]),
			alpha: xmlFloatAny(xml, ['alpha', 'opacity'], 1),
			angle: xmlFloatAny(xml, ['angle', 'rotation'], 0),
			color: normalizeStageColor(xmlStringAny(xml, ['color', 'tint'], 'FFFFFF')),
			filters: xmlStageFilters(xml)
		};

		if(type != 'square')
		{
			Reflect.setField(obj, 'flipX', xmlBoolAny(xml, ['flipX', 'flip_x'], false));
			Reflect.setField(obj, 'flipY', xmlBoolAny(xml, ['flipY', 'flip_y'], false));
			Reflect.setField(obj, 'image', normalizeStageImagePath(rawImage.length > 0 ? rawImage : name));
			Reflect.setField(obj, 'antialiasing', xmlBoolAny(xml, ['antialiasing', 'antialias', 'aa'], true));
		}

		if(type == 'animatedSprite')
		{
			var animations = xmlStageAnimations(xml);
			Reflect.setField(obj, 'animations', animations);
			if(animations.length > 0)
				Reflect.setField(obj, 'firstAnimation', Reflect.field(animations[0], 'anim'));
		}

		return obj;
	}

	static function xmlStageAnimations(xml:Xml):Array<Dynamic>
	{
		var animations:Array<Dynamic> = [];
		for (child in xml.elements())
		{
			if(!isStageAnimationNode(child)) continue;

			var animName = normalizeAnimName(xmlStringAny(child, ['name', 'id', 'anim'], 'idle'));
			var prefix = xmlStringAny(child, ['prefix', 'anim', 'symbol', 'name'], animName);
			var fps = Std.int(xmlFloatAny(child, ['fps', 'framerate', 'frameRate'], 24));
			var loop = xmlBoolAny(child, ['loop', 'looped'], animName == 'idle');
			var offset = intPoint(xmlPair(child, ['x', 'offsetX'], ['y', 'offsetY'], ['offset', 'offsets'], [0, 0]));
			var animation = makeAnimation(animName, prefix, offset, fps, loop);
			var indices = xmlIntList(xmlStringAny(child, ['indices', 'frames'], ''));
			if(indices.length > 0)
				Reflect.setField(animation, 'indices', indices);
			animations.push(animation);
		}
		return animations;
	}

	static function xmlHasAnimationChildren(xml:Xml):Bool
	{
		for (child in xml.elements())
			if(isStageAnimationNode(child)) return true;
		return false;
	}

	static function xmlStagePoint(root:Xml, node:Xml, prefixes:Array<String>, fallback:Array<Dynamic>):Array<Float>
	{
		var base = parsePackedPoint(xmlStringAny(root, prefixes, ''), [fallbackFloatAt(fallback, 0), fallbackFloatAt(fallback, 1)]);
		if(base == null) base = [fallbackFloatAt(fallback, 0), fallbackFloatAt(fallback, 1)];

		var xFallback = xmlPrefixedFloat(root, prefixes, ['x', 'posX', 'positionX'], base[0]);
		var yFallback = xmlPrefixedFloat(root, prefixes, ['y', 'posY', 'positionY'], base[1]);
		return [
			xmlFloatAny(node, ['x', 'posX', 'positionX'], xFallback),
			xmlFloatAny(node, ['y', 'posY', 'positionY'], yFallback)
		];
	}

	static function xmlStageCameraPoint(root:Xml, node:Xml, prefixes:Array<String>, fallback:Array<Float>):Array<Float>
	{
		var base = parsePackedPoint(xmlPrefixedString(root, prefixes, ['camera', 'cam', 'cameraOffset', 'camOffset'], ''), [fallback[0], fallback[1]]);
		if(base == null) base = [fallback[0], fallback[1]];

		var xFallback = xmlPrefixedFloat(root, prefixes, ['camX', 'cameraX', 'cameraOffsetX', 'camOffsetX'], base[0]);
		var yFallback = xmlPrefixedFloat(root, prefixes, ['camY', 'cameraY', 'cameraOffsetY', 'camOffsetY'], base[1]);
		return [
			xmlFloatAny(node, ['camX', 'cameraX', 'cameraOffsetX', 'camOffsetX'], xFallback),
			xmlFloatAny(node, ['camY', 'cameraY', 'cameraOffsetY', 'camOffsetY'], yFallback)
		];
	}

	static function xmlCharacterName(node:Xml, fallback:String):String
	{
		if(node == null) return fallback;
		var character = xmlStringAny(node, ['character', 'char', 'asset', 'sprite', 'id', 'name'], fallback);
		return normalizeGodotChartCharacter(character, fallback);
	}

	static function xmlStringAny(xml:Xml, names:Array<String>, fallback:String):String
	{
		if(xml == null) return fallback;
		for (name in names)
		{
			var value = xml.get(name);
			if(value != null && value.trim().length > 0) return value;
		}
		return fallback;
	}

	static function xmlBoolAny(xml:Xml, names:Array<String>, fallback:Bool):Bool
	{
		if(xml == null) return fallback;
		for (name in names)
		{
			var value = xml.get(name);
			if(value == null) continue;
			var clean = value.toLowerCase().trim();
			if(clean == 'true' || clean == '1' || clean == 'yes') return true;
			if(clean == 'false' || clean == '0' || clean == 'no') return false;
		}
		return fallback;
	}

	static function xmlFloatAny(xml:Xml, names:Array<String>, fallback:Float):Float
	{
		if(xml == null) return fallback;
		for (name in names)
		{
			var value = xml.get(name);
			if(value == null) continue;
			var parsed = Std.parseFloat(value);
			if(!Math.isNaN(parsed)) return parsed;
		}
		return fallback;
	}

	static function xmlHasAny(xml:Xml, names:Array<String>):Bool
	{
		if(xml == null) return false;
		for (name in names)
			if(xml.exists(name)) return true;
		return false;
	}

	static function xmlPair(xml:Xml, xNames:Array<String>, yNames:Array<String>, packedNames:Array<String>, fallback:Array<Float>):Array<Float>
	{
		var packed = parsePackedPoint(xmlStringAny(xml, packedNames, ''), fallback);
		if(packed == null) packed = fallback.copy();
		return [
			xmlFloatAny(xml, xNames, packed[0]),
			xmlFloatAny(xml, yNames, packed[1])
		];
	}

	static function xmlPrefixedString(xml:Xml, prefixes:Array<String>, suffixes:Array<String>, fallback:String):String
	{
		if(xml == null) return fallback;
		for (prefix in prefixes)
		{
			for (suffix in suffixes)
			{
				for (name in prefixedNames(prefix, suffix))
				{
					var value = xml.get(name);
					if(value != null && value.trim().length > 0) return value;
				}
			}
		}
		return fallback;
	}

	static function xmlPrefixedFloat(xml:Xml, prefixes:Array<String>, suffixes:Array<String>, fallback:Float):Float
	{
		if(xml == null) return fallback;
		for (prefix in prefixes)
		{
			for (suffix in suffixes)
			{
				for (name in prefixedNames(prefix, suffix))
				{
					var value = xml.get(name);
					if(value == null) continue;
					var parsed = Std.parseFloat(value);
					if(!Math.isNaN(parsed)) return parsed;
				}
			}
		}
		return fallback;
	}

	static function prefixedNames(prefix:String, suffix:String):Array<String>
	{
		var suffixUpper = suffix.charAt(0).toUpperCase() + suffix.substr(1);
		var suffixLower = suffix.charAt(0).toLowerCase() + suffix.substr(1);
		return [
			prefix + suffixUpper,
			prefix + '_' + suffixLower,
			prefix + '-' + suffixLower,
			prefix + '.' + suffixLower
		];
	}

	static function parsePackedPoint(value:String, fallback:Array<Float>):Array<Float>
	{
		if(value == null || value.trim().length < 1) return null;
		var clean = value.replace(';', ',').replace('|', ',');
		var parts = clean.contains(',') ? clean.split(',') : clean.split(' ');
		var output:Array<Float> = [];
		for (part in parts)
		{
			var trimmed = part.trim();
			if(trimmed.length < 1) continue;
			var parsed = Std.parseFloat(trimmed);
			output.push(Math.isNaN(parsed) ? (output.length < fallback.length ? fallback[output.length] : 0) : parsed);
			if(output.length >= fallback.length) break;
		}
		if(output.length < 1) return null;
		// Single scalar (e.g. scale="1.5") applies to BOTH axes
		if(output.length == 1 && fallback.length >= 2)
			output.push(output[0]);
		while(output.length < fallback.length) output.push(fallback[output.length]);
		return output;
	}

	static function xmlIntList(value:String):Array<Int>
	{
		var output:Array<Int> = [];
		if(value == null || value.trim().length < 1) return output;
		for (part in value.split(','))
		{
			var parsed = Std.parseFloat(part.trim());
			if(!Math.isNaN(parsed)) output.push(Std.int(parsed));
		}
		return output;
	}

	static function fallbackFloatAt(values:Array<Dynamic>, index:Int):Float
	{
		if(values == null || values.length <= index) return 0;
		var parsed = Std.parseFloat(Std.string(values[index]));
		return Math.isNaN(parsed) ? 0 : parsed;
	}

	static function xmlStageFilters(xml:Xml):Int
	{
		var hasLow = xmlHasAny(xml, ['lowQuality', 'low', 'showLowQuality']);
		var hasHigh = xmlHasAny(xml, ['highQuality', 'high', 'showHighQuality']);
		if(!hasLow && !hasHigh) return STAGE_FILTER_ALL;

		var filters = 0;
		if(xmlBoolAny(xml, ['lowQuality', 'low', 'showLowQuality'], false)) filters |= 1;
		if(xmlBoolAny(xml, ['highQuality', 'high', 'showHighQuality'], false)) filters |= 2;
		return filters == 0 ? STAGE_FILTER_ALL : filters;
	}

	static function normalizeStageImagePath(path:String):String
	{
		var clean = path == null || path.trim().length < 1 ? 'unknown' : path.trim();
		clean = clean.replace('\\', '/');
		if(clean.contains(':')) clean = clean.substr(clean.lastIndexOf(':') + 1);
		if(clean.startsWith('assets/'))
		{
			var imageIndex = clean.indexOf('/images/');
			if(imageIndex > -1) clean = clean.substr(imageIndex + 8);
		}
		if(clean.startsWith('images/')) clean = clean.substr(7);
		if(clean.endsWith('.png') || clean.endsWith('.xml') || clean.endsWith('.json') || clean.endsWith('.txt'))
			clean = clean.substr(0, clean.lastIndexOf('.'));
		return clean;
	}

	static function normalizeStageColor(value:String):String
	{
		if(value == null || value.trim().length < 1) return 'FFFFFF';
		var clean = value.trim();
		if(clean.startsWith('#')) clean = clean.substr(1);
		if(clean.startsWith('0x')) clean = clean.substr(2);
		if(clean.length == 8 && clean.startsWith('FF')) clean = clean.substr(2);
		return clean.length >= 6 ? clean.substr(0, 6).toUpperCase() : 'FFFFFF';
	}

	static function uniqueStageObjectName(name:String, objects:Array<Dynamic>):String
	{
		var base = Paths.formatToSongPath(name);
		if(base.length < 1) base = 'sprite';
		var candidate = base;
		var suffix = 1;
		while(stageObjectNameExists(candidate, objects))
		{
			candidate = base + suffix;
			suffix++;
		}
		return candidate;
	}

	static function stageObjectNameExists(name:String, objects:Array<Dynamic>):Bool
	{
		for (object in objects)
			if(Reflect.field(object, 'name') == name) return true;
		return false;
	}

	static function appendStageCharacterObjects(objects:Array<Dynamic>)
	{
		appendStageCharacterObject(objects, 'gf');
		appendStageCharacterObject(objects, 'dad');
		appendStageCharacterObject(objects, 'boyfriend');
	}

	static function appendStageCharacterObject(objects:Array<Dynamic>, type:String)
	{
		if(stageObjectTypeExists(type, objects)) return;
		objects.push({type: type});
	}

	static function stageObjectTypeExists(type:String, objects:Array<Dynamic>):Bool
	{
		for (object in objects)
			if(Reflect.field(object, 'type') == type) return true;
		return false;
	}

	static function buildStagePreload(objects:Array<Dynamic>):Dynamic
	{
		var preload:Dynamic = {};
		var found:Bool = false;

		for (object in objects)
		{
			var type = Std.string(Reflect.field(object, 'type'));
			if(type != 'sprite' && type != 'animatedSprite') continue;

			var image:Dynamic = Reflect.field(object, 'image');
			if(image == null) continue;

			var imagePath = Std.string(image);
			if(imagePath.length < 1) continue;

			var key = imagePath.startsWith('images/') ? imagePath : 'images/' + imagePath;
			var filters = stageObjectFilters(object);
			var current:Dynamic = Reflect.field(preload, key);
			if(current != null)
				filters |= Std.int(Std.parseFloat(Std.string(current)));
			Reflect.setField(preload, key, filters);
			found = true;
		}

		return found ? preload : null;
	}

	static function stageObjectFilters(object:Dynamic):Int
	{
		var raw:Dynamic = Reflect.field(object, 'filters');
		if(raw == null) return STAGE_FILTER_ALL;

		var parsed = Std.parseFloat(Std.string(raw));
		return Math.isNaN(parsed) ? STAGE_FILTER_ALL : Std.int(parsed);
	}

	static function optionalField(data:Dynamic, names:Array<String>):Dynamic
	{
		if(data == null) return null;
		for (name in names)
		{
			var value:Dynamic = Reflect.field(data, name);
			if(value != null) return value;
		}
		return null;
	}

	static function dynamicArray(value:Dynamic):Array<Dynamic>
	{
		if(value == null) return null;
		if(Std.isOfType(value, Array)) return cast value;

		var fields = Reflect.fields(value);
		if(fields.length < 1) return null;

		var output:Array<Dynamic> = [];
		for (field in fields)
			output.push(Reflect.field(value, field));
		return output;
	}

	static function vSliceCharacterData(characters:Dynamic, root:Dynamic, names:Array<String>):Dynamic
	{
		for (name in names)
		{
			var value = optionalField(characters, [name]);
			if(value != null) return value;
		}

		for (name in names)
		{
			var value = optionalField(root, [name]);
			if(value != null) return value;
		}
		return null;
	}

	static function vSliceCharacterName(data:Dynamic, fallback:String):String
	{
		if(data == null) return fallback;
		if(Std.isOfType(data, String)) return normalizeGodotChartCharacter(Std.string(data), fallback);
		return normalizeGodotChartCharacter(vSliceString(data, ['character', 'char', 'asset', 'assetPath', 'id', 'name'], fallback), fallback);
	}

	static function vSliceString(data:Dynamic, names:Array<String>, fallback:String):String
	{
		if(data == null) return fallback;
		if(Std.isOfType(data, String)) return Std.string(data);

		for (name in names)
		{
			var value:Dynamic = Reflect.field(data, name);
			if(value == null) continue;
			var text = Std.string(value);
			if(text.trim().length > 0) return text;
		}
		return fallback;
	}

	static function vSliceBool(data:Dynamic, names:Array<String>, fallback:Bool):Bool
	{
		if(data == null) return fallback;
		for (name in names)
		{
			var value:Dynamic = Reflect.field(data, name);
			if(value == null) continue;
			if(Std.isOfType(value, Bool)) return cast value;
			var clean = Std.string(value).toLowerCase().trim();
			if(clean == 'true' || clean == '1' || clean == 'yes') return true;
			if(clean == 'false' || clean == '0' || clean == 'no') return false;
		}
		return fallback;
	}

	static function vSliceFloat(data:Dynamic, names:Array<String>, fallback:Float):Float
	{
		if(data == null) return fallback;
		for (name in names)
		{
			var value:Dynamic = Reflect.field(data, name);
			if(value == null) continue;
			var parsed = Std.parseFloat(Std.string(value));
			if(!Math.isNaN(parsed)) return parsed;
		}
		return fallback;
	}

	static function vSlicePoint(data:Dynamic, names:Array<String>, fallback:Array<Float>):Array<Float>
	{
		if(data == null) return fallback.copy();

		var direct = parsePoint(data, fallback);
		if(direct != null) return direct;

		for (name in names)
		{
			var parsed = parsePoint(Reflect.field(data, name), fallback);
			if(parsed != null) return parsed;
		}

		return [
			vSliceFloat(data, ['x', 'posX', 'positionX'], fallback[0]),
			vSliceFloat(data, ['y', 'posY', 'positionY'], fallback[1])
		];
	}

	static function vSlicePair(data:Dynamic, packedNames:Array<String>, xNames:Array<String>, yNames:Array<String>, fallback:Array<Float>):Array<Float>
	{
		var packed = fallback.copy();
		var value = optionalField(data, packedNames);
		if(value != null)
		{
			var parsed = parsePoint(value, fallback);
			if(parsed != null)
				packed = parsed;
			else
			{
				var scalar = Std.parseFloat(Std.string(value));
				if(!Math.isNaN(scalar)) packed = [scalar, scalar];
			}
		}

		return [
			vSliceFloat(data, xNames, packed[0]),
			vSliceFloat(data, yNames, packed[1])
		];
	}

	static function vSliceHasAny(data:Dynamic, names:Array<String>):Bool
	{
		return optionalField(data, names) != null;
	}

	static function vSliceStageFilters(data:Dynamic):Int
	{
		var hasLow = vSliceHasAny(data, ['lowQuality', 'low', 'showLowQuality']);
		var hasHigh = vSliceHasAny(data, ['highQuality', 'high', 'showHighQuality']);
		if(!hasLow && !hasHigh) return STAGE_FILTER_ALL;

		var filters = 0;
		if(vSliceBool(data, ['lowQuality', 'low', 'showLowQuality'], false)) filters |= 1;
		if(vSliceBool(data, ['highQuality', 'high', 'showHighQuality'], false)) filters |= 2;
		return filters == 0 ? STAGE_FILTER_ALL : filters;
	}

	static function sourceLabel(source:String):String
	{
		return switch(source)
		{
			case SOURCE_PSYCH: 'Psych Engine';
			case SOURCE_GODOT: 'Godot';
			case SOURCE_CODENAME: 'Codename Engine';
			case SOURCE_NIGHTMAREVISION: 'NightmareVision';
			case SOURCE_VSLICE: 'V-Slice';
			case SOURCE_FOREVER: 'Forever Engine';
			default: 'Unknown';
		}
	}

	static function characterFilter(source:String):Array<FileFilter>
	{
		if(source == SOURCE_CODENAME) return [new FileFilter('Character XML/JSON', 'xml;json')];
		return [new FileFilter('Character JSON', 'json')];
	}

	static function stageFilter(source:String):Array<FileFilter>
	{
		if(source == SOURCE_VSLICE || source == SOURCE_NIGHTMAREVISION)
			return [new FileFilter('Stage JSON', 'json')];
		return [new FileFilter('Stage XML', 'xml')];
	}

	static function isCharacterFileForSource(file:String, source:String):Bool
	{
		if(source == SOURCE_CODENAME) return file.endsWith('.xml') || file.endsWith('.json');
		return file.endsWith('.json');
	}

	static function cleanFolderPath(path:String):String
	{
		var clean = path.replace('\\', '/');
		if(clean.endsWith('/')) clean = clean.substr(0, clean.length - 1);
		return clean;
	}

	static function getFileBase(path:String):String
	{
		var name = path.replace('\\', '/');
		if(name.contains('/')) name = name.substr(name.lastIndexOf('/') + 1);
		var lower = name.toLowerCase();
		if(lower.endsWith('.json') || lower.endsWith('.xml')) name = name.substr(0, name.lastIndexOf('.'));
		return name;
	}

	function setStatus(text:String, error:Bool = false)
	{
		statusText.color = error ? FlxColor.RED : FlxColor.YELLOW;
		statusText.text = text;
	}

	function onCancel()
	{
		setStatus('File selecting was canceled.');
	}

	function onError()
	{
		setStatus('File dialog failed.', true);
	}

	function back()
	{
		if(page == PAGE_MAIN)
			MusicBeatState.switchState(new funkin.states.editors.EditorsMenus());
		else
			setPage(PAGE_MAIN);
	}
}