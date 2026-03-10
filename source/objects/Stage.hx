package objects;

import flixel.FlxObject;
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
    public var stageItems:Array<FlxObject> = [];
    public function reloadStage(curStage:String)
    {
        this.curStage = curStage;
        stageItems = [];
        
        loadedScript = null;
        
        var scriptPath:String = "";
        for(file in Assets.list('data/stages/$curStage', SCRIPT)) {
            trace("trying: " + file);
            scriptPath = file;
        }

        if (scriptPath != "")
        {
            loadedScript = new Iris(scriptPath, this, {name: scriptPath, autoRun: true, autoPreset: true});
            loadedScript.set("Paths", Paths);
            loadedScript.set("Assets", Assets);
            callScript("create");
            return;
        }

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

    public function add(obj:FlxSprite) {
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