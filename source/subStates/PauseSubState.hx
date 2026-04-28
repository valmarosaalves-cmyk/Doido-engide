package substates;

import backend.Controls;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
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
	var p_backgroundDecor:FlxSprite; // Sua imagem "me bg"
	var p_opponent:FlxSprite;
	var songTxt:FlxText;

	public function new()
	{
		super();

		// 1. Fundo escurecido atrás de tudo
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		// 2. SUA IMAGEM DE FUNDO "me bg" (Adicionada primeiro para ficar atrás)
		p_backgroundDecor = new FlxSprite(FlxG.width - 500, 200);
		p_backgroundDecor.loadGraphic(Paths.image('mebg')); // Carrega o PNG "me bg"
		p_backgroundDecor.antialiasing = true;
		// Ajuste a escala se a imagem for muito grande ou pequena
		// p_backgroundDecor.scale.set(0.8, 0.8); 
		// p_backgroundDecor.updateHitbox();
		add(p_backgroundDecor);
		
		// Inicia o movimento fluido em escada para a imagem
		moveBackgroundDecor();

		// 3. JANELA ESTILO PC (Lado Esquerdo, na frente do "me bg")
		p_window = new FlxSprite(80, 100).makeGraphic(450, 550, 0xFFC0C0C0); // Cinza clássico Windows
		add(p_window);

		// Barra de título da janela
		var bar = new FlxSprite(80, 100).makeGraphic(450, 35, 0xFF000080); // Azul clássico
		add(bar);
		
		var winTitle = new FlxText(90, 105, 0, "OPÇÕES DO SISTEMA", 16);
		winTitle.setFormat(null, 16, FlxColor.WHITE, LEFT);
		add(winTitle);

		// 4. ITENS DO MENU (Fonte padrão)
		grpMenu = new FlxTypedGroup<FlxText>();
		add(grpMenu);

		for (i in 0...menuItems.length)
		{
			var text:FlxText = new FlxText(120, 200 + (i * 90), 0, menuItems[i], 45);
			text.setFormat(null, 45, FlxColor.BLACK, LEFT);
			text.ID = i;
			grpMenu.add(text);
		}

		// 5. NOME DA MÚSICA (Canto Superior Direito, com sua fonte)
		// Usando sua fonte pixel-game.regular.otf
		songTxt = new FlxText(FlxG.width - 600, 40, 550, PlayState.SONG.song.toUpperCase(), 42);
		songTxt.setFormat(Paths.font("pixel-game.regular.otf"), 42, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		songTxt.antialiasing = false; // Fontes pixel ficam melhores assim
		add(songTxt);

		// 6. PERSONAGEM OPONENTE (Canto inferior direito, na frente do "me bg")
		p_opponent = new FlxSprite(FlxG.width - 400, FlxG.height - 450);
		// Tenta pegar o personagem que o PlayState está usando como "Dad" (Oponente)
		p_opponent.loadGraphic(Paths.image('characters/' + PlayState.instance.dad.curCharacter)); 
		p_opponent.antialiasing = true;
		p_opponent.scale.set(0.7, 0.7);
		p_opponent.updateHitbox();
		add(p_opponent);

		changeSelection();
	}

	// Lógica do movimento fluido em escada para a imagem PNG
	function moveBackgroundDecor()
	{
		// Sobe 80px e vai 80px pro lado (Ajuste os valores para o tamanho da sua imagem)
		FlxTween.tween(p_backgroundDecor, {x: p_backgroundDecor.x + 80, y: p_backgroundDecor.y - 80}, 0.8, {
			ease: FlxEase.quartInOut,
			onComplete: function(twn:FlxTween) {
				// Se sumir da tela ou subir muito, reseta posição para reiniciar a "escada"
				// Ajuste este valor (100) dependendo de onde você quer que ela reapareça
				if(p_backgroundDecor.y < 100) {
					p_backgroundDecor.setPosition(FlxG.width - 500, 450);
				}
				moveBackgroundDecor(); // Repete o ciclo
			}
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

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
					FlxG.switchState(new OptionsState()); // Abre as configurações
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
				item.color = 0xFF0000FF; // Fica azul quando selecionado (estilo link)
			}
		}
		
		if(change != 0) FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}
