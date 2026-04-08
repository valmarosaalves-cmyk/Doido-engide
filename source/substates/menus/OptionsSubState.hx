package substates.menus;

import doido.utils.NoteUtil;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
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
    var ?display:Dynamic->String;
    var ?onChange:Void->Void;
    var ?canPlaySound:Void->Bool;
    // SELECTORS
    var ?options:Array<String>;
    // SLIDERS
    var ?step:Float;
    var ?limits:Array<Float>;
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

    public final enabledColor:FlxColor = FlxColor.WHITE;
    public final disabledColor:FlxColor = FlxColor.WHITE.getDarkened(0.6);

    public var curCategoryString:String = "";
    public var curCategory:Int = 0;
    public var curSelection:Int = 0;

    public var curAttachType:AttachmentType = CATEGORY;

    public var holdTimer:Float = 0.0;
    public var holdMax:Float = 0.4;
    public var holdTimerSfx:Bool = false;

    public function new(?playState:PlayState)
    {
        super();
        this.playState = playState;
        //if (playState == null)
        //{
        bg = new FlxSprite().makeColor(0, 0, 0xFF000000);
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
                    name: "Centered Notes",
                    get: () -> Save.data.middlescroll,
                    set: (b:Bool) -> Save.data.middlescroll = b
                },
            ],
            "Preferences" => [
                #if windows
                {
                    name: "Dark Window Border",
                    get: () -> Save.data.darkMode,
                    set: (b:Bool) -> Save.data.darkMode = b,
                    onChange: () -> {
                        doido.system.Windows.setDarkMode(Save.data.darkMode);
                    }
                },
                #end
                #if desktop
                {
                    name: "View FPS Counter",
                    get: () -> Save.data.fpsCounter,
                    set: (b:Bool) -> Save.data.fpsCounter = b
                },
                #end
                {
                    name: "Note Quantization",
                    get: () -> Save.data.quantNotes,
                    set: (b:Bool) -> Save.data.quantNotes = b
                },
                {
                    name: "Hitsound SFX",
                    get: () -> Save.data.hitsound,
                    set: (b:String) -> Save.data.hitsound = b,
                    options: ["OFF", "OSU", "NSWITCH", "CD"],
                    canPlaySound: () -> return Save.data.hitsound == "OFF",
                    onChange: () -> NoteUtil.playHitsound()
                },
                {
                    name: "Hitsound Volume",
                    get: () -> Save.data.hitsoundVolume,
                    set: (i:Float) -> Save.data.hitsoundVolume = i,
                    step: 0.05,
                    limits: [0.0, 1.0],
                    display: (i:Float) -> return '${Math.floor(i * 100)}%',
                    canPlaySound: () -> return Save.data.hitsound == "OFF",
                    onChange: () -> {
                        if (holdTimerSfx) NoteUtil.playHitsound();
                    }
                },
                {
                    name: "Flashing Lights",
                    get: () -> Save.data.flashingLights,
                    set: (s:String) -> Save.data.flashingLights = s,
                    options: ["ON", "REDUCED", "OFF"]
                },
            ],
            "Graphics" => [
                #if desktop
                {
                    name: "FPS Cap",
                    get: () -> Save.data.fps,
                    set: (i:Int) -> Save.data.fps = i,
                    limits: [30, 310],
                    step: 5,
                },
                {
                    name: "Window Size",
                    get: () -> Save.data.windowSize,
                    set: (s:String) -> Save.data.windowSize = s,
                    options: ["640x360","854x480","960x540","1024x576","1152x648","1280x720","1366x768","1600x900","1920x1080", "2560x1440", "3840x2160"],
                    onChange: () -> Main.setWindowSize(Save.data.windowSize)
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

    public var curSound:FlxSound;
    public function playSound(key:String)
    {
        if (curSound?.playing) curSound.stop();
        curSound = FlxG.sound.load(Assets.sound(key));
        curSound.play();
    }

    public function changeCategory(?change:Int = 0)
    {
        //if (change != 0) FlxG.sound.play(Assets.sound("scroll"));
        var sfx = FlxG.sound.load(Assets.sound("options/options-open"));
        sfx.pitch = FlxG.random.float(0.9, 1.1);
        sfx.play();
        
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
            if (data.canPlaySound == null) data.canPlaySound = () -> true;

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
                attach.setSelectorValue(0, data);
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

    public function changeSelection(?change:Int = 0)
    {
        holdTimer = 0.0;
        if (change != 0) FlxG.sound.play(Assets.sound("scroll"));
        curSelection = FlxMath.wrap(curSelection + change, 0, optionList.get(curCategoryString).length);

        alphabetGrp.forEachAlive((alphabet) -> {
            alphabet.color = disabledColor;
            if (alphabet.ID == curSelection)
                alphabet.color = enabledColor;
        });

        curAttachType = null;
        attachGrp.forEachAlive((attach) -> {
            if (attach.parent.ID == curSelection)
                curAttachType = attach.type;
        });

        curOption = optionList.get(curCategoryString)[curSelection - 1];
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

    public function saveOptions()
    {
        Save.save();
        if (curOption?.onChange != null) curOption?.onChange();
        if (playState == null) return;
        playState.updateOption(optionList.get(curCategoryString)[curSelection - 1].name);
    }

    override function draw()
    {
        alphabetGrp.forEach((alphabet) -> {
            for(char in alphabet.members) {
                char.clipToSprite([bg]);
            }
        });
        attachGrp.forEach((attach) -> {
            for(item in attach.members) {
                if (Std.isOfType(item, SliderBar))
                {
                    for(sprite in cast(item, SliderBar))
                        sprite.clipToSprite([bg]);
                }
                else if(Std.isOfType(item, Alphabet))
                {
                    for(char in cast(item, Alphabet))
                        char.clipToSprite([bg]);
                }
                else
                    item.clipToSprite([bg]);
            }
        });

        attachGrp.forEachAlive((attach) -> {
            attach.y = attach.parent.y;
            attach.color = attach.parent.color;

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
                        arrow.color = attach.parent.color;
                    }
                    if (attach.sliderBar.percent <= 0.0) attach.arrows[1].color = disabledColor;
                    if (attach.sliderBar.percent >= 100) attach.arrows[0].color = disabledColor;
                    
                case CHECKMARK:
                    attach.y -= 25;
                    var check = attach.checkmark;
                    check.x = attach.parent.x + bgWidth - attach.getWidth();
            }            
        });
        super.draw();
    }

    public var curOption:OptionData;

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if (Controls.justPressed(BACK))
        {
            FlxG.sound.play(Assets.sound("options/options-close"));
            close();
        }

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
            switch (curAttachType)
            {
                case CATEGORY:
                    if (Controls.justPressed(UI_LEFT)) changeCategory(-1);
                    else if (Controls.justPressed(UI_RIGHT)) changeCategory(1);

                case SELECTOR:
                    attachGrp.forEachAlive((attach) -> {
                        if (attach.parent.ID != curSelection) return;

                        var change:Int = (Controls.pressed(UI_RIGHT) ? 1 : 0) - (Controls.pressed(UI_LEFT) ? 1 : 0);

                        if (Controls.justPressed(UI_LEFT) || Controls.justPressed(UI_RIGHT))
                        {
                            attach.setSelectorValue(change, curOption);
                            if (curOption.canPlaySound())
                                playSound('options/selector-change');

                            calcBGWidth();
                            saveOptions();
                        }
                    });
                
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
                            var prevPercent = attach.sliderBar.percent;

                            var step:Float = curOption.step ?? 1.0;
                            var newValue:Float = curOption.get() + change * step;
                            attach.setSliderValue(newValue, curOption);

                            if (holdTimer < holdMax)
                                holdTimerSfx = true;
                            else
                            {
                                if (prevPercent == attach.sliderBar.percent)
                                    holdTimerSfx = false;
                                else
                                    holdTimerSfx = !holdTimerSfx;
                            }

                            if (holdTimerSfx && curOption.canPlaySound())
                                playSound('options/slider-${change < 0 ? "down" : "up"}');

                            if (holdTimer >= holdMax)
				                holdTimer = holdMax - 0.02; // 0.02

                            saveOptions();
                        }
                    });
                
                case CHECKMARK:
                    if (Controls.justPressed(ACCEPT))
                    {
                        curOption.set(!curOption.get());

                        attachGrp.forEachAlive((attach) -> {
                            if (attach.parent.ID != curSelection) return;
                            var check = attach.checkmark;
                            check.animation.play('${curOption.get()}', true);
                        });
                        
                        if (curOption.canPlaySound())
                            playSound('options/checkmark-${curOption.get()}');

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

    override function draw()
	{
		forEachAlive(function(char:AlphaCharacter) {
			char.color = color;
		});
		super.draw();
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
    public var sliderBar:SliderBar;
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

        sliderBar = new SliderBar();
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

    public function setSliderValue(newValue:Float, data:OptionData)
    {
        if (type != SLIDER) return;

        var step:Float = data.step ?? 1.0;

        var limits = data.limits;
        if (limits == null) limits = [0, 100];
        if (newValue < Math.min(limits[0], limits[1]))
            newValue = Math.min(limits[0], limits[1]);
        if (newValue > Math.max(limits[1], limits[0]))
            newValue = Math.max(limits[1], limits[0]);

        if (Std.isOfType(data.get(), Float))
            data.set(Math.round(newValue / step) * step);
        else
            data.set(Math.floor(newValue));
        
        selectorTxt.text = (data.display == null) ? '$newValue' : data.display(newValue);
        sliderBar.percent = FlxMath.remapToRange(
            newValue,
            limits[0], limits[1],
            100, 0
        );
    }

    public function setSelectorValue(change:Int, data:OptionData)
    {
        if (type != SELECTOR) return;

        if (change != 0)
        {
            var curSel = data.options.indexOf(data.get());
            curSel += change;
            data.set(data.options[FlxMath.wrap(curSel, 0, data.options.length - 1)]);
        }

        selectorTxt.text = (data.display == null) ? data.get() : data.display(data.get());
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

    override function draw()
	{
		selectorTxt?.forEachAlive(function(char:AlphaCharacter) {
			char.color = color;
		});
		super.draw();
	}
}
class SliderBar extends FlxSpriteGroup
{
	public var border:FlxSprite;

	public var sideL:FlxSprite;
	public var sideR:FlxSprite;
	public var percent(default, set):Float = 0;

	public function set_percent(v:Float)
	{
		percent = v;
		if (sideL != null && sideR != null)
		{
            sideL.scale.x = 1.0 - (percent / 100);
            sideR.scale.x = (percent / 100);
            sideL.updateHitbox();
            sideR.updateHitbox();
            updatePos();
		}
		return percent;
	}

	public function new()
	{
		super(x, y);
		percent = 50;

		sideR = new FlxSprite();
		sideR.loadGraphic(Assets.image("menu/sliderBarR"));
		sideL = new FlxSprite();
		sideL.loadGraphic(Assets.image("menu/sliderBarL"));

		add(sideR);
		add(sideL);

		border = new FlxSprite().loadGraphic(Assets.image("menu/sliderBar-border"));
		add(border);
	}

	public function updatePos()
	{
		for(item in members)
			item.setPosition(x, y);
        sideR.x += border.width - sideR.width;
	}

	override function draw()
	{
		for(item in members)
			item.color = color;
		super.draw();
	}
}
