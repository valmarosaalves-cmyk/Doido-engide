package shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;

class MultiplyShader extends FlxShader
{
	@:glFragmentSource('
        #pragma header

        uniform vec3 uColor;
        uniform float uOpacity;

        float blendMultiply(float base, float blend) {
            return base * blend;
        }

        vec3 blendMultiply(vec3 base, vec3 blend) {
            return vec3(
                blendMultiply(base.r, blend.r),
                blendMultiply(base.g, blend.g),
                blendMultiply(base.b, blend.b)
            );
        }

        vec3 blendMultiply(vec3 base, vec3 blend, float opacity) {
            return (blendMultiply(base, blend) * opacity + base * (1.0 - opacity));
        }

        void main() {
            vec2 uv = openfl_TextureCoordv.xy;
            vec4 color = flixel_texture2D(bitmap, uv);
            gl_FragColor = vec4(blendMultiply(color.rgb, uColor.rgb, uOpacity), color.a);
        }
    ')
	public function new()
	{
		super();
		uColor.value = [1.0, 1.0, 1.0];
		uOpacity.value = [0];
	}

	public var multiplyOpacity(get, set):Float;

	inline function set_multiplyOpacity(value:Float):Float
	{
		this.uOpacity.value[0] = value;
		return value;
	}

	inline function get_multiplyOpacity():Float
	{
		return this.uOpacity.value[0];
	}

	public var multiplyColor(get, set):FlxColor;

	inline function set_multiplyColor(value:FlxColor):FlxColor
	{
		this.uColor.value = toVec3(value);
		return value;
	}

	inline function get_multiplyColor():FlxColor
	{
		var color = this.uColor.value;
		return FlxColor.fromRGBFloat(color[0], color[1], color[2]);
	}

	function toVec3(color:FlxColor):Array<Float>
	{
		return [color.redFloat, color.greenFloat, color.blueFloat];
	}
}
