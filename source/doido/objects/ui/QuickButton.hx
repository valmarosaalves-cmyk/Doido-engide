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
	public var onDisable(default, null):ButtonSignal = new ButtonSignal();

	public var maxScale:Float = 1.15;
	public var minScale:Float = 0.9;
	public var idleScale:Float = 1;
	public var changeScale:Bool = true;

	private var storedMax:Float = 1;
	private var storedMin:Float = 1;

	public var disabled(default, set):Bool;

	public function set_disabled(b:Bool)
	{
		disabled = b;

		if (disabled)
		{
			storedMax = maxScale;
			storedMin = minScale;
			maxScale = 1;
			minScale = 1;
		}
		else
		{
			maxScale = storedMax;
			minScale = storedMin;
		}

		onDisable.dispatch(this);
		return b;
	}

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

		if (!disabled)
		{
			if (FlxG.mouse.overlaps(this))
			{
				if (maxScale != 1 || minScale != 1)
				{
					daScale = maxScale;
					if (FlxG.mouse.pressed)
						daScale = minScale;
				}

				if (FlxG.mouse.justPressed)
					onDown.dispatch(this);
				if (FlxG.mouse.justReleased)
					onUp.dispatch(this);
				if (!hovering)
				{
					onHover.dispatch(this);
					hovering = true;
				}
			}
			else if (hovering)
			{
				onOut.dispatch(this);
				hovering = false;
			}
		}

		if (changeScale)
			scale.set(FlxMath.lerp(scale.x, daScale, elapsed * 8), FlxMath.lerp(scale.y, daScale, elapsed * 8));
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

		this.onUp.add((btn) ->
		{
			if (!disabled)
				btn.animation.play("idle");
		});
		this.onDown.add((btn) ->
		{
			if (!disabled)
				btn.animation.play("pressed");
		});
		this.onOut.add((btn) ->
		{
			if (!disabled)
				btn.animation.play("idle");
		});

		maxScale = 1;
		minScale = 0.95;
	}

	override function set_disabled(b:Bool):Bool
	{
		super.set_disabled(b);
		animation.play(b ? "pressed" : "idle");
		return disabled;
	}
}

class Checkmark extends QuickButton
{
	public var value(default, set):Bool;

	public function set_value(b:Bool)
	{
		value = b;
		animation.play((value ? "on" : "off"));
		return value;
	}

	public function new(defVal:Bool = false, sprite:String = "editors/charting/checkmark", animation:String = "button checkmark", ?onUp:QuickButton->Void,
			?onDown:QuickButton->Void)
	{
		super(onUp, onDown);

		this.loadSparrow(sprite);
		this.animation.addByPrefix("off", animation + "0000", 0, false);
		this.animation.addByPrefix("on", animation + "0001", 0, false);

		this.onUp.add((btn) ->
		{
			value = !value;
		});

		value = defVal;
		maxScale = 1;
		minScale = 0.95;
	}
}

class TextButton extends FlxSpriteGroup
{
	public var button:AnimatedButton;
	public var text:FlxBitmapText;

	public function new(label:String = "", big:Bool = false, ?onUp:QuickButton->Void, ?onDown:QuickButton->Void)
	{
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

	function updateText()
	{
		var targetScale = 0.625 * button.scale.x;
		if (text.scale.x != targetScale)
		{
			text.scale.set(targetScale, targetScale);
			text.updateHitbox();
		}

		text.x = button.x + (button.width / 2) - (text.width / 2);
		text.y = button.y + (button.height / 2) - (text.height / 2);
	}
}

class MenuButton extends FlxSpriteGroup
{
	var _label:FlxBitmapText;
	var _bind:FlxBitmapText;
	var button:QuickButton;

	public function new(label:String, ?bind:String, width:Float = 318, height:Float = 22, ?onUp:QuickButton->Void, ?onDown:QuickButton->Void)
	{
		super();

		button = new QuickButton(onUp, onDown);
		button.makeColor(width, height, 0xFFD8DAF6);
		button.alpha = 0;
		button.maxScale = 1;
		button.minScale = 1;
		button.changeScale = false;
		add(button);

		button.onHover.add((btn) ->
		{
			btn.alpha = 0.2;
		});
		button.onOut.add((btn) ->
		{
			btn.alpha = 0;
		});

		_label = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
		_label.color = 0xFFFFFFFF;
		_label.alignment = LEFT;
		_label.text = label;
		_label.scale.set(0.625, 0.625);
		_label.updateHitbox();
		_label.setPosition(button.x + 2, button.y + ((button.height / 2) - (_label.height / 2)));
		add(_label);

		if (bind != null)
		{
			_bind = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
			_bind.color = 0xFF557BA0;
			_bind.alignment = RIGHT;
			_bind.text = '($bind)';
			_bind.scale.set(0.625, 0.625);
			_bind.updateHitbox();
			_bind.setPosition(button.x + button.width - _bind.width - 2, button.y + ((button.height / 2) - (_bind.height / 2)));
			add(_bind);
		}
	}
}

class BoxLabel extends FlxSpriteGroup
{
	var text:FlxBitmapText;
	var bg:FlxSprite;
	var button:QuickButton;
	var toggled:Bool = false;

	public function new(label:String, width:Float = 318, height:Float = 22, center:Bool = true, ?onUp:QuickButton->Void, ?onDown:QuickButton->Void)
	{
		super();

		bg = new FlxSprite().makeColor(width, height, 0xFFFFFFFF);
		bg.alpha = 0.5;
		add(bg);

		button = new QuickButton(onUp, onDown);
		button.makeColor(width, height, 0xFFD8DAF6);
		button.alpha = 0;
		button.changeScale = false;
		button.maxScale = 1;
		button.minScale = 1;
		add(button);

		button.onHover.add((btn) ->
		{
			btn.alpha = 0.2;
		});
		button.onOut.add((btn) ->
		{
			btn.alpha = 0;
		});

		text = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
		text.color = 0xFFFFFFFF;
		text.alignment = (center ? CENTER : LEFT);
		text.text = label;
		text.scale.set(0.625, 0.625);
		text.updateHitbox();
		text.setPosition((center ? button.x + (button.width / 2) - (text.width / 2) : button.x + 2), button.y + ((button.height / 2) - (text.height / 2)));
		add(text);
	}

	public var selected(default, set):Bool;

	public function set_selected(b:Bool):Bool
	{
		selected = b;
		text.color = (selected ? 0xFF20222D : 0xFFD8DAF6);
		bg.color = (selected ? 0xFFD8DAF6 : 0xFF000000);
		bg.alpha = (selected ? 1 : 0.5);
		return selected;
	}
}

class ChooserButton extends FlxSpriteGroup
{
	var _label:FlxBitmapText;

	public var button:QuickButton;

	public function new(label:String, width:Int = 318, height:Int = 22, ?onUp:QuickButton->Void, ?onDown:QuickButton->Void)
	{
		super();

		button = new QuickButton(onUp, onDown);
		button.makeGraphic(width, height, 0xFFD8DAF6);
		button.alpha = 0;
		button.maxScale = 1;
		button.minScale = 1;
		button.changeScale = false;
		button.onDisable.add((b) ->
		{
			if (b.disabled)
				b.alpha = 0;
		});
		add(button);

		button.onHover.add((btn) ->
		{
			btn.alpha = 0.2;
		});
		button.onOut.add((btn) ->
		{
			btn.alpha = 0;
		});

		_label = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
		_label.color = 0xFFFFFFFF;
		_label.alignment = CENTER;
		_label.text = label;
		_label.scale.set(0.625, 0.625);
		_label.updateHitbox();
		_label.setPosition(button.x + ((button.width / 2) - (_label.width / 2)), button.y + ((button.height / 2) - (_label.height / 2)));
		add(_label);
	}
}
