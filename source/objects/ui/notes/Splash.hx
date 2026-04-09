package objects.ui.notes;

import doido.song.Timings;
import objects.ui.notes.Note;
import shaders.RGBPalette;

class Splash extends BaseSplash
{
	override public function reloadSplash()
	{
		clearOffsets();
		var direction:String = NoteUtil.intToString(note.data.lane);
		var hasRgb:Bool = false;
		rgb = skin.endsWith("-quant");

		switch (skin.replace("-quant", ""))
		{
			case "pixel" | "pixel-quant" | "pixel-rgb":
				var frameArr:Array<Int> = [0, 1, 2, 3, 4, 5];

				if (!rgb)
				{
					for (i in 0...frameArr.length)
					{
						frameArr[i] *= 4;
						frameArr[i] += note.data.lane;
					}
				}

				this.loadImage('notes/pixel/${rgb ? 'quant/' : ''}splashes', true, 33, 33);
				for (i in 0...2)
					animation.add('splash$i', frameArr, 18, false, (i == 1));
				splashScale = 6;
				antialiasing = false;
				hasRgb = true;

			default:
				this.loadSparrow('notes/base/${rgb ? 'quant/' : ''}splashes');
				direction = rgb ? "" : direction + " ";

				for (i in 1...3)
				{
					animation.addByPrefix('splash$i', '${direction}splash $i', 24, false);
				}
				splashScale = 0.8;
				startAlpha = 0.8;
				hasRgb = true;
		}

		if (!hasRgb)
			rgb = false;
		if (!rgb || note == null)
			shader = null;
		else
		{
			if (shader != colorShader)
				shader = colorShader;

			var colorArray = note.rgbColors;
			colorShader.setColor(colorArray[0], colorArray[1], colorArray[2],);
		}

		super.reloadSplash();
		playRandom();
	}

	private function playRandom(play:Bool = false)
	{
		var animList = animation.getNameList();
		playAnim(animList[FlxG.random.int(0, animList.length - 1)], true);
		splashed = true;
	}
}

class Cover extends BaseSplash
{
	public var strum:StrumNote = null;

	override public function reloadSplash()
	{
		clearOffsets();
		var direction:String = NoteUtil.intToString(note.data.lane);
		var hasRgb:Bool = false;
		rgb = skin.endsWith("-quant");

		switch (skin.replace("-quant", ""))
		{
			case "pixel" | "pixel-quant" | "pixel-rgb":
				function getArr(arr:Array<Int>):Array<Int>
				{
					if (rgb)
						return arr;

					var format:Array<Int> = [];
					for (i in 0...arr.length)
						format[i] = (arr[i] * 4) + note.data.lane;
					return format;
				}

				var anims:Map<String, Array<Int>> = [
					"start" => getArr([0]),
					"loop" => getArr([1, 2, 3]),
					"splash" => getArr([4, 5, 6, 7, 8]),
				];

				trace(anims);

				this.loadImage('notes/pixel/${rgb ? 'quant/' : ''}covers', true, 33, 33);
				for (anim => frameArr in anims)
					animation.add(anim, frameArr, 18, (anim == "loop"));
				splashScale = 6;
				antialiasing = false;
				hasRgb = true;

			default:
				this.loadSparrow('notes/base/${rgb ? 'quant/' : ''}covers');
				direction = rgb ? "" : direction.toUpperCase();

				animation.addByPrefix("start", 'holdCoverStart$direction', 24, false);
				animation.addByPrefix("loop", 'holdCover${direction}0', 24, true);
				animation.addByPrefix("splash", 'holdCoverEnd$direction', 24, false);
				splashScale = 0.7;
				hasRgb = true;

				if (rgb)
					addOffset("splash", {x: -6, y: -16});
				else
				{
					for (anim in ["start", "loop", "splash"])
						addOffset(anim, {x: 6, y: -32});
				}
		}

		if (!hasRgb)
			rgb = false;
		if (!rgb || note == null)
			shader = null;
		else
		{
			if (shader != colorShader)
				shader = colorShader;

			var colorArray = note.rgbColors;
			colorShader.setColor(colorArray[0], colorArray[1], colorArray[2]);
		}

		super.reloadSplash();
		playAnim("start");
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (strum != null)
		{
			setPosition(strum.x, strum.y);
			if (strum.animation.curAnim.name != "confirm" || note.holdHitPercent >= 1.0)
			{
				if (animation.curAnim.name != "splash")
				{
					// trace(note.holdHitPercent);
					if (note.holdHitPercent < Timings.timings.get("sick").hold)
						kill();
					else
						playAnim("splash");
				}
			}
		}

		if (animation.finished)
		{
			switch (animation.curAnim.name)
			{
				case "start":
					playAnim('loop');
				case "splash":
					splashed = true;
			}
		}
	}
}

class BaseSplash extends DoidoSprite
{
	public var startAlpha:Float = 1.0;
	public var splashScale:Float = 1.0;
	public var splashed:Bool = false;
	public var note:Note;
	public var skin:String;

	public var rgb:Bool = false;
	public var colorShader:RGBPalette;

	public function new()
	{
		super();
		colorShader = new RGBPalette();
	}

	public function loadData(note:Note, skin:String)
	{
		this.skin = skin;
		visible = true;
		splashed = false;
		this.note = note;
	}

	public function reloadSplash()
	{
		alpha = startAlpha;
		scale.set(splashScale, splashScale);
		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (curAnimFinished && splashed)
			kill();
	}

	// offsets are set differently for splashes, since they're centered by default
	// multiple things break if you change it but be sure you update the hitbox and dont multiply the offsets by the scale
	override public function updateOffset()
	{
		updateHitbox();
		offset.x += frameWidth * scale.x / 2;
		offset.y += frameHeight * scale.y / 2;
		if (animOffsets.exists(curAnimName))
		{
			var daOffset = animOffsets.get(curAnimName);
			offset.x += daOffset.x;
			offset.y += daOffset.y;
		}
	}
}
