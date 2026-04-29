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

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('Achievements/menuBGBlue'));
		menuBG.antialiasing = true;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		add(menuBG);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...achievementList.length) {
			// Criando o texto sem usar isMenuItem (que deu erro)
			var optionText:Alphabet = new Alphabet(0, 0, achievementList[i].replace('_', ' '), true);
			optionText.ID = i;
			grpOptions.add(optionText);

			// Ícone da conquista
			var icon:FlxSprite = new FlxSprite();
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
		
		// Posicionamento manual para evitar o erro de targetY
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
			grpOptions.members[i].alpha = 0.6;
			iconArray[i].alpha = 0.6;
			
			if (i == curSelected) {
				grpOptions.members[i].alpha = 1;
				iconArray[i].alpha = 1;
			}
		}
		
		if(change != 0) FlxG.sound.play(Paths.sound('menu/scrollMenu'), 0.4);
	}
}
