package states.editors;

import doido.song.AudioHandler;
import doido.song.Conductor;
import doido.song.chart.SongHandler.DoidoEvents;
import doido.song.chart.SongHandler.DoidoSong;
import doido.utils.NoteUtil;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.tweens.FlxTween;
import objects.ui.notes.Note;

class ChartingState extends MusicBeatState
{
    public static var GRID_SIZE:Int = 40;
    public static var GRID_X:Int = 358;

    public var grid:ChartingGrid;
    public var timeBar:FlxSprite;

    var audio:AudioHandler;
    public var playingSong:Bool = false;

    public var SONG:DoidoSong;
    public var EVENTS:DoidoEvents;

    public var renderNotes:FlxTypedGroup<ChartingNote>;

    public function new(SONG:DoidoSong, EVENTS:DoidoEvents)
    {
        super();
        this.SONG = SONG;
        this.EVENTS = EVENTS;
    }

    override function create()
    {
        super.create();
        FlxG.mouse.visible = true;
        Conductor.initialBPM = SONG.bpm;
		Conductor.mapBPMChanges(EVENTS.events);
		Conductor.songPos = 0;

        audio = new AudioHandler(SONG.song);

        if(NoteUtil.directions.length == 0)
            NoteUtil.setUpDirections(4);

        var bg = new FlxSprite().loadGraphic(Assets.image('menuChartEditor'));
		bg.screenCenter();
		add(bg);

        grid = new ChartingGrid(GRID_X, audio.length);
        add(grid);

        renderNotes = new FlxTypedGroup<ChartingNote>();
        add(renderNotes);

        timeBar = new FlxSprite(GRID_X).makeColor(GRID_SIZE * 8, 4, 0xFFFF0000);
        timeBar.screenCenter(Y);
        add(timeBar);
    }

    var tweeningSongPos:Bool = false;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        // debug camera lol
        if (FlxG.keys.justPressed.NINE || FlxG.keys.justPressed.NUMPADNINE)
            FlxG.camera.zoom = (FlxG.camera.zoom == 1.0 ? 0.8 : 1.0);

        if (tweeningSongPos)
            playingSong = false;
        else
        {
            if (FlxG.keys.justPressed.SPACE) playingSong = !playingSong;
            
            if (FlxG.mouse.wheel != 0)
            {
                playingSong = false;
                Conductor.songPos -= FlxG.mouse.wheel * 10000 * elapsed;
            }
        }

        if (playingSong)
        {
            if (!audio.playing && Conductor.songPos >= 0)
                audio.play(Conductor.songPos);
            
            Conductor.songPos += elapsed * 1000;
        }
        else
        {
            if (audio.playing) audio.pause();
        }

        if (Conductor.songPos < 0) Conductor.songPos = 0;
        if (Conductor.songPos >= audio.length)
        {
            Conductor.songPos = audio.length;
            playingSong = false;
        }

        if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.D)
        {
            var dir = (FlxG.keys.justPressed.A ? -1 : 1) * (FlxG.keys.pressed.SHIFT ? 4 : 1);
            tweenSongPos(
                getSectionStart(
                    Conductor.songPos + ((Conductor.crochet * 4 + 10) * dir)
                )
            );
        }

        if (!tweeningSongPos)
        {
            if (FlxG.keys.justPressed.R)
            {
                if (FlxG.keys.pressed.SHIFT)
                {
                    if (Conductor.songPos <= 10000)
                        tweenSongPos(0, 0.25, FlxEase.cubeInOut);
                    else
                    {
                        FlxTween.tween(FlxG.camera, {zoom: 1.3}, 1.6, {ease: FlxEase.cubeIn, startDelay: 0.4});
                        tweenSongPos(0, 2, FlxEase.cubeIn, (twn) -> {
                            FlxTween.completeTweensOf(FlxG.camera);
                            FlxTween.tween(FlxG.camera, {zoom: 1.0}, 0.1, {ease: FlxEase.cubeOut});
                            FlxG.camera.shake(0.02, 0.15);
                        });
                    }
                }
                else
                {
                    tweenSongPos(getSectionStart());
                }
            }
        }

        if (FlxG.mouse.pressedMiddle) {
            timeBar.y = FlxG.mouse.y;
            lastDraw = Math.NEGATIVE_INFINITY;
        }

        grid.gridY = (timeBar.y + (timeBar.height / 2)) - FlxMath.remapToRange(
            Conductor.songPos,
            0, Conductor.stepCrochet,
            0, GRID_SIZE
        );
    }

    public function getSectionStart(?time:Float):Float
    {
        if (time == null) time = Conductor.songPos;

        var round:Float = (Conductor.crochet * 4);
        return Math.floor(time / round) * round;
    }

    public function tweenSongPos(target:Float, duration:Float = 0.1, ?ease:EaseFunction, ?onComplete:FlxTween->Void)
    {
        target = FlxMath.bound(target, 0, audio.length);

        tweeningSongPos = true;
        FlxTween.completeTweensOf(Conductor);
        FlxTween.tween(
            Conductor,
            {
                songPos: target,
            },
            duration,
            {
                ease: ease ?? FlxEase.cubeOut,
                onComplete: (twn) -> {
                    tweeningSongPos = false;
                    if (onComplete != null) onComplete(twn);
                }
            }
        );
    }

    var lastDraw:Float = Math.NEGATIVE_INFINITY;
    override function draw()
    {
        if (lastDraw != Conductor.songPos)
        {
            lastDraw = Conductor.songPos;
            for(note in renderNotes.members) {
                renderNotes.remove(note, true);
                note.kill();
            }

            for(noteData in SONG.notes)
            {
                var noteY:Float = grid.gridY + (noteData.stepTime * GRID_SIZE);
                if (noteY < -GRID_SIZE) continue;
                if (noteY > FlxG.height) break;
                
                var note:ChartingNote = cast renderNotes.recycle(ChartingNote);
                note.loadData(noteData);
                note.reloadSprite();

                note.setGraphicSize(GRID_SIZE, GRID_SIZE);
                note.updateHitbox();
                
                //note.setZ(2);
                renderNotes.add(note);
            }
        }

        for(note in renderNotes.members)
        {
            var noteY:Float = grid.gridY + (note.data.stepTime * GRID_SIZE);
            note.setPosition(
                grid.gridX + (note.data.lane * GRID_SIZE) + (note.data.strumline * GRID_SIZE * 4),
                noteY 
            );
        }

        super.draw();
    }

    override function stepHit()
    {
        super.stepHit();
        if (audio.playing && Conductor.songPos >= 0)
            audio.sync();
    }
}
class ChartingGrid extends FlxSprite
{
    public var GRID_SIZE:Float = 0.0;
    public var gridX:Float = 0.0;
    public var gridY:Float = 0.0;

    public var length:Float = 0.0;

    public var border:FlxSprite;
    public var sectBG:FlxSprite;
    public var sectText:FlxBitmapText;
    public var midLine:FlxSprite;
    public var beatLine:FlxSprite;

    public function new(x:Float, length:Float)
    {
        super();
        gridX = x;
        this.length = length;
        GRID_SIZE = ChartingState.GRID_SIZE;
        this.makeColor(GRID_SIZE, GRID_SIZE, 0xFFFFFFFF); // 358

        border = new FlxSprite(gridX - GRID_SIZE * 0.25).makeColor(GRID_SIZE * 8.5, FlxG.height, 0xFF1C1A24);

        sectBG = new FlxSprite().makeColor(1, 1, 0xFF1C1A24);

        sectText = new FlxBitmapText(0, 0, Assets.bitmapFont("vcr"));
        sectText.alignment = LEFT;
        
        midLine = new FlxSprite(gridX + GRID_SIZE * 4).makeColor(4, FlxG.height, 0xFF1C1A24);
        midLine.x -= midLine.width / 2;

        beatLine = new FlxSprite(gridX, 0).makeColor(GRID_SIZE * 8, 4, 0xFFFFFFFF);
    }

    override function draw()
    {
        border.draw();
        //super.draw();
        for (_y in 0...Math.floor(Conductor.getStepAtTime(length)))
        {
            var gridY:Float = gridY + (GRID_SIZE * _y);
            if (gridY < -GRID_SIZE) continue;
            if (gridY > FlxG.height) break;

            for(_x in 0...8)
            {
                color = (((_x + _y) % 2 == 0) ? 0xFFEBEFFE : 0xFFD7D9F6);
                x = gridX + (GRID_SIZE * _x);
                y = gridY;
                super.draw();
            }

            if (_y % 4 == 0)
            {
                beatLine.color = (_y % 16 == 0) ? 0xFF1C1A24 : 0xFFA5B1E4;
                beatLine.scale.y = (_y % 16 == 0) ? 8 : 4;
                beatLine.updateHitbox();
                
                beatLine.y = gridY - (beatLine.height / 2);
                beatLine.draw();

                if (_y % 16 == 0)
                {
                    // section number
                    sectText.text = '${Math.floor(_y / 16)}';
                    sectText.x = (gridX + GRID_SIZE * 8);
                    sectText.y = beatLine.y;

                    sectBG.x = sectText.x;
                    sectBG.y = sectText.y;
                    sectBG.scale.set(sectText.width + 12, sectText.height + 12);
                    sectBG.updateHitbox();

                    sectText.x += (sectBG.width - sectText.width) / 2;
                    sectText.y += (sectBG.height- sectText.height)/ 2;

                    sectBG.draw();
                    sectText.draw();
                }
            }
        }
        midLine.draw();
    }
}
class ChartingNote extends Note
{
    public function new()
    {
        super();
    }
}