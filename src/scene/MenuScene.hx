package scene;

import dialogue.event.DialogueHidden;
import dialogue.DialogueBoxController;
import dialogue.event.StartNode.StartDialogueNode;
import assets.Assets;
import h2d.Text;
import ecs.event.EventBus;
import h2d.Scene;
import h2d.Console;
import ecs.scene.GameScene;

class MenuScene extends GameScene {
	var eventBus:EventBus;
	var title:Text;
	var canStart = true;
	var dialogueBox:DialogueBoxController;

	public function new(heapsScene:Scene, console:Console) {
		super(heapsScene, console);

		eventBus = Game.current.globalEventBus;
	}

	function dialogueHidden(e:DialogueHidden) {
		eventBus.unsubscribe(DialogueHidden, dialogueHidden);
		dialogueBox.remove();
		haxe.Timer.delay(function() {
			Game.current.setGameScene(new PlayScene(getScene(), console));
		}, 1000);
	};

	public override function init():Void {
		var s2d = getScene();

		eventBus.subscribe(DialogueHidden, dialogueHidden);

		var font:h2d.Font = Assets.font;
		title = new h2d.Text(font);
		title.setScale(3);
		title.text = "How I Remember It";
		title.textAlign = Center;
		title.x = s2d.width / 2;
		title.y = s2d.height / 4;

		this.addChild(title);

		var button = new h2d.Text(font);
		button.text = "Play";
		button.textAlign = Center;
		button.x = s2d.width / 2;
		button.y = s2d.height * .75;

		var interaction = new h2d.Interactive(button.calcTextWidth(button.text) * 2, button.textHeight * 1.5, button);
		interaction.x -= button.calcTextWidth(button.text);
		interaction.onClick = function(event:hxd.Event) {
			if (canStart) {
				title.remove();
				button.remove();
				eventBus.publishEvent(new StartDialogueNode("Tutorial"));
				canStart = false;
			}
		}

		this.addChild(button);

		dialogueBox = new DialogueBoxController(eventBus, null, this, Game.current.ca, Assets.dialogue);
		dialogueBox.moveTo(4, getScene().height / 2 - dialogueBox.getSize().height / 2, TopRight);
	}

	public override function update(dt:Float):Void {
		dialogueBox.update(dt);
	}
}
