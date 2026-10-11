function onCreate()
	-- Background
	makeLuaSprite('bg', 'stages/Tabi/restaurant/bg', -1100, -550);
	setScrollFactor('bg', 1, 1);
	scaleObject('bg', 0.825, 0.825);
	addLuaSprite('bg', false);

	-- Chandelier (Lustre)
	-- O Codename usa "high-memory", na Psych apenas checamos se Low Quality está desativado
	if not lowQuality then
		makeLuaSprite('chandelier', 'stages/Tabi/restaurant/chandelier', 250, -400);
		setScrollFactor('chandelier', 1.05, 1.05);
		addLuaSprite('chandelier', false);
	end

	-- Foreground (Frente)
	if not lowQuality then
		makeLuaSprite('fg', 'stages/Tabi/restaurant/fg', -800, 600);
		setScrollFactor('fg', 1.25, 1.25);
		setProperty('fg.alpha', 0.75);
		addLuaSprite('fg', true); -- 'true' define que fica na frente dos personagens
	end
end