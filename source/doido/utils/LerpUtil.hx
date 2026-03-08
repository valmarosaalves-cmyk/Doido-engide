package doido.utils;

import flixel.math.FlxMath;

class LerpPoint
{
    var _x:LerpFloat;
    var _y:LerpFloat;

    public function new(?init:DoidoPoint, tweening:Bool = true) {
        if(init == null) init = {x:0,y:0};
        _x = new LerpFloat(init.x, tweening);
        _y = new LerpFloat(init.y, tweening);
        this.tweening = tweening;
    }

    public function set(point:DoidoPoint) {
        x = point.x;
        y = point.y;
    }

    public function get(lerp:Float):DoidoPoint
        return {x: 0, y: 0};

    public var x(get, set):Float;
    public function get_x():Float return _x.get();
    public function set_x(v:Float) return _x.set(v);

    public var y(get, set):Float;
    public function get_y():Float return _y.get();
    public function set_y(v:Float) return _y.set(v);

    public var tweening(default, set):Bool = false;
    public function set_tweening(v:Bool):Bool {
        tweening = v;
        _x.tweening = v;
        _y.tweening = v;
        return tweening;
    }
}

class LerpFloat
{
    public var tweening:Bool = false;
    var value:Float = 0;
    var lerped:Float = 0;

    public function new(init:Float = 0, tweening:Bool = true) {
        set(init);
        get(init);
        this.tweening = tweening;
    }

    public function set(value:Float) {
        this.value = value;
        return value;
    }

    public function get(lerp:Float = 1):Float {
        if(!tweening) lerp = 1;
        lerped = FlxMath.lerp(lerped, value, lerp);
        return lerped;
    }
}
