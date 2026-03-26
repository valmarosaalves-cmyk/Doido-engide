package doido.utils;

import flixel.math.FlxMath;

class LerpPoint
{
	public var tweening:Bool = false;
	public var point:DoidoPoint;

	var lerped:DoidoPoint;

	public function new(tweening:Bool = false)
	{
		this.tweening = tweening;
		point = {x: 0, y: 0};
		lerped = {x: 0, y: 0};
	}

	public function set(point:DoidoPoint)
		this.point = point;

	public function get(lerp:Float):DoidoPoint
	{
		if (!tweening)
			lerp = 1;
		lerped.x = FlxMath.lerp(lerped.x, point.x, lerp);
		lerped.y = FlxMath.lerp(lerped.y, point.y, lerp);
		return lerped;
	}
}
