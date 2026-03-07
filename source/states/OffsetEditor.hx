package states;

import doido.utils.DoidoPoint;
import objects.Character;
import flixel.FlxSprite;
import objects.Character;
import flixel.text.FlxText;
import flixel.FlxObject;
import flixel.math.FlxMath;
import doido.objects.DoidoCamera;
import StringTools;

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

    var char:Character;
    var ghost:Character;

    var exportTxt:FlxText;
    var camFollow:FlxObject;

    override function create()
	{
		super.create();
        DiscordIO.changePresence("In the Offset Editor");

		camChar = new DoidoCamera(false, true);
        camHUD = new DoidoCamera(true, false);

        camFollow = new FlxObject();
		camChar.follow(camFollow, LOCKON, 1);
        camFollow.setPosition(FlxG.width/2, FlxG.height/2);

        var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
        bg.screenCenter();
		add(bg);

        ghost = new Character(curChar, isPlayer);
		ghost.setPosition(
			(FlxG.width / 2) - (ghost.width/2),
			(FlxG.height / 2) - (ghost.height/2)
		);
        ghost.alpha = 0.4;
		add(ghost);

        char = new Character(curChar, isPlayer);
		char.setPosition(
			(FlxG.width / 2) - (char.width/2),
			(FlxG.height / 2) - (char.height/2)
		);
		add(char);

        exportTxt = new FlxText(0,0,0,"",24);
		exportTxt.setFormat(Main.globalFont, 24, 0xFFFFFFFF, RIGHT);
		exportTxt.setBorderStyle(OUTLINE, 0xFF000000, 2);
		exportTxt.cameras = [camHUD];
		add(exportTxt);
        updateTxt();

        var controlTxt = new FlxText(0,0,0,"Arrows - Change Offset\nWASD - Change Camera Pos\nQ/E - Change Anim\nQ/E + SHIFT - Change Zoom",24);
		controlTxt.setFormat(Main.globalFont, 24, 0xFFFFFFFF, LEFT);
		controlTxt.setBorderStyle(OUTLINE, 0xFF000000, 2);
		controlTxt.cameras = [camHUD];
		add(controlTxt);

        controlTxt.x = 0;
		controlTxt.y = FlxG.height- controlTxt.height;
    }

    function updateTxt()
	{
		exportTxt.text = "";

		for(anim in char.animList)
		{
			if(!char.animOffsets.exists(anim))
				char.addOffset(anim, {x: 0, y: 0});

			var offsets:DoidoPoint = char.animOffsets.get(anim);

			exportTxt.text += '$anim ${offsets.x} ${offsets.y}\n';
		}
		exportTxt.text += '\nCam Pos: ${(Math.round(camFollow.x*10))/10} ${(Math.round(camFollow.y*10))/10}' 
        + '\nZoom (on editor): ${(Math.round(camChar.zoom*10))/10}';
		exportTxt.x = FlxG.width - exportTxt.width;
		exportTxt.y = FlxG.height- exportTxt.height;
	}

    static var camZoom:Float = 1.0;
    override function update(elapsed:Float)
	{
		super.update(elapsed);

        if(Controls.justPressed(BACK))
		    MusicBeat.switchState(new states.DebugMenu());

        var speed:Float = elapsed * 400;
        if(FlxG.keys.anyPressed([A, D, W, S])) {
            if(FlxG.keys.pressed.A) camFollow.x -= speed;
            if(FlxG.keys.pressed.D) camFollow.x += speed;
            if(FlxG.keys.pressed.W) camFollow.y -= speed;
            if(FlxG.keys.pressed.S) camFollow.y += speed;
            updateTxt();
        }

        var daChange:Array<Bool> = [
			FlxG.keys.justPressed.LEFT,
			FlxG.keys.justPressed.RIGHT,
			FlxG.keys.justPressed.UP,
			FlxG.keys.justPressed.DOWN,
		];
		
		if(daChange[0]) updateOffset(-1, 0);
		if(daChange[1]) updateOffset(1,  0);
		if(daChange[2]) updateOffset(0, -1);
		if(daChange[3]) updateOffset(0,  1);

        if(FlxG.keys.pressed.SHIFT) {
            var speedCam:Float = elapsed * camChar.zoom;
            if(FlxG.keys.pressed.Q && camChar.zoom > 0.5) camZoom -= speedCam;
            if(FlxG.keys.pressed.E && camChar.zoom < 2.5) camZoom += speedCam;
			camChar.zoom = FlxMath.lerp(camChar.zoom, camZoom, elapsed * 12);
			updateTxt();
        }
        else {
            if(FlxG.keys.justPressed.Q) changeAnim(-1);
            if(FlxG.keys.justPressed.E) changeAnim(1);
        }

        if(FlxG.keys.justPressed.SPACE) char.playAnim(char.curAnimName, true);
    }

    public function changeAnim(change:Int = 0)
	{
		if(change != 0) FlxG.sound.play(Assets.sound('scroll'));
        curAnim += change;
		curAnim = FlxMath.wrap(curAnim, 0, char.animList.length-1);
        char.playAnim(char.animList[curAnim], true);
	}

    var curAnim:Int = 0;
    function updateOffset(x:Float = 0, y:Float = 0)
	{
		if(FlxG.keys.pressed.ALT) {
			x*=0.1;
			y*=0.1;
		} else if(FlxG.keys.pressed.SHIFT) {
			x*=10;
			y*=10;
		} else if(FlxG.keys.pressed.CONTROL) {
			x*=100;
			y*=100;
		}
		
        char.animOffsets.get(char.curAnimName).x += -x;
        char.animOffsets.get(char.curAnimName).y += -y;
        char.playAnim(char.curAnimName, true);
		
		updateTxt();
	}
}