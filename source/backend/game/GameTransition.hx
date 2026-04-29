package backend.game;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import backend.game.MusicBeatData.MusicBeatSubState;

class GameTransition extends MusicBeatSubState
{	
	var fadeOut:Bool = false;
	var transition:String = 'funkin';
	
	public var finishCallback:Void->Void;

	var blocks:FlxTypedGroup<FlxSprite>;
	var sprBlack:FlxSprite;
	
	public function new(fadeOut:Bool = true, transition:String = "funkin")
	{
		super();
		this.fadeOut = fadeOut;
		this.transition = transition;

		switch(transition) {
			case 'funkin':
				blocks = new FlxTypedGroup<FlxSprite>();
				add(blocks);

				var blockSize:Int = 100;
				var cols:Int = Math.ceil(FlxG.width / blockSize);
				var rows:Int = Math.ceil(FlxG.height / blockSize);
				
				for (y in 0...rows) {
					for (x in 0...cols) {
						var block = new FlxSprite(x * blockSize, y * blockSize).makeGraphic(blockSize, blockSize, FlxColor.BLACK);
						block.antialiasing = false;
						
						if (fadeOut) {
							block.scale.set(1, 1);
						} else {
							block.scale.set(0, 0);
						}
						
						blocks.add(block);

						var delay:Float = (x + y) * 0.04; 
						
						FlxTween.tween(block.scale, {x: (fadeOut ? 0 : 1), y: (fadeOut ? 0 : 1)}, 0.4, {
							ease: FlxEase.cubeInOut,
							startDelay: delay,
							onComplete: function(twn:FlxTween) {
								if (x == cols - 1 && y == rows - 1) {
									endTransition();
								}
							}
						});
					}
				}

			default:
				sprBlack = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
				sprBlack.screenCenter();
				add(sprBlack);
				
				sprBlack.alpha = (fadeOut ? 1 : 0);
				FlxTween.tween(sprBlack, {alpha: fadeOut ? 0 : 1}, 0.32, {
					onComplete: function(twn:FlxTween)
					{
						endTransition();
					}
				});
		}
	}

	function endTransition()
	{
		if(finishCallback != null)
			finishCallback();
		else
			close();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}
}
