package objects;

import doido.objects.DoidoSprite;

typedef Animation = {
    var name:String;
    var prefix:String;
    var ?framerate:Int;
    var ?looped:Bool;
    var ?offset:Offset;
    var ?indices:Array<Int>;
    var ?flipX:Bool;
    var ?flipY:Bool;
}

typedef DoidoCharacter = {
	var spritesheet:String;
    var ?extrasheets:Array<String>;
    var ?type:String;

    var anims:Array<Animation>;
    var ?idleAnims:Array<String>;
    var ?quickDancer:Bool;
    var ?deathChar:String;

    var ?globalOffset:Offset;
    var ?cameraOffset:Offset;

    var ?scale:OffsetFloat;
    var ?pixel:Bool;
    var ?flipX:Bool;
    var ?flipY:Bool;
}

typedef Offset = {
    var x:Int;
    var y:Int;
}

typedef OffsetFloat = {
    var x:Float;
    var y:Float;
}

class Character extends DoidoSprite
{
    var curChar:String = "bf";
    var type:Frames;
    var data:DoidoCharacter;

    public function new(curChar:String = "bf")
    {
        super(0,0);
        this.curChar = curChar;
        loadCharacter();
    }

    var idleAnims:Array<String> = ["idle"];
    var quickDancer:Bool = false;
    var deathChar:String = "bf-dead";

    var globalOffset:Offset = {x: 0, y: 0};
    var cameraOffset:Offset = {x: 0, y: 0};

    function loadCharacter()
    {
        data = cast(Assets.json('images/${getPath()}/data'));
        type = framesFromString(data.type);
        frames = cast Assets.framesCollection('${getPath()}/${data.spritesheet}', type);

        for(anim in data.anims) {
            if((anim.indices ?? []).length > 0) animation.addByIndices(anim.name, anim.prefix, anim.indices, "", anim.framerate ?? 24, anim.looped ?? false, anim.flipX ?? false, anim.flipY ?? false);
            else animation.addByPrefix(anim.name, anim.prefix, anim.framerate ?? 24, anim.looped ?? false, anim.flipX ?? false, anim.flipY ?? false);
            if(anim.offset != null) addOffset(anim.name, anim.offset.x, anim.offset.y);
        }

        idleAnims = data.idleAnims ?? idleAnims;
        quickDancer = data.quickDancer ?? quickDancer;
        deathChar = data.deathChar ?? deathChar;

        for(i in 0...idleAnims.length) {
			if(!animExists(idleAnims[i]))
				idleAnims[i] = "idle"; //ill fix this later?????
		}

        globalOffset = data.globalOffset ?? globalOffset;
        cameraOffset = data.cameraOffset ?? cameraOffset;

        data.scale ??= {x: 1, y: 1};
        scale.set(data.scale.x, data.scale.y);
        antialiasing = ((data.pixel == true) ? false : flixel.FlxSprite.defaultAntialiasing);
        flipX = data.flipX ?? false;
        flipY = data.flipY ?? false;

        playAnim(idleAnims[0]);
		updateHitbox();
        dance();
    }

    private var curDance:Int = 0;
	public function dance(forced:Bool = false) {
        playAnim(idleAnims[curDance]);
        curDance++;
        if (curDance >= idleAnims.length)
            curDance = 0;
	}

    override public function update(elapsed:Float) {
        super.update(elapsed);
        if(animExists(curAnimName + '-loop') && curAnimFinished)
			playAnim(curAnimName + '-loop');
    }

    function framesFromString(frames:Null<String>):Frames {
        return switch(frames.toUpperCase()) {
            case "ATLAS": ATLAS;
            default: SPARROW;
        }
    }

    function getPath() return 'characters/$curChar';
}