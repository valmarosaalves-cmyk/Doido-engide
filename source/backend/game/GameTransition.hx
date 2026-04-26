package backend.game;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
import backend.game.MusicBeatData.MusicBeatSubState;

class GameTransition extends MusicBeatSubState
{	
	var fadeOut:Bool = false;
	public var finishCallback:Void->Void;
	var cubeGroup:FlxTypedGroup<FlxSprite>;
	
	public function new(fadeOut:Bool = true, transition:String = "cubes")
	{
		super();
		this.fadeOut = fadeOut;

		cubeGroup = new FlxTypedGroup<FlxSprite>();
		add(cubeGroup);

		// Tamanho do cubo e colunas/linhas
		var size:Int = 100; 
		var cols:Int = Math.ceil(FlxG.width / size) + 1;
		var rows:Int = Math.ceil(FlxG.height / size) + 1;
		
		for (row in 0...rows) {
			for (col in 0...cols) {
				// Cria o cubo (um pouco menor que o slot para parecer cubo individual)
				var cube:FlxSprite = new FlxSprite(col * size, row * size).makeGraphic(size - 4, size - 4, 0xFF000000);
				cube.antialiasing = true;
				cubeGroup.add(cube);
				
				// Se for Entrada (fadeOut = false), os cubos começam invisíveis e pequenos
				// Se for Saída (fadeOut = true), eles já estão lá e somem
				if (!fadeOut) {
					cube.scale.set(0, 0);
					cube.alpha = 0;
					
					// Delay baseado na posição (faz um efeito de onda diagonal)
					var delay:Float = (col + row) * 0.05;
					
					FlxTween.tween(cube.scale, {x: 1, y: 1}, 0.4, {ease: FlxEase.cubeOut, startDelay: delay});
					FlxTween.tween(cube, {alpha: 1}, 0.3, {
						ease: FlxEase.quadOut, 
						startDelay: delay,
						onComplete: function(twn:FlxTween) {
							if (row == rows - 1 && col == cols - 1) endTransition();
						}
					});
				} else {
					// Saindo da tela: os cubos diminuem até sumir
					cube.scale.set(1, 1);
					var delay:Float = (col + row) * 0.05;
					
					FlxTween.tween(cube.scale, {x: 0, y: 0}, 0.4, {ease: FlxEase.cubeIn, startDelay: delay});
					FlxTween.tween(cube, {alpha: 0}, 0.3, {
						ease: FlxEase.quadIn, 
						startDelay: delay,
						onComplete: function(twn:FlxTween) {
							if (row == rows - 1 && col == cols - 1) endTransition();
						}
					});
				}
			}
		}
	}

	function endTransition() {
		if(finishCallback != null) finishCallback();
		else close();
	}
	
	override function update(elapsed:Float) {
		super.update(elapsed);
		if (FlxG.cameras.list.length > 0)
			this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}
}

