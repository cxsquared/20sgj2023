package system;

import ecs.component.Camera;
import ecs.Entity;
import ecs.component.Renderable;
import component.HoverHighlight;
import ecs.component.Transform;
import ecs.system.IPerEntitySystem;

class HoverHighlightSystem implements IPerEntitySystem {
	public var forComponents:Array<Class<Dynamic>> = [Transform, HoverHighlight, Renderable];

	public var enabled = true;

	var window:hxd.Window;
	var cameraTransform:Transform;
	var cameraComponent:Camera;

	public var camera(default, set):Entity;

	public function set_camera(newCamera:Entity) {
		cameraComponent = newCamera.get(Camera);
		cameraTransform = newCamera.get(Transform);
		return camera = newCamera;
	}

	public function new(w:hxd.Window, camera:Entity) {
		this.window = w;
		this.camera = camera;
	}

	public function update(entity:Entity, dt:Float) {
		var t = entity.get(Transform);
		var r = entity.get(Renderable);

		var mx = window.mouseX;
		var my = window.mouseY;

		if (enabled && mx > t.x && mx < t.x + t.width && my > t.y && my < t.y + t.height) {
			r.drawable.visible = true;
		} else {
			r.drawable.visible = false;
		}
	}
}
