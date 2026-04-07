package substates.menus;

import doido.objects.Alphabet;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import states.PlayState;

typedef OptionData =
{
	var name:String;
	var get:Void->Dynamic;
	var set:Dynamic->Void;
    var ?step:Float;
    var ?display:Dynamic->String;
}
class OptionsSubState extends MusicBeatSubState
{
    public var playState:PlayState = null;

    public var optionOrder:Array<String> = [
        "Gameplay",
        "Preferences",
        "Graphics",
        #if TOUCH_CONTROLS, "Mobile",#end
    ];
    public var optionList:Map<String, Array<OptionData>> = [];

    public var alphabetGrp:FlxTypedGroup<OptionAlphabet>;
    public var attachGrp:FlxTypedGroup<Attachment>;

    public var curCategoryString:String = "";
    public var curCategory:Int = 0;
    public var curSelection:Int = 0;

    public function new(?playState:PlayState)
    {
        super();
        this.playState = playState;
        if (playState == null)
        {
            var bg = new FlxSprite().makeColor(FlxG.width + 10, FlxG.height + 10, 0xFF000000);
            bg.screenCenter();
            bg.alpha = 0.9;
            add(bg);
        }

        optionList = [
            "Gameplay" => [
                {
                    name: "Downscroll",
                    get: () -> Save.data.downscroll,
                    set: (b:Bool) -> Save.data.downscroll = b
                },
                {
                    name: "Middlescroll",
                    get: () -> Save.data.middlescroll,
                    set: (b:Bool) -> Save.data.middlescroll = b
                },
            ],
            "Preferences" => [
                {
                    name: "Dark Window Border",
                    get: () -> Save.data.darkMode,
                    set: (b:Bool) -> Save.data.darkMode = b
                },
                {
                    name: "Quant Notes",
                    get: () -> Save.data.quantNotes,
                    set: (b:Bool) -> Save.data.quantNotes = b
                },
                #if desktop
                {
                    name: "FPS Counter",
                    get: () -> Save.data.fpsCounter,
                    set: (b:Bool) -> Save.data.fpsCounter = b
                },
                #end
                {
                    name: "Hitsounds",
                    get: () -> Save.data.hitsounds,
                    set: (b:Bool) -> Save.data.hitsounds = b
                },
                {
                    name: "Hitsound Volume",
                    get: () -> Save.data.hitsoundVolume,
                    set: (i:Float) -> Save.data.hitsoundVolume = FlxMath.bound(i, 0.0, 1.0),
                    step: 0.1,
                    display: (i:Float) -> return '${Math.floor(i * 100)}%'
                },
                {
                    name: "Flashing Lights",
                    get: () -> Save.data.flashingLights,
                    set: (i:Int) -> Save.data.flashingLights = ["ON", "REDUCED", "OFF"][i]
                },
            ],
            "Graphics" => [
                #if desktop
                {
                    name: "FPS",
                    get: () -> Save.data.fps,
                    set: (i:Int) -> Save.data.fps = Math.floor(FlxMath.bound(i, 30, 144))
                },
                {
                    name: "Window Size",
                    get: () -> Save.data.windowSize,
                    set: (i:Int) -> Save.data.windowSize = ["640x360", "1280x720", "1920x1080"][i]
                },
                {
                    name: "GPU Caching",
                    get: () -> Save.data.gpuCaching,
                    set: (b:Bool) -> Save.data.gpuCaching = b
                },
                #end
                {
                    name: "Antialiasing",
                    get: () -> Save.data.antialiasing,
                    set: (b:Bool) -> Save.data.antialiasing = b
                },
                {
                    name: "Low Quality",
                    get: () -> Save.data.lowQuality,
                    set: (b:Bool) -> Save.data.lowQuality = b
                },
            ],
            #if TOUCH_CONTROLS
            "Mobile" => [
                {
                    name: "Modern Controls",
                    get: () -> Save.data.modernControls,
                    set: (b:Bool) -> Save.data.modernControls = b
                },
                {
                    name: "Invert Swipe X",
                    get: () -> Save.data.invertX,
                    set: (b:Bool) -> Save.data.invertX = b
                },
                {
                    name: "Invert Swipe Y",
                    get: () -> Save.data.invertY,
                    set: (b:Bool) -> Save.data.invertY = b
                },
            ],
            #end
        ];

        add(alphabetGrp = new FlxTypedGroup<OptionAlphabet>());
        add(attachGrp = new FlxTypedGroup<Attachment>());

        changeCategory();
    }

    public function changeCategory(?change:Int = 0)
    {
        if (change != 0) FlxG.sound.play(Assets.sound("scroll"));
        curCategory = FlxMath.wrap(curCategory + change, 0, optionOrder.length - 1);
        curCategoryString = optionOrder[curCategory];

        alphabetGrp.forEachAlive((alphabet) -> {
            alphabet.kill();
        });
        attachGrp.forEachAlive((attach) -> {
            attach.kill();
        });

        var catTitle:OptionAlphabet = alphabetGrp.recycle(OptionAlphabet);
        catTitle.reloadStuff(40, curCategoryString, true);
        catTitle.ID = 0;
        if (!alphabetGrp.members.contains(catTitle))
            alphabetGrp.add(catTitle);

        var _i:Int = 0;
        for (data in optionList.get(curCategoryString))
        {
            var optionText:OptionAlphabet = alphabetGrp.recycle(OptionAlphabet);
            optionText.reloadStuff(140 + (80 * _i), data.name);
            optionText.x = 80;
            optionText.ID = _i + 1;

            if (!alphabetGrp.members.contains(optionText))
                alphabetGrp.add(optionText);

            _i++;
        }

        changeSelection();
    }

    public function changeSelection(?change:Int = 0)
    {
        if (change != 0) FlxG.sound.play(Assets.sound("scroll"));
        curSelection = FlxMath.wrap(curSelection + change, 0, optionList.get(curCategoryString).length);

        alphabetGrp.forEachAlive((alphabet) -> {
            alphabet.alpha = 0.4;
            if (alphabet.ID == curSelection)
                alphabet.alpha = 1.0;
        });
        attachGrp.forEachAlive((attach) -> {
            attach.alpha = attach.parent.alpha;
        });
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (Controls.justPressed(BACK))
            close();

        if (Controls.justPressed(UI_UP)) changeSelection(-1);
        if (Controls.justPressed(UI_DOWN)) changeSelection(1);

        if (curSelection == 0)
        {
            if (Controls.justPressed(UI_LEFT)) changeCategory(-1);
            if (Controls.justPressed(UI_RIGHT)) changeCategory(1);
        }
        else
        {

        }
    }
}

class OptionAlphabet extends Alphabet
{
    public var startY:Float = 0.0;
    public var isCategory:Bool = false;

    public function new() {
        super(0, 0, text, true);
    }

    public function reloadStuff(startY:Float, text:String, isCategory:Bool = false)
    {
        this.y = this.startY = startY;
        this.text = text;
        this.isCategory = isCategory;
        if (isCategory)
        {
            align = CENTER;
            x = FlxG.width / 2;
            scale.set(1.0, 1.0);
        }
        else
        {
            align = LEFT;
            scale.set(0.8, 0.8);
        }
        updateHitbox();
    }
}

class Attachment extends FlxSprite
{
    public var startY:Float = 0.0;
    public var parent:OptionAlphabet;

    public function new() {
        super();
    }
}