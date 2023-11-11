package system;

import ecs.utils.CameraUtils;
import h2d.col.Point;
import ecs.component.Camera;
import ecs.Entity;
import ecs.system.IPerEntitySystem;
import ecs.component.Transform;
import component.Highlight;

class HighlightSystem implements IPerEntitySystem {
	public var forComponents:Array<Class<Dynamic>> = [Highlight, Transform];

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
		var h = entity.get(Highlight);
		var t = entity.get(Transform);

		var mx = window.mouseX;
		var my = window.mouseY;

		var point = new Point(t.x, t.y);
		var position = CameraUtils.worldToScreen(point, cameraComponent, new Point(cameraTransform.x, cameraTransform.y));

		h.drawable.setPosition(position.x, position.y);

		if (mx > t.x && mx < t.x + t.width && my > t.y && my < t.y + t.height) {
			h.drawable.visible = true;
		} else {
			h.drawable.visible = false;
		}
	}
}
