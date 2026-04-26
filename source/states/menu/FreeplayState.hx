package states.menu;

import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import backend.song.Highscore;
import backend.song.Highscore.ScoreData;
import backend.song.SongData;
import objects.menu.AlphabetMenu;
import objects.hud.HealthIcon;
import states.*;
import states.editors.ChartingState;
import subStates.menu.DeleteScoreSubState;
import backend.song.Timings;
import flixel.util.FlxStringUtil;

using StringTools;

typedef FreeplaySong = {
	var name:String;
	var icon:String;
	var diffs:Array<String>;
	var color:FlxColor;
}

class FreeplayState extends MusicBeatState
{
	var songList:Array<FreeplaySong> = [];
	
	function addSong(name:String, icon:String, diffs:Array<String>)
	{
		songList.push({
			name: name,
			icon: icon,
			diffs: diffs,
			color: HealthIcon.getColor(icon),
		});
	}

	static var curSelected:Int = 0;
	static var curDiff:Int = 1;

	var bg:FlxSprite;
	var bgTween:FlxTween;
	var grpItems:FlxGroup;

	var scoreCounter:ScoreCounter;

	override function create()
	{
		super.create();
		CoolUtil.playMusic("freakyMenu");

		DiscordIO.changePresence("Freeplay - Choosin' a track");

		bg = new FlxSprite().loadGraphic(Paths.image('menu/backgrounds/menuDesat'));
		bg.scale.set(1.2,1.2); bg.updateHitbox();
		bg.screenCenter();
		add(bg);
		
		for(i in 0...SongData.weeks.length)
		{
			var week = SongData.getWeek(i);
			if(week.storyModeOnly) continue;

			for(song in week.songs)
				addSong(song[0], song[1], week.diffs);
		}

		var extraSongs = CoolUtil.parseTxt('extra-songs');
		for(line in extraSongs)
		{
			if(line.startsWith("//")) continue;
			var diffArray:Array<String> = line.split(' ');
			if(diffArray.length < 1) continue;
			var songName:String = diffArray.shift();
			if(diffArray.length < 1) diffArray = SongData.defaultDiffs;
			addSong(songName, "face", diffArray);
		}

		grpItems = new FlxGroup();
		add(grpItems);

		for(i in 0...songList.length)
		{
			var label:String = songList[i].name;
			var item = new AlphabetMenu(0, 0, label, true);
			
			item.spaceX = 0; 
			item.ID = i;
			item.focusY = i - curSelected;
			item.updatePos();
			item.screenCenter(X); 
			grpItems.add(item);

			var icon = new HealthIcon();
			icon.setIcon(songList[i].icon);
			icon.ID = i;
			grpItems.add(icon);

			item.icon = icon;
		}

		scoreCounter = new ScoreCounter();
		add(scoreCounter);

		#if TOUCH_CONTROLS
		createPad("reset");
		#else
		var resetTxt = new FlxText(0, 0, 0, "PRESS RESET TO DELETE SONG SCORE");
		resetTxt.setFormat(Main.gFont, 28, 0xFFFFFFFF, RIGHT);
		var resetBg = new FlxSprite().makeGraphic(Math.floor(FlxG.width * 1.5), Math.floor(resetTxt.height+ 8), 0xFF000000);
		resetBg.alpha = 0.4;
		resetBg.screenCenter(X);
		resetBg.y = FlxG.height- resetBg.height;
		resetTxt.screenCenter(X);
		resetTxt.y = resetBg.y + 4;
		add(resetBg);
		add(resetTxt);
		#end

		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		for(rawItem in grpItems.members)
		{
			if(Std.isOfType(rawItem, AlphabetMenu))
			{
				var item = cast(rawItem, AlphabetMenu);
				item.screenCenter(X); 
				item.icon.x = item.x + item.width + 10;
				item.icon.y = item.y - 30;
				item.icon.alpha = item.alpha;
			}
		}

		if(Controls.justPressed(UI_UP)) changeSelection(-1);
		if(Controls.justPressed(UI_DOWN)) changeSelection(1);
		if(Controls.justPressed(UI_LEFT)) changeDiff(-1);
		if(Controls.justPressed(UI_RIGHT)) changeDiff(1);

		if(Controls.justPressed(RESET)) {
			var curSong = songList[curSelected];
			openSubState(new DeleteScoreSubState(curSong.name, curSong.diffs[curDiff]));
		}

		if(DeleteScoreSubState.deletedScore) {
			DeleteScoreSubState.deletedScore = false;
			updateScoreCount();
		}

		if(Controls.justPressed(ACCEPT) || FlxG.keys.justPressed.SEVEN)
		{
			try {
				var curSong = songList[curSelected];
				PlayState.playList = [];
				PlayState.songDiff = curSong.diffs[curDiff];
				PlayState.loadSong(curSong.name);
				Main.switchState(new LoadingState());
			} catch(e:Dynamic) {
				FlxG.sound.play(Paths.sound('menu/cancelMenu'));
			}
		}
		
		if(Controls.justPressed(BACK)) {
			FlxG.sound.play(Paths.sound('menu/cancelMenu'));
			Main.switchState(new MainMenuState());
		}
	}
	
	public function changeDiff(change:Int = 0)
	{
		curDiff += change;
		var maxDiff:Int = songList[curSelected].diffs.length - 1;
		curDiff = (change == 0) ? Math.floor(FlxMath.bound(curDiff, 0, maxDiff)) : FlxMath.wrap(curDiff, 0, maxDiff);
		updateScoreCount();
	}

	public function changeSelection(?change:Int = 0)
	{
		curSelected += change;
		curSelected = FlxMath.wrap(curSelected, 0, songList.length - 1);
		changeDiff();
		
		for(rawItem in grpItems.members)
		{
			if(Std.isOfType(rawItem, AlphabetMenu))
			{
				var item = cast(rawItem, AlphabetMenu);
				item.focusY = item.ID - curSelected;
				item.alpha = (item.ID == curSelected) ? 1 : 0.4;
			}
		}
		
		if(bgTween != null) bgTween.cancel();
		bgTween = FlxTween.color(bg, 0.4, bg.color, songList[curSelected].color);
		if(change != 0) FlxG.sound.play(Paths.sound("menu/scrollMenu"));
		updateScoreCount();
	}
	
	public function updateScoreCount()
	{
		var curSong = songList[curSelected];
		scoreCounter.updateDisplay(curSong.name, curSong.diffs[curDiff]);
	}
}

class ScoreCounter extends FlxGroup
{
	public var bg:FlxSprite;
	public var text:FlxText;
	public var diffTxt:FlxText;
	public var realValues:ScoreData;
	public var lerpValues:ScoreData;
	var rank:String = "N/A";

	public function new()
	{
		super();
		bg = new FlxSprite().makeGraphic(32, 32, 0xFF000000);
		bg.alpha = 0.4;
		add(bg);
		
		text = new FlxText(0, 0, 0, "");
		text.setFormat(Main.gFont, 28, 0xFFFFFFFF, CENTER);
		add(text);
		
		diffTxt = new FlxText(0,0,0,"< DURO >");
		diffTxt.setFormat(Main.gFont, 28, 0xFFFFFFFF, CENTER);
		add(diffTxt);

		realValues = {score: 0, accuracy: 0, misses: 0};
		lerpValues = {score: 0, accuracy: 0, misses: 0};
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		text.text = "HIGHSCORE: " + FlxStringUtil.formatMoney(Math.floor(lerpValues.score), false, true) +
					"\nACCURACY:  " +(Math.floor(lerpValues.accuracy * 100) / 100) + "%" + ' [$rank]' +
					"\nMISSES:    " + Math.floor(lerpValues.misses);

		lerpValues.score 	= FlxMath.lerp(lerpValues.score, 	realValues.score, 	 elapsed * 8);
		lerpValues.accuracy = FlxMath.lerp(lerpValues.accuracy, realValues.accuracy, elapsed * 8);
		lerpValues.misses 	= FlxMath.lerp(lerpValues.misses, 	realValues.misses, 	 elapsed * 8);

		rank = Timings.getRank(lerpValues.accuracy, Math.floor(lerpValues.misses), false, lerpValues.accuracy == realValues.accuracy);

		bg.scale.x = ((text.width + 40) / 32);
		bg.scale.y = ((text.height + diffTxt.height + 20) / 32);
		bg.updateHitbox();

		bg.screenCenter(X);
		bg.y = 10;

		text.screenCenter(X);
		text.y = bg.y + 10;
		
		diffTxt.screenCenter(X);
		diffTxt.y = text.y + text.height + 5;
	}

	public function updateDisplay(song:String, diff:String)
	{
		realValues = Highscore.getScore('${song}-${diff}');
		diffTxt.text = '< ${diff.toUpperCase()} >';
	}
}

