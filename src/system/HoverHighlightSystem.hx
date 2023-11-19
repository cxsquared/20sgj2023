package system;

import ecs.Entity;
import ecs.component.Renderable;
import component.HoverHighlight;
import ecs.component.Transform;
import ecs.system.IPerEntitySystem;

class HoverHighlightSystem implements IPerEntitySystem {
	public var forComponents:Array<Class<Dynamic>> = [Transform, HoverHighlight, Renderable];

	public var enabled = true;

	public function new() {
	}

	public function update(entity:Entity, dt:Float) {
		var t = entity.get(Transform);
		var r = entity.get(Renderable);

		var mx = Game.current.s2d.mouseX;
		var my = Game.current.s2d.mouseY;

		if (enabled && mx  > t.x && mx < t.x + t.width
			&& my > t.y && my < t.y + t.height) {
			r.drawable.visible = true;
		} else {
			r.drawable.visible = false;
		}
	}
}
