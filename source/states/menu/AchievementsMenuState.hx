package states;

import backend.Achievements;
import objects.AttachedAchievementIcon;
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
	private var achievementArray:Array<AttachedAchievementIcon> = [];
	private var descText:FlxText;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Visualizando Conquistas", null);
		#end

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		add(menuBG);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		// Carrega a lista de conquistas registradas no backend
		Achievements.loadAchievements();
		for (i in 0...Achievements.achievementsStuff.length) {
			if(!Achievements.achievementsStuff[i][3] || Achievements.isAchievementUnlocked(Achievements.achievementsStuff[i][2])) {
				options.push(Achievements.achievementsStuff[i][2]);
				
				var optionText:Alphabet = new Alphabet(0, (70 * i) + 30, Achievements.achievementsStuff[i][0], true);
				optionText.isMenuItem = true;
				optionText.targetY = i;
				grpOptions.add(optionText);

				// Ícone da conquista (mesmo sistema da Psych 0.7.1)
				var icon:AttachedAchievementIcon = new AttachedAchievementIcon(optionText, Achievements.achievementsStuff[i][2]);
				achievementArray.push(icon);
				add(icon);
			}
		}

		descText = new FlxText(150, 600, 980, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		changeSelection();
		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.UI_UP_P) changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0) curSelected = options.length - 1;
		if (curSelected >= options.length) curSelected = 0;

		var bullShit:Int = 0;
		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;
			item.alpha = 0.6;
			if (item.targetY == 0) item.alpha = 1;
		}

		for (i in 0...achievementArray.length) {
			achievementArray[i].alpha = 0.6;
			if (i == curSelected) achievementArray[i].alpha = 1;
		}

		// Atualiza a descrição baseada no JSON da conquista
		descText.text = Achievements.achievementsStuff[curSelected][1];
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
}
