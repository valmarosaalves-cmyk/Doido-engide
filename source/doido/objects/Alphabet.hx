package doido.objects;

import doido.utils.AlphabetUtil;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

//bitmap font to-do:
// - outlines
// - better antialiasing fix?

enum AlphabetAlign
{
	LEFT;
	CENTER;
	RIGHT;
}
class Alphabet extends FlxTypedSpriteGroup<AlphaCharacter>
{
    public var text(default, set):String = "";
    public var untaggedText(default, null):String = "";
    public var align(default, set):AlphabetAlign = LEFT;
    public var bold(default, set):Bool = false;
    public var font(default, set):String = "alphabet";
    public var pixel(default, set):Bool = false;

    public function new(x:Float, y:Float, text:String, ?bold:Bool = false, ?align:AlphabetAlign = LEFT, ?font:String = "alphabet")
    {
        super();
        this.x = x;
        this.y = y;
        this.text = text;
        this.bold = bold;
        this.align = align;
        this.font = font;
    }
    
    public function set_text(v:String):String
    {
        text = v;
        reloadText();
        return text;
    }
    public function set_bold(v:Bool):Bool
    {
        bold = v;
        reloadText();
        return bold;
    }
    public function set_align(v:AlphabetAlign):AlphabetAlign
    {
        align = v;
        reloadText();
        return align;
    }

    public function set_font(v:String):String
    {
        font = v;
        calculateSize();
        reloadText();
        return font;
    }
    //jank, should be fixed later
    public function calculateSize() {
        switch(font) {
            case "alphabet":
                charHeight = 70;
                charWidth = 35;
            default:
                var char = new AlphaCharacter();
                char.frames = fontFrames;
                char.alphabet = (font == "alphabet");
                char.makeLetter("l");
                charHeight = char.height;
                charWidth = char.width;
                char.kill();
        }
    }

    public function set_pixel(b:Bool):Bool {
        pixel = b;
        forEachAlive(function(char:AlphaCharacter) {
            updateAntialiasing(char);
        });
        return pixel;
    }
    public function updateAntialiasing(char:AlphaCharacter) {
        char.antialiasing = pixel ? false : flixel.FlxSprite.defaultAntialiasing;
    }

    //in any other engine we could cache the framescollection so it doesnt have to keep being loaded
    //but we already have a cache to take care of that lol
    public var fontFrames(get, never):FlxFramesCollection;
    public function get_fontFrames():FlxFramesCollection
        return Assets.framesCollection(font, "fonts", [], ((font == "alphabet") ? SPARROW : FONT));

    private var letters:String = "abcdefghijklmnopqrstuvwxyzç";
	private var numbers:String = "0123456789";
	private var symbols:String = ",.#$%&()*+-:;<=>@[]^_!¨?/|~'\"";

    public var charHeight:Float = 70;
    public var charWidth:Float = 35;
    public var lineWidth:Array<Float> = [];

    public function reloadText()
    {
        for(char in members)
            char.kill();

        var lastWidth:Float = 0;
        var daRow:Int = 0;

        var parsed = AlphabetUtil.parse(text);

        untaggedText = "";
        var formatText = parsed.chars;
        var textTags = parsed.tags;

        var charID:Int = 0;
        for(rawChar in formatText)
        {
            untaggedText += rawChar;
            if(rawChar == "\n")
            {
                daRow++;
                lastWidth = 0;
                lineWidth[daRow] = 0;
                charID++;
                continue;
            }

            if(rawChar == " ") 
            {
                lastWidth += charWidth;
                lineWidth[daRow] = lastWidth;
                charID++;
                continue;
            }

            var char = recycle(AlphaCharacter);
            char.frames = fontFrames;
            char.alphabet = (font == "alphabet");
            char.row = daRow;

            var charBold:Bool = bold;

            if (textTags.length > 0)
            {
                for(tag in textTags)
                {
                    if (charID > tag.endIndex) continue;

                    if (charID >= tag.startIndex && charID < tag.endIndex)
                    {
                        switch(tag.type)
                        {
                            case BoldTag: charBold = true;
                            case PlainTag: charBold = false;
                            case ColorTag(value): char.setColor(value, charBold);
                            case RainbowTag(speed, uniform):
                                char.rainbowSpeed = speed;
                                if (!uniform)
                                    char.rainbowHue = FlxMath.mod(30 * -charID, 360);
                            case ShakeTag(speed, intensity):
                                char.shakeSpeed = speed;
                                char.shakeIntensity = intensity;
                            case WaveTag(speed, intensity):
                                char.waveSpeed = speed;     
                                char.waveIntensity = intensity;
                        }
                    }
                }
            }

            char.ID = charID;

            // letters
            if(letters.contains(rawChar.toLowerCase()))
                char.makeLetter(rawChar, charBold);

            // numbers
            if(numbers.contains(rawChar))
                char.makeNumber(rawChar, charBold);

            // symbols
            if(symbols.contains(rawChar))
                char.makeSymbol(rawChar, charBold);

            // just so the width stays consistent
            char.scale.set(1,1);
            char.updateHitbox();

            // pixel fonts
            updateAntialiasing(char);

            char.lastWidth = lastWidth;
            lastWidth += char.width;
            lineWidth[daRow] = lastWidth;

            charID++;
            if (!members.contains(char)) add(char);
        }

        updateHitbox();
    }

    override function updateHitbox()
    {
        super.updateHitbox();
        updatePositions();
    }

    public function updatePositions()
    {
        forEachAlive(function(char:AlphaCharacter) {
            
            char.scale.set(scale.x, scale.y);
			char.updateHitbox();

			char.x = x + ((char.lastWidth * scale.x) + (char.charOffset.x * scale.x));

			switch(align)
			{
				case CENTER:
					char.x -= (lineWidth[char.row] * scale.x) / 2;
				case RIGHT:
					char.x -= (lineWidth[char.row] * scale.x);
                default:
			}

			// i hate you i hate you i hate you i hate you
			char.y = y + (charHeight * scale.y * (char.row + 1));
			char.y -= char.height - (char.charOffset.y * scale.y);

        });
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        forEachAlive(function(char:AlphaCharacter) {
            
            if (char.shakeIntensity > 0)
            {
                if (char.shakeSpeed > 0)
                {
                    if (char.shakeTimer <= 0)
                    {
                        char.shakeTimer = 1.0;
                        char.offset.x = char.scaleOffset.x + FlxG.random.float(-char.shakeIntensity, char.shakeIntensity) * scale.x;
                        char.offset.y = char.scaleOffset.y + FlxG.random.float(-char.shakeIntensity, char.shakeIntensity) * scale.y;
                    }
                    else
                        char.shakeTimer -= elapsed * char.shakeSpeed * 10;
                }
                return;
            }
            else
            {
                char.offset.x = char.scaleOffset.x;
                char.offset.y = char.scaleOffset.y;
            }

            if (char.waveIntensity > 0)
            {
                char.waveSine += elapsed * char.waveSpeed;
                char.offset.y += Math.sin(char.waveSine - char.ID) * char.waveIntensity;
            }

            if (char.rainbowSpeed > 0)
            {
                char.rainbowHue += elapsed * 60 * char.rainbowSpeed;
                char.rainbowHue %= 360;

                char.setColor(FlxColor.fromHSB(char.rainbowHue, 1, 1));
            }

        });
    }
}

class AlphaCharacter extends FlxSprite
{
	public var lastWidth:Float = 0;
	public var row:Int = 0;

    public var scaleOffset:DoidoPoint = {x: 0, y: 0};
	public var charOffset:DoidoPoint = {x: 0, y: 0};

    public var waveSine:Float = 0.0;
    public var waveSpeed:Float = 0.0;
    public var waveIntensity:Float = 0.0;
    
    public var shakeTimer:Float = 0.0;
    public var shakeSpeed:Float = 0.0;
    public var shakeIntensity:Float = 0.0;

    public var rainbowSpeed:Float = 0.0;
    public var rainbowHue:Float = 0.0;

    public var alphabet:Bool = true;
    public var bold:Bool = false;

	public function new() {
		super();
	}

    override function revive()
    {
        charOffset = {x: 0, y: 0};

        color = FlxColor.WHITE;
        setColorTransform(1,1,1,1,0,0,0,0);

        waveSine = 0.0;
        waveSpeed = 0.0;
        waveIntensity = 0.0;

        shakeTimer = 0.0;
        shakeSpeed = 0.0;
        shakeIntensity = 0.0;

        rainbowSpeed = 0.0;
        rainbowHue = 0.0;

        alphabet = true;
        bold = false;

        super.revive();
    }

	function addAnim(animName:String, animXml:String):Void
    {
		animation.addByPrefix(animName, animXml, 24, true);
		animation.play(animName);
		updateHitbox();
	}

	public function makeLetter(key:String, bold:Bool = false):Void
    {
        this.bold = bold;
        if(alphabet) {
            if(!bold)
            {
                var captPref:String = (key == key.toUpperCase()) ? "capital" : "lowercase";
                addAnim(key, '${key.toUpperCase()} ${captPref}');
            }
            else
                addAnim(key, '${key.toUpperCase()} bold');
        }
		else addAnim(key, key);
	}

	public function makeNumber(key:String, bold:Bool = false):Void
	{
        this.bold = bold;
        if (!alphabet) return addAnim(key, key);

        if(!bold)
            addAnim(key, '${key}0');
        else
            addAnim(key, '$key bold');
	}

	public function makeSymbol(key:String, bold:Bool = false):Void
	{
        if(alphabet) {
            var animName:String = switch(key)
            {
                default: key;
                case "'": "apostraphie";
                case ",": "comma";
                case "!": "exclamation point";
                case '"': "parentheses start";
                case ".": "period";
                case "?": "question mark";
                case "/": "slash forward";
                case "÷": "heart";
            }

            animName += (bold ? " bold" : "0");
            addAnim(key, animName);

            switch(key)
            {
                case "-": charOffset.y = -20;
                case '"'|"'": charOffset.y = -40;
            }
        }
        else addAnim(key, key);
	}

	public function makeArrow(key:String):Void
	{
		//Logs.print('why $key');
		switch(key.toLowerCase())
		{
			case "left": addAnim("arrowL", "arrow left");
			case "down": addAnim("arrowD", "arrow down");
			case "up": 	 addAnim("arrowU", "arrow up");
			case "right":addAnim("arrowR", "arrow right");
		}
	}

    public function setColor(color:FlxColor, ?bold:Bool)
    {
        if (bold == null) bold = this.bold;
        if (alphabet && !bold)
        {
            setColorTransform(
                0, 0, 0, 1,
                color.red,
                color.green,
                color.blue,
                0
            );
        }
        else
            this.color = color;
    }

    override function updateHitbox() {
        super.updateHitbox();
        scaleOffset = {x: offset.x, y: offset.y};
    }
}