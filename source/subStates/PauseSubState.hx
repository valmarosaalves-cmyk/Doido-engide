import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxRect;
import flixel.group.FlxGroup.FlxTypedGroup;

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

        // 1. Fundo escurecido
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.6;
        add(bg);

        // 2. O Retângulo Central (Menu)
        bgBox = new FlxSprite().makeGraphic(400, 500, FlxColor.BLACK);
        bgBox.alpha = 0.8;
        bgBox.screenCenter();
        add(bgBox);

        // 3. Retângulo do Topo (Onde passa o nome da música)
        topRect = new FlxSprite(bgBox.x + 10, bgBox.y + 10).makeGraphic(380, 50, 0xFF222222);
        add(topRect);

        // 4. Texto da Música (Estilo Rádio)
        songText = new FlxText(topRect.x + topRect.width, topRect.y + 12, 0, PlayState.SONG.song, 24);
        songText.setFormat(Paths.font("pixel-game.regular.otf"), 24, FlxColor.WHITE, LEFT);
        
        // Define a área de corte (Mask) para o texto não sair do retângulo
        textMask = new FlxRect(0, 0, topRect.width, topRect.height);
        songText.clipRect = textMask;
        add(songText);

        // 5. Itens do Menu
        grpMenuShit = new FlxTypedGroup<FlxText>();
        add(grpMenuShit);

        for (i in 0...menuItems.length)
        {
            var item:FlxText = new FlxText(0, bgBox.y + 150 + (i * 80), 0, menuItems[i], 32);
            item.setFormat(Paths.font("pixel-game.regular.otf"), 32, FlxColor.WHITE, CENTER);
            item.screenCenter(X);
            item.ID = i;
            grpMenuShit.add(item);
        }

        changeSelection();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        // Movimentação do Texto (Efeito Rádio Antigo)
        songText.x -= elapsed * 100; // Velocidade do scroll
        
        // Se o texto sair totalmente da esquerda do retângulo, volta para a direita
        if (songText.x + songText.width < topRect.x) {
            songText.x = topRect.x + topRect.width;
        }

        // Ajuste dinâmico do ClipRect para manter o corte perfeito
        songText.clipRect = new FlxRect(topRect.x - songText.x, 0, topRect.width, topRect.height);

        // Controles de navegação
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
                    PlayState.deathCounter = 0;
                    PlayState.seenCutscene = false;
                    MusicBeatState.switchState(new MainMenuState());
            }
        }
    }

    function changeSelection(change:Int = 0):Void
    {
        curSelected += change;

        if (curSelected < 0)
            curSelected = menuItems.length - 1;
        if (curSelected >= menuItems.length)
            curSelected = 0;

        grpMenuShit.forEach(function(txt:FlxText)
        {
            txt.color = FlxColor.WHITE;
            txt.alpha = 0.6;

            if (txt.ID == curSelected)
            {
                txt.color = FlxColor.YELLOW;
                txt.alpha = 1;
            }
        });
    }
			}
			
