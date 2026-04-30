package states.menu;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath; // Import correto para o erro do print
import backend.Paths;
import objects.menu.Alphabet;

class AchievementsMenuState extends MusicBeatState
{
	var achievementList:Array<String> = ["friday_night_felon", "she_call_me_pico", "debugger"];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<FlxSprite> = [];
	private static var curSelected:Int = 0;

	override function create() {
		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('Achievements/menuBGBlue'));
		menuBG.antialiasing = true;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		add(menuBG);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...achievementList.length) {
			// Removi isMenuItem e targetY para evitar erro de campo inexistente
			var optionText:Alphabet = new Alphabet(0, 0, achievementList[i].replace('_', ' '), true);
			optionText.ID = i;
			optionText.screenCenter(X);
			optionText.y = (i * 120) + 200;
			grpOptions.add(optionText);

			var icon:FlxSprite = new FlxSprite();
			icon.loadGraphic(Paths.image('Achievements/' + achievementList[i]));
			icon.ID = i;
			iconArray.push(icon);
			add(icon);
		}
		
		changeSelection();
		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.keys.justPressed.UP) changeSelection(-1);
		if (FlxG.keys.justPressed.DOWN) changeSelection(1);
		
		if (FlxG.keys.justPressed.ESCAPE) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			// Usando FlxG.switchState que funciona em quase todas as versões
			FlxG.switchState(new states.menu.MainMenuState());
		}

		// Toque na tela para Android
		if (FlxG.touches.justStarted().length > 0) {
			var touch = FlxG.touches.justStarted()[0];
			if (touch.y < FlxG.height / 2) changeSelection(-1);
			else changeSelection(1);
		}

		for (i in 0...grpOptions.members.length) {
			var item = grpOptions.members[i];
			item.screenCenter(X);
			// Usando FlxMath direto para evitar o erro do print
			item.y = FlxMath.lerp(item.y, (FlxG.height / 2) + ((i - curSelected) * 140), 0.15);
			
			if (iconArray[i] != null) {
				iconArray[i].y = item.y;
				iconArray[i].x = item.x - 110;
			}
		}
	}

	function changeSelection(change:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + change, 0, achievementList.length - 1);
		if(change != 0) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		for (i in 0...grpOptions.members.length) {
			grpOptions.members[i].alpha = (i == curSelected) ? 1 : 0.6;
			if(iconArray[i] != null) iconArray[i].alpha = (i == curSelected) ? 1 : 0.6;
		}
	}
}
