package objects.ui.notes;

import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import shaders.RGBPalette;

class StrumNote extends DoidoSprite
{
	public var lane:Int = 0;

	public var initialPos:FlxPoint = FlxPoint.get(0, 0);
	public var strumScale:Float = 1.0;
	public var strumAngle:Float = 0.0;
	
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

	public function reloadStrum(lane:Int)
	{
		this.lane = lane;
		this.strumScale = 1.0;

		var direction:String = NoteUtil.intToString(lane);

		switch ("ill do it later")
		{
			default:
				if (canQuant) {
					this.loadSparrow("notes/base/quant/strums");
				} else {
					this.loadSparrow("notes/base/strums");
					shader = null;
				}

				for (anim in ["static", "pressed", "confirm"])
					animation.addByPrefix(anim, 'strum $direction $anim', 24, false);

				strumScale = 0.7;
		}

		if (canQuant) getQuantColors("base");
		scale.set(strumScale, strumScale);
		updateHitbox();
		playAnim("static");
	}

	override function playAnim(animName:String, forced:Bool = false, frame:Int = 0)
	{
		if (canQuant)
		{
			if (animName == "static")
				shader = null;
			else {
				if (shader != quantShader)
					shader = quantShader;

				if (animName == "pressed")
					playConfirm(null);
			}
		}
		super.playAnim(animName, forced, frame);
	}

	public var quantModifier:String = "";
	public var quantColors:Array<Array<FlxColor>> = [];
	public function getQuantColors(quantModifier:String)
	{
		if (this.quantModifier == quantModifier) return;
		this.quantModifier = quantModifier;
		quantColors = NoteUtil.getQuantColors(quantModifier);
	}

	public function playConfirm(note:Note)
	{
		if (note != null) playAnim("confirm");
		if (!canQuant) return;

		var colorArray:Array<FlxColor> = [];
		if (note == null)
			colorArray = quantColors[quantColors.length - 1];
		else	
			colorArray = note.quantColors[note.noteQuant];
		
		quantShader.setColor(
			colorArray[0],
			colorArray[1],
			colorArray[2],	
		);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updateOffset();
	}

	override function preUpdateOffset()
	{
		this.spriteCenter();
	}
}
