package system;

import hxd.Key;
import ecs.Entity;
import ecs.component.Transform;
import component.Clickable;
import ecs.system.IPerEntitySystem;

class ClickableSystem implements IPerEntitySystem {
	public var forComponents:Array<Class<Dynamic>> = [Clickable, Transform];

	var window:hxd.Window;

	public var canClick = true;

	public function new(w:hxd.Window) {
		this.window = w;
	}

	public function update(entity:Entity, dt:Float) {
		var c = entity.get(Clickable);
		var t = entity.get(Transform);

		var mx = window.mouseX;
		var my = window.mouseY;

		if (!canClick || !Key.isPressed(Key.MOUSE_LEFT))
			return;

		if (mx > t.x && mx < t.x + t.width && my > t.y && my < t.y + t.height) {
			c.onClick();
		}
	}
}
