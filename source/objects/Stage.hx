package objects;

import flixel.FlxObject;
import states.PlayState;
import flixel.FlxSprite;

class Stage
{
    public var playState:PlayState;

    public function new(playState:PlayState)
    {
        this.playState = playState;
    }

    public var curStage:String = "";
    public var stageItems:Array<FlxObject> = [];
    public function reloadStage(curStage:String)
    {
        stageItems = [];

        this.curStage = curStage;
        switch(curStage)
        {
            default:
                var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
                bg.scale.set(1.15,1.15);
                bg.updateHitbox();
                bg.scrollFactor.set();
                bg.screenCenter();
                bg.setZ(0);
                add(bg);
                //stageItems = [bg];
        }
    }

    public function add(obj:FlxObject)
        stageItems.push(obj);
}