package doido.utils;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;

class SpriteUtil
{
	public static function makeColor(spr:FlxSprite, width:Float, height:Float, ?color:FlxColor):FlxSprite
	{
		if (color == null)
			color = FlxColor.WHITE;
		spr.makeGraphic(1, 1, color);
		spr.antialiasing = false;
		spr.scale.set(width, height);
		spr.updateHitbox();
		return spr;
	}

	public static function makeGradient(spr:FlxSprite, width:Float, height:Float, colors:Array<FlxColor>, chunkSize:UInt = 1, rotation:Int = 90,
			interpolate:Bool = true):FlxSprite
	{
		if (colors.length == 0)
			colors = [FlxColor.WHITE];
		if (colors.length == 1)
			return makeColor(spr, width, height, colors[0]);

		spr = FlxGradient.createGradientFlxSprite(Math.floor(width), Math.floor(height), colors, chunkSize, rotation, interpolate);
		return spr;
	}

	public static function loadImage(spr:FlxSprite, key:String, animated:Bool = false, frameWidth:Int = 0, frameHeight:Int = 0):FlxSprite
	{
		spr.loadGraphic(Assets.image(key), animated, frameWidth, frameHeight);
		return spr;
	}

	public static function loadSparrow(spr:FlxSprite, key:String):FlxSprite
	{
		spr.frames = Assets.sparrow(key);
		return spr;
	}

	public static function loadMultiSparrow(spr:FlxSprite, key:String, extraSheets:Array<String>):FlxSprite
	{
		spr.frames = Assets.multiSparrow(key, extraSheets);
		return spr;
	}

	public static function loadPacker(spr:FlxSprite, key:String):FlxSprite
	{
		spr.frames = Assets.packer(key);
		return spr;
	}

	public static function loadAseprite(spr:FlxSprite, key:String):FlxSprite
	{
		spr.frames = Assets.aseprite(key);
		return spr;
	}

	public static function spriteCenter(spr:FlxSprite):FlxSprite
	{
		spr.updateHitbox();
		spr.offset.x += spr.frameWidth * spr.scale.x / 2;
		spr.offset.y += spr.frameHeight * spr.scale.y / 2;
		return spr;
	}

	public static function clipToSprite(spr:FlxSprite, objects:Array<FlxSprite>):FlxSprite
    {
		var clipRect = (spr.clipRect ?? new flixel.math.FlxRect());
		clipRect.x = clipRect.y = 0;
		clipRect.width = spr.frameWidth;
		clipRect.height = spr.frameHeight;
		
        for(object in objects)
        {
			var sprX:Float = spr.x;
			var sprY:Float = spr.y;
			
            if(sprX < object.x)
                clipRect.x += object.x - sprX;
            if(sprX + spr.width > object.x + object.width)
                clipRect.width -= (sprX + spr.width) - (object.x + object.width);
            if(sprY < object.y)
                clipRect.y += (object.y - sprY) / spr.scale.y;
            if(sprY + spr.height > object.y + object.height)
                clipRect.height -= ((sprY + spr.height) - (object.y + object.height)) / spr.scale.y;
        }
        spr.clipRect = clipRect;
		return spr;
    }
}
