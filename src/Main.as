package 
{
	import cepa.utils.ToolTip;
	import com.adobe.serialization.json.JSON;
	import fl.transitions.easing.None;
	import fl.transitions.Tween;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.setTimeout;
	import flash.utils.Timer;
	import pipwerks.SCORM;
	
	/**
	 * ...
	 * @author Alexandre
	 */
	public class Main extends Sprite
	{
		private var tweenX:Tween;
		private var tweenY:Tween;
		
		private var tweenX2:Tween;
		private var tweenY2:Tween;
		
		private var tweenTime:Number = 0.2;
		private var conncetionsSpr:Sprite;
		private var state:String = "Parte 1:";
		private var maxTentativas:int = 3;
		private var tentativaAtual:int = 1;
		
		
		public function Main() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			this.scrollRect = new Rectangle(0, 0, 700, 600);
			
			fundoSegundaParte.visible = false;
			entrada.tentativas.text = String(tentativaAtual) + "/" + String(maxTentativas);
			
			adicionaListeners();
			addListeners();
			
			createAnswer();
			
			if (ExternalInterface.available) {
				initLMSConnection();
				if (mementoSerialized != null) {
					if(mementoSerialized != "" && mementoSerialized != "null") recoverStatus(mementoSerialized);
				}
			}
			
			verificaFinaliza();
			criaConexoes();
			stage.addEventListener(MouseEvent.MOUSE_DOWN, initDragFundo);
		}
		
		private function saveStatusForRecovery(e:MouseEvent = null):void
		{
			var status:Object = new Object();
			
			status.fase = state;
			status.tentativas = tentativaAtual;
			status.pecas = new Object();
			status.fundos = new Object();
			
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					status.pecas[child.name] = new Object();
					status.pecas[child.name].x = child.x;
					status.pecas[child.name].y = child.y;
					status.pecas[child.name].frame = Peca(child).bkg.currentFrame;
					if (Peca(child).currentFundo != null) status.pecas[child.name].currentFundo = Peca(child).currentFundo.name;
					else status.pecas[child.name].currentFundo = "null";
				}else if (child is Fundo) {
					status.fundos[child.name] = new Object();
					status.fundos[child.name].x = child.x;
					status.fundos[child.name].y = child.y;
					status.fundos[child.name].disponivel = Fundo(child).disponivel;
				}
			}
			
			mementoSerialized = JSON.encode(status);
		}
		
		private function recoverStatus(memento:String):void
		{
			var status:Object = JSON.decode(memento);
			
			state = status.fase;
			parte.text = state;
			
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					Peca(child).bkg.gotoAndStop(status.pecas[child.name].frame);
					child.x = status.pecas[child.name].x;
					child.y = status.pecas[child.name].y;
					if (status.pecas[child.name].currentFundo != "null") {
						Peca(child).currentFundo = getFundoByName(status.pecas[child.name].currentFundo);
						Fundo(Peca(child).currentFundo).currentPeca = Peca(child);
					}
				}else if (child is Fundo) {
					Fundo(child).setPosition(status.fundos[child.name].x, status.fundos[child.name].y);
					Fundo(child).disponivel = status.fundos[child.name].disponivel;
				}
			}
			
			if (state == "Parte 2:") {
				iniciaSegundaParte();
				criaConexoes();
			}
			
			tentativaAtual = status.tentativas;
			entrada.tentativas.text = String(tentativaAtual) + "/" + String(maxTentativas);
		}
		
		private var connections:Array = [
			[13, 1], [24, 1], [15, 1], [2, 1], [23, 1], [6, 1],
			[3, 2],
			[5, 4], [2, 4],
			[3, 5],
			[5, 6], [2, 6], [23, 6], [12, 6], [8, 6], [9, 6], [7, 6],
			[6, 7], [8, 7], [16, 7], [9, 7], [18, 7],
			[5, 8], [17, 8], [9, 8],
			[3, 10], [17, 10], [19, 10],
			[7, 11], [18, 11],
			[20, 12], [19, 12],
			[3, 13],
			[17,14],
			[17,15],
			[17, 16],
			[19, 18],
			[19,20],
			[10, 21], [20, 21], [22, 21],
			[3,23],
			[3,24]
		];
		
		private function criaConexoes():void 
		{
			if (conncetionsSpr == null) {
				conncetionsSpr = new Sprite();
				addChild(conncetionsSpr);
				setChildIndex(conncetionsSpr, 0);
				setChildIndex(fundoSegundaParte, 0);
			}
			
			conncetionsSpr.graphics.clear();
			
			//var fundoIni:Fundo = this["fundo" + String(connections[0][0])];
			//var fundoEnd:Fundo = this["fundo" + String(connections[0][1])];
			//makeConection(fundoIni.x, fundoIni.y, fundoEnd.x, fundoEnd.y, 0x000000);
			
			for (var i:int = 0; i < connections.length; i++) 
			{
				var fundoIni:Fundo = this["fundo" + String(connections[i][0])];
				var fundoEnd:Fundo = this["fundo" + String(connections[i][1])];
					
				if (fundoDragging != null) {
					if (fundoDragging == fundoIni || fundoDragging == fundoEnd) {
						makeConection(fundoIni.x, fundoIni.y, fundoEnd.x, fundoEnd.y, 0x000000);
					}else {
						makeConection(fundoIni.x, fundoIni.y, fundoEnd.x, fundoEnd.y, 0xC0C0C0);
					}
				}else makeConection(fundoIni.x, fundoIni.y, fundoEnd.x, fundoEnd.y, 0x000000);
			}
		}
		
		private var raioPeca:Number = 36;
		private var posAFixo:Point = new Point( -10, 3);
		private var posBFixo:Point = new Point( -10, -3);
		
		private function makeConection(xIni:Number, yIni:Number, xEnd:Number, yEnd:Number, color:uint):void
		{
			var angle:Number = Math.atan2(yEnd - yIni, xEnd - xIni);
			
			//var posA:Point = new Point(raioFlecha * Math.cos(angleFlecha + angle), raioFlecha * Math.sin(angleFlecha + angle));
			//var posB:Point = new Point(raioFlecha * Math.cos(angleFlecha - angle), raioFlecha * Math.sin(-angleFlecha - angle));
			
			var posA:Point = new Point(posAFixo.x * Math.cos(angle) - posAFixo.y * Math.sin(angle), posAFixo.x * Math.sin(angle) + posAFixo.y * Math.cos(angle));
			var posB:Point = new Point(posBFixo.x * Math.cos(angle) - posBFixo.y * Math.sin(angle), posBFixo.x * Math.sin(angle) + posBFixo.y * Math.cos(angle));
			
			var posIni:Point = new Point(xIni + Math.cos(angle) * raioPeca, yIni + Math.sin(angle) * raioPeca);
			var posEnd:Point = new Point(xEnd + Math.cos(angle + Math.PI) * (raioPeca + 4), yEnd + Math.sin(angle + Math.PI) * (raioPeca + 4));
			var posEnd2:Point = new Point(xEnd + Math.cos(angle + Math.PI) * raioPeca, yEnd + Math.sin(angle + Math.PI) * raioPeca);
			
			conncetionsSpr.graphics.beginFill(color);
			conncetionsSpr.graphics.lineStyle(2, color);
			conncetionsSpr.graphics.moveTo(posIni.x, posIni.y);
			conncetionsSpr.graphics.lineTo(posEnd.x, posEnd.y);
			conncetionsSpr.graphics.lineStyle(1, color);
			conncetionsSpr.graphics.moveTo(posEnd2.x, posEnd2.y);
			conncetionsSpr.graphics.lineTo(posEnd2.x + posB.x, posEnd2.y + posB.y);
			conncetionsSpr.graphics.lineTo(posEnd2.x + posA.x, posEnd2.y + posA.y);
			conncetionsSpr.graphics.lineTo(posEnd2.x, posEnd2.y);
			conncetionsSpr.graphics.endFill();
		}
		
		/**
		 * Adiciona os eventListeners nos botões.
		 */
		private function adicionaListeners():void 
		{
			makeButton(botoes.tutorialBtn);
			makeButton(botoes.orientacoesBtn);
			makeButton(botoes.creditos);
			makeButton(botoes.resetButton);
			
			botoes.tutorialBtn.addEventListener(MouseEvent.CLICK, iniciaTutorial);
			botoes.orientacoesBtn.addEventListener(MouseEvent.CLICK, openOrientacoes);
			botoes.creditos.addEventListener(MouseEvent.CLICK, openCreditos);
			botoes.resetButton.addEventListener(MouseEvent.CLICK, reset);
			
			createToolTips();
		}
		
		private function makeButton(btn:MovieClip):void
		{
			btn.gotoAndStop(1);
			btn.buttonMode = true;
			btn.mouseChildren = false;
			btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {MovieClip(e.target).gotoAndStop(2) } );
			btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {MovieClip(e.target).gotoAndStop(1) } );
		}
		
		/**
		 * Cria os tooltips nos botões
		 */
		private function createToolTips():void 
		{
			var intTT:ToolTip = new ToolTip(botoes.tutorialBtn, "Reiniciar tutorial", 12, 0.8, 150, 0.6, 0.1);
			var instTT:ToolTip = new ToolTip(botoes.orientacoesBtn, "Orientações", 12, 0.8, 100, 0.6, 0.1);
			var resetTT:ToolTip = new ToolTip(botoes.resetButton, "Reiniciar", 12, 0.8, 100, 0.6, 0.1);
			var infoTT:ToolTip = new ToolTip(botoes.creditos, "Créditos", 12, 0.8, 100, 0.6, 0.1);
			
			addChild(intTT);
			addChild(instTT);
			addChild(resetTT);
			addChild(infoTT);
			
		}
		
		/**
		 * Abrea a tela de orientações.
		 */
		private function openOrientacoes(e:MouseEvent):void 
		{
			orientacoesScreen.openScreen();
			setChildIndex(orientacoesScreen, numChildren - 1);
			setChildIndex(bordaAtividade, numChildren - 1);
		}
		
		/**
		 * Abre a tela de créditos.
		 */
		private function openCreditos(e:MouseEvent):void 
		{
			creditosScreen.openScreen();
			setChildIndex(creditosScreen, numChildren - 1);
			setChildIndex(bordaAtividade, numChildren - 1);
		}
		
		/**
		 * Reinicia a atividade, colocando-a no seu estado inicial.
		 */
		public function reset(e:MouseEvent = null):void 
		{
			fundoDragging = null;
			pecaDragging = null;
			
			if(state == "Parte 1:"){
				for (var i:int = 0; i < numChildren; i++)
				{
					var child:DisplayObject = getChildAt(i);
					if (child is Peca) {
						child.x = Peca(child).inicialPosition.x;
						child.y = Peca(child).inicialPosition.y;
						if (Peca(child).currentFundo != null) {
							Fundo(Peca(child).currentFundo).currentPeca = null;
						}
						Peca(child).currentFundo = null;
						Peca(child).bkg.gotoAndStop(WAITING);
						
						var fundoPeca:Fundo = getFundo(new Point(child.x, child.y));
						if (fundoPeca != null) {
							Peca(child).currentFundo = fundoPeca;
							fundoPeca.currentPeca = Peca(child);
							Peca(child).mouseEnabled = false;
							fundoPeca.disponivel = false;
							Peca(child).bkg.gotoAndStop(STATIC);
						}
					}
				}
			}else {
				for (i = 0; i < numChildren; i++)
				{
					child = getChildAt(i);
					if (child is Fundo) {
						Fundo(child).setPosition(Fundo(child).inicialPos.x, Fundo(child).inicialPos.y);
						Fundo(child).currentPeca.x = child.x;
						Fundo(child).currentPeca.y = child.y;
					}
				}
			}
			
			verificaFinaliza();
			criaConexoes();
			saveStatus();
		}
		
		private function addListeners():void 
		{
			entrada.okBtn.addEventListener(MouseEvent.CLICK, finalizaExec);
			entrada.okBtn.buttonMode = true;
		}
		
		private function finalizaExec(e:MouseEvent):void 
		{
			if(tentativaAtual <= maxTentativas){
				if (state == "Parte 1:") {
					var nCertas:int = 0;
					var nPecas:int = 0;
					
					for (var i:int = 0; i < numChildren; i++) 
					{
						var child:DisplayObject = getChildAt(i);
						if (child is Peca) {
							if(Fundo(Peca(child).currentFundo).disponivel){
								nPecas++;
								if(Peca(child).fundo.indexOf(Peca(child).currentFundo) != -1){
									nCertas++;
								}
							}
						}
					}
					
					var currentScore:int = int((nCertas / nPecas) * 100);
					//iniciaSegundaParte();
					
					if (currentScore < 99) {
						var comp:Boolean = false;
						if (tentativaAtual == maxTentativas) {
							feedbackScreen.setText("Ops!... Você precisa iniciar uma nova tentativa para refazer o exercício.");
							comp = true;
						}
						else feedbackScreen.setText("Ops!... Reveja as relações de predação. Você ainda tem " + String(maxTentativas - tentativaAtual) + " tentativa(s).");
						tentativaAtual++;
						if (tentativaAtual <= maxTentativas) {
							entrada.tentativas.text = String(tentativaAtual) + "/" + String(maxTentativas);
						}
						if(!completed){
							score = currentScore;
							completed = comp;
							saveStatus();
							commit();
						}
					}else {
						feedbackScreen.setText("Correto! Agora organize os animais em níveis tróficos (pressione \"terminei\" quando tiver concluído).");
						iniciaSegundaParte();
						if(!completed){
							score = currentScore;
							completed = false;
							saveStatus();
							commit();
						}
					}
					setChildIndex(feedbackScreen, numChildren - 1);
				}else {
					var acertosP2:int = 0;
					var nFundos:int = 0;
					
					for (i = 0; i < numChildren; i++) 
					{
						child = getChildAt(i);
						if (child is Fundo) {
							nFundos++;
							var posFundo:Point = new Point(child.x, child.y);
							if(Fundo(child).espaco.hitTestPoint(posFundo.x, posFundo.y)){
								acertosP2++;
							}
						}
					}
					
					var currentScoreP2:int = int((acertosP2 / nFundos) * 100);
					
					if (currentScoreP2 < 99) {
						var comp2:Boolean = false;
						if (tentativaAtual == maxTentativas) {
							feedbackScreen.setText("Ops!... Você precisa iniciar uma nova tentativa para refazer o exercício.");
							comp2 = true;
						}
						else feedbackScreen.setText("Ops!... Reveja os níveis tróficos. Você ainda tem " + String(maxTentativas - tentativaAtual) + " tentativa(s).");
						tentativaAtual++;
						if (tentativaAtual <= maxTentativas) {
							entrada.tentativas.text = String(tentativaAtual) + "/" + String(maxTentativas);
						}
						if (!completed) {
							completed = comp2;
							score = 50 + currentScoreP2 / 2;
							saveStatus();
							commit();
						}
					}else {
						feedbackScreen.setText("Correto!");
						if(!completed){
							completed = true;
							score = 50 + currentScoreP2 / 2;
							saveStatus();
							commit();
						}
					}
					
				}
			}else {
				feedbackScreen.setText("Número de tentativas excedidas.\nVocê precisa iniciar uma nova tentativa para refazer o exercício.");
			}
			setChildIndex(bordaAtividade, numChildren - 1);
		}
		
		private function iniciaSegundaParte():void 
		{
			state = "Parte 2:";
			parte.text = state;
			parte2.text = "Organize os animais em níveis tróficos.";
			tentativaAtual = 1;
			entrada.tentativas.text = "1/3";
			
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					//Peca(child).x = Peca(child).fundo[0].x;
					//Peca(child).y = Peca(child).fundo[0].y;
					//Peca(child).currentFundo = Peca(child).fundo[0];
					//Fundo(Peca(child).currentFundo).currentPeca = Peca(child);
					
					Fundo(Peca(child).currentFundo).disponivel = true;
					Peca(child).mouseEnabled = true;
					Peca(child).removeListeners();
					Peca(child).buttonMode = true;
					Peca(child).bkg.gotoAndStop(STATIC);
				}
			}
			
			fundoPecasStage.visible = false;
			fundoSegundaParte.visible = true;
			saveStatus();
		}
		
		private var fundoDragging:Fundo;
		private var fundoClickPos:Point = new Point();
		private var posClick:Point;
		private function initDragFundo(e:MouseEvent):void 
		{
			posClick = new Point(stage.mouseX, stage.mouseY);
			fundoDragging = getFundo(posClick, true);
			
			if(state == "Parte 2:"){
				if (fundoDragging != null) {
					stage.addEventListener(MouseEvent.MOUSE_MOVE, movingFundo);
					stage.addEventListener(MouseEvent.MOUSE_UP, stopDraggingFundo);
					
					fundoClickPos.x = fundoDragging.mouseX;
					fundoClickPos.y = fundoDragging.mouseY;
				}
			}
			criaConexoes();
		}
		
		private function movingFundo(e:MouseEvent):void 
		{
			fundoDragging.x = Math.max(fundoDragging.width / 2, Math.min(stage.stageWidth - fundoDragging.width / 2, stage.mouseX - fundoClickPos.x));
			fundoDragging.y = Math.max(fundoDragging.height / 2 , Math.min(stage.stageHeight - fundoDragging.height / 2, stage.mouseY - fundoClickPos.y));
			
			fundoDragging.currentPeca.x = fundoDragging.x;
			fundoDragging.currentPeca.y = fundoDragging.y;
			
			criaConexoes();
		}
		
		private function stopDraggingFundo(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, movingFundo);
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopDraggingFundo);
			
			fundoDragging.currentPeca.x = fundoDragging.x;
			fundoDragging.currentPeca.y = fundoDragging.y;
			
			fundoDragging.setPosition(fundoDragging.x, fundoDragging.y);
			//fundoDragging = null;
			
			criaConexoes();
			saveStatus();
		}
		
		private function verificaFinaliza():void 
		{
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					if(Peca(child).currentFundo == null){
						entrada.okBtn.mouseEnabled = false;
						entrada.okBtn.alpha = 0.5;
						return;
					}
				}
			}
			
			entrada.okBtn.mouseEnabled = true;
			entrada.okBtn.alpha = 1;
		}
		
		private function checkForFinish():Boolean
		{
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				
				if (child is Peca) {
					if (Peca(child).currentFundo == null) return false;
				}
			}
			
			return true;
		}
		
		private function createAnswer():void 
		{
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					setAnswerForPeca(Peca(child));
					var objClass:Class = Class(getDefinitionByName(getQualifiedClassName(child)));
					var ghostObj:* = new objClass();
					MovieClip(ghostObj).gotoAndStop(1);
					Peca(child).ghost = ghostObj;
					Peca(child).addListeners();
					Peca(child).inicialPosition = new Point(child.x, child.y);
					child.addEventListener("fimArraste", verifyPosition);
					child.addEventListener("inicioArraste", verifyForFilter);
					Peca(child).buttonMode = true;
					Peca(child).gotoAndStop(1);
					
					var fundoPeca:Fundo = getFundo(new Point(child.x, child.y));
					if (fundoPeca != null) {
						Peca(child).currentFundo = fundoPeca;
						fundoPeca.currentPeca = Peca(child);
						Peca(child).mouseEnabled = false;
						fundoPeca.disponivel = false;
						Peca(child).bkg.gotoAndStop(STATIC);
					}
				}else if (child is Fundo) {
					Fundo(child).setPosition(child.x, child.y);
					Fundo(child).inicialPos = new Point(child.x, child.y);
					Fundo(child).espaco = getEspacoFundo(child.name);
				}
				
			}
		}
		
		private var espacosFundo:Array = [
			["fundo1", "fundo6", "fundo7", "fundo11"],
			["fundo4", "fundo8", "fundo21"],
			["fundo9", "fundo12", "fundo22"],
			["fundo3", "fundo17", "fundo19"]
		];
		private function getEspacoFundo(fundoName:String):MovieClip 
		{
			if (espacosFundo[0].indexOf(fundoName) != -1) {
				return fundoSegundaParte.c4;
			}else if (espacosFundo[1].indexOf(fundoName) != -1) {
				return fundoSegundaParte.c3;
			}else if (espacosFundo[2].indexOf(fundoName) != -1) {
				return fundoSegundaParte.c2;
			}else if (espacosFundo[3].indexOf(fundoName) != -1) {
				return fundoSegundaParte.p;
			}else {
				return fundoSegundaParte.c1;
			}
		}
		
		private function overMc(e:MouseEvent):void
		{
			var peca:Peca = Peca(e.target);
			peca.gotoAndStop(2);
			setChildIndex(peca, numChildren - 1);
		}
		
		private function outMc(e:MouseEvent):void
		{
			var peca:Peca = Peca(e.target);
			peca.gotoAndStop(1);
		}
		
		private var pecaDragging:Peca;
		private var fundoFilter:GlowFilter = new GlowFilter(0xFF8080, 1, 20, 20, 1, 2, true, true);
		//private var fundoFilter:GlowFilter = new GlowFilter(0xFF8080);
		private var fundoWGlow:MovieClip;
		private function verifyForFilter(e:Event):void 
		{
			pecaDragging = Peca(e.target);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, verifying);
		}
		
		private function verifying(e:MouseEvent):void 
		{
			var fundoUnder:Fundo = getFundo(new Point(pecaDragging.ghost.x, pecaDragging.ghost.y));
			
			if (fundoUnder != null) {
				/*if (fundoUnder.currentPeca != null) {
					if (fundoWGlow == null) {
						fundoWGlow = fundoUnder.currentPeca;
						fundoWGlow.gotoAndStop(2);
					}else {
						if (fundoWGlow is Fundo) {
							fundoWGlow.borda.filters = [];
						}else {
							fundoWGlow.gotoAndStop(1);
						}
						fundoWGlow = fundoUnder.currentPeca;
						fundoWGlow.gotoAndStop(2);
					}
				}else{*/
					if (fundoWGlow == null) {
						fundoWGlow = fundoUnder;
						fundoWGlow.borda.filters = [fundoFilter];
					}else {
						if (fundoWGlow is Fundo) {
							fundoWGlow.borda.filters = [];
						}else {
							fundoWGlow.gotoAndStop(1);
						}
						fundoWGlow = fundoUnder;
						fundoWGlow.borda.filters = [fundoFilter];
					}
				//}
			}else {
				if (fundoWGlow != null) {
					if(fundoWGlow is Fundo){
						Fundo(fundoWGlow).borda.filters = [];
					}else {
						fundoWGlow.gotoAndStop(1);
					}
					fundoWGlow = null;
				}
			}
			
			fundoDragging = fundoUnder;
			criaConexoes();
		}
		
		private static const WAITING:int = 1;
		private static const DROPED:int = 2;
		private static const STATIC:int = 3;
		private function verifyPosition(e:Event):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, verifying);
			pecaDragging = null;
			if (fundoWGlow != null) {
				if (fundoWGlow is Fundo) fundoWGlow.borda.filters = [];
				else fundoWGlow.gotoAndStop(1);
				fundoWGlow = null;
			}
			
			var peca:Peca = e.target as Peca;
			var fundoDrop:Fundo = getFundo(peca.position);
			
			if (fundoDrop != null) {
				if (fundoDrop.currentPeca == null) {
					if (peca.currentFundo != null) {
						Fundo(peca.currentFundo).currentPeca = null;
					}
					fundoDrop.currentPeca = peca;
					peca.currentFundo = fundoDrop;
					//tweenX = new Tween(peca, "x", None.easeNone, peca.x, fundoDrop.x, 0.5, true);
					//tweenY = new Tween(peca, "y", None.easeNone, peca.y, fundoDrop.y, 0.5, true);
					peca.x = fundoDrop.x;
					peca.y = fundoDrop.y;
					peca.bkg.gotoAndStop(DROPED);
				}else {
					if(peca.currentFundo != null){
						var pecaFundo:Peca = Peca(fundoDrop.currentPeca);
						var fundoPeca:Fundo = Fundo(peca.currentFundo);
						
						tweenX = new Tween(peca, "x", None.easeNone, peca.x, fundoDrop.x, tweenTime, true);
						tweenY = new Tween(peca, "y", None.easeNone, peca.y, fundoDrop.y, tweenTime, true);
						
						tweenX2 = new Tween(pecaFundo, "x", None.easeNone, pecaFundo.x, fundoPeca.x, tweenTime, true);
						tweenY2 = new Tween(pecaFundo, "y", None.easeNone, pecaFundo.y, fundoPeca.y, tweenTime, true);
						
						peca.currentFundo = fundoDrop;
						fundoDrop.currentPeca = peca;
						
						pecaFundo.currentFundo = fundoPeca;
						fundoPeca.currentPeca = pecaFundo;
					}else {
						pecaFundo = Peca(fundoDrop.currentPeca);
						
						//tweenX = new Tween(peca, "x", None.easeNone, peca.position.x, fundoDrop.x, tweenTime, true);
						//tweenY = new Tween(peca, "y", None.easeNone, peca.position.y, fundoDrop.y, tweenTime, true);
						peca.x = fundoDrop.x;
						peca.y = fundoDrop.y;
						peca.bkg.gotoAndStop(DROPED);
						
						tweenX2 = new Tween(pecaFundo, "x", None.easeNone, pecaFundo.x, pecaFundo.inicialPosition.x, tweenTime, true);
						tweenY2 = new Tween(pecaFundo, "y", None.easeNone, pecaFundo.y, pecaFundo.inicialPosition.y, tweenTime, true);
						
						peca.currentFundo = fundoDrop;
						fundoDrop.currentPeca = peca;
						
						pecaFundo.currentFundo = null;
						pecaFundo.bkg.gotoAndStop(WAITING);
					}
				}
			}else {
				if (peca.currentFundo != null) {
					Fundo(peca.currentFundo).currentPeca = null;
					peca.currentFundo = null;
				}
				tweenX = new Tween(peca, "x", None.easeNone, peca.x, peca.inicialPosition.x, tweenTime, true);
				tweenY = new Tween(peca, "y", None.easeNone, peca.y, peca.inicialPosition.y, tweenTime, true);
				peca.bkg.gotoAndStop(WAITING);
			}
			
			verificaFinaliza();
			setTimeout(saveStatus, (tweenTime + 0.1) * 1000);
		}
		
		private function getFundo(position:Point, semDisponivel:Boolean = false):Fundo 
		{
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Fundo) {
					if (child.hitTestPoint(position.x, position.y)) {
						if (Fundo(child).disponivel) return Fundo(child);
						else if(semDisponivel) return Fundo(child);
					}
				}
			}
			return null;
		}
		
		private function getFundoByName(name:String):Fundo 
		{
			if (name == "") return null;
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Fundo) {
					if (child.name == name) return Fundo(child);
				}
			}
			return null;
		}
		
		private function setAnswerForPeca(child:Peca):void 
		{
			if (child is Peca1) {
				child.fundo = [fundo1];
				child.nome = "peca1";
			}else if (child is Peca2) {
				child.fundo = [fundo2];
				child.nome = "peca2";
			}else if (child is Peca3) {
				child.fundo = [fundo3];
				child.nome = "peca3";
			}else if (child is Peca4) {
				child.fundo = [fundo4];
				child.nome = "peca4";
			}else if (child is Peca5) {
				child.fundo = [fundo5];
				child.nome = "peca5";
			}else if (child is Peca6) {
				child.fundo = [fundo6];
				child.nome = "peca6";
			}else if (child is Peca7) {
				child.fundo = [fundo7];
				child.nome = "peca7";
			}else if (child is Peca8) {
				child.fundo = [fundo8];
				child.nome = "peca8";
			}else if (child is Peca9) {
				child.fundo = [fundo9];
				child.nome = "peca9";
			}else if (child is Peca10) {
				child.fundo = [fundo10];
				child.nome = "peca10";
			}else if (child is Peca11) {
				child.fundo = [fundo11];
				child.nome = "peca11";
			}else if (child is Peca12) {
				child.fundo = [fundo12];
				child.nome = "peca12";
			}else if (child is Peca13) {
				child.fundo = [fundo13];
				child.nome = "peca13";
			}else if (child is Peca14) {
				child.fundo = [fundo14];
				child.nome = "peca14";
			}else if (child is Peca15) {
				child.fundo = [fundo15];
				child.nome = "peca15";
			}else if (child is Peca16) {
				child.fundo = [fundo16];
				child.nome = "peca16";
			}else if (child is Peca17) {
				child.fundo = [fundo17];
				child.nome = "peca17";
			}else if (child is Peca18) {
				child.fundo = [fundo18];
				child.nome = "peca18";
			}else if (child is Peca19) {
				child.fundo = [fundo19];
				child.nome = "peca19";
			}else if (child is Peca20) {
				child.fundo = [fundo20];
				child.nome = "peca20";
			}else if (child is Peca21) {
				child.fundo = [fundo21];
				child.nome = "peca21";
			}else if (child is Peca22) {
				child.fundo = [fundo22];
				child.nome = "peca22";
			}else if (child is Peca23) {
				child.fundo = [fundo23];
				child.nome = "peca23";
			}else if (child is Peca24) {
				child.fundo = [fundo24];
				child.nome = "peca24";
			}
		}
		
		
		//---------------- Tutorial -----------------------
		
		private var balao:CaixaTexto;
		private var pointsTuto:Array;
		private var tutoBaloonPos:Array;
		private var tutoPos:int;
		private var tutoSequence:Array = ["Esta atividade interativa tem duas partes.", 
										  "Nesta primeira parte você deve arrastar os animais...",
										  "... para as caixas corretas...",
										  "... conforme descrito nas orientações.",
										  "Clique numa caixa para destacar as relações dela.",
										  "Quando você tiver concluído, pressione \"terminei\" (você tem 3 chances para acertar e prosseguir).",
										  "Esta é a parte dois. Agora você deve organizar os animais em níveis tróficos.",
										  "Pressiona \"terminei\" quando tiver concluído."];
		
		public function iniciaTutorial(e:MouseEvent = null):void 
		{
			tutoPos = 0;
			if(balao == null){
				balao = new CaixaTexto(true);
				addChild(balao);
				balao.visible = false;
				
				pointsTuto = 	[new Point(320, 440),
								new Point(230 , 130),
								new Point(650 , 500),
								new Point(230 , 130),
								new Point(650 , 500),
								new Point(230 , 130),
								new Point(650 , 500),
								new Point(650, 500)];
								
				tutoBaloonPos = [[CaixaTexto.BOTTON, CaixaTexto.CENTER],
								[CaixaTexto.BOTTON, CaixaTexto.CENTER],
								[CaixaTexto.RIGHT, CaixaTexto.FIRST],
								[CaixaTexto.BOTTON, CaixaTexto.CENTER],
								[CaixaTexto.RIGHT, CaixaTexto.FIRST],
								[CaixaTexto.BOTTON, CaixaTexto.CENTER],
								[CaixaTexto.RIGHT, CaixaTexto.FIRST],
								[CaixaTexto.TOP, CaixaTexto.CENTER]];
			}
			balao.removeEventListener(Event.CLOSE, closeBalao);
			
			balao.setText(tutoSequence[tutoPos], tutoBaloonPos[tutoPos][0], tutoBaloonPos[tutoPos][1]);
			balao.setPosition(pointsTuto[tutoPos].x, pointsTuto[tutoPos].y);
			balao.addEventListener(Event.CLOSE, closeBalao);
			balao.visible = true;
		}
		
		private function closeBalao(e:Event):void 
		{
			tutoPos++;
			if (tutoPos >= tutoSequence.length) {
				balao.removeEventListener(Event.CLOSE, closeBalao);
				balao.visible = false;
			}else {
				balao.setText(tutoSequence[tutoPos], tutoBaloonPos[tutoPos][0], tutoBaloonPos[tutoPos][1]);
				balao.setPosition(pointsTuto[tutoPos].x, pointsTuto[tutoPos].y);
			}
		}
		
		
		/*------------------------------------------------------------------------------------------------*/
		//SCORM:
		
		private const PING_INTERVAL:Number = 5 * 60 * 1000; // 5 minutos
		private var completed:Boolean;
		private var scorm:SCORM;
		private var scormExercise:int;
		private var connected:Boolean;
		private var score:int = 0;
		private var pingTimer:Timer;
		private var mementoSerialized:String = "";
		
		/**
		 * @private
		 * Inicia a conexão com o LMS.
		 */
		private function initLMSConnection () : void
		{
			completed = false;
			connected = false;
			scorm = new SCORM();
			
			pingTimer = new Timer(PING_INTERVAL);
			pingTimer.addEventListener(TimerEvent.TIMER, pingLMS);
			
			connected = scorm.connect();
			
			if (connected) {
				// Verifica se a AI já foi concluída.
				var status:String = scorm.get("cmi.completion_status");	
				mementoSerialized = scorm.get("cmi.suspend_data");
				var stringScore:String = scorm.get("cmi.score.raw");
			 
				switch(status)
				{
					// Primeiro acesso à AI
					case "not attempted":
					case "unknown":
					default:
						completed = false;
						break;
					
					// Continuando a AI...
					case "incomplete":
						completed = false;
						break;
					
					// A AI já foi completada.
					case "completed":
						completed = true;
						//setMessage("ATENÇÃO: esta Atividade Interativa já foi completada. Você pode refazê-la quantas vezes quiser, mas não valerá nota.");
						break;
				}
				
				//unmarshalObjects(mementoSerialized);
				scormExercise = 1;
				score = Number(stringScore.replace(",", "."));
				
				var success:Boolean = scorm.set("cmi.score.min", "0");
				if (success) success = scorm.set("cmi.score.max", "100");
				
				if (success)
				{
					scorm.save();
					pingTimer.start();
				}
				else
				{
					//trace("Falha ao enviar dados para o LMS.");
					connected = false;
				}
			}
			else
			{
				trace("Esta Atividade Interativa não está conectada a um LMS: seu aproveitamento nela NÃO será salvo.");
				mementoSerialized = ExternalInterface.call("getLocalStorageString");
			}
			
			//reset();
		}
		
		/**
		 * @private
		 * Salva cmi.score.raw, cmi.location e cmi.completion_status no LMS
		 */ 
		private function commit()
		{
			if (connected)
			{
				// Salva no LMS a nota do aluno.
				var success:Boolean = scorm.set("cmi.score.raw", score.toString());

				// Notifica o LMS que esta atividade foi concluída.
				success = scorm.set("cmi.completion_status", (completed ? "completed" : "incomplete"));

				// Salva no LMS o exercício que deve ser exibido quando a AI for acessada novamente.
				success = scorm.set("cmi.location", scormExercise.toString());
				
				// Salva no LMS a string que representa a situação atual da AI para ser recuperada posteriormente.
				//mementoSerialized = marshalObjects();
				success = scorm.set("cmi.suspend_data", mementoSerialized.toString());

				if (success)
				{
					scorm.save();
				}
				else
				{
					pingTimer.stop();
					//setMessage("Falha na conexão com o LMS.");
					connected = false;
				}
			}else { //LocalStorage
				ExternalInterface.call("save2LS", mementoSerialized);
			}
		}
		
		/**
		 * @private
		 * Mantém a conexão com LMS ativa, atualizando a variável cmi.session_time
		 */
		private function pingLMS (event:TimerEvent)
		{
			//scorm.get("cmi.completion_status");
			commit();
		}
		
		private function saveStatus():void
		{
			if (ExternalInterface.available) {
				saveStatusForRecovery();
				if (connected) {
					scorm.set("cmi.suspend_data", mementoSerialized);
					scorm.save();
				}else {//LocalStorage
					ExternalInterface.call("save2LS", mementoSerialized);
				}
			}
		}
		
	}

}