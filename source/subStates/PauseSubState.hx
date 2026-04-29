package subStates;

import backend.song.Conductor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.sound.FlxSound;
import objects.menu.AlphabetMenu;
import states.*;

class PauseSubState extends MusicBeatSubState
{
	var optionShit:Array<String> = ["resume", "restart song", "botplay", "options", "exit to menu"];
	var curSelected:Int = 0;
	
	var optionsGrp:FlxTypedGroup<AlphabetMenu>;
	var menuBox:FlxSprite;
	var nameBox:FlxSprite;
	var songNameTxt:FlxText;
	var mebg:FlxSprite;
	
	var pauseSong:FlxSound;
	var playstate:PlayState;

	public function new()
	{
		super();
		playstate = PlayState.instance;
		this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		// 1. Fundo MEBG (atrás de tudo)
		mebg = new FlxSprite().loadGraphic(Paths.image('mebg'));
		mebg.antialiasing = true;
		mebg.scale.set(1.4, 1.4);
		add(mebg);

		// Movimento escada infinito
		FlxTween.tween(mebg, {x: mebg.x + 150, y: mebg.y - 150}, 2, {type: LOOPING, ease: FlxEase.linear});

		// 2. Blocos de UI
		menuBox = new FlxSprite().makeGraphic(420, 550, 0xAA000000);
		menuBox.screenCenter();
		add(menuBox);

		nameBox = new FlxSprite(menuBox.x + 35, menuBox.y + 30).makeGraphic(350, 60, 0xFF000000);
		add(nameBox);

		// 3. Nome da Música (Letreiro Rolante)
		var displaySong = PlayState.SONG.song.toUpperCase();
		songNameTxt = new FlxText(0, nameBox.y + 12, 0, displaySong);
		songNameTxt.setFormat("assets/fonts/pixel-game.regular.otf", 32, 0xFFFFFFFF, LEFT);
		add(songNameTxt);

		// Máscara para o texto não vazar do nameBox
		songNameTxt.clipRect = new FlxRect(0, 0, nameBox.width, nameBox.height);
		
		// Inicia fora à direita e corre para a esquerda
		songNameTxt.x = nameBox.x + nameBox.width;
		FlxTween.tween(songNameTxt, {x: nameBox.x - songNameTxt.width}, 5, {type: LOOPING});

		// 4. Opções do Menu
		optionsGrp = new FlxTypedGroup<AlphabetMenu>();
		add(optionsGrp);

		for(i in 0...optionShit.length)
		{
			var newItem = new AlphabetMenu(0, 0, optionShit[i], true);
			newItem.ID = i;
			newItem.scale.set(0.55, 0.55); // Pequeno para caber
			newItem.updateHitbox();
			newItem.y = menuBox.y + 130 + (i * 75);
			newItem.screenCenter(X);
			optionsGrp.add(newItem);
		}

		// IMPORTANTE: Suporte para Mobile (Não apagar)
		#if TOUCH_CONTROLS
		createPad("up-down-back", "accept");
		addPad();
		#end

		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Atualiza a máscara do texto enquanto ele anda
		if (songNameTxt.clipRect != null) {
			songNameTxt.clipRect.x = nameBox.x - songNameTxt.x;
			songNameTxt.clipRect = songNameTxt.clipRect;
		}

		if(Controls.justPressed(UI_UP)) changeSelection(-1);
		if(Controls.justPressed(UI_DOWN)) changeSelection(1);
		if(Controls.justPressed(BACK)) close();

		if(Controls.justPressed(ACCEPT))
		{
			switch(optionShit[curSelected])
			{
				case "resume": close();
				case "restart song": Main.resetState();
				case "exit to menu": PlayState.sendToMenu();
			}
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		if(change != 0) FlxG.sound.play(Paths.sound("menu/scrollMenu"));

		for(item in optionsGrp)
		{
			item.alpha = 0.5;
			if(item.ID == curSelected) item.alpha = 1;
		}
	}
			}
			
