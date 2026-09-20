#if DISCORD_ALLOWED
import funkin.utils.api.DiscordAPI;
#end

#if LUA_ALLOWED
import llua.*;
import llua.Lua;
#end

#if ACHIEVEMENTS_ALLOWED
import funkin.states.achievements.data.Achievements;
#end

#if sys
import sys.*;
import sys.io.*;
#elseif js
import js.html.*;
#end

// Pico Engine Stuff - v2.26.7
import funkin.Paths;
import funkin.data.ClientPrefs;
import funkin.data.objects.Alphabet;

import funkin.states.PlayState;
import funkin.states.LoadingScreenMenuState;
import funkin.states.MusicBeatState;
import funkin.states.TitleMenuState;
import funkin.states.CreditsMenuState;
import funkin.states.menus.MainMenuState;
import funkin.states.menus.StoryModeMenuState;
import funkin.states.options.OptionsMenuState;

import funkin.play.Rank;
import funkin.play.Difficulty;
import funkin.play.Conductor;

import funkin.stages.BaseStage;
import funkin.stages.BGSprite;

import funkin.utils.Controls;
import funkin.utils.CoolUtil;
import funkin.utils.CustomFadeTransition;
import funkin.utils.engines.pico.EnginePerformance;

import funkin.translations.Language;
import funkin.substates.MusicBeatSubstate;
import funkin.modding.ModsMenuState;

#if MODS_ALLOWED
import funkin.modding.Mods;
#end

#if LUA_ALLOWED
import funkin.modding.scripting.FunkinLuaProgramming;
import funkin.modding.scripting.psychlua.*;
#end

#if PSYCH_ALLOWED
// Psych UI Elements
import funkin.utils.engines.psych.ui.*;
#end

#if flxanimate
import funkin.utils.engines.psych.PsychFlxAnimate as FlxAnimate;
import flxanimate.*;
#end

// News Flixel and openfl
import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.transition.FlxTransitionableState;
import flixel.system.FlxAssets.FlxShader;
import flixel.addons.display.FlxGridOverlay;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import flixel.FlxSubState;
import flixel.util.FlxSave;
import flixel.util.FlxSort;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxStringUtil;
import flixel.util.FlxDestroyUtil;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.frames.FlxAtlasFrames;

import lime.utils.Assets;
import lime.media.AudioBuffer;

import flash.media.Sound;
import flash.geom.Rectangle;

import haxe.Json;
import haxe.Exception;
import haxe.io.Bytes;

import openfl.media.Sound;
import lime.utils.Assets;
using StringTools;