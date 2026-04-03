package doido.utils;

typedef SkinData =
{
	var notes:NoteSkin;
}

typedef NoteSkin =
{
	var ?anim:String; // generic
	var ?anims:Array<SkinAnim>; // specific
}

typedef SkinAnim =
{
    var id:Int;
	var name:String;
	var prefix:String;
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

		if (tempSkin.notes.anim != null)
		{
			for (i in 0...NoteUtil.directions.length)
                for(anim in ["note", "hold", "end"])
				    noteAnims[i].set(anim, parseAnimation(tempSkin.notes.anim, i, getState(anim)));
		}

        if(tempSkin.notes.anims != null)
            for(anim in tempSkin.notes.anims)
                noteAnims[anim.id].set(anim.name, parseAnimation(anim.prefix, anim.id, getState(anim.name)));

		trace(noteAnims);
	}

	function parseAnimation(str:String, id:Int, state:String):String
	{
		var newstr = str;
		var vals = [
			"%id" => Std.string(id),
			"%direction" => NoteUtil.directions[id],
			"%state" => state,
			"%color" => colors[id]
		];

		for (key => value in vals)
			newstr = newstr.replace(key, value);

		return newstr;
	}

    function getState(name:String)
    {
        return switch(name) {
            case "hold": " hold";
            case "holdend" | "hold end" | "end": " hold end";
            default: "";
        }
    }

	// note: implement support for other direction counts later
	var colors(get, never):Array<String>;

	function get_colors():Array<String>
		return ["purple", "blue", "green", "red"];
}
