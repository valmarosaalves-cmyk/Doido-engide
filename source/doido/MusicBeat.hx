package doido;

import doido.Cache;
import doido.song.Conductor;
import doido.system.Screenshot;
import doido.objects.system.Transition;
import flixel.FlxCamera;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.ui.FlxUIState;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class MusicBeat
{
	public static var activeState:FlxState;
	public static var nextTransition:String = '';

	public static function switchState(?target:MusicBeatState, tOut:String = 'funkin', ?tIn:String)
	{
		#if SCREENSHOT_FEATURE Screenshot.clearScreenshot(); #end

		if (tIn != null)
			nextTransition = tIn;
		else
			nextTransition = tOut;

		var trans = new Transition(false, tOut);
		trans.finishCallback = function()
		{
			if (target != null)
				FlxG.switchState(() -> target);
			else
				FlxG.resetState();
		};

		if (skipTrans)
			return trans.finishCallback();

		if (activeState != null)
			activeState.openSubState(trans);
	}

	public static function resetState()
	{
		switchState(null);
	}

	public static var skipClearCache:Bool = false;
	public static var skipTrans:Bool = true;
	public static var skip(get, set):Bool;

	public static function get_skip()
		return skipTrans && skipClearCache;

	public static function set_skip(newSkip:Bool)
	{
		skipTrans = newSkip;
		skipClearCache = newSkip;
		return newSkip;
	}

	// for pausing timers and tweens
	public static function activateTimers(apple:Bool = true)
	{
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer)
		{
			if (!tmr.finished)
				tmr.active = apple;
		});

		FlxTween.globalManager.forEach(function(twn:FlxTween)
		{
			if (!twn.finished)
				twn.active = apple;
		});
	}

	public static function getTopCamera():FlxCamera
		return FlxG.cameras.list[FlxG.cameras.list.length - 1];
}

/*
	Custom state and substate classes. Use them instead of FlxState or FlxSubstate
 */
class MusicBeatState extends FlxUIState
{
	override function create()
	{
		super.create();
		flixel.FlxSprite.defaultAntialiasing = Save.data.antialiasing;
		MusicBeat.activeState = this;
		Logs.print('switched to ${Type.getClassName(Type.getClass(this))}');
		persistentDraw = true;
		persistentUpdate = false;
		FlxG.animationTimeScale = 1.0;

		Controls.setSoundKeys();

		if (!MusicBeat.skipClearCache)
			Cache.clearCache();

		Cache.pushAll();

		if (!MusicBeat.skipTrans)
			openSubState(new Transition(true, MusicBeat.nextTransition));

		MusicBeat.skip = false;

		curStepFloat = Conductor.getStepAtTime();
		curStep = _curStep = Math.floor(curStepFloat);

		setFpsPos();
	}

	override function openSubState(subState:FlxSubState)
	{
		Controls.inputDelay = 2;
		#if SCREENSHOT_FEATURE Screenshot.clearScreenshot(); #end
		super.openSubState(subState);
	}

	private var _curStep = 0; // actual curStep

	public var curStep = 0;
	public var curStepFloat:Float = 0;
	public var curBeat = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updateStep();
		// stopped working for some reason??
		/*if(FlxG.keys.justPressed.F5) {
			MusicBeat.skip = (!FlxG.keys.pressed.SHIFT);
			MusicBeat.resetState();
		}*/
	}

	private function updateStep()
	{
		curStepFloat = Conductor.getStepAtTime();
		_curStep = Math.floor(curStepFloat);

		while (_curStep != curStep)
			stepHit();
	}

	private function stepHit()
	{
		if (_curStep > curStep)
			curStep++;
		else
		{
			curStep = _curStep;
		}

		if (curStep % 4 == 0)
			beatHit();

		function loopGroup(group:FlxGroup):Void
		{
			if (group == null)
				return;
			for (item in group.members)
			{
				if (item == null)
					continue;
				if (Std.isOfType(item, FlxGroup))
					loopGroup(cast item);

				/*if(item._stepHit != null)
					item._stepHit(curStep); */
			}
		}
		loopGroup(this);
	}

	private function beatHit()
	{
		// finally you're useful for something
		curBeat = Math.floor(curStep / 4);
	}

	private function setFpsPos(x:Int = 5, y:Int = 5)
	{
		if (Main.fpsX != x || Main.fpsY != y)
			Main.setFpsPos(x, y);
	}
}

class MusicBeatSubState extends FlxSubState
{
	var subParent:FlxState;

	override function create()
	{
		super.create();
		subParent = MusicBeat.activeState;
		MusicBeat.activeState = this;
		persistentDraw = true;
		persistentUpdate = false;
		FlxG.animationTimeScale = 1.0;
		curStepFloat = Conductor.getStepAtTime();
		curStep = _curStep = Math.floor(curStepFloat);

		cameras = [MusicBeat.getTopCamera()];
	}

	override function close()
	{
		MusicBeat.activeState = subParent;
		super.close();
	}

	override function openSubState(subState:FlxSubState)
	{
		Controls.inputDelay = 2;
		#if SCREENSHOT_FEATURE Screenshot.clearScreenshot(); #end
		super.openSubState(subState);
	}

	private var _curStep:Int = 0; // actual curStep

	public var curStep:Int = 0;
	public var curStepFloat:Float = 0;
	public var curBeat:Int = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updateStep();
	}

	private function updateStep()
	{
		curStepFloat = Conductor.getStepAtTime();
		_curStep = Math.floor(curStepFloat);

		while (_curStep != curStep)
			stepHit();
	}

	private function stepHit()
	{
		if (_curStep > curStep)
			curStep++;
		else
		{
			curStep = _curStep;
		}

		if (curStep % 4 == 0)
			beatHit();

		function loopGroup(group:FlxGroup):Void
		{
			if (group == null)
				return;
			for (item in group.members)
			{
				if (item == null)
					continue;
				if (Std.isOfType(item, FlxGroup))
					loopGroup(cast item);

				/*if (item._stepHit != null)
					item._stepHit(curStep); */
			}
		}
		loopGroup(this);
	}

	private function beatHit()
	{
		// finally you're useful for something
		curBeat = Math.floor(curStep / 4);
	}
}
