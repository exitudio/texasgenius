package com.sleepydesign.utils
{

	public class JSONUtil
	{
		public static function decode(value:String):*
		{
			return JSON.parse(value);
		}

		public static function encode(value:*):String
		{
			return JSON.stringify(value);
		}
	}
}
