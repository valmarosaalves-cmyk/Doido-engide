package substates;

import states.PlayState;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.math.FlxMath;

class PauseSubState extends MusicBeatSubState
{
    var options:Array<String> = ["Resume", "Restart Song", "Exit To Menu"];
    var text:FlxText;
    var title:FlxText;
    var cur:Int = 0;

    public function new()
    {
        super();
        var bg = new FlxSprite().makeColor(FlxG.width + 10, FlxG.height + 10, 0xFF000000);
        bg.alpha = 0.4;
        add(bg);

        text = new FlxText(10, 0, 0, '');
		text.setFormat(Main.globalFont, 48, 0xFFFFFFFF, LEFT);
		text.setOutline(0xFF000000, 3);
		add(text);
        drawText();
        text.y = FlxG.height - text.height - 10;

        //add the song title to the other side (was dissapearing for sm reason)
        title = new FlxText(10, 10, 0, PlayState.SONG.song);
		title.setFormat(Main.globalFont, 48, 0xFFFFFFFF, RIGHT);
		title.setOutline(0xFF000000, 5);
		add(title);
    }

    function drawText() {
        text.text = "";
        for(i in 0...options.length)
            text.text += (i == cur ? "> " : "") + options[i] + "\n";
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(Controls.justPressed(UI_UP))
            changeSelection(-1);
        if(Controls.justPressed(UI_DOWN))
            changeSelection(1);

        if (Controls.justPressed(ACCEPT))
        {
            switch(options[cur].toLowerCase()) {
                case 'resume':
                    close();
                case 'restart song':
                    MusicBeat.skip = true;
			        MusicBeat.switchState(new states.PlayState());
                case 'exit to menu':
			        MusicBeat.switchState(new states.DebugMenu());

            }
        }

        if(Controls.justPressed(BACK))
			close();
    }

    override function close() {
        PlayState.instance.unpauseSong();
        super.close();
    }

    public function changeSelection(change:Int = 0)
	{
		if(change != 0) FlxG.sound.play(Assets.sound('scroll'));
		
		cur += change;
		cur = FlxMath.wrap(cur, 0, options.length - 1);
		drawText();
	}
}