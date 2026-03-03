package substates;

import states.PlayState;
import flixel.text.FlxText;
import flixel.FlxSprite;

class PauseSubState extends MusicBeatSubState
{
    public function new()
    {
        super();
        var bg = new FlxSprite().makeColor(FlxG.width + 10, FlxG.height + 10, 0xFF000000);
        bg.alpha = 0.4;
        add(bg);

        var text = new FlxText(10, 0, 0, 'PAUSED');
		text.setFormat(Main.globalFont, 18, 0xFFFFFFFF, CENTER);
		text.setOutline(0xFF000000, 1.5);
		text.antialiasing = false;
        text.screenCenter();
        text.floorPos();
		add(text);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if (Controls.justPressed(ACCEPT))
        {
            close();
            PlayState.instance.unpauseSong();
        }

        if(Controls.justPressed(BACK)) {
			MusicBeat.switchState(new states.DebugMenu());
		}
    }
}