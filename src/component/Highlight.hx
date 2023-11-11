package component;

import h2d.Drawable;
import ecs.component.IComponent;

class Highlight implements IComponent {
	public var drawable:Drawable;
	public var offsetX = 0.0;
	public var offsetY = 0.0;

	// TODO: Maybe pass in a parent so that anims can get added correctly
	// if we pass in null
	public function new(?drawable:Drawable) {
		this.drawable = drawable;
	}

	public function debugText():String {
		return '[Highlight]';
	}

	public function remove() {
		if (drawable != null) {
			drawable.remove();
		}
	}
}
