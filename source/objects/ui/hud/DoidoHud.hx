package objects.ui.hud;

class DoidoHud extends BaseHud
{
    public function new()
    {
        super("doido");

        add(ratingGrp);
        
        scoreTxt = new FlxBitmapText(10, 0, Assets.bitmapFont("vcr"));
		scoreTxt.setOutline(0xFF000000, 2);
        scoreTxt.alignment = CENTER;
		add(scoreTxt);
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

    override function updateScoreTxt()
    {
        scoreTxt.text = "";
        scoreTxt.text += 'Score: ' + FlxStringUtil.formatMoney(Timings.score, false, true) + separator;
		scoreTxt.text += 'Accuracy: ' + Timings.accuracy + "%" + ' [${Timings.getRank()}]' + separator;
		scoreTxt.text += 'Misses: ' + Timings.misses;

        scoreTxt.y = (playState.playField.bfStrumline.downscroll ? 50 : FlxG.height - scoreTxt.height - 50);
        scoreTxt.screenCenter(X);
        //scoreTxt.floorPos();
    }
}