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
import doido.utils.EditorUtil;

enum MenuObjects
{
	BUTTON;
	SEPARATOR;
}

class ChooserWindow extends BaseWindow
{
	public var x:Float;
	public var y:Float;
	public var width:Int;
	public var height:Int;
	public var filter(default, set):String;

	var spacing:Int = 12;
	var buttonHeight:Int = 40;
	var bottom:Int = 0;

	var buttons:Array<ChooserButton> = [];
	var slider:DoidoSlider;
	var options(default, set):Array<String>;
	var filtered:Array<String> = [];
	var noScroll(get, never):Bool;

	public function new(x:Float = 0, y:Float = 0, width:Int = 440, height:Int = 185, chartState:ChartingState)
	{
		super(chartState);
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		@:bypassAccessor filter = "";

		options = ["bba", "a", "ba", "c", "d", "e", "f", "g", "h"];

		bg.scale.set(width, height);
		bg.updateHitbox();
		bg.x = x;
		bg.y = y;

		slider = new DoidoSlider(bg.x + bg.width - 18 - spacing, bg.y + spacing, 18, height - (spacing * 2), 0, 0, 1, 0, 0, true, true);
		slider.bar.color = 0xFF000000;
		slider.onScrub.add((b) ->
		{
			yOffset = slider.value;
			updateButtons();
		});
		add(slider);

		buildButtons();
	}

	function buildButtons()
	{
		for (button in buttons)
			button.kill();

		buttons = [];

		for (i in 0...filtered.length)
		{
			var button:ChooserButton = new ChooserButton(filtered[i], width - 40 - spacing, buttonHeight, (btn) -> Logs.print('click ${options[i]}'));
			button.x = x + spacing;
			button.ID = i;
			buttons.push(button);
			add(button);
		}

		yOffset = 0;
		bottom = (buttonHeight * filtered.length) + (2 * spacing) - height;
		slider.rangeMax = bottom;
		updateButtons();
	}

	var yOffset:Float = 0;

	function updateButtons()
	{
		yOffset = (noScroll ? 0 : FlxMath.bound(yOffset, 0, bottom));
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

		if (overlapping && !noScroll)
		{
			if (FlxG.mouse.wheel != 0)
			{
				yOffset -= FlxG.mouse.wheel * 32;
				updateButtons();
				slider.value = yOffset;
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

	public function set_filter(s:String)
	{
		filter = s;
		filtered = EditorUtil.doidoSearch(options, filter);
		buildButtons();
		return filter;
	}

	public function set_options(a:Array<String>)
	{
		options = a;
		filtered = EditorUtil.doidoSearch(options, filter);
		return options;
	}

	function get_noScroll()
	{
		return bottom <= bg.y;
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
