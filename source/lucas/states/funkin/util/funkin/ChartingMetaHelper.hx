package lucas.states.funkin.util.funkin;

import backend.Song.SwagSong;
import lucas.states.funkin.util.funkin.metadata.SongMetadata;
import lucas.states.funkin.util.funkin.metadata.SongMetadataBridge;
import lucas.states.funkin.util.funkin.metadata.SongMetadata.SongMetadataStruct;

class ChartingMetaHelper
{
    public static function loadOrCreate(song:SwagSong, songId:String, ?modFolder:String):SongMetadataStruct
    {
        // Tenta carregar o metadata existente
        var meta = SongMetadata.loadFromPath(songId, modFolder);

        if (meta != null) {
            #if debug
            trace('[ChartingMeta] Metadata carregado: $songId');
            #end
            return meta;
        }

        // Não existe: gera um novo a partir dos dados do SwagSong
        var artist:String = Reflect.field(song, 'artist') ?? 'Unknown Artist';
        var charter:String = Reflect.field(song, 'charter') ?? '';

        var newMeta = SongMetadata.createDefault(
            songId,
            song.song,
            artist,
            song.bpm,
            song.stage   ?? 'stage',
            song.player1 ?? 'bf',
            song.player2 ?? 'dad',
            song.gfVersion ?? 'gf'
        );

        // Aplica charter se existir
        if (charter != '') newMeta.charter = charter;

        #if debug
        trace('[ChartingMeta] Metadata criado do zero para: $songId');
        #end

        return newMeta;
    }

    /**
     * Sincroniza os dados do SwagSong → metadata antes de salvar.
     * Garante que BPM, personagens e stage estejam atualizados.
     *
     * Chame ANTES de saveMetadata(), ao clicar em "Save Chart".
     */
    public static function syncFromSong(meta:SongMetadataStruct, song:SwagSong):Void
    {
        if (meta == null || song == null) return;

        // Sync BPM (primeiro timeChange)
        if (meta.timeChanges != null && meta.timeChanges.length > 0)
            meta.timeChanges[0].bpm = song.bpm;

        // Sync personagens
        if (meta.playData != null && meta.playData.characters != null) {
            meta.playData.characters.player      = song.player1   ?? 'bf';
            meta.playData.characters.opponent    = song.player2   ?? 'dad';
            meta.playData.characters.girlfriend  = song.gfVersion ?? 'gf';
        }

        // Sync stage
        if (meta.playData != null && song.stage != null)
            meta.playData.stage = song.stage;

        // Sync artist via Reflect
        var artist:String = Reflect.field(song, 'artist') ?? '';
        if (artist != '') meta.artist = artist;

        // Sync generatedBy
        meta.generatedBy = SongMetadata.GENERATED_BY;
    }

    /**
     * Salva o metadata no disco ao clicar em "Save Chart" no ChartingState.
     * Sincroniza automaticamente antes de salvar.
     *
     * Retorna true se salvo com sucesso.
     *
     * Uso no ChartingState, dentro do save callback:
     *   var ok = ChartingMetaHelper.save(currentMeta, SONG, songId, modFolder);
     *   if (!ok) openSubState(new Prompt('Erro ao salvar metadata!'));
     */
    public static function save(
        meta:SongMetadataStruct,
        song:SwagSong,
        songId:String,
        ?modFolder:String
    ):Bool
    {
        if (meta == null) {
            // Cria do zero se não tiver
            meta = loadOrCreate(song, songId, modFolder);
        }

        syncFromSong(meta, song);

        var errors = SongMetadata.validate(meta);
        if (errors.length > 0) {
            #if debug
            trace('[ChartingMeta] Metadata inválido, campos faltando: ' + errors.join(', '));
            #end
            return false;
        }

        return SongMetadataBridge.saveMetadata(meta, songId, modFolder);
    }

    /**
     * Atualiza as dificuldades no metadata com base na lista atual do ChartingState.
     * Chame sempre que o modder adicionar/remover uma dificuldade.
     *
     * Parâmetro diffs: ex. ["easy", "normal", "hard", "erect"]
     */
    public static function updateDifficulties(meta:SongMetadataStruct, diffs:Array<String>):Void
    {
        if (meta == null || meta.playData == null) return;
        meta.playData.difficulties = diffs.map(d -> d.toLowerCase());
    }

    /**
     * Define o rating de uma dificuldade no metadata.
     *
     * Parâmetro stars: 0–10
     */
    public static function setRating(meta:SongMetadataStruct, diff:String, stars:Int):Void
    {
        if (meta == null || meta.playData == null) return;
        if (meta.playData.ratings == null) meta.playData.ratings = {};
        Reflect.setField(meta.playData.ratings, diff.toLowerCase(), Std.int(Math.max(0, Math.min(10, stars))));
    }

    /**
     * Define o intervalo de preview para o Freeplay.
     *
     * Parâmetros em milissegundos.
     */
    public static function setPreview(meta:SongMetadataStruct, startMs:Float, endMs:Float):Void
    {
        if (meta == null || meta.playData == null) return;
        meta.playData.previewStart = startMs;
        meta.playData.previewEnd   = endMs;
    }
}
