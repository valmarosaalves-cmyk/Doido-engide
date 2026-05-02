package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class WarningState extends MusicBeatState
{
	var avisoImg:FlxSprite;
	var popUpTxt:FlxText;
	var btnSim:FlxText;
	var btnNao:FlxText;
	
	var selecionouSim:Bool = true; 

	override public function create():Void 
	{
		super.create();

		// Fundo preto de segurança para garantir que nada apareça atrás
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		// 1. Carregar a imagem
		// DICA: Certifique-se que o arquivo 1000523347.png está em: assets/images/
		avisoImg = new FlxSprite();
		avisoImg.loadGraphic(Paths.image('aviso!')); 
		
		avisoImg.antialiasing = true; // Deixa a imagem mais bonita
		avisoImg.scrollFactor.set();
		avisoImg.updateHitbox();
		avisoImg.screenCenter();
		add(avisoImg);

		// Se a imagem ainda estiver pequena demais, aumente aqui:
		avisoImg.scale.set(2, 2); 
		avisoImg.updateHitbox();
		avisoImg.screenCenter();

		// 2. Texto de Aviso
		var mensagem:String = "Cuidado! Este jogo tem partes que podem prejudicar quem tem epilepsia. Deseja desabilitar as luzes piscantes?";
		
		popUpTxt = new FlxText(0, 0, 550, mensagem); 
		popUpTxt.setFormat(Main.gFont, 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		popUpTxt.borderSize = 2;
		popUpTxt.screenCenter();
		popUpTxt.y -= 30; 
		add(popUpTxt);

		// 3. Botões
		btnSim = new FlxText(0, popUpTxt.y + 150, 0, "SIM");
		btnSim.setFormat(Main.gFont, 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		btnSim.x = FlxG.width / 2 - 150;
		add(btnSim);

		btnNao = new FlxText(0, popUpTxt.y + 150, 0, "NÃO");
		btnNao.setFormat(Main.gFont, 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		btnNao.x = FlxG.width / 2 + 80;
		add(btnNao);

		atualizarVisualBotoes();
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		if (Controls.justPressed(UI_LEFT) || Controls.justPressed(UI_RIGHT)) {
			selecionouSim = !selecionouSim;
			FlxG.sound.play(Paths.sound('menu/scrollMenu')); 
			atualizarVisualBotoes();
		}

		if(Controls.justPressed(ACCEPT))
		{
			FlxG.save.data.flashing = !selecionouSim; 
            FlxG.save.data.beenWarned = true;
            FlxG.save.flush();
            
            FlxG.sound.play(Paths.sound('menu/confirmMenu'));
            
            // Vai para o Init
            Init.flagState(); 
        }
	}

	function atualizarVisualBotoes() {
		if (selecionouSim) {
			btnSim.color = FlxColor.YELLOW;
			btnNao.color = FlxColor.WHITE;
			btnSim.scale.set(1.2, 1.2);
			btnNao.scale.set(1, 1);
		} else {
			btnSim.color = FlxColor.WHITE;
			btnNao.color = FlxColor.YELLOW;
			btnSim.scale.set(1, 1);
			btnNao.scale.set(1.2, 1.2);
		}
	}
}

