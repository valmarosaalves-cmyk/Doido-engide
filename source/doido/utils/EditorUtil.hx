package doido.utils;

import lime.app.Application;
import lime.ui.MouseCursor;

class EditorUtil
{
	/*
		ARROW
		CROSSHAIR
		DEFAULT
		MOVE
		POINTER
		RESIZE_NESW
		RESIZE_NS
		RESIZE_NWSE
		RESIZE_WE
		TEXT
		WAIT
		WAIT_ARROW
		CUSTOM
	 */
	public static function setCursor(newCursor:MouseCursor)
	{
		if (Application.current.window.cursor != newCursor)
			Application.current.window.cursor = newCursor;
	}

	public static function doidoSearch(arr:Array<String>, filter:String):Array<String>
	{
		var filtered:Array<String> = [];

		for(str in arr)
			if(str.toLowerCase().indexOf(filter.toLowerCase()) != -1)
				filtered.push(str);

		filtered.sort(function(a, b) return a.toLowerCase().indexOf(filter.toLowerCase()) - b.toLowerCase().indexOf(filter.toLowerCase()));

		return filtered;
	}
}
