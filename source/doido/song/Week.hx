package doido.song;

typedef WeekData = {
	var songs:Array<WeekSong>;
	var ?weekFile:String;
	var ?weekName:String;
	var ?chars:Array<String>;
    var ?diffs:Array<String>;
	var ?freeplayOnly:Bool;
	var ?storyModeOnly:Bool;
}

typedef WeekSong = {
    var song:String;
    var ?icon:String;
}

typedef WeekOrder = {
    var order:Array<String>;
}

class Week
{
    public static var DEFAULT:WeekData = {
        songs: [],
        weekFile: "week1",
        weekName: "unknown",
        chars: ["dad", "bf", "gf"],
        freeplayOnly: false,
        storyModeOnly: false,
        diffs: ['easy', 'normal', 'hard']
    }

    public static function weekList(storyMode:Bool = false, freeplay:Bool = true):Array<WeekData> {
        var order:WeekOrder = {order: []};
        var list:Array<WeekData> = [];

        try {
            order = cast Assets.json('data/weeks/order');
        }
        catch(e) {
            Logs.print('WEEK ORDER LOAD ERROR: $e');
            order.order = Assets.list("data/weeks/", true, ["order"], JSON);
        }

        for(week in order.order) {
            var rawWeek:WeekData = loadWeek(week);
            if ((!rawWeek.storyModeOnly || storyMode) && (!rawWeek.freeplayOnly || freeplay) && rawWeek.songs.length > 0)
                list.push(rawWeek);
        }

        return list;
    }

    public static function loadWeek(week:String):WeekData {
        var newWeek:WeekData;
        try {
            newWeek = cast(Assets.json('data/weeks/$week'));
        }
        catch(e) {
            Logs.print('WEEK $week LOAD ERROR: $e', ERROR);
            newWeek = DEFAULT;
        }

        newWeek.weekFile = newWeek.weekFile ?? DEFAULT.weekFile;
        newWeek.weekName = newWeek.weekName ?? DEFAULT.weekName;

        newWeek.chars = newWeek.chars ?? DEFAULT.chars;
        newWeek.diffs = newWeek.diffs ?? DEFAULT.diffs;

        newWeek.freeplayOnly = newWeek.freeplayOnly ?? DEFAULT.freeplayOnly;
        newWeek.storyModeOnly = newWeek.storyModeOnly ?? DEFAULT.storyModeOnly;
        
        return newWeek;
    }
}