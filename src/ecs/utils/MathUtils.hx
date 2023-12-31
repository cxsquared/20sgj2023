package ecs.utils;

import h2d.col.Point;

class MathUtils {
	// https://stackoverflow.com/questions/5731863/mapping-a-numeric-range-onto-another
	public static function map(x:Float, in_min:Float, in_max:Float, out_min:Float, out_max:Float):Float {
		return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
	}

	public static function normalizeToOne(value:Float, min:Float, max:Float):Float {
		return (value - min) / (max - min);
	}

	public static function getFourPointsAroundCenter(center:Point, itemWidth:Float, itemHeight:Float, padding:Float):Array<Point> {
		return [
			new Point(center.x - itemWidth - padding, center.y - itemHeight / 2),
			new Point(center.x - itemWidth / 2, center.y - itemHeight - padding),
			new Point(center.x + padding, center.y - itemHeight / 2),
			new Point(center.x - itemWidth / 2, center.y + padding)
		];
	}

	public static function roll(dice:Int, ?seed:Int):Int {
		return Math.floor(hxd.Math.random(dice) + 1);
	}

	public static function getSign(value:Float):Int {
		return value > 0 ? 1 : value < 0 ? -1 : 0;
	}

	public static function randomSign():Int {
		return hxd.Math.random() > .5 ? -1 : 1; 
	}

	// https://stackoverflow.com/questions/23689001/how-to-reliably-format-a-floating-point-number-to-a-specified-number-of-decimal
	public static function floatToStringPrecision(n:Float, prec:Int) {
		n = Math.round(n * Math.pow(10, prec));
		var str = '' + n;
		var len = str.length;
		if (len <= prec) {
			while (len < prec) {
				str = '0' + str;
				len++;
			}
			return '0.' + str;
		} else {
			return str.substr(0, str.length - prec) + '.' + str.substr(str.length - prec);
		}
	}

	// https://gist.github.com/jkilla1000/ed500705a8b7333b1b52
	private static var hexCodes = "0123456789ABCDEF";

	public static function rgbToHex(r:Int, g:Int, b:Int):Int
	{
		var hexString = "0x";
		//Red
		hexString += hexCodes.charAt(Math.floor(r/16));
		hexString += hexCodes.charAt(r%16);
		//Green
		hexString += hexCodes.charAt(Math.floor(g/16));
		hexString += hexCodes.charAt(g%16);
		//Blue
		hexString += hexCodes.charAt(Math.floor(b/16));
		hexString += hexCodes.charAt(b%16);
		
		return Std.parseInt(hexString);
	}
}
