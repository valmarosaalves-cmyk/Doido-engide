package objects;

import doido.utils.NoteUtil;
import objects.ui.notes.Note;
import flixel.group.FlxGroup.FlxTypedGroup;
import objects.ui.notes.Strumline;

class CharGroup extends FlxTypedGroup<Character>
{
    public var char:Character;
    public var isPlayer:Bool = false;
    public var strumline:Strumline;
    public function new(isPlayer:Bool = false)
    {
        super();
        this.isPlayer = isPlayer;
    }

    public function addChar(charName:String, isActive:Bool = false)
    {
        var newChar = new Character(charName, isPlayer);
        add(newChar);

        if (isActive)
            setActive(charName);
    }

    public function setActive(charName:String)
    {
        char = null;
        for(char in members)
        {
            char.alpha = 0.0001;
            if (char.curChar == charName)
                this.char = char;
        }
        if (char == null) { 
            char = members[0];
            Logs.print(charName + "DOESN'T EXIST", WARNING);
        }
        char.alpha = 1.0;
        updateChar();
    }

    public function updateChar()
    {
        char.x = x - char.width / 2;
        char.y = y - char.height;
    }

    public var x(default, set):Float = 0.0;
    public function set_x(v:Float):Float
    {
        x = v;
        updateChar();
        return x;
    }
    public var y(default, set):Float = 0.0;
    public function set_y(v:Float):Float
    {
        y = v;
        updateChar();
        return y;
    }
    public function setPos(x:Float = 0, y:Float = 0)
    {
        this.x = x;
        this.y = y;
    }

    public function playSingAnim(note:Note, miss:Bool = false)
    {
        char.singStep = char.singLength;
        playAnim(
			NoteUtil.getSingAnims(4)[note.data.lane] + (miss ? "miss" : ""),
			true
		);
    }

    public function playAnim(animName:String, forced:Bool = true, frame:Int = 0)
		char.playAnim(animName, forced, frame);

    public function dance(forced:Bool = false)
        char.dance(forced);
}