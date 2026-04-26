// Flixel core
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.FlxCamera;
import flixel.FlxBasic;
import flixel.FlxObject;

// Flixel display
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.ui.FlxButton;

// Flixel groups
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

// Flixel math & utils
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxAxes;

// Flixel animation & graphics
import flixel.animation.FlxAnimationController;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;

// Flixel tweens & effects
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.effects.FlxFlicker;

// Flixel sound
import flixel.sound.FlxSound;
import flixel.sound.FlxSoundGroup;

// Flixel input
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.touch.FlxTouch;

// Flixel addons
import flixel.addons.display.FlxRuntimeShader;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.FlxTransitionSprite;
import flixel.addons.ui.FlxInputText;

// OpenFL
import openfl.display.Sprite;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.Assets;
import openfl.Lib;
import openfl.events.Event;

// Haxe std
import haxe.Json;
import haxe.io.Path;

// Psych Engine backend
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import backend.Controls;
import backend.ClientPrefs;
import backend.Conductor;
import backend.CoolUtil;
import backend.Mods;
import backend.Paths;
import backend.Highscore;
import backend.WeekData;
import backend.Song;
import backend.Language;
import backend.Achievements;
import backend.BaseStage;
import backend.NoteTypesConfig;

// Psych Engine states
import states.PlayState;

// Psych Engine objects
import objects.Note;
import objects.StrumNote;
import objects.Alphabet;
import objects.AttachedSprite;
import objects.Bar;
import objects.BGSprite;
import objects.CheckboxThingie;
import objects.HealthIcon;
import objects.MenuCharacter;
import objects.NoteSplash;

// Pico Engine backend
import lucas.states.funkin.scripts.backend.display.fps.FPSCounter;

// Shaders
import shaders.ColorSwap;

#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
#end

#if LUA_ALLOWED
import psychlua.LuaUtils;
import psychlua.HScript;
#end

#if DISCORD_ALLOWED
import backend.Discord.DiscordClient;
#end

#if mobile
import flixel.input.touch.FlxTouch;
#end
