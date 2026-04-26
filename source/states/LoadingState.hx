package states;

import backend.utils.DialogueUtil;
import backend.song.ChartLoader;
import backend.song.SongData.SwagSong;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import objects.*;
import objects.hud.*;
import objects.note.*;
import objects.dialogue.Dialogue;

#if PRELOAD_SONG
import sys.thread.Mutex;
import sys.thread.Thread;
#end

class LoadingState extends MusicBeatState
{
	var threadActive:Bool = true;

	#if PRELOAD_SONG
	var mutex:Mutex;
	#end

	var behind:FlxGroup;
	var bg:FlxSprite;
	
	var loadBar:FlxSprite;
	var loadPercent:Float = 0;
	
	// Variável para controlar o tempo da onda
	var waveTimer:Float = 0;
	// Posição Y original da barra para ela saber onde voltar
	var barOriginalY:Float = 0;
	
	function addBehind(item:FlxBasic)
	{
		behind.add(item);
		behind.remove(item);
	}
	
	override function create()
	{
		super.create();
		behind = new FlxGroup();
		add(behind);
		
		var color = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFCAFF4D);
		color.screenCenter();
		add(color);
		
		bg = new FlxSprite().loadGraphic(Paths.image('funkay'));
		bg.scale.set(0.8,0.8);
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);
		
		loadBar = new FlxSprite().makeGraphic(FlxG.width - 16, 20 - 8, 0xFFFF16D2);
		barOriginalY = FlxG.height - loadBar.height - 20; // Ajustado um pouco para cima para a onda ter espaço
		loadBar.y = barOriginalY;
		changeBarSize(0);
		add(loadBar);

		#if PRELOAD_SONG
		mutex = new Mutex();
		#end
		
		var oldAnti:Bool = FlxSprite.defaultAntialiasing;
		FlxSprite.defaultAntialiasing = false;
		
		PlayState.resetStatics();
		var assetModifier = PlayState.assetModifier;
		var SONG = PlayState.SONG;
		var unspawnEvents = ChartLoader.getEvents(PlayState.EVENTS);

		#if PRELOAD_SONG
		var preloadThread = Thread.create(function()
		{
			mutex.acquire();
		#end
			Paths.preloadPlayStuff();
			Rating.preload(assetModifier);
			Paths.preloadGraphic('hud/base/healthBar');
			
			var stageBuild = new Stage();
			stageBuild.reloadStageFromSong(SONG.song, SONG.gfVersion);
			addBehind(stageBuild);

			var playerChars:Array<String> = [SONG.player1];
			var charList:Array<String> = [SONG.player1, SONG.player2, stageBuild.gfVersion];
			for(daEvent in unspawnEvents)
			{
				switch(daEvent.eventName)
				{
					case 'Change Character':
						charList.push(daEvent.value2);
						switch(daEvent.value1)
						{
							case 'bf'|'boyfriend': playerChars.push(daEvent.value2);
						}
					case 'Change Stage':
						stageBuild.reloadStage(daEvent.value1);
						addBehind(stageBuild);

						if(!charList.contains(stageBuild.gfVersion))
							charList.push(stageBuild.gfVersion);
				}
			}
			loadPercent = 0.2;
			for(i in charList)
			{
				var char = new Character(i, playerChars.contains(i));
				addBehind(char);

				if(char.isPlayer && !charList.contains(char.deathChar))
				{
					var dead = new Character(char.deathChar, true);
					addBehind(dead);
				}
				
				if(i != stageBuild.gfVersion)
				{
					var icon = new HealthIcon();
					icon.setIcon(i, false);
					addBehind(icon);
				}
				loadPercent += (0.6 - 0.2) / charList.length;
			}
			
			loadPercent = 0.6;
			
			var songDiff:String = PlayState.songDiff;
			Paths.preloadSound(Paths.songPath(SONG.song, 'Inst', songDiff));
			if(SONG.needsVoices)
			{
				Paths.preloadSound(Paths.songPath(SONG.song, 'Voices', songDiff, '-player'));
				var oppPath:String = Paths.songPath(SONG.song, 'Voices', songDiff, '-opp');
				if(oppPath.endsWith('-opp'))
					Paths.preloadSound(oppPath);
			}

			loadPercent = 0.75;

			var dialData:DialogueData = DialogueUtil.loadDialogue(SONG.song, songDiff);
			if(dialData.pages.length > 0) {
				var dial = new Dialogue();
				dial.load(dialData, true);
				addBehind(dial);
			}

			loadPercent = 0.85;
			loadPercent = 0.95;
			loadPercent = 1.0;
			threadActive = false;
			FlxSprite.defaultAntialiasing = oldAnti;
		#if PRELOAD_SONG
			mutex.release();
		});
		#end
	}
	
	var byeLol:Bool = false;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Faz a onda acontecer!
		waveTimer += elapsed * 5; // Muda esse 5 para a onda ser mais rápida ou lenta
		loadBar.y = barOriginalY + (Math.sin(waveTimer) * 15); // O 15 é a altura da onda

		if(!threadActive && !byeLol && loadBar.scale.x >= 0.98)
		{
			byeLol = true;
			changeBarSize(1);
			Main.skipClearMemory = true;
			Main.switchState(new PlayState());
		}
		
		if(Controls.justPressed(ACCEPT))
		{
			bg.scale.x += 0.04;
			bg.scale.y += 0.04;
		}
		
		var bgCalc = FlxMath.lerp(bg.scale.x, 0.75, elapsed * 6);
		bg.scale.set(bgCalc, bgCalc);
		bg.updateHitbox();
		bg.screenCenter();
		
		changeBarSize(FlxMath.lerp(loadBar.scale.x, loadPercent, elapsed * 6));
	}
	
	function changeBarSize(newSize:Float)
	{
		loadBar.scale.x = newSize;
		loadBar.updateHitbox();
		loadBar.screenCenter(X);
	}
	}

