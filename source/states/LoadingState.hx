package states;

import doido.utils.NoteUtil;
import objects.Character;
import flixel.FlxSprite;
import sys.thread.Mutex;
import sys.thread.Thread;
import flixel.group.FlxGroup;
import flixel.FlxBasic;
import doido.Cache;
import objects.Stage;
import doido.objects.DoidoSprite;
import objects.ui.HealthIcon;
import objects.ui.HealthIcon.IconData;
import doido.song.AudioHandler;

class LoadingState extends MusicBeatState
{
	var threadActive:Bool = true;
	var mutex:Mutex;

	var images:Array<String> = [];
	var sounds:Array<String> = [];

	override function create()
	{
		super.create();

		var color = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFCAFF4D);
		color.screenCenter();
		add(color);

		var SONG = PlayState.SONG;
		mutex = new Mutex();
		var preloadThread = Thread.create(function()
		{
			mutex.acquire();
			Logs.print("start load");
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
				try
				{
					data = cast(Assets.json('data/characters/$char'));
				}
				catch (e)
				{
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
					try
					{
						icon = cast(Assets.json('data/icons/$char'));
					}
					catch (e)
					{
						Logs.print('ICON $char LOAD ERROR: $e', ERROR);
						icon = HealthIcon.defaultIcon();
					}

					Assets.image('icons/${icon.image ?? char}');
				}
			}

			var audio = new AudioHandler(SONG.CHART.song);
			NoteUtil.loadMissSounds();

			pushImage(Assets.list('images/ui/hud/${SONG.META.assets.hudType}/', false, IMAGE));
			pushImage(Assets.list('images/ui/ratings/${SONG.META.assets.hudType}/', false, IMAGE));

			for (image in images)
				Assets.image(image);

			for (sound in sounds)
				Assets.sound(sound);

			Logs.print("end load");
			Cache.loading = false;
			threadActive = false;
			mutex.release();
		});
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

		if (!threadActive && !byeLol)
		{
			byeLol = true;
			MusicBeat.skipClearCache = true;
			MusicBeat.switchState(new states.PlayState());
		}
	}
}
