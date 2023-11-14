package system;

import component.TimerMask;
import ecs.Entity;
import ecs.system.IPerEntitySystem;

class TimerMaskSystem implements IPerEntitySystem {
	public var forComponents:Array<Class<Dynamic>> = [TimerMask];

	public function new() {}

	public function update(entity:Entity, dt:Float) {
		var m = entity.get(TimerMask);

		m.currentTime += dt;
		var x = m.path.getPointAtTime(m.currentTime).x - m.xOffset;
		m.mask.x = x;
	}
}
