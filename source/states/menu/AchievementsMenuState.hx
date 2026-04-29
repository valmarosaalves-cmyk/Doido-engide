package states.menu;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import objects.menu.Alphabet;
import states.menu.MainMenuState;

class AchievementsMenuState extends MusicBeatState
{
	// Nomes padrão da Psych Engine (Exemplos)
	var achievementList:Array<String> = [
		"friday_night_felon",
		"she_call_me_pico",
		"debugger"
	];
	
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<FlxSprite> = [];
	private static var curSelected:Int = 0;
	private var descText:FlxText;

	override function create() {
		#if DISCORD_ALLOWED
		DiscordIO.changePresence("Achievements Menu");
		#end

		// Fundo da pasta Achievements
		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('Achievements/menuBGBlue'));
		menuBG.antialiasing = true;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		add(menuBG);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...achievementList.length) {
			// Texto da conquista
			var optionText:Alphabet = new Alphabet(280, 300, achievementList[i].replace('_', ' '), true);
			optionText.isMenuItem = true;
			optionText.targetY = i - curSelected;
			grpOptions.add(optionText);

			// Ícone da conquista (Puxando da sua pasta Achievements)
			var icon:FlxSprite = new FlxSprite(optionText.x - 105, optionText.y);
			// Tenta carregar o ícone. Se não achar, use 'locked' ou 'unknown'
			icon.loadGraphic(Paths.image('Achievements/' + achievementList[i]));
			icon.antialiasing = true;
			icon.ID = i;
			iconArray.push(icon);
			add(icon);
		}

		descText = new FlxText(150, 600, 980, "Conquistas do Mod", 32);
		descText.setFormat(Main.gFont, 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.screenCenter(X);
		add(descText);
		
		#if TOUCH_CONTROLS
		createPad("up-down-back", "none");
		#end

		changeSelection();
		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (Controls.justPressed(UI_UP)) changeSelection(-1);
		if (Controls.justPressed(UI_DOWN)) changeSelection(1);

		if (Controls.justPressed(BACK)) {
			FlxG.sound.play(Paths.sound('menu/cancelMenu'));
			Main.switchState(new MainMenuState());
		}
		
		// Faz os ícones seguirem o texto
		for (i in 0...iconArray.length) {
			iconArray[i].y = grpOptions.members[i].y;
			iconArray[i].x = grpOptions.members[i].x - 110;
		}
	}

	function changeSelection(change:Int = 0) {
		curSelected = flixel.math.FlxMath.wrap(curSelected + change, 0, achievementList.length - 1);

		for (item in grpOptions.members) {
			item.alpha = 0.6;
			if (item.ID == curSelected) item.alpha = 1;
		}

		for (icon in iconArray) {
			icon.alpha = 0.6;
			if (icon.ID == curSelected) icon.alpha = 1;
		}
		
		if(change != 0) FlxG.sound.play(Paths.sound('menu/scrollMenu'), 0.4);
	}
}
