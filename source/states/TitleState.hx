package states;

import backend.song.Conductor;
import backend.song.SongData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import objects.menu.Alphabet;
import states.menu.MainMenuState;

using StringTools;

class TitleState extends MusicBeatState
{
	var textGroup:FlxTypedGroup<Alphabet>;
	var curWacky:Array<String> = ['',''];
	var ngSpr:FlxSprite;
	
	var blackScreen:FlxSprite;
	var gf:FlxSprite;
	var logoBump:FlxSprite;
	var bg:FlxSprite; 
	
	var enterTxt:FlxSprite;
	
	static var introEnded:Bool = false;

	override function create()
	{
		super.create();
		
		// Fundo começando com uma cor clara
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFFFFFFF);
		add(bg);
		
		if (FlxG.save.data.flashing) {
			updateColor();
		} else {
			bg.color = 0xFF444444; // Um cinza mais claro para o modo seguro
		}

		if(!introEnded)
		{
			new FlxTimer().start(0.5, function(tmr:FlxTimer) {
				CoolUtil.playMusic("freakyMenu");
			});
			
			var allTexts:Array<String> = CoolUtil.parseTxt('introText');
			curWacky = allTexts[FlxG.random.int(0, allTexts.length - 1)].split('--');
		}
		
		DiscordIO.changePresence("In Title Screen");
		FlxG.mouse.visible = false;
		
		persistentUpdate = true;
		Conductor.setBPM(102);
		
		gf = new FlxSprite();
		gf.frames = Paths.getSparrowAtlas('menu/title/gfDanceTitle');
		gf.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gf.animation.addByIndices('danceRight','gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gf.screenCenter();
		gf.visible = false; 
		add(gf);
		
		logoBump = new FlxSprite();
		logoBump.frames = Paths.getSparrowAtlas('menu/title/logoBumpin');
		logoBump.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBump.screenCenter();
		logoBump.y -= 30; // Ajustado para dar espaço ao Enter centralizado
		add(logoBump);
		
		enterTxt = new FlxSprite();
		enterTxt.frames = Paths.getSparrowAtlas('menu/title/titleEnter');
		enterTxt.animation.addByPrefix('idle', 'Press Enter to Begin', 24, true);
		enterTxt.animation.addByPrefix('pressed', 'ENTER PRESSED', 24, true);
		enterTxt.animation.play('idle');
		
		// CENTRALIZAÇÃO TOTAL DO "PRESS ENTER"
		enterTxt.screenCenter(); 
		enterTxt.y += 180; // Posicionado um pouco abaixo do logo, mas mantendo o centro X
		add(enterTxt);
		
		blackScreen = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
		blackScreen.screenCenter();
		add(blackScreen);
		
		textGroup = new FlxTypedGroup<Alphabet>();
		add(textGroup);
		
		ngSpr = new FlxSprite().loadGraphic(Paths.image('menu/title/newgrounds_logo'));
		ngSpr.screenCenter();
		ngSpr.y = FlxG.height - ngSpr.height - 40;
		ngSpr.visible = false;
		add(ngSpr);

		addText([]);
		
		if(introEnded)
			skipIntro(true);
	}
	
	function updateColor()
	{
		// Cores mais claras: Saturação em 0.4 (pastel) e Brilho em 1.0 (máximo)
		var newColor:FlxColor = FlxColor.fromHSB(FlxG.random.int(0, 359), 0.4, 1.0);
		
		FlxTween.color(bg, 4, bg.color, newColor, {
			onComplete: function(twn:FlxTween) {
				updateColor(); 
			}
		});
	}
	
	var pressedEnter:Bool = false;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(FlxG.sound.music != null)
			if(FlxG.sound.music.playing)
				Conductor.songPos = FlxG.sound.music.time;
		
		if(Controls.justPressed(ACCEPT))
		{
			if(introEnded)
			{
				if(!pressedEnter)
				{
					pressedEnter = true;
					enterTxt.animation.play('pressed');
					FlxG.sound.play(Paths.sound('menu/confirmMenu'));
					
					if (FlxG.save.data.flashing)
						CoolUtil.flash(FlxG.camera, 1, 0xFFFFFFFF);
						
					new FlxTimer().start(2.0, function(tmr:FlxTimer)
					{
						Main.switchState(new MainMenuState());
					});
				}
			}
			else
				skipIntro();
		}
	}
	
	override function beatHit()
	{
		super.beatHit();
		
		if(logoBump != null)
			logoBump.animation.play('bump', true);
	}
	
	public function skipIntro(force:Bool = false)
	{
		if(introEnded && !force) return;
		introEnded = true;
		
		if(FlxG.sound.music != null)
			FlxG.sound.music.time = (Conductor.crochet * 16);
		
		addText([]);
		ngSpr.visible = false;
		
		if (FlxG.save.data.flashing)
			CoolUtil.flash(FlxG.camera, Conductor.crochet * 4 / 1000, 0xFFFFFFFF);
			
		remove(blackScreen);
	}
	
	public function addText(newText:Array<String>, clearTxt:Bool = true, mainY:Int = 130)
	{
		if(clearTxt) textGroup.clear();
		
		for(i in newText)
		{
			var item = new Alphabet(0, 0, i.toUpperCase(), true);
			item.align = CENTER;
			item.x = FlxG.width / 2;
			item.y = mainY + item.boxHeight * textGroup.members.length;
			item.updateHitbox();
			textGroup.add(item);
		}
	}
}

