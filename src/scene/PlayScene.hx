package scene;

import hxd.Save;
import hxd.Rand;
import event.TalkedToEvent;
import component.Person;
import system.TimerMaskSystem;
import component.TimerMask;
import h2d.Graphics;
import h2d.filter.Mask;
import event.LevelComplete;
import h2d.Layers;
import dialogue.event.DialogueComplete;
import system.SparkMover;
import ecs.utils.Path;
import ecs.utils.WorldUtils;
import h2d.col.Point;
import component.Spark;
import hxsl.Shader;
import shaders.WobbleShader;
import system.HoverHighlightSystem;
import dialogue.event.DialogueHidden;
import system.ClickableSystem;
import dialogue.event.StartNode.StartDialogueNode;
import assets.Assets;
import h2d.Object;
import dialogue.DialogueBoxController;
import ecs.event.EventBus;
import hxd.Window;
import ecs.system.VelocityController;
import constant.Const;
import h2d.col.Bounds;
import h2d.Console;
import h2d.Scene;
import h2d.Bitmap;
import ecs.system.CameraController;
import ecs.component.Velocity;
import ecs.component.Renderable;
import ecs.component.Transform;
import ecs.component.Camera;
import ecs.system.Renderer;
import ecs.scene.GameScene;
import ecs.Entity;
import ecs.World;
import system.PlayerInputController;
import component.Player;

class PlayScene extends GameScene {
	var world:World;
	var eventBus:EventBus;
	var dialogueBox:DialogueBoxController;
	var clickableSystem:ClickableSystem;
	var highlightSystem:HoverHighlightSystem;
	var currentInbetweenNode = 0;
	var currentEntities:Array<Entity> = [];
	var partyPeople:Array<Person> = [];
	var clubPeople:Array<Person> = [];
	var coffeePeople:Array<Person> = [];
	var lastVisited:Array<Array<String>> = [];
	var partyBg:Bitmap;
	var clubBg:Bitmap;
	var coffeeBg:Bitmap;
	var sceneLayer:Object;

	static var inbetweenNodes = [
		"CurrentTimeStart",
		"CurrentTimeAfterParty",
		"CurrentTimeAfterClub",
		"CurrentTimeEnd"
	];

	public function new(heapsScene:Scene, console:Console) {
		super(heapsScene, console);

		eventBus = Game.current.globalEventBus;
	}

	public override function init():Void {
		var s2d = getScene();
		var layers = new Layers(this);
		this.world = new World();

		var player = createPlayer(s2d.width, s2d.height);
		var camera = createCamera(s2d.width, s2d.height, player);
		setupSystems(world, s2d, camera);

		#if debug
		WorldUtils.registerConsoleDebugCommands(console, world);
		#end

		sceneLayer = new Object();
		layers.add(sceneLayer, Const.BackgroundLayerIndex);

		loadParty(sceneLayer);
		loadClub(s2d, sceneLayer);
		loadCoffee(s2d, sceneLayer);

		var uiParent = new Object();
		layers.add(uiParent, Const.UiLayerIndex);
		dialogueBox = new DialogueBoxController(eventBus, world, uiParent, Game.current.ca, Assets.dialogue);

		eventBus.subscribe(StartDialogueNode, nodeStarted);
		eventBus.subscribe(TalkedToEvent, talkedTo);
		eventBus.subscribe(DialogueHidden, dialogueHidden);
		eventBus.subscribe(DialogueComplete, dialogueComplete);
		eventBus.subscribe(LevelComplete, levelComplete);

		// eventBus.publishEvent(new DialogueComplete(inbetweenNodes[1]));
		startInbetween();
	}

	function gameEnd() {
		dialogueBox.remove();
		eventBus.unsubscribe(StartDialogueNode, nodeStarted);
		eventBus.unsubscribe(TalkedToEvent, talkedTo);
		eventBus.unsubscribe(DialogueHidden, dialogueHidden);
		eventBus.unsubscribe(DialogueComplete, dialogueComplete);
		eventBus.unsubscribe(LevelComplete, levelComplete);
		haxe.Timer.delay(function() {
			Game.current.saveData.playThroughs += 1;
			Save.save(Game.current.saveData, Const.SaveFile);

			Assets.dialogue.dialogue.setInitialVariables(true);
			Game.current.setGameScene(new MenuScene(getScene(), console));
		}, 1000);
	}

	function levelComplete(e:LevelComplete) {
		// Party done
		if (e.level == Const.Levels[0]) {
			Assets.dialogue.stop();
			removeEntitnes();
			haxe.Timer.delay(function() {
				startInbetween();
			}, 1000);
		}

		if (e.level == Const.Levels[1]) {
			Assets.dialogue.stop();
			removeEntitnes();
			haxe.Timer.delay(function() {
				startInbetween();
			}, 1000);
		}

		if (e.level == Const.Levels[2]) {
			Assets.dialogue.stop();
			removeEntitnes();
			haxe.Timer.delay(function() {
				startInbetween();
			}, 1000);
		}
	}

	function dialogueComplete(e:DialogueComplete) {
		var s2d = getScene();
		if (e.nodeName == inbetweenNodes[0]) {
			setDistortText();
			dialogueBox.moveTo(4, 4);
			spawnParty(s2d, sceneLayer, world);
			currentInbetweenNode++;
			return;
		}

		if (e.nodeName == inbetweenNodes[1]) {
			setDistortText();
			dialogueBox.moveTo(4, 4);
			spawnClub(s2d, sceneLayer, world);
			currentInbetweenNode++;
			return;
		}

		if (e.nodeName == inbetweenNodes[2]) {
			setDistortText();
			dialogueBox.moveTo(4, 4);
			spawnCoffee(s2d, sceneLayer, world);
			currentInbetweenNode++;
			return;
		}

		if (e.nodeName == inbetweenNodes[3]) {
			gameEnd();
		}
	}

	function setDistortText() {
		if (Game.current.saveData.playThroughs > 0) {
			dialogueBox.distortText = true;
		}
	}

	function nodeStarted(e:StartDialogueNode) {
		if (clickableSystem != null)
			clickableSystem.canClick = false;

		if (highlightSystem != null)
			highlightSystem.enabled = false;
	}

	function talkedTo(e:TalkedToEvent) {
		lastVisited.push(e.names);
	}

	function dialogueHidden(e) {
		if (clickableSystem != null)
			clickableSystem.canClick = true;

		if (highlightSystem != null)
			highlightSystem.enabled = true;
	}

	function wobbleShadder(bmp:Bitmap, strength:Float = .05):Shader {
		var shader = new WobbleShader();
		shader.speed = 5;
		shader.strength = strength;
		shader.frames = 4;
		shader.texture = bmp.tile.getTexture();
		shader.flowMap = hxd.Res.noise.toTexture();
		return shader;
	}

	function startInbetween() {
		dialogueBox.distortText = false;
		dialogueBox.moveTo(4, getScene().height / 2 - dialogueBox.getSize().height / 2, TopRight);
		eventBus.publishEvent(new StartDialogueNode(inbetweenNodes[currentInbetweenNode]));
	}

	function loadParty(parent:Object) {
		// BG
		partyBg = new Bitmap(hxd.Res.party.party_bg.toTile(), parent);
		partyBg.visible = false;

		// boy A
		var boyABmp = new Bitmap(hxd.Res.party.boyA.toTile(), parent);
		var boyAHighlightBmp = new Bitmap(hxd.Res.party.boyA_highlight.toTile(), parent);
		boyABmp.addShader(wobbleShadder(boyABmp));
		var boyA = new Person(["BoyA"], "PartyBoyA", boyABmp, boyAHighlightBmp, 1110, 464);

		partyPeople.push(boyA);

		// Girl A
		var girlABmp = new Bitmap(hxd.Res.party.girlA.toTile(), parent);
		girlABmp.addShader(wobbleShadder(girlABmp));
		var girlAHighlightBmp = new Bitmap(hxd.Res.party.girlA_highlight.toTile(), parent);
		var girlA = new Person(["GirlA"], "PartyGirlA", girlABmp, girlAHighlightBmp, 62, 523);

		partyPeople.push(girlA);

		// Girl B/Boy B
		var girlBBmp = new Bitmap(hxd.Res.party.girlBBoyB.toTile(), parent);
		girlBBmp.addShader(wobbleShadder(girlBBmp));
		var girlBHighlightBmp = new Bitmap(hxd.Res.party.girlBBoyB_highlight.toTile(), parent);

		var girlBBoyB = new Person(["GirlB", "BoyB"], "PartyGirlBBoyB", girlBBmp, girlBHighlightBmp, 405, 477);

		partyPeople.push(girlBBoyB);

		// Boy C
		var boyCbmp = new Bitmap(hxd.Res.party.boyC.toTile(), parent);
		boyCbmp.addShader(wobbleShadder(boyCbmp));
		var boyCHighlightBmp = new Bitmap(hxd.Res.party.boyC_highlight.toTile(), parent);
		var boyC = new Person(["BoyC"], "PartyBoyC", boyCbmp, boyCHighlightBmp, 805, 453);

		partyPeople.push(boyC);
	}

	function spawnParty(s2d:Scene, parent:Object, world:World) {
		var bg = world.addEntity("bg").add(new Renderable(partyBg));
		partyBg.visible = true;

		currentEntities.push(bg);

		for (person in partyPeople) {
			var p = person.spawnPerson(world, eventBus);
			var highlight = person.spawnHighlight(p, world);

			currentEntities.push(p);
			currentEntities.push(highlight);
		}

		spawnSpark(s2d, parent, Const.Levels[0]);
	}

	function loadClub(s2d:Scene, parent:Object) {
		clubBg = new Bitmap(hxd.Res.club.club_bg.toTile(), parent);
		clubBg.visible = false;

		// girlC girl D
		var girlCgirlDBmp = new Bitmap(hxd.Res.club.girlCgirlD.toTile(), parent);
		girlCgirlDBmp.addShader(wobbleShadder(girlCgirlDBmp));
		var girlCGirlDHighlightBmp = new Bitmap(hxd.Res.club.girlCgirlD_highlight.toTile(), parent);

		var girlCGirlD = new Person(["GirlC", "GirlD"], "ClubGirlCGirlD", girlCgirlDBmp, girlCGirlDHighlightBmp, 370,
			s2d.height - girlCgirlDBmp.getSize().height);

		clubPeople.push(girlCGirlD);

		// Girl A
		var girlABmp = new Bitmap(hxd.Res.club.girlA.toTile(), parent);
		girlABmp.addShader(wobbleShadder(girlABmp));
		var girlAHighlightBmp = new Bitmap(hxd.Res.club.girlA_highlight.toTile(), parent);

		var girlA = new Person(["GirlA"], "ClubGirlA", girlABmp, girlAHighlightBmp, 997, s2d.height - girlABmp.getSize().height);

		clubPeople.push(girlA);

		// Girl B/Boy C
		var girlBBmp = new Bitmap(hxd.Res.club.girlABoyC.toTile(), parent);
		girlBBmp.addShader(wobbleShadder(girlBBmp));
		var girlBHighlightBmp = new Bitmap(hxd.Res.club.girlABoyC_highlight.toTile(), parent);

		var girlBBoyC = new Person(["GirlB", "BoyC"], "ClubGirlBBoyC", girlBBmp, girlBHighlightBmp, 600, s2d.height - girlBBmp.getSize().height);

		clubPeople.push(girlBBoyC);

		// Boy B
		var boyBbmp = new Bitmap(hxd.Res.club.boyB.toTile(), parent);
		boyBbmp.addShader(wobbleShadder(boyBbmp));
		var boyBHighlightBmp = new Bitmap(hxd.Res.club.boyB_highlight.toTile(), parent);

		var boyB = new Person(["BoyB"], "ClubBoyB", boyBbmp, boyBHighlightBmp, 227, s2d.height - boyBbmp.getSize().height);

		clubPeople.push(boyB);

		// boy A
		var boyABmp = new Bitmap(hxd.Res.club.boyA.toTile(), parent);
		boyABmp.addShader(wobbleShadder(boyABmp));
		var boyABmpHighlight = new Bitmap(hxd.Res.club.boyA_highlight.toTile(), parent);

		var boyA = new Person(["BoyA"], "ClubBoyA", boyABmp, boyABmpHighlight, 750, s2d.height - boyABmp.getSize().height);

		clubPeople.push(boyA);
	}

	function spawnClub(s2d:Scene, parent:Object, world:World) {
		// BG
		var bg = world.addEntity("bg").add(new Renderable(clubBg));
		clubBg.visible = true;

		currentEntities.push(bg);

		var totalNumberToSpawn = 5;

		var peopleToSpawn = new Array<Person>();
		peopleToSpawn.push(clubPeople.shift());

		totalNumberToSpawn -= 2;

		Rand.create().shuffle(clubPeople);

		var lastMet:Person = null;
		if (lastVisited.length > 0) {
			var lastNames = lastVisited[0];
			Rand.create().shuffle(lastNames);
			lastMet = clubPeople.filter(function(f) {
				return f.names.contains(lastNames[0]);
			})[0];
			clubPeople.remove(lastMet);
			peopleToSpawn.push(lastMet);
			totalNumberToSpawn -= lastMet.names.length;
		}

		while (totalNumberToSpawn > 0 && clubPeople.length > 0) {
			var person = clubPeople.pop();
			if (totalNumberToSpawn >= person.names.length) {
				peopleToSpawn.push(person);
				totalNumberToSpawn -= person.names.length;
			}
		}

		for (person in peopleToSpawn) {
			var p = person.spawnPerson(world, eventBus);
			var highlight = person.spawnHighlight(p, world);

			currentEntities.push(p);
			currentEntities.push(highlight);
		}

		spawnSpark(s2d, parent, Const.Levels[1]);

		lastVisited = [];
	}

	function loadCoffee(s2d:Scene, parent:Object) {
		coffeeBg = new Bitmap(hxd.Res.coffee.coffee_bg.toTile(), parent);
		coffeeBg.visible = false;

		// girlE
		var girlEBmp = new Bitmap(hxd.Res.coffee.girlE.toTile(), parent);
		girlEBmp.addShader(wobbleShadder(girlEBmp));
		var girlEHighlightBmp = new Bitmap(hxd.Res.coffee.girlE_highlight.toTile(), parent);
		var girlE = new Person(["GirlE"], "CoffeeGirlE", girlEBmp, girlEHighlightBmp, 521, s2d.height - girlEBmp.getSize().height);

		coffeePeople.push(girlE);

		// girlBBoyD
		var girlBBoyDBmp = new Bitmap(hxd.Res.coffee.girlBBoyD.toTile(), parent);
		girlBBoyDBmp.addShader(wobbleShadder(girlBBoyDBmp));
		var girlBBoyDHighlightBmp = new Bitmap(hxd.Res.coffee.girlBBoyD_highlight.toTile(), parent);
		var girlBBoyD = new Person(["GirlB", "BoyD"], "CoffeeGirlBBoyD", girlBBoyDBmp, girlBBoyDHighlightBmp, 746, s2d.height - girlBBoyDBmp.getSize().height);

		coffeePeople.push(girlBBoyD);

		// boy B
		var boyBBmp = new Bitmap(hxd.Res.coffee.boyb.toTile(), parent);
		boyBBmp.addShader(wobbleShadder(boyBBmp));
		var boyBHighlightBmp = new Bitmap(hxd.Res.coffee.boyb_highlight.toTile(), parent);
		var boyB = new Person(["BoyB"], "CoffeeBoyB", boyBBmp, boyBHighlightBmp, 1152, 553);

		coffeePeople.push(boyB);

		// Boy A
		var boyABmp = new Bitmap(hxd.Res.coffee.boyA.toTile(), parent);
		boyABmp.addShader(wobbleShadder(boyABmp));
		var boyAHighlightBmp = new Bitmap(hxd.Res.coffee.boyA_highlight.toTile(), parent);
		var boyA = new Person(["BoyA"], "CoffeeBoyA", boyABmp, boyAHighlightBmp, 992, s2d.height - boyABmp.getSize().height);

		coffeePeople.push(boyA);

		// Girl D
		var girlDBmp = new Bitmap(hxd.Res.coffee.girlD.toTile(), parent);
		girlDBmp.addShader(wobbleShadder(girlDBmp));
		var girlDHighlightBmp = new Bitmap(hxd.Res.coffee.girlD_highlight.toTile(), parent);
		var girlD = new Person(["GirlD"], "CoffeeGirlD", girlDBmp, girlDHighlightBmp, 42, s2d.height - girlDBmp.getSize().height);

		coffeePeople.push(girlD);

		// Girl C Boy C
		var girlCBoyCBmp = new Bitmap(hxd.Res.coffee.girlCBoyC.toTile(), parent);
		girlCBoyCBmp.addShader(wobbleShadder(girlCBoyCBmp));
		var girlCBoyCHighlightBmp = new Bitmap(hxd.Res.coffee.girlCBoyC_highlight.toTile(), parent);
		var girlCBoyC = new Person(["GirlC", "BoyC"], "CoffeeGirlCBoyC", girlCBoyCBmp, girlCBoyCHighlightBmp, 330, s2d.height - girlCBoyCBmp.getSize().height);

		coffeePeople.push(girlCBoyC);

		// Girl A
		var girlABmp = new Bitmap(hxd.Res.coffee.girlA.toTile(), parent);
		girlABmp.addShader(wobbleShadder(girlABmp));
		var girlAHighlightBmp = new Bitmap(hxd.Res.coffee.girlA_highlight.toTile(), parent);
		var girlA = new Person(["GirlA"], "CoffeeGirlA", girlABmp, girlAHighlightBmp, 229, s2d.height - girlABmp.getSize().height);

		coffeePeople.push(girlA);
	}

	function spawnCoffee(s2d:Scene, parent:Object, world:World) {
		// BG
		var bg = world.addEntity("bg").add(new Renderable(coffeeBg));
		coffeeBg.visible = true;

		currentEntities.push(bg);

		var totalNumberToSpawn = 7;

		var peopleToSpawn = new Array<Person>();
		peopleToSpawn.push(coffeePeople.shift());
		totalNumberToSpawn -= 1;
		peopleToSpawn.push(coffeePeople.shift());
		totalNumberToSpawn -= 2;

		Rand.create().shuffle(coffeePeople);

		var lastMet:Person = null;
		if (lastVisited.length > 0) {
			var lastNames = lastVisited[0];
			Rand.create().shuffle(lastNames);
			lastMet = coffeePeople.filter(function(f) {
				return f.names.contains(lastNames[0]);
			})[0];
			if (lastMet != null) {
				coffeePeople.remove(lastMet);
				peopleToSpawn.push(lastMet);
				totalNumberToSpawn -= lastMet.names.length;
			}
		}

		while (totalNumberToSpawn > 0 && coffeePeople.length > 0) {
			var person = coffeePeople.pop();
			if (totalNumberToSpawn >= person.names.length) {
				peopleToSpawn.push(person);
				totalNumberToSpawn -= person.names.length;
			}
		}

		for (person in peopleToSpawn) {
			var p = person.spawnPerson(world, eventBus);
			var highlight = person.spawnHighlight(p, world);

			currentEntities.push(p);
			currentEntities.push(highlight);
		}

		spawnSpark(s2d, parent, Const.Levels[2]);

		lastVisited = [];
	}

	function spawnSpark(s2d:Scene, parent:Object, level:String) {
		var sparkTile = hxd.Res.images.spark_128_128.toTile();
		var sparkTiles = [
			for (y in 0...Std.int(sparkTile.height / 128))
				for (x in 0...Std.int(sparkTile.width / 128))
					sparkTile.sub(x * 128, y * 128, 128, 128)
		];
		var path = new Path([new Point(s2d.width, s2d.height - 20), new Point(76, s2d.height - 20)]);

		var timerTile = hxd.Res.timer.toTile();
		var mask = new h2d.Graphics(parent);
		mask.beginFill(0xFF0000, 0.5);
		mask.drawRect(0, 0, timerTile.width, timerTile.height);
		mask.x = 30;
		mask.y = 658;

		var timerBmp = new Bitmap(timerTile, parent);
		timerBmp.addShader(wobbleShadder(timerBmp, .005));
		timerBmp.filter = new Mask(mask);
		var timer = world.addEntity("timer")
			.add(new Renderable(timerBmp))
			.add(new Transform(30, 658, timerBmp.width, timerBmp.height))
			.add(new TimerMask(mask, path));
		var sparkAnim = new h2d.Anim(sparkTiles, parent);

		currentEntities.push(timer);

		var spark = world.addEntity("spark")
			.add(new Renderable(sparkAnim))
			.add(new Transform(0, 0, 128, 128))
			.add(new Spark(path, function() {
				eventBus.publishEvent(new LevelComplete(level));
			}));

		currentEntities.push(spark);
	}

	function removeEntitnes() {
		var e = currentEntities.pop();
		while (e != null) {
			world.removeEntity(e);
			e = currentEntities.pop();
		}
	}

	function createPlayer(sceneWidth:Int, sceneHeight:Int):Entity {
		var playerSize = Const.TileSize;
		var playerX = sceneWidth / 2 - playerSize / 2;
		var playerY = sceneHeight / 2 - playerSize / 2;
		return world.addEntity("Player")
			.add(new Player())
			.add(new Transform(playerX, playerY, playerSize, playerSize))
			.add(new Velocity(0, 0));
	}

	function createCamera(sceneWidth:Int, sceneHeight:Int, target:Entity):Entity {
		var cameraBounds = Bounds.fromValues(0, 0, sceneWidth, sceneHeight);
		return world.addEntity("Camera")
			.add(new Transform())
			.add(new Velocity(0, 0))
			.add(new Camera(target, cameraBounds, sceneWidth / 2, sceneHeight / 2));
	}

	function setupSystems(world:World, scene:Scene, camera:Entity) {
		var window = Window.getInstance();
		clickableSystem = new ClickableSystem(window);
		highlightSystem = new HoverHighlightSystem(window, camera);
		world.addSystem(clickableSystem);
		world.addSystem(new PlayerInputController(Game.current.ca));
		world.addSystem(new VelocityController());
		world.addSystem(highlightSystem);
		world.addSystem(new TimerMaskSystem());
		world.addSystem(new SparkMover());
		world.addSystem(new CameraController(scene, console));
		world.addSystem(new Renderer(camera));
	}

	public override function update(dt:Float):Void {
		dialogueBox.update(dt);
		world.update(dt);
	}
}
