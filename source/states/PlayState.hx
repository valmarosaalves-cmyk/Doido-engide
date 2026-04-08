package states;

import flixel.sound.FlxSound;
import flixel.math.FlxMath;
import doido.song.*;
import doido.song.chart.SongHandler;
import doido.song.chart.SongHandler.DoidoChart;
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
	public static var skip:Bool = false;

	public var playField:PlayField;
	public var hudClass:BaseHud;
	public var debugInfo:DebugInfo;

	public var camGame:DoidoCamera;
	public var camHUD:DoidoCamera;
	public var camStrum:DoidoCamera;
	public var camOther:DoidoCamera;

	public var camFollow:LerpPoint;
	public var camDisplace:LerpPoint;
	public var defaultHudZoom:Float = 1.0;

	public var camZoom:Float = 0.9;

	public var curFocus:String = "";
	public var maxDisplace:DoidoPoint = {x: 0, y: 0};

	public var paused:Bool = false;
	public var canPause:Bool = true;

	public var audio:AudioHandler;
	public var countdownSfx:Array<FlxSound> = [];

	public var defaultSongSpeed:Float = 1.0;
	public var startedSong:Bool = false;

	public var stageBuild:Stage;

	public var dad:CharGroup;
	public var bf:CharGroup;
	public var gf:CharGroup;
	public var characters:Array<CharGroup> = [];

	public var health:Float = 1;

	public var downscroll:Bool;
	public var middlescroll:Bool;
	public var validScore:Bool = true;

	#if TOUCH_CONTROLS
	var pauseButton:DoidoHitbox;
	#end

	public var spawnEvents:Array<EventData> = [];
	public var curEventCount:Int = 0;

	public static var instance:PlayState;

	public var loadedScripts:Array<Iris> = [];

	public static function loadSong(jsonInput:String, ?diff:String = "normal")
	{
		SONG = {
			CHART: SongHandler.loadChart(jsonInput, diff),
			EVENTS: SongHandler.loadEvents(jsonInput, diff),
			META: SongHandler.loadMeta(jsonInput, diff)
		};
	}

	public function resetStatics()
	{
		Timings.init();
	}

	override function create()
	{
		super.create();
		instance = this;
		DiscordIO.changePresence("Playing - " + CHART.song);
		persistentDraw = true;
		persistentUpdate = false;

		var scriptPaths:Array<String> = Assets.getScriptArray(CHART.song);
		for (path in scriptPaths)
		{
			var newScript:Iris = new Iris(Assets.script('$path'), instance, {name: path, autoRun: true, autoPreset: true});
			loadedScripts.push(newScript);
		}
		setScript("playState", instance);

		Conductor.initialBPM = CHART.bpm;
		Conductor.mapBPMChanges(EVENTS.events);
		Conductor.songPos = -(Conductor.crochet * 5);
		resetStatics();

		downscroll = (#if TOUCH_CONTROLS Save.data.modernControls #else false #end ?true:Save.data.downscroll);
		middlescroll = (#if TOUCH_CONTROLS Save.data.modernControls #else false #end ?true:Save.data.middlescroll);

		spawnEvents = EVENTS.events;

		audio = new AudioHandler(CHART.song);

		camGame = new DoidoCamera(false, true);
		camHUD = new DoidoCamera(true, false);
		camStrum = new DoidoCamera(true, false);
		camOther = new DoidoCamera(true, false);

		camFollow = new LerpPoint(true);
		camDisplace = new LerpPoint(true);

		stageBuild = new Stage(this);

		bf = new CharGroup(true);
		bf.addChar(META.player1, true);
		bf.setZ(10);

		dad = new CharGroup(false);
		dad.addChar(META.player2, true);
		dad.setZ(9);

		gf = new CharGroup(false);
		gf.addChar(META.gf, true);
		gf.setZ(8);

		characters.push(gf);
		characters.push(dad);
		characters.push(bf);

		for (char in characters)
		{
			add(char);
		}

		// temporary caching
		Assets.image("hud/base/numbers");
		Assets.image("hud/base/ratings");
		Assets.sparrow("notes/base/splashes");
		Assets.sparrow("notes/base/covers");
		for (i in 0...4)
		{
			countdownSfx.push(FlxG.sound.load(Assets.sound("countdown/base/intro" + ["3", "2", "1", "Go"][i])));
		}

		hudClass = switch (CHART.song)
		{
			default: new DoidoHud(this);
		}
		add(hudClass);

		for (event in spawnEvents)
			preloadEvent(event.name, event.data);

		callScript("create");
		changeStage(META.stage);

		playField = new PlayField(CHART.notes, CHART.speed, downscroll, middlescroll);
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
		pauseButton = new DoidoHitbox(0, 0, 100, 100, 0.4);
		pauseButton.cameras = [camOther];
		add(pauseButton);
		#end

		if (skip)
		{
			audio.play();
			audio.pause();
			audio.time = 50000;
			updateStep();
			for (note in CHART.notes)
			{
				if (note.stepTime <= curStepFloat)
					playField.curSpawnNote++;
			}
		}

		followCamera("dad");
		camFollow.get(1);

		camGame.zoom = camZoom;
		for (cam in [camHUD, camStrum])
			cam.zoom = defaultHudZoom;

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
				if (note.missed) health -= 0.1;
			}
			else
			{
				Timings.addScore(note, noteDiff);
				rating = Timings.addAccuracyDiff(noteDiff);
				hudClass.popUpCombo(Timings.combo);

				var judge = Timings.getTiming(rating).judge;
				var healthJudge:Float = 0.05 * judge;
				if (judge < 0)
					healthJudge *= 2;
				health += healthJudge;
			}

			if (rating != "miss")
				hudClass.popUpRating(rating);
			hudClass.updateScoreTxt();
		}

		function muteVoices()
		{
			if (Timings.combo >= 10)
			{
				if (gf.animExists("sad"))
				{
					gf.resetSingStep();
					gf.playAnim("sad");
				}
			}

			audio.muteVoices = true;
		}

		playField.onNoteHit = (note, strumline) ->
		{
			if (note.isHold && !note.isHoldEnd)
				return;

			if (!note.isHold || note.missed)
			{
				for (char in characters)
				{
					if (char.strumline == strumline)
						char.playSingAnim(note, note.missed);
				}
			}

			if (strumline.isPlayer)
			{
				if (note.missed)
					muteVoices();
				else
					audio.muteVoices = false;

				updateScore(note, playField.noteDiff(note.data));

				// cool thingy
				if (Timings.combo > 0 && Timings.combo % 50 == 0)
				{
					// nene weekend 1 support
					if (Timings.combo % 200 == 0 && gf.animExists("horny"))
					{
						gf.resetSingStep();
						gf.playAnim("horny");
					}
					else if (gf.animExists("cheer")) // gf cheer
					{
						gf.resetSingStep();
						gf.playAnim("cheer");
					}
				}
			}
			else
			{
				if (audio.voicesOpp == null)
					audio.muteVoices = false;
			}
			callScript("onNoteHit", [note, strumline]);
		};
		playField.onNoteMiss = (note, strumline) ->
		{
			if (note.isHold && !note.isHoldEnd)
				return;

			for (char in characters)
			{
				if (char.strumline == strumline)
					char.playSingAnim(note, true);
			}

			if (strumline.isPlayer)
			{
				muteVoices();
				updateScore(note, Timings.getTiming("miss").diff);
			}
			callScript("onNoteMiss", [note, strumline]);
		};
		playField.onNoteHold = (note, strumline) ->
		{
			for (char in characters)
			{
				if (char.strumline == strumline)
				{
					if (char.singType == LAST)
						char.resetSingStep();
					else if (char.curAnimFrame == char.singLoop || char.singType == FIRST)
						char.playSingAnim(note);
				}
			}

			if (strumline.isPlayer)
				health += FlxG.elapsed * 0.08;

			callScript("onNoteHold", [note, strumline]);
		};

		playField.onGhostTap = (lane, direction) ->
		{
			// Logs.print("GHOST TAPPED " + direction.toUpperCase(), WARNING);
			hudClass.updateScoreTxt();
			callScript("onGhostTap", [lane, direction]);
		};
	}

	public function changeStage(curStage:String)
	{
		if (curStage != stageBuild.curStage)
		{
			for (item in stageBuild.stageItems)
				remove(item);

			stageBuild.reloadStage(curStage);
			for (item in stageBuild.stageItems)
				add(item);
		}

		camZoom = stageBuild.camZoom;
		if (stageBuild.gfVersion != "")
			gf.setActive(stageBuild.gfVersion);
		else
			gf.setActive(META.gf);

		dad.setPos(stageBuild.dadPos.x, stageBuild.dadPos.y);
		bf.setPos(stageBuild.bfPos.x, stageBuild.bfPos.y);
		gf.setPos(stageBuild.gfPos.x, stageBuild.gfPos.y);

		dad.setScrollFactor(stageBuild.dadScrollFactor.x, stageBuild.dadScrollFactor.y);
		bf.setScrollFactor(stageBuild.bfScrollFactor.x, stageBuild.bfScrollFactor.y);
		gf.setScrollFactor(stageBuild.gfScrollFactor.x, stageBuild.gfScrollFactor.y);
	}

	override function draw()
	{
		members.sort(ZIndex.sortAscending);
		super.draw();
	}

	var cameraSpeed:Float = 1.0;

	override function update(elapsed:Float)
	{
		callScript("update", [elapsed]);
		super.update(elapsed);

		if (botplay && startedSong)
			validScore = false;

		function followLerp():Float
			return FlxMath.bound((cameraSpeed * 5 * elapsed), 0, 1);

		updateDisplace();
		camGame.moveCam([
			camFollow.get(followLerp()),
			camDisplace.get(followLerp()),
			{x: -FlxG.width / 2, y: -FlxG.height / 2}
		]);

		camGame.zoom = FlxMath.lerp(camGame.zoom, camZoom, elapsed * 12);
		for (cam in [camHUD, camStrum])
			cam.zoom = FlxMath.lerp(cam.zoom, defaultHudZoom, elapsed * 12);

		health = FlxMath.bound(health, 0, 2);
		if (Controls.justPressed(RESET) || health <= 0)
		{
			MusicBeat.skip = true;
			MusicBeat.switchState(new states.PlayState());
		}

		if (FlxG.keys.justPressed.SEVEN)
			MusicBeat.switchState(new ChartingState(SONG));

		if (FlxG.keys.justPressed.ONE)
			changeStage(stageBuild.curStage == "stage" ? "school" : "stage");

		if (FlxG.keys.justPressed.F9)
			audio.speed = 10;
		if (FlxG.keys.justReleased.F9)
			audio.speed = defaultSongSpeed;

		if (canPause)
		{
			if (Controls.justPressed(PAUSE) #if TOUCH_CONTROLS || pauseButton.justPressed #end)
			{
				pauseSong();
			}
		}

		if (!paused)
		{
			Conductor.songPos += elapsed * 1000 * audio.speed;
			FlxG.animationTimeScale = audio.speed;
			if (!startedSong)
			{
				for (snd in countdownSfx)
					if (snd.playing)
						snd.pitch = audio.speed;
			}
		}

		if (curEventCount < spawnEvents.length)
		{
			for (i in 0...spawnEvents.length)
			{
				if (i < curEventCount)
					continue;

				var eventData = spawnEvents[curEventCount];
				if ((eventData.stepTime - curStepFloat) <= 0)
				{
					playEvent(eventData.name, eventData.data);
					curEventCount++;
				}
			}
		}

		playField.updateNotes(curStepFloat);
		callScript("updatePost", [elapsed]);
	}

	function preloadEvent(name:String, data:Array<Dynamic>)
	{
		switch (name)
		{
			case 'Change Character':
				strToChar(data[0]).addChar(data[1]);
			case 'Change Stage':
				stageBuild.reloadStage(data[0]);
				if (stageBuild.gfVersion != "")
					gf.addChar(stageBuild.gfVersion, false);
		}
	}

	function playEvent(name:String, data:Array<Dynamic>)
	{
		callScript("playEvent", [name, data]);
		switch (name)
		{
			case "Change Stage":
				changeStage(data[0]);
			case "Camera Focus":
				followCamera(data[0]);
		}
	}

	public function followCamera(charStr:String = "", ?offset:DoidoPoint)
	{
		offset = MathUtil.addPoint(offset ?? {x: 0, y: 0}, switch (charStr)
		{
			case "dad": stageBuild.dadCam;
			case "bf": stageBuild.bfCam;
			case "gf": stageBuild.gfCam;
			default: {x: 0, y: 0};
		});

		var char = strToChar(charStr);
		curFocus = charStr;
		camFollow.point = {x: 0, y: 0};

		if (char != null)
		{
			var playerMult:Int = (char.isPlayer ? -1 : 1);

			camFollow.point = {
				x: char.getMidpoint().x + ((200 + char.cameraOffset.x) * playerMult),
				y: char.getMidpoint().y - 20 + char.cameraOffset.y
			};
		}

		camFollow.point = MathUtil.addPoint(camFollow.point, offset);
	}

	function updateDisplace()
	{
		if (maxDisplace == {x: 0, y: 0})
			return;
		switch (strToChar(curFocus).curAnimName)
		{
			case 'singLEFT':
				camDisplace.point = {x: -maxDisplace.x, y: 0};
			case 'singRIGHT':
				camDisplace.point = {x: maxDisplace.x, y: 0};
			case 'singUP':
				camDisplace.point = {x: 0, y: -maxDisplace.y};
			case 'singDOWN':
				camDisplace.point = {x: 0, y: maxDisplace.y};
			default:
				camDisplace.point = {x: 0, y: 0};
		}
	}

	function strToChar(str:String, nullable:Bool = false):CharGroup
	{
		return switch (str)
		{
			default: nullable ? null : dad;
			case 'dad': dad;
			case 'bf' | 'boyfriend': bf;
			case 'gf' | 'girlfriend': gf;
		}
	}

	public function startSong()
	{
		audio.play();
		startedSong = true;
	}

	public function pauseSong()
	{
		paused = true;
		for (snd in FlxG.sound.list)
		{
			snd.pause();
		}
		audio.pause();
		audio.speed = 0.0;
		MusicBeat.activateTimers(false);
		openSubState(new PauseSubState());
	}

	public function unpauseSong()
	{
		paused = false;
		for (snd in FlxG.sound.list)
		{
			snd.resume();
		}
		MusicBeat.activateTimers(true);
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

	public function updateOption(optionName:String)
	{
		switch(optionName)
		{
			case "Downscroll":
				downscroll = Save.data.downscroll;
				//hudClass.play.downscroll = downscroll;
				hudClass.updatePositions();

				for(strumline in playField.strumlines)
				{
					strumline.downscroll = downscroll;
					strumline.recalculateY();
				}
				playField.updateNotes();
				
			case "Middlescroll":
				middlescroll = Save.data.middlescroll;
				//hudClass.play.middlescroll = middlescroll;
				hudClass.updatePositions();

				var strumPos = playField.getStrumlinePos(middlescroll);
				var _i:Int = 0;
				for(strumline in playField.strumlines)
				{
					strumline.x = (FlxG.width / 2) + strumPos[_i % strumPos.length];
					strumline.recalculateX();
					_i++;
				}
				playField.updateNotes();
		}
	}

	public function beatCamera(gameZoom:Float, hudZoom:Float)
	{
		camGame.zoom *= gameZoom;
		for (cam in [camHUD, camStrum])
			cam.zoom *= hudZoom;
	}

	var endedSong:Bool = false;

	public function endSong()
	{
		if (endedSong)
			return;
		endedSong = true;
		canPause = false;

		if (validScore)
		{
			Highscore.addScore(CHART.song.toLowerCase() /* + '-' + songDiff*/, {
				score: Timings.score,
				accuracy: Timings.accuracy,
				misses: Timings.misses,
			});
		}

		MusicBeat.switchState(new states.DebugMenu());
	}

	override function stepHit()
	{
		super.stepHit();
		callScript("stepHit", [curStep]);
		playField.stepHit(curStep);

		if (startedSong && !endedSong)
		{
			if (Conductor.songPos < audio.length - 2000)
				audio.sync();
			else if (Conductor.songPos >= audio.length)
				endSong();
		}

		hudClass.stepHit(curStep);
	}

	override function beatHit()
	{
		super.beatHit();
		callScript("beatHit", [curBeat]);

		if (curBeat < -4)
			return;

		// COUNTDOWN AND SONG START
		if (curBeat <= 0)
		{
			// start song
			if (curBeat == 0)
				startSong();
			else if (curBeat + 4 >= 0) // countdown
			{
				// trace(curBeat + 4);
				countdownSfx[curBeat + 4].play();
			}
		}

		for (char in characters)
		{
			if ((curBeat % 2 == 0 || char.quickDancer) && (char.singStep <= 0))
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

		if (curBeat % 4 == 0)
			beatCamera(1.05, 1.02);

		hudClass.beatHit(curBeat);
	}

	public function callScript(fun:String, ?args:Array<Dynamic>)
	{
		for (script in loadedScripts)
		{
			@:privateAccess {
				var ny:Dynamic = script.interp.variables.get(fun);
				try
				{
					if (ny != null && Reflect.isFunction(ny))
						script.call(fun, args);
				}
				catch (e)
				{
					Logs.print('error parsing script: ' + e, ERROR);
				}
			}
		}
		stageBuild.callScript(fun, args);
	}

	public function setScript(name:String, value:Dynamic, allowOverride:Bool = true)
	{
		for (script in loadedScripts)
			script.set(name, value, allowOverride);
	}

	public var player1(get, never):String;

	public function get_player1():String
		return bf.curChar;

	public var player2(get, never):String;

	public function get_player2():String
		return dad.curChar;

	public var songLength(get, never):Float;

	public function get_songLength():Float
		return audio.length;

	public var botplay(default, set):Bool;

	public function set_botplay(b:Bool):Bool
	{
		botplay = b;
		playField.bfStrumline.botplay = b;
		return botplay;
	}

	public static var CHART(get, never):DoidoChart;

	public static function get_CHART():DoidoChart
		return SONG.CHART;

	public static var EVENTS(get, never):DoidoEvents;

	public static function get_EVENTS():DoidoEvents
		return SONG.EVENTS;

	public static var META(get, never):DoidoMeta;

	public static function get_META():DoidoMeta
		return SONG.META;
}

interface Playable
{
	var health:Float;
	var downscroll:Bool;
	var middlescroll:Bool;
	var validScore:Bool;
	var botplay(default, set):Bool;
	var songLength(get, never):Float;
	var player1(get, never):String;
	var player2(get, never):String;
}
