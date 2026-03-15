package objects.ui.hud;

import flixel.math.FlxMath;
import objects.ui.hud.BaseHud.IconChange;
import doido.song.Conductor;

class DoidoHud extends BaseHud
{
    public var scoreTxt:FlxBitmapText;
	public var timeTxt:FlxBitmapText;

    public var healthBar:DoidoBar;
    public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

    public function new(play:Playable)
    {
        super("doido", play);
		add(numberGrp);
        add(ratingGrp);

        healthBar = new DoidoBar("hud/base/healthBar", "hud/base/healthBar-border");
		add(healthBar);

        iconP1 = new HealthIcon();
		changeIcon(play.player1, PLAYER);
		add(iconP1);

		iconP2 = new HealthIcon();
		changeIcon(play.player2, ENEMY);
		add(iconP2);
        
        scoreTxt = new FlxBitmapText(0, 0, Assets.bitmapFont("vcr"));
		scoreTxt.setOutline(0xFF000000, 2);
        scoreTxt.alignment = CENTER;
		add(scoreTxt);

		timeTxt = new FlxBitmapText(0, 0, Assets.bitmapFont("vcr"));
		timeTxt.setOutline(0xFF000000, 2);
        timeTxt.alignment = CENTER;
		timeTxt.scale.set(1.4,1.4);
		timeTxt.updateHitbox();
		add(timeTxt);

        updatePositions();
    }

    override function popUpRating(ratingName:String = ""):RatingSprite
    {
        var rating = super.popUpRating(ratingName);
		rating.ratingScale = 0.7;
        rating.screenCenter(X);
		if(Save.data.middlescroll) rating.x -= FlxG.width / 4;
		rating.y = ratingPos;
        rating.defaultAnim();
        return rating;
    }

    override function popUpCombo(comboNum:Int):Array<ComboSprite>
    {
        var numberArray = super.popUpCombo(comboNum);
        
        for (number in numberArray) {
			if(Save.data.middlescroll) number.x -= FlxG.width / 4;
            number.y = ratingPos + 75;
            number.defaultAnim();
        }

        return numberArray;
    }

	var ratingPos(get, never):Int;
	function get_ratingPos():Int
		return Save.data.downscroll ? FlxG.height - 150 : 65;

	override function positionCombo(numberArray:Array<ComboSprite>) {
		for(number in numberArray) number.numberScale = 0.7;
        super.positionCombo(numberArray);
    }

    override function updatePositions() {
        super.updatePositions();

        healthBar.x = (FlxG.width / 2) - (healthBar.border.width / 2);
		healthBar.y = (Save.data.downscroll ? 70 : FlxG.height - healthBar.border.height - 50);
        scoreTxt.y = healthBar.y + healthBar.border.height + 8;

		updateTimeTxt();
		timeTxt.y = Save.data.downscroll ? (FlxG.height - timeTxt.height - 14) : (14);
    }

    override function updateScoreTxt()
    {
        var scoreText:String = "";
		scoreText += 'Misses: ' + Timings.misses + separator;
		scoreText += 'Accuracy: ' + Timings.accuracy + "%" + ' [${Timings.getRank()}]' + separator;
		scoreText += 'Score: ' + FlxStringUtil.formatMoney(Timings.score, false, true);

		scoreTxt.text = scoreText;
        scoreTxt.screenCenter(X);
    }

	public var songTime:Float = 0.0;
	function updateTimeTxt()
	{
		if(!timeTxt.visible) return;
		songTime = FlxMath.bound(Conductor.songPos, 0, play.songLength);
		timeTxt.text
			= TextUtil.posToTimer(songTime)
			+ " / "
			+ TextUtil.posToTimer(play.songLength);
		timeTxt.screenCenter(X);
	}

    override function update(elapsed:Float) {
        super.update(elapsed);
        healthBar.percent = (health * 50);

        for(icon in [iconP1, iconP2])
		{
			icon.scale.set(
				FlxMath.lerp(icon.scale.x, 1, FlxG.elapsed * 6),
				FlxMath.lerp(icon.scale.y, 1, FlxG.elapsed * 6)
			);
			if(!icon.isPlayer)
				icon.setAnim(2 - play.health);
			else
				icon.setAnim(play.health);

			icon.updateHitbox();
		}
		updateIconPos();
		updateTimeTxt();
    }

    public function updateIconPos() {
		var healthBarPos:DoidoPoint = {
			x: healthBar.x + FlxMath.lerp(healthBar.border.width, 0, healthBar.percent / 100),
			y: healthBar.y - (healthBar.border.height / 2)
        };

		iconP1.y = healthBarPos.y - (iconP1.height / 2);
		iconP2.y = healthBarPos.y - (iconP2.height / 2);

		iconP1.x = healthBarPos.x - 20;
		iconP2.x = healthBarPos.x - iconP2.width + 32;
	}

    override function changeIcon(newIcon:String = "face", type:IconChange = ENEMY) {
		super.changeIcon(newIcon, type);
		var isPlayer:Bool = (type == PLAYER);
		var icon = (isPlayer ? iconP1 : iconP2);
		icon.setIcon(newIcon, isPlayer);

		(isPlayer ? healthBar.sideR : healthBar.sideL).color = icon.barColor;
	}

	override function beatHit(curBeat:Int = 0) {
		super.beatHit(curBeat);
		if(curBeat % 2 == 0)
		{
			for(icon in [iconP1, iconP2])
			{
				icon.scale.set(1.3,1.3);
				icon.updateHitbox();
				updateIconPos();
			}
		}
	}
}