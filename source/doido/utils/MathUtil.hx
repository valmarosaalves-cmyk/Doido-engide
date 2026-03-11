package doido.utils;

typedef DoidoPoint = {
    var x:Float;
    var y:Float;
}
class MathUtil
{
    inline public static function intArray(end:Int, start:Int = 0):Array<Int>
	{
		if(start > end) {
			var oldStart = start;
			start = end;
			end = oldStart;
		}
		
		var result:Array<Int> = [];
		for(i in start...(end + 1))
			result.push(i);

		return result;
	}
}