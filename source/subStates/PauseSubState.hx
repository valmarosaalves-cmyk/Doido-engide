package substates;

import backend.Controls;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.math.FlxRect;
import states.PlayState;
import states.menu.MainMenuState;
import states.menu.OptionsState;
import backend.MusicBeatSubstate;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenu:FlxTypedGroup<FlxText>;
	var menuItems:Array<String> = ['RESUME', 'RESTART', 'CONFIGS', 'BACK'];
	var curSelected:Int = 0;

	var p_window:FlxSprite;
	var p_backgroundDecor:FlxSprite; 
	var p_opponent:FlxSprite;
	
	// Variáveis para o nome da música
	var songTxt:FlxText;
	var songContainer:FlxSprite;
	var textSpeed:Float = 100; // Velocidade do texto correndo

	public function new()
	{
		super();

		// 1. Fundo escurecido
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		// 2. IMAGEM "me bg" (Movimento Escada)
		p_backgroundDecor = new FlxSprite(FlxG.width - 500, 450);
		p_backgroundDecor.loadGraphic(Paths.image('me bg')); 
		p_backgroundDecor.antialiasing = true;
		add(p_backgroundDecor);
		moveBackgroundDecor();

		// 3. CAIXA DO NOME DA MÚSICA (Marquee)
		songContainer = new FlxSprite(FlxG.width - 500, 40).makeGraphic(450, 60, FlxColor.BLACK);
		songContainer.alpha = 0.8;
		add(songContainer);

		songTxt = new FlxText(songContainer.x, songContainer.y + 10, 0, PlayState.SONG.song.toUpperCase(), 35);
		songTxt.setFormat(Paths.font("pixel-game.regular.otf"), 35, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		songTxt.antialiasing = false;
		songTxt.clipRect = new FlxRect(0, 0, 450, 60); // Corta o texto se sair da caixa
		add(songTxt);

		// 4. JANELA ESTILO PC (Lado Esquerdo)
		p_window = new FlxSprite(80, 100).makeGraphic(450, 550, 0xFFC0C0C0); 
		add(p_window);

		var bar = new FlxSprite(80, 100).makeGraphic(450, 35, 0xFF000080); 
		add(bar);
		
		var winTitle = new FlxText(90, 105, 0, "OPÇÕES DO SISTEMA", 16);
		winTitle.setFormat(null, 16, FlxColor.WHITE, LEFT);
		add(winTitle);

		// 5. ITENS DO MENU
		grpMenu = new FlxTypedGroup<FlxText>();
		add(grpMenu);

		for (i in 0...menuItems.length)
		{
			var text:FlxText = new FlxText(120, 200 + (i * 90), 0, menuItems[i], 45);
			text.setFormat(null, 45, FlxColor.BLACK, LEFT);
			text.ID = i;
			grpMenu.add(text);
		}

		// 6. PERSONAGEM OPONENTE
		p_opponent = new FlxSprite(FlxG.width - 400, FlxG.height - 450);
		p_opponent.loadGraphic(Paths.image('characters/' + PlayState.instance.dad.curCharacter)); 
		p_opponent.antialiasing = true;
		p_opponent.scale.set(0.7, 0.7);
		p_opponent.updateHitbox();
		add(p_opponent);

		changeSelection();
	}

	function moveBackgroundDecor()
	{
		FlxTween.tween(p_backgroundDecor, {x: p_backgroundDecor.x + 80, y: p_backgroundDecor.y - 80}, 0.8, {
			ease: FlxEase.quartInOut,
			onComplete: function(twn:FlxTween) {
				if(p_backgroundDecor.y < 150) {
					p_backgroundDecor.setPosition(FlxG.width - 500, 450);
				}
				moveBackgroundDecor();
			}
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Lógica do texto passando (Marquee)
		if (songTxt.width > 450) {
			songTxt.x -= textSpeed * elapsed;
			if (songTxt.x < songContainer.x - songTxt.width) {
				songTxt.x = songContainer.x + 450;
			}
		} else {
			songTxt.x = songContainer.x + (songContainer.width / 2) - (songTxt.width / 2);
		}

		if (controls.UI_UP_P) changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);

		if (controls.ACCEPT)
		{
			var daChoice:String = menuItems[curSelected];
			switch (daChoice)
			{
				case "RESUME":
					close();
				case "RESTART":
					FlxG.resetState();
				case "CONFIGS":
					FlxG.switchState(new OptionsState());
				case "BACK":
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;
					FlxG.switchState(new MainMenuState());
			}
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;
		if (curSelected < 0) curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length) curSelected = 0;

		for (item in grpMenu.members)
		{
			item.alpha = 0.5;
			item.color = FlxColor.BLACK;
			if (item.ID == curSelected) {
				item.alpha = 1;
				item.color = 0xFF0000FF; 
			}
		}
		
		if(change != 0) FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}
