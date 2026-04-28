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

using StringTools;

class MainMenuState extends MusicBeatState
{
	var optionShit:Array<String> = ["story mode", "freeplay", "credits", "options"];
	static var curSelected:Int = 0;
	
	var grpOptions:FlxTypedGroup<FlxSprite>;
	
	var bg:FlxSprite;
	var bgMag:FlxSprite;
	var bgPosY:Float = 0;
	
	var flickMag:Float = 1;
	var flickBtn:Float = 1;
	
	override function create()
	{
		super.create();
		CoolUtil.playMusic("freakyMenu");
		
		DiscordIO.changePresence("In the Main Menu");

		bg = new FlxSprite().loadGraphic(Paths.image('menu/backgrounds/menuBG'));
		bg.scale.set(1.2,1.2);
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
			grpOptions.add(item);
			
			item.scale.set(optionSize, optionSize);
			item.updateHitbox();
			
			var itemSize:Float = (90 * optionSize);
			var minY:Float = 40 + itemSize;
			var maxY:Float = FlxG.height - itemSize - 40;
			
			if(optionShit.length < 4)
			for(i in 0...(4 - optionShit.length))
			{
				minY += itemSize;
				maxY -= itemSize;
			}
			
			// --- AJUSTE DE POSIÇÃO PARA A DIREITA ---
			var margin:Float = 60; // Aumente ou diminua para afastar da borda
			item.x = FlxG.width - item.width - margin; 
			
			item.y = FlxMath.lerp(
				minY, 
				maxY, 
				i / (optionShit.length - 1)
			);
			
			item.ID = i;
		}
		
		var doidoSplash:String = 'noobs Engine ${lime.app.Application.current.meta.get('version')}';
		var funkySplash:String = 'Friday Night Funkin\' Rewritten';

		var splashTxt = new FlxText(4, 0, 0, '$doidoSplash\n$funkySplash');
		splashTxt.setFormat(Main.gFont, 18, 0xFFFFFFFF, LEFT);
		splashTxt.setBorderStyle(OUTLINE, 0xFF000000, 1.5);
		splashTxt.y = FlxG.height - splashTxt.height - 4;
		add(splashTxt);

		changeSelection();
		bg.y = bgPosY;

		#if TOUCH_CONTROLS
		createPad("back");
		#end
	}
	
	var selectedSum:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(!selectedSum)
		{
			if(Controls.justPressed(UI_UP))
				changeSelection(-1);
			if(Controls.justPressed(UI_DOWN))
				changeSelection(1);
			
			if(Controls.justPressed(BACK))
				Main.switchState(new TitleState());
			
			if(Controls.justPressed(ACCEPT))
			{
				selectedSum = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));
				
				for(item in grpOptions.members)
				{
					if(item.ID != curSelected)
						FlxTween.tween(item, {alpha: 0}, 0.4, {ease: FlxEase.cubeOut});
				}
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer)
				{
					switch(optionShit[curSelected])
					{
						case "story mode": Main.switchState(new StoryMenuState());
						case "freeplay": Main.switchState(new FreeplayState());
						case "credits": Main.switchState(new CreditsState());
						case "options": Main.switchState(new OptionsState());
						default: Main.resetState();
					}
				});
			}
		}
		
		bg.y = FlxMath.lerp(bg.y, bgPosY, elapsed * 6);
		bgMag.setPosition(bg.x, bg.y);
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
			if(curSelected == item.ID)
				item.animation.play('hover');
			
			item.updateHitbox();
			
			// Mantém o offset centralizado para a animação de escala não bugar
			item.offset.x = item.frameWidth / 2;
			item.offset.y = item.frameHeight / 2;
		}
	}
}
