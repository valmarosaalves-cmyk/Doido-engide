package;

import backend.game.*;
import backend.system.FPSCounter;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import haxe.CallStack;
import haxe.io.Path;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.UncaughtErrorEvent;
import flixel.util.typeLimit.NextState;
import flixel.util.FlxSave; // Import necessário para o save

#if desktop
import backend.system.ALSoftConfig;
#end

#if !html5
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class Main extends Sprite
{
	public static var FPSCounter:FPSCounter;

	// Use these to customize your mod further!
	public static final savePath:String = "arthur/noobEngine";
	public static var gFont:String = Paths.font("vcr.ttf");

	public function new()
	{
		super();
		// thanks @sqirradotdev
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);

		var ws:Array<String> = SaveData.displaySettings.get("Window Size")[0].split("x");
		var windowSize:Array<Int> = [Std.parseInt(ws[0]),Std.parseInt(ws[1])];

		// --- LÓGICA DA LOGO HAXEFLIXEL (APARECE UMA ÚNICA VEZ) ---
		var showSplash:Bool = false; 
		var splashSave:FlxSave = new FlxSave();
		splashSave.bind('haxeSplashCheck', 'arthur/noobEngine');

		if (splashSave.data.seenBefore != null && splashSave.data.seenBefore == true) {
			showSplash = true; // Se já viu, skipSplash = true (Pula)
		} else {
			showSplash = false; // Se não viu, skipSplash = false (Mostra a logo colorido)
			splashSave.data.seenBefore = true;
			splashSave.flush();
		}
		// -------------------------------------------------------

		// Agora usamos a variável showSplash no lugar do "true" que estava fixo
		addChild(new FlxGame(windowSize[0], windowSize[1], Init, 120, 120, showSplash));

		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#elseif desktop
		addChild(fpsCounter = new FPSCounter(5, 3));
		#end

		#if ENABLE_PRINTING
		Logs.init();
		#end

		// shader coords fix
		FlxG.signals.focusGained.add(function() {
			resetCamCache();
		});
		FlxG.signals.gameResized.add(function(w, h) {
			resetCamCache();
		});

		FlxG.stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, (e) ->
		{
			if (e.keyCode == FlxKey.F11)
				FlxG.fullscreen = !FlxG.fullscreen;
			
			if (e.keyCode == FlxKey.ENTER && e.altKey)
				e.stopImmediatePropagation();
		}, false, 100);
	}
	
	function resetCamCache()
	{
		if(FlxG.cameras != null) {
			for(cam in FlxG.cameras.list) {
				if(cam != null && cam.filters != null)
					resetSpriteCache(cam.flashSprite);
			}
		}
		if(FlxG.game != null)
			resetSpriteCache(FlxG.game);
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
			sprite.__cacheBitmap 	 = null;
			sprite.__cacheBitmapData = null;
		}
	}

	function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		e.preventDefault();
		e.stopImmediatePropagation();

		var path:String;
		var exception:String = 'Exception: ${e.error}\n';
		var stackTraceString = exception + StringTools.trim(CallStack.toString(CallStack.exceptionStack(true)));
		var dateNow:String = Date.now().toString().replace(" ", "_").replace(":", "'");

		path = 'crash/DoidoEngine_${dateNow}.txt';

		#if sys
		if (!FileSystem.exists("crash/"))
			FileSystem.createDirectory("crash/");
		File.saveContent(path, '${stackTraceString}\n');
		#end

		var normalPath:String = Path.normalize(path);

		Logs.print(stackTraceString, ERROR, true, true, false, false);
		Logs.print('Crash dump saved in $normalPath', WARNING, true, true, false, false);

		#if (flixel < "6.0.0")
		FlxG.bitmap.dumpCache();
		#end

		FlxG.bitmap.clearCache();
		CoolUtil.playMusic();

		Main.skipTrans = true;
		Main.switchState(new CrashHandlerState(stackTraceString + '\n\nCrash log created at: "${normalPath}"'));
	}
	
	public static var activeState:FlxState;
	
	public static var skipClearMemory:Bool = false; 
	public static var skipTrans:Bool = true; 
	public static var lastTransition:String = '';
	public static function switchState(?target:NextState, transition:String = 'funkin'):Void
	{
		lastTransition = transition;
		var trans = new GameTransition(false, transition);
		trans.finishCallback = function()
		{
			if(target != null)		
				FlxG.switchState(target);
			else
				FlxG.resetState();
		};

		if(skipTrans)
			return trans.finishCallback();
		
		if(activeState != null)
			activeState.openSubState(trans);
	}
	
	public static function resetState(transition:String = 'funkin'):Void
		return switchState(null, transition);

	public static function skipStuff(?ohreally:Bool = true):Void
	{
		skipClearMemory = ohreally;
		skipTrans = ohreally;
	}

	public static function changeFramerate(rawFps:Float = 120)
	{
		var newFps:Int = Math.floor(rawFps);

		if(newFps > FlxG.updateFramerate)
		{
			FlxG.updateFramerate = newFps;
			FlxG.drawFramerate   = newFps;
		}
		else
		{
			FlxG.drawFramerate   = newFps;
			FlxG.updateFramerate = newFps;
		}
	}
}

