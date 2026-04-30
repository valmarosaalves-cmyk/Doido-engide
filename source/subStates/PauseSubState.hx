package; // Ou o package específico da sua pasta de substates

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxRect;
import flixel.group.FlxGroup.FlxTypedGroup;
// Estes imports abaixo são os que costumam dar erro de substate:
import backend.MusicBeatSubstate;
import backend.Paths;
import backend.Controls;

class CustomPauseScript extends MusicBeatSubstate
{
    var menuItems:Array<String> = ['Resume', 'Restart Song', 'Exit to Menu'];
    var grpMenuShit:FlxTypedGroup<FlxText>;
    var curSelected:Int = 0;

    var bgBox:FlxSprite;
    var topRect:FlxSprite;
    var songText:FlxText;
    var textMask:FlxRect;

    public function new()
    {
        super();

        // 1. Fundo Escurecido
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.6;
        bg.scrollFactor.set();
        add(bg);

        // 2. O Quadrado/Menu Central
        bgBox = new FlxSprite().makeGraphic(450, 550, FlxColor.BLACK);
        bgBox.alpha = 0.8;
        bgBox.screenCenter();
        bgBox.scrollFactor.set();
        add(bgBox);

        // 3. Retângulo do Topo (Letreiro)
        topRect = new FlxSprite(bgBox.x + 25, bgBox.y + 20).makeGraphic(400, 60, 0xFF1A1A1A);
        topRect.scrollFactor.set();
        add(topRect);

        // 4. Texto da Música (Efeito Rádio)
        // Usamos o nome da música atual
        var playingMusic:String = "Tocando: " + states.PlayState.SONG.song;
        
        songText = new FlxText(topRect.x + topRect.width, topRect.y + 15, 0, playingMusic, 28);
        songText.setFormat(Paths.font("pixel-game.regular.otf"), 28, FlxColor.WHITE, LEFT);
        songText.scrollFactor.set();
        
        // Criando a máscara para o texto não sair do retângulo
        songText.clipRect = new FlxRect(0, 0, topRect.width, topRect.height);
        add(songText);

        // 5. Opções do Menu
        grpMenuShit = new FlxTypedGroup<FlxText>();
        add(grpMenuShit);

        for (i in 0...menuItems.length)
        {
            var item:FlxText = new FlxText(0, bgBox.y + 180 + (i * 90), 0, menuItems[i], 35);
            item.setFormat(Paths.font("pixel-game.regular.otf"), 35, FlxColor.WHITE, CENTER);
            item.screenCenter(X);
            item.ID = i;
            item.scrollFactor.set();
            grpMenuShit.add(item);
        }

        changeSelection();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        // Lógica do Letreiro Correndo (Rádio Antigo)
        songText.x -= elapsed * 120; // Velocidade

        // Se o texto sumir na esquerda, ele reseta na direita do retângulo
        if (songText.x < topRect.x - songText.width) {
            songText.x = topRect.x + topRect.width;
        }

        // Atualiza a máscara de corte em tempo real
        // Isso garante que o texto só apareça "dentro" do topRect
        songText.clipRect = new FlxRect(topRect.x - songText.x, 0, topRect.width, topRect.height);

        // Controles de Navegação
        if (controls.UI_UP_P) changeSelection(-1);
        if (controls.UI_DOWN_P) changeSelection(1);

        if (controls.ACCEPT)
        {
            var daChoice:String = menuItems[curSelected];
            switch (daChoice)
            {
                case 'Resume':
                    close();
                case 'Restart Song':
                    FlxG.resetState();
                case 'Exit to Menu':
                    states.PlayState.deathCounter = 0;
                    states.PlayState.seenCutscene = false;
                    MusicBeatState.switchState(new states.MainMenuState());
            }
        }
    }

    function changeSelection(change:Int = 0):Void
    {
        curSelected += change;

        if (curSelected < 0) curSelected = menuItems.length - 1;
        if (curSelected >= menuItems.length) curSelected = 0;

        grpMenuShit.forEach(function(txt:FlxText)
        {
            txt.color = FlxColor.WHITE;
            txt.alpha = 0.5;

            if (txt.ID == curSelected)
            {
                txt.color = FlxColor.YELLOW;
                txt.alpha = 1;
            }
        });
    }
			}
			
