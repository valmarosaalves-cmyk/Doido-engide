package objects.ui.notes;

import doido.song.Timings;
import objects.ui.notes.Note;
import shaders.RGBPalette;

class Splash extends BaseSplash
{
	override public function reloadSplash()
	{
		var direction:String = NoteUtil.intToString(note.data.lane);
		switch ("la la la")
		{
			default:
				if (canQuant) {
					this.loadSparrow("notes/base/quant/splashes");
					direction = "";
				} else {
					this.loadSparrow("notes/base/splashes");
					direction += " ";
				}
				for(i in 1...3) {
					animation.addByPrefix('splash$i', '${direction}splash $i', 24, false);
				}
				splashScale = 0.8;
				startAlpha = 0.8;
		}

		alpha = startAlpha;
		scale.set(splashScale, splashScale);
		updateHitbox();
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
	public var isPlayer:Bool = false;

	override public function reloadSplash()
	{
		var direction:String = NoteUtil.intToString(note.data.lane);
		switch ("la la la")
		{
			default:
				
				splashScale = 0.7;

				if(canQuant) {
					this.loadSparrow("notes/base/quant/covers");
					direction = "";
				} else {
					this.loadSparrow("notes/base/covers");
					direction = direction.toUpperCase();
				}
				
				animation.addByPrefix("start", 'holdCoverStart$direction', 24, false);
				animation.addByPrefix("loop", 'holdCover${direction}0', 24, true);
				animation.addByPrefix("splash", 'holdCoverEnd$direction', 24, false);

				if (canQuant)
					addOffset("splash", {x: -6, y: -16});
				else
				{
					for (anim in ["start", "loop", "splash"])
						addOffset(anim, {x: 6, y: -32});
				}
		}

		alpha = startAlpha;
		scale.set(splashScale, splashScale);
		updateHitbox();
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

	public var canQuant:Bool = false;
	public var quantShader:RGBPalette;

	public function new()
	{
		super();
		if (Save.data.quantNotes)
		{
			quantShader = new RGBPalette();
			canQuant = true;
		}
	}

	public function loadData(note:Note)
	{
		visible = true;
		splashed = false;
		this.note = note;

		if (!canQuant || note == null)
			shader = null;
		else
		{
			if (shader != quantShader)
				shader = quantShader;

			var colorArray = note.quantColors[note.noteQuant];
			quantShader.setColor(
				colorArray[0],
				colorArray[1],
				colorArray[2],	
			);
		}
	}

	public function reloadSplash() {}

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
