package states.menu;

import backend.song.SongData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.effects.FlxFlicker;

using StringTools;

class MainMenuState extends MusicBeatState
{
	var optionShit:Array<String> = ["story mode", "freeplay", "credits", "menu_awards", "options"];
	static var curSelected:Int = 0;
	
	var grpOptions:FlxTypedGroup<FlxSprite>;
	
	var bg:FlxSprite;
	var bgMag:FlxSprite;
	var bgPosY:Float = 0;
	
	var menuScript:Dynamic; 

	override function create()
	{
		super.create();
		
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		menuScript = Paths.getScript('data/scripts/MainMenuState'); 
		#end

		CoolUtil.playMusic("freakyMenu");
		DiscordIO.changePresence("In the Main Menu");

		bg = new FlxSprite().loadGraphic(Paths.image('menu/backgrounds/menuBG'));
		bg.scale.set(1.2, 1.2);
		bg.updateHitbox();
		bg.screenCenter(X);
		add(bg);
		
		bgMag = new FlxSprite().loadGraphic(Paths.image('menu/backgrounds/menuBGMagenta'));
		bgMag.scale.set(bg.scale.x, bg.scale.y);
		bgMag.updateHitbox();
		bgMag.visible = false;
		add(bgMag);
		
		grpOptions = new FlxTypedGroup<FlxSprite>();
		add(grpOptions);
		
		var optionSize:Float = 0.9;
		if(optionShit.length > 4)
		{
			for(i in 0...(optionShit.length - 4))
				optionSize -= 0.04;
		}
		
		for(i in 0...optionShit.length)
		{
			var item = new FlxSprite();
			item.frames = Paths.getSparrowAtlas('menu/mainmenu/' + optionShit[i].replace(' ', '-'));
			item.animation.addByPrefix('idle',  optionShit[i] + ' basic', 24, true);
			item.animation.addByPrefix('hover', optionShit[i] + ' white', 24, true);
			item.animation.play('idle');
			
			item.scale.set(optionSize, optionSize);
			item.updateHitbox();
			
			// Posição inicial à direita
			var margin:Float = 50; 
			item.x = FlxG.width - item.width - margin; 

			var itemSize:Float = (90 * optionSize);
			var minY:Float = 40 + itemSize;
			var maxY:Float = FlxG.height - itemSize - 40;
			
			item.y = FlxMath.lerp(minY, maxY, i / (optionShit.length - 1));
			
			item.ID = i;
			grpOptions.add(item);
		}
		
		var doidoSplash:String = 'noobs Engine ${lime.app.Application.current.meta.get('version')}';
		var funkySplash:String = 'Friday Night Funkin\' Rewritten';

		var splashTxt = new FlxText(4, 0, 0, '$doidoSplash\n$funkySplash');
		splashTxt.setFormat(Main.gFont, 18, 0xFFFFFFFF, LEFT);
		splashTxt.setBorderStyle(OUTLINE, 0xFF000000, 1.5);
		splashTxt.y = FlxG.height - splashTxt.height - 4;
		add(splashTxt);

		changeSelection();
	}
	
	var selectedSum:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(!selectedSum)
		{
			if(Controls.justPressed(UI_UP)) changeSelection(-1);
			if(Controls.justPressed(UI_DOWN)) changeSelection(1);
			if(Controls.justPressed(BACK)) Main.switchState(new TitleState());
			
			if(Controls.justPressed(ACCEPT))
			{
				selectedSum = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));
				
				for(item in grpOptions.members)
				{
					if(item.ID != curSelected)
					{
						FlxTween.tween(item, {alpha: 0}, 0.4, {ease: FlxEase.cubeOut});
					}
					else
					{
						// CORREÇÃO DO ERRO DA IMAGEM: Uso correto do FlxFlicker
						FlxFlicker.flicker(item, 1, 0.06, false, false, function(flick:FlxFlicker) {
							loadState();
						});
					}
				}
			}
		}
		
		bg.y = FlxMath.lerp(bg.y, bgPosY, elapsed * 6);
		bgMag.setPosition(bg.x, bg.y);
	}

	function loadState()
	{
		switch(optionShit[curSelected])
		{
			case "story mode": Main.switchState(new StoryMenuState());
			case "freeplay": Main.switchState(new FreeplayState());
			case "credits": Main.switchState(new CreditsState());
			case "options": Main.switchState(new OptionsState());
			default: Main.resetState();
		}
	}

	public function changeSelection(change:Int = 0)
	{
		if(change != 0) FlxG.sound.play(Paths.sound('scrollMenu'));
		
		curSelected += change;
		curSelected = FlxMath.wrap(curSelected, 0, optionShit.length - 1);
		
		bgPosY = FlxMath.lerp(0, -(bg.height - FlxG.height), curSelected / (optionShit.length - 1));
		
		for(item in grpOptions.members)
		{
			item.animation.play('idle');
			item.alpha = 0.6; 
			
			if(curSelected == item.ID)
			{
				item.animation.play('hover');
				item.alpha = 1;
			}
			
			item.updateHitbox();
			
			// Garante que o item fique na DIREITA mesmo após o updateHitbox
			var margin:Float = 50;
			item.x = FlxG.width - item.width - margin;
			item.offset.x = 0; 
		}
	}
}
