--[[
  scripts/states/notestyle/funkin.lua   ← path principal

  Scripts de notestyle: movimento, change skin, etc.
  Carregue no PlayState junto com o style ativo:
    local path = -- from Haxe NoteData.noteStyle.getLuaPath()
    new FunkinLuaProgramming(path)

  Callbacks úteis:
    onCreate, onUpdate(elapsed), onBeatHit, onStepHit
    goodNoteHit / opponentNoteHit (se o PlayState repassar)
]]

local waveEnabled = false
local waveAmp = 12
local waveSpeed = 6
local skinChanged = false

function onCreate()
	debugPrint('notestyle.lua loaded: funkin')
	-- waveEnabled = true
end

function onUpdate(elapsed)
	if not waveEnabled then return end
	-- Exemplo: oscilar notas unspawned (requer getPropertyFromGroup)
	local len = getProperty('notes.length')
	if len == nil then return end
	for i = 0, len - 1 do
		local baseX = getPropertyFromGroup('notes', i, 'x')
		local strumTime = getPropertyFromGroup('notes', i, 'strumTime')
		if strumTime ~= nil then
			local offset = math.sin((strumTime * 0.01) + (getSongPosition() * 0.001 * waveSpeed)) * waveAmp
			-- setPropertyFromGroup('notes', i, 'offsetX', offset) -- se a engine expuser offsetX
		end
	end
end

--- Troca o sprite da nota em runtime (sem noteSplash.json)
function changeSkinNote(imagePath)
	if imagePath == nil or imagePath == '' then return end
	-- Aplica em todas as notas já spawnadas
	local len = getProperty('notes.length') or 0
	for i = 0, len - 1 do
		setPropertyFromGroup('notes', i, 'texture', imagePath)
	end
	-- Próximas notas: set default via global se exposto
	setPropertyFromClass('funkin.data.objects.game.notes.config.Note', 'defaultNoteSkin', imagePath)
	skinChanged = true
	debugPrint('changeSkinNote → ' .. imagePath)
end

--- Ativa / desativa movimento onda
function setNoteWave(enabled, amplitude, speed)
	waveEnabled = enabled == true
	if amplitude ~= nil then waveAmp = amplitude end
	if speed ~= nil then waveSpeed = speed end
end

function onBeatHit()
	-- Exemplo: a cada 16 beats troca skin
	-- if curBeat % 16 == 0 then
	--   changeSkinNote('noteSkins/NOTE_assets')
	-- end
end

function goodNoteHit(id, direction, noteType, isSustainNote)
	-- custom por direção se quiser
end