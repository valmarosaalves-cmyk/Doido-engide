package objects.ui;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import doido.objects.DoidoSprite;

typedef IconData = {
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

    var data:IconData;

    public function setIcon(curIcon:String = "face", isPlayer:Bool = false):HealthIcon {
        this.isPlayer = isPlayer;
        this.curIcon = curIcon;

        if(Assets.fileExists('data/icons/$curIcon.json')) data = cast(Assets.json('data/icons/$curIcon'));
        else data = DEFAULT_DATA;

        var iconGraphic = Assets.image('icons/${data.image ?? curIcon}');
        gridFrames = data.gridFrames ?? (Math.floor(iconGraphic.width / (data.gridWidth ?? DEFAULT_DATA.gridWidth)));
        loadGraphic(iconGraphic, true, Math.floor(iconGraphic.width / gridFrames), iconGraphic.height);

        animation.add("icon", [for(i in 0...gridFrames) i], 0, false);
        animation.play("icon");

        scale.set(data.scale ?? DEFAULT_DATA.scale, data.scale ?? DEFAULT_DATA.scale);
        updateHitbox();

        var clr:Dynamic = data.color ?? DEFAULT_DATA.color;
        if(Std.isOfType(clr, String)) barColor = FlxColor.fromString(clr);
        else if(Std.isOfType(clr, Array)) barColor = FlxColor.fromRGB(clr[0], clr[1], clr[2]); 

        flipX = data.flipX ?? DEFAULT_DATA.flipX;
        flipY = data.flipY ?? DEFAULT_DATA.flipY;
        antialiasing = ((data.pixel == true) ? false : DEFAULT_DATA.pixel);
        if(isPlayer) flipX = !flipX;
        
        return this;
    }
        
    public function setAnim(health:Float = 1) {
		health /= 2;
		var daFrame:Int = 0;

		if(health < 0.3) daFrame = 1;
		if(health > 0.7) daFrame = 2;
		if(daFrame >= gridFrames) daFrame = 0;

		animation.curAnim.curFrame = daFrame;
	}

    final DEFAULT_DATA:IconData = {
        color: "0xFFA1A1A1",
        scale: 1,
        pixel: flixel.FlxSprite.defaultAntialiasing,
        gridWidth: 150,
        flipX: false,
        flipY: false
    }
}