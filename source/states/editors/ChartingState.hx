package states.editors;

import flixel.util.FlxTimer;
import doido.utils.EditorUtil;
import doido.song.chart.SongHandler.NoteData;
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
import objects.ui.DebugInfo;
import objects.ui.notes.Note;
import shaders.MultiplyShader;
import haxe.Json;

class ChartingState extends MusicBeatState
{
    public static var GRID_SIZE:Int = 40;
    public static var GRID_LANES:Int = 8;

    public var noFunAllowed:Bool = false; // reduced animations
    
    public var audio:AudioHandler;
    public var playingSong:Bool = false;

    public var SONG:DoidoSong;
    public var EVENTS:DoidoEvents;

    public var grid:ChartingGrid;
    public var timeBar:FlxSprite;
    public var renderNotes:FlxTypedGroup<ChartingNote>;

    public var selectedShader:MultiplyShader;

    // editor stuff
    public var selectedNotes:Array<NoteData> = [];
    public var draggingSelectedNotes:Bool = false;
    public var hoverSquare:FlxSprite;
    public var selectSquare:FlxSprite;

    public var lastClicked:DoidoPoint = {x: 0, y: 0};
    public var lastClickedOffset:Float = 0.0;
    public var lastMouseStep:Null<Float>;
    public var lastMouseLane:Null<Int>;
    public var heldOnNote:Bool = false;

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

        grid = new ChartingGrid(358, audio.length);
        add(grid);

        renderNotes = new FlxTypedGroup<ChartingNote>();
        add(renderNotes);

        selectedShader = new MultiplyShader();
        selectedShader.multiplyColor = 0xFF0078D4;

        timeBar = new FlxSprite(grid.gridX).makeColor(GRID_SIZE * GRID_LANES, 4, 0xFFFF0000);
        timeBar.screenCenter(Y);
        timeBar.offset.y = timeBar.height / 2;
        add(timeBar);

        hoverSquare = new FlxSprite().makeColor(GRID_SIZE, GRID_SIZE, 0xFFFFFFFF);
        hoverSquare.visible = false;
        hoverSquare.alpha = 0.7;
        add(hoverSquare);

        selectSquare = new FlxSprite().makeColor(1, 1, 0xFF0078D4);
        selectSquare.visible = false;
        selectSquare.alpha = 0.5;
        add(selectSquare);

        var debugInfo = new DebugInfo(this);
        debugInfo.visible = true;
        add(debugInfo);
    }

    var tweeningSongPos:Bool = false;

    override function update(elapsed:Float)
    {
        // debug camera lol
        if (FlxG.keys.justPressed.NINE || FlxG.keys.justPressed.NUMPADNINE)
            FlxG.camera.zoom = (FlxG.camera.zoom == 1.0 ? 0.8 : 1.0);

        if (tweeningSongPos)
            playingSong = false;
        else
        {
            if (FlxG.keys.justPressed.SPACE) playingSong = !playingSong;
        }

        if (FlxG.mouse.justPressed)
        {
            lastClicked = {x: FlxG.mouse.x, y: FlxG.mouse.y};
            lastClickedOffset = grid.gridY;
        }

        if (FlxG.mouse.justReleased)
        {
            heldOnNote = false;
        }

        if (lastClickedOffset != grid.gridY)
        {
            lastClicked.y -= (lastClickedOffset - grid.gridY);
            lastClickedOffset = grid.gridY;
        }

        if (FlxG.mouse.pressed)
        {
            // if you moved 10 pixels from it
            if (Math.abs(FlxG.mouse.x - lastClicked.x) >= 10
            || Math.abs(FlxG.mouse.y - lastClicked.y) >= 10)
            {
                if (selectedNotes.length > 0)
                {
                    if (heldOnNote)
                        draggingSelectedNotes = true;
                    else
                        selectSquare.visible = true;
                }
                else
                    selectSquare.visible = true;
            }

            if (!playingSong)
            {
                var mouseMove:Int = 60;
                if (FlxG.mouse.y < mouseMove
                || FlxG.mouse.y > FlxG.height - mouseMove)
                {
                    var dir:Int = (FlxG.mouse.y < mouseMove) ? -1 : 1;
                    if (FlxG.mouse.y < mouseMove / 2
                    || FlxG.mouse.y > FlxG.height - mouseMove / 2)
                        dir *= 4;
                    
                    Conductor.songPos += dir * 1000 * elapsed;
                }
            }
        }

        if (selectedNotes.length > 0)
        {
            selectedShader.multiplyOpacity = 0.8 + Math.sin(FlxG.game.ticks / 100) * 0.4;

            if (FlxG.keys.justPressed.DELETE)
            {
                for(note in selectedNotes)
                {
                    playSfx("editors/pop", FlxG.random.float(0.0, 0.4));
                    SONG.notes.remove(note);
                }
                selectedNotes = [];
                sortNotes();
            }
        }
        
        if (selectSquare.visible)
        {
            hoverSquare.visible = false;

            selectSquare.scale.set(
                Math.abs(FlxG.mouse.x - lastClicked.x),
                Math.abs(FlxG.mouse.y - lastClicked.y)
            );
            selectSquare.updateHitbox();
            
            if (FlxG.mouse.x < lastClicked.x)
                selectSquare.x = lastClicked.x - selectSquare.width;
            else
                selectSquare.x = lastClicked.x;

            if (FlxG.mouse.y < lastClicked.y)
                selectSquare.y = lastClicked.y - selectSquare.height;
            else
                selectSquare.y = lastClicked.y;

            if (FlxG.mouse.justReleased)
            {
                if (!FlxG.keys.pressed.CONTROL) selectedNotes = [];

                var startY:Float = Math.floor((selectSquare.y - grid.gridY) / GRID_SIZE);
                var endY:Float = startY + Math.floor(selectSquare.height / GRID_SIZE);
                var startX:Float = Math.floor((selectSquare.x - grid.gridX) / GRID_SIZE);
                var endX:Float = startX + Math.floor(selectSquare.width / GRID_SIZE);

                for (note in SONG.notes)
                {
                    var rawLane:Int = note.lane + (4 * note.strumline);

                    if(note.stepTime > startY - 1
                    && note.stepTime < endY + 1
                    && rawLane > startX - 1
                    && rawLane < endX + 1)
                    {
                        if (!selectedNotes.contains(note))
                            selectedNotes.push(note);
                    }
                }

                selectSquare.visible = false;
            }
        }
        else
        {
            if (FlxG.mouse.x > grid.gridX && FlxG.mouse.x < grid.gridX + GRID_SIZE * GRID_LANES
            && FlxG.mouse.y > grid.gridY && FlxG.mouse.y < grid.gridY + GRID_SIZE * grid.gridLength)
            {
                var mouseStep:Float = (FlxG.mouse.y - grid.gridY) / GRID_SIZE;
                if(!FlxG.keys.pressed.ALT) mouseStep = Math.floor(mouseStep);
                var mouseLane:Int = Math.floor((FlxG.mouse.x - grid.gridX) / GRID_SIZE);

                hoverSquare.visible = true;
                hoverSquare.setPosition(
                    grid.gridX + mouseLane * GRID_SIZE,
                    grid.gridY + mouseStep * GRID_SIZE
                );

                if (FlxG.mouse.justPressedRight)
                    selectedNotes = [];
                
                if (FlxG.mouse.overlaps(renderNotes))
                {
                    EditorUtil.setCursor(POINTER);
                    if (FlxG.mouse.pressedRight)
                    {
                        //EditorUtil.setCursor();
                        var removed:Bool = false;
                        for(note in renderNotes.members)
                        {
                            if (FlxG.mouse.overlaps(note))
                            {
                                removed = true;
                                SONG.notes.remove(note.data);
                            }
                        }
                        if (removed)
                        {
                            playSfx("editors/pop");
                            sortNotes();
                        }
                    }
                    if (FlxG.mouse.justPressed)
                    {
                        //selectedNotes = [];
                        heldOnNote = true;
                        var clearNote:NoteData = null;
                        for(note in renderNotes.members)
                        {
                            if (FlxG.mouse.overlaps(note))
                            {
                                if (FlxG.keys.pressed.CONTROL)
                                {
                                    if (!selectedNotes.contains(note.data))
                                        selectedNotes.push(note.data);
                                    else
                                        selectedNotes.remove(note.data);
                                }
                                else
                                {
                                    if (!selectedNotes.contains(note.data))
                                        clearNote = note.data;
                                }
                            }
                        }

                        lastMouseStep = mouseStep;
                        lastMouseLane = mouseLane;

                        if (clearNote != null)
                            selectedNotes = [clearNote];

                        sortNotes();
                    }
                }
                else
                {
                    if (FlxG.mouse.justReleased)
                    {
                        if (!draggingSelectedNotes)
                        {
                            playSfx("editors/click");
                            var newNote:NoteData = {
                                stepTime: mouseStep,
                                lane: (mouseLane % 4),
                                strumline: (mouseLane >= 4) ? 1 : 0,
                                type: "none",
                                length: 0.0,
                            };
                            //trace('added lane ${newNote.lane} to strumline ${newNote.strumline}');
                            SONG.notes.push(newNote);
                            selectedNotes = [newNote];
                            sortNotes();
                        }
                    }
                }

                if(draggingSelectedNotes)
                {
                    EditorUtil.setCursor(MOVE);
                    if (FlxG.mouse.justReleased)
                    {
                        draggingSelectedNotes = false;
                        playSfx("editors/click");
                        for(note in selectedNotes)
                        {
                            note.stepTime -= (lastMouseStep - mouseStep);
                            if(note.stepTime < 0 || note.stepTime > grid.gridLength)
                            {
                                SONG.notes.remove(note); // BE CAREFUL!!
                                continue;
                            }

                            note.lane -= (lastMouseLane - mouseLane);
                            while (note.lane < 0)
                            {
                                note.lane += 4;
                                note.strumline -= 1;
                                if (note.strumline < 0)
                                    note.strumline = 1;
                            }
                            while (note.lane > 3)
                            {
                                note.lane %= 4;
                                note.strumline += 1;
                                if (note.strumline > 1)
                                    note.strumline = 0;
                            }
                        }
                        sortNotes();
                    }
                }
            }
            else
                hoverSquare.visible = false;
        }

        if (FlxG.mouse.wheel != 0)
        {
            playingSong = false;
            stopTweenSongPos();
            Conductor.songPos += -FlxG.mouse.wheel * 10000 * elapsed * (FlxG.keys.pressed.SHIFT ? 4 : 1);
        }

        if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
        {
            playingSong = false;
            stopTweenSongPos();
            var dir:Int = (FlxG.keys.pressed.S ? 1 : 0) - (FlxG.keys.pressed.W ? 1 : 0);
            Conductor.songPos += dir * 1000 * elapsed * (FlxG.keys.pressed.SHIFT ? 4 : 1);
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
            var wasA:Bool = FlxG.keys.justPressed.A;
            if (wasA && FlxG.keys.pressed.CONTROL)
            {
                selectedNotes = [];
                for(note in SONG.notes)
                    selectedNotes.push(note);
            }
            else
            {
                var dir = (wasA ? -1 : 1) * (FlxG.keys.pressed.SHIFT ? 4 : 1);
                tweenSongPos(getSectionStart(curStepFloat + 1 + (16 * dir)));
            }
        }

        if (FlxG.keys.justPressed.R)
        {
            if (FlxG.keys.pressed.SHIFT)
            {
                if (!tweeningSongPos)
                {
                    if (Conductor.songPos <= 10000 || noFunAllowed)
                        tweenSongPos(0, 0.25, FlxEase.cubeInOut);
                    else
                    {
                        FlxTween.tween(FlxG.camera, {zoom: 1.3}, 1.6, {ease: FlxEase.cubeIn, startDelay: 0.4});
                        tweenSongPos(0, 2, FlxEase.cubeIn, (twn) -> {
                            playSfx("editors/clank");
                            FlxTween.completeTweensOf(FlxG.camera);
                            FlxTween.tween(FlxG.camera, {zoom: 1.0}, 0.1, {ease: FlxEase.cubeOut});
                            FlxG.camera.shake(0.02, 0.15);
                        });
                    }
                }
                else
                {
                    FlxTween.completeTweensOf(Conductor);
                    
                }
            }
            else
            {
                tweenSongPos(getSectionStart());
            }
        }

        if (FlxG.mouse.pressedMiddle) {
            timeBar.y = FlxG.mouse.y;
            
        }

        if (FlxG.keys.justPressed.ENTER)
        {
            PlayState.SONG = SONG;
            PlayState.EVENTS = EVENTS;
            MusicBeat.switchState(new PlayState());
        }

        if (FlxG.keys.justPressed.EIGHT || FlxG.keys.justPressed.NUMPADEIGHT)
            noFunAllowed = !noFunAllowed;

        if(FlxG.keys.justPressed.S && FlxG.keys.pressed.CONTROL)
            save();

        grid.gridY = timeBar.y - (curStepFloat * GRID_SIZE);
        super.update(elapsed);
    }

    function save() {
        var data:String = Json.stringify(SONG, "\t");
        if(data != null && data.length > 0)
        {
            Assets.fileSave(
                data.trim(),
                '${SONG.song}.json'
            );
        }

        var data:String = Json.stringify(EVENTS, "\t");
        if(data != null && data.length > 0)
        {
            Assets.fileSave(
                data.trim(),
                '${SONG.song}-events.json'
            );
        }
    }

    public function getSectionStart(?step:Float):Float
    {
        if (step == null) step = curStepFloat;

        return Conductor.getTimeAtStep(Math.floor(step / 16) * 16);
    }

    public function stopTweenSongPos()
    {
        if (tweeningSongPos)
            tweenSongPos(getSectionStart());
    }

    public function tweenSongPos(target:Float, duration:Float = 0.1, ?ease:EaseFunction, ?onComplete:FlxTween->Void)
    {
        target = FlxMath.bound(target, 0, audio.length);
        if (noFunAllowed) duration = 0;

        FlxTween.completeTweensOf(Conductor);
        tweeningSongPos = true;
        
        if (duration == 0)
        {
            Conductor.songPos = target;
            tweeningSongPos = false;
        }
        else
            FlxTween.tween(
                Conductor, { songPos: target },
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

    public function sortNotes()
    {
        SONG.notes.sort(NoteUtil.sortNotes);
        
    }
    
    public function playSfx(key:String, pitchShift:Bool = true, startDelay:Float = 0.0)
    {
        var sfx = FlxG.sound.load(Assets.sound(key));
        if (pitchShift) sfx.pitch = FlxG.random.float(0.8, 1.2);
        if (startDelay <= 0.0)
            sfx.play();
        else
            new FlxTimer().start(startDelay, (tmr) -> {
                sfx.play();
            });
    }

    override function draw()
    {
        for(note in renderNotes.members) {
            note.kill();
        }

        for(noteData in SONG.notes)
        {
            var noteY:Float = grid.gridY + (noteData.stepTime * GRID_SIZE);
            var noteHeight:Float = GRID_SIZE * (noteData.length + 1);
            if (noteY < -noteHeight) continue;
            if (noteY > FlxG.height) break;
            
            var note:ChartingNote = cast renderNotes.recycle(ChartingNote);
            note.loadData(noteData);
            note.reloadSprite();

            note.setGraphicSize(GRID_SIZE, GRID_SIZE);
            note.updateHitbox();

            if (selectedNotes.contains(noteData))
                note.shader = selectedShader;
            else
                note.shader = null;

            if (noteData.stepTime < curStepFloat)
                note.alpha = 0.4;
            
            note.setZ(2);
            note.setPosition(
                grid.gridX + (note.data.lane * GRID_SIZE) + (note.data.strumline * GRID_SIZE * GRID_LANES / 2),
                noteY
            );

            if (!renderNotes.members.contains(note)) renderNotes.add(note);

            if (noteData.length > 0)
            {
                var hold:ChartingNote = cast renderNotes.recycle(ChartingNote);
				hold.loadData(noteData);
                hold.isHold = true;
                hold.reloadSprite();
                
                hold.setGraphicSize(
                    GRID_SIZE * 0.25,
                    GRID_SIZE * (noteData.length + 0.5)
                );
                hold.updateHitbox();
                
                hold.setPosition(
                    note.x + (GRID_SIZE - hold.width) / 2,
                    note.y + (GRID_SIZE / 2)
                );
                hold.alpha = note.alpha;
                hold.shader = note.shader;

				hold.holdParent = note; // idk you might need it
				hold.setZ(1);

                if (!renderNotes.members.contains(note)) renderNotes.add(hold);
            }
        }

        renderNotes.sort(ZIndex.sort);

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
    public var gridLength:Int = 0;

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
        this.makeColor(GRID_SIZE, GRID_SIZE, 0xFFFFFFFF);

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
        gridLength = Math.ceil(Conductor.getStepAtTime(length));
        for (_y in 0...gridLength)
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