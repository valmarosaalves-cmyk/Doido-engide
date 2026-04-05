package doido.objects.ui;

import doido.objects.ui.DoidoWindow.IWindow;
import flixel.group.FlxGroup;
import states.editors.ChartingState;
import doido.objects.ui.QuickButton.BoxLabel;
import doido.objects.ui.DoidoWindow.BaseWindow;

class DoidoBox extends FlxGroup implements IWindow
{
	public var chartState:ChartingState;
	public var tabs:Array<BaseWindow> = [];
	public var buttons:Array<BoxLabel> = [];

	public var x:Float = 0;
	public var y:Float = 0;
	public var width:Float = 0;
	public var buttonWidth:Float = 0;
	public var buttonHeight:Float = 0;

	var cur:Int = -1;
	var spacing:Float = 5;

	public function new(x:Float = 0, y:Float = 0, width:Float = 100, buttonHeight:Float = 20, startingTab:Int = -1, centerButtons:Bool = true,
			tabs:Array<BaseWindow>, chartState:ChartingState)
	{
		super();
		this.x = x;
		this.y = y;
		this.width = width;
		this.buttonHeight = buttonHeight;

		this.tabs = tabs;
		this.chartState = chartState;

		buttonWidth = (width - ((tabs.length - 1) * spacing)) / tabs.length;
		for (i in 0...tabs.length)
			addButton(tabs[i].title, i, centerButtons);

		cur = startingTab;
		toggleButtons();
	}

	inline function toggleButtons()
	{
		for (button in buttons)
			button.selected = (cur == button.ID);
	}

	function addButton(title:String, i:Int, centerButtons:Bool)
	{
		var newBtn = new BoxLabel(title, buttonWidth, buttonHeight, centerButtons, (btn) ->
		{
			cur = (cur == i ? -1 : i);
			toggleButtons();
		});
		newBtn.ID = i;
		buttons.push(newBtn);
		add(newBtn);

		newBtn.x = x + i * (buttonWidth + spacing);
		newBtn.y = y;
	}

	override function draw()
	{
		super.draw();

		if (tabs[cur] != null)
			tabs[cur].draw();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (tabs[cur] != null)
			tabs[cur].update(elapsed);
	}

	public var overlapping(get, never):Bool;

	public function get_overlapping():Bool
	{
		for (button in buttons)
		{
			if (FlxG.mouse.overlaps(button, FlxG.cameras.list[FlxG.cameras.list.length - 1]))
				return true;
		}

		if (tabs[cur] != null)
			return tabs[cur].overlapping;

		return false;
	}
}
