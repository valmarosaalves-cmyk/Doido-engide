package states;

import backend.Achievements;
import backend.ClientPrefs;
import objects.Alphabet;
import objects.AttachedSprite; // Doido costuma usar AttachedSprite para ícones
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class AchievementsMenuState extends MusicBeatState
{
	var options:Array<String> = [];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	private var achievementArray:Array<AttachedSprite> = [];
	private var descText:FlxText;

	override function create()
	{
		#if DISCORD_ALLOWED
		backend.DiscordClient.changePresence("Visualizando Conquistas", null);
		#end

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		add(menuBG);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		// Na Doido Engine, certifique-se de que Achievements.load() ou similar foi chamado
		Achievements.loadAchievements(); 
		
		for (i in 0...Achievements.achievementsStuff.length) {
			var isUnlocked:Bool = Achievements.isAchievementUnlocked(Achievements.achievementsStuff[i][2]);
			
			var optionText:Alphabet = new Alphabet(0, (70 * i) + 30, Achievements.achievementsStuff[i][0], true);
			optionText.isMenuItem = true;
			optionText.targetY = i;
			grpOptions.add(optionText);

			// Ícone da conquista
			var icon:AttachedSprite = new AttachedSprite('achievements/' + Achievements.achievementsStuff[i][2]);
			icon.sprTracker = optionText;
			icon.copyAlpha = true;
			icon.alpha = isUnlocked ? 1 : 0.4; // Se não desbloqueou, fica transparente
			achievementArray.push(icon);
			add(icon);
		}

		descText = new FlxText(150, 600, 980, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		add(descText);

		changeSelection();
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P) changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0) curSelected = Achievements.achievementsStuff.length - 1;
		if (curSelected >= Achievements.achievementsStuff.length) curSelected = 0;

		var bullShit:Int = 0;
		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;
			item.alpha = (item.targetY == 0) ? 1 : 0.6;
		}

		descText.text = Achievements.achievementsStuff[curSelected][1]; // Descrição do JSON
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
}
