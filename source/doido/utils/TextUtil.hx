package doido.utils;

import flixel.text.FlxText;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;
import flixel.util.typeLimit.OneOfTwo;

class TextUtil
{
	public static function setOutline(text:OneOfTwo<FlxText, FlxBitmapText>, ?color:FlxColor, thickness:Float = 1.0)
	{
		if (color == null) color = FlxColor.BLACK;
		
		(cast text).borderStyle = OUTLINE; 
		(cast text).borderColor = color;
		(cast text).borderSize = thickness;
	}

	public static function floorPos(text:FlxText)
	{
		text.setPosition(
			Math.floor(text.x),
			Math.floor(text.y)
		);
	}
}