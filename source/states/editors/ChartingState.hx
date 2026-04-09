package states.editors;

import doido.Cache;
import flixel.graphics.frames.FlxFramesCollection;
import openfl.geom.Rectangle;
import flixel.graphics.FlxGraphic;
import objects.ui.HealthIcon;
import doido.objects.ui.DoidoWindow.ChooserWindow;
import doido.objects.ui.QuickButton.Checkmark;
import doido.objects.ui.PsychUINumericStepper;
import doido.objects.ui.DoidoWindow.BaseWindow;
import doido.objects.ui.DoidoWindow.MenuWindow;
import doido.objects.ui.DoidoWindow.IWindow;
import doido.objects.ui.*;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import doido.utils.EditorUtil;
import doido.song.SongHandler.NoteData;
import doido.song.AudioHandler;
import doido.song.Conductor;
import doido.song.SongHandler.DoidoSong;
import doido.song.SongHandler.DoidoChart;
import doido.song.SongHandler.DoidoEvents;
import doido.song.SongHandler.DoidoMeta;
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
import flixel.util.FlxColor;
import doido.objects.ui.QuickButton.TextButton;
import flixel.graphics.frames.FlxFrame;

class ChartingNote extends Note
{
	public var selected:Bool = false;

	public function new()
	{
		super();
	}
}

class ChartingState extends MusicBeatState
{
	public static var GRID_SIZE:Int = 40;
	public static var GRID_LANES:Int = 8;

	public static var GRID_SNAP:Int = 16;
	public static var GRID_ZOOM:Float = 1.0;

	public static var noFunAllowed:Bool = false; // reduced animations

	public var audio:AudioHandler;
	public var playingSong:Bool = false;

	public var SONG:DoidoSong;

	public var cursorTxt:FlxBitmapText;
	public var scrollBall:FlxSprite;

	public var grid:ChartingGrid;
	public var timeBar:FlxSprite;
	public var renderNotes:FlxTypedGroup<ChartingNote>;
	public var selectedColor:FlxColor = FlxColor.BLACK;

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
	public var gridWindow:GridWindow;
	public var menuBox:DoidoBox;
	public var menuMain:DoidoBox;

	var characters:Array<String> = [];

	public function new(SONG:DoidoSong)
	{
		super();
		this.SONG = SONG;
	}

	override function create()
	{
		super.create();
		setFpsPos(18, 544);
		FlxG.mouse.visible = true;
		Conductor.initialBPM = CHART.bpm;
		Conductor.mapBPMChanges(EVENTS.events);
		Conductor.songPos = 0;

		characters = Assets.list("data/characters/", true, JSON).concat(["face"]);

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

		timeBar = new FlxSprite(grid.gridX).makeColor(GRID_SIZE * GRID_LANES, 4, 0xFFFF0000);
		timeBar.screenCenter(Y);
		add(timeBar);

		selectSquare = new FlxSprite().makeColor(1, 1, 0xFF0078D4);
		selectSquare.visible = false;
		selectSquare.alpha = 0.5;
		add(selectSquare);

		addMenu();
		addMain();

		timeWindow = new TimeWindow(this);
		add(timeWindow);

		gridWindow = new GridWindow(this);
		add(gridWindow);

		var debugInfo = new DebugInfo(this);
		// debugInfo.visible = true;
		add(debugInfo);

		cursorTxt = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
		cursorTxt.setOutline(0xFF000000, 2);
		cursorTxt.alignment = LEFT;
		cursorTxt.scale.set(0.7, 0.7);
		cursorTxt.updateHitbox();

		scrollBall = new FlxSprite(0, 0).loadImage("editors/charting/scrollBall");

		// preload icons
		for (char in characters)
		{
			var icon:HealthIcon = new HealthIcon();
			icon.setIcon(char, false);
			icon.destroy();
		}
	}

	function addMenu()
	{
		var x = 20;
		var y = 20;
		var width = 318;
		var height = 22;

		var fileWindow = new MenuWindow(x, y + 30, width, this);
		fileWindow.title = "File";
		// fileWindow.addButton("New", "Ctrl + N");
		// fileWindow.addSeparator();

		// fileWindow.addButton("Open Events", "Ctrl + Alt + O");
		// fileWindow.addSeparator();
		// fileWindow.addButton("Open Song", "Ctrl + O");
		fileWindow.addButton("Save Song", "Ctrl + S", (btn) ->
		{
			save(CHART, "normal");
			save(EVENTS, "events");
			save(META, "meta");
		});
		fileWindow.addSeparator();
		fileWindow.addButton("Save Chart", "Ctrl + Shift + S", (btn) -> save(CHART, "normal"));
		fileWindow.addButton("Save Events", "Ctrl + Alt + S", (btn) -> save(EVENTS, "events"));
		fileWindow.addButton("Save Meta", "Ctrl + Tab + S", (btn) -> save(META, "meta"));
		fileWindow.addSeparator();
		// fileWindow.addButton("Reload Chart", "Ctrl + Shift + Alt + R");
		// fileWindow.addSeparator();
		// fileWindow.addButton("Preview", "ESC");
		fileWindow.addButton("Playtest", "Enter", (btn) -> play());
		fileWindow.updateBg();

		var editWindow = new MenuWindow(x, y + 30, width, this);
		editWindow.title = "Edit";
		// editWindow.addButton("Undo", "Ctrl + Z");
		// editWindow.addButton("Redo", "Ctrl + Y");
		// editWindow.addSeparator();
		editWindow.addButton("Select All", "Ctrl + A", (btn) -> selectAll());
		editWindow.updateBg();

		var viewWindow = new MenuWindow(x, y + 30, width, this);
		viewWindow.title = "View";
		// viewWindow.addButton("Go to Section...");
		// viewWindow.addSeparator();
		viewWindow.addButton("Go to Song Start", "Ctrl + R", (btn) -> goToSong(0));
		viewWindow.addButton("Go to Song End", null, (btn) -> goToSong(audio.length - 1));
		// viewWindow.addButton("Go to...");
		viewWindow.updateBg();

		menuBox = new DoidoBox(x, y, width, height, 0, false, [fileWindow, editWindow, viewWindow], this);
		add(menuBox);
	}

	function createBasic(title:String = "test"):BaseWindow
	{
		var newWindow:BaseWindow = new BaseWindow(this);
		newWindow.title = title;
		newWindow.bg.scale.set(458, 501);
		newWindow.bg.updateHitbox();
		newWindow.bg.setPosition(FlxG.width - newWindow.bg.width - 18, 57);
		return newWindow;
	}

	function createText(x:Float = 0, y:Float = 0, text:String = "", color:FlxColor = 0xFFFFFFFF):FlxBitmapText
	{
		var newText = new FlxBitmapText(x, y, Assets.bitmapFont("phantommuff"));
		newText.alignment = LEFT;
		newText.text = text;
		newText.color = color;
		newText.scale.set(0.625, 0.625);
		newText.updateHitbox();
		return newText;
	}

	var spacingH:Float = 30;

	function createChartingTab():BaseWindow
	{
		var tab = createBasic("Charting");

		function getX(place:String = "margin_left", width:Float = 0)
		{
			return switch (place)
			{
				case "margin_first": tab.bg.x + 138;
				case "margin_first_small": tab.bg.x + 76;
				case "margin_second": tab.bg.x + 178;
				case "margin_right": tab.bg.x + tab.bg.width - width - 8;
				case "center": tab.bg.x + (tab.bg.width / 2) - (width / 2);
				default: tab.bg.x + 8;
			}
		}

		function getY(i:Int = 0)
			return tab.bg.y + 8 + (spacingH * i);

		tab.add(createText(getX(), getY(0), "Volume:"));
		tab.add(createText(getX(), getY(1) + 3, "Player:", 0xFFD8DAF6));
		tab.add(createText(getX(), getY(2) + 3, "Opponent:", 0xFFD8DAF6));
		tab.add(createText(getX(), getY(3) + 3, "Instrumental:", 0xFFD8DAF6));

		var playerVol:Checkmark = new Checkmark(true);
		playerVol.onUp.add((btn) ->
		{
			audio.muteVoices = !playerVol.value;
		});
		playerVol.x = getX("margin_first");
		playerVol.y = getY(1) - 1;
		tab.add(playerVol);

		var playerStepper = new PsychUINumericStepper(getX("margin_right", 100), getY(1), 0.01, 1, 0, 1.0, 2, 100, true);
		tab.add(playerStepper);

		var oppVol:Checkmark = new Checkmark(true);
		oppVol.onUp.add((btn) ->
		{
			audio.muteOpponent = !oppVol.value;
		});
		oppVol.x = getX("margin_first");
		oppVol.y = getY(2) - 1;
		tab.add(oppVol);

		var oppStepper = new PsychUINumericStepper(getX("margin_right", 100), getY(2), 0.01, 1, 0, 1.0, 2, 100, true);
		tab.add(oppStepper);

		var instVol:Checkmark = new Checkmark(true);
		instVol.onUp.add((btn) ->
		{
			audio.muteInst = !instVol.value;
		});
		instVol.x = getX("margin_first");
		instVol.y = getY(3) - 1;
		tab.add(instVol);

		var instStepper = new PsychUINumericStepper(getX("margin_right", 100), getY(3), 0.01, 1, 0, 1.0, 2, 100, true);
		tab.add(instStepper);

		var playerSlider:DoidoSlider = new DoidoSlider(getX("margin_second"), getY(1) + 9, 160, 6, 1, 0, 1, 3, 0.02);
		playerSlider.onScrub.add((sld) ->
		{
			@:bypassAccessor audio.muteVoices = false;
			playerVol.value = true;
			playerStepper.value = playerSlider.value;
			if (audio.voicesGlobal != null)
				audio.voicesGlobal.volume = playerSlider.value;
		});
		tab.add(playerSlider);

		var oppSlider:DoidoSlider = new DoidoSlider(getX("margin_second"), getY(2) + 9, 160, 6, 1, 0, 1, 3, 0.02);
		oppSlider.onScrub.add((sld) ->
		{
			@:bypassAccessor audio.muteVoices = false;
			oppVol.value = true;
			oppStepper.value = oppSlider.value;
			if (audio.voicesOpp != null)
				audio.voicesOpp.volume = oppSlider.value;
		});
		tab.add(oppSlider);

		var instSlider:DoidoSlider = new DoidoSlider(getX("margin_second"), getY(3) + 9, 160, 6, 1, 0, 1, 3, 0.02);
		instSlider.onScrub.add((sld) ->
		{
			@:bypassAccessor audio.muteVoices = false;
			instVol.value = true;
			instStepper.value = instSlider.value;
			audio.inst.volume = instSlider.value;
		});
		tab.add(instSlider);

		playerStepper.onValueChange = (() ->
		{
			@:bypassAccessor audio.muteVoices = false;
			playerVol.value = true;
			playerSlider.value = playerStepper.value;
			if (audio.voicesGlobal != null)
				audio.voicesGlobal.volume = playerStepper.value;
		});

		oppStepper.onValueChange = (() ->
		{
			@:bypassAccessor audio.muteOpponent = false;
			oppVol.value = true;
			oppSlider.value = oppStepper.value;
			if (audio.voicesOpp != null)
				audio.voicesOpp.volume = oppStepper.value;
		});

		instStepper.onValueChange = (() ->
		{
			@:bypassAccessor audio.muteInst = false;
			instVol.value = true;
			instSlider.value = instStepper.value;
			audio.inst.volume = instStepper.value;
		});

		var balls:FlxSprite = new FlxSprite().loadImage("editors/charting/balls");
		balls.setPosition(getX("center", balls.width), getY(4) + 5);
		tab.add(balls);

		// playback
		tab.add(createText(getX(), getY(5), "Playback:"));

		tab.add(createText(getX(), getY(6) + 3, "Speed:", 0xFFD8DAF6));

		var playbackStepper = new PsychUINumericStepper(getX("margin_right", 152), getY(6), 0.1, 1, 0, 2.0, 2, 100, false, true);
		tab.add(playbackStepper);

		var playbackSlider:DoidoSlider = new DoidoSlider(getX("margin_first_small"), getY(6) + 9, 210, 6, 1, 0, 2, 5, 0.03);
		playbackSlider.onScrub.add((sld) ->
		{
			if (playbackSlider.value <= 0)
			{
				playingSong = false;
				audio.pause();
			}
			playbackStepper.value = playbackSlider.value;
			audio.speed = playbackSlider.value;
		});
		tab.add(playbackSlider);

		playbackStepper.onValueChange = (() ->
		{
			if (playbackStepper.value <= 0)
			{
				playingSong = false;
				audio.pause();
			}
			playbackSlider.value = playbackStepper.value;
			audio.speed = playbackStepper.value;
		});

		return tab;
	}

	function createSongTab():BaseWindow
	{
		var tab = createBasic("Song");

		function getX(place:String = "margin_left", width:Float = 0)
		{
			return switch (place)
			{
				case "margin_first": tab.bg.x + 110;
				case "margin_first_search": tab.bg.x + 80;
				case "margin_right": tab.bg.x + tab.bg.width - width - 8;
				case "center": tab.bg.x + (tab.bg.width / 2) - (width / 2);
				default: tab.bg.x + 8;
			}
		}

		function getY(i:Int = 0)
			return tab.bg.y + 8 + (spacingH * i);

		// chart options
		// tab.add(createText(getX(), getY(0), "Chart:"));
		tab.add(createText(getX(), getY(0) + 3, "Name:", 0xFFD8DAF6));
		tab.add(createText(getX(), getY(1) + 3, "BPM:", 0xFFD8DAF6));
		tab.add(createText(getX(), getY(2) + 3, "Note Speed:", 0xFFD8DAF6));

		var songName:PsychUIInputText;
		songName = new PsychUIInputText(getX("margin_first"), getY(0), 342, CHART.song, 14);
		songName.onChange.add((old, cur, input) -> CHART.song = cur);
		tab.add(songName);

		var bpmStepper = new PsychUINumericStepper(getX("margin_first"), getY(1), 1, CHART.bpm, 1, 339, 0);
		bpmStepper.onValueChange = (() ->
		{
			Conductor.initialBPM = bpmStepper.value;
			CHART.bpm = Conductor.bpm;
		});
		tab.add(bpmStepper);

		var speedStepper = new PsychUINumericStepper(getX("margin_first"), getY(2), 0.1, CHART.speed, 0.1, 10, 1);
		speedStepper.onValueChange = (() ->
		{
			CHART.speed = speedStepper.value;
		});
		tab.add(speedStepper);

		var reloadButton = new TextButton("Reload Audio", (btn) ->
		{
			playingSong = false;
			audio.pause();
			audio.reload(CHART.song);
			grid.length = audio.length;
		});
		reloadButton.x = getX("margin_right", reloadButton.width);
		reloadButton.y = getY(2) - 9;
		reloadButton.button.setColorTransform(0.59, 0.78, 1);
		reloadButton.text.color = 0xFFFFFFFF;
		tab.add(reloadButton);

		var balls:FlxSprite = new FlxSprite().loadImage("editors/charting/balls");
		balls.setPosition(getX("center", balls.width), getY(3) + 5);
		tab.add(balls);

		// meta options
		// tab.add(createText(getX(), getY(5), "Meta:"));

		tab.add(createText(getX(), getY(4) + 3, "Search:", 0xFFD8DAF6));

		var test:ChooserWindow = new ChooserWindow(getX("center", 440), getY(5) + 5, 440, 165, [], this);
		tab.add(test);

		var filter:PsychUIInputText;
		filter = new PsychUIInputText(getX("margin_first_search"), getY(4), 372, "", 14);
		filter.onChange.add((old, cur, input) -> test.filter = cur);
		filter.behindText.color = 0xFFD8DAF6;
		tab.add(filter);

		var glass:FlxSprite = new FlxSprite().loadImage("editors/charting/glass");
		glass.setGraphicSize(filter.behindText.height - 2, filter.behindText.height - 2);
		glass.x = filter.behindText.x + 1;
		glass.y = filter.behindText.y + 1;
		tab.add(glass);

		filter.textObj.x += glass.width + 2;
		filter.fieldWidth -= Std.int(glass.width + 2);

		tab.add(createText(getX(), getY(11), "Player:", 0xFFD8DAF6));
		tab.add(createText(getX("center", 145), getY(11), "Opponent:", 0xFFD8DAF6));
		tab.add(createText(getX("margin_right", 145), getY(11), "Girlfriend:", 0xFFD8DAF6));

		var bfIcon = new HealthIcon();
		bfIcon.globalScale = 0.33;
		bfIcon.setIcon(META.player1, false);
		bfIcon.setPosition(getX() + 145 - bfIcon.width, getY(11) - 10);
		tab.add(bfIcon);

		var bfButton = new TextButton("");
		bfButton.button.onUp.add((btn) ->
		{
			if (test.buttonId == "bf")
			{
				test.options = [];
				test.onClick = null;
				test.buttonId = "";
			}
			else
			{
				test.buttonId = "bf";
				test.view = GRID;
				test.type = CHARACTER;
				test.options = characters;
				test.onClick = (name) ->
				{
					test.options = [];
					bfButton.text.text = name;
					bfIcon.setIcon(name, false);
					bfButton.button.setColorTransform(bfIcon.barColor.redFloat, bfIcon.barColor.greenFloat, bfIcon.barColor.blueFloat);
					META.player1 = name;
					test.buttonId = "";
				};
			}
		});
		bfButton.x = getX(); // bfButton.width
		bfButton.y = getY(11) + 22;
		bfButton.button.setColorTransform(bfIcon.barColor.redFloat, bfIcon.barColor.greenFloat, bfIcon.barColor.blueFloat);
		bfButton.text.text = META.player1;
		bfButton.text.color = 0xFFFFFFFF;
		tab.add(bfButton);

		var oppIcon = new HealthIcon();
		oppIcon.globalScale = 0.33;
		oppIcon.setIcon(META.player2, false);
		oppIcon.setPosition(getX("center", 145) + 145 - oppIcon.width, getY(11) - 10);
		tab.add(oppIcon);

		var oppButton = new TextButton("",);
		oppButton.button.onUp.add((btn) ->
		{
			if (test.buttonId == "opp")
			{
				test.options = [];
				test.onClick = null;
				test.buttonId = "";
			}
			else
			{
				test.buttonId = "opp";
				test.view = GRID;
				test.type = CHARACTER;
				test.options = characters;
				test.onClick = (name) ->
				{
					test.options = [];
					oppButton.text.text = name;
					oppIcon.setIcon(name, false);
					oppButton.button.setColorTransform(oppIcon.barColor.redFloat, oppIcon.barColor.greenFloat, oppIcon.barColor.blueFloat);
					META.player2 = name;
					test.buttonId = "";
				};
			}
		});
		oppButton.x = getX("center", oppButton.width); // bfButton.width
		oppButton.y = getY(11) + 22;
		oppButton.button.setColorTransform(oppIcon.barColor.redFloat, oppIcon.barColor.greenFloat, oppIcon.barColor.blueFloat);
		oppButton.text.text = META.player2;
		oppButton.text.color = 0xFFFFFFFF;
		tab.add(oppButton);

		var gfIcon = new HealthIcon();
		gfIcon.globalScale = 0.33;
		gfIcon.setIcon(META.gf, false);
		gfIcon.setPosition(getX("margin_right", 145) + 145 - gfIcon.width, getY(11) - 10);
		tab.add(gfIcon);

		var gfButton = new TextButton("");
		gfButton.button.onUp.add((btn) ->
		{
			if (test.buttonId == "gf")
			{
				test.options = [];
				test.onClick = null;
				test.buttonId = "";
			}
			else
			{
				test.buttonId = "gf";
				test.view = GRID;
				test.type = CHARACTER;
				test.options = characters;
				test.onClick = (name) ->
				{
					test.options = [];
					gfButton.text.text = name;
					gfIcon.setIcon(name, false);
					gfButton.button.setColorTransform(gfIcon.barColor.redFloat, gfIcon.barColor.greenFloat, gfIcon.barColor.blueFloat);
					META.gf = name;
					test.buttonId = "";
				};
			}
		});
		gfButton.x = getX("margin_right", gfButton.width); // bfButton.width
		gfButton.y = getY(11) + 22;
		gfButton.button.setColorTransform(gfIcon.barColor.redFloat, gfIcon.barColor.greenFloat, gfIcon.barColor.blueFloat);
		gfButton.text.text = META.gf;
		gfButton.text.color = 0xFFFFFFFF;
		tab.add(gfButton);

		tab.add(createText(getX(), getY(13), "Stage:", 0xFFD8DAF6));

		var stages:Array<String> = Assets.list("data/stages/", true, SCRIPT);
		stages = stages.concat(stages);
		var stageButton = new TextButton("");
		stageButton.button.onUp.add((btn) ->
		{
			if (test.buttonId == "stages")
			{
				test.options = [];
				test.onClick = null;
				test.buttonId = "";
			}
			else
			{
				test.buttonId = "stages";
				test.view = LIST;
				test.type = NONE;
				test.options = stages;
				test.onClick = (name) ->
				{
					test.options = [];
					stageButton.text.text = name;
					META.stage = name;
					test.buttonId = "";
				};
			}
		});
		stageButton.x = getX(); // bfButton.width
		stageButton.y = getY(13) + 22;
		stageButton.text.text = META.stage;
		// stageButton.text.color = 0xFFFFFFFF;
		tab.add(stageButton);

		tab.add(createText(getX("center", 145), getY(13), "Composer:", 0xFFD8DAF6));
		tab.add(createText(getX("margin_right", 145), getY(13), "Charter:", 0xFFD8DAF6));

		var composer:PsychUIInputText;
		composer = new PsychUIInputText(getX("center", 145), getY(13) + 22, 145, META.composer, 14);
		composer.onChange.add((old, cur, input) -> META.composer = cur);
		tab.add(composer);

		var charter:PsychUIInputText;
		charter = new PsychUIInputText(getX("margin_right", 145), getY(13) + 22, 145, META.charter, 14);
		charter.onChange.add((old, cur, input) -> META.charter = cur);
		tab.add(charter);

		return tab;
	}

	function createEventsTab()
	{
		var tab = createBasic("Events");

		function getX(place:String = "margin_left", width:Float = 0)
		{
			return switch (place)
			{
				case "center": tab.bg.x + (tab.bg.width / 2) - (width / 2);
				case "margin_first": tab.bg.x + 110;
				default: tab.bg.x + 8;
			}
		}

		function getY(i:Int = 0)
			return tab.bg.y + 8 + (spacingH * i);

		return tab;
	}

	function addMain()
	{
		menuMain = new DoidoBox(803, 19, 458, 32, 4, [
			createChartingTab(),
			createEventsTab(),
			createBasic("Note"),
			createBasic("Functions"),
			createSongTab()
		], this);
		add(menuMain);
	}

	public var tweeningSongPos:Bool = false;
	public var curCursor:lime.ui.MouseCursor = DEFAULT;

	var clickedOnWindow:Bool = false;

	var autoScrolling:Bool = false;
	var scrollAutoY:Float = 0;

	var typing(get, never):Bool;

	function get_typing():Bool
		return PsychUIInputText.focusOn != null;

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
			if (FlxG.keys.justPressed.SPACE && !typing && audio.speed > 0)
				playingSong = !playingSong;
		}

		var overlapsWindow:Bool = false;

		for (basic in members)
		{
			if (Std.isOfType(basic, IWindow))
			{
				if (cast(basic, IWindow).overlapping)
				{
					overlapsWindow = true;
				}
			}
		}

		if (FlxG.mouse.justPressed)
			clickedOnWindow = overlapsWindow;

		var cursorText:String = "";

		if (!clickedOnWindow && !typing)
		{
			if (FlxG.keys.pressed.SHIFT)
				cursorText = "4x";

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
				var selColor:Float = 0.8 + Math.sin(FlxG.game.ticks / 100) * 2;
				selectedColor.redFloat = selColor;
				selectedColor.greenFloat = selColor;
				selectedColor.blueFloat = selColor;
				for (note in renderNotes.members)
				{
					if (note.selected)
						note.color = selectedColor;
				}

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

					var zoomedGrid:Float = GRID_SIZE * GRID_ZOOM;
					var startY:Float = Math.floor((selectSquare.y - grid.gridY) / zoomedGrid);
					var endY:Float = startY + Math.floor(selectSquare.height / zoomedGrid);
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
					var mouseLane:Int = getMouseLane();
					var zoomSnap:Float = (GRID_SNAP * GRID_ZOOM);
					var realSnap:Float = (zoomSnap / 16);
					var sizeTimed:Float = (GRID_SIZE / realSnap) * GRID_ZOOM;

					hoverSquare.visible = true;
					hoverSquare.setPosition(grid.gridX + mouseLane * GRID_SIZE, grid.gridY + Math.floor((FlxG.mouse.y - grid.gridY) / sizeTimed) * sizeTimed);
					if (GRID_SNAP == 0)
						hoverSquare.y = FlxG.mouse.y;

					var mouseStep:Float = (hoverSquare.y - grid.gridY) / GRID_SIZE / GRID_ZOOM;

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
				Conductor.songPos += -FlxG.mouse.wheel * 10000 * elapsed * (FlxG.keys.pressed.SHIFT ? 4 : 1) / GRID_ZOOM;
			}

			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				playingSong = false;
				stopTweenSongPos();
				var dir:Int = (FlxG.keys.pressed.S ? 1 : 0) - (FlxG.keys.pressed.W ? 1 : 0);
				Conductor.songPos += dir * 1000 * elapsed * (FlxG.keys.pressed.SHIFT ? 4 : 1) / GRID_ZOOM;
			}

			if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.D)
			{
				var wasA:Bool = FlxG.keys.justPressed.A;
				if (wasA && FlxG.keys.pressed.CONTROL)
					selectAll();
				else
					changeSection(wasA ? -1 : 1);
			}

			if (FlxG.keys.justPressed.R)
				resetSection();

			if (FlxG.keys.justPressed.ENTER)
				play();

			if (FlxG.keys.justPressed.EIGHT || FlxG.keys.justPressed.NUMPADEIGHT)
				noFunAllowed = !noFunAllowed;

			if (FlxG.keys.justPressed.S && FlxG.keys.pressed.CONTROL)
			{
				var pressedNone = !FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.ALT && !FlxG.keys.pressed.TAB;

				if (FlxG.keys.pressed.SHIFT || pressedNone)
					save(CHART, "normal");
				if (FlxG.keys.pressed.ALT || pressedNone)
					save(EVENTS, "events");
				if (FlxG.keys.pressed.TAB || pressedNone)
					save(META, "meta");
			}
		}

		if (playingSong && audio.speed > 0)
		{
			if (!audio.playing && Conductor.songPos >= 0)
				audio.play(Conductor.songPos);

			Conductor.songPos += elapsed * 1000 * audio.speed;
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

		if (!playingSong)
		{
			if (FlxG.mouse.pressedMiddle && FlxG.keys.pressed.CONTROL)
				timeBar.y = (FlxG.keys.pressed.SHIFT ? (FlxG.height / 2) - (timeBar.height / 2) : FlxG.mouse.y);
			else if (FlxG.mouse.justPressedMiddle)
			{
				autoScrolling = !autoScrolling;

				if (autoScrolling)
				{
					scrollAutoY = FlxG.mouse.getWorldPosition().y;
					scrollBall.setPosition(FlxG.mouse.getWorldPosition()
						.x - (scrollBall.width / 2), FlxG.mouse.getWorldPosition().y - (scrollBall.height / 2));
				}
			}

			if (autoScrolling)
				Conductor.songPos += (FlxG.mouse.getWorldPosition().y - scrollAutoY) * 10 * elapsed * (FlxG.keys.pressed.SHIFT ? 4 : 1);
		}

		grid.gridY = timeBar.y + (timeBar.height / 2) - (curStepFloat * GRID_SIZE * GRID_ZOOM);

		super.update(elapsed);
		EditorUtil.setCursor(curCursor);
		if (cursorTxt.text != cursorText)
		{
			cursorTxt.text = cursorText;
			cursorTxt.color = (cursorText == "X" ? 0xFFFF0000 : 0xFFFFFFFF);
		}
	}

	public function save(_data:Dynamic, name:String)
	{
		var data:String = Json.stringify(_data, "\t");
		if (data != null && data.length > 0)
		{
			Assets.fileSave(data.trim(), '${CHART.song}-${name}.json');
		}
	}

	public function play()
	{
		PlayState.SONG = SONG;
		MusicBeat.switchState(new PlayState());
		FlxG.mouse.visible = false;
	}

	function selectAll()
	{
		selectedNotes = [];
		for (note in CHART.notes)
			selectedNotes.push(note);
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
		var sectionLength:Int = 16;

		dir *= (FlxG.keys.pressed.SHIFT ? 4 : 1);
		tweenSongPos(getSectionStart(curStepFloat + 1 + (sectionLength * dir)));
	}

	public function resetSection()
	{
		if (FlxG.keys.pressed.SHIFT)
		{
			goToSong(0);
		}
		else
		{
			tweenSongPos(getSectionStart());
		}
	}

	public function goToSong(target:Float)
	{
		if (!tweeningSongPos)
		{
			if (Math.abs(Conductor.songPos - target) <= 10000 || noFunAllowed)
				tweenSongPos(0, 0.25, FlxEase.cubeInOut);
			else
			{
				FlxTween.tween(FlxG.camera, {zoom: 1.3}, 1.6, {ease: FlxEase.cubeIn, startDelay: 0.4});
				tweenSongPos(target, 2, FlxEase.cubeIn, (twn) ->
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
			var noteY:Float = grid.gridY + (noteData.stepTime * GRID_SIZE * GRID_ZOOM);
			var noteHeight:Float = GRID_SIZE + (GRID_SIZE * GRID_ZOOM * (noteData.length + 1));
			if (noteY < -noteHeight)
				continue;
			if (noteY > FlxG.height)
				break;

			var note:ChartingNote = cast renderNotes.recycle(ChartingNote);
			note.loadData(noteData);
			note.reloadSprite();

			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();

			note.selected = false;
			if (!selectedNotes.contains(noteData))
				note.color = 0xFFFFFFFF;
			else
				note.selected = true;

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

				hold.setGraphicSize(GRID_SIZE * 0.25, GRID_SIZE * GRID_ZOOM * (noteData.length + 1));
				hold.updateHitbox();

				hold.setPosition(note.x + (GRID_SIZE - hold.width) / 2, note.y);
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

		if (autoScrolling)
			scrollBall.draw();
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
		gridLength = Math.ceil(Conductor.getStepAtTime(length) * ChartingState.GRID_ZOOM);
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
			var zoomedY:Float = (_y / ChartingState.GRID_ZOOM);
			var gridY:Float = gridY + (GRID_SIZE * _y);
			// beat lines and section numbers
			if (zoomedY % 4 == 0)
			{
				beatLine.color = (zoomedY % 16 == 0) ? 0xFF1C1A24 : 0xFFA5B1E4;
				beatLine.scale.y = (zoomedY % 16 == 0) ? 8 : 4;
				beatLine.updateHitbox();

				beatLine.y = gridY - (beatLine.height / 2);
				beatLine.draw();
			}

			// section numbers
			if (zoomedY % 16 == 0)
			{
				sectText.text = '${Math.floor(zoomedY / 16)}'.lpad("0", 2);

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
		midLine.draw();
	}
}

class GridWindow extends BaseWindow
{
	var windowTitle:FlxBitmapText;
	var zoomTxt:FlxBitmapText;
	var snapTxt:FlxBitmapText;

	var songName:PsychUIInputText;
	var zoomStepper:PsychUINumericStepper;
	var snapDrowUp:PsychUIDropDownMenu;

	public function new(chartState:ChartingState)
	{
		super(chartState);
		bg.scale.set(190, 104);
		bg.updateHitbox();
		bg.setPosition(18, FlxG.height - bg.height - 18);

		windowTitle = new FlxBitmapText(bg.x + 6, bg.y + 12, Assets.bitmapFont("phantommuff"));
		windowTitle.alignment = LEFT;
		windowTitle.text = "Grid Settings: ";
		windowTitle.scale.set(0.625, 0.625);
		windowTitle.updateHitbox();
		add(windowTitle);

		zoomTxt = new FlxBitmapText(bg.x + 6, windowTitle.y + 32, Assets.bitmapFont("phantommuff"));
		zoomTxt.alignment = LEFT;
		zoomTxt.text = "Zoom: ";
		zoomTxt.color = 0xFFD8DAF6;
		zoomTxt.scale.set(0.625, 0.625);
		zoomTxt.updateHitbox();
		add(zoomTxt);

		zoomStepper = new PsychUINumericStepper(bg.x + 82, windowTitle.y + 30, 0.25, ChartingState.GRID_ZOOM, 0.25, 4, 2, 100, true);
		zoomStepper.onValueChange = () ->
		{
			ChartingState.GRID_ZOOM = zoomStepper.value;
		};
		add(zoomStepper);

		snapTxt = new FlxBitmapText(bg.x + 6, zoomTxt.y + 32, Assets.bitmapFont("phantommuff"));
		snapTxt.alignment = LEFT;
		snapTxt.text = "Snap: ";
		snapTxt.color = 0xFFD8DAF6;
		snapTxt.scale.set(0.625, 0.625);
		snapTxt.updateHitbox();
		add(snapTxt);

		var snaps:Array<String> = [
			"NONE", "4th", "8th", "12th", "16th", "20th", "24th", "32th", "48th", "64th", "96th", "192th"
		];
		snaps.reverse();
		snapDrowUp = new PsychUIDropDownMenu(bg.x + 82, zoomTxt.y + 30, snaps, (i, s) ->
		{
			if (s == "NONE")
				s = "0th";
			ChartingState.GRID_SNAP = Std.parseInt(s.replace("th", ""));
		}, 100, true);
		snapDrowUp.selectedLabel = (ChartingState.GRID_SNAP == 0 ? "NONE" : '${ChartingState.GRID_SNAP}th');
		add(snapDrowUp);
	}
}

class TimeWindow extends BaseWindow
{
	public var timeTxt:FlxBitmapText;
	public var infoTxt:FlxBitmapText;
	public var timeBar:DoidoBar;
	public var timeBall:FlxSprite;
	public var oldMark:Checkmark;
	public var oldTxt:FlxBitmapText;

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

		oldMark = new Checkmark(false);
		oldMark.onUp.add((btn) ->
		{
			oldTimer = oldMark.value;
		});
		oldMark.x = bg.x + bg.width - oldMark.width - 8;
		oldMark.y = bg.y + 8;
		add(oldMark);

		oldTxt = new FlxBitmapText(0, bg.y + 8 + 3, Assets.bitmapFont("phantommuff"));
		oldTxt.color = 0xFFD8DAF6;
		oldTxt.alignment = LEFT;
		oldTxt.scale.set(0.625, 0.625);
		oldTxt.updateHitbox();
		oldTxt.text = "Old Timer:";
		oldTxt.x = oldMark.x - oldTxt.width - 8;
		add(oldTxt);
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

	public var oldTimer:Bool = false;

	public function getTime(time:Float):String
	{
		time /= 1000;
		if (!oldTimer) // new timer
			return FlxStringUtil.formatTime(time, true);
		else // old timer
			return '${Math.floor(time * 100) / 100}';
	}
}
