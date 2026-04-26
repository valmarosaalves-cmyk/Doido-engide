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
	
	// Variável para saber qual botão está selecionado (Sim ou Não)
	var selecionouSim:Bool = true; 

	override public function create():Void 
	{
		super.create();

		// 1. Carregar a imagem de fundo
		avisoImg = new FlxSprite().loadGraphic(Paths.image('1000523347')); // Nome do seu PNG
		
		// AJUSTE DE TAMANHO: Aumente os números abaixo se o PNG estiver pequeno
		avisoImg.scale.set(1.2, 1.2); 
		avisoImg.updateHitbox(); // Garante que o Haxe entenda o novo tamanho para centralizar
		avisoImg.screenCenter();
		add(avisoImg);

		// 2. Texto de Aviso
		// O número 450 define a largura máxima. Se o texto bater ali, ele pula linha.
		var mensagem:String = "Cuidado! Este jogo tem partes que podem prejudicar quem tem epilepsia. Deseja desabilitar as luzes piscantes?";
		
		popUpTxt = new FlxText(0, 0, 450, mensagem); 
		popUpTxt.setFormat(Main.gFont, 24, FlxColor.WHITE, CENTER);
		popUpTxt.screenCenter();
		popUpTxt.y -= 30; // Ajusta a altura para não ficar em cima dos botões
		add(popUpTxt);

		// 3. Botões de Escolha
		// Posicionados em relação à imagem de aviso
		btnSim = new FlxText(avisoImg.x + 80, popUpTxt.y + 140, 0, "SIM");
		btnSim.setFormat(Main.gFont, 32, FlxColor.WHITE, CENTER);
		add(btnSim);

		btnNao = new FlxText(avisoImg.x + avisoImg.width - 160, popUpTxt.y + 140, 0, "NÃO");
		btnNao.setFormat(Main.gFont, 32, FlxColor.WHITE, CENTER);
		add(btnNao);

		atualizarVisualBotoes();
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		// Troca a seleção com as setas esquerda/direita
		if (Controls.justPressed(UI_LEFT) || Controls.justPressed(UI_RIGHT)) {
			selecionouSim = !selecionouSim;
			FlxG.sound.play(Paths.sound('scrollMenu')); // Som opcional de menu
			atualizarVisualBotoes();
		}

		if(Controls.justPressed(ACCEPT))
		{
			// Se o jogador escolher SIM, desabilitamos o Flashing (luzes)
			// Se escolher NÃO, deixamos ativo.
			FlxG.save.data.flashing = !selecionouSim; 
			
           	Init.flagState(); // Continua para o próximo estado do jogo
            FlxG.save.data.beenWarned = true;
            FlxG.save.flush();
        }
	}

	function atualizarVisualBotoes() {
		// Destaca o botão selecionado mudando a cor
		if (selecionouSim) {
			btnSim.color = FlxColor.YELLOW;
			btnNao.color = FlxColor.WHITE;
		} else {
			btnSim.color = FlxColor.WHITE;
			btnNao.color = FlxColor.YELLOW;
		}
	}
}
