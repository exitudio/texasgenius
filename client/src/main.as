package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import EXIT.util.JSONLoader;
	
	import model.MainModel;
	
	import module.IPage;
	import module.gamepage.GamePage2;
	import module.roompage.RoomPage;
	
	import net.area80.utils.DrawingUtils;
	
	public class main extends Sprite
	{
		private var mainModel:MainModel = MainModel.getInstance();
		private var currentPageSprite:IPage;
		private var freezeMc:Sprite = DrawingUtils.getRectSprite(500,500,0);
		
		private var pageLayer:Sprite = new Sprite();
		private var freezeLayer:Sprite = new Sprite();
		
		public function main()
		{
			/*var urlLoader:URLLoader = new URLLoader(new URLRequest("http://texasgenius.com/phpsys/action.php?action_option=getCard&name=[%22547822084_ธนาคาร%20ชิพ%20โคล่า%20(ขายชิปไม่ได้แจกไม่ต้องมาขอ)_0.15618322091177106%22,%22547822084_ธนาคาร%20ชิพ%20โคล่า%20(ขายชิปไม่ได้แจกไม่ต้องมาขอ)_0.95243623200804%22]&roomid=3"));
			urlLoader.addEventListener(Event.COMPLETE,function(e:Event):void{
				trace("data:"+e.currentTarget.data);
			});*/
			
			
			
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			
			var obj:Object = root.loaderInfo.parameters;
			if( obj!=null ){
				UserData.access_token = obj.access_token;
				UserData.fbuid = obj.fbuid;
			}
			trace("access_token:"+UserData.access_token);
			trace("uid:"+UserData.fbuid);
			
			addChild(pageLayer);
			addChild(freezeLayer);
			
			mainModel.addChangePageCallback(changePage);
			mainModel.addFreezeCallback(freezeCallback);
			
			freezeMc.alpha = .5;
			
			var jsonLoader:JSONLoader = new JSONLoader("https://graph.facebook.com/"+UserData.fbuid);
			jsonLoader.signalComplete.add(getUserData);
			jsonLoader.load();
		}
		
		private function getUserData(_json:*):void
		{
			mainModel.changePage(MainModel.PAGE_ROOM);
			//ServerConnector.getInstace().start(UserData.fbuid+"_"+_json.name+"_"+Math.random());
			ServerConnector.getInstace().start(UserData.fbuid+"_ธนาคาร ชิพ โคล่า (ขายชิปไม่ได้แจกไม่ต้องมาขอ)_"+Math.random());
		}
		
		private function changePage(_page:String):void
		{
			if(currentPageSprite){
				currentPageSprite.dispose();
				pageLayer.removeChild(Sprite(currentPageSprite));
			}
			if( _page == MainModel.PAGE_ROOM ){
				currentPageSprite = new RoomPage();
				currentPageSprite.start();
				pageLayer.addChild( Sprite(currentPageSprite) );
			}else if( _page == MainModel.PAGE_GAME ){
				currentPageSprite = new GamePage2();
				currentPageSprite.start();
				pageLayer.addChild( Sprite(currentPageSprite) );
			}
		}
		
		private function freezeCallback(_isFreeze:Boolean):void
		{
			if( _isFreeze ){
				this.mouseEnabled = false;
				this.mouseChildren = false;
				freezeMc.width = stage.stageWidth;
				freezeMc.height = stage.stageHeight;
				freezeLayer.addChild(freezeMc);
			}else{
				this.mouseEnabled = true;
				this.mouseChildren = true;
				if( freezeLayer.contains(freezeMc) ){
					freezeLayer.removeChild(freezeMc);
				}
			}
		}
	}
}