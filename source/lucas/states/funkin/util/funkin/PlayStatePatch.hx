package lucas.states.funkin.util.funkin;

// ════════════════════════════════════════════════════════
//  PATCH 2 — PlayState.hx
//  Carregar metadata automaticamente ao iniciar a gameplay
//  Localização: source/states/PlayState.hx
// ════════════════════════════════════════════════════════
//
//  NÃO substitua o PlayState.hx inteiro!
//  Adicione/modifique apenas os trechos indicados abaixo.
//
// ────────────────────────────────────────────────────────

// ── PASSO 1: imports no topo do PlayState.hx ─────────────
// Adicione junto aos outros imports:
/*
    import backend.SongMetadata;
    import backend.SongMetadataBridge;
*/

// ── PASSO 2: variável de instância na classe PlayState ────
// Adicione junto às outras variáveis públicas/estáticas:
/*
    // Metadata V-Slice da música atual (pode ser null se não existir)
    public static var currentSongMeta:SongMetadataStruct = null;
*/

// ── PASSO 3: dentro de create(), logo após Song.loadFromJson ─
// Encontre a linha parecida com:
//   SONG = Song.loadFromJson(songDiff, songName);
// e DEPOIS dela adicione:
/*
    // ── Pico Engine: carrega metadata V-Slice ──
    currentSongMeta = SongMetadata.loadFromPath(SONG.song.toLowerCase().replace(' ', '-'));
    if (currentSongMeta != null)
        SongMetadataBridge.enrich(SONG, SONG.song.toLowerCase().replace(' ', '-'));
*/

// ── PASSO 4: acesso ao artist na HUD (opcional) ───────────
// Onde você exibir o nome do artista (ex: numa UI customizada):
/*
    var artistName:String = '';
    if (PlayState.currentSongMeta != null)
        artistName = PlayState.currentSongMeta.artist;
    else
        artistName = Reflect.field(SONG, 'artist') ?? 'Unknown';
*/

// ════════════════════════════════════════════════════════
//  CLASSE AUXILIAR — PlayStateMetaHelper
//  Cole no final do PlayState.hx ou em arquivo separado
// ════════════════════════════════════════════════════════

class PlayStateMetaHelper
{
    /**
     * Retorna o nome do artista da música atual.
     * Prioridade: metadata V-Slice → campo Reflect no SwagSong → "Unknown"
     */
    public static function getCurrentArtist():String
    {
        // 1. Tenta pelo metadata V-Slice
        if (PlayState.currentSongMeta != null && PlayState.currentSongMeta.artist != null)
            return PlayState.currentSongMeta.artist;

        // 2. Tenta pelo SwagSong via Reflect (campo adicionado via FreeplayMeta)
        if (PlayState.SONG != null) {
            var r:Dynamic = Reflect.field(PlayState.SONG, 'artist');
            if (r != null && Std.string(r) != '') return Std.string(r);
        }

        return 'Unknown';
    }

    /**
     * Retorna o BPM de início da música atual, priorizando o metadata.
     */
    public static function getStartBPM():Float
    {
        if (PlayState.currentSongMeta != null)
            return SongMetadata.getStartBPM(PlayState.currentSongMeta);
        return (PlayState.SONG != null) ? PlayState.SONG.bpm : 120.0;
    }

    /**
     * Retorna o rating (estrelas) da dificuldade atual.
     * Útil para exibir na tela de resultados ou no Freeplay.
     */
    public static function getCurrentDiffRating():Int
    {
        if (PlayState.currentSongMeta == null) return 0;
        var diff = CoolUtil.difficulties[PlayState.storyDifficulty].toLowerCase();
        return SongMetadata.getDifficultyRating(PlayState.currentSongMeta, diff);
    }

    /**
     * Valida se o metadata da música atual está íntegro.
     * Útil no ChartingState para dar feedback ao modder.
     */
    public static function validateCurrentMeta():Array<String>
    {
        return SongMetadata.validate(PlayState.currentSongMeta);
    }
}
