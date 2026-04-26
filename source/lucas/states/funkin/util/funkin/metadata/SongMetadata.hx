package lucas.states.funkin.util.funkin.metadata;

typedef SongTimeChange = {
	var t:Float;
	@:optional var b:Float;
	var bpm:Float;
	@:optional var n:Int;
	@:optional var d:Int;
	@:optional var bt:Array<Int>;
}

/**
 * Offsets de áudio para sincronização fina.
 * Valores positivos = atrasar o áudio (em ms).
 */
typedef SongOffsets = {
	@:optional var instrumental:Float;
	@:optional var altInstrumentals:Dynamic; // Map de variação → offset
	@:optional var vocals:Dynamic;           // Map de personagem → offset
	@:optional var altVocals:Dynamic;
}

/**
 * Personagens da música para cada slot.
 */
typedef SongCharacters = {
	var player:String;
	var girlfriend:String;
	var opponent:String;
	@:optional var instrumental:String;
	@:optional var altInstrumentals:Array<String>;
	@:optional var opponentVocals:Array<String>;
	@:optional var playerVocals:Array<String>;
}

/**
 * Ratings de dificuldade (estrelas de 0–10).
 * Chave = nome da dificuldade (ex: "easy", "normal", "hard").
 */
typedef SongRatings = Dynamic; // ex: { "easy": 2, "normal": 5, "hard": 8 }

/**
 * Dados de gameplay: dificuldades, personagens, stage, etc.
 */
typedef SongPlayData = {
	@:optional var songVariations:Array<String>;
	var difficulties:Array<String>;
	var characters:SongCharacters;
	var stage:String;
	@:optional var noteStyle:String;
	@:optional var ratings:SongRatings;
	@:optional var album:String;
	@:optional var previewStart:Float; // ms onde começa o preview no Freeplay
	@:optional var previewEnd:Float;   // ms onde termina o preview no Freeplay
}

/**
 * Struct principal do metadata de uma música.
 * Equivale ao arquivo `SONGID-metadata.json` do V-Slice.
 */
typedef SongMetadataStruct = {
	// ── Identificação ──
	var version:String;       // ex: "2.2.4"
	var songName:String;      // Nome de exibição
	var artist:String;        // Artista/compositor
	@:optional var charter:String; // Quem fez o chart
	var timeFormat:String;    // "ms" ou "ticks"
	@:optional var divisions:Int; // Divisões por beat (padrão: 96), usado com "ticks"
	var timeChanges:Array<SongTimeChange>;
	@:optional var looped:Bool;
	@:optional var offsets:SongOffsets;
	var playData:SongPlayData;
	@:optional var generatedBy:String; // ex: "Pico Engine v1.0"
}

class SongMetadata
{
	// Versão atual do schema usado pelo Pico Engine
	public static final SCHEMA_VERSION:String = "2.2.4";
	public static final GENERATED_BY:String   = "Pico Engine v${MainMenuState.PicoVersion}";

	// ── Parsing ─────────────────────────────

	/**
	 * Carrega e parseia o metadata de uma música a partir de um JSON string.
	 * Retorna null se o JSON for inválido.
	 */
	public static function fromJson(jsonStr:String):SongMetadataStruct
	{
		var data:SongMetadataStruct = null;
		try {
			data = cast haxe.Json.parse(jsonStr);
		} catch (e:Dynamic) {
			#if debug
			trace('[SongMetadata] Erro ao parsear metadata JSON: $e');
			#end
			return null;
		}
		return data;
	}

	/**
	 * Carrega o metadata direto de um arquivo via Paths.
	 * Caminho esperado: data/songs/SONGID/SONGID-metadata.json
	 */
	public static function loadFromPath(songId:String, ?modFolder:String):SongMetadataStruct
	{
		var path:String = Paths.json('songs/$songId/$songId-metadata', modFolder);
		if (!openfl.Assets.exists(path)) {
			#if debug
			trace('[SongMetadata] Arquivo não encontrado: $path');
			#end
			return null;
		}
		var content:String = openfl.Assets.getText(path);
		return fromJson(content);
	}

	// ── Getters utilitários ──────────────────

	/**
	 * Retorna o BPM inicial da música (primeiro timeChange).
	 */
	public static function getStartBPM(meta:SongMetadataStruct):Float
	{
		if (meta == null || meta.timeChanges == null || meta.timeChanges.length == 0)
			return 100.0;
		return meta.timeChanges[0].bpm;
	}

	/**
	 * Retorna o compasso do primeiro timeChange no formato "N/D" (ex: "4/4").
	 */
	public static function getTimeSig(meta:SongMetadataStruct):String
	{
		if (meta == null || meta.timeChanges == null || meta.timeChanges.length == 0)
			return "4/4";
		var tc = meta.timeChanges[0];
		var n:Int = (tc.n != null) ? tc.n : 4;
		var d:Int = (tc.d != null) ? tc.d : 4;
		return '$n/$d';
	}

	/**
	 * Retorna o offset do instrumental (em ms). Padrão: 0.
	 */
	public static function getInstrumentalOffset(meta:SongMetadataStruct):Float
	{
		if (meta == null || meta.offsets == null) return 0.0;
		var off:Float = meta.offsets.instrumental;
		return (off != null) ? off : 0.0;
	}

	/**
	 * Retorna a lista de dificuldades disponíveis.
	 */
	public static function getDifficulties(meta:SongMetadataStruct):Array<String>
	{
		if (meta == null || meta.playData == null) return ["normal"];
		return meta.playData.difficulties ?? ["normal"];
	}

	/**
	 * Verifica se uma dificuldade específica existe no metadata.
	 */
	public static function hasDifficulty(meta:SongMetadataStruct, diff:String):Bool
	{
		return getDifficulties(meta).indexOf(diff.toLowerCase()) >= 0;
	}

	/**
	 * Retorna o rating (estrelas) de uma dificuldade. Padrão: 0.
	 */
	public static function getDifficultyRating(meta:SongMetadataStruct, diff:String):Int
	{
		if (meta == null || meta.playData == null || meta.playData.ratings == null)
			return 0;
		var r:Dynamic = Reflect.field(meta.playData.ratings, diff.toLowerCase());
		return (r != null) ? Std.int(r) : 0;
	}

	/**
	 * Retorna o ID do stage da música.
	 */
	public static function getStage(meta:SongMetadataStruct):String
	{
		if (meta == null || meta.playData == null) return "stage";
		return meta.playData.stage ?? "stage";
	}

	/**
	 * Retorna o ID do personagem player (bf por padrão).
	 */
	public static function getPlayer(meta:SongMetadataStruct):String
	{
		if (meta == null || meta.playData == null) return "bf";
		return meta.playData.characters?.player ?? "bf";
	}

	/**
	 * Retorna o ID do personagem opponent (dad por padrão).
	 */
	public static function getOpponent(meta:SongMetadataStruct):String
	{
		if (meta == null || meta.playData == null) return "dad";
		return meta.playData.characters?.opponent ?? "dad";
	}

	/**
	 * Retorna o ID do personagem girlfriend (gf por padrão).
	 */
	public static function getGirlfriend(meta:SongMetadataStruct):String
	{
		if (meta == null || meta.playData == null) return "gf";
		return meta.playData.characters?.girlfriend ?? "gf";
	}

	/**
	 * Retorna o previewStart em ms para o Freeplay. Padrão: 0.
	 */
	public static function getPreviewStart(meta:SongMetadataStruct):Float
	{
		if (meta == null || meta.playData == null) return 0.0;
		return meta.playData.previewStart ?? 0.0;
	}

	/**
	 * Retorna o previewEnd em ms para o Freeplay. Padrão: 0.
	 */
	public static function getPreviewEnd(meta:SongMetadataStruct):Float
	{
		if (meta == null || meta.playData == null) return 0.0;
		return meta.playData.previewEnd ?? 0.0;
	}

	/**
	 * Retorna o nome do álbum (para ícone no Freeplay). Padrão: "".
	 */
	public static function getAlbum(meta:SongMetadataStruct):String
	{
		if (meta == null || meta.playData == null) return "";
		return meta.playData.album ?? "";
	}

	// ── Criação / Serialização ───────────────

	/**
	 * Cria um metadata padrão com os valores mínimos necessários.
	 * Útil para gerar templates via ChartingState ou ExtraSongsState.
	 */
	public static function createDefault(
		songId:String,
		songName:String,
		artist:String,
		bpm:Float = 120.0,
		stage:String = "stage",
		player:String = "bf",
		opponent:String = "dad",
		girlfriend:String = "gf"
	):SongMetadataStruct
	{
		return {
			version:     SCHEMA_VERSION,
			songName:    songName,
			artist:      artist,
			charter:     "",
			timeFormat:  "ms",
			divisions:   96,
			looped:      false,
			offsets: {
				instrumental:    0.0,
				altInstrumentals: {},
				vocals:          {},
				altVocals:       {}
			},
			timeChanges: [
				{
					t:   0.0,
					b:   0.0,
					bpm: bpm,
					n:   4,
					d:   4,
					bt:  [4, 4, 4, 4]
				}
			],
			playData: {
				songVariations: [],
				difficulties:   ["easy", "normal", "hard"],
				characters: {
					player:          player,
					girlfriend:      girlfriend,
					opponent:        opponent,
					instrumental:    "",
					altInstrumentals: [],
					opponentVocals:  [opponent],
					playerVocals:    [player]
				},
				stage:        stage,
				noteStyle:    "funkin",
				ratings:      { easy: 2, normal: 4, hard: 6 },
				album:        "",
				previewStart: 0.0,
				previewEnd:   0.0
			},
			generatedBy: GENERATED_BY
		};
	}

	/**
	 * Serializa um SongMetadataStruct para uma string JSON formatada.
	 * Útil para salvar arquivos via ChartingState.
	 */
	public static function toJson(meta:SongMetadataStruct):String
	{
		return haxe.Json.stringify(meta, null, "\t");
	}

	// ── Validação ────────────────────────────

	/**
	 * Verifica se um metadata possui todos os campos obrigatórios.
	 * Retorna uma lista de campos ausentes (lista vazia = tudo OK).
	 */
	public static function validate(meta:SongMetadataStruct):Array<String>
	{
		var missing:Array<String> = [];

		if (meta == null)                                return ["(inteiro)"];
		if (meta.version == null || meta.version == "") missing.push("version");
		if (meta.songName == null || meta.songName == "") missing.push("songName");
		if (meta.artist == null || meta.artist == "")  missing.push("artist");
		if (meta.timeFormat == null)                   missing.push("timeFormat");
		if (meta.timeChanges == null || meta.timeChanges.length == 0)
			missing.push("timeChanges");
		if (meta.playData == null)
			missing.push("playData");
		else {
			if (meta.playData.difficulties == null || meta.playData.difficulties.length == 0)
				missing.push("playData.difficulties");
			if (meta.playData.stage == null || meta.playData.stage == "")
				missing.push("playData.stage");
			if (meta.playData.characters == null)
				missing.push("playData.characters");
		}

		return missing;
	}

	/**
	 * Atalho: retorna true se o metadata for válido.
	 */
	public static function isValid(meta:SongMetadataStruct):Bool
	{
		return validate(meta).length == 0;
	}

	// ── Integração com SwagSong (Psych) ──────

	/**
	 * Preenche campos de um SwagSong existente a partir do SongMetadata.
	 * Usa Reflect para compatibilidade com campos opcionais adicionados
	 * ao SwagSong no Pico Engine (ex: "artist").
	 */
	public static function applyToSwagSong(meta:SongMetadataStruct, song:Dynamic):Void
	{
		if (meta == null || song == null) return;

		// Campo artist (adicionado via Reflect no SwagSong do Pico Engine)
		Reflect.setField(song, "artist", meta.artist ?? "");

		// BPM inicial
		if (meta.timeChanges != null && meta.timeChanges.length > 0)
			song.bpm = meta.timeChanges[0].bpm;

		// Personagens
		if (meta.playData != null && meta.playData.characters != null) {
			song.player1  = meta.playData.characters.player ?? "bf";
			song.player2  = meta.playData.characters.opponent ?? "dad";
			song.gfVersion = meta.playData.characters.girlfriend ?? "gf";
		}

		// Stage
		if (meta.playData != null && meta.playData.stage != null)
			song.stage = meta.playData.stage;
	}
}
