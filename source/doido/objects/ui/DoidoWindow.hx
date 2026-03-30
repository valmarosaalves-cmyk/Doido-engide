package doido.objects.ui;

import doido.objects.ui.QuickButton.ChooserButton;
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

	var buttons:Array<ChooserButton> = [];
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
			var button:ChooserButton = new ChooserButton(options[i], width, 40);
			button.x = x;
			button.ID = i;
			buttons.push(button);
			add(button);
		}

		updateButtons();
	}

	function updateButtons()
	{
		for (button in buttons)
		{
			button.y = y + (40 * button.ID);
			for (item in button.members)
				setClip(item);
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		/*if (overlapping)
		{
			updateButtons();
		}*/
	}

	function setClip(sprite:FlxSprite)
	{
		var newx:Float = x - sprite.x;
		var newy:Float = y - sprite.y;
		var newwidth:Float = (x + width - sprite.x) - newx;
		var newheight:Float = (y + height - sprite.y) - newy;
		sprite.clipRect = new FlxRect(newx, newy, newwidth, newheight);
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
