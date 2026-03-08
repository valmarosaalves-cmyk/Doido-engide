package states;

import doido.utils.DoidoPoint;
import flixel.math.FlxMath;
import doido.song.*;
import doido.song.chart.SongHandler;
import doido.song.chart.SongHandler.DoidoSong;
import doido.song.chart.SongHandler.DoidoEvents;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import hscript.iris.Iris;
import objects.*;
import objects.play.*;
import objects.ui.*;
import objects.ui.hud.*;
import objects.ui.notes.*;
import states.editors.ChartingState;
import substates.PauseSubState;
import doido.objects.DoidoCamera;
import doido.utils.LerpUtil;

#if TOUCH_CONTROLS
import doido.objects.DoidoHitbox;
#end

class PlayState extends MusicBeatState implements Playable
{
	public static var SONG:DoidoSong;
	public static var EVENTS:DoidoEvents;
	public static var skip:Bool = false;

	public var playField:PlayField;
	public var hudClass:BaseHud;
	public var debugInfo:DebugInfo;

	var camGame:DoidoCamera;
	var camHUD:DoidoCamera;
	var camStrum:DoidoCamera;
	var camOther:DoidoCamera;

	var camFollow:LerpPoint = new LerpPoint();
	var camDisplace:LerpPoint = new LerpPoint();
	var defaultCamZoom:Float = 1.0;
	var defaultHudZoom:Float = 1.0;

	public var curFocus:String = "";
	public var maxDisplace:DoidoPoint = {x: 0, y: 0};

	public var paused:Bool = false;
	public var canPause:Bool = true;

	var audio:AudioHandler;
	var defaultSongSpeed:Float = 1.0;

	var dad:CharGroup;
	var bf:CharGroup;
	var characters:Array<CharGroup> = [];

	public var health:Float = 1;

	#if TOUCH_CONTROLS
	var pauseButton:DoidoHitbox;
	#end

	public var spawnEvents:Array<EventData> = [];
	public var curEventCount:Int = 0;

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

		Conductor.initialBPM = SONG.bpm;
		Conductor.mapBPMChanges(EVENTS.events);
		Conductor.songPos = -(Conductor.crochet * 5);
		resetStatics();

		spawnEvents = EVENTS.events;
		
		audio = new AudioHandler(SONG.song);

		camGame = new DoidoCamera(false, true);
		camHUD = new DoidoCamera(true, false);
		camStrum = new DoidoCamera(true, false);
		camOther = new DoidoCamera(true, false);
		
		var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
		bg.scrollFactor.set();
		bg.screenCenter();
		add(bg);
		
		bf = new CharGroup(true);
		bf.addChar("bf", true);
		bf.setPos(
			(FlxG.width / 2) + (FlxG.width / 4),
			FlxG.height - 50
		);
		add(bf);

		dad = new CharGroup(false);
		dad.addChar("face", true);
		dad.setPos(
			(FlxG.width / 2) - (FlxG.width / 4),
			FlxG.height - 50
		);
		add(dad);
		
		characters.push(dad);
		characters.push(bf);

		//temporary caching
		Assets.image("hud/base/numbers");
		Assets.image("hud/base/ratings");
		Assets.sparrow("notes/base/splashes");
		Assets.sparrow("notes/base/covers");
		for(i in 0...4)
			Assets.sound("countdown/base/intro" + ["3", "2", "1", "Go"][i]);

		hudClass = switch(SONG.song) {
			default: new DoidoHud(this);
		}
		add(hudClass);

		callScript("create");
		
		playField = new PlayField(SONG.notes, SONG.speed, Save.data.downscroll, Save.data.middlescroll);
		playField.cameras = [camStrum];
		add(playField);

		bf.strumline = playField.bfStrumline;
		dad.strumline = playField.dadStrumline;

		hudClass.init();
		hudClass.cameras = [camHUD];
		setUpInput();
		
		debugInfo = new DebugInfo(this);
		debugInfo.cameras = [camStrum];
		add(debugInfo);

		#if TOUCH_CONTROLS
		pauseButton = new DoidoHitbox(0,0,100,100,0.4);
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

		followCamera("dad");
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

				var judge = Timings.getTiming(rating).judge;
				var healthJudge:Float = 0.05 * judge;
				if(judge < 0) healthJudge *= 2;
				health += healthJudge;
			}

			if (rating != "miss") hudClass.popUpRating(rating);
			hudClass.updateScoreTxt();
		}

		playField.onNoteHit = (note, strumline) ->
		{
			if (note.isHold && !note.isHoldEnd) return;

			if (!note.isHold)
			{
				for(char in characters)
				{
					if (char.strumline == strumline)
						char.playSingAnim(note);
				}
			}

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

			for(char in characters)
			{
				if (char.strumline == strumline)
					char.playSingAnim(note, true);
			}
			
			if (strumline.isPlayer)
			{
				audio.muteVoices = true;
				updateScore(note, Timings.getTiming("miss").diff);
			}
		};
		playField.onNoteHold = (note, strumline) -> {
			for(char in characters)
			{
				if (char.strumline == strumline) {
					if(char.singType == LAST)
						char.resetSingStep();
					else if(char.curAnimFrame == char.singLoop || char.singType == FIRST)
						char.playSingAnim(note);
				}
			}

			if (strumline.isPlayer)
				health += FlxG.elapsed * 0.08;
		};
		
		playField.onGhostTap = (lane, direction) ->
		{
			//Logs.print("GHOST TAPPED " + direction.toUpperCase(), WARNING);
			hudClass.updateScoreTxt();
		};
	}

	var cameraSpeed:Float = 1.0;
	override function update(elapsed:Float)
	{
		callScript("update", [elapsed]);
		super.update(elapsed);

		function followLerp():Float
			return FlxMath.bound((cameraSpeed * 5 * elapsed), 0, 1);

		updateDisplace();
		camGame.moveCam([
			camFollow.get(followLerp()),
			camDisplace.get(followLerp()),
			{x: -FlxG.width/2, y: -FlxG.height/2}
		]);
		
		camGame.zoom = FlxMath.lerp(camGame.zoom, defaultCamZoom, elapsed * 12);
		for(cam in [camHUD, camStrum])
			cam.zoom = FlxMath.lerp(cam.zoom, defaultHudZoom, elapsed * 12);

		health = FlxMath.bound(health, 0, 2);
		if(Controls.justPressed(RESET) || health <= 0) {
			MusicBeat.skipClearCache = true;
			MusicBeat.switchState(new states.PlayState());
		}

		if (FlxG.keys.justPressed.SEVEN)
			MusicBeat.switchState(new ChartingState(SONG, EVENTS));
		
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

		if (curEventCount < spawnEvents.length)
		{
			for(i in 0...spawnEvents.length)
			{
				if (i < curEventCount) continue;

				var eventData = spawnEvents[curEventCount];
				if ((eventData.stepTime - curStepFloat) <= 0) {
					playEvent(eventData);
					curEventCount++;
				}
					
			}
		}
			
		playField.updateNotes(curStepFloat);
		callScript("updatePost", [elapsed]);
	}

	function playEvent(event:EventData) {
		switch(event.name) {
			case "Camera Focus":
				followCamera(event.data[0]);
		}
	}

	public function followCamera(charStr:String = "", ?offset:DoidoPoint){
		var char = strToChar(charStr);
		curFocus = charStr;
		camFollow.set({x: 0,y: 0});

		if(char != null) {
			var playerMult:Int = (char.isPlayer ? -1 : 1);

			camFollow.set({x: char.getMidpoint().x + (200 * playerMult), y: char.getMidpoint().y - 20});

			//camFollow.x += char.cameraOffset.x * playerMult;
			//camFollow.y += char.cameraOffset.y;
		}

		if(offset != null) {
			//camFollow.x += offset.x;
			//camFollow.y += offset.y;
		}
	}

	function updateDisplace() {
		if(maxDisplace == {x: 0, y: 0}) return;
		switch (strToChar(curFocus).curAnimName) {
			case 'singLEFT':
				camDisplace.set({x: -maxDisplace.x, y: 0});
			case 'singRIGHT':
				camDisplace.set({x: maxDisplace.x, y: 0});
			case 'singUP':
				camDisplace.set({x: 0, y: -maxDisplace.y});
			case 'singDOWN':
				camDisplace.set({x: 0, y: maxDisplace.y});
			default:
				camDisplace.set({x: 0, y: 0});
		}
	}

	function strToChar(str:String, nullable:Bool = false):CharGroup {
		return switch(str) {
			default: nullable ? null : dad;
			case 'dad': dad;
			case 'bf'|'boyfriend': 	bf;
			//case 'gf'|'girlfriend': gf; //she doesnt exist yet!
		}
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
		hudClass.stepHit(curStep);
	}

	var camSwitch:Bool = true; //remove later...
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

		if (curBeat % 2 == 0)
		{
			// dancing
			for(char in characters)
			{
				if (char.singStep <= 0)
				{
					if (char.isPlayer)
					{
						if (!playField.playerHolding)
							char.dance();
					}
					else
						char.dance();
				}
			}
		}

		if (curBeat % 4 == 0)	
		{
			beatCamera(1.05, 1.02);
		}

		/*if(curBeat % 16 == 0 && curBeat > 0) {
			followCamera(camSwitch ? "bf" : "dad");
			camSwitch = !camSwitch;
		}*/

		hudClass.beatHit(curBeat);
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

	public var player1(get, never):String;
	public function get_player1():String
		return bf.curChar;

	public var player2(get, never):String;
	public function get_player2():String
		return dad.curChar;
}

interface Playable {
	var health:Float;
	var player1(get, never):String;
	var player2(get, never):String;
}