package objects;

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
    public var stageItems:Array<FlxSprite> = [];
    public function reloadStage(curStage:String)
    {
        stageItems = [];

        this.curStage = curStage;
        switch(curStage)
        {
            default:
                var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
                bg.scrollFactor.set();
                bg.screenCenter();
                bg.setZ(0);
                
                stageItems = [bg];
            }
    }
}