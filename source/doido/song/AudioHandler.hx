package doido.song;

import flixel.sound.FlxSound;

typedef AudioData =
{
	var stem:FlxSound;
	var variants:Array<String>;
}

// class for handling song files (Inst, Voices)
class AudioHandler
{
	// esse é que é o tal de "encapsulamento?"
	public var inst:FlxSound;
	public var voicesGlobal:FlxSound; // default
	public var voicesOpp:FlxSound; // if the opponent has a voices file, play them too

	public function new(song:String, diff:String = "normal")
	{
		reload(song, diff);
	}

	public function reload(song:String, diff:String = "normal")
	{
		if (diff == "nightmare")
			diff = "erect";

		if (!Assets.fileExists('songs/${song}/audio/Inst-$diff', SOUND))
			diff = "";
		else
			diff = '-$diff';

		inst = FlxG.sound.load(Assets.inst(song, diff));
		length = inst?.length;

		// global voices
		if (Assets.fileExists('songs/${song}/audio/Voices$diff-player', SOUND))
			voicesGlobal = FlxG.sound.load(Assets.voices(song, '$diff-player'));
		else if (Assets.fileExists('songs/${song}/audio/Voices$diff-$diff', SOUND))
			voicesGlobal = FlxG.sound.load(Assets.voices(song, diff));
		else
			voicesGlobal = null;

		if (voicesGlobal?.length < length)
			length = voicesGlobal.length;

		// opponent voices
		if (Assets.fileExists('songs/${song}/audio/Voices$diff-opp', SOUND))
			voicesOpp = FlxG.sound.load(Assets.voices(song, '$diff-opp'));
		else if (Assets.fileExists('songs/${song}/audio/Voices$diff-opponent', SOUND))
			voicesOpp = FlxG.sound.load(Assets.voices(song, '$diff-opponent'));
		else
			voicesOpp = null;

		if (voicesOpp?.length < length)
			length = voicesOpp.length;

		muteVoices = false;
	}

	private function update(func:(snd:FlxSound) -> Void)
	{
		func(inst);
		if (voicesGlobal != null)
			func(voicesGlobal);
		if (voicesOpp != null)
			func(voicesOpp);
	}

	public var resyncThreshold:Int = 30;

	public function sync()
	{
		if (Math.abs(Conductor.songPos - inst.time) >= resyncThreshold)
		{
			Logs.print('FIXING DELAYED CONDUCTOR: ${Conductor.songPos} > ${inst.time}', WARNING);
			Conductor.songPos = inst.time;
		}

		update((snd) ->
		{
			if (snd == inst)
				return;
			if (Math.abs(Conductor.songPos - snd.time) >= resyncThreshold)
			{
				Logs.print('FIXING DELAYED MUSIC: ${snd.time} > ${Conductor.songPos}', WARNING);
				update((fixSnd) ->
				{
					fixSnd.time = Conductor.songPos;
				});
			}
		});
	}

	public function play(?time:Float)
	{
		update((snd) ->
		{
			snd.play();
			if (time != null)
				snd.time = time;
		});
	}

	public function pause()
	{
		update((snd) ->
		{
			snd.pause();
		});
	}

	public var playing(get, never):Bool;

	function get_playing():Bool
	{
		return inst.playing;
	}

	public var time(default, set):Float = 0.0;

	public function set_time(v:Float)
	{
		// trace("before " + inst.time);
		time = v;
		update((snd) ->
		{
			snd.time = v;
		});
		sync();
		return speed;
	}

	public var length:Float = 0.0;

	public var speed(default, set):Float = 1.0;

	public function set_speed(v:Float)
	{
		speed = v;
		update((snd) ->
		{
			snd.pitch = v;
		});
		return speed;
	}

	public var muteVoices(default, set):Bool;
	public var muteOpponent(default, set):Bool;
	public var muteInst(default, set):Bool;

	function set_muteVoices(val:Bool):Bool
	{
		if (voicesGlobal != null)
			voicesGlobal.volume = (val ? 0.0 : 1.0);

		muteVoices = val;
		return val;
	}

	function set_muteOpponent(val:Bool):Bool
	{
		if (voicesOpp != null)
			voicesOpp.volume = (val ? 0.0 : 1.0);

		muteOpponent = val;
		return val;
	}

	function set_muteInst(val:Bool):Bool
	{
		if (inst != null)
			inst.volume = (val ? 0.0 : 1.0);

		muteInst = val;
		return val;
	}
}
