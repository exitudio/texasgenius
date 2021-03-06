package net.area80.ui.component
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;

	import net.area80.ui.skin.ScrollBarSkin;

	import org.osflash.signals.Signal;

	public class Scrollbar extends Sprite
	{
		public var signalMove:Signal = new Signal();
		private var content:DisplayObjectContainer;

		private var maskWidth:Number;
		private var maskHeight:Number;
		private var scrollBarSkin:ScrollBarSkin;
		private var magnitudeMask:Number;
		private var isUpDownDirection:Boolean;


		private var arrowUp:Sprite;
		private var arrowDown:Sprite;
		private var bgScrollBar:Sprite;
		public var scrubber:Sprite;


		// -------Property width height x y-------
		private var magnitudeFix:String;
		private var positionFix:String;
		private var magnitudeMove:String;
		private var positionMove:String;
		private var maskMc:DisplayObjectContainer;
		// ----------Init value -----------------
		//public var contentStep:Number;//when arrow hit or scrol, content will move 1 step = contentPixel
		private var snapContentStep:Number;
		private var ratioMaskToContent:Number;
		private var magnitudeContentMove:Number //use in to check derection and magnitude to move. Becuase scroll mouse has magnitude
		private var initContentPosition:Number;
		private var ratioRectToContentMove:Number; //ratio of area that can move
		private var isScaleScrubber:Boolean;

		private var contentMoveMultiply:int = 0; //use when arrow hit or scroll

		private var scrubValue:Number; //value of scroll bar position	
		private var rect:Rectangle; //area that can scroll

		private var haveArrow:Boolean = false;
		private var intialBarPosition:Number;
		// --------- for easing -------------------
		private var destination:Number;
		private var lastPosition:Number = 1000000;

		/* TO DO LIST
			1. mouse wheel detect active by mask.
			2. click bar can move.
			3. scroll bar width height function
			4. when scroll at the edge snap tail.
		*/
		/**
		  COMMENT ...
		  * ส่ง mask mc เข้ามาเลยดีกว่า เพราะไม่งั้นต้องส่งตัวแปรมาเยอะมา width hight y(or x)
		  * เป็นposition เริ่มต้นเพราะมีปัญหาถ้าupdate แล้วcontent ต้องไปอยู่ที่position เริ่มต้นเลยต้องใช้mask อิงposition
		  *
		 */

		public function Scrollbar(content:DisplayObjectContainer, maskMc:DisplayObjectContainer, scrollBarSkin:ScrollBarSkin, isUpDownDirection:Boolean = true, snapContentStep:Number = 1, isScaleScrubber:Boolean = false)
		{
			this.content = content;

			this.maskMc = maskMc;
			this.scrollBarSkin = scrollBarSkin;
			this.isUpDownDirection = isUpDownDirection;
			this.snapContentStep = snapContentStep;
			this.isScaleScrubber = isScaleScrubber;

			arrowUp = this.scrollBarSkin.arrowUp;
			arrowDown = this.scrollBarSkin.arrowDown;
			bgScrollBar = this.scrollBarSkin.bgScrollBar;
			scrubber = this.scrollBarSkin.scrubber;

			this.x = scrollBarSkin.x;
			this.y = scrollBarSkin.y;
			scrollBarSkin.x = 0;
			scrollBarSkin.y = 0;
			// checking default type
			if (isUpDownDirection) {
				magnitudeFix = "width";
				positionFix = "x";

				magnitudeMove = "height";
				positionMove = "y";
			} else {
				magnitudeFix = "height";
				positionFix = "y";

				magnitudeMove = "width";
				positionMove = "x";
			}



			this.addChild(scrollBarSkin);


			justify();

			addEventListener(Event.ADDED_TO_STAGE, init);

		}

		private function init(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			addEventListener(Event.REMOVED_FROM_STAGE, dispose);
			addEvent();
			checkShowScrollbar();
		}

		private function checkShowScrollbar():void
		{
			trace("maskMc[magnitudeMove]>=content[magnitudeMove]:"+maskMc[magnitudeMove]+" / "+content[magnitudeMove]);
			if (maskMc[magnitudeMove]>=content[magnitudeMove]) {
				scrollBarSkin.visible = false;
				content.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelMove);
			} else {
				scrollBarSkin.visible = true;
				content.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelMove);
			}
		}


		/****************************************************
		 * compose all object
		 *
		 ***************************************************/
		private function justify():void
		{
			if (arrowUp&&arrowDown) {
				haveArrow = true;
				intialBarPosition = bgScrollBar[positionMove];
			} else {
				intialBarPosition = 0;
			}

			//content & maskMc
			/*content.x = maskMc.x;
			content.y = maskMc.y;*/

			//RATIO
			ratioMaskToContent = maskMc[magnitudeMove]/content[magnitudeMove];
			//scrollBarSkin
			//this[positionFix] = maskMc[positionFix] + maskMc[magnitudeFix];
			//this[positionMove] = maskMc[positionMove];
			//arrowUp
//			if(haveArrow){
//				arrowUp.x = 0;
//				arrowUp.y = 0;
//			}
			//bgScrollBar
			//bgScrollBar[positionFix] = 0;
			//bgScrollBar[positionMove] = intialBarPosition;
//			bgScrollBar[magnitudeMove] = maskMc[magnitudeMove] - arrowUp[magnitudeMove] - arrowDown[magnitudeMove];
			//arrowDown
			if (haveArrow) {
				//arrowDown[positionFix] = 0;
				//arrowDown[positionMove] = bgScrollBar[positionMove] + bgScrollBar[magnitudeMove];
			}
			//scrubber
			scrubber[positionFix] = bgScrollBar[positionFix];
			if (isScaleScrubber) {
				scrubber[magnitudeMove] = bgScrollBar[magnitudeMove]*ratioMaskToContent;
			}

			//scroll area
			rect = new Rectangle();
			rect[positionFix] = bgScrollBar[positionFix];
			rect[positionMove] = bgScrollBar[positionMove];
			rect[magnitudeFix] = 0;
			rect[magnitudeMove] = bgScrollBar[magnitudeMove]-scrubber[magnitudeMove];

			//magnitude that content can move
			magnitudeContentMove = content[magnitudeMove]-maskMc[magnitudeMove];

			ratioRectToContentMove = rect[magnitudeMove]/magnitudeContentMove;



			//// align content and scrubber
			initContentPosition = maskMc[positionMove];
			if (content[magnitudeMove]>maskMc[magnitudeMove]) {
				if (content[positionMove]+content[magnitudeMove]<maskMc[positionMove]+maskMc[magnitudeMove]) {
					content[positionMove] = maskMc[positionMove]+maskMc[magnitudeMove]-content[magnitudeMove];
//					scrubber[positionMove] = bgScrollBar[positionMove]+bgScrollBar[magnitudeMove]-scrubber[magnitudeMove]; //bgScrollBar[positionMove];
				}
			} else {
				content[positionMove] = initContentPosition;
//				scrubber[positionMove] = bgScrollBar[positionMove];
			}

			scrubber[positionMove] = bgScrollBar[positionMove]+((maskMc[positionMove]-content[positionMove])*ratioRectToContentMove);

		}

		/****************************************************
		 *event
		 *
		 ****************************************************/
		private function addEvent():void
		{
			scrubber.addEventListener(MouseEvent.MOUSE_DOWN, startMove, false, 0, true);
			if (haveArrow) {
				arrowUp.addEventListener(MouseEvent.MOUSE_DOWN, moveUp, false, 0, true);
				arrowDown.addEventListener(MouseEvent.MOUSE_DOWN, moveDown, false, 0, true);
			}
			stage.addEventListener(MouseEvent.MOUSE_UP, removeMove, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, removeMove, false, 0, true);
			content.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelMove);
		}

		private function startMove(e:MouseEvent):void
		{
			scrubber.startDrag(false, rect);

			stage.addEventListener(MouseEvent.MOUSE_MOVE, update, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, stopMove, false, 0, true);
		}

		private function moveDown(e:MouseEvent):void
		{
			contentMoveMultiply = -1;
			addEventListener(Event.ENTER_FRAME, moveContent, false, 0, true);
		}

		private function moveUp(e:MouseEvent):void
		{
			contentMoveMultiply = 1;
			addEventListener(Event.ENTER_FRAME, moveContent, false, 0, true);
		}

		private function removeMove(e:MouseEvent):void
		{
			removeEventListener(Event.ENTER_FRAME, moveContent);
		}

		private function mouseWheelMove(e:MouseEvent):void
		{
			//trace(e.delta);
			contentMoveMultiply = e.delta<=0?(e.delta-1):e.delta;
			moveContent();
		}

		// called by arrow and mouse wheel
		private function moveContent(e:Event = null):void
		{
			//trace("contentMoveMultiply :::: "+contentMoveMultiply);
			if (contentMoveMultiply>0) {
				//trace("scrub move down");
				//content move down, scrubber move up
				if (scrubber[positionMove]>intialBarPosition) {
					scrubber[positionMove] -= contentMoveMultiply*snapContentStep*ratioRectToContentMove;
					setSnap();
				}
			} else {
				//content move up, scrubber move down
				//trace("scrub move up");
				if (scrubber[positionMove]<rect[positionMove]+rect[magnitudeMove]) {
					scrubber[positionMove] -= contentMoveMultiply*snapContentStep*ratioRectToContentMove;
					setSnap();
				}
			}
			signalMove.dispatch();
		}

		private function stopMove(e:MouseEvent = null):void
		{
			scrubber.stopDrag();
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopMove);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, update);
			setSnap();
		}

		/*****************************************************
		 * snap function
		 * this function will move scrubber to the snap step
		 ****************************************************/
		private function setSnap():void
		{
			//if(snapContentStep){
			scrubValue = (scrubber[positionMove]-intialBarPosition)/rect[magnitudeMove];
			destination = initContentPosition-(magnitudeContentMove*scrubValue);

			var contentVal:Number = initContentPosition-destination;
			var fraction:Number = contentVal%snapContentStep;
			var contentValSnap:Number = ((contentVal-fraction)+Math.round(fraction/snapContentStep)*snapContentStep)/magnitudeContentMove;
			//trace("contentValSnap :: "+contentValSnap+",  magnitudeContentMove::"+magnitudeContentMove);

			if (scrubber[positionMove]<intialBarPosition) {
				//check upper limit
				scrubber[positionMove] = intialBarPosition;
				trace('a');
			} else if (scrubber[positionMove]>=rect[positionMove]+rect[magnitudeMove]) { //check lower limit
				scrubber[positionMove] = rect[positionMove]+rect[magnitudeMove];
				trace('b');
			} else {
				scrubber[positionMove] = rect[positionMove]+rect[magnitudeMove]*contentValSnap;
				trace('c');
			}
			update();
		}

		/****************************************************
		 * update will be called when scrub move
		 ****************************************************/
		private function update(e:MouseEvent = null):void
		{
			scrubValue = (scrubber[positionMove]-intialBarPosition)/rect[magnitudeMove];
			destination = initContentPosition-(magnitudeContentMove*scrubValue);

			addEventListener(Event.ENTER_FRAME, animove, false, 0, true);
		}

		private function animove(e:Event):void
		{
			content[positionMove] += (destination-content[positionMove])/3;
			if (lastPosition==content[positionMove]) {
				content[positionMove] = destination;
				removeEventListener(Event.ENTER_FRAME, animove);
					//trace("+++++++ remove ++++");
			}
			lastPosition = content[positionMove];
			signalMove.dispatch();
			//trace("move..."+(Math.abs(destination)-Math.abs(content[positionMove])));
		}

		/****************************************************
		 *
		 * PUBLIC FUNCTION
		 *
		 ***************************************************/
		public function contentUpdate(displayObjectContainer:DisplayObjectContainer):void
		{
			content.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelMove);
			content = displayObjectContainer;
			updateStatus()
		}

		public function updateStatus():void
		{
			//content.addEventListener(MouseEvent.MOUSE_WHEEL,mouseWheelMove);
			removeEventListener(Event.ENTER_FRAME, animove);

			justify();
			checkShowScrollbar();
		}

		public function get size():Number
		{
			return this[magnitudeMove];
		}

		public function set size($value:Number):void
		{
			arrowUp[positionMove] = 0;
			bgScrollBar[positionMove] = arrowUp[magnitudeMove];
			bgScrollBar[magnitudeMove] = $value-arrowUp[magnitudeMove]-arrowDown[magnitudeMove];
			arrowDown[positionMove] = bgScrollBar[positionMove]+bgScrollBar[magnitudeMove]
			scrubber[positionMove] = bgScrollBar[positionMove];

			justify();
		}

		/****************************************************
		 *dispose function will be called automaticly when this is removeChilded.
		 * @param e
		 *
		 ****************************************************/
		private function dispose(e:Event):void
		{
//			scrubber.removeEventListener(MouseEvent.MOUSE_DOWN, startMove);
			if (arrowUp)
				arrowUp.removeEventListener(MouseEvent.MOUSE_DOWN, moveUp);
			if (arrowDown)
				arrowDown.removeEventListener(MouseEvent.MOUSE_DOWN, moveDown);
			stage.removeEventListener(MouseEvent.MOUSE_UP, removeMove);
			if (content)
				content.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelMove);

			stage.removeEventListener(MouseEvent.MOUSE_MOVE, update);
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopMove);

			stopMove();

			removeEventListener(Event.ENTER_FRAME, animove);
			removeEventListener(Event.REMOVED_FROM_STAGE, dispose);
		}
	}
}
