package objects.ui.hud;

class DoidoHud extends BaseHud
{
    public var scoreTxt:FlxBitmapText;
    public var healthBar:DoidoBar;

    public function new()
    {
        super("doido");
        add(ratingGrp);

        healthBar = new DoidoBar("hud/base/healthBar", "hud/base/healthBar-border");
        healthBar.sideL.color = 0xFFFF0000;
        healthBar.sideR.color = 0xFF66FF33;
		add(healthBar);
        
        scoreTxt = new FlxBitmapText(10, 0, Assets.bitmapFont("vcr"));
		scoreTxt.setOutline(0xFF000000, 2);
        scoreTxt.alignment = CENTER;
		add(scoreTxt);

        updatePositions();
    }

    override function popUpRating(ratingName:String = ""):RatingSprite
    {
        var rating = super.popUpRating(ratingName);
        
        rating.screenCenter();
        rating.defaultAnim();

        return rating;
    }

    override function popUpCombo(comboNum:Int):Array<ComboSprite>
    {
        var numberArray = super.popUpCombo(comboNum);
        
        for (number in numberArray)
        {
            number.y += 100;
            number.defaultAnim();
        }

        return numberArray;
    }

    override function updatePositions() {
        super.updatePositions();

        healthBar.x = (FlxG.width / 2) - (healthBar.border.width / 2);
		healthBar.y = (Save.data.downscroll ? 70 : FlxG.height - healthBar.border.height - 50);
        scoreTxt.y = healthBar.y + healthBar.border.height + 8;
    }

    override function updateScoreTxt()
    {
        scoreTxt.text = "";
        scoreTxt.text += 'Score: ' + FlxStringUtil.formatMoney(Timings.score, false, true) + separator;
		scoreTxt.text += 'Accuracy: ' + Timings.accuracy + "%" + ' [${Timings.getRank()}]' + separator;
		scoreTxt.text += 'Misses: ' + Timings.misses;

        scoreTxt.screenCenter(X);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        healthBar.percent = (play.health * 50);
    }
}