/*
package doido.utils;

import doido.objects.DoidoSprite.Animation;

typedef SkinData =
{
	var notes:SkinAnims;
	var ?strums:SkinAnims;
	var ?splashes:SkinAnims;
	var ?covers:SkinAnims;
}

typedef SkinAnims =
{
	var ?template:String; // generic
	var ?custom:Array<Animation>; // specific
}

class Skin
{
	public var skin:String = "base";

	public var noteAnims:Array<Map<String, String>> = [];
	public var strumAnims:Array<Map<String, String>> = [];
	public var splashAnims:Array<Map<String, String>> = [];
	public var coverAnims:Array<Map<String, String>> = [];

	public function new(skin:String = "base")
	{
		this.skin = skin;

		for (arr in [noteAnims, strumAnims, splashAnims, coverAnims])
			for (i in 0...NoteUtil.directions.length)
				arr[i] = [];

		loadData('data/notes/$skin');
	}

	function loadData(path:String)
	{
		var tempSkin:SkinData;

		try
		{
			tempSkin = cast(Assets.json('data/notes/$skin'));
		}
		catch (e)
		{
			Logs.print('SKIN $skin LOAD ERROR: $e', ERROR);
			return;
		}

		fillAnimMap(noteAnims, tempSkin.notes, ["note", "hold", "end"]);
		fillAnimMap(strumAnims, tempSkin.strums, ["static", "pressed", "confirm"]);
		fillAnimMap(splashAnims, tempSkin.splashes, ["splash"]);
		fillAnimMap(coverAnims, tempSkin.covers, ["start", "loop", "splash"]);

		trace(noteAnims);
		trace(strumAnims);
		trace(splashAnims);
		trace(coverAnims);
	}

	function fillAnimMap(target:Array<Map<String, String>>, source:SkinAnims, anims:Array<String>)
	{
		if (source.template != null)
		{
			for (i in 0...count)
				for (anim in anims)
					target[i].set(anim, parseAnimation(source.template, i, anim));
		}

		if (source.custom != null)
		{
			for (anim in source.custom)
				if (anim.id != null)
					target[anim.id].set(anim.name, parseAnimation(anim.prefix, anim.id, getState(anim.name)));
		}
	}

	function parseAnimation(str:String, id:Int, name:String):String
	{
		var newstr = str;
		var vals = [
			"%id" => Std.string(id),
			"%direction" => NoteUtil.directions[id],
			"%state" => getState(name),
			"%color" => colors[id]
		];

		for (key => value in vals)
			newstr = newstr.replace(key, value);

		return formatAnim(newstr);
	}

	function formatAnim(str:String):String
		return str.trim() + "0";

	function getState(name:String)
	{
		return switch (name)
		{
			case "hold": "hold";
			case "holdend" | "hold end" | "end": "hold end";
			case "note" | "loop": "";
			case "start": "Start";
			case "splash": "End";
			default: name;
		}
	}

	// note: implement support for other direction counts later
	var colors(get, never):Array<String>;
	var count(get, never):Int;

	function get_colors():Array<String>
		return ["purple", "blue", "green", "red"];

	function get_count():Int
		return NoteUtil.directions.length;
}
*/