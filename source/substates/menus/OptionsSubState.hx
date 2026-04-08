package substates.menus;

import doido.objects.ui.DoidoBar;
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
    var ?limits:Array<Float>;
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
    public var bgWidth:Float = 0.0;
    public var bgHeight:Float = 0.0;

    public var alphabetGrp:FlxTypedGroup<OptionAlphabet>;
    public var attachGrp:FlxTypedGroup<Attachment>;

    public var curCategoryString:String = "";
    public var curCategory:Int = 0;
    public var curSelection:Int = 0;

    public var curAttachType:AttachmentType = CATEGORY;

    public var holdTimer:Float = 0.0;
    var holdMax:Float = 0.4;

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
                    set: (i:Float) -> Save.data.hitsoundVolume = i,
                    step: 0.05,
                    limits: [0.0, 1.0],
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
                    set: (i:Int) -> Save.data.fps = i,
                    limits: [30, 144],
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
        catTitle.y += bg.y;
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
            optionText.reloadStuff(130 + (60 * _i), data.name);
            optionText.y += bg.y;
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
            else if (Std.isOfType(dataGet, String))
            {
                attach.reloadStuff(optionText, SELECTOR);
                attach.selectorTxt.text = (data.display == null) ? '$dataGet' : data.display(dataGet);
            }
            else if (Std.isOfType(dataGet, Int) || Std.isOfType(dataGet, Float))
            {
                attach.reloadStuff(optionText, SLIDER);
                attach.setSliderValue(dataGet, data);
            }
            else
                attach.kill(); // no use for you sorry

            if (attachGrp.members.contains(attach))
                attachGrp.add(attach);

            _i++;
        }

        changeSelection();
        calcBGWidth();
        calcBGHeight();
    }

    public function calcBGWidth()
    {
        var alphabetWidth:Float = 0.0;
        alphabetGrp.forEachAlive((alphabet) -> {
            alphabetWidth = Math.max(alphabetWidth, alphabet.width);
        });
        var rawAttachWidth:Float = 0.0;
        var attachWidth:Float = 0.0;
        attachGrp.forEachAlive((attach) -> {
            if (attach.parent.width + attach.getWidth() > rawAttachWidth)
            {
                rawAttachWidth = attach.parent.width + attach.getWidth();
                attachWidth = attach.getWidth() - alphabetWidth + attach.parent.width;
            }
        });

        bgWidth = alphabetWidth + attachWidth + 20;
    }

    public function calcBGHeight()
    {
        var firstAlphabetY:Float = FlxG.height;
        var lastAlphabetY:Float = 0.0;
        alphabetGrp.forEachAlive((alphabet) -> {
            firstAlphabetY = Math.min(firstAlphabetY, alphabet.y);
            lastAlphabetY = Math.max(lastAlphabetY, alphabet.y + alphabet.height);
        });
        bgHeight = lastAlphabetY - firstAlphabetY;
    }

    public function changeSelection(?change:Int = 0)
    {
        holdTimer = 0.0;
        if (change != 0) FlxG.sound.play(Assets.sound("scroll"));
        curSelection = FlxMath.wrap(curSelection + change, 0, optionList.get(curCategoryString).length);

        alphabetGrp.forEachAlive((alphabet) -> {
            alphabet.alpha = 0.4;
            if (alphabet.ID == curSelection)
                alphabet.alpha = 1.0;
        });

        curAttachType = null;
        attachGrp.forEachAlive((attach) -> {
            if (attach.parent.ID == curSelection)
                curAttachType = attach.type;
        });
    }

    public function saveOptions()
    {
        Save.save();
        if (playState == null) return;
        playState.updateOption(optionList.get(curCategoryString)[curSelection - 1].name);
    }

    override function draw()
    {
        attachGrp.forEachAlive((attach) -> {
            attach.y = attach.parent.y;
            attach.alpha = attach.parent.alpha;

            for(arrow in attach.arrows)
            {
                if (arrow.alive)
                {
                    if (attach.parent.ID != curSelection)
                        arrow.animation.play("idle");
                    else
                    {
                        if (arrow.ID == 0) arrow.animation.play(Controls.pressed(UI_LEFT) ? "push" : "idle");
                        else arrow.animation.play(Controls.pressed(UI_RIGHT) ? "push" : "idle");
                    }
                }
            }

            switch(attach.type)
            {
                case CATEGORY:
                    for(arrow in attach.arrows)
                    {
                        arrow.y = attach.parent.y;
                        arrow.x = attach.parent.x - (attach.parent.width / 2);
                        if (arrow.ID == 0)
                            arrow.x -= arrow.width + 15;
                        else
                            arrow.x += attach.parent.width + 15;
                    }
                case SELECTOR:
                    attach.arrows[1].x = attach.parent.x + bgWidth - attach.arrows[1].width;
                    attach.selectorTxt.x = attach.arrows[1].x - attach.selectorTxt.width - 10;
                    attach.arrows[0].x = attach.selectorTxt.x - attach.arrows[0].width - 10;

                    for(arrow in attach.arrows)
                        arrow.y = attach.parent.y - 6;
                
                case SLIDER:
                    attach.arrows[1].x = attach.parent.x + bgWidth - attach.arrows[1].width;
                    attach.sliderBar.x = attach.arrows[1].x - attach.sliderBar.border.width - 20;
                    attach.arrows[0].x = attach.sliderBar.x - attach.arrows[0].width - 20;
                    
                    attach.sliderBar.y = attach.parent.y + (attach.parent.height - attach.sliderBar.border.height) / 2;
                    attach.sliderBall.setPosition(
                        attach.sliderBar.x + (attach.sliderBar.border.width * (100 - attach.sliderBar.percent) / 100) - (attach.sliderBall.width / 2),
                        attach.sliderBar.y + (attach.sliderBar.border.height - attach.sliderBall.height) / 2
                    );
                    attach.sliderBar.updatePos();

                    attach.selectorTxt.x = attach.sliderBar.x + (attach.sliderBar.border.width - attach.selectorTxt.width) / 2;

                    for(arrow in attach.arrows) {
                        arrow.y = attach.parent.y - 6;
                        arrow.alpha = attach.parent.alpha;
                    }
                    if (attach.sliderBar.percent <= 0.0) attach.arrows[1].alpha = 0.4;
                    if (attach.sliderBar.percent >= 100) attach.arrows[0].alpha = 0.4;
                    
                case CHECKMARK:
                    attach.y -= 25;
                    var check = attach.checkmark;
                    check.x = attach.parent.x + bgWidth - attach.getWidth();
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

        bg.scale.set(
            FlxMath.lerp(bg.scale.x, bgWidth + 140, elapsed * 8),
            FlxMath.lerp(bg.scale.y, bgHeight + 80, elapsed * 8)
        );
        bg.updateHitbox();
        bg.screenCenter();

        alphabetGrp.forEachAlive((alphabet) -> {
            alphabet.y = FlxMath.lerp(
                alphabet.y,
                bg.y + alphabet.startY,
                elapsed * 8
            );
            if (alphabet.ID == 0) return;
            alphabet.x = FlxMath.lerp(
                alphabet.x,
                bg.x + (bg.width - bgWidth) / 2,
                elapsed * 8
            );
        });

        if (curAttachType != null)
        {
            var option = optionList.get(curCategoryString)[curSelection - 1];
            switch (curAttachType)
            {
                case CATEGORY:
                    if (Controls.justPressed(UI_LEFT)) changeCategory(-1);
                    else if (Controls.justPressed(UI_RIGHT)) changeCategory(1);

                case SELECTOR:
                    // calcBGWidth();
                
                case SLIDER:
                    attachGrp.forEachAlive((attach) -> {
                        if (attach.parent.ID != curSelection) return;

                        var change:Int = (Controls.pressed(UI_RIGHT) ? 1 : 0) - (Controls.pressed(UI_LEFT) ? 1 : 0);
                        if (change != 0)
                            holdTimer += elapsed;
                        else
                            holdTimer = 0.0;

                        if (Controls.justPressed(UI_LEFT) || Controls.justPressed(UI_RIGHT) || holdTimer >= holdMax)
                        {
                            if (holdTimer >= holdMax)
				                holdTimer = holdMax - 0.02; // 0.02

                            var step:Float = option.step ?? 1.0;
                            var newValue:Float = option.get() + change * step;
                            attach.setSliderValue(newValue, option);

                            saveOptions();
                        }
                    });
                
                case CHECKMARK:
                    if (Controls.justPressed(ACCEPT))
                    {
                        option.set(!option.get());

                        attachGrp.forEachAlive((attach) -> {
                            if (attach.parent.ID != curSelection) return;
                            var check = attach.checkmark;
                            check.animation.play(option.get() ? "true" : "false", true);
                        });
                        
                        saveOptions();
                    }
            }
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
    SLIDER;
}
class Attachment extends FlxSpriteGroup
{
    public var startY:Float = 0.0;
    public var parent:OptionAlphabet;

    public var type:AttachmentType = CHECKMARK;

    public var checkmark:FlxSprite;
    public var arrows:Array<FlxSprite> = [];
    public var selectorTxt:Alphabet;
    public var sliderBar:DoidoBar;
    public var sliderBall:FlxSprite;

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

        sliderBar = new DoidoBar("menu/sliderBar", "menu/sliderBar-border");
		sliderBar.sideR.color = 0xFF2A2C44;
		add(sliderBar);
        
		sliderBall = new FlxSprite().loadImage("menu/sliderBall");
		add(sliderBall);

        selectorTxt = new Alphabet(x, y, "", true, LEFT);
        selectorTxt.scale.set(0.65, 0.65);
        selectorTxt.updateHitbox();
        add(selectorTxt);
    }

    public function getWidth():Float
    {
        return switch(type)
        {
            case SELECTOR: arrows[1].width + selectorTxt.width + arrows[0].width + 20;
            case SLIDER: arrows[1].width + sliderBar.border.width + arrows[0].width + 40;
            case CHECKMARK: checkmark.width - 12;
            default: 0.0;
        }
    }

    public function setSliderValue(newValue:Float, option:OptionData)
    {
        if (type != SLIDER) return;

        var step:Float = option.step ?? 1.0;

        var limits = option.limits;
        if (limits == null) limits = [0, 100];
        if (newValue < Math.min(limits[0], limits[1]))
            newValue = Math.min(limits[0], limits[1]);
        if (newValue > Math.max(limits[1], limits[0]))
            newValue = Math.max(limits[1], limits[0]);

        if (Std.isOfType(option.get(), Float))
            option.set(Math.round(newValue / step) * step);
        else
            option.set(Math.floor(newValue));
        
        selectorTxt.text = (option.display == null) ? '$newValue' : option.display(newValue);
        sliderBar.percent = FlxMath.remapToRange(
            newValue,
            limits[0], limits[1],
            100, 0
        );
    }

    public function reloadStuff(parent:OptionAlphabet, type:AttachmentType)
    {
        this.parent = parent;
        this.type = type;

        checkmark.kill();
        for (arrow in arrows) arrow.kill();
        selectorTxt.kill();
        sliderBar.kill();
        sliderBall.kill();
        switch(type)
        {
            case CATEGORY|SELECTOR|SLIDER:
                for (arrow in arrows)
                {
                    arrow.revive();
                    switch(type)
                    {
                        case CATEGORY: arrow.scale.set(0.7, 0.7);
                        default: arrow.scale.set(0.6, 0.6);
                    }
                    arrow.updateHitbox();
                }
                if (type != CATEGORY)
                {
                    selectorTxt.revive();
                    if(type == SLIDER)
                    {
                        sliderBar.revive();
                        sliderBall.revive();
                    }
                }

            case CHECKMARK:
                checkmark.revive();
            default:
        }
    }
}