package objects;

import flixel.FlxObject;
import states.PlayState;
import flixel.FlxSprite;
import hscript.iris.Iris;
import doido.utils.MathUtil;

class Stage
{
    public var playState:PlayState;

    public function new(playState:PlayState)
    {
        this.playState = playState;
    }

    public var curStage:String = "";
    public var stageItems:Array<FlxObject> = [];
    
    public var bfCamOffset:DoidoPoint;
    public var dadCamOffset:DoidoPoint;

    public var camZoom:Float = 0.9;

    public function reloadStage(curStage:String)
    {
        this.curStage = curStage;
        stageItems = [];

        // default data values
        camZoom = 0.9;
        playState.bf.setPos(
            FlxG.width - 200,
            FlxG.height - 50
        );
        playState.dad.setPos(
            200,
            FlxG.height - 50
        );
        playState.gf.setPos(
            FlxG.width / 2,
            FlxG.height - 150
        );

        dadCamOffset = {x: 0, y: 0};
        bfCamOffset = {x: 0, y: 0};
        
        // loading the script
        var scriptPath:String = 'data/stages/$curStage';
        if (Assets.fileExists(scriptPath, SCRIPT))
        {
            loadedScript = new Iris(Assets.getAsset(scriptPath, SCRIPT), this, {name: scriptPath, autoRun: true, autoPreset: true});
            loadedScript.set("Paths", Assets);
            loadedScript.set("Assets", Assets);
            loadedScript.set("PlayState", PlayState);
            loadedScript.set("FlxSprite", FlxSprite);
            loadedScript.set("MathUtil", MathUtil);
            
            callScript("create");
        }
        else
            loadedScript = null;

        /*
            wanna hardcode your stage?
            alright
        */
        if (loadedScript == null)
        {
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
            }
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