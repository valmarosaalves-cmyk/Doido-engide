package doido.song;

typedef WeekData = {
	var songs:Array<Array<String>>;
	var ?weekFile:String;
	var ?weekName:String;
	var ?chars:Array<String>;
	var ?freeplayOnly:Bool;
	var ?storyModeOnly:Bool;
	var ?diffs:Array<String>;
}

typedef WeekSong = {
    var song:String;
    var ?icon:String;
}

class Week
{
    var DEFAULT:WeekData = {
        songs: [],
        weekFile: "week1",
        weekName: "unknown",
        chars: ["dad", "bf", "gf"],
        freeplayOnly: false,
        storyModeOnly: false,
        diffs: ['easy', 'normal', 'hard']
    }
}