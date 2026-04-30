package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxRect;
import flixel.group.FlxGroup.FlxTypedGroup;

// Se der erro aqui, a gente troca por FlxSubState
class CustomPauseScript extends backend.MusicBeatSubstate
{
    var menuItems:Array<String> = ['Resume', 'Restart', 'Exit'];
    var grpMenu:FlxTypedGroup<FlxText>;
    var curSelected:Int = 0;

    var bgBox:FlxSprite;
    var topRect:FlxSprite;
    var songText:FlxText;

    public function new()
    {
        super();

        // Fundo transparente
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.6;
        bg.scrollFactor.set();
        add(bg);

        // Menu Centralizado
        bgBox = new FlxSprite().makeGraphic(400, 500, FlxColor.BLACK);
        bgBox.alpha = 0.8;
        bgBox.screenCenter();
        bgBox.scrollFactor.set();
        add(bgBox);

        // Retângulo do Letreiro (Topo do menu)
        topRect = new FlxSprite(bgBox.x + 20, bgBox.y + 20).makeGraphic(360, 50, 0xFF222222);
        topRect.scrollFactor.set();
        add(topRect);

        // Texto da Música (Estilo Rádio)
        // Pegando o nome da música direto da PlayState
        var name:String = "Tocando agora: " + states.PlayState.SONG.song + "  ";
        songText = new FlxText(topRect.x + 10, topRect.y + 10, 0, name, 22);
        songText.setFormat(backend.Paths.font("pixel-game.regular.otf"), 22, FlxColor.WHITE, LEFT);
        
        // A MÁGICA: O ClipRect faz o texto não sair do retângulo
        songText.clipRect = new FlxRect(0, 0, topRect.width, topRect.height);
        add(songText);

        // Opções do Menu
        grpMenu = new FlxTypedGroup<FlxText>();
        add(grpMenu);

        for (i in 0...menuItems.length)
        {
            var item:FlxText = new FlxText(0, bgBox.y + 150 + (i * 80), 0, menuItems[i], 32);
            item.setFormat(backend.Paths.font("pixel-game.regular.otf"), 32, FlxColor.WHITE, CENTER);
            item.screenCenter(X);
            item.ID = i;
            item.scrollFactor.set();
            grpMenu.add(item);
        }

        changeSelection();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        // Movimento do rádio (Letreiro)
        songText.x -= elapsed * 100;
        if (songText.x < topRect.x - songText.width) {
            songText.x = topRect.x + topRect.width;
        }

        // Ajuste constante da máscara para não vazar pro menu
        songText.clipRect = new FlxRect(topRect.x - songText.x, 0, topRect.width, topRect.height);

        // Controles
        if (controls.UI_UP_P) changeSelection(-1);
        if (controls.UI_DOWN_P) changeSelection(1);

        if (controls.ACCEPT)
        {
            switch (menuItems[curSelected])
            {
                case 'Resume': close();
                case 'Restart': FlxG.resetState();
                case 'Exit': MusicBeatState.switchState(new states.MainMenuState());
            }
        }
    }

    function changeSelection(change:Int = 0):Void
    {
        curSelected += change;
        if (curSelected < 0) curSelected = menuItems.length - 1;
        if (curSelected >= menuItems.length) curSelected = 0;

        grpMenu.forEach(function(txt:FlxText) {
            txt.alpha = (txt.ID == curSelected) ? 1 : 0.5;
            txt.color = (txt.ID == curSelected) ? FlxColor.YELLOW : FlxColor.WHITE;
        });
    }
			}
			
