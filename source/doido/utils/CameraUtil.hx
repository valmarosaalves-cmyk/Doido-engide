package doido.utils;

import flixel.FlxCamera;
import flixel.math.FlxMath;

class CameraUtil
{
    public static function createCam(cam:FlxCamera, ui:Bool = false, defaultDrawTarget:Bool = false):FlxCamera {
        if(ui) cam.bgColor.alpha = 0;
        if(!defaultDrawTarget) FlxG.cameras.add(cam, false);
        else {
            FlxG.cameras.reset(cam);
            FlxG.cameras.setDefaultDrawTarget(cam, true);
        }
        return cam;
    }

    public static function moveCam(cam:flixel.FlxCamera, target:DoidoPoint, lerp:Float = -1) {
        if(lerp == -1) {
            cam.scroll.x = target.x - FlxG.width / 2;
		    cam.scroll.y = target.y - FlxG.height/ 2;
        }
        else {
            cam.scroll.x = FlxMath.lerp(cam.scroll.x, target.x - FlxG.width / 2, lerp);
		    cam.scroll.y = FlxMath.lerp(cam.scroll.y, target.y - FlxG.height/ 2, lerp);
        }
	}
}