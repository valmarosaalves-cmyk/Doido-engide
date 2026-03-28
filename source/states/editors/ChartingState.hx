package states.editors;

import doido.objects.ui.*;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import doido.utils.EditorUtil;
import doido.song.chart.SongHandler.NoteData;
import doido.song.AudioHandler;
import doido.song.Conductor;
import doido.song.chart.SongHandler.DoidoSong;
import doido.song.chart.SongHandler.DoidoChart;
import doido.song.chart.SongHandler.DoidoEvents;
import doido.song.chart.SongHandler.DoidoMeta;
import doido.utils.NoteUtil;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.tweens.FlxTween;
import objects.ui.DebugInfo;
import objects.ui.notes.Note;
import shaders.MultiplyShader;
import haxe.Json;

class ChartingNote extends Note
{
	public function new()
	{
		super();
	}
}

class ChartingState extends MusicBeatState
{
	public static var GRID_SIZE:Int = 40;
	public static var GRID_LANES:Int = 8;

	public static var noFunAllowed:Bool = false; // reduced animations

	public var audio:AudioHandler;
	public var playingSong:Bool = false;

	public var SONG:DoidoSong;

	public var cursorTxt:FlxBitmapText;

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
	public var heldOnNoteHold:Bool = false;

	// windows!!
	public var timeWindow:TimeWindow;

	public function new(SONG:DoidoSong)
	{
		super();
		this.SONG = SONG;
	}

	override function create()
	{
		super.create();
		FlxG.mouse.visible = true;
		Conductor.initialBPM = CHART.bpm;
		Conductor.mapBPMChanges(EVENTS.events);
		Conductor.songPos = 0;

		audio = new AudioHandler(CHART.song);

		if (NoteUtil.directions.length == 0)
			NoteUtil.setUpDirections(4);

		var bg = new FlxSprite().loadGraphic(Assets.image('menuChartEditor'));
		bg.screenCenter();
		add(bg);

		hoverSquare = new FlxSprite().makeColor(GRID_SIZE, GRID_SIZE, 0xFFFFFFFF);
		hoverSquare.visible = false;
		hoverSquare.alpha = 0.7;
		// add(hoverSquare);

		grid = new ChartingGrid(358, audio.length, hoverSquare);
		add(grid);

		renderNotes = new FlxTypedGroup<ChartingNote>();
		add(renderNotes);

		selectedShader = new MultiplyShader();
		selectedShader.multiplyColor = 0xFF0078D4;

		timeBar = new FlxSprite(grid.gridX).makeColor(GRID_SIZE * GRID_LANES, 4, 0xFFFF0000);
		timeBar.screenCenter(Y);
		add(timeBar);

		selectSquare = new FlxSprite().makeColor(1, 1, 0xFF0078D4);
		selectSquare.visible = false;
		selectSquare.alpha = 0.5;
		add(selectSquare);

		timeWindow = new TimeWindow(this);
		add(timeWindow);

		var debugInfo = new DebugInfo(this);
		// debugInfo.visible = true;
		add(debugInfo);

		cursorTxt = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
		cursorTxt.setOutline(0xFF000000, 2);
		cursorTxt.alignment = LEFT;
		cursorTxt.scale.set(0.7, 0.7);
		cursorTxt.updateHitbox();
	}

	public var tweeningSongPos:Bool = false;
	public var curCursor:lime.ui.MouseCursor = DEFAULT;

	var clickedOnWindow:Bool = false;

	var autoScrolling:Bool = false;
	var scrollAutoY:Float = 0;
	override function update(elapsed:Float)
	{
		// debug camera lol
		if (FlxG.keys.justPressed.NINE || FlxG.keys.justPressed.NUMPADNINE)
			FlxG.camera.zoom = (FlxG.camera.zoom == 1.0 ? 0.8 : 1.0);

		curCursor = DEFAULT;
		if (tweeningSongPos)
			playingSong = false;
		else
		{
			if (FlxG.keys.justPressed.SPACE)
				playingSong = !playingSong;
		}

		var overlapsWindow:Bool = false;

		for (basic in members)
		{
			if (Std.isOfType(basic, BaseWindow))
			{
				if (FlxG.mouse.overlaps(cast(basic, BaseWindow).bg))
				{
					overlapsWindow = true;
					/*if (FlxG.mouse.justPressed)
						clickedOnWindow = true; */
				}
			}
		}

		if (FlxG.mouse.justPressed)
			clickedOnWindow = overlapsWindow;

		var cursorText:String = "";
		if (FlxG.keys.pressed.SHIFT)
			cursorText = "4x";

		if (!clickedOnWindow)
		{
			if (FlxG.mouse.pressedRight)
				cursorText = "X";

			if (FlxG.mouse.justPressed)
			{
				lastClicked = {x: FlxG.mouse.x, y: FlxG.mouse.y};
				lastClickedOffset = grid.gridY;
			}

			if (FlxG.mouse.justReleased)
			{
				heldOnNote = false;
				// heldOnNoteHold = false;
			}

			if (lastClickedOffset != grid.gridY)
			{
				lastClicked.y -= (lastClickedOffset - grid.gridY);
				lastClickedOffset = grid.gridY;
			}

			if (FlxG.mouse.pressed)
			{
				// if you moved 10 pixels from it
				if (Math.abs(FlxG.mouse.x - lastClicked.x) >= 10 || Math.abs(FlxG.mouse.y - lastClicked.y) >= 10)
				{
					if (selectedNotes.length > 0)
					{
						if (heldOnNote)
							draggingSelectedNotes = true;
						else if (!heldOnNoteHold)
							selectSquare.visible = true;
					}
					else
						selectSquare.visible = true;
				}

				if (!playingSong)
				{
					var mouseMove:Int = 60;
					if (FlxG.mouse.y < mouseMove || FlxG.mouse.y > FlxG.height - mouseMove)
					{
						var dir:Int = (FlxG.mouse.y < mouseMove) ? -1 : 1;
						if (FlxG.mouse.y < mouseMove / 2 || FlxG.mouse.y > FlxG.height - mouseMove / 2)
							dir *= 4;

						Conductor.songPos += dir * 1000 * elapsed;
					}
				}
			}

			if (selectedNotes.length > 0)
			{
				selectedShader.multiplyOpacity = 0.8 + Math.sin(FlxG.game.ticks / 100) * 0.4;

				if (FlxG.keys.justPressed.Q || FlxG.keys.justPressed.E)
				{
					playSfx("editors/click");
					var dir:Int = FlxG.keys.justPressed.Q ? -1 : 1;
					if (FlxG.keys.pressed.SHIFT)
						dir *= 4;
					for (note in selectedNotes)
					{
						note.length += dir;
						if (note.length < 0)
							note.length = 0;
					}
				}

				if (FlxG.keys.justPressed.DELETE)
				{
					for (note in selectedNotes)
					{
						playSfx("editors/pop", FlxG.random.float(0.0, 0.4));
						CHART.notes.remove(note);
					}
					selectedNotes = [];
					sortNotes();
				}
			}

			if (selectSquare.visible)
			{
				hoverSquare.visible = false;

				selectSquare.scale.set(Math.abs(FlxG.mouse.x - lastClicked.x), Math.abs(FlxG.mouse.y - lastClicked.y));
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
					if (!FlxG.keys.pressed.CONTROL)
						selectedNotes = [];

					var startY:Float = Math.floor((selectSquare.y - grid.gridY) / GRID_SIZE);
					var endY:Float = startY + Math.floor(selectSquare.height / GRID_SIZE);
					var startX:Float = Math.floor((selectSquare.x - grid.gridX) / GRID_SIZE);
					var endX:Float = startX + Math.floor(selectSquare.width / GRID_SIZE);

					for (note in CHART.notes)
					{
						var rawLane:Int = note.lane + (4 * note.strumline);

						if (note.stepTime > startY - 1 && note.stepTime < endY + 1 && rawLane > startX - 1 && rawLane < endX + 1)
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
				if (FlxG.mouse.x > grid.gridX
					&& FlxG.mouse.x < grid.gridX + GRID_SIZE * GRID_LANES
					&& FlxG.mouse.y > grid.gridY
					&& FlxG.mouse.y < grid.gridY + GRID_SIZE * grid.gridLength)
				{
					var mouseStep:Float = getMouseStep();
					var mouseLane:Int = getMouseLane();

					hoverSquare.visible = true;
					hoverSquare.setPosition(grid.gridX + mouseLane * GRID_SIZE, grid.gridY + mouseStep * GRID_SIZE);

					if (FlxG.mouse.justPressedRight)
						selectedNotes = [];

					if (FlxG.mouse.overlaps(renderNotes))
					{
						var mightBeHold:Bool = false;

						curCursor = POINTER;
						for (note in renderNotes.members)
						{
							if (FlxG.mouse.overlaps(note))
							{
								// hold hitbox
								if ((note.isHold && FlxG.mouse.y > note.y + GRID_SIZE / 2)
									|| (!note.isHold && FlxG.mouse.y > note.y + GRID_SIZE * 0.75))
								{
									curCursor = RESIZE_NS;
									mightBeHold = true;
								}
							}
						}
						if (FlxG.mouse.pressedRight)
						{
							var removed:Bool = false;
							for (note in renderNotes.members)
							{
								if (FlxG.mouse.overlaps(note))
								{
									removed = true;
									if (note.isHold)
										CHART.notes[CHART.notes.indexOf(note.data)].length = 0;
									else
										CHART.notes.remove(note.data);
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
							if (mightBeHold)
								heldOnNoteHold = true;
							else
								heldOnNote = true;

							var clearNote:NoteData = null;
							for (note in renderNotes.members)
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
							if (!draggingSelectedNotes && !heldOnNoteHold)
							{
								playSfx("editors/click");
								var newNote:NoteData = {
									stepTime: mouseStep,
									lane: (mouseLane % 4),
									strumline: (mouseLane >= 4) ? 1 : 0,
									type: "none",
									length: 0.0,
								};
								// trace('added lane ${newNote.lane} to strumline ${newNote.strumline}');
								CHART.notes.push(newNote);
								selectedNotes = [newNote];
								sortNotes();
							}
						}
					}

					if (heldOnNoteHold)
					{
						curCursor = RESIZE_NS;
						if (FlxG.mouse.justReleased)
						{
							playSfx("editors/click");
							heldOnNoteHold = false;
							for (note in selectedNotes)
							{
								note.length -= (lastMouseStep - mouseStep);
								if (note.length < 0)
									note.length = 0;
							}
						}
					}

					if (draggingSelectedNotes)
					{
						curCursor = MOVE;
						if (FlxG.mouse.justReleased)
						{
							playSfx("editors/click");
							draggingSelectedNotes = false;
							for (note in selectedNotes)
							{
								note.stepTime -= (lastMouseStep - mouseStep);
								if (note.stepTime < 0 || note.stepTime > grid.gridLength)
								{
									CHART.notes.remove(note); // BE CAREFUL!!
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

			if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.D)
			{
				var wasA:Bool = FlxG.keys.justPressed.A;
				if (wasA && FlxG.keys.pressed.CONTROL)
				{
					selectedNotes = [];
					for (note in CHART.notes)
						selectedNotes.push(note);
				}
				else
				{
					changeSection(wasA ? -1 : 1);
				}
			}

			if (FlxG.keys.justPressed.R)
				resetSection();

			if (FlxG.keys.justPressed.ENTER)
			{
				PlayState.SONG = SONG;
				MusicBeat.switchState(new PlayState());
			}

			if (FlxG.keys.justPressed.EIGHT || FlxG.keys.justPressed.NUMPADEIGHT)
				noFunAllowed = !noFunAllowed;

			if (FlxG.keys.justPressed.S && FlxG.keys.pressed.CONTROL)
				save();
		}

		if (playingSong)
		{
			if (!audio.playing && Conductor.songPos >= 0)
				audio.play(Conductor.songPos);

			Conductor.songPos += elapsed * 1000;
		}
		else
		{
			if (audio.playing)
				audio.pause();
		}

		if (Conductor.songPos < 0)
			Conductor.songPos = 0;
		if (Conductor.songPos >= audio.length)
		{
			Conductor.songPos = audio.length;
			playingSong = false;
		}

		// if (FlxG.mouse.pressedMiddle)
		// {
		// 	timeBar.y = FlxG.mouse.y
		// }

		if(!playingSong) {
			if(FlxG.mouse.justPressedMiddle) {
				autoScrolling = !autoScrolling;
				scrollAutoY = FlxG.mouse.getWorldPosition().y;
			}

			if(autoScrolling) {
				Conductor.songPos += (FlxG.mouse.getWorldPosition().y - scrollAutoY) * 10 * elapsed * (FlxG.keys.pressed.SHIFT ? 4 : 1);
				curCursor = MOVE;
			}
		}

		grid.gridY = timeBar.y + (timeBar.height / 2) - (curStepFloat * GRID_SIZE);

		super.update(elapsed);
		EditorUtil.setCursor(curCursor);
		if (cursorTxt.text != cursorText)
		{
			cursorTxt.text = cursorText;
			cursorTxt.color = (cursorText == "X" ? 0xFFFF0000 : 0xFFFFFFFF);
		}
	}

	function save()
	{
		var data:String = Json.stringify(CHART, "\t");
		if (data != null && data.length > 0)
		{
			Assets.fileSave(data.trim(), '${CHART.song}.json');
		}

		var data:String = Json.stringify(EVENTS, "\t");
		if (data != null && data.length > 0)
		{
			Assets.fileSave(data.trim(), '${CHART.song}-events.json');
		}
	}

	public function getMouseStep():Float
	{
		var mouseStep:Float = (FlxG.mouse.y - grid.gridY) / GRID_SIZE;
		if (!FlxG.keys.pressed.ALT)
			mouseStep = Math.floor(mouseStep);
		return mouseStep;
	}

	public function getMouseLane():Int
	{
		return Math.floor((FlxG.mouse.x - grid.gridX) / GRID_SIZE);
	}

	public function getSectionStart(?step:Float):Float
	{
		if (step == null)
			step = curStepFloat;

		return Conductor.getTimeAtStep(Math.floor(step / 16) * 16);
	}

	public function stopTweenSongPos()
	{
		if (tweeningSongPos)
			tweenSongPos(getSectionStart());
	}

	public function changeSection(dir:Int)
	{
		dir *= (FlxG.keys.pressed.SHIFT ? 4 : 1);
		tweenSongPos(getSectionStart(curStepFloat + 1 + (16 * dir)));
	}

	public function resetSection()
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
					tweenSongPos(0, 2, FlxEase.cubeIn, (twn) ->
					{
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

	public function tweenSongPos(target:Float, duration:Float = 0.1, ?ease:EaseFunction, ?onComplete:FlxTween->Void)
	{
		target = FlxMath.bound(target, 0, audio.length);
		if (noFunAllowed)
			duration = 0;

		FlxTween.completeTweensOf(Conductor);
		tweeningSongPos = true;

		if (duration == 0)
		{
			Conductor.songPos = target;
			tweeningSongPos = false;
		}
		else
			FlxTween.tween(Conductor, {songPos: target}, duration, {
				ease: ease ?? FlxEase.cubeOut,
				onComplete: (twn) ->
				{
					tweeningSongPos = false;
					if (onComplete != null)
						onComplete(twn);
				}
			});
	}

	public function sortNotes()
	{
		CHART.notes.sort(NoteUtil.sortNotes);
	}

	public function playSfx(key:String, pitchShift:Bool = true, startDelay:Float = 0.0)
	{
		var sfx = FlxG.sound.load(Assets.sound(key));
		if (pitchShift)
			sfx.pitch = FlxG.random.float(0.8, 1.2);
		if (startDelay <= 0.0)
			sfx.play();
		else
			new FlxTimer().start(startDelay, (tmr) ->
			{
				sfx.play();
			});
	}

	override function draw()
	{
		for (note in renderNotes.members)
		{
			note.kill();
		}

		for (noteData in CHART.notes)
		{
			var noteY:Float = grid.gridY + (noteData.stepTime * GRID_SIZE);
			var noteHeight:Float = GRID_SIZE * (noteData.length + 1);
			if (noteY < -noteHeight)
				continue;
			if (noteY > FlxG.height)
				break;

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
			note.setPosition(grid.gridX + (note.data.lane * GRID_SIZE) + (note.data.strumline * GRID_SIZE * GRID_LANES / 2), noteY);

			if (!renderNotes.members.contains(note))
				renderNotes.add(note);

			if (noteData.length > 0)
			{
				var hold:ChartingNote = cast renderNotes.recycle(ChartingNote);
				hold.loadData(noteData);
				hold.isHold = true;
				hold.reloadSprite();

				hold.setGraphicSize(GRID_SIZE * 0.25, GRID_SIZE * (noteData.length + 0.5));
				hold.updateHitbox();

				hold.setPosition(note.x + (GRID_SIZE - hold.width) / 2, note.y + (GRID_SIZE / 2));
				hold.alpha = note.alpha;
				hold.shader = note.shader;

				hold.holdParent = note; // idk you might need it
				hold.setZ(1);

				if (!renderNotes.members.contains(note))
					renderNotes.add(hold);
			}
		}

		renderNotes.sort(ZIndex.sort);

		super.draw();

		if (cursorTxt.text != "")
		{
			cursorTxt.setPosition(FlxG.mouse.x + 18, FlxG.mouse.y + 18);
			cursorTxt.draw();
		}
	}

	override function stepHit()
	{
		super.stepHit();
		if (audio.playing && Conductor.songPos >= 0)
			audio.sync();
	}

	public var CHART(get, never):DoidoChart;

	public function get_CHART():DoidoChart
		return SONG.CHART;

	public var EVENTS(get, never):DoidoEvents;

	public function get_EVENTS():DoidoEvents
		return SONG.EVENTS;

	public var META(get, never):DoidoMeta;

	public function get_META():DoidoMeta
		return SONG.META;
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
	public var sectCap:FlxSprite;
	public var sectText:FlxBitmapText;
	public var midLine:FlxSprite;
	public var beatLine:FlxSprite;

	private var hoverSquare:FlxSprite;

	public function new(x:Float, length:Float, hoverSquare:FlxSprite)
	{
		super();
		gridX = x;
		this.length = length;
		this.hoverSquare = hoverSquare;
		GRID_SIZE = ChartingState.GRID_SIZE;
		this.makeColor(GRID_SIZE, GRID_SIZE, 0xFFFFFFFF);

		border = new FlxSprite(gridX - GRID_SIZE * 0.25).makeColor(GRID_SIZE * 8.5, FlxG.height, 0xFF1C1A24);

		sectBG = new FlxSprite().makeColor(1, 1, 0xFF1C1A24);
		sectCap = new FlxSprite().loadImage("editors/charting/sectionCap");

		sectText = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
		sectText.alignment = CENTER;
		sectText.scale.set(0.8, 0.8);
		sectText.updateHitbox();

		midLine = new FlxSprite(gridX + GRID_SIZE * 4).makeColor(4, FlxG.height, 0xFF1C1A24);
		midLine.x -= midLine.width / 2;

		beatLine = new FlxSprite(gridX, 0).makeColor(GRID_SIZE * 8, 4, 0xFFFFFFFF);
	}

	override function draw()
	{
		var minGrid:Int = 0;
		var maxGrid:Int = 0;

		border.draw();
		gridLength = Math.ceil(Conductor.getStepAtTime(length));
		for (_y in 0...gridLength)
		{
			var gridY:Float = gridY + (GRID_SIZE * _y);
			if (gridY < -GRID_SIZE)
			{
				minGrid++;
				continue;
			}
			maxGrid = _y + 1;
			if (gridY > FlxG.height)
				break;

			// grid squares
			for (_x in 0...8)
			{
				color = (((_x + _y) % 2 == 0) ? 0xFFEBEFFE : 0xFFD7D9F6);
				x = gridX + (GRID_SIZE * _x);
				y = gridY;
				super.draw();
			}
		}

		// hover squares
		if (hoverSquare.visible)
			hoverSquare.draw();

		for (_y in minGrid...maxGrid)
		{
			var gridY:Float = gridY + (GRID_SIZE * _y);
			// beat lines and section numbers
			if (_y % 4 == 0)
			{
				beatLine.color = (_y % 16 == 0) ? 0xFF1C1A24 : 0xFFA5B1E4;
				beatLine.scale.y = (_y % 16 == 0) ? 8 : 4;
				beatLine.updateHitbox();

				beatLine.y = gridY - (beatLine.height / 2);
				beatLine.draw();

				// section numbers
				if (_y % 16 == 0)
				{
					sectText.text = '${Math.floor(_y / 16)}'.lpad("0", 2);

					sectBG.scale.set(sectText.width + 12, sectText.height + 12);
					sectBG.updateHitbox();

					sectCap.scale.y = (sectBG.height / sectCap.frameHeight);
					sectCap.updateHitbox();

					sectBG.setPosition(border.x + border.width, gridY - (sectBG.height / 2));
					sectCap.setPosition(sectBG.x + sectBG.width - (sectCap.width / 2), sectBG.y);
					sectText.setPosition(sectBG.x + (12 / 2), sectBG.y + (12 / 2));
					sectCap.draw();
					sectBG.draw();
					sectText.draw();
				}
			}
		}
		midLine.draw();
	}
}

class TimeWindow extends BaseWindow
{
	public var timeTxt:FlxBitmapText;
	public var infoTxt:FlxBitmapText;
	public var timeBar:DoidoBar;
	public var timeBall:FlxSprite;

	public var buttons:Array<FlxSprite> = [];

	public function new(chartState:ChartingState)
	{
		super(chartState);
		bg.scale.set(458, 138);
		bg.updateHitbox();
		bg.setPosition(FlxG.width - bg.width - 18, FlxG.height - bg.height - 18);

		timeTxt = new FlxBitmapText(bg.x + 8, bg.y + 8, Assets.bitmapFont("phantommuff"));
		timeTxt.alignment = LEFT;
		add(timeTxt);

		infoTxt = new FlxBitmapText(bg.x + 8, timeTxt.y + 32, Assets.bitmapFont("phantommuff"));
		infoTxt.color = 0xFFD8DAF6;
		infoTxt.alignment = LEFT;
		infoTxt.scale.set(0.625, 0.625);
		infoTxt.updateHitbox();
		add(infoTxt);

		timeBar = new DoidoBar("editors/charting/timeBar", "editors/charting/timeBar-border");
		timeBar.setPosition(bg.x + (bg.width - timeBar.width) / 2, bg.y + bg.height - timeBar.height - 12);
		timeBar.sideR.color = 0xFF2A2C44;
		add(timeBar);

		timeBall = new FlxSprite(0, timeBar.y).loadImage("editors/charting/timeBall");
		timeBall.y += (timeBar.height - timeBall.height) / 2;
		add(timeBall);

		// play button
		addButton(0, 0, (btn) ->
		{
			if (!chartState.tweeningSongPos)
				chartState.playingSong = !chartState.playingSong;
			else
			{
				FlxTween.completeTweensOf(btn);
				FlxTween.color(btn, 0.4, 0xFFFF0000, 0xFFFFFFFF);
				FlxTween.shake(btn, 0.05, 0.4);
			}
		});

		// section buttons
		addButton(-32, 3, (btn) ->
		{
			chartState.changeSection(-1);
		});
		addButton(32, 2, (btn) ->
		{
			chartState.changeSection(1);
		});

		// reset button
		addButton(64, 4, (btn) ->
		{
			chartState.resetSection();
		});
	}

	override function draw()
	{
		var timeText:String = "Time: " + getTime(Conductor.songPos) + " / " + getTime(chartState.audio.length);
		if (timeTxt.text != timeText)
			timeTxt.text = timeText;

		var infoText:String = "";
		infoText += "Step: " + Math.floor(chartState.curStepFloat * 100) / 100;
		infoText += "\nBeat: " + Math.floor(chartState.curStepFloat / 4 * 100) / 100;
		infoText += "\nBPM: " + Math.floor(Conductor.bpm * 1000) / 1000;
		if (infoTxt.text != infoText)
			infoTxt.text = infoText;

		timeBar.percent = (1.0 - (Conductor.songPos / chartState.audio.length)) * 100;
		timeBall.x = FlxMath.lerp(timeBar.x, timeBar.x + timeBar.width, 1 - (timeBar.percent / 100)) - (timeBall.width / 2);

		// time button!!
		buttons[0].animation.curAnim.curFrame = (chartState.playingSong ? 1 : 0);

		super.draw();
	}

	public function addButton(xOffset:Float, frame:Int, func:QuickButton->Void)
	{
		var newBtn = new QuickButton(func);
		newBtn.loadSparrow("editors/charting/timeButtons");
		newBtn.animation.addByPrefix("btn", "timeButtons", 0, false);
		newBtn.animation.play("btn", true, false, frame);
		buttons.push(newBtn);
		add(newBtn);

		newBtn.x = (bg.x + (bg.width - newBtn.width) / 2) + xOffset;
		newBtn.y = timeBar.y - newBtn.height - 12;
	}

	var scrubbing:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.overlaps(timeBar.border) || FlxG.mouse.overlaps(timeBall))
		{
			chartState.curCursor = POINTER;
			if (FlxG.mouse.justPressed)
				scrubbing = true;
		}

		if (scrubbing)
		{
			chartState.curCursor = POINTER;
			chartState.playingSong = false;

			Conductor.songPos = FlxMath.bound(FlxMath.remapToRange(FlxG.mouse.x, timeBar.x, timeBar.x + timeBar.width, 0, chartState.audio.length), 0,
				chartState.audio.length);

			if (!FlxG.mouse.pressed)
				scrubbing = false;
		}
	}

	public function getTime(time:Float):String
	{
		time /= 1000;
		if (true) // new timer
			return FlxStringUtil.formatTime(time, true);
		else // old timer
			return '${Math.floor(time * 100) / 100}';
	}
}

class BaseWindow extends FlxGroup
{
	public var chartState:ChartingState;
	public var bg:FlxSprite;

	public function new(chartState:ChartingState)
	{
		super();
		this.chartState = chartState;

		bg = new FlxSprite().makeColor(100, 100, 0xFF000000);
		bg.alpha = 0.5;
		add(bg);
	}
}
