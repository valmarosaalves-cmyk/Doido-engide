package states;

import flixel.math.FlxMath;
import substates.PauseSubState;
import animate.FlxAnimate;
import doido.song.*;
import doido.song.chart.SongHandler;
import doido.song.chart.SongHandler.DoidoSong;
import doido.song.chart.SongHandler.DoidoEvents;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import objects.*;
import objects.play.*;
import objects.ui.*;
import objects.ui.hud.*;
import objects.ui.notes.*;
import hscript.iris.Iris;
import flixel.FlxCamera;

#if TOUCH_CONTROLS
import doido.objects.DoidoButton.ButtonHitbox;
#end

using doido.utils.CameraUtil;

class PlayState extends MusicBeatState
{
	public static var SONG:DoidoSong;
	public static var EVENTS:DoidoEvents;
	public static var skip:Bool = false;

	public var playField:PlayField;
	public var hudClass:BaseHud;
	public var debugInfo:DebugInfo;

	var camGame:FlxCamera;
	var camHUD:FlxCamera;
	var camStrum:FlxCamera;
	var camOther:FlxCamera;

	var defaultCamZoom:Float = 1.0;
	var defaultHudZoom:Float = 1.0;

	public var paused:Bool = false;
	public var canPause:Bool = true;

	var audio:AudioHandler;
	var defaultSongSpeed:Float = 1.0;

	#if TOUCH_CONTROLS
	var pauseButton:ButtonHitbox;
	#end

	public static var instance:PlayState;
	public var loadedScripts:Array<Iris> = [];

	public static function loadSong(jsonInput:String, ?diff:String = "normal")
	{
		SONG = SongHandler.loadSong(jsonInput, diff);
		EVENTS = SongHandler.loadEvents(jsonInput, diff);
	}

	public function resetStatics()
	{
		Timings.init();	
	}
	
	override function create()
	{
		super.create();
		instance = this;
		DiscordIO.changePresence("Playing - " + SONG.song);
		persistentDraw = true;
		persistentUpdate = false;

		var scriptPaths:Array<String> = Assets.getScriptArray(SONG.song);
		for(path in scriptPaths) {
			var newScript:Iris = new Iris(Assets.script('$path'), instance, {name: path, autoRun: true, autoPreset: true});
			loadedScripts.push(newScript);
		}
		//setScript("this", instance); //hopefully we wont be needing THIS anymore!

		Conductor.initialBPM = SONG.bpm;
		Conductor.mapBPMChanges(EVENTS.events);
		Conductor.songPos = -(Conductor.crochet * 5);
		resetStatics();
		
		audio = new AudioHandler(SONG.song);

		camGame = new FlxCamera().createCam(false, true);
		camHUD = new FlxCamera().createCam(true, false);
		camStrum = new FlxCamera().createCam(true, false);
		camOther = new FlxCamera().createCam(true, false);
		
		var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
		//bg.zIndex = 500;
		add(bg);

		//temporary caching
		Assets.image("hud/base/numbers");
		Assets.image("hud/base/ratings");
		Assets.sparrow("notes/base/splashes");
		Assets.sparrow("notes/base/covers");

		hudClass = switch(SONG.song)
		{
			default: new DoidoHud();
		}
		hudClass.playState = this;
		add(hudClass);

		callScript("create");
		
		playField = new PlayField(SONG.notes, SONG.speed, Save.data.downscroll, Save.data.middlescroll);
		playField.cameras = [camStrum];
		add(playField);

		hudClass.init();
		hudClass.cameras = [camHUD];
		setUpInput();
		
		debugInfo = new DebugInfo(this);
		add(debugInfo);

		#if TOUCH_CONTROLS
		pauseButton = new ButtonHitbox(0,0,100,100,0.4);
		add(pauseButton);
		#end

		if(skip) {
			audio.play();
			audio.pause();
			audio.time = 50000;
			updateStep();
			for(note in SONG.notes)
			{
				if (note.stepTime <= curStepFloat)
					playField.curSpawnNote++;
			}
		}

		callScript("createPost");
	}

	public function setUpInput()
	{
		function updateScore(note:Note, noteDiff:Float)
		{
			var rating = "sick";
			if (note.isHold)
			{
				Timings.addScoreHold(note);
				rating = Timings.addAccuracyHold(note.holdHitPercent);
			}
			else
			{
				Timings.addScore(note, noteDiff);
				rating = Timings.addAccuracyDiff(noteDiff);
				hudClass.popUpCombo(Timings.combo);
			}
			if (rating != "miss") hudClass.popUpRating(rating);
			hudClass.updateScoreTxt();
		}

		playField.onNoteHit = (note, strumline) ->
		{
			if (note.isHold && !note.isHoldEnd) return;

			if (strumline.isPlayer)
			{
				audio.muteVoices = false;
				updateScore(note, playField.noteDiff(note.data));
			}
			else
			{
				if (audio.voicesOpp == null) audio.muteVoices = false;
			}
		};
		playField.onNoteMiss = (note, strumline) ->
		{
			if (note.isHold && !note.isHoldEnd) return;
			
			if (strumline.isPlayer)
			{
				audio.muteVoices = true;
				updateScore(note, Timings.getTiming("miss").diff);
			}
		};
		
		playField.onGhostTap = (lane, direction) ->
		{
			//Logs.print("GHOST TAPPED " + direction.toUpperCase(), WARNING);
			hudClass.updateScoreTxt();
		};
	}

	override function update(elapsed:Float)
	{
		callScript("update", [elapsed]);
		super.update(elapsed);
		
		camGame.zoom = FlxMath.lerp(camGame.zoom, defaultCamZoom, elapsed * 12);
		for(cam in [camHUD, camStrum])
			cam.zoom = FlxMath.lerp(cam.zoom, defaultHudZoom, elapsed * 12);

		if(Controls.justPressed(RESET)) {
			MusicBeat.skipClearCache = true;
			MusicBeat.switchState(new states.PlayState());
		}

		#if debug
		if (FlxG.keys.justPressed.F9)
			audio.speed = 10;
		if (FlxG.keys.justReleased.F9)
			audio.speed = defaultSongSpeed;
		#end
		
		if (canPause)
		{
			if(Controls.justPressed(PAUSE) #if TOUCH_CONTROLS || pauseButton.justPressed #end) {
				pauseSong();
			}
		}
		
		if (!paused)
			Conductor.songPos += elapsed * 1000 * audio.speed;
			
		playField.updateNotes(curStepFloat);
		callScript("updatePost", [elapsed]);
	}

	public function startSong()
	{
		audio.play();
	}

	public function pauseSong()
	{
		paused = true;
		audio.pause();
		audio.speed = 0.0;
		MusicBeat.activateTimers(false);
		openSubState(new PauseSubState());
	}

	public function unpauseSong()
	{
		MusicBeat.activateTimers(true);
		paused = false;
		if (Conductor.songPos < audio.length)
		{
			if (Conductor.songPos >= 0)
				audio.play();

			FlxTween.cancelTweensOf(audio);
			FlxTween.tween(audio, {speed: defaultSongSpeed}, Conductor.crochet / 1000, {ease: FlxEase.sineIn});
		}
		else
			audio.speed = defaultSongSpeed;
	}

	public function beatCamera(gameZoom:Float, hudZoom:Float)
	{
		camGame.zoom *= gameZoom;
		for(cam in [camHUD, camStrum])
			cam.zoom *= hudZoom;
	}

	override function stepHit()
	{
		super.stepHit();
		callScript("stepHit", [curStep]);
		playField.stepHit(curStep);
		if (audio.playing && Conductor.songPos < audio.length)
			audio.sync();
		
		if (Conductor.songPos >= audio.length)
		{
			canPause = false;
			MusicBeat.switchState(new states.DebugMenu());
		}
	}

	override function beatHit()
	{
		super.beatHit();
		callScript("beatHit", [curBeat]);

		// COUNTDOWN AND SONG START
		if (curBeat <= 0)
		{
			// start song
			if (curBeat == 0)
				startSong();
			else if (curBeat + 4 >= 0) // countdown
			{
				//trace(curBeat + 4);
				FlxG.sound.play(Assets.sound("countdown/base/intro" + ["3", "2", "1", "Go"][curBeat + 4]));
			}
		}

		if (curBeat % 4 == 0)
			beatCamera(1.05, 1.02);
	}

	public function callScript(fun:String, ?args:Array<Dynamic>) {
		for(script in loadedScripts) {
			@:privateAccess {
				var ny: Dynamic = script.interp.variables.get(fun);
				try {
					if(ny != null && Reflect.isFunction(ny))
						script.call(fun, args);
				} catch(e) {
					Logs.print('error parsing script: ' + e, ERROR);
				}
			}
		}
	}
	
	public function setScript(name:String, value:Dynamic, allowOverride:Bool = true) {
		for(script in loadedScripts)
			script.set(name, value, allowOverride);
	}
}