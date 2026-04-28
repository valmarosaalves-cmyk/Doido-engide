package subStates;

import backend.song.Conductor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.sound.FlxSound;
import objects.menu.Alphabet;
import objects.menu.AlphabetMenu;
import states.*;
import subStates.options.OptionsSubState;

class PauseSubState extends MusicBeatSubState
{
	var optionShit:Array<String> = [
		"resume",
		"restart song",
		"botplay",
		"options",
		"exit to menu",
	];
	
	var curSelected:Int = 0;
	
	var optionsGrp:FlxTypedGroup<AlphabetMenu>;
	var textsGrp:FlxTypedGroup<FlxText>;
	var bottomTxt:FlxText;

	var pauseSong:FlxSound;
	var onCountdown:Bool = false;
	var delayTween:FlxTween;
	var playstate:PlayState;

	// Novas variáveis para os seus PNGs
	var mebg:FlxSprite;
	var fpov:FlxSprite;

	public function new()
	{
		super();
		playstate = PlayState.instance;
		playstate.setScript("this", this);
		DiscordIO.changePresence("Paused - Restin' a bit");
		this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		// Fundo preto base
		var banana = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		add(banana);
		banana.alpha = 0;
		FlxTween.tween(banana, {alpha: 0.4}, 0.1);

		// 1. PNG mebg (Debaixo de tudo, movimento escadinha)
		mebg = new FlxSprite().loadGraphic(Paths.image('mebg'));
		mebg.antialiasing = true;
		mebg.screenCenter();
		add(mebg);

		// Movimento suave de escadinha (diagonal ida e volta)
		FlxTween.tween(mebg, {x: mebg.x + 30, y: mebg.y - 30}, 4, {
			ease: FlxEase.sineInOut, 
			type: PINGPONG
		});

		// 2. PNG fpov (No meio, acima do mebg)
		fpov = new FlxSprite().loadGraphic(Paths.image('fpov'));
		fpov.antialiasing = true;
		fpov.screenCenter();
		add(fpov);

		if(!PlayState.startedSong)
			optionShit.remove("options");

		optionsGrp = new FlxTypedGroup<AlphabetMenu>();
		add(optionsGrp);

		for(i in 0...optionShit.length)
		{
			var newItem = new AlphabetMenu(0, 0, optionShit[i], true);
			newItem.ID = i;
			newItem.focusY = i - curSelected;

			newItem.spaceX = 0; // Removido deslocamento para manter no centro
			newItem.spaceY = 150; 

			newItem.updatePos();
			newItem.screenCenter(X); // Força as letras no meio
			optionsGrp.add(newItem);
		}
		
		textsGrp = new FlxTypedGroup<FlxText>();
		add(textsGrp);
		
		var textArray:Array<String> = [
			PlayState.SONG.song,
			PlayState.songDiff,
			'BLUEBALLED: ' + PlayState.blueballed,
		];
		for(i in 0...textArray.length)
		{
			if(textArray[i] == "") continue;
		
			var text = new FlxText(0,0,0,textArray[i].toUpperCase());
			text.setFormat(Main.gFont, 36, 0xFFFFFFFF, RIGHT);
			text.setPosition(FlxG.width - text.width - 10, 10 + 40 * i);
			textsGrp.add(text);
			
			text.alpha = 0.00001;
			text.y -= 20;
			FlxTween.tween(text, {y: text.y + 20, alpha: 1}, 0.4, {ease: FlxEase.quadOut, startDelay: 0.2 + 0.18 * i});
		}
		
		bottomTxt = new FlxText(0,0,0,"");
		bottomTxt.setFormat(Main.gFont, 36, 0xFFFFFFFF, RIGHT);
		add(bottomTxt);

		pauseSong = new FlxSound();
		if(Conductor.songPos > 0)
		{
			@:privateAccess
			pauseSong.loadEmbedded(playstate.inst._sound, true, false);
			pauseSong.play(Conductor.songPos);
			pauseSong.pitch = 0.9;
			pauseSong.volume = 0;
			FlxTween.tween(pauseSong, {volume: 0.6}, 3, {startDelay: 1});
		}
		FlxG.sound.list.add(pauseSong);

		changeSelection();
	}

	function closePause()
	{
		pauseSong.stop();
		if(SaveData.data.get('Delay on Unpause') && PlayState.startedSong)
		{
			playstate.songSpeed = 0.0;
			if(delayTween != null) delayTween.cancel();
			delayTween = FlxTween.tween(playstate, {songSpeed: 1.0}, Conductor.crochet * 1 / 1000, {
				ease: FlxEase.sineIn
			});
		}
		else
			playstate.songSpeed = 1.0;

		close();
	}

	override function close()
	{
		pauseSong.stop();
		PlayState.paused = false;
		playstate.updateOption('Song Offset');
		playstate.callScript('onUnpause');
		playstate.setScript("this", playstate);
		super.close();
	}

	var inputDelay:Float = 0.05;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Manter as letras centralizadas durante o update
		optionsGrp.forEach(function(item:AlphabetMenu) {
			item.screenCenter(X);
		});

		bottomTxt.text = "";
		if(PlayState.botplay)
			bottomTxt.text += "BOTPLAY";
		
		bottomTxt.x = FlxG.width - bottomTxt.width - 10;
		bottomTxt.y = FlxG.height- bottomTxt.height- 10;

		if(inputDelay > 0)
		{
			inputDelay -= elapsed;
			return;
		}

		if(!onCountdown)
		{
			if(!pauseSong.playing && Conductor.songPos >= 0)
				pauseSong.play(false, pauseSong.time);

			if(Controls.justPressed(UI_UP))
				changeSelection(-1);
			if(Controls.justPressed(UI_DOWN))
				changeSelection(1);

			if(Controls.justPressed(ACCEPT))
			{
				switch(optionShit[curSelected])
				{
					case "resume":
						closePause();
					case "restart song":
						Main.skipStuff();
						Main.resetState();
					case "botplay":
						FlxG.sound.play(Paths.sound("menu/cancelMenu"));
						PlayState.botplay = !PlayState.botplay;
					case "options":
						persistentDraw = false;
						pauseSong.pause();
						this.openSubState(new OptionsSubState(playstate));
					case "exit to menu":
						persistentDraw = true;
						PlayState.sendToMenu();
					default:
						FlxG.sound.play(Paths.sound("menu/cancelMenu"));
				}
			}

			if(Controls.justPressed(BACK))
				closePause();
		}
		else
		{
			for(item in optionsGrp)
				item.alpha = FlxMath.lerp(item.alpha, 0, elapsed * 12);
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		curSelected = FlxMath.wrap(curSelected, 0, optionShit.length - 1);

		for(item in optionsGrp)
		{
			item.focusY = item.ID - curSelected;
			item.alpha = 0.4;
			if(item.ID == curSelected)
				item.alpha = 1;
		}

		if(change != 0)
			FlxG.sound.play(Paths.sound("menu/scrollMenu"));
	}
}
