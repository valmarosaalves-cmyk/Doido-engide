package states;

import doido.objects.ui.DoidoWindow.BaseWindow;
import doido.objects.DoidoCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxObject;
import flixel.math.FlxMath;
import objects.Character;
import objects.Character;
import flixel.addons.display.FlxGridOverlay;
import flixel.text.FlxBitmapText;
import doido.objects.ui.DoidoSlider;

class OffsetEditor extends MusicBeatState
{
	var curChar:String = "";
	var isPlayer:Bool = false;

	public function new(curChar:String, isPlayer:Bool = false)
	{
		this.curChar = curChar;
		this.isPlayer = isPlayer;
		super();
	}

	var camChar:DoidoCamera;
	var camHUD:DoidoCamera;

	public var char:Character;
	public var ghost:Character;

	var exportTxt:FlxText;
	var camFollow:FlxObject;

	var animWindow:AnimWindow;

	override function create()
	{
		super.create();
		DiscordIO.changePresence("In the Offset Editor");
		FlxG.mouse.visible = true;

		camChar = new DoidoCamera(false, true);
		camHUD = new DoidoCamera(true, false);

		camFollow = new FlxObject();
		camChar.follow(camFollow, LOCKON, 1);
		camFollow.setPosition(FlxG.width / 2 + FlxG.width / 4, FlxG.height / 2 - FlxG.width / 8);
		camChar.zoom = camZoom;

		var grid = FlxGridOverlay.create(64, 64, FlxG.width * 3, FlxG.height * 3, true, 0xFFEBEFFE, 0xFFD7D9F6);
		grid.screenCenter();
		add(grid);

		var middlePoint = new FlxSprite().loadImage('editors/point');
		middlePoint.setPosition((FlxG.width - middlePoint.width) / 2, FlxG.height - 200 - (middlePoint.height / 2));
		middlePoint.color = 0xFFFF0000;

		ghost = new Character(curChar, isPlayer);
		ghost.alpha = 0.4;
		add(ghost);

		char = new Character(curChar, isPlayer);
		add(char);

		add(middlePoint);

		for (char in [ghost, char])
		{
			char.debugMode = true;
			char.setPosition(middlePoint.x - (char.width - middlePoint.width) / 2, middlePoint.y + (middlePoint.height / 2) - char.height);
			char.x += char.globalOffset.x;
			char.y += char.globalOffset.y;
		}

		exportTxt = new FlxText(0, 0, 0, "", 24);
		exportTxt.setFormat(Main.globalFont, 24, 0xFFFFFFFF, RIGHT);
		exportTxt.setBorderStyle(OUTLINE, 0xFF000000, 2);
		exportTxt.cameras = [camHUD];
		// add(exportTxt);
		updateTxt();

		/*var controlTxt = new FlxText(0, 0, 0, "Arrows - Change Offset\nWASD - Change Camera Pos\nQ/E - Change Anim\nQ/E + SHIFT - Change Zoom", 24);
			controlTxt.setFormat(Main.globalFont, 24, 0xFFFFFFFF, LEFT);
			controlTxt.setBorderStyle(OUTLINE, 0xFF000000, 2);
			controlTxt.cameras = [camHUD];
			add(controlTxt);

			controlTxt.x = 0;
			controlTxt.y = FlxG.height - controlTxt.height; */

		for (anim in char.animList)
		{
			if (!char.animOffsets.exists(anim))
				char.addOffset(anim, {x: 0, y: 0});
		}

		animWindow = new AnimWindow(this);
		animWindow.cameras = [camHUD];
		add(animWindow);
	}

	function updateTxt()
	{
		exportTxt.text = "";

		for (anim in char.animList)
		{
			if (!char.animOffsets.exists(anim))
				char.addOffset(anim, {x: 0, y: 0});

			var offsets:DoidoPoint = char.animOffsets.get(anim);

			exportTxt.text += (char.curAnimName == anim ? "> " : "") + '$anim ${offsets.x} ${offsets.y}\n';
		}
		exportTxt.text += '\nCam Pos: ${(Math.round(camFollow.x * 10)) / 10} ${(Math.round(camFollow.y * 10)) / 10}'
			+ '\nZoom (on editor): ${(Math.round(camChar.zoom * 10)) / 10}';
		exportTxt.x = FlxG.width - exportTxt.width;
		exportTxt.y = FlxG.height - exportTxt.height;
	}

	static var camZoom:Float = 0.9;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (Controls.justPressed(BACK))
			MusicBeat.switchState(new states.DebugMenu());

		var speed:Float = elapsed * 400;
		if (FlxG.keys.anyPressed([A, D, W, S]))
		{
			if (FlxG.keys.pressed.A)
				camFollow.x -= speed;
			if (FlxG.keys.pressed.D)
				camFollow.x += speed;
			if (FlxG.keys.pressed.W)
				camFollow.y -= speed;
			if (FlxG.keys.pressed.S)
				camFollow.y += speed;
			animWindow.updateAnim();
		}

		var daChange:Array<Bool> = [
			FlxG.keys.justPressed.LEFT,
			FlxG.keys.justPressed.RIGHT,
			FlxG.keys.justPressed.UP,
			FlxG.keys.justPressed.DOWN,
		];

		if (daChange[0])
			updateOffset(-1, 0);
		if (daChange[1])
			updateOffset(1, 0);
		if (daChange[2])
			updateOffset(0, -1);
		if (daChange[3])
			updateOffset(0, 1);

		if (FlxG.keys.pressed.SHIFT)
		{
			var speedCam:Float = elapsed * camChar.zoom;
			if (FlxG.keys.pressed.Q && camChar.zoom > 0.5)
				camZoom -= speedCam;
			if (FlxG.keys.pressed.E && camChar.zoom < 2.5)
				camZoom += speedCam;
			camChar.zoom = FlxMath.lerp(camChar.zoom, camZoom, elapsed * 12);
			animWindow.updateAnim();
		}
		else
		{
			if (FlxG.keys.justPressed.Q)
				changeAnim(-1);
			if (FlxG.keys.justPressed.E)
				changeAnim(1);
		}

		if (FlxG.keys.justPressed.SPACE)
			char.playAnim(char.curAnimName, true);
	}

	public function changeAnim(change:Int = 0):Void
	{
		if (change != 0)
			FlxG.sound.play(Assets.sound('scroll'));
		curAnim += change;
		curAnim = FlxMath.wrap(curAnim, 0, char.animList.length - 1);

		char.playAnim(char.animList[curAnim], true);
		animWindow.updateAnim();
		// updateTxt();
	}

	var curAnim:Int = 0;

	function updateOffset(x:Float = 0, y:Float = 0)
	{
		if (FlxG.keys.pressed.ALT)
		{
			x *= 0.1;
			y *= 0.1;
		}
		else if (FlxG.keys.pressed.SHIFT)
		{
			x *= 10;
			y *= 10;
		}
		else if (FlxG.keys.pressed.CONTROL)
		{
			x *= 100;
			y *= 100;
		}

		char.addToOffset(char.curAnimName, -x, -y);

		var loopAnimName:String = char.curAnimName.endsWith("-loop") ? char.curAnimName.replace("-loop", "") : char.curAnimName + "-loop";
		if (char.animExists(loopAnimName))
		{
			if (char.animExists(loopAnimName))
				char.addOffset(loopAnimName, char.getOffset(char.curAnimName));
		}

		char.playAnim(char.curAnimName, true);

		animWindow.updateAnim();
	}
}

class AnimWindow extends BaseWindow
{
	var offsetEditor:OffsetEditor;

	public var animName:FlxBitmapText;
	public var offsetTxt:FlxBitmapText;
	public var charTxt:FlxBitmapText;
	public var ghostTxt:FlxBitmapText;

	var charSlider:DoidoSlider;
	var ghostSlider:DoidoSlider;

	public function new(offsetEditor:OffsetEditor)
	{
		super(null);
		this.offsetEditor = offsetEditor;

		bg.scale.set(458, 138);
		bg.updateHitbox();
		bg.setPosition(FlxG.width - bg.width - 18, FlxG.height - bg.height - 18);

		animName = new FlxBitmapText(0, bg.y + 8, Assets.bitmapFont("phantommuff"));
		animName.alignment = CENTER;
		add(animName);

		offsetTxt = new FlxBitmapText(0, animName.y + 32, Assets.bitmapFont("phantommuff"));
		offsetTxt.color = 0xFFD8DAF6;
		offsetTxt.alignment = CENTER;
		offsetTxt.scale.set(0.625, 0.625);
		offsetTxt.updateHitbox();
		add(offsetTxt);

		charTxt = new FlxBitmapText(bg.x + 8, offsetTxt.y + 32, Assets.bitmapFont("phantommuff"));
		charTxt.alignment = LEFT;
		charTxt.text = "Character: ";
		charTxt.color = 0xFFD8DAF6;
		charTxt.scale.set(0.625, 0.625);
		charTxt.updateHitbox();
		add(charTxt);

		charSlider = new DoidoSlider(charTxt.x + charTxt.width + 14, charTxt.y + 7, 320, 6, -1, -1, 3, 3, /*Math.POSITIVE_INFINITY*/);
		charSlider.onScrub.add((sld) ->
		{
			var isOff:Bool = (charSlider.value < 0.0);
			if (isOff)
				offsetEditor.char.playAnim(offsetEditor.char.curAnimName, true);
			else
			{
				offsetEditor.char.playAnim(offsetEditor.char.curAnimName, true, Math.floor(charSlider.value));
				offsetEditor.char.anim.pause();
			}
		});
		add(charSlider);

		ghostTxt = new FlxBitmapText(bg.x + 8, charTxt.y + 32, Assets.bitmapFont("phantommuff"));
		ghostTxt.alignment = LEFT;
		ghostTxt.text = "Ghost: ";
		ghostTxt.color = 0xFFD8DAF6;
		ghostTxt.scale.set(0.625, 0.625);
		ghostTxt.updateHitbox();
		add(ghostTxt);

		ghostSlider = new DoidoSlider(charSlider.x, ghostTxt.y + 7, 320, 6, -1, -1, 3, 3, /*Math.POSITIVE_INFINITY*/);
		ghostSlider.onScrub.add((sld) ->
		{
			var isOff:Bool = (ghostSlider.value < 0.0);
			if (isOff)
				offsetEditor.ghost.playAnim(offsetEditor.ghost.curAnimName, true);
			else
			{
				offsetEditor.ghost.playAnim(offsetEditor.ghost.curAnimName, true, Math.floor(ghostSlider.value));
				offsetEditor.ghost.anim.pause();
			}
		});
		add(ghostSlider);

		updateAnim();
	}

	public function updateAnim()
	{
		var char = offsetEditor.char;
		var ghost = offsetEditor.ghost;
		var anim = offsetEditor.char.curAnimName;
		var offsets:DoidoPoint = char.animOffsets.get(anim);

		animName.text = anim;
		offsetTxt.text = 'X: ${offsets.x} / Y: ${offsets.y}';

		animName.x = bg.x + bg.width / 2 - animName.width / 2;
		offsetTxt.x = bg.x + bg.width / 2 - offsetTxt.width / 2;

		charSlider.rangeMax = char.animation.curAnim.frames.length - 1;
		charSlider.steps = char.animation.curAnim.frames.length - 1;
		// charSlider.snappingStrength = Math.POSITIVE_INFINITY;

		ghostSlider.rangeMax = ghost.animation.curAnim.frames.length - 1;
		ghostSlider.steps = ghost.animation.curAnim.frames.length - 1;
	}
}
