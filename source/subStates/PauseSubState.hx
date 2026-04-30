package substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxRect;
import flixel.group.FlxGroup.FlxTypedGroup;

// Caminhos oficiais da versão mais recente (1.0+)
import backend.MusicBeatSubstate;
import backend.Paths;
import backend.Controls;
import states.PlayState;
import states.MainMenuState;

class PauseSubState extends MusicBeatSubstate
{
	var menuItems:Array<String> = ['Resume', 'Restart Song', 'Exit to Menu'];
	var grpMenuShit:FlxTypedGroup<FlxText>;
	var curSelected:Int = 0;

	var bgBox:FlxSprite;
	var topRect:FlxSprite;
	var songText:FlxText;

	public function new()
	{
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		bg.scrollFactor.set();
		add(bg);

		// Menu Centralizado
		bgBox = new FlxSprite().makeGraphic(400, 500, FlxColor.BLACK);
		bgBox.alpha = 0.8;
		bgBox.screenCenter();
		bgBox.scrollFactor.set();
		add(bgBox);

		// Retângulo do Topo (Rádio)
		topRect = new FlxSprite(bgBox.x + 20, bgBox.y + 20).makeGraphic(360, 50, 0xFF222222);
		topRect.scrollFactor.set();
		add(topRect);

		// Texto da Música
		var name:String = "Tocando: " + PlayState.SONG.song + "    ";
		songText = new FlxText(topRect.x + 10, topRect.y + 12, 0, name, 24);
		songText.setFormat(Paths.font("pixel-game.regular.otf"), 24, FlxColor.WHITE, LEFT);
		songText.scrollFactor.set();
		
		// ClipRect para o texto não vazar
		songText.clipRect = new FlxRect(0, 0, topRect.width, topRect.height);
		add(songText);

		grpMenuShit = new FlxTypedGroup<FlxText>();
		add(grpMenuShit);

		for (i in 0...menuItems.length)
		{
			var item:FlxText = new FlxText(0, bgBox.y + 160 + (i * 90), 0, menuItems[i], 32);
			item.setFormat(Paths.font("pixel-game.regular.otf"), 32, FlxColor.WHITE, CENTER);
			item.screenCenter(X);
			item.ID = i;
			item.scrollFactor.set();
			grpMenuShit.add(item);
		}

		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Efeito de letreiro correndo
		songText.x -= elapsed * 100;
		if (songText.x < topRect.x - songText.width) {
			songText.x = topRect.x + topRect.width;
		}

		// Ajuste da máscara de corte
		songText.clipRect = new FlxRect(topRect.x - songText.x, 0, topRect.width, topRect.height);

		if (controls.UI_UP_P) changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);

		if (controls.ACCEPT)
		{
			var daChoice:String = menuItems[curSelected];
			switch (daChoice)
			{
				case 'Resume':
					close();
				case 'Restart Song':
					FlxG.resetState();
				case 'Exit to Menu':
					PlayState.deathCounter = 0;
					MusicBeatState.switchState(new MainMenuState());
			}
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;
		if (curSelected < 0) curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length) curSelected = 0;

		grpMenuShit.forEach(function(txt:FlxText) {
			txt.color = (txt.ID == curSelected) ? FlxColor.YELLOW : FlxColor.WHITE;
			txt.alpha = (txt.ID == curSelected) ? 1 : 0.6;
		});
	}
			}
			
