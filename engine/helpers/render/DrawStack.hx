package engine.helpers.render;
import engine.base.RueObject;
import engine.helpers.collections.DrawNode;
import engine.helpers.TileSheetEntry;
import engine.systems.TileRenderSystem;
import engine.World;
import flash.display.Graphics;
import flash.display.Sprite;
import openfl.display.Tilesheet;

/**
 * ...
 * @author Jakegr
 */

class DrawStack extends RueObject
{
	public static var Layers:DrawStackList = DrawStackList.Create();
	
	static var Head:DrawStack;
	var Next:DrawStack;
	var Self:DrawStack;
	
	var TheSheet:TileSheetEntry;
	public var Target:Sprite;
	var Owner:Sprite;
	
	var _InnerLayers:Array<DrawNodeCountPair>;
	
	static var ElementNumber:Int = 4;
	var TheLayer:Int;
	
	public var _RenderOnce:Bool;
	public var _AllowedToRender:Bool;
	
	public var _CameraPullX:Float; //used for when the render target follows the camera, usually defaulted at 0
	public var _CameraPullY:Float;
	
	var _CameraX:Float;
	var _CameraY:Float;
	
	var _CurrentX:Float; //the current position X and Y of the render target. for internal use only.
	var _CurrentY:Float;
	
	var _PositionChanged:Bool;
	
	private function new() 
	{
		super();
		Self = this;
	}

	// The tile sheet that contains the bitmap data
	// The target sprite where to render the data
	// The global layer on which we will be adding our child target
	// The scale X
	// The scale Y
	public static function Create(TileSheet:TileSheetEntry, Owner:Sprite, Layer:Int = 0, ScaleX:Float = 1, ScaleY:Float = 1, Alpha:Float = 1.0, RenderOnce:Bool = false ):DrawStack
	{
		var Vessel:DrawStack;
		if(Head != null) { Vessel = Head; Head = Head.Next; }
		else { Vessel = new DrawStack(); }

		Vessel.TheSheet = TileSheet;
		Vessel.Target = new Sprite();
		Vessel.Target.scaleX = ScaleX;
		Vessel.Target.scaleY = ScaleY;
		Vessel.Target.alpha = Alpha;
		Vessel.TheLayer = Layer;
		
		Vessel._RenderOnce = RenderOnce;
		Vessel._AllowedToRender = true;
		
		Vessel._PositionChanged = false;
		
		Vessel._CameraX = 0;
		Vessel._CameraY = 0;
		
		Vessel._CameraPullX = 0;
		Vessel._CameraPullY = 0;
		
		Vessel._CurrentX = 0;
		Vessel._CurrentY = 0;
		
		Vessel._InnerLayers = new Array<DrawNodeCountPair>();
		for (i in 0...Layer)
		{
			Vessel._InnerLayers[i] = DrawNodeCountPair.Create();
		}
		
		Vessel.Owner = Owner;
		Owner.addChild(Vessel.Target);

		Layers.Add(Vessel);//automatically adds itself to the rendering
		return Vessel;
	}
	
	public function SetCameraPullXY(X:Float, Y:Float):Void
	{
		_CameraPullX = X;
		_CameraPullY = Y;
		SetCameraXY(TileRenderSystem.CameraX, TileRenderSystem.CameraY);
	}
	
	public function SetCameraXY(X:Float, Y:Float):Void
	{
		if (_CameraPullX != 0)
		{
			_CameraX = _CameraPullX * X;
			_PositionChanged = true;
		}
		if (_CameraPullY != 0)
		{
			_CameraY = _CameraPullY * Y;
			_PositionChanged = true;
		}
	}
	
	public function SetScale(X:Float, Y:Float):Void
	{
		Target.scaleX = X;
		Target.scaleY = Y;
	}
	
	//hard coded value for position
	public function SetRenderTargetXY(X:Float, Y:Float):Void
	{
		if (X != _CurrentX) 
		{
			_PositionChanged = true;
			_CurrentX = X;
		}
		if (Y != _CurrentY)
		{
			_PositionChanged = true;
			_CurrentY = Y;
		}
	}
	
	public function SetRenderTargetAlpha(Alpha:Float):Void
	{
		Target.alpha = Alpha;
	}
	
	override public function Recycle():Void
	{
		Target = null;
		
		for (i in 0..._InnerLayers.length)
		{
			_InnerLayers[i].Recycle();
		}
		
		_InnerLayers = null;
		
		Next = Head;
		Head = Self;
		Owner.removeChild(Target);
		super.Recycle();
	}
	
	public function AddToRender(Layer:Int, UniqueID:Int, X:Float, Y:Float, Rotation:Float):Void
	{
		var LayerToAdd:DrawNodeCountPair = _InnerLayers[Layer];
		var Offset:FloatTupe = TheSheet.Offsets[UniqueID];
		var NewNode:DrawNode = DrawNode.Create(X - Offset.ValueOne, Y - Offset.ValueTwo, UniqueID, Rotation);
		LayerToAdd.Add(NewNode);
	}
	
	public function RenderAll():Void
	{
		if (_PositionChanged)
		{
			_PositionChanged = false;
			Target.x = _CurrentX - _CameraX;
			Target.y = _CurrentY - _CameraY;
		}
		
		if (!_AllowedToRender) { return; }
		Target.graphics.clear();
		
		
		
		var CurrentCount:Int = 0;
		var TileStack:Array<Float> = new Array<Float>();
		for (i in 0..._InnerLayers.length)
		{
			var Current:DrawNodeCountPair = _InnerLayers[i];
			CurrentCount += Current._Count*ElementNumber;
			var CountDown:Int = CurrentCount;
			var StackHead:DrawNode = Current._DrawHeadNode;
			while (StackHead != null)
			{
				TileStack[--CountDown] = -StackHead.Rotation;
				TileStack[--CountDown] = StackHead.Frame;
				TileStack[--CountDown] = StackHead.PositionY;
				TileStack[--CountDown] = StackHead.PositionX;
				StackHead.Recycle();
				StackHead = StackHead.NextNode;
			}
			Current.Flush();
		}
		
		TheSheet.TheSheet.drawTiles(Target.graphics, TileStack, true, Tilesheet.TILE_ROTATION);
		if (_RenderOnce)
		{
			_AllowedToRender = false;
		}
	}
	

		
	
}