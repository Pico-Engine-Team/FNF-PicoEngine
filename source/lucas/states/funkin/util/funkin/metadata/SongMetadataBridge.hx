package lucas.states.funkin.util.funkin.metadata;

import backend.Song.SwagSong;
import lucas.states.funkin.util.funkin.metadata.SongMetadata.SongMetadataStruct;

class SongMetadataBridge
{
    public static function enrich(song:SwagSong, songId:String, ?modFolder:String):Void
    {
        if (song == null) return;

        var meta = SongMetadata.loadFromPath(songId, modFolder);
        if (meta == null) {
            #if debug
            trace('[SongMetadataBridge] metadata não encontrado para: $songId');
            #end
            return;
        }

        Reflect.setField(song, 'artist',       meta.artist       ?? '');
        Reflect.setField(song, 'charter',      meta.charter      ?? '');
        Reflect.setField(song, 'album',        SongMetadata.getAlbum(meta));
        Reflect.setField(song, 'previewStart', SongMetadata.getPreviewStart(meta));
        Reflect.setField(song, 'previewEnd',   SongMetadata.getPreviewEnd(meta));
        Reflect.setField(song, 'noteStyle',    meta.playData?.noteStyle ?? 'funkin');

        var metaBPM = SongMetadata.getStartBPM(meta);
        if (metaBPM > 0 && song.bpm != metaBPM)
            song.bpm = metaBPM;

        #if debug
        trace('[SongMetadataBridge] enriquecido: ${song.song} | artist=${meta.artist} | bpm=$metaBPM');
        #end
    }

    /**
     * Cria um SwagSong mínimo + metadata ao mesmo tempo, útil no ChartingState
     * ao criar uma música nova do zero.
     */
    public static function createNew(
        songId:String, songName:String, artist:String,
        bpm:Float = 120.0, stage:String = 'stage',
        player:String = 'bf', opponent:String = 'dad', gf:String = 'gf',
        ?modFolder:String):

    {song:SwagSong, meta:SongMetadataStruct}
    {
        var meta = SongMetadata.createDefault(songId, songName, artist, bpm, stage, player, opponent, gf);
    
        var song:SwagSong = {
            song:      songName,
            notes:     [],
            events:    [],
            bpm:       bpm,
            needsVoices: true,
            speed:     1.0,

            player1:   player,
            player2:   opponent,
            gfVersion: gf,
            stage:     stage,
        
            offset:    0,
            format:    "psych_v1"
    };
    Reflect.setField(song, 'artist',  artist);
    Reflect.setField(song, 'charter', '');
    Reflect.setField(song, 'album',   '');
    return { song: song, meta: meta };
}

    public static function saveMetadata(meta:SongMetadataStruct, songId:String, ?modFolder:String):Bool
    {
        #if sys
        var folder:String = (modFolder != null && modFolder != '')
            ? 'mods/$modFolder/data/songs/$songId'
            : 'assets/data/songs/$songId';

        var filePath:String = '$folder/$songId-metadata.json';

        try {
            if (!sys.FileSystem.exists(folder))
                sys.FileSystem.createDirectory(folder);

            sys.io.File.saveContent(filePath, SongMetadata.toJson(meta));
            #if debug
            trace('[SongMetadataBridge] Salvo: $filePath');
            #end
            return true;
        } catch (e:Dynamic) {
            #if debug
            trace('[SongMetadataBridge] Erro ao salvar metadata: $e');
            #end
            return false;
        }
        #else
        trace('[SongMetadataBridge] saveMetadata() requer target sys (desktop).');
        return false;
        #end
    }
}