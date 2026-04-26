package lucas.states.funkin.util.funkin;

import lucas.states.funkin.util.funkin.metadata.SongMetadata;
import lucas.states.funkin.util.funkin.metadata.SongMetadata.SongMetadataStruct;

class FreeplayMetaHelper
{
    /**
     * Pré-carrega os metadatas de todas as músicas do Freeplay em cache.
     * Chame isso no create() do FreeplayState, após montar a lista de songs.
     *
     * Parâmetro songIds: lista dos IDs das músicas (nome da pasta, lowercase-hyphenated)
     * Retorna o Map preenchido.
     *
     * Exemplo de uso no FreeplayState.create():
     *   metaCache = FreeplayMetaHelper.preloadAll(songIdList);
     */
    public static function preloadAll(songIds:Array<String>, ?modFolder:String):Map<String, SongMetadataStruct>
    {
        var cache:Map<String, SongMetadataStruct> = [];
        for (id in songIds) {
            var meta = SongMetadata.loadFromPath(id, modFolder);
            if (meta != null)
                cache.set(id, meta);
            #if debug
            else
                trace('[FreeplayMetaHelper] Sem metadata para: $id');
            #end
        }
        return cache;
    }

    /**
     * Retorna o tempo (ms) em que o preview da música deve começar.
     * Fallback: 0 ms (começa do início).
     */
    public static function getPreviewStart(cache:Map<String, SongMetadataStruct>, songId:String):Float
    {
        var meta = cache.get(songId);
        return (meta != null) ? SongMetadata.getPreviewStart(meta) : 0.0;
    }

    /**
     * Retorna o tempo (ms) em que o preview da música deve terminar.
     * Fallback: 0 (sem limite, toca até o fim).
     */
    public static function getPreviewEnd(cache:Map<String, SongMetadataStruct>, songId:String):Float
    {
        var meta = cache.get(songId);
        return (meta != null) ? SongMetadata.getPreviewEnd(meta) : 0.0;
    }

    /**
     * Retorna o ID do álbum para carregar o ícone de capa no Freeplay.
     * Caminho do ícone esperado: images/freeplay/albums/ALBUMID.png
     * Fallback: "" (sem ícone de álbum).
     */
    public static function getAlbum(cache:Map<String, SongMetadataStruct>, songId:String):String
    {
        var meta = cache.get(songId);
        return (meta != null) ? SongMetadata.getAlbum(meta) : '';
    }

    /**
     * Retorna o rating (estrelas 0–10) de uma dificuldade específica.
     * Útil para exibir ícones de dificuldade no Freeplay.
     */
    public static function getRating(cache:Map<String, SongMetadataStruct>, songId:String, diff:String):Int
    {
        var meta = cache.get(songId);
        return (meta != null) ? SongMetadata.getDifficultyRating(meta, diff) : 0;
    }

    public static function getArtist(cache:Map<String, SongMetadataStruct>, songId:String, ?freeplayMeta:Dynamic):String
    {
        var meta = cache.get(songId);
        if (meta != null && meta.artist != null && meta.artist != '')
            return meta.artist;

        if (freeplayMeta != null) {
            var r:Dynamic = Reflect.field(freeplayMeta, 'artist');
            if (r != null && Std.string(r) != '') return Std.string(r);
        }
        return 'Unknown Artist';
    }

    /**
     * Aplica o preview de uma música ao FlxSound do Freeplay.
     * Chame dentro do updateMusicPlayer() ou equivalente no FreeplayState.
     *
     * Parâmetros:
     *   sound     → o FlxSound tocando o Inst da música
     *   cache     → o Map de metadatas já carregado
     *   songId    → ID da música selecionada
     *
     * Exemplo:
     *   FreeplayMetaHelper.applyPreview(FlxG.sound.music, metaCache, curSongId);
     */
    public static function applyPreview(
        sound:flixel.sound.FlxSound,
        cache:Map<String, SongMetadataStruct>,
        songId:String
    ):Void
    {
        if (sound == null) return;

        var startMs = getPreviewStart(cache, songId);
        var endMs   = getPreviewEnd(cache, songId);

        // Pula para o ponto de início do preview
        if (startMs > 0 && sound.time < startMs)
            sound.time = startMs;

        // Se passou do fim do preview, volta ao início
        if (endMs > 0 && sound.time >= endMs)
            sound.time = startMs;
    }
}