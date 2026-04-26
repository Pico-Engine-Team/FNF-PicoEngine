package lucas.states.funkin.util.funkin;

class ExtraSongsMetaHelper
{
    /**
     * Carrega o metadata de UMA música extra e enriquece um SwagSong.
     *
     * Uso quando o jogador seleciona uma música no menu de extras:
     *   var enriched = ExtraSongsMetaHelper.loadAndEnrich(songId, modFolder);
     *   PlayState.SONG = enriched.song;
     *   PlayState.currentSongMeta = enriched.meta;
     */
    public static function loadAndEnrich(
        songId:String,
        ?modFolder:String
    ):{ song:SwagSong, meta:SongMetadataStruct }
    {
        // Carrega o chart via o sistema existente do ExtraSongsState
        var rawSong = Song.loadFromJson(
            CoolUtil.difficulties[PlayState.storyDifficulty],
            songId
        );

        // Enriquece com o metadata V-Slice
        var meta = SongMetadata.loadFromPath(songId, modFolder);
        if (meta != null)
            SongMetadataBridge.enrich(rawSong, songId, modFolder);

        return { song: rawSong, meta: meta };
    }

    /**
     * Retorna as dificuldades disponíveis para uma música extra,
     * priorizando o metadata V-Slice (mais confiável que o .txt).
     *
     * Fallback: lista padrão do CoolUtil.difficulties do Psych.
     */
    public static function getDifficulties(
        cache:Map<String, SongMetadataStruct>,
        songId:String
    ):Array<String>
    {
        var meta = cache.get(songId);
        if (meta != null)
            return SongMetadata.getDifficulties(meta);

        // Fallback: dificuldades globais do Psych Engine
        return CoolUtil.difficulties.map(d -> d.toLowerCase());
    }

    /**
     * Retorna o nome do artista de uma música extra.
     * Fonte: metadata V-Slice → campo `artist` no .txt → "Unknown".
     */
    public static function getArtist(
        cache:Map<String, SongMetadataStruct>,
        songId:String,
        ?fallbackArtist:String
    ):String
    {
        var meta = cache.get(songId);
        if (meta != null && meta.artist != null && meta.artist != '')
            return meta.artist;
        return fallbackArtist ?? 'Unknown Artist';
    }

    /**
     * Verifica se um songId tem metadata válido no cache.
     * Útil para mostrar um ícone "✓ metadata" no ExtraSongsState.
     */
    public static function hasValidMeta(
        cache:Map<String, SongMetadataStruct>,
        songId:String
    ):Bool
    {
        var meta = cache.get(songId);
        return (meta != null) && SongMetadata.isValid(meta);
    }

    /**
     * Gera e salva um metadata padrão para uma música extra que ainda
     * não tem `-metadata.json`. Útil para migrar músicas antigas.
     *
     * Retorna o metadata criado (ou null em caso de falha).
     */
    public static function generateMissing(
        songId:String,
        ?modFolder:String
    ):SongMetadataStruct
    {
        // Já tem? não faz nada
        if (SongMetadata.loadFromPath(songId, modFolder) != null) {
            #if debug
            trace('[ExtraSongsMeta] $songId já tem metadata, pulando.');
            #end
            return null;
        }

        // Carrega o SwagSong para pegar os dados básicos
        var song:SwagSong = null;
        try {
            song = Song.loadFromJson(CoolUtil.difficulties[1], songId); // "normal"
        } catch (e:Dynamic) {
            #if debug
            trace('[ExtraSongsMeta] Falha ao carregar song para gerar metadata: $e');
            #end
            return null;
        }

        if (song == null) return null;

        var artist:String = Reflect.field(song, 'artist') ?? 'Unknown Artist';
        var meta = SongMetadata.createDefault(
            songId,
            song.song,
            artist,
            song.bpm,
            song.stage   ?? 'stage',
            song.player1 ?? 'bf',
            song.player2 ?? 'dad',
            song.gfVersion ?? 'gf'
        );

        var ok = SongMetadataBridge.saveMetadata(meta, songId, modFolder);
        if (!ok) return null;

        #if debug
        trace('[ExtraSongsMeta] Metadata gerado para: $songId');
        #end

        return meta;
    }

    /**
     * Varre todos os songIds da lista e gera metadata para os que estão faltando.
     * Útil para "migrar" uma mod inteira de uma vez.
     *
     * Retorna quantos metadatas foram criados.
     */
    public static function generateAllMissing(
        songIds:Array<String>,
        ?modFolder:String
    ):Int
    {
        var count = 0;
        for (id in songIds) {
            var created = generateMissing(id, modFolder);
            if (created != null) count++;
        }
        #if debug
        trace('[ExtraSongsMeta] Metadatas gerados: $count / ${songIds.length}');
        #end
        return count;
    }
}
