package com.sleepydesign.net
{
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	/**
	 * @example
	 *
	 * 	just load		: LoaderUtil.load("test.jpg", trace);
	 * 	load as bitmap	: LoaderUtil.loadAsset("test.jpg", trace);
	 * 	load as binary	: LoaderUtil.loadBinary("test.jpg", trace);
	 *
	 * @author	katopz
	 */
	public class LoaderUtil
	{
		public static const BLANK_LOADER_CLIP:Shape = new Shape;

		public static var useDebug:Boolean = true;

		public static var showLoader:Function = new Function();
		public static var hideLoader:Function = new Function();

		public static var defaultLoaderClip:DisplayObject;

		public static var loaderDict:Dictionary = new Dictionary(true);

		public static function setLoader(uri:String, loaderClip:DisplayObject):void
		{
			loaderDict[uri] = loaderClip;
		}

		public static function ignoreLoader(uri:String):void
		{
			setLoader(uri, BLANK_LOADER_CLIP);
		}

		private static var loaders:Array = [];

		public static function saveJPG(uri:String, data:ByteArray, eventHandler:Function = null):URLLoader
		{
			return saveBinary(uri, data, eventHandler, "image/jpeg");
		}

		public static function savePNG(uri:String, data:ByteArray, eventHandler:Function = null):URLLoader
		{
			return saveBinary(uri, data, eventHandler, "image/png");
		}

		public static function saveBinary(uri:String, data:ByteArray, eventHandler:Function = null, contentType:String = "application/octet-stream"):URLLoader
		{
			var _loader:URLLoader = new URLLoader();
			_loader.dataFormat = URLLoaderDataFormat.BINARY;

			if (eventHandler is Function)
				_loader.addEventListener(Event.COMPLETE, eventHandler);

			var request:URLRequest = new URLRequest(uri);
			request.contentType = contentType;
			request.method = URLRequestMethod.POST;
			request.data = data;

			// gc
			var _removeEventListeners:Function = function():void
			{
				if (eventHandler is Function)
					_loader.removeEventListener(Event.COMPLETE, eventHandler);

				if (loaderDict[uri])
					loaderDict[uri].visible = false;

				if (defaultLoaderClip && hideLoader is Function)
					hideLoader();

				// gc
				if (_loaderVO)
				{
					removeItem(loaders, _loaderVO);
					_loaderVO.destroy = null;
					_loaderVO.loader = null;
				}

				_loaderVO = null;
				_loader = null;
				request = null;
			}

			var _loaderVO:Object = {loader: _loader, destroy: _removeEventListeners};

			_loader.addEventListener(Event.COMPLETE, _removeEventListeners);

			// destroy
			loaders.push(_loaderVO);

			_loader.load(request);

			return _loader;
		}

		/**
		 * Load as ByteArray
		 * @param byteArray
		 * @param eventHandler
		 * @return Loader
		 */
		public static function loadBytes(byteArray:ByteArray, eventHandler:Function = null, context:LoaderContext = null):Loader
		{
			var _loader:Loader = new Loader();
			if (eventHandler is Function)
				_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, eventHandler);

			_loader.loadBytes(byteArray, context);

			// gc
			var _loaderVO:Object = {loader: null, destroy: null};
			const _removeEventListeners:Function = function():void
			{
				if (eventHandler is Function)
					_loader.removeEventListener(Event.COMPLETE, eventHandler);

				if (loaderDict[_loader.contentLoaderInfo.url])
					loaderDict[_loader.contentLoaderInfo.url].visible = false;
				else if (defaultLoaderClip && hideLoader is Function)
					hideLoader();

				// gc
				if (_loaderVO)
				{
					removeItem(loaders, _loaderVO);
					_loaderVO.destroy = null;
					_loaderVO.loader = null;
				}

				_loaderVO = null;
				_loader = null;
			};
			_loaderVO.info = _loader;
			_loaderVO.destroy = _removeEventListeners;
			loaders.push(_loaderVO);

			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, _removeEventListeners);

			return _loader;
		}

		/**
		 * Load as URLVariables
		 * @param uri
		 * @param eventHandler
		 * @return URLLoader
		 */
		public static function loadVars(uri:String, eventHandler:Function = null):URLLoader
		{
			return load(uri, function(event:Event):void
			{
				if (event.type == Event.COMPLETE)
					event.target.data = new URLVariables(String(event.target.data));

				if (eventHandler is Function)
					eventHandler(event);
			}, URLLoaderDataFormat.TEXT) as URLLoader;
		}

		/**
		 * Load as XML
		 * @param uri
		 * @param eventHandler
		 * @return URLLoader
		 */
		public static function loadXML(uri:String, eventHandler:Function = null):URLLoader
		{
			return load(uri, function(event:Event):void
			{
				if (event.type == Event.COMPLETE)
					event.target.data = new XML(event.target.data);

				if (eventHandler is Function)
					eventHandler(event);
			}, "xml") as URLLoader;
		}

		/**
		 * Load as Image type
		 * @param uri
		 * @param eventHandler
		 * @return Loader
		 */
		public static function loadAsset(uri:String, eventHandler:Function = null):Loader
		{
			return load(uri, eventHandler, "asset") as Loader;
		}


		public static function loadBinaryAsBitmap(uri:String, eventHandler:Function = null):Loader
		{
			const loader:Loader = new Loader();

			loadBinary(uri, function(event:Event):void
			{
				if (event.type == Event.COMPLETE)
				{

					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(event:Event):void
					{
						if (eventHandler is Function)
						{
							loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, eventHandler);
							eventHandler(event);
						}
					});
					loader.loadBytes(event.target.data as ByteArray);
				}
				else
				{
					if (eventHandler is Function)
						eventHandler(event);
				}
			});

			return loader;
		}

		/**
		 * Load as Binary type
		 * @param uri
		 * @param eventHandler
		 * @return URLLoader
		 */
		public static function loadBinary(uri:String, eventHandler:Function = null, context:LoaderContext = null):URLLoader
		{
			return load(uri, eventHandler, URLLoaderDataFormat.BINARY, null, false, context) as URLLoader;
		}

		public static function loadCompress(uri:String, eventHandler:Function = null):URLLoader
		{
			return load(uri, function(event:Event):void
			{
				if (event.type == Event.COMPLETE)
				{
					event.target.data = ByteArray(event.target.data);
					try
					{
						ByteArray(event.target.data).uncompress();
					}
					catch (e:*)
					{
						trace("[Warning] not compressed data");
					}
				}

				if (eventHandler is Function)
					eventHandler(event);
			}, URLLoaderDataFormat.BINARY) as URLLoader;
		}

		public static function queue(uri:String, eventHandler:Function = null, type:String = "auto", urlRequest:URLRequest = null):*
		{
			return load(uri, eventHandler, type, urlRequest, true);
		}

		public static function start():void
		{
			for each (var loaderObject:Object in loaders)
				if (loaderObject.urlRequest)
					loaderObject.loader.load(loaderObject.urlRequest);
		}

		/**
		 * Just load
		 * @param uri
		 * @param eventHandler
		 * @param type
		 * @return Loader, URLLoader
		 */
		public static function load(uri:String, eventHandler:Function = null, type:String = "auto", urlRequest:URLRequest = null, isQueue:Boolean = false, context:LoaderContext = null):Object
		{
			if (loaderDict[uri])
				loaderDict[uri].visible = true;
			else if (defaultLoaderClip && showLoader is Function)
				showLoader();

			// select type
			if (type == "auto")
				switch (getType(uri))
				{
					case "jpg":
					case "png":
					case "gif":
					case "swf":
						type = "asset";
						break;
					case "asp":
					case "php":
					case "text":
					case "json":
					case "xml":
						type = URLLoaderDataFormat.TEXT;
						break;
					default:
						type = URLLoaderDataFormat.BINARY;
						break;
				}

			if (useDebug)
				trace(" ! Load [" + type + "] : " + uri);

			// select loader
			var _loader:*;
			if (type == "asset")
			{
				//The Loader class is used to load SWF files or image (JPG, PNG, or GIF) files. 
				//Use the load() method to initiate loading. The loaded display object is added as a child of the Loader object. 
				var loader:Loader = new Loader();
				_loader = loader.contentLoaderInfo;
			}
			else
			{
				//The URLLoader class downloads data from a URL as text, binary data, or URL-encoded variables. 
				var urlLoader:URLLoader = new URLLoader();
				urlLoader.dataFormat = type;
				_loader = urlLoader;
			}

			// callback
			if (eventHandler is Function)
			{
				_loader.addEventListener(Event.COMPLETE, eventHandler);
				_loader.addEventListener(ProgressEvent.PROGRESS, eventHandler);

				_loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, eventHandler);
				_loader.addEventListener(IOErrorEvent.IO_ERROR, eventHandler);
				_loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, eventHandler);
			}

			var _loaderVO:Object = {info: null, destroy: null, loader: null, urlRequest: null};
			const _removeEventListeners:Function = function():void
			{
				_loader.removeEventListener(Event.COMPLETE, _removeEventListeners);

				if (eventHandler is Function)
				{
					_loader.removeEventListener(Event.COMPLETE, eventHandler);
					_loader.removeEventListener(ProgressEvent.PROGRESS, eventHandler);

					_loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, eventHandler);
					_loader.removeEventListener(IOErrorEvent.IO_ERROR, eventHandler);
					_loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, eventHandler);
				}

				// gc
				if (_loaderVO)
				{
					removeItem(loaders, _loaderVO);
					_loaderVO.destroy = null;
					_loaderVO.info = null;
					_loaderVO.loader = null;
				}

				if (loaderDict[uri])
				{
					loaderDict[uri].visible = false;
				}
				else if (defaultLoaderClip && (hideLoader is Function) && loaders && (loaders.length == 0))
				{
					hideLoader();
				}
				else
				{
					var isDone:Boolean = true;
					for each (var loaderObject:Object in loaders)
					{
						try
						{
							if (!loaderDict[loaderObject.urlRequest.url])
								isDone = false;
						}
						catch (e:Error)
						{
							trace(e.toString())
						}
					}

					if (isDone)
						hideLoader();
				}

				_loaderVO = null;

				loader = null;
				urlLoader = null;
			};
			_loaderVO.info = _loader;
			_loaderVO.destroy = _removeEventListeners;
			loaders.push(_loaderVO);

			// gc
			_loader.addEventListener(Event.COMPLETE, _removeEventListeners);

			// 404
			const _404:Function = function(event:Event):void
			{
				_loader.removeEventListener(IOErrorEvent.IO_ERROR, _404);
				if (useDebug)
				{
					trace(" ! Error : " + event);
					trace(" ! Not found? : " + uri);
				}
				_removeEventListeners();
			}
			_loader.addEventListener(IOErrorEvent.IO_ERROR, _404);

			// load
			try
			{
				urlRequest = urlRequest ? urlRequest : new URLRequest(uri);
				_loaderVO.urlRequest = urlRequest;

				if (type == "asset")
				{
					_loaderVO.loader = loader;
					if (!isQueue)
						loader.load(urlRequest, context); //, new LoaderContext(false, ApplicationDomain.currentDomain));
					return loader;
				}
				else
				{
					_loaderVO.loader = urlLoader;
					if (!isQueue)
						urlLoader.load(urlRequest);
					return urlLoader;
				}
			}
			catch (e:Error)
			{
				if (useDebug)
					trace(" ! Error in loading file (" + uri + "): \n" + e.message + "\n" + e.getStackTrace());
			}

			return null;
		}

		public static function request(uri:String, data:*, eventHandler:Function = null, type:String = "auto", method:String = URLRequestMethod.POST):Object
		{
			if (data)
			{
				const _urlRequest:URLRequest = new URLRequest(uri);
				_urlRequest.method = method;
				_urlRequest.data = data;

				return load(uri, eventHandler, type, _urlRequest);
			}
			else
			{
				return load(uri, eventHandler, type);
			}
		}

		public static function requestVars(uri:String, data:*, eventHandler:Function = null, method:String = URLRequestMethod.POST):URLLoader
		{
			return request(uri, data, function(event:Event):void
			{
				if (event.type == Event.COMPLETE)
					event.target.data = new URLVariables(String(event.target.data));

				if (eventHandler is Function)
					eventHandler(event);
			}, URLLoaderDataFormat.TEXT, method) as URLLoader;
		}

		public static function requestXML(uri:String, data:*, eventHandler:Function = null, method:String = URLRequestMethod.POST):URLLoader
		{
			return request(uri, data, function(event:Event):void
			{
				if (event.type == Event.COMPLETE)
					event.target.data = new XML(String(event.target.data));

				if (eventHandler is Function)
					eventHandler(event);
			}, URLLoaderDataFormat.TEXT, method) as URLLoader;
		}

		/**
		 * Get type of file URI
		 * @param value
		 * @return type of file URI
		 */
		public static function getType(value:String):String
		{
			//file.something.type?q#a
			value = value.split("#")[0];
			//file.something.type?q
			value = value.split("?")[0];
			//file.something.type
			var results:Array = value.split(".");
			//type
			return results[results.length - 1].toLowerCase();
		}

		public static function isPicture(source:String):Boolean
		{
			return ["jpg", "jpeg", "gif", "png"].indexOf(getType(source)) > -1;
		}

		private static function removeItem(tarArray:Array, item:*):uint
		{
			var i:int = tarArray.indexOf(item);
			var f:uint = 0;

			while (i != -1)
			{
				tarArray.splice(i, 1);
				i = tarArray.indexOf(item, i);
				f++;
			}

			return f;
		}

		public static function cancel(loader:* = null):void
		{
			hideLoader();

			if (loaders.length <= 0)
				return;

			if (!loader)
				loader = loaders[0].info;

			if (loader is Loader)
				loader = loader.contentLoaderInfo;

			for each (var _loaderVO:* in loaders)
			{
				if (_loaderVO && _loaderVO.info == loader && _loaderVO.destroy is Function)
					_loaderVO.destroy();
			}
		}
	}
}
