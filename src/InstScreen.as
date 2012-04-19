package
{
	import fl.containers.ScrollPane;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	import flash.utils.setTimeout;
	/**
	 * ...
	 * @author Alexandre
	 */
	public class InstScreen extends MovieClip
	{
		private var innerObj:MovieClip;
		private var nChecks:int = 15;
		private var status:String = "";
		
		public function InstScreen() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			setTimeout(getInner, 1);
			
			this.x = stage.stageWidth / 2;
			this.y = stage.stageHeight / 2;
			
			//this.gotoAndStop("END");
			this.visible = false;
			
			//this.addEventListener(MouseEvent.CLICK, closeScreen);
			closeButton.addEventListener(MouseEvent.CLICK, closeScreen, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_UP, escCloseScreen);
			
		}
		
		private function escCloseScreen(e:KeyboardEvent):void 
		{
			if (e.keyCode ==  Keyboard.ESCAPE) {
				if (this.currentFrame == 1) closeScreen();//this.play();
			}
		}
		
		private function getInner():void
		{
			innerObj = MovieClip(ScrollPane(scroll).content);
			
			if (innerObj == null) setTimeout(getInner, 100);
			else {
				for (var i:int = 1; i <= nChecks; i++) 
				{
					innerObj["check" + String(i)].addEventListener(MouseEvent.CLICK, dispatchEventClick);
				}
			}
		}
		
		private function dispatchEventClick(e:MouseEvent):void 
		{
			dispatchEvent(new Event("clicado", true));
		}
		
		private function closeScreen(e:MouseEvent = null):void 
		{
			//this.play();
			this.visible = false;
		}
		
		public function openScreen():void
		{
			//this.gotoAndStop("BEGIN");
			this.visible = true;
		}
		
		public function saveStatus():String
		{
			status = "";
			
			for (var i:int = 1; i <= nChecks; i++) 
			{
				if (innerObj["check" + String(i)].selected) status += String(i) + ";";
			}
			
			return status;
		}
		
		public function setStatus(str:String):void
		{
			status = str;
			recoverStatus();
		}
		
		private function recoverStatus():void
		{
			if (innerObj == null) {
				setTimeout(recoverStatus, 100);
				return;
			}
			
			if(innerObj != null){
				var arr:Array = status.split(";");
				
				for (var i:int = 0; i < arr.length - 1; i++) 
				{
					innerObj["check" + arr[i]].selected = true;
				}
			}
		}
		
	}

}