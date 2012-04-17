package  
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Alexandre
	 */
	public class Fundo extends MovieClip
	{
		public var currentPeca:MovieClip;
		public var disponivel:Boolean = true;
		public var currentposition:Point = new Point();
		public var espaco:MovieClip;
		public var inicialPos:Point;
		
		public function Fundo() 
		{
			
		}
		
		public function setPosition(posX:Number, posY:Number):void
		{
			currentposition.x = posX;
			currentposition.y = posY;
			
			this.x = posX;
			this.y = posY;
		}
		
	}

}