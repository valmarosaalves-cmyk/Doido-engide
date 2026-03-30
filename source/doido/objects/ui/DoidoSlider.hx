package doido.objects.ui;

import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxSignal;

typedef SliderSignal = FlxTypedSignal<DoidoSlider->Void>;

class DoidoSlider extends FlxSpriteGroup
{
	public var onScrub(default, null):SliderSignal = new SliderSignal();
	public var bar:FlxSprite;
	public var slider:FlxSprite;
	public var dots:Array<FlxSprite> = [];

	public var value:Float = 0;
	public var rangeMin:Float = 0;
	public var rangeMax:Float = 1;
	public var steps:Int = 2;
	public var snappingStrength:Float = 0.05; // 0.05 seems pretty good

	var dotSpacing:Float = 1;

	public function new(x:Float = 0, y:Float = 0, wid:Int = 160, hei:Int = 6, defValue:Float = 0, rangeMin:Float = 0, rangeMax:Float = 0, steps:Int = 2,
			snappingStrength:Float = 0)
	{
		super(x, y);
		this.rangeMin = rangeMin;
		this.rangeMax = rangeMax;
		this.steps = steps;

		bar = new FlxSprite().makeGraphic(wid, hei, 0xFFD8DAF6);
		add(bar);

		// you cant really have less than two
		if (steps >= 2)
		{
			dotSpacing = wid / (steps - 1);
			for (i in 0...steps)
			{
				var dot = new FlxSprite().loadImage("editors/charting/dot");
				dot.x = (dotSpacing * i) - (dot.width / 2);
				dot.y = (bar.height / 2) - (dot.height / 2);
				add(dot);
				dots.push(dot);
			}
		}

		slider = new FlxSprite().loadImage("editors/charting/slider");
		slider.y = (bar.height / 2) - (slider.height / 2);
		add(slider);

		value = defValue;
		this.snappingStrength = FlxMath.remapToRange(dotSpacing, 0, bar.width, rangeMin, rangeMax)/2;
	}

	override function draw()
	{
		slider.x = FlxMath.lerp(bar.x, bar.x + bar.width, FlxMath.remapToRange(value, rangeMin, rangeMax, 0, 1)) - (slider.width / 2);
		super.draw();
	}

	var scrubbing:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.overlaps(bar) || FlxG.mouse.overlaps(slider))
		{
			// chartState.curCursor = POINTER;
			if (FlxG.mouse.justPressed)
				scrubbing = true;
		}

		if (scrubbing)
		{
			value = FlxMath.bound(FlxMath.remapToRange(FlxG.mouse.x, bar.x, bar.x + bar.width, rangeMin, rangeMax), rangeMin, rangeMax);

			if (steps >= 2 && snappingStrength >= 0)
			{
				for (i in 0...steps)
				{
					var space = FlxMath.remapToRange(i * dotSpacing, 0, bar.width, rangeMin, rangeMax);
					if (Math.abs(value - space) <= snappingStrength)
						value = space;
				}
			}

			if (!FlxG.mouse.pressed)
				scrubbing = false;

			onScrub.dispatch(this);
		}
	}
}
