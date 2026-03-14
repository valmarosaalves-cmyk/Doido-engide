package doido.system;

import doido.objects.ui.Transition;
import flixel.FlxBasic;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import lime.app.Application;
import openfl.display.BitmapData;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class Screenshot extends FlxBasic
{
    private static var lastScreenshot:FlxSprite;

    var screnshotDelay:Int = 0;
    override function update(elapsed:Float)
    {
        if (screnshotDelay > 0)
        {
            screnshotDelay--;
            if (screnshotDelay <= 0) {
                screnshotDelay = 0;
                takeScreenshot();
            }
        }

        if (FlxG.keys.justPressed.F2)
        {
            screnshotDelay = 2;
            MusicBeat.getTopCamera().stopFlash();
            clearScreenshot();
        }

        super.update(elapsed);
    }

    public function takeScreenshot()
    {
        // sorry no screenshots during transitions
        if (Std.isOfType(MusicBeat.activeState, Transition)) return;
        
        FlxG.sound.play(Assets.sound('screenshot'));
        var rawImage = Application.current.window.readPixels();
        var pngBytes = rawImage.encode(PNG);
        if (!FileSystem.exists("screenshots/"))
			FileSystem.createDirectory("screenshots/");
        var i:Int = 0;
        var rawName:String = Date.now().toString().replace(":", "-");
        var name:String = rawName;
        while (FileSystem.exists('screenshots/$name.png'))
        {
            i++;
            name = '$rawName ($i)';
        }
        File.saveBytes('screenshots/$name.png', pngBytes);
        var camera = MusicBeat.getTopCamera();
        camera.flash(0.8, null, true);
        
        lastScreenshot = new FlxSprite().loadGraphic(FlxGraphic.fromBitmapData(BitmapData.fromImage(rawImage)));
        lastScreenshot.scale.set(0.25, 0.25);
        lastScreenshot.updateHitbox();
        lastScreenshot.cameras = [camera];

        MusicBeat.activeState.add(lastScreenshot);

        lastScreenshot.y = FlxG.height;
        FlxTween.tween(lastScreenshot, {y: FlxG.height - lastScreenshot.height}, 0.4, {
            ease: FlxEase.cubeOut,
            startDelay: 0.6,
            onComplete: (twn) -> {
                
                FlxTween.tween(lastScreenshot, {x: -FlxG.width}, 0.4, {
                    ease: FlxEase.cubeIn,
                    startDelay: 1.6,
                    onComplete: (twn) -> {
                        clearScreenshot();
                    }
                });

            }  
        });
    }

    public static function clearScreenshot()
    {
        if (lastScreenshot == null) return;
        FlxTween.cancelTweensOf(lastScreenshot);
        MusicBeat.activeState.remove(lastScreenshot);
        Cache.clearSingleGraphic(lastScreenshot.graphic);
        lastScreenshot = null;
    }
}