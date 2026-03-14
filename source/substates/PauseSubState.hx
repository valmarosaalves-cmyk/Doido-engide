package substates;

import states.PlayState;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.math.FlxMath;

class PauseSubState extends MusicBeatSubState
{
    var options:Array<String> = ["Resume", "Restart Song", "Exit To Menu"];
    var optionText:FlxText;
    var title:FlxText;
    var creditsText:FlxText;
    var cur:Int = 0;

    public function new()
    {
        super();
        var bg = new FlxSprite().makeColor(FlxG.width + 10, FlxG.height + 10, 0xFF000000);
        bg.alpha = 0.4;
        add(bg);

        optionText = new FlxText(10, 0, 0, '');
		optionText.setFormat(Main.globalFont, 48, 0xFFFFFFFF, LEFT);
		optionText.setOutline(0xFF000000, 3);
		add(optionText);
        drawOptionsText();
        optionText.y = FlxG.height - optionText.height - 10;

        // add the song title
        title = new FlxText(10, 10, 0, PlayState.SONG.song);
		title.setFormat(Main.globalFont, 36, 0xFFFFFFFF, RIGHT);
		title.setOutline(0xFF000000, 2);
        title.x = FlxG.width - title.width - 10;
		add(title);

        //  add the credits text
        creditsText = new FlxText(10, title.y + 30, 0, "");
        creditsText.setFormat(Main.globalFont, 36, 0xFFFFFFFF, RIGHT);
		creditsText.setOutline(0xFF000000, 2);
        drawCreditsText();
        add(creditsText);
    }

    function drawOptionsText() {
        optionText.text = "";
        for(i in 0...options.length)
            optionText.text += (i == cur ? "> " : "") + options[i] + "\n";
    }

    /**
     * Function that draws credits text.
     * if any of the credits fields are missing (null), they're skipped.
     */
    function drawCreditsText()
    {
        if(PlayState.META.composer != null)
            creditsText.text += 'Composer: ' + PlayState.META.composer + "\n";
        if(PlayState.META.charter != null)
            creditsText.text += 'Charter: ' + PlayState.META.charter+ "\n";
        if(PlayState.META.artist != null)
            creditsText.text += 'Artist: ' + PlayState.META.artist;

        //if the credits text is empty, it gets destroyed.
        // not really needed but since flxtext is a bitch, ill keep it.
        if(creditsText.text == "")
        {
            creditsText.kill();
            creditsText.destroy();
            return;
        }

        creditsText.x = FlxG.width - (creditsText.width + 12);
        creditsText.updateHitbox();
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
		drawOptionsText();
	}
}