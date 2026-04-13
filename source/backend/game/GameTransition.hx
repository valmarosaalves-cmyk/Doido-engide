package backend.game;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxGradient;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import backend.game.MusicBeatData.MusicBeatSubState;

class GameTransition extends MusicBeatSubState
{	
	var fadeOut:Bool = false;
	var transition:String = 'funkin';
	
	public var finishCallback:Void->Void;

	var sprBlack:FlxSprite;
	var sprGrad:FlxSprite;
	
	var blocksCompleted:Int = 0;
	var totalBlocks:Int = 0;
	
	public function new(fadeOut:Bool = true, transition:String = "funkin")
	{
		super();
		this.fadeOut = fadeOut;
		this.transition = transition;

		switch(transition) {
			case 'blocks':
				var blockSize:Float = 100;
				var cols:Int = Math.ceil(FlxG.width / blockSize);
				var rows:Int = Math.ceil(FlxG.height / blockSize);
				totalBlocks = cols * rows;
				blocksCompleted = 0;

				for (y in 0...rows) {
					for (x in 0...cols) {
						var block = new FlxSprite(x * blockSize, y * blockSize).makeGraphic(Std.int(blockSize + 2), Std.int(blockSize + 2), 0xFF000000);
						block.scrollFactor.set(0, 0);
						
						if (fadeOut) {
							block.scale.set(1, 1);
						} else {
							block.scale.set(0, 0);
						}
						
						add(block);

						var delay:Float = (x + y) * 0.03; 

						FlxTween.tween(block.scale, {x: fadeOut ? 0 : 1, y: fadeOut ? 0 : 1}, 0.35, {
							startDelay: delay,
							ease: FlxEase.cubeOut,
							onComplete: function(twn:FlxTween) {
								blocksCompleted++;
								if (blocksCompleted >= totalBlocks) {
									endTransition();
								}
							}
						});
					}
				}

			case 'funkin':
				sprBlack = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
				sprBlack.screenCenter(X);
				add(sprBlack);
				
				sprGrad = FlxGradient.createGradientFlxSprite(FlxG.width, Math.floor(FlxG.height / 2), [0xFF000000, 0x00], 1, 90);
				sprGrad.screenCenter(X);
				sprGrad.flipY = fadeOut;
				add(sprGrad);
				
				var yPos:Array<Float> = [
					-sprBlack.height - sprGrad.height - 40,
					FlxG.height / 2 - sprBlack.height / 2,
					FlxG.height + sprGrad.height + 40
				];
				var curY:Int = (fadeOut ? 1 : 0);
				
				sprBlack.y = yPos[curY];
				updateGradPos();

				FlxTween.tween(sprBlack, {y: yPos[curY + 1]}, fadeOut ? 0.6 : 0.8, {
					onComplete: function(twn:FlxTween)
					{
						endTransition();
					}
				});
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
	
	function updateGradPos():Void {
		if (sprGrad != null && sprBlack != null) {
			sprGrad.y = sprBlack.y + (fadeOut ? -sprGrad.height : sprBlack.height);
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		switch(transition) {
			case 'funkin':
				updateGradPos();
			default:
		}
	}
}
