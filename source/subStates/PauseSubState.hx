package substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.Flx.group.FlxGroup.FlxTypeGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTweens;
import backend.MusicBeatSubstate;
import backend.Paths;
import states.PlayState;

class PauseSubState extends MusicBeatSubstate
{
  var grpmenuShit: FlxTypeGroup<Alphabet>;
  var menuItems:Array<String> = ['resume', 'restart', 'botplay', 'exit'];
  var curSelected:Int = 0;
  
  var bg:FlxSprite;
  var retangulo:FlxSprite;
  var caixaMusica:FlxSprite
  var levelnfo:FlxText
  groupMenuShit = new
  FlxTypeGroup<Alphabet>();
  for (i in 0...menuItems.lenght)
}
var MenuItems:Alphabet = new Alphabet (0, (i * 100) + 250,MenuItems[i], true);
menuItems.isMenuItem = true;
menuItems.targetY = i;
menuItems.screemCenter(X);
menuItems.ID = i;

groupMenuShit.add(menuItems);
}
    function changeSelection(change:Int = 0):Void
    {
        curSelected += change;

        if (curSelected < 0)
            curSelected = menuItems.length - 1;
        if (curSelected >= menuItems.length)
            curSelected = 0;

        var bullShit:Int = 0;

        for (item in grpMenuShit.members)
        {
            item.targetY = bullShit - curSelected;
            bullShit++;

            item.alpha = 0.6; // Deixa os outros botões meio transparentes

            if (item.ID == curSelected)
            {
                item.alpha = 1; // Deixa o selecionado bem visível
            }
        }
    }
    override function update(elapsed:Float)
    {
        super.update(elapsed);

        // Controles para subir e descer
        if (controls.UI_UP_P) changeSelection(-1);
        if (controls.UI_DOWN_P) changeSelection(1);

        // Quando você aperta ENTER ou ESPAÇO
        if (controls.ACCEPT)
        {
            var daSelected:String = menuItems[curSelected];

            switch (daSelected)
            {
                case "Resume":
                    close(); // Fecha o menu e volta pro jogo
                case "Restart":
                    restartSong(); // Função padrão da Psych para reiniciar
                case "Botplay":
                    PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
                    PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
                case "Exit":
                    PlayState.deathCounter = 0;
                    MusicBeatState.switchState(new states.MainMenuState());
            }
        }
    }
