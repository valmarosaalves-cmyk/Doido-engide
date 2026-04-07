package substates.menus;

import doido.objects.Alphabet;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
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
        #if TOUCH_CONTROLS "Mobile",#end
    ];
    public var optionList:Map<String, Array<OptionData>> = [];

    public var bg:FlxSprite;

    public var alphabetGrp:FlxTypedGroup<OptionAlphabet>;
    public var attachGrp:FlxTypedGroup<Attachment>;

    public var curCategoryString:String = "";
    public var curCategory:Int = 0;
    public var curSelection:Int = 0;

    public var curAttachType:AttachmentType = CATEGORY;

    public function new(?playState:PlayState)
    {
        super();
        this.playState = playState;
        //if (playState == null)
        //{
        bg = new FlxSprite().makeColor(FlxG.width * 0.8, FlxG.height * 0.8, 0xFF000000);
        bg.screenCenter();
        bg.alpha = 0.9;
        add(bg);
        //}

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
        catTitle.reloadStuff(bg.y + 20, curCategoryString, true);
        catTitle.ID = 0;
        if (!alphabetGrp.members.contains(catTitle))
            alphabetGrp.add(catTitle);

        var catAttach:Attachment = attachGrp.recycle(Attachment);
        catAttach.reloadStuff(catTitle, CATEGORY);
        if (attachGrp.members.contains(catAttach))
            attachGrp.add(catAttach);

        var _i:Int = 0;
        for (data in optionList.get(curCategoryString))
        {
            var optionText:OptionAlphabet = alphabetGrp.recycle(OptionAlphabet);
            optionText.reloadStuff(bg.y + 110 + (60 * _i), data.name);
            optionText.x = bg.x + 20;
            optionText.ID = _i + 1;

            if (!alphabetGrp.members.contains(optionText))
                alphabetGrp.add(optionText);

            var dataGet:Dynamic = data.get();
            var attach:Attachment = attachGrp.recycle(Attachment);
            if (Std.isOfType(dataGet, Bool))
            {
                attach.reloadStuff(optionText, CHECKMARK);
                var check = attach.checkmark;
                check.animation.play(cast(dataGet, Bool) ? "true" : "false", true);
                check.animation.curAnim.curFrame = check.animation.curAnim.numFrames - 1;
            }
            else
                attach.kill(); // no use for you sorry

            if (attachGrp.members.contains(attach))
                attachGrp.add(attach);

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
            if (attach.parent.ID == curSelection)
                curAttachType = attach.type;
        });
    }

    public function updatePlayState()
    {
        if (playState == null) return;
        playState.updateOption(optionList.get(curCategoryString)[curSelection - 1].name);
    }

    override function draw()
    {
        attachGrp.forEachAlive((attach) -> {
            attach.y = attach.parent.y - 25;
            attach.alpha = attach.parent.alpha;

            switch(attach.type)
            {
                case CATEGORY:
                    for(arrow in attach.arrows)
                    {
                        arrow.y = attach.parent.y;
                        arrow.x = attach.parent.x - (attach.parent.width / 2);
                        if (arrow.ID == 0)
                            arrow.x -= arrow.width;
                        else
                            arrow.x += attach.parent.width;

                        if (attach.parent.ID != curSelection)
                            arrow.animation.play("idle");
                        else
                        {
                            if (arrow.ID == 0) arrow.animation.play(Controls.pressed(UI_LEFT) ? "push" : "idle");
                            else arrow.animation.play(Controls.pressed(UI_RIGHT) ? "push" : "idle");
                        }
                    }
                case SELECTOR:
                    
                case CHECKMARK:
                    var check = attach.checkmark;
                    check.x = attach.parent.x + attach.parent.width;
            }            
        });
        super.draw();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (Controls.justPressed(BACK))
            close();

        if (Controls.justPressed(UI_UP)) changeSelection(-1);
        else if (Controls.justPressed(UI_DOWN)) changeSelection(1);

        switch (curAttachType)
        {
            case CATEGORY:
                if (Controls.justPressed(UI_LEFT)) changeCategory(-1);
                else if (Controls.justPressed(UI_RIGHT)) changeCategory(1);
            
            case CHECKMARK:
                if (Controls.justPressed(ACCEPT))
                {
                    var option = optionList.get(curCategoryString)[curSelection - 1];
                    option.set(!option.get());

                    attachGrp.forEachAlive((attach) -> {
                        if (attach.parent.ID != curSelection) return;
                        var check = attach.checkmark;
                        check.animation.play(option.get() ? "true" : "false", true);
                    });
                    
                    updatePlayState();
                }
            case SELECTOR:
                
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
            scale.set(0.8, 0.8);
        }
        else
        {
            align = LEFT;
            scale.set(0.65, 0.65);
        }
        updateHitbox();
    }
}

enum AttachmentType
{
    CATEGORY;
    CHECKMARK;
    SELECTOR;
}
class Attachment extends FlxSpriteGroup
{
    public var startY:Float = 0.0;
    public var parent:OptionAlphabet;

    public var type:AttachmentType = CHECKMARK;

    public var checkmark:FlxSprite;
    public var arrows:Array<FlxSprite> = [];

    public function new()
    {
        super();
        checkmark = new FlxSprite();
        checkmark.loadSparrow("menu/checkmark");
        checkmark.animation.addByPrefix("false", "false", 24, false);
        checkmark.animation.addByPrefix("true", "true", 24, false);
        checkmark.animation.play("true");
        checkmark.scale.set(0.7, 0.7);
        checkmark.updateHitbox();
        add(checkmark);

        for (i in 0...2)
        {
            var dir:String = (i == 0 ? "left" : "right");
            var arrow = new FlxSprite();
            arrow.loadSparrow("menu/menuArrows");
            arrow.animation.addByPrefix('idle', 'arrow $dir', 24, false);
            arrow.animation.addByPrefix('push', 'arrow push $dir', 24, false);
            arrow.animation.play("idle");
            arrow.scale.set(0.7, 0.7);
            arrow.updateHitbox();
            arrows.push(arrow);
            arrow.ID = i;
            add(arrow);
        }
    }

    public function reloadStuff(parent:OptionAlphabet, type:AttachmentType)
    {
        this.parent = parent;
        this.type = type;

        checkmark.kill();
        for (arrow in arrows) arrow.kill();
        switch(type)
        {
            case CATEGORY|SELECTOR:
                for (arrow in arrows)
                    arrow.revive();

            case CHECKMARK:
                checkmark.revive();
            default:
        }
    }

    public function getWidth()
    {
        switch(type)
        {
            case CHECKMARK: return checkmark.width;
            default: return 0;
        }
    }
}