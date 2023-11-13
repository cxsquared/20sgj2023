package system;

import component.Spark;
import ecs.component.Transform;
import ecs.Entity;
import ecs.system.IPerEntitySystem;

class SparkMover implements IPerEntitySystem {
	public var forComponents:Array<Class<Dynamic>> = [Spark, Transform];

	public function new() {}

	public function update(entity:Entity, dt:Float) {
		var t = entity.get(Transform);
		var s = entity.get(Spark);

		s.currentTime += dt;
		var p = s.path.getPointAtTime(s.currentTime);

		t.x = p.x - t.width / 2;
		t.y = p.y - t.height / 2;
	}
}
