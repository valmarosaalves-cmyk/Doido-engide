package objects.ui.notes;

import flixel.util.FlxColor;
import shaders.RGBPalette;
import flixel.FlxSprite;
import doido.utils.NoteUtil.SkinData;

class Note extends FlxSprite
{
	// main data
	public var data:NoteData;
	public var gotHit:Bool = false;
	public var missed:Bool = false;

	// hold parenting
	public var holdParent:Note = null;
	public var children:Array<Note> = [];
	// hold data
	public var isHold:Bool = false;
	public var isHoldEnd:Bool = false;
	public var holdIndex:Float = -1;
	public var holdStep:Float = -1;
	public var holdHitPercent:Float = 0.0;

	// noteskin stuff
	public var noteScale:Float = 1.0;

	// modchart stuff
	public var noteAngle:Null<Float> = null;
	public var noteSpeed:Null<Float> = null;
	public var noteSpeedMult:Float = 1.0;

	//oop
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

	public function loadData(data:NoteData)
	{
		// visual stuff
		setPosition(-5000, -5000); // offscreen lol
		visible = true;
		alpha = 1.0;
		angle = 0;

		// main data
		this.data = data;
		gotHit = false;
		missed = false;

		// hold parenting
		holdParent = null;
		children = [];
		// hold stuff
		isHold = isHoldEnd = false;
		holdIndex = 0;
		holdStep = 0;
		holdHitPercent = 0.0;

		// noteskin stuff
		noteScale = 1.0;

		// modchart stuff
		noteAngle = null;
		noteSpeed = null;
		noteSpeedMult = 1.0;

		// noteSpeed = (FlxG.random.bool(50) ? null : 1.0);
	}

	public function reloadSprite()
	{
		clipRect = null;

		var direction:String = NoteUtil.intToString(data.lane);
		switch ("i told you ill do the skins later")
		{
			default:
				if (canQuant) {
					this.loadSparrow("notes/base/quant/notes");
					if (shader != quantShader)
						shader = quantShader;
				} else {
					this.loadSparrow("notes/base/notes");
					shader = null;
				}

				var postfix:String = (isHold ? " hold" + (isHoldEnd ? " end" : "") : "");
				animation.addByPrefix(direction, 'note ${direction}${postfix}0', 0, false);
				noteScale = 0.7;
		}

		scale.set(noteScale, noteScale);
		updateHitbox();
		animation.play(direction);

		if (canQuant)
		{
			getQuantColors("base");
			noteQuant = NoteUtil.calcQuant(data);
			
			quantShader.setColor(
				quantColors[noteQuant][0],
				quantColors[noteQuant][1],
				quantColors[noteQuant][2],
			);
		}
	}

	public var noteQuant:Int = 0;
	public var quantModifier:String = "";
	public var quantColors:Array<Array<FlxColor>> = [];
	public function getQuantColors(quantModifier:String)
	{
		if (this.quantModifier == quantModifier) return;
		this.quantModifier = quantModifier;
		quantColors = NoteUtil.getQuantColors(quantModifier);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public function updateOffsets()
	{
		updateHitbox();
		offset.x += frameWidth * scale.x / 2;
		if (isHold)
		{
			offset.y = 0;
			origin.y = 0;
		}
		else
			offset.y += frameHeight * scale.y / 2;
	}
}
