--Recreation Made by JogadorIce--
--Please Dont Forgot about my Credits for making this script for you--
-- OG Inspiration of This Script is of: --
-- Friday Night Funkin' VS Sonic.exe 2.5/3.0 Cancelled Build --
-- That Have a Credits Box on Start of Song --
-- Will Have some "-- Text --" On Script to Help You for Change --
-- For this Script Work, you need put that Credits.lua File on Data / Your Song --
-- (Dont change Name Of File!) --
-- Thank you For Read This, Enjoy! :) --

-- Main Work Tags --
function onCreate()
	makeLuaSprite('Main', 'CREDITTEXT', 350, -1300)
	makeGraphic('Main', 570, 1300, '373737')
	setObjectCamera('Main', 'other')
	setProperty('Main.alpha', 0.9)
	addLuaSprite('Main', true)
	
	makeLuaSprite('BorderLeft', 'OUTLINE', 350, -1300)
	makeGraphic('BorderLeft', 7, 1300, 'FFFFFF')
	setObjectCamera('BorderLeft', 'other')
	setProperty('BorderLeft.alpha', 0.8)
	addLuaSprite('BorderLeft', true)
	makeLuaSprite('BorderRight', 'OUTLINE', 920, -1300)
	makeGraphic('BorderRight', 7, 1300, 'FFFFFF')
	setObjectCamera('BorderRight', 'other')
	setProperty('BorderRight.alpha', 0.8)
	addLuaSprite('BorderRight', true)

	makeLuaText('CREDITS', 'CREDITS', 1000, 132, -1000) -- Title Credits Box (Dont need Change) --
	setTextAlignment('CREDITS', 'center')
	setTextSize('CREDITS', 50)
	setObjectCamera('CREDITS', 'other')
	addLuaText('CREDITS')
	
	makeLuaText('CODERS', 'CODERS', 1000, 132, -1000) -- Coder Tag --
	setTextAlignment('CODERS', 'center')
	setTextSize('CODERS', 35)
	setObjectCamera('CODERS', 'other')
	addLuaText('CODERS')

	makeLuaText('ARTISTS', 'ARTISTS', 1000, 132, -1000) -- Artist Tag --
	setTextAlignment('ARTISTS', 'center')
	setTextSize('ARTISTS', 35)
	setObjectCamera('ARTISTS', 'other')
	addLuaText('ARTISTS')
	
	makeLuaText('MUSICIANS', 'MUSICIANS', 1000, 132, -1000) -- Composer Tag --
	setTextAlignment('MUSICIANS', 'center')
	setTextSize('MUSICIANS', 35)
	setObjectCamera('MUSICIANS', 'other')
	addLuaText('MUSICIANS')
	
	makeLuaText('CHARTERS', 'CHARTER', 1000, 132, -1000) -- Charter Tag --
	setTextAlignment('CHARTERS', 'center')
	setTextSize('CHARTERS', 35)
	setObjectCamera('CHARTERS', 'other')
	addLuaText('CHARTERS')

	-- Insert Name of People that Working on Your Mode Here --
	makeLuaText('CODER1', 'LucasSanches Baran', 1000, 132, -1000) --Team Member Helping Name Here--
	setTextAlignment('CODER1', 'center')
	setTextSize('CODER1', 25)
	setObjectCamera('CODER1', 'other')
	addLuaText('CODER1')
	
	makeLuaText('ARTIST1', 'Sonic.Exe Team', 1000, 132, -1000) --Team Member Helping Name Here--
	setTextAlignment('ARTIST1', 'center')
	setTextSize('ARTIST1', 25)
	setObjectCamera('ARTIST1', 'other')
	addLuaText('ARTIST1')
	
	makeLuaText('MUSICIAN1', '@felizen', 1000, 132, -1000) --Team Member Helping Name Here--
	setTextAlignment('MUSICIAN1', 'center')
	setTextSize('MUSICIAN1', 25)
	setObjectCamera('MUSICIAN1', 'other')
	addLuaText('MUSICIAN1') 
	
	makeLuaText('CHARTER1', '?', 1000, 132, -1000) --Team Member Helping Name Here--
	setTextAlignment('CHARTER1', 'center')
	setTextSize('CHARTER1', 25)
	setObjectCamera('CHARTER1', 'other')
	addLuaText('CHARTER1')
end
function onStepHit()
	-- Position of Texts and The Box and Animations --
	-- (Dont Need Change anything of This) --

	if curStep == 10 then -- Time of Credits Box Come --
	
	doTweenY('UNDERLAY1', 'Main', 0, 0.5, 'linear')
	doTweenY('UNDERLAY2', 'BorderLeft', 0, 0.5, 'linear')
	doTweenY('UNDERLAY3', 'BorderRight', 0, 0.5, 'linear')

	doTweenY('CREDSTEXT', 'CREDITS', 60, 0.3, 'linear')

	doTweenY('CODETEXT', 'CODERS', 140, 0.3, 'linear')
	doTweenY('CODER1', 'CODER1', 180, 0.3, 'linear')
	doTweenY('CODER2', 'CODER2', 210, 0.3, 'linear')
	doTweenY('CODER3', 'CODER3', 240, 0.3, 'linear')
	doTweenY('CODER4', 'CODER3', 240, 0.3, 'linear')

	doTweenY('ARTTEXT', 'ARTISTS', 280, 0.3, 'linear')
	doTweenY('ARTIST1', 'ARTIST1', 320, 0.3, 'linear')

	doTweenY('MUSICTEXT', 'MUSICIANS', 420, 0.3, 'linear')
	doTweenY('MUSICIAN1', 'MUSICIAN1', 460, 0.3, 'linear')

	doTweenY('CHARTEXT', 'CHARTERS', 560, 0.3, 'linear')
	doTweenY('CHARTER1', 'CHARTER1', 600, 0.3, 'linear')

	runTimer('Gone', 5, 3) -- Leaving Box --
	end
end
function onTimerCompleted(tag, loops, loopsLeft)
	if tag == 'Gone' then
	
	doTweenY('UNDERLAY1EXIT', 'Main', -1300, 0.2, 'linear')
	doTweenY('UNDERLAY2EXIT', 'BorderLeft', -1300, 0.2, 'linear')
	doTweenY('UNDERLAY3EXIT', 'BorderRight', -1300, 0.2, 'linear')

	doTweenY('CREDSTEXTEXIT', 'CREDITS', -1000, 0.3, 'linear')

	doTweenY('CODETEXTEXIT', 'CODERS', -1000, 0.3, 'linear')
	doTweenY('CODER1EXIT', 'CODER1', -1000, 0.3, 'linear')
	doTweenY('CODER2EXIT', 'CODER2', -1000, 0.3, 'linear')
	doTweenY('CODER3EXIT', 'CODER3', -1000, 0.3, 'linear')

	doTweenY('ARTTEXTEXIT', 'ARTISTS', -1000, 0.3, 'linear')
	doTweenY('ARTIST1EXIT', 'ARTIST1', -1000, 0.3, 'linear')

	doTweenY('MUSICTEXTEXIT', 'MUSICIANS', -1000, 0.3, 'linear')
	doTweenY('MUSICIAN1EXIT', 'MUSICIAN1', -1000, 0.3, 'linear')
	doTweenY('MUSICIAN2EXIT', 'MUSICIAN2', -1000, 0.3, 'linear')

	doTweenY('CHARTEXTEXIT', 'CHARTERS', -1000, 0.3, 'linear')
	doTweenY('CHARTER1EXIT', 'CHARTER1', -1000, 0.3, 'linear')
	end
end