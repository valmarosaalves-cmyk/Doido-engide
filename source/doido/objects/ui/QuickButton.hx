package doido.objects.ui;

import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxSignal;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;

typedef ButtonSignal = FlxTypedSignal<QuickButton->Void>;

class QuickButton extends FlxSprite
{
    public var onUp(default, null):ButtonSignal = new ButtonSignal();
    public var onDown(default, null):ButtonSignal = new ButtonSignal();
    public var onHover(default, null):ButtonSignal = new ButtonSignal();
    public var onOut(default, null):ButtonSignal = new ButtonSignal();

    public var maxScale:Float = 1.15;
    public var minScale:Float = 0.9;
    public var idleScale:Float = 1;

    public function new(?onUp:QuickButton->Void, ?onDown:QuickButton->Void)
    {
        super();
        this.onUp.add(onUp);
        this.onDown.add(onDown);
    }

    var hovering:Bool = false;
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        var daScale:Float = idleScale;
        if (FlxG.mouse.overlaps(this))
        {
            daScale = maxScale;
            if (FlxG.mouse.pressed) daScale = minScale;
            if (FlxG.mouse.justPressed) onDown.dispatch(this);
            if (FlxG.mouse.justReleased) onUp.dispatch(this);
            if(!hovering) {
                onHover.dispatch(this);
                hovering = true;
            }
        }
        else if(hovering) {
            onOut.dispatch(this);
            hovering = false;
        }

        scale.set(
            FlxMath.lerp(scale.x, daScale, elapsed * 8),
            FlxMath.lerp(scale.y, daScale, elapsed * 8)
        );
    }
}

class AnimatedButton extends QuickButton
{
    public function new(sprite:String, animation:String, ?onUp:QuickButton->Void, ?onDown:QuickButton->Void)
    {
        super(onUp, onDown);

        this.loadSparrow(sprite);
        this.animation.addByPrefix("idle", animation + "0000", 0, false);
        this.animation.addByPrefix("pressed", animation + "0001", 0, false);
        this.animation.play("idle", true);

        this.onUp.add((btn) -> {btn.animation.play("idle");});
        this.onDown.add((btn) -> {btn.animation.play("pressed");});
        this.onOut.add((btn) -> {btn.animation.play("idle");});

        maxScale = 1.05;
        minScale = 0.95;
    }
}

class TextButton extends FlxSpriteGroup
{
    var button:AnimatedButton;
    var text:FlxBitmapText;

    public function new(label:String = "", big:Bool = false, ?onUp:QuickButton->Void, ?onDown:QuickButton->Void) {
        super();

        button = new AnimatedButton("editors/charting/button_big", "buttonbig", onUp, onDown);
        add(button);
        
        text = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
        text.color = 0xFF000000;
        text.alignment = CENTER;
        text.text = label;
        updateText();
		add(text);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        updateText();
    }

    function updateText() {
        var targetScale = 0.625 * button.scale.x;
        if (text.scale.x != targetScale) {
            text.scale.set(targetScale, targetScale);
            text.updateHitbox();
        }

        text.x = button.x + (button.width / 2) - (text.width / 2);
        text.y = button.y + (button.height / 2) - (text.height / 2);
    }
}