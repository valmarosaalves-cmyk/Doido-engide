package states.menu;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import objects.menu.Alphabet;

class AchievementsMenuState extends MusicBeatState
{
	var achievementList:Array<String> = ["friday_night_felon", "she_call_me_pico", "debugger"];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<FlxSprite> = [];
	private static var curSelected:Int = 0;
	private var descText:FlxText;

	override function create() {
		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('Achievements/menuBGBlue'));
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		add(menuBG);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...achievementList.length) {
			var optionText:Alphabet = new Alphabet(0, 0, achievementList[i].replace('_', ' '), true);
			optionText.ID = i;
			grpOptions.add(optionText);

			var icon:FlxSprite = new FlxSprite();
			icon.loadGraphic(Paths.image('Achievements/' + achievementList[i]));
			icon.ID = i;
			iconArray.push(icon);
			add(icon);
		}

		descText = new FlxText(150, 600, 980, "Conquistas", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.screenCenter(X);
		add(descText);
		
		changeSelection();
		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		// SOLUÇÃO: Usando o teclado puro do HaxeFlixel para não dar erro na engine
		if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W) changeSelection(-1);
		if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S) changeSelection(1);
		
		if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE) {
			FlxG.sound.play(Paths.sound('menu/cancelMenu'));
			Main.switchState(new MainMenuState());
		}

		// Adicionei um suporte básico de toque para você conseguir sair no Android
		for (touch in FlxG.touches.list) {
			if (touch.justPressed) {
				if (touch.y < FlxG.height / 3) changeSelection(-1);
				else if (touch.y > (FlxG.height / 3) * 2) changeSelection(1);
				else {
					FlxG.sound.play(Paths.sound('menu/cancelMenu'));
					Main.switchState(new MainMenuState());
				}
			}
		}

		for (i in 0...grpOptions.members.length) {
			var item = grpOptions.members[i];
			item.screenCenter(X);
			item.y = FlxG.height / 2 + (i - curSelected) * 120;
			if (iconArray[i] != null) {
				iconArray[i].y = item.y;
				iconArray[i].x = item.x - 110;
			}
		}
	}

	function changeSelection(change:Int = 0) {
		curSelected = flixel.math.FlxMath.wrap(curSelected + change, 0, achievementList.length - 1);
		for (i in 0...grpOptions.members.length) {
			grpOptions.members[i].alpha = (i == curSelected) ? 1 : 0.6;
			if(iconArray[i] != null) iconArray[i].alpha = (i == curSelected) ? 1 : 0.6;
		}
		if(change != 0) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
}
