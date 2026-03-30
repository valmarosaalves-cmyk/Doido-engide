package doido.objects.system;

import haxe.Timer;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.display.Sprite;
import flixel.util.FlxStringUtil;

class FPSCounter extends Sprite
{
	@:noCompletion private var times:Array<Float>;
	@:noCompletion private var deltaTimeout:Float = 0.0;

	var fpsField:CounterField;
	var labelField:CounterField;
	var memField:CounterField;

	// Use this if you want to add a watermark to the counter!
	var watermark:String = "";
	var taskMem:Bool = false;

	public function new(x:Float = 0, y:Float = 0)
	{
		super();
		this.x = x;
		this.y = y;

		fpsField = new CounterField(x, y, 22, 100, "", Main.globalFont, 0xFFFFFF);
		addChild(fpsField);

		labelField = new CounterField(x - 30, y + 9, 12, 100, "FPS", Main.globalFont, 0xFFFFFF);
		addChild(labelField);

		memField = new CounterField(x, y + 21, 14, 300, "", Main.globalFont, 0xFFFFFF);
		addChild(memField);

		visible = Save.data.fpsCounter;
		// watermark = 'DE-Pudim ${Main.internalVer}';

		times = [];
	}

	private override function __enterFrame(deltaTime:Float)
	{
		if (!visible)
			return;

		if (FlxG.mouse.visible)
		{
			// using Lib.current.mouse instead of FlxG.mouse
			// so the position is consistent in every resolution
			if (openfl.Lib.current.mouseX < 92 && openfl.Lib.current.mouseY < 62)
				alpha = 0.0;
			else if (alpha < 1.0)
				alpha += 0.2 * FlxG.elapsed;
		}
		else
			alpha = 1.0;

		final now:Float = Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000)
			times.shift();

		// prevents the overlay from updating every frame, why would you need to anyways @crowplexus
		if (deltaTimeout < 50)
		{
			deltaTimeout += deltaTime;
			return;
		}

		var fps:Int = times.length;
		if (fps > FlxG.updateFramerate)
			fps = FlxG.updateFramerate;

		fpsField.text = '$fps';
		labelField.x = fpsField.x + fpsField.getLineMetrics(0).width + 5;

		memField.text = FlxStringUtil.formatBytes(System.totalMemoryNumber);

		#if windows
		if (taskMem)
			memField.text == '\n${FlxStringUtil.formatBytes(doido.system.Windows.getMem())}';
		#end

		#if debug
		memField.text += '\n${Type.getClassName(Type.getClass(FlxG.state))}';
		#end

		memField.text += '\n${watermark}';

		if (fps < 30 || fps > 360)
			fpsField.textColor = 0xFF0000;
		else
			fpsField.textColor = 0xFFFFFF;

		graphics.clear();

		var bgWidth:Float = Math.max(fpsField.textWidth + labelField.textWidth + 5, memField.textWidth) + 20;
		var bgHeight:Float = memField.y + memField.textHeight + 16;

		// draw background
		graphics.beginFill(0x000000, 0.5);
		graphics.drawRoundRect(x - 6, y - 6, bgWidth, bgHeight, 6, 6);
		graphics.endFill();
	}
}

class CounterField extends TextField
{
	public function new(x:Float = 0, y:Float = 0, size:Int = 14, width:Float = 0, initText:String = "", font:String = "", color:Int = 0xFFFFFF)
	{
		super();
		this.x = x;
		this.y = y;
		this.text = initText;

		if (width != 0)
			this.width = width;

		selectable = false;
		defaultTextFormat = new TextFormat(font, size, color);
	}
}
