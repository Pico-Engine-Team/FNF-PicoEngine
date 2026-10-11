function onCreate()
	Dodged = false;
    canDodge = false;
    DodgeTime = 0;
	
    precacheImage('mechanics/DodgeSpacebar');
    precacheImage('ui/mechanics/Notes/Bullet/dodged');
end

function onCreatePost()

    makeLuaSprite("popDodge", "ui/mechanics/Notes/Bullet/dodged", 0, 500)
    setObjectCamera("popDodge", 'other')
    addLuaSprite("popDodge", false)
    screenCenter('popDodge', 'x')
    scaleObject('popDodge', 0.55, 0.55, false)
    setProperty('popDodge.alpha', 0)
end

function onEvent(name, value1, value2)
    if name == "DodgeEvent" then
    DodgeTime = (value1);
	
    canDodge = true;
	makeAnimatedLuaSprite('spacebar', 'mechanics/DodgeSpacebar', 400, 200);
    luaSpriteAddAnimationByPrefix('spacebar', 'spacebar', 'spacebar', 25, true);
	luaSpritePlayAnimation('spacebar', 'spacebar');
	setObjectCamera('spacebar', 'other');
	scaleLuaSprite('spacebar', 0.50, 0.50); 
    addLuaSprite('spacebar', true); 
	runTimer('Died', DodgeTime);
	end
end

function onUpdate()
   if canDodge and keyboardJustPressed('SPACE') then
   
    canDodge = false
    Dodged = true;
    characterPlayAnim('boyfriend', 'dodge', true);
    setProperty('boyfriend.specialAnim', true);
    removeLuaSprite('spacebar');
   end
end

function onTimerCompleted(tag, loops, loopsLeft)
   if tag == 'Died' and Dodged == false then
   setProperty('health', 0);
   
   elseif tag == 'Died' and Dodged == true then
   Dodged = false
   end
end