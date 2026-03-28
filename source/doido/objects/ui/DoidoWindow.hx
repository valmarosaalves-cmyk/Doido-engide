package doido.objects.ui;

import flixel.group.FlxGroup;
import doido.objects.ui.QuickButton.MenuButton;
import states.editors.ChartingState;
import flixel.FlxSprite;

enum MenuObjects
{
	BUTTON;
	SEPARATOR;
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

class BaseWindow extends FlxGroup
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
}
