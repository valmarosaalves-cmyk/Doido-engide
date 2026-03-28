package doido.objects.ui;

import flixel.group.FlxGroup;
import states.editors.ChartingState;
import doido.objects.ui.QuickButton.BoxLabel;
import doido.objects.ui.DoidoWindow.BaseWindow;

class DoidoBox extends FlxGroup
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

	public function new(x:Float = 0, y:Float = 0, width:Float = 100, buttonHeight:Float = 20, tabs:Array<BaseWindow>, chartState:ChartingState)
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
			addButton(tabs[i].title, i);

		toggleButtons();
	}

	inline function toggleButtons()
	{
		for (button in buttons)
			button.selected = (cur == button.ID);
	}

	function addButton(title:String, i:Int)
	{
		var newBtn = new BoxLabel(title, buttonWidth, buttonHeight, (btn) ->
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
}
