local extraCharacters = {}

function onCreate()
	addLuaScript('game/extra/extraIcon')
end

function createCharacter(char,json,x,y,isPlayer,addIcon)
	if checkFileExists('data/characters/'..json..'.json') then
		isPlayer = (isPlayer == true)
		table.insert(extraCharacters,char)
		runHaxeCode(
			[[
				var isPlayer = ]]..tostring(isPlayer)..[[;
				var char = getVar("]]..char..[[");
				if(!char){
					char = new Character(]]..x..','..y..',"'..json..[[",isPlayer);
				}
				setVar("]]..char..[[",char);
				if(isPlayer){
					game.insert(game.members.indexOf(game.boyfriendGroup),char);
				}
				else{
					game.insert(game.members.indexOf(game.dadGroup),char);
				}
			]]
		)
		if addIcon then
			callScript('extra_scripts/extraIcon','addExtraIcon',{char..'Icon',getProperty(char..'.healthIcon'),false,isPlayer,true})
		end
	end
end

function removeCharacter(char,removeImageFromMemory)
	local imageFile = runHaxeCode(
		[[
			var char = getVar("]]..char..[[");
			if(char != null){
				var image = char.imageFile;
				char.kill();
				char.destroy();
				return image;
			}
		]]
	)
	if removeImageFromMemory and imageFile ~= nil then
		callScript('scripts/optimization','removeFromMemory',{imageFile})
	end
	for i, chars in pairs(extraCharacters) do
		if char == chars then
			table.remove(extraCharacters,i)
			break
		end
	end
end

function addExtraCharToList(character,tag)
	if checkFileExists('characters/'..character..'.json') then
		if tag == nil then
			tag = character
		end
		runHaxeCode(
			[[
				var char = getVar("]]..tag..[[");
				if(!char){
					var newChar = new Character(charArray.x,charArray.y,']]..character..[[',false);
					newChar.alpha = 0.001;
					setVar("]]..tag..[["] = newChar;
					game.insert(game.members.indexOf(game.dadGroup),newChar);
				}
			]]
		)
	end
end
function changeExtraCharacter(character, lua) -- character = character json, lua = the name of the sprite already created
	addExtraCharToList(character)
	runHaxeCode(
		[[
			var char = getVar("]]..character..[[");
			var oldChar = getVar("]]..lua..[[");
			if(char != null and oldChar != null){
				char.alpha = 1;
				char.x = oldChar.x - oldChar.positionArray[0] + char.positionArray[0];
				char.y = oldChar.y - oldChar.positionArray[1] + char.positionArray[1];
				newChar.x += newChar.positionArray[0];
				newChar.y += newChar.positionArray[1];
				oldChar.alpha = 0;
				char = newChar;
				setVar("]]..lua..[[",char);
			}
		}
	]]
	)
end
function resetExtraCharPos(char,whichGroup)
	if luaSpriteExists(char) then
		if whichGroup == nil then
			if getProperty(char..'.isPlayer') then
				whichGroup = 'boyfriendGroup'
			else
				whichGroup = 'dadGroup'
			end
		elseif whichGroup == 'dad' then
			whichGroup = 'dadGroup'
		elseif whichGroup == 'gf' then
			whichGroup = 'gfGroup'
		else
			whichGroup = 'boyfriendGroup'
		end
		setProperty(char..'.x',getProperty(whichGroup..'.x') + getProperty(char..'.positionArray[0]')*(getProperty(char..'isPlayer') and -1 or 1))
		setProperty(char..'.y',getProperty(whichGroup..'.y') + getProperty(char..'.positionArray[1]'))
	end
end
function onBeatHit()
	local characters = ''
	for i, char in pairs(extraCharacters) do
		characters = ',"'..char..'"'
	end
	characters = string.sub(characters,2)
	runHaxeCode(
		[[
			for(char in []]..characters..[[]){
				var extraChar = game.getLuaObject(char);
				if(extraChar != null && !extraChar.specialAnim && extraChar.holdTimer == 0 && !StringTools.startsWith(extraChar.animation.curAnim.name,'sing')){
					extraChar.dance();
				}
			}
		]]
	)
end