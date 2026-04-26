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
	
	var selecionouSim:Bool = true; // Controle de qual botão está focado

	override public function create():Void 
	{
		super.create();

		// 1. Adicionando a sua imagem de fundo
		avisoImg = new FlxSprite().loadGraphic(Paths.image('aviso!'));
		avisoImg.screenCenter();
		add(avisoImg);

		// 2. Configurando o texto principal
		// Definimos uma largura (ex: 500) para o texto não vazar da imagem
		var mensagem:String = "Cuidado: esse jogo tem partes que podem prejudicar quem tem epilepsia. Deseja desabilitar as luzes piscantes?";
		
		popUpTxt = new FlxText(0, 0, 550, mensagem); // 550 é a largura máxima
		popUpTxt.setFormat(Main.gFont, 28, FlxColor.WHITE, CENTER);
		popUpTxt.screenCenter();
		popUpTxt.y -= 40; // Sobe um pouco para dar espaço aos botões
		add(popUpTxt);

		// 3. Criando os botões Sim e Não
		btnSim = new FlxText(avisoImg.x + 100, popUpTxt.y + 150, 0, "SIM");
		btnSim.setFormat(Main.gFont, 32, FlxColor.WHITE, CENTER);
		add(btnSim);

		btnNao = new FlxText(avisoImg.x + avisoImg.width - 200, popUpTxt.y + 150, 0, "NÃO");
		btnNao.setFormat(Main.gFont, 32, FlxColor.WHITE, CENTER);
		add(btnNao);

		atualizarSelecao();
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		// Controles para alternar entre Sim e Não
		if (Controls.justPressed(UI_LEFT) || Controls.justPressed(UI_RIGHT)) {
			selecionouSim = !selecionouSim;
			atualizarSelecao();
		}

		if(Controls.justPressed(ACCEPT))
		{
			// Aqui salvamos a preferência do jogador
			// Se selecionou SIM, desabilitamos as luzes (flashing)
			FlxG.save.data.flashing = !selecionouSim; 
			
           	Init.flagState();
            FlxG.save.data.beenWarned = true;
            FlxG.save.flush();
        }
	}

	function atualizarSelecao() {
		// Muda a cor para mostrar qual está selecionado
		if (selecionouSim) {
			btnSim.color = FlxColor.YELLOW;
			btnNao.color = FlxColor.WHITE;
		} else {
			btnSim.color = FlxColor.WHITE;
			btnNao.color = FlxColor.YELLOW;
		}
	}
}
