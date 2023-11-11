package ui;

import h2d.Tile;
import h2d.ScaleGrid;
import h2d.Object;

class Bar extends Object {
	public var innerBarMaxWidth(get, never):Float;
	public var innerBarHeight(get, never):Float;
	public var outerWidth(get, never):Float;
	public var outerHeight(get, never):Float;

	var bg:ScaleGrid;
	var bar:ScaleGrid;
	var curValue:Float;
	var curMax:Float;
	var padding:Int;

	public function new(wid:Int, hei:Int, bgTile:Tile, barTile:Tile, ?parent:Object) {
		super(parent);

		curValue = 0;
		curMax = 1;

		bg = new ScaleGrid(bgTile, 1, 1, this);
		bar = new ScaleGrid(barTile, 1, 1, this);

		setSize(wid, hei, 1);
	}

	inline function get_innerBarMaxWidth()
		return outerWidth - padding * 2;

	inline function get_innerBarHeight()
		return outerHeight - padding * 2;

	inline function get_outerWidth()
		return bg.width;

	inline function get_outerHeight()
		return bg.height;

	public function setSize(wid:Int, hei:Int, pad:Int) {
		padding = pad;

		bar.setPosition(padding, padding);

		bg.width = wid + padding * 2;
		bar.width = wid;

		bg.height = hei + padding * 2;
		bar.height = hei;
	}

	public function set(v:Float, max:Float) {
		curValue = v;
		curMax = max;
		renderBar();
	}

	function renderBar() {
		bar.visible = curValue > 0;
		bar.width = innerBarMaxWidth * (curValue / curMax);
	}
}
