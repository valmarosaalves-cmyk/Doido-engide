package states.editors;

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
import doido.objects.ui.DoidoWindow.IWindow;
import doido.objects.ui.*;

class CharacterEditor extends MusicBeatState
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

	var camFollow:FlxObject;
	var animWindow:AnimWindow;

	public var menuMain:DoidoBox;

	override function create()
	{
		super.create();
		DiscordIO.changePresence("In the Character Editor");
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

		for (anim in char.animList)
		{
			if (!char.animOffsets.exists(anim))
				char.addOffset(anim, {x: 0, y: 0});
		}

		animWindow = new AnimWindow(this);
		animWindow.cameras = [camHUD];
		add(animWindow);

		addMain();
	}

	function createBasic(title:String = "test"):BaseWindow
	{
		var newWindow:BaseWindow = new BaseWindow(null);
		newWindow.title = title;
		newWindow.bg.scale.set(458, 501);
		newWindow.bg.updateHitbox();
		newWindow.bg.setPosition(FlxG.width - newWindow.bg.width - 18, 57);
		return newWindow;
	}

	function createAnimations():BaseWindow
	{
		var tab = createBasic("Animations");
		return tab;
	}

	function addMain()
	{
		menuMain = new DoidoBox(803, 19, 458, 32, 4, true, [
			createAnimations()
		], null);
		menuMain.cameras = [camHUD];
		add(menuMain);
	}

	static var camZoom:Float = 0.9;

	var draggingCharacter:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (Controls.justPressed(BACK))
			MusicBeat.switchState(new states.DebugMenu());

		var overlapsWindow:Bool = false;
		for (basic in members)
		{
			if (Std.isOfType(basic, IWindow))
			{
				if (cast(basic, IWindow).overlapping)
				{
					overlapsWindow = true;
				}
			}
		}

		if (!overlapsWindow)
		{
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

			if (mouseOverlapsOffset(char))
			{
				if (FlxG.mouse.justPressed)
					draggingCharacter = true;
			}

			if (draggingCharacter)
				updateOffset(FlxG.mouse.deltaViewX, FlxG.mouse.deltaViewY, false);

			if ((FlxG.mouse.pressed && !draggingCharacter) || FlxG.mouse.pressedMiddle)
			{
				camFollow.x -= FlxG.mouse.deltaViewX;
				camFollow.y -= FlxG.mouse.deltaViewY;
			}

			// this only checks if the character is being dragged to cover a bug im not sure how to fix
			// ill think about it later so consider this temporary
			if (FlxG.mouse.wheel != 0 && !draggingCharacter)
			{
				var init = FlxG.mouse.getWorldPosition(camChar);
				camZoom += (FlxG.mouse.wheel) / 2;
				camZoom = FlxMath.bound(camZoom, 0.4, 2.5);
				camChar.zoom = FlxMath.lerp(camChar.zoom, camZoom, elapsed * 12);
				var post = FlxG.mouse.getWorldPosition(camChar);

				camFollow.x += init.x - post.x;
				camFollow.y += init.y - post.y;
			}

			if (FlxG.mouse.justReleased)
				draggingCharacter = false;

			if (FlxG.keys.justPressed.Q)
				changeAnim(-1);
			if (FlxG.keys.justPressed.E)
				changeAnim(1);

			if (FlxG.keys.justPressed.SPACE)
				char.playAnim(char.curAnimName, true);
		}
	}

	function mouseOverlapsOffset(_char:Character)
	{
		var mousePos = FlxG.mouse.getWorldPosition(camChar);
		var offsets:DoidoPoint = char.animOffsets.get(char.curAnimName);
		mousePos.x += offsets.x;
		mousePos.y += offsets.y;
		return _char.overlapsPoint(mousePos);
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

	function updateOffset(x:Float = 0, y:Float = 0, arrows:Bool = true)
	{
		if (arrows)
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
	var characterEditor:CharacterEditor;

	public var animName:FlxBitmapText;
	public var offsetTxt:FlxBitmapText;
	public var charTxt:FlxBitmapText;
	public var ghostTxt:FlxBitmapText;

	var charSlider:DoidoSlider;
	var ghostSlider:DoidoSlider;

	public function new(characterEditor:CharacterEditor)
	{
		super(null);
		this.characterEditor = characterEditor;

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
				characterEditor.char.playAnim(characterEditor.char.curAnimName, true);
			else
			{
				characterEditor.char.playAnim(characterEditor.char.curAnimName, true, Math.floor(charSlider.value));
				characterEditor.char.anim.pause();
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
				characterEditor.ghost.playAnim(characterEditor.ghost.curAnimName, true);
			else
			{
				characterEditor.ghost.playAnim(characterEditor.ghost.curAnimName, true, Math.floor(ghostSlider.value));
				characterEditor.ghost.anim.pause();
			}
		});
		add(ghostSlider);

		updateAnim();
	}

	public function updateAnim()
	{
		var char = characterEditor.char;
		var ghost = characterEditor.ghost;
		var anim = characterEditor.char.curAnimName;
		var offsets:DoidoPoint = char.animOffsets.get(anim);

		animName.text = anim;
		offsetTxt.text = 'X: ${offsets.x} / Y: ${offsets.y}';

		animName.x = bg.x + bg.width / 2 - animName.width / 2;
		offsetTxt.x = bg.x + bg.width / 2 - offsetTxt.width / 2;

		charSlider.rangeMax = char.animation.curAnim.frames.length - 1;
		charSlider.steps = char.animation.curAnim.frames.length - 1;
		charSlider.snappingStrength = Math.POSITIVE_INFINITY;

		ghostSlider.rangeMax = ghost.animation.curAnim.frames.length - 1;
		ghostSlider.steps = ghost.animation.curAnim.frames.length - 1;
		ghostSlider.snappingStrength = Math.POSITIVE_INFINITY;
	}
}
