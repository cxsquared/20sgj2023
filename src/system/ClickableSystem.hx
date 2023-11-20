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
	var relX:Float = -1;
	var relY:Float = -1;

	public function new() {
		Game.current.s2d.addEventListener(function(e) {
			if (e.kind == EPush) {
				clicked = true;
				relX = e.relX;
				relY = e.relY;
			}

			if (e.kind == ERelease) {
				clicked = false;
				relX = -1;
				relY = -1;
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

		if (intersets(t, mx, my) || intersets(t, relX, relY)) {
			c.onClick();
		}
	}

	function intersets(t:Transform, mx:Float, my:Float) {
		return mx > t.x && mx < t.x + t.width && my > t.y && my < t.y + t.height;
	}
}
