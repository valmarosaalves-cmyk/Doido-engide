package doido.song;

typedef ScoreData =
{
	var score:Float;
	var accuracy:Float;
	var misses:Int;
}

class Highscore
{
	public static var scores:Map<String, ScoreData> = [];

	public static function addScore(song:String, newScore:ScoreData)
	{
		var oldScore:ScoreData = getScore(song);

		if ((newScore.score > oldScore.score))
			scores.set(song, newScore);

		save();
	}

	public static function getScore(song:String):ScoreData
	{
		if (!scores.exists(song))
			return {score: 0, accuracy: 0, misses: 0};
		else
			return scores.get(song);
	}

	public static function save(?file:DoidoSave)
	{
		if (file == null)
			file = new DoidoSave("highscore");

		file.data.scores = scores;
		file.close();
	}

	public static function load()
	{
		var file = new DoidoSave("highscore");

		if (file.data.scores == null)
			file.data.scores = scores;
		scores = file.data.scores;

		save(file);
	}
}
