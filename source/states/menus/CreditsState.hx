package states.menus;

import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import doido.objects.Alphabet;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;

typedef CreditData = {
    var name:String;
    var icon:String;
    var color:FlxColor;
	var info:String;
	var ?link:String;
}
class CreditsState extends MusicBeatState
{
    public var creditList:Array<CreditData> = [];
    public var curSelected:Int = 0;

    // ANGLE STUFF
    public var rawSelected:Int = 0;
    public var lerpSelected:Float = 0;
    public var angleStep:Float = 360;

    public var bg:FlxSprite;
    public var creditGuys:FlxTypedGroup<CreditChar>;
    public var nameTxt:Alphabet;
    public var descTxt:Alphabet;

    function addCredit(name:String, icon:String = "", color:FlxColor, info:String = "", ?link:String)
	{
		creditList.push({
			name: name,
			icon: icon,
			color: color,
			info: info,
			link: link,
		});
	}
    override function create()
    {
        super.create();
        final specialPeople = 'Anakim, ArturYoshi, BeastlyChip, Bnyu, Pi3tr0, Raphalitos, ZieroSama';
		final specialCoders = 'ShadzXD, pisayesiwsi, Lasystuff, Gazozoz, Joalor64GH, LeonGamerPS1';
		// yes, this implies coders aren't people :D
		
		// btw you dont need to credit everyone here on your mod
		// just credit doido engine as a whole and we're good
        addCredit('DiogoTV', 'diogotv', 0xFFC385FF, "Doido Engine's Owner and Main Coder", 'https://bsky.app/profile/diogotv.bsky.social');
		addCredit('teles', 'teles',     0xFFFF95AC, "Doido Engine's Co-Owner and Additional Coder", 'https://youtube.com/@telesfnf');
        addCredit('yoisabo', 'yoisabo', 0xFF56EF19, "Main artist and designer of Doido Engine's chart editor", 'https://bsky.app/profile/yoisabo.bsky.social');
		addCredit('GoldenFoxy', 'anna', 0xFFFFE100, "Main designer of Doido Engine's chart editor", 'https://bsky.app/profile/goldenfoxy.bsky.social');
		addCredit('doubleonikoo', 'nikoo', 0xFF60458A, "Credits sprite Artist", 'https://bsky.app/profile/doubleonikoo.bsky.social');
        addCredit('UTAstra', 'astra', 0xFFFFFFFF, "Coding help on Doido Engine", "https://x.com/utastra");
        addCredit('JulianoBeta', 'juyko', 0xFF0BA5FF, "Composed Doido Engine's offset menu music", 'https://www.youtube.com/@prodjuyko');
		addCredit('crowplexus', 'crowplexus', 0xFF313538, "Creator of HScript Iris", 'https://github.com/crowplexus/hscript-iris');
		addCredit('mochoco', 'coco', 0xFF56EF19, "Mobile Button Artist", 'https://x.com/mochocofrappe');
        addCredit('Github Contributors', 'github', 0xFFFFFFFF, 'THANKS TO:\n${specialCoders}\nfor helping out the engine!!', 'https://github.com/DoidoTeam/FNF-Doido-Engine/graphs/contributors');
		addCredit('Special Thanks', 'heart', 0xFFC01B42, 'THANK YOU:\n${specialPeople}!!\nfor being cool friends <33', "https://youtu.be/N0IkgKHdgIc");

        /*
		*	Don't modify the rest of the code unless you know what you're doing!!
		*/
        persistentUpdate = true;
        DiscordIO.changePresence("Credits - Thanks!!");

        bg = new FlxSprite().loadGraphic(Assets.image('menuDesat'));
        bg.alpha = 0.6;
		bg.screenCenter();
		add(bg);

        nameTxt = new Alphabet(FlxG.width / 2, 500, "A", true, CENTER);
        add(nameTxt);
        
        descTxt = new Alphabet(FlxG.width / 2, nameTxt.y + nameTxt.height + 10, "B", false, CENTER);
        descTxt.scale.set(0.5, 0.5);
        descTxt.updateHitbox();
        add(descTxt);

        add(creditGuys = new FlxTypedGroup<CreditChar>());

        angleStep = (360 / creditList.length);
        for(i in 0...creditList.length)
        {
            var newChar = new CreditChar(creditList[i].icon);
            newChar.ID = i;
            creditGuys.add(newChar);
        }
        changeSelection();
    }
    
    var leaving:Bool = false;
    var elapsedTime:Float = 0.0;
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if (!leaving)
        {
            if (Controls.justPressed(UI_LEFT)) changeSelection(-1);
            if (Controls.justPressed(UI_RIGHT)) changeSelection(1);
            if (Controls.justPressed(BACK))
            {
                leaving = true;
                MusicBeat.switchState(new states.DebugMenu());
            }
        }
        
        elapsedTime += elapsed;
        lerpSelected = FlxMath.lerp(lerpSelected, rawSelected, elapsed * 4);
        for(char in creditGuys.members)
        {
            var daAngle = FlxAngle.asRadians((char.ID - lerpSelected) * angleStep);

            var rawScale:Float = 0.8 + Math.cos(daAngle) * 0.2;
            var scaleX:Float = rawScale;
            var scaleY:Float = rawScale;

            var selected:Bool = (curSelected == char.ID);

            switch(char.curChar)
            {
                case "nikoo": // nothing

                case "yoisabo":
                    /*if (selected)
                        char.angle = ((char.angle + elapsed * 180) % 360);
                    else
                        char.angle = FlxMath.lerp(char.angle, 0, elapsed * 8);*/
                
                default:
                    if (selected)
                    {
                        char.selectedScaleElapsed += elapsed * 4;
                        char.selectedScaleX = Math.sin(char.selectedScaleElapsed) * 0.12;
                        char.selectedScaleY = Math.sin(char.selectedScaleElapsed) * -0.12;
                    }
                    else
                    {
                        char.selectedScaleElapsed = 0;
                        char.selectedScaleX = FlxMath.lerp(char.selectedScaleX, 0.0, elapsed * 5);
                        char.selectedScaleY = FlxMath.lerp(char.selectedScaleY, 0.0, elapsed * 5);
                    }
                    scaleX += char.selectedScaleX;
                    scaleY += char.selectedScaleY;

                    if (char.curChar == "diogotv")
                    {
                        if (selected)
                            char.angle = Math.cos(elapsedTime * 2) * 8;
                        else
                            char.angle = FlxMath.lerp(char.angle, 0, elapsed * 6);
                    }
            }

            char.color = FlxColor.interpolate(
                FlxColor.BLACK,
                FlxColor.WHITE,
                FlxMath.bound(0.5 + Math.cos(daAngle) * 0.5, 0.5, 1.0)
            );
            char.scale.set(scaleX, scaleY);
            char.updateHitbox();

            switch(char.curChar)
            {
                case "nikoo":
                    var floorOffset:Float = char.offset.y;
                    
                    char.nikooJumpVsp += elapsed * (char.nikooJumpVsp < 0 ? 6 : 10);
                    char.nikooJumpOffset += char.nikooJumpVsp;

                    char.offset.y -= char.nikooJumpOffset;
                    if (char.offset.y < floorOffset)
                    {
                        char.offset.y = floorOffset;
                        if (selected)
                            char.nikooJumpVsp = -FlxG.random.float(1, 4);
                        else
                            char.nikooJumpVsp = 0;
                    }
                    
                    char.shadowScale = 1.0 - (char.offset.y - floorOffset) / 200;
                    if (char.shadowScale < 0.0)
                        char.shadowScale = 0.0;
                        
                case "yoisabo":
                    char.offset.y += (80 + Math.sin(elapsedTime * 3) * 20) * rawScale;
                    char.shadowScale = 0.7 + Math.sin(elapsedTime * 3) * -0.1;
                case "heart":
                    char.offset.y += 60 * rawScale;
                    char.angle = Math.sin(elapsedTime * 4) * 8;
            }

            char.x = ((FlxG.width - char.width) / 2) + Math.sin(daAngle) * 400;
            char.y = (nameTxt.y - 160 - char.height) + Math.cos(daAngle) * 80;
            char.setZ(Math.floor(char.y + char.height));
        }
        creditGuys.sort(ZIndex.sort);
    }

    public function changeSelection(?change:Int = 0)
    {
        if (change != 0) FlxG.sound.play(Assets.sound("scroll"));

        rawSelected += change;
        curSelected += change;
        if (curSelected < 0) curSelected = creditList.length - 1;
        if (curSelected > creditList.length - 1) curSelected = 0;
        
        var curCredit = creditList[curSelected];
        nameTxt.text = curCredit.name;
        descTxt.text = curCredit.info;
        FlxTween.cancelTweensOf(bg);
        FlxTween.color(bg, 0.4, bg.color, curCredit.color);
    }
}
class CreditChar extends FlxSprite
{
    public var shadow:FlxSprite;
    public var shadowScale:Float = 1.0;

    public var curChar:String = "";

    public var nikooJumpOffset:Float = 0.0;
    public var nikooJumpVsp:Float = 0.0;

    public var selectedScaleElapsed:Float = 0.0;
    public var selectedScaleX:Float = 0.0;
    public var selectedScaleY:Float = 0.0;

    public function new(curChar:String)
    {
        super();
        this.curChar = curChar;
        shadow = new FlxSprite();
        shadow.loadImage("credits/shadow");
        switch(curChar)
        {
            default:
                if (Assets.fileExists('images/credits/char/$curChar', IMAGE))
                    this.loadImage('credits/char/$curChar');
                else
                    this.loadImage('credits/char/null');
        }
    }

    override function draw()
    {
        shadow.alpha = 0.4 * Math.min(shadowScale, 1.0);
        shadow.scale.set(
            width / shadow.frameWidth * shadowScale,
            scale.y * shadowScale
        );
        shadow.updateHitbox();
        shadow.setPosition(
            x + (width - shadow.width) / 2,
            y + height - (shadow.height / 2)
        );
        shadow.draw();
        
        if (curChar == "diogotv")
            origin.set(width / 2, height);

        super.draw();
    }
}