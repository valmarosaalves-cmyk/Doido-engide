package substates;

import states.PlayState;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

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
        creditsText.alpha = 1;
        add(creditsText);

        drawCreditsText();
        creditsFade();
    }

    function drawOptionsText() {
        optionText.text = "";
        for(i in 0...options.length)
            optionText.text += (i == cur ? "> " : "") + options[i] + "\n";
    }

    var curCredit:Int = 0;
    function drawCreditsText()
    {
        creditsText.text = (curCredit == 0 ?
            'Composer: ' + PlayState.META.composer + "\n" :
            'Charter: ' + PlayState.META.charter+ "\n"
        );

        creditsText.x = FlxG.width - (creditsText.width + 12);
        creditsText.updateHitbox();

        curCredit++;
        curCredit = FlxMath.wrap(curCredit, 0, 1);
    }

    var creditsTween:FlxTween;
    var fadeDelay:Float = 5;
    var fadeDuration:Float = 0.75;
    function creditsFade()
    {
        creditsTween = FlxTween.tween(creditsText, {alpha: 0.0}, fadeDuration, {
            startDelay: fadeDelay,
            ease: FlxEase.quartOut,
            onComplete: (_) ->
            {
                //drawCreditsText();
                FlxTween.tween(creditsText, {alpha: 1.0}, fadeDuration, {
                ease: FlxEase.quartOut,
                onComplete: (_) ->
                {
                    creditsFade();
                }
                });
            }
        });
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