package component;

import ecs.utils.Path;
import h2d.Object;
import ecs.component.IComponent;

class TimerMask implements IComponent {
	public var mask:Object;
	public var currentTime:Float = 0;
	public var path:Path;
	public var xOffset = 1247;

	public function new(mask:Object, path:Path) {
		this.mask = mask;
		this.path = path;
	}

	public function debugText():String {
		return "[mask]";
	}

	public function remove() {
		if (mask != null)
			mask.remove();
	}
}
