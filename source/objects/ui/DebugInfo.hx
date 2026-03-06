package objects.ui;

import doido.song.Conductor;
import flixel.group.FlxGroup;
import flixel.text.FlxBitmapText;

using doido.utils.TextUtil;

class DebugInfo extends FlxGroup
{
	public var daText:FlxBitmapText;
	public var curState:MusicBeatState;
	
	public function new(curState:MusicBeatState)
	{
		super();
		this.curState = curState;
		visible = false;

		daText = new FlxBitmapText(10, 0, Assets.bitmapFont("vcr"));
        daText.alignment = LEFT;
		daText.setOutline(0xFF000000, 1.5);
		daText.antialiasing = false;
		add(daText);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.keys.justPressed.F1) visible = !visible;
	}
	
	override function draw()
	{
		if (visible)
		{
			var text:String = "";
			text += "Time: " + Math.floor(Conductor.songPos / 1000 * 100) / 100;
			text += "\nStep: " + Math.floor(curState.curStepFloat * 100) / 100;
			text += "\nBeat: " + Math.floor(curState.curStepFloat / 4 * 100) / 100;
			text += "\nBPM: " + Math.floor(Conductor.bpm * 100) / 100;
			
			if (daText.text != text) {
				daText.text = text;
				daText.y = FlxG.height - daText.height - 10;
			}
		}
		super.draw();
	}
}