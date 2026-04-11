package states;

import doido.Cache;
import doido.objects.Alphabet;
import doido.objects.DoidoSprite;
import doido.song.AudioHandler;
import doido.utils.NoteUtil;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import objects.Character;
import objects.Stage;
import objects.ui.HealthIcon;
import objects.ui.HealthIcon.IconData;
import sys.thread.Mutex;
import sys.thread.Thread;

class LoadingState extends MusicBeatState
{
	var threadActive:Bool = true;

	var images:Array<String> = [];
	var sounds:Array<String> = [];

	var bgFile:String = "";
	var bg:FlxSprite;
	var loadingTxt:Alphabet;
	var loadingTxtColor:String = "";

	var loadingPercent:Float = 0.0;
	var doingWhat:String = "";

	override function create()
	{
		super.create();
		persistentUpdate = true;

		loadingTxtColor = (Save.data.darkMode ? "FFFFFF" : "000000");

		bgFile = '${Save.data.darkMode ? "menuInvert" : "menuDesat"}';
		bg = new FlxSprite().loadImage(bgFile);
		bg.color = FlxColor.fromHSB(FlxG.random.int(0, 359), 0.7, 1);
		bg.screenCenter();
		add(bg);

		var splashTxt = new Alphabet(40, 0, '<wave intensity=5 speed=5>LOADING...</wave>', true, LEFT);
		splashTxt.y = FlxG.height - splashTxt.height - 60;
		add(splashTxt);

		loadingTxt = new Alphabet(40, splashTxt.y + splashTxt.height, "", false, LEFT);
		loadingTxt.scale.set(0.5,0.5);
		add(loadingTxt);

		loadingPercent = 0.0;
		doingWhat = "Loading Characters";

		var SONG = PlayState.SONG;
		var mutex = new Mutex();
		Thread.create(function()
		{
			mutex.acquire();
			Logs.print("Loading Started!");
			Cache.loading = true;
			
			var charList:Array<String> = [SONG.META.player1, SONG.META.player2];
			var gfList:Array<String> = [SONG.META.gf];

			var stageBuild = new Stage(null);
			stageBuild.reloadStage(SONG.META.stage);

			if (!gfList.contains(stageBuild.gfVersion) || stageBuild.gfVersion != "")
				gfList.push(stageBuild.gfVersion);

			for (event in SONG.EVENTS.events)
			{
				switch (event.name)
				{
					/*case 'Change Character':
						charList.push(daEvent.value2);
						switch (daEvent.value1)
						{
							case 'bf' | 'boyfriend': playerChars.push(daEvent.value2);
						}
					 */
					case 'Change Stage':
						stageBuild.reloadStage(event.data[0]);

						if (!gfList.contains(stageBuild.gfVersion) || stageBuild.gfVersion != "")
							gfList.push(stageBuild.gfVersion);
				}
			}

			for (char in charList.concat(gfList))
			{
				var data:DoidoCharacter;
				try {
					data = cast(Assets.json('data/characters/$char'));
				} catch (e) {
					Logs.print('CHAR $char LOAD ERROR: $e', ERROR);
					data = Character.defaultCharacter();
				}

				var extrasheets:Array<String> = [];
				if ((data.extrasheets ?? []).length > 0)
				{
					for (sheet in (data.extrasheets ?? []))
						extrasheets.push('images/characters/$sheet');
				}

				Assets.framesCollection('characters/${data.spritesheet}', extrasheets, DoidoSprite.stringToSpriteType(data.spriteType));

				if (!gfList.contains(char))
				{
					var icon:IconData;
					try {
						icon = cast(Assets.json('data/icons/$char'));
					} catch (e) {
						Logs.print('ICON $char LOAD ERROR: $e', ERROR);
						icon = HealthIcon.defaultIcon();
					}

					Assets.image('icons/${icon.image ?? char}');
				}
			}

			loadingPercent = 0.5;
			doingWhat = "Loading Audio";

			var audio = new AudioHandler(SONG.CHART.song);
			NoteUtil.loadMissSounds();

			// temporary caching
			for (i in 0...4) {
				Assets.sound("countdown/base/intro" + ["3", "2", "1", "Go"][i]);
			}

			loadingPercent = 0.75;
			doingWhat = "Loading HUD";

			// temporary caching
			for (folder in ["", "/quant"]) {
				for (file in ["splashes", "covers"])
					Assets.sparrow('ui/notes/base$folder/$file');
			}

			pushImage(Assets.list('images/ui/hud/${SONG.META.assets.hudType}/', false, IMAGE));
			pushImage(Assets.list('images/ui/ratings/${SONG.META.assets.hudType}/', false, IMAGE));

			loadingPercent = 0.9;
			doingWhat = "Loading Other";

			for (image in images)
				Assets.image(image);

			for (sound in sounds)
				Assets.sound(sound);
			
			loadingPercent = 1.0;
			doingWhat = "Done!";
			Logs.print("Loading Ended!");

			Cache.loading = false;
			threadActive = false;
			mutex.release();
		});
	}

	override function destroy()
	{
		Cache.clearGraphic('assets/images/$bgFile.png', bg.graphic);
		super.destroy();
	}

	function pushImage(?path:String, ?list:Array<String>)
	{
		if (path != null)
			images.push(formatImage(path));

		if (list != null)
			for (image in list)
				images.push(formatImage(image));
	}

	function formatImage(image:String)
		return image.replace("assets/images/", "").replace(".png", "");

	var byeLol:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (loadingTxt.text != doingWhat)
			loadingTxt.text = '<color value=#${loadingTxtColor}><wave intensity=2 speed=5>${doingWhat}</wave></color>';

		if (!threadActive && !byeLol)
		{
			byeLol = true;
			MusicBeat.skipClearCache = true;
			MusicBeat.switchState(new states.PlayState());
		}
	}
}
