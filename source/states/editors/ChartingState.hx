package states.editors;

import objects.ui.notes.Note;
import flixel.group.FlxGroup.FlxTypedGroup;
import doido.song.AudioHandler;
import doido.song.Conductor;
import doido.song.chart.SongHandler.DoidoEvents;
import doido.song.chart.SongHandler.DoidoSong;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import doido.utils.NoteUtil;

class ChartingState extends MusicBeatState
{
    public static var GRID_SIZE:Int = 40;
    public static var GRID_X:Int = 358;

    public var grid:ChartingGrid;
    public var timeBar:FlxSprite;

    var audio:AudioHandler;
    public var playing:Bool = false;

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

        var bg = new FlxSprite().loadGraphic(Assets.image('menuInvert'));
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

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.SPACE) playing = !playing;

        if (playing)
        {
            if (!audio.playing && Conductor.songPos >= 0)
                audio.play(Conductor.songPos);
            
            Conductor.songPos += elapsed * 1000;
            //audio.sync();
        }
        else
        {
            if (audio.playing) audio.pause();
        }
        
        if (FlxG.mouse.wheel != 0)
        {
            playing = false;
            Conductor.songPos -= FlxG.mouse.wheel * 10000 * elapsed;
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
    public var beatLine:FlxSprite;

    public function new(x:Float, length:Float)
    {
        super();
        gridX = x;
        this.length = length;
        GRID_SIZE = ChartingState.GRID_SIZE;
        this.makeColor(GRID_SIZE, GRID_SIZE, 0xFFFFFFFF); // 358

        border = new FlxSprite(gridX - GRID_SIZE * 0.25).makeColor(GRID_SIZE * 8.5, FlxG.height, 0xFF1C1A24);

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
                beatLine.y = gridY;
                beatLine.draw();
            }
        }
    }
}
class ChartingNote extends Note
{
    public function new()
    {
        super();
    }
}