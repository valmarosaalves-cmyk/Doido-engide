package objects.ui;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import doido.objects.DoidoSprite;

typedef IconData =
{
	var ?image:String;
	var ?color:Dynamic;
	var ?scale:Float;
	var ?pixel:Bool;
	var ?gridWidth:Int;
	var ?gridFrames:Int;
	var ?flipX:Bool;
	var ?flipY:Bool;
}

class HealthIcon extends FlxSprite
{
	public var gridFrames:Int = 0;
	public var isPlayer:Bool = false;
	public var curIcon:String = "";
	public var barColor:FlxColor;

	public var globalScale:Float = 1;

	var data:IconData;

	public function setIcon(curIcon:String = "face", isPlayer:Bool = false):HealthIcon
	{
		this.isPlayer = isPlayer;
		this.curIcon = curIcon;

		try
		{
			data = cast(Assets.json('data/icons/$curIcon'));
		}
		catch (e)
		{
			Logs.print('ICON $curIcon LOAD ERROR: $e', ERROR);
			data = DEFAULT;
		}

		var iconGraphic = Assets.image('icons/${data.image ?? curIcon}');
		gridFrames = data.gridFrames ?? (Math.floor(iconGraphic.width / (data.gridWidth ?? DEFAULT.gridWidth)));
		loadGraphic(iconGraphic, true, Math.floor(iconGraphic.width / gridFrames), iconGraphic.height);

		animation.add("icon", [for (i in 0...gridFrames) i], 0, false);
		animation.play("icon");

		var newscale = (data.scale ?? DEFAULT.scale) * globalScale;
		scale.set(newscale, newscale);
		updateHitbox();

		var clr:Dynamic = data.color ?? DEFAULT.color;
		if (Std.isOfType(clr, String))
			barColor = FlxColor.fromString(clr);
		else if (Std.isOfType(clr, Array))
			barColor = FlxColor.fromRGB(clr[0], clr[1], clr[2]);

		flipX = data.flipX ?? DEFAULT.flipX;
		flipY = data.flipY ?? DEFAULT.flipY;
		antialiasing = ((data.pixel == true) ? false : flixel.FlxSprite.defaultAntialiasing);
		if (isPlayer)
			flipX = !flipX;

		return this;
	}

	public function setAnim(health:Float = 1)
	{
		health /= 2;
		var daFrame:Int = 0;

		if (health < 0.3)
			daFrame = 1;
		if (health > 0.7)
			daFrame = 2;
		if (daFrame >= gridFrames)
			daFrame = 0;

		animation.curAnim.curFrame = daFrame;
	}

	final DEFAULT:IconData = {
		image: "face",
		color: "0xFFA1A1A1",
		scale: 1,
		gridWidth: 150,
		flipX: false,
		flipY: false
	}
}
