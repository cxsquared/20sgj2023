package component;

import event.TalkedToEvent;
import ecs.event.EventBus;
import dialogue.event.StartNode.StartDialogueNode;
import ecs.component.Transform;
import ecs.component.Renderable;
import ecs.Entity;
import ecs.World;
import h2d.Bitmap;

class Person {
	public var names:Array<String>;
	public var bitmap:Bitmap;
	public var highlight:Bitmap;
	public var x:Float;
	public var y:Float;
	public var dialogueNode:String;

	public function new(names:Array<String>, dialogueNode:String, bmp:Bitmap, highlight:Bitmap, x:Float, y:Float) {
		this.names = names;
		this.dialogueNode = dialogueNode;
		this.bitmap = bmp;
		this.highlight = highlight;
		this.x = x;
		this.y = y;

		this.bitmap.visible = false;
		this.highlight.visible = false;
	}

	public function spawnPerson(world:World, eventBus:EventBus):Entity {
		this.bitmap.visible = true;
		this.highlight.visible = true;

		return world.addEntity(names.join(""))
			.add(new Renderable(bitmap))
			.add(new Transform(x, y, bitmap.getSize().width, bitmap.getSize().height))
			.add(new Clickable(function() {
				eventBus.publishEvent(new TalkedToEvent(names));

				var event = new StartDialogueNode(dialogueNode);
				eventBus.publishEvent(event);
			}));
	}

	public function spawnHighlight(person:Entity, world:World):Entity {
		return world.addEntity('${names.join("")}Highlight')
			.add(new Renderable(highlight))
			.add(person.get(Transform))
			.add(new HoverHighlight());
	}
}
