package doido.utils;

typedef DoidoPoint =
{
	var x:Float;
	var y:Float;
}

class MathUtil
{
	inline public static function intArray(end:Int, start:Int = 0):Array<Int>
	{
		if (start > end)
		{
			var oldStart = start;
			start = end;
			end = oldStart;
		}

		var result:Array<Int> = [];
		for (i in start...(end + 1))
			result.push(i);

		return result;
	}

	inline public static function addPoint(a:DoidoPoint, b:DoidoPoint):DoidoPoint
		return {x: a.x + b.x, y: a.y + b.y};

	inline public static function copyPoint(a:DoidoPoint):DoidoPoint
		return a == null ? {x: 0, y: 0} : {x: a.x, y: a.y};
}
