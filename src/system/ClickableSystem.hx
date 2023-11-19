package system;

import hxd.Key;
import ecs.Entity;
import ecs.component.Transform;
import component.Clickable;
import ecs.system.IPerEntitySystem;

class ClickableSystem implements IPerEntitySystem {
	public var forComponents:Array<Class<Dynamic>> = [Clickable, Transform];

	public var canClick = true;
	var clicked = false;

	public function new() {
		Game.current.s2d.addEventListener(function(e) {
			if (e.kind == EPush) {
				clicked = true;
			}

			if (e.kind == ERelease) {
				clicked =  false;
			}
		});
	}

	public function update(entity:Entity, dt:Float) {
		var c = entity.get(Clickable);
		var t = entity.get(Transform);

		var mx = Game.current.s2d.mouseX;
		var my = Game.current.s2d.mouseY;

		if (!canClick || !clicked)
			return;

		if (mx > t.x && mx < t.x + t.width
			&& my > t.y && my < t.y + t.height) {
			c.onClick();
		}
	}
}
