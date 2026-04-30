package subStates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import backend.Paths;
import objects.menu.Alphabet;
import states.PlayState;

class PauseSubState extends MusicBeatSubState
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var menuItems:Array<String> = ['Resume', 'Restart Song', 'Exit to Menu'];
	var curSelected:Int = 0;

	public function new()
	{
		super();
		
		// Fundo escuro simples
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		for (i in 0...menuItems.length)
		{
			var item:Alphabet = new Alphabet(0, 0, menuItems[i], true);
			item.ID = i;
			// Forçando o centro para não ficarem "fora do menu"
			item.screenCenter(X);
			item.y = (i * 120) + 250;
			grpMenuShit.add(item);
		}

		changeSelection();
		
		// Pausa a música para não dar conflito
		if (FlxG.sound.music != null) FlxG.sound.music.pause();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Controles de Teclado
		if (FlxG.keys.justPressed.UP) changeSelection(-1);
		if (FlxG.keys.justPressed.DOWN) changeSelection(1);

		// Suporte a Toque e Tecla de Voltar do Android
		var touchConfirm:Bool = false;
		if (FlxG.touches.justStarted().length > 0) touchConfirm = true;

		if (FlxG.keys.justPressed.ENTER || FlxG.android.justPressed.BACK || touchConfirm)
		{
			var daSelected:String = menuItems[curSelected].toLowerCase();

			switch (daSelected)
			{
				case "resume":
					fecharMenu();
				case "restart song":
					MusicBeatState.resetState();
				case "exit to menu":
					PlayState.seenCutscene = false;
					PlayState.deathCounter = 0;
					MusicBeatState.switchState(new states.menu.MainMenuState());
			}
		}
	}

	function fecharMenu() {
		if (FlxG.sound.music != null) FlxG.sound.music.resume(); // RESOLVE O CONGELAMENTO
		close();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxG.math.FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);
		if(change != 0) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		for (item in grpMenuShit.members) {
			item.alpha = 0.6;
			if (item.ID == curSelected) {
				item.alpha = 1;
				item.screenCenter(X); // Mantém centralizado mesmo selecionado
			}
		}
	}
			}
			
