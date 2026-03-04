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
    var ?x:Int;
    var ?y:Int;
}

typedef OffsetFloat = {
    var ?x:Float;
    var ?y:Float;
}

class Character extends DoidoSprite
{
    var curChar:String = "bf";
    var data:DoidoCharacter;

    public function new(curChar:String = "bf")
    {
        super(0,0);
        this.curChar = curChar;
        loadCharacter();
    }
    
    function loadCharacter()
    {
        //
    }
}