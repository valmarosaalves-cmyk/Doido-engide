package doido.song.chart;

import doido.utils.NoteUtil;
import doido.song.chart.Legacy;

typedef DoidoSong = 
{
	var song:String;
	var CHART:DoidoChart;
	var EVENTS:DoidoEvents;
	var META:DoidoMeta;
}

typedef DoidoMeta =
{
    var ?player1:String;
    var ?player2:String;
    var ?gf:String;
    var ?stage:String;
    //var ?difficulties:Array<String>; // im not sure how im going to implement this...
}

typedef DoidoChart =
{
	var song:String; //you stay, for now...
	var notes:Array<NoteData>;
	var bpm:Float;
	var speed:Float;
}

typedef NoteData = {
	var stepTime:Float;
	var lane:Int;
	var strumline:Int;
    var type:String;
	var length:Float;
}

typedef DoidoEvents =
{
	var events:Array<EventData>;
}

typedef EventData =
{
	var name:String;
	var stepTime:Float;
	var data:Array<Dynamic>;
	//var isCamera:Bool;
}

class SongHandler
{
	/*public static final allEvents:Map<String, Dynamic> = [
		"BPM Change" => [],
		"BPM Tween" => [],

	];*/

	public static function loadSong(jsonInput:String, ?diff:String = "normal"):DoidoSong
		return parseSong(getChart(jsonInput, diff), loadEvents(jsonInput, diff), loadMeta(jsonInput, diff));

	public static function parseSong(rawChart:Dynamic, EVENTS:DoidoEvents, META:DoidoMeta):DoidoSong
	{
		var CHART:DoidoChart = null;
        if (!Std.isOfType(rawChart.song, String)) {
			CHART = Legacy.getChartFromLegacy(rawChart.song);
			EVENTS = mergeEvents(EVENTS, Legacy.getEventsFromLegacy(rawChart.song));
			META = mergeMetas(META, Legacy.getMetaFromLegacy(rawChart.song));
		}
		else
        	CHART = cast rawChart;

		return {
			song: CHART.song,
			CHART: formatChart(CHART),
			EVENTS: EVENTS,
			META: META
		};
	}

	inline public static function loadChart(jsonInput:String, ?diff:String = "normal"):DoidoChart
	{
		var rawChart:Dynamic = cast getChart(jsonInput, diff);
		var CHART:DoidoChart = null;
		
        if (!Std.isOfType(rawChart.song, String))
            CHART = Legacy.getChartFromLegacy(rawChart.song);
		else
        	CHART = cast rawChart;

        return formatChart(CHART);
	}

    inline public static function getChart(jsonInput:String, ?diff:String = "normal"):Dynamic
	{		
		Logs.print('Chart Loaded: ' + '$jsonInput/$diff');

		if(!Assets.fileExists('songs/$jsonInput/chart/$diff.json'))
			diff = "normal";

		return Assets.json('songs/$jsonInput/chart/$diff');
	}

	inline public static function loadEvents(jsonInput:String, ?diff:String = "normal"):DoidoEvents
	{
		var eventPath:String = 'songs/$jsonInput/chart/events-$diff';
		if(!Assets.fileExists('$eventPath.json'))
			eventPath = eventPath.replace('-$diff', "");
		
		if(!Assets.fileExists('$eventPath.json'))
		{
			Logs.print('Events not found: ${eventPath}');
			return {events:[]};
		}

		Logs.print('Events Loaded: ' + '$jsonInput/$eventPath');

		return formatEvents(cast Assets.json(eventPath));
	}

	inline public static function loadMeta(jsonInput:String, ?diff:String = "normal"):DoidoMeta
	{
		var meta:DoidoMeta = {
			player1: "bf",
			player2: "face",
			gf: "gf",
			stage: "stage",
			//difficulties: ["normal"]
		};

		var metaPath:String = 'songs/$jsonInput/meta';
		if(Assets.fileExists('$metaPath.json'))
			meta = mergeMetas(meta, cast Assets.json(metaPath));
		if(Assets.fileExists('$metaPath-$diff.json'))
			meta = mergeMetas(meta, cast Assets.json('$metaPath-$diff'));
			
		return meta;
	}

    // Removes duplicated notes from a chart.
	inline private static function formatChart(CHART:DoidoChart):DoidoChart
	{
		// Normalize song name to use only lowercases and no spaces
		CHART.song = CHART.song.toLowerCase();
		if(CHART.song.contains(' '))
			CHART.song = CHART.song.replace(' ', '-');

		// cleaning multiple notes at the same place
		var removed:Int = 0;
		for(note in CHART.notes)
		{
			for(doubleNote in CHART.notes)
			{
				if(note != doubleNote
				&& note.strumline == doubleNote.strumline
                && note.stepTime == doubleNote.stepTime
                && note.lane == doubleNote.lane)
				{
					CHART.notes.remove(doubleNote);
					removed++;
				}
			}
		}
		if(removed > 0)
			Logs.print('removed $removed duplicated notes');

		/*if(SONG.gfVersion == null)
			SONG.gfVersion = "stage-set";*/

		CHART.notes.sort(NoteUtil.sortNotes);
		
		return CHART;
	}

	inline private static function formatEvents(EVENTS:DoidoEvents):DoidoEvents
	{
		EVENTS.events.sort(NoteUtil.sortEvents);
		return EVENTS;
	}

	static function mergeEvents(a:DoidoEvents, b:DoidoEvents):DoidoEvents
		return {events: a.events.concat(b.events)};

	static function mergeMetas(a:DoidoMeta, b:DoidoMeta):DoidoMeta {
        var meta:DoidoMeta = {};
        meta.player1 = (b.player1 ?? a.player1);
        meta.player2 = (b.player2 ?? a.player2);
        meta.gf = (b.gf ?? a.gf);
        meta.stage = (b.stage ?? a.stage);
        //meta.difficulties = (b.difficulties ?? a.difficulties);
        return meta;
    }
}