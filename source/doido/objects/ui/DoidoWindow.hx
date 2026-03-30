package doido.objects.ui;

import doido.objects.ui.QuickButton.ChooserButton;
import doido.objects.ui.DoidoSlider;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import doido.objects.ui.QuickButton.MenuButton;
import states.editors.ChartingState;
import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.math.FlxMath;

enum MenuObjects
{
	BUTTON;
	SEPARATOR;
}

class ChooserWindow extends BaseWindow
{
	public var x:Float;
	public var y:Float;
	public var width:Float;
	public var height:Float;

	var spacing:Int = 12;
	var buttonHeight:Int = 40;
	var bottom:Int = 0;

	var buttons:Array<ChooserButton> = [];
	var slider:DoidoSlider;
	var options:Array<String> = ["thing1", "thing2", "thing3", "thing4", "thing5", "thing6", "thing7", "thing8"];

	public function new(x:Float = 0, y:Float = 0, width:Int = 440, height:Int = 185, chartState:ChartingState)
	{
		super(chartState);
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;

		bg.scale.set(width, height);
		bg.updateHitbox();
		bg.x = x;
		bg.y = y;

		for (i in 0...options.length)
		{
			var button:ChooserButton = new ChooserButton(options[i], width - 40 - spacing, buttonHeight, (btn) -> Logs.print('click ${options[i]}'));
			button.x = x + spacing;
			button.ID = i;
			buttons.push(button);
			add(button);
		}

		bottom = (buttonHeight * options.length) + (2 * spacing) - height;

		slider = new DoidoSlider(bg.x + bg.width - 18 - spacing, bg.y + spacing, 18, height - (spacing * 2), 0, 0, bottom, 0, 0, true, true);
		slider.bar.color = 0xFF000000;
		slider.onScrub.add((b) ->
		{
			yOffset = slider.value;
			updateButtons();
		});
		add(slider);

		updateButtons();
	}

	var yOffset:Float = 0;

	function updateButtons()
	{
		for (button in buttons)
		{
			button.y = y + spacing + (40 * button.ID) - yOffset;
			for (item in button.members)
				setClip(item);
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		for (button in buttons)
			button.button.disabled = !overlapping;

		if (overlapping)
		{
			if (FlxG.mouse.wheel != 0)
			{
				yOffset -= FlxG.mouse.wheel * 32;
				yOffset = FlxMath.bound(yOffset, 0, bottom);
				slider.value = yOffset;
				updateButtons();
			}
		}
	}

	function setClip(sprite:FlxSprite)
	{
		var newx:Float = x - sprite.x;
		var newy:Float = y - sprite.y;
		var newwidth:Float = (x + width - sprite.x) - newx;
		var newheight:Float = (y + height - sprite.y) - newy;
		sprite.clipRect = new FlxRect(newx / sprite.scale.x, newy / sprite.scale.y, newwidth / sprite.scale.x, newheight / sprite.scale.y);
	}
}

class MenuWindow extends BaseWindow
{
	public var buttons:Array<MenuButton> = [];
	public var separators:Array<FlxSprite> = [];

	var width:Float = 0;
	var yOffset:Float = 0;

	public function new(x:Float = 0, y:Float = 0, width:Float = 100, chartState:ChartingState)
	{
		super(chartState);
		this.width = width;
		bg.setPosition(x, y);
	}

	public function updateBg()
	{
		bg.scale.set(width, yOffset);
		bg.updateHitbox();
	}

	public function addButton(label:String, ?bind:String, ?func:QuickButton->Void)
	{
		var newBtn = new MenuButton(label, bind, width, func);
		buttons.push(newBtn);
		add(newBtn);

		newBtn.x = bg.x;
		newBtn.y = bg.y + yOffset;
		yOffset += newBtn.height;
	}

	public function addSeparator()
	{
		var separator:FlxSprite = new FlxSprite().makeColor(width, 3, 0xFF000000);
		separator.alpha = 0.5;
		add(separator);

		separator.x = bg.x;
		separator.y = bg.y + yOffset;
		yOffset += separator.height;
	}
}

class BaseWindow extends FlxGroup implements IWindow
{
	public var chartState:ChartingState;
	public var bg:FlxSprite;
	public var title:String = "";

	public function new(chartState:ChartingState)
	{
		super();
		this.chartState = chartState;

		bg = new FlxSprite().makeColor(100, 100, 0xFF000000);
		bg.alpha = 0.5;
		add(bg);
	}

	public var overlapping(get, never):Bool;

	public function get_overlapping():Bool
		return FlxG.mouse.overlaps(bg);
}

interface IWindow
{
	var overlapping(get, never):Bool;
}
