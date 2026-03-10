package objects;

import states.PlayState;
import flixel.FlxSprite;
import hscript.iris.Iris;

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

        loadedScript = null;
        
        for(file in Assets.list('data/stages/$curStage', SCRIPT)) {
            trace("trying: " + file);
            loadedScript = new Iris(file, this, {name: file, autoRun: true, autoPreset: true});
        }

        if(loadedScript != null) {
            callScript("create");
            return;
        }

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

    public function add(obj:FlxSprite)
    {
        stageItems.push(obj);
    }

    //Scripts
    public var loadedScript:Iris;
	public function callScript(fun:String, ?args:Array<Dynamic>) {
        if(loadedScript == null) return;

        @:privateAccess {
            var ny: Dynamic = loadedScript.interp.variables.get(fun);
            try {
                if(ny != null && Reflect.isFunction(ny))
                    loadedScript.call(fun, args);
            } catch(e) {
                Logs.print('error parsing stage script: ' + e, ERROR);
            }
        }
	}
}