unit u_sprite_def;

{$mode ObjFPC}{$H+}

//{$define DEBUG_SHOW_STATE}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmaptypes,
  u_sprite_basepacman, u_sprite_baseghost,
  u_sprite_basehighscore, u_panel_basepause, u_panel_basemain,
  u_panel_baseoptions, u_panel_basepresskey;

type

{ TMaze }

TMaze = class(TTileEngine)
private type
  TSuperDot = record   // used to blink the cell that contain super dot
    Row, Col: integer;
    WasEaten: boolean;
  end;
private
  FSuperDots: array[0..3] of TSuperDot;
  FSuperDotBlinkDuration: single;
  FSuperDotBlinkEnabled, FSuperDotState: boolean;
  procedure UpdateSuperDots;
public
  constructor Create;
  procedure Update(const aElapsedtime: single); override;

  procedure StartBlinkSuperDots;
  procedure StopBlinkSuperDots;

  procedure RemoveDotFromMap(aRow, aCol: integer);
  procedure RemoveSuperDotFromMap(aRow, aCol: integer);
end;

var
  FMaze: TMaze;

type

TDirection = (dUnknown, dLeft, dRight, dUp, dDown);

TPacmanState = (psUnknown,
                psWaitingBeginOfGame,
                psRunning,
                psStopOnWall,
                psPlayingLoseAnimation,
                psStoppedForEndOfGame);

// Every time Pac-Man eats a regular dot, he stops moving for one frame (1/60th of a second)
// Eating an energizer dot causes Pac-Man to stop moving for three frames
{ TPacMan }

TPacMan = class(TBasePacMan)
  FState: TPacmanState;
{$ifdef DEBUG_SHOW_STATE}  debug: TFreeText;  {$endif}
private
  FDirection: TDirection;
  FTurning: boolean;
  FTargetCellToTurn: TPoint;
  FSkipFrameCount: integer;
  procedure SetState(AValue: TPacmanState);
  procedure SetStartPosition;
  procedure SetDirection(AValue: TDirection);
  procedure SetPacmanSpeed;
private // position utils
  procedure CenterOnTile(aRowIndex, aColIndex: integer);
private // check move utils
  function DirectionToCellOffset: TPoint;
  procedure PlacePacmanOnTheCenterOfItsCell;
  function ThereIsAWallAtPos(aPt: TPointF): boolean;
  function GetCellCenterUnderPacman: TPoint;
  procedure CheckGroundtypeOnCurrentPos;
  function GetGroundtypeOneStepForward: integer;
  function CanGoForward: boolean;
  function CanTurn(aOffsetDirection: TPoint): boolean;
public
  constructor Create(aLayerIndex: integer=-1);
  procedure Update(const aElapsedtime: single); override;

  procedure GoLeft;
  procedure GoRight;
  procedure GoUp;
  procedure GoDown;

  procedure EnterFrightMode;
  procedure ExitFrightMode;

  procedure StartEatAnim;
  procedure StopEatAnim;

  property State: TPacmanState read FState write SetState;
  property Direction: TDirection read FDirection write SetDirection;
end;



{ TGhostHouseManager }
// class to compute when a ghost can leave its house
TGhostHouseManager = class
private
  class var FTimer: single;
  var FGlobalDotCounter: integer;
  FGlobalCounterEnabled : boolean;
  FPinkyDotCounter, FInkyDotCounter, FClideDotCounter: integer;
  function GetTimerDuration: single;
  procedure CheckDotCounter;
public
  procedure CallWhenLifeIsLost;
  procedure IncrementDotEatenByPacman;
  procedure Update(const aElapsedTime: single);
end;

TPossible = record
  Direction: TDirection;
  Distance: single;
end;

TArrayOfPossible = array of TPossible;

TGhostState = (ghsUnknown,
               ghsWaitingBeginOfGame,
               ghsInHome,
               ghsExitingHome,
               ghsScatterMode,
               ghsChaseMode,
               ghsRetreatToHome,
               ghsStoppedForEndOfGame);

{ TGhost }
// Ghosts alternate between scatter and chase modes 4 time during gameplay at predetermined intervals
// the last chase mode is infinite
TGhost = class(TBaseGhost)
private
{$ifdef DEBUG_SHOW_STATE}  debug: TFreeText; {$endif}
private
  FGhostColor, FGhostColorFright,
  FGhostColorFrightFlashBody, FGhostColorFrightFlashMouth: TBGRAPixel;
  FWasEaten: boolean;
  FStateBeforeEaten : TGhostState;
  FScatterChaseCounter: integer;
  FScatterDuration: single;
  FChaseDuration: single;
  FElroyLevel: integer;
  FDirection: TDirection;
  FPreviousGhostMapPos: TPoint;
  FIsInTunnel: boolean;
  FState: TGhostState;
  procedure SetState(AValue: TGhostState);
private // position utils
  procedure CenterOnTile(aRowIndex, aColIndex: integer);
  procedure CenterToTileRightSide(aRowIndex, aColIndex: integer);
  procedure SpriteLeftSideOnTileLeftSide(aRowIndex, aColIndex: integer);
  procedure PlaceGhostOnTheCenterOfItsCell;
  function CanGoOnCell(aCell: TPoint): boolean;
  function GhostIsInSpecialArea: boolean;
  function CanTurn(aOffset: TPoint): boolean;
  function GetPossibleTurn: TArrayOfPossible;
  function GetPossibleTurnWithDistance(atargetMapPos: TPoint; out aIndexWithMinDistance: integer): TArrayOfPossible;
  procedure ComputeNextDirection(aTargetMapPos: TPoint);
  procedure ComputeMoveInFrightMode;
  function GetHouseRetreatMapPosition: TPoint; virtual; abstract;
  procedure SetPositionAndDirectionAtBeginning; virtual; abstract;
  function GetScatterCornerTargetMapCell: TPoint; virtual; abstract;
  function GetChaseTargetMapPosition: TPoint; virtual; abstract;
  function GetDotsLimitToLeaveHouse: integer; virtual; abstract;
  procedure SetGhostSpeed;
public
  procedure UpdateVisual;
public
  constructor Create(aGhostColor: TBGRAPixel; aLayerIndex: integer=-1);
  procedure Update(const aElapsedtime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;

  procedure StartDressAnimation;
  procedure StopDressAnimation;

  function CanKillPacman: boolean;
  function CanBeEaten: boolean;
  procedure RestoreStateAfterExitingHouse;
  procedure ReverseDirection;
  procedure EnterFrightMode;
  procedure ExitFrightMode;
  // show the bonus label 200 400 800 1600
  procedure ShowGhostEatenBonus(aBonus: integer);

  property State: TGhostState read FState write SetState;
  property Direction: TDirection read FDirection write FDirection;

public // intersession utils
  procedure SetNormalMode;
  procedure SetFrightMode;
  procedure SetDressRepeared;
  procedure SetCoor(aX, aY: single);
  procedure SetYValue(AValue: single);
  function BodyWidth: integer;
  function BodyHeight: integer;
  function BodyBottomY: single;
  function BodyLeft: single;
  function BodyRight: single;
  function DressRight: single;
end;

// alternate scatter/chase mode while no Elroy. When Elroy level is > 0,
//  blinky disable the scatter mode and stay in chase mode.

{ TBlinky }

TBlinky = class(TGhost)  // red
private
  function GetHouseRetreatMapPosition: TPoint; override;
  procedure SetPositionAndDirectionAtBeginning; override;
  function GetScatterCornerTargetMapCell: TPoint; override;
  function GetChaseTargetMapPosition: TPoint; override;
  function GetDotsLimitToLeaveHouse: integer; override;
public
  constructor Create(aLayerIndex: integer=-1);
end;

{ TPinky }

TPinky = class(TGhost)  // pink
private
  function GetHouseRetreatMapPosition: TPoint; override;
  procedure SetPositionAndDirectionAtBeginning; override;
  function GetScatterCornerTargetMapCell: TPoint; override;
  function GetChaseTargetMapPosition: TPoint; override;
  function GetDotsLimitToLeaveHouse: integer; override;
public
  constructor Create(aLayerIndex: integer=-1);
end;

{ TInky }

TInky = class(TGhost)  // blue
private
  function GetHouseRetreatMapPosition: TPoint; override;
  procedure SetPositionAndDirectionAtBeginning; override;
  function GetScatterCornerTargetMapCell: TPoint; override;
  function GetChaseTargetMapPosition: TPoint; override;
  function GetDotsLimitToLeaveHouse: integer; override;
public
  constructor Create(aLayerIndex: integer=-1);
end;


{ TClide }

TClide = class(TGhost)  // orange
private
  function GetHouseRetreatMapPosition: TPoint; override;
  procedure SetPositionAndDirectionAtBeginning; override;
  function GetScatterCornerTargetMapCell: TPoint; override;
  function GetChaseTargetMapPosition: TPoint; override;
  function GetDotsLimitToLeaveHouse: integer; override;
public
  constructor Create(aLayerIndex: integer=-1);
end;


function GetCurrentMapPosition(aSurface: TSimpleSurfaceWithEffect): TPoint;
function GetGroundTypeAt(aMapPos: TPoint): integer;
function IsNearTileCenter(aSpriteCenter, aMapPos: TPoint; aSpriteDirection: TDirection): boolean;

type
THighScore = class(TBaseHighScore)
  constructor Create(aLayerIndex: integer=-1);
  procedure SetValue(aValue: integer);
end;


TFruits = class(TSpriteContainer)
private
  var FIcons: array[0..7] of TSprite;
public
  constructor Create(aLayerIndex: integer);
  procedure UpdateIcons;
end;


{ TFruitInMaze }

TFruitInMaze = class(TSpriteContainer)
private
  FFruit: TSprite;
  FCount: integer;
  procedure CreateFruit;
public
  constructor Create;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure KillFruit;
  procedure ShowBonus;
  property Fruit: TSprite read FFruit;
end;


TLives = class(TSpriteContainer)
private
  class var texLife: PTexture;
  procedure UpdateIcons;
public
  class procedure LoadTexture(aAtlas: TAtlas);
  constructor Create(aLayerIndex: integer);
  procedure Update(const aElapsedTime: single); override;
end;


{ TPanelPause }

TPanelPause = class(TPanelBasePause)
private
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
public
  constructor Create;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Show; reintroduce;
end;


{ TPanelMainMenu }

TPanelMainMenu = class(TPanelBaseMain)
private
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
public
  constructor Create;
end;


{ TPanelOptions }

TPanelOptions = class(TPanelBaseOptions)
private
  FButtonEdited: TUIButton;
  procedure UpdateTextDifficulty;
  procedure UpdateKeyNames;
  procedure UpdateHighscoreLabel;
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
  procedure ProcessPressAKeyDone(aKey: word);
public
  constructor Create;
end;


{ TPanelPressAKey }

TPanelPressAKey = class(TPanelBasePressKey)
private
  FCounter: single;
  FScanKey: boolean;
  FParentOptionPanel: TPanelOptions;
public
  constructor Create(aParentOptionPanel: TPanelOptions);
  procedure Update(const aElapsedTime: single); override;
end;

implementation

uses u_common, u_game_manager, screen_game, u_audio, form_main, screen_mainmenu,
  screen_intermission, Math;

function GetCurrentMapPosition(aSurface: TSimpleSurfaceWithEffect): TPoint;
var p: TPoint;
begin
  p := aSurface.Center.Round;
  Result.x := EnsureRange(p.x div FTileSize.cx, 0, FMaze.MapTileCount.cx-1);
  Result.y := EnsureRange(p.y div FTileSize.cy, 0, FMaze.MapTileCount.cy-1);
end;

function GetGroundTypeAt(aMapPos: TPoint): integer;
var til: PTile;
begin
  til := FMaze.GetPTile(aMapPos.y, aMapPos.x);
  if til = NIL then Result := -1
    else Result := FMaze.GetGroundType(til^.TextureIndex, til^.ixFrame, til^.iyFrame);
end;

function IsNearTileCenter(aSpriteCenter, aMapPos: TPoint; aSpriteDirection: TDirection): boolean;
var cellCenter, margin: TPoint;
begin
  cellCenter.x := aMapPos.x * FTileSize.cx + FHalfTileSize.cx;
  cellCenter.y := aMapPos.y * FTileSize.cy + FHalfTileSize.cy;
  margin.x := FTileSize.cx  div 10;
  margin.y := FTileSize.cy  div 10;

  case aSpriteDirection of
    dLeft: Result := aSpriteCenter.x <= cellCenter.x + margin.x;
    dRight: Result := aSpriteCenter.x >= cellCenter.x - margin.x;
    dUp: Result := aSpriteCenter.y <= cellCenter.y + margin.y;
    dDown: Result := aSpriteCenter.y >= cellCenter.y - margin.y;
    else Result := True;
  end;
end;

{ TMaze }

procedure TMaze.UpdateSuperDots;
var i: integer;
  procedure ClearCell(aRow, aCol: integer);
  var til: PTile;
  begin
    til := GetPTile(aRow, aCol);
    if til <> NIL then
      SetCell(aRow, aCol, til^.TextureIndex, 3, 2);
  end;
  procedure FillCellWithSuperDotNotVisible(aRow, aCol: integer);
  var til: PTile;
  begin
    til := GetPTile(aRow, aCol);
    if til <> NIL then
      SetCell(aRow, aCol, til^.TextureIndex, 6, 2);
  end;
  procedure FillCellWithSuperDotVisible(aRow, aCol: integer);
  var til: PTile;
  begin
    til := GetPTile(aRow, aCol);
    if til <> NIL then
      SetCell(aRow, aCol, til^.TextureIndex, 4, 2);
  end;
begin
  for i:=0 to High(FSuperDots) do
    if FSuperDots[i].WasEaten then ClearCell(FSuperDots[i].Row, FSuperDots[i].Col)
    else
    if not FSuperDotState then FillCellWithSuperDotNotVisible(FSuperDots[i].Row, FSuperDots[i].Col)
      else FillCellWithSuperDotVisible(FSuperDots[i].Row, FSuperDots[i].Col);
end;

constructor TMaze.Create;
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_MAZE);
  LoadMapFile(DataFolder+'Main_Map.map', texMazeTileSet);
  SetTileSize(FTileSize.cx, FTileSize.cy);
  SetCoordinate(0, FTileSize.cy*2);
  PositionOnMap.Value := PointF(0, 0);
  SetViewSize(FTileSize.cx*MAZE_H_TILE_COUNT, FTileSize.cy*MAZE_V_TILE_COUNT);

  // init super dots
  FSuperDots[0].Col := 1;
  FSuperDots[0].Row := 3;
  FSuperDots[0].WasEaten := False;
  FSuperDots[1].Col := 26;
  FSuperDots[1].Row := 3;
  FSuperDots[1].WasEaten := False;
  FSuperDots[2].Col := 26;
  FSuperDots[2].Row := 23;
  FSuperDots[2].WasEaten := False;
  FSuperDots[3].Col := 1;
  FSuperDots[3].Row := 23;
  FSuperDots[3].WasEaten := False;
end;

procedure TMaze.Update(const aElapsedtime: single);
begin
  inherited Update(aElapsedtime);

  if not FSuperDotBlinkEnabled then exit;

  FSuperDotBlinkDuration := FSuperDotBlinkDuration - aElapsedtime;
  if FSuperDotBlinkDuration <= 0.0 then begin
    FSuperDotBlinkDuration := 0.25;
    FSuperDotState := not FSuperDotState;
    UpdateSuperDots;
  end;
end;

procedure TMaze.StartBlinkSuperDots;
begin
  FSuperDotBlinkDuration := 0.25;
  FSuperDotBlinkEnabled := True;
end;

procedure TMaze.StopBlinkSuperDots;
begin
  FSuperDotBlinkEnabled := False;
  FSuperDotState := True;
  UpdateSuperDots;
end;

procedure TMaze.RemoveDotFromMap(aRow, aCol: integer);
var til: PTile;
begin
  til := GetPTile(aRow, aCol);
  if til = NIL then exit;
  FMaze.SetCell(aRow, aCol, til^.TextureIndex, 3, 2);
end;

procedure TMaze.RemoveSuperDotFromMap(aRow, aCol: integer);
var i: integer;
begin
  RemoveDotFromMap(aRow, aCol);

  for i:=0 to High(FSuperDots) do
    if (FSuperDots[i].Row = aRow) and (FSuperDots[i].Col = aCol) then
      FSuperDots[i].WasEaten := True;
end;

{ TPacMan }

procedure TPacMan.SetState(AValue: TPacmanState);
begin
  if FState = AValue then Exit;
  FState := AValue;
  case FState of
    psWaitingBeginOfGame: begin
      Frame := 1;
      FlipH := True;
      Speed.Value := PointF(0, 0);
      FTurning := False;
      Direction := dleft;
      SetStartPosition;
      Visible := False;
    end;

    psRunning: begin
      SetPacmanSpeed;
      StartEatAnim;
    end;

    psStopOnWall: begin
      Speed.Value := PointF(0, 0);
      //PlacePacmanOnTheCenterOfItsCell;
      StopEatAnim;
    end;

    psStoppedForEndOfGame: begin
      Speed.Value := PointF(0, 0);
      Frame := 1;
    end;

    psPlayingLoseAnimation: begin
      Speed.Value := PointF(0, 0);
    end;
  end;
end;

procedure TPacMan.SetStartPosition;
begin
  SetCenterCoordinate(FTileSize.cx*14, FTileSize.cy*23.5);
end;

function TPacMan.DirectionToCellOffset: TPoint;
begin
  case Direction of
    dLeft: Result := Point(-1, 0);
    dRight: Result := Point(1, 0);
    dUp: Result := Point(0, -1);
    dDown: Result := Point(0, 1);
    else Result := Point(0, 0);
  end;
end;

procedure TPacMan.SetDirection(AValue: TDirection);
begin
  FDirection := AValue;
  case AValue Of
    dLeft: begin
      Angle.Value := 0;
      FlipH := True;
      SetPacmanSpeed;
    end;
    dRight: begin
      Angle.Value := 0;
      FlipH := False;
      SetPacmanSpeed;
    end;
    dUp: begin
      Angle.Value := -90;
      FlipH := False;
      SetPacmanSpeed;
    end;
    dDown: begin
      Angle.Value := 90;
      FlipH := False;
      SetPacmanSpeed;
    end;
  end;
end;

procedure TPacMan.PlacePacmanOnTheCenterOfItsCell;
var
  mapPos: TPoint;
begin
  mapPos := GetCurrentMapPosition(Self);
  CenterX := (mapPos.x+0.5) * FTileSize.cx;
  CenterY := (mapPos.y+0.5) * FTileSize.cy;
end;

function TPacMan.ThereIsAWallAtPos(aPt: TPointF): boolean;
var mapPos: TPoint;
  groundType: integer;
begin
  mapPos.x := EnsureRange(Round(aPt.x) div FTileSize.cx, 0, FMaze.MapTileCount.cx-1);
  mapPos.y := EnsureRange(Round(aPt.y) div FTileSize.cy, 0, FMaze.MapTileCount.cy-1);
  groundType := GetGroundTypeAt(mapPos);

  Result := groundType in [GROUND_WALL, GROUND_DOOR];
end;

function TPacMan.GetCellCenterUnderPacman: TPoint;
var mapPos: TPoint;
begin
  mapPos := GetCurrentMapPosition(Self);
  Result.x := mapPos.x * FTileSize.cx + FHalfTileSize.cx;
  Result.y := mapPos.y * FTileSize.cy + FHalfTileSize.cy;
end;

procedure TPacMan.CheckGroundtypeOnCurrentPos;
var mapPos: TPoint;
begin
  mapPos := GetCurrentMapPosition(Self);

  case GetGroundTypeAt(mapPos) of
    GROUND_DOT: begin
      // play sound eat
      Audio.PlaySoundChomp;
      // inc score + 10
      ScreenGame.IncrementScore(10);
      ScreenGame.GhostHouseManager.IncrementDotEatenByPacman;

      GameManager.DotEaten := GameManager.DotEaten + 1;
      // remove the dot from map
      FMaze.RemoveDotFromMap(mapPos.y, mapPos.x);
      // skip one frame
      FSkipFrameCount := 1;
    end;

    GROUND_SUPERDOT: begin
      FrightManager.EnterFrightMode;
      // inc score + 50
      ScreenGame.IncrementScore(50);
      GameManager.DotEaten := GameManager.DotEaten + 1;
      ScreenGame.GhostHouseManager.IncrementDotEatenByPacman;
      // remove the super dot from map
      FMaze.RemoveSuperDotFromMap(mapPos.y, mapPos.x);
    end;
  end;
end;

function TPacMan.GetGroundtypeOneStepForward: integer;
begin
  Result := GetGroundTypeAt(GetCurrentMapPosition(Self) + DirectionToCellOffset);
end;

function TPacMan.CanGoForward: boolean;
var p, mapPos: TPoint;
  groundType: Integer;
begin
  // look one half tile forward
  p := Center.Round;
  case Direction of
     dLeft: p.x := p.x - FHalfTileSize.cx;
    dRight: p.x := p.x + FHalfTileSize.cx;
       dUp: p.y := p.y - FHalfTileSize.cy;
     dDown: p.y := p.y + FHalfTileSize.cy;
  end;
  mapPos.x := EnsureRange(p.x div FTileSize.cx, 0, FMaze.MapTileCount.cx-1);
  mapPos.y := EnsureRange(p.y div FTileSize.cy, 0, FMaze.MapTileCount.cy-1);

  groundType := GetGroundTypeAt(mapPos);
  if groundType = -1 then exit(False);

  Result := not (groundType in [GROUND_WALL, GROUND_DOOR]);
end;

function TPacMan.CanTurn(aOffsetDirection: TPoint): boolean;
var groundType: Integer;
begin
  groundType := GetGroundTypeAt(GetCurrentMapPosition(Self) + aOffsetDirection);
  Result := groundType in [GROUND_HOLE, GROUND_NEUTRAL, GROUND_DOT, GROUND_SUPERDOT];
end;

procedure TPacMan.SetPacmanSpeed;
var sp: single;
begin
  if FrightManager.Enabled then sp := GameManager.GetFrightPacmanSpeedValue
    else if State = psRunning then sp := GameManager.GetPacmanSpeedValue
      else sp := 0;

  case Direction of
    dLeft: Speed.Value := PointF(-sp, 0);
    dRight: Speed.Value := PointF(sp, 0);
    dUp: Speed.Value := PointF(0, -sp);
    dDown: Speed.Value := PointF(0, sp);
  end;
end;

procedure TPacMan.StartEatAnim;
begin
  SetFrameLoopBounds(1, 3);
  FrameAddPerSecond(18);
end;

procedure TPacMan.StopEatAnim;
begin
  Frame := 2;
  FrameAddPerSecond(0);
end;

procedure TPacMan.CenterOnTile(aRowIndex, aColIndex: integer);
begin
  SetCenterCoordinate(FTileSize.cx*aColIndex+FHalfTileSize.cx, FTileSize.cy*aRowIndex+FHalfTileSize.cy);
end;

constructor TPacMan.Create(aLayerIndex: integer);
begin
  inherited Create(aLayerIndex);
  if aLayerIndex = -1 then SetChildOf(FMaze, 0);
  Frame := 1;

  {$ifdef DEBUG_SHOW_STATE}
  debug := TFreeText.Create(Fscene);
  debug.SetChildOf(Self, 0);
  debug.Y.Value := Height;
  debug.TexturedFont := texturedfontBonus;
  {$endif}
end;

procedure TPacMan.Update(const aElapsedtime: single);
var p: TPoint;
  {$ifdef DEBUG_SHOW_STATE}s1:string;{$endif}
begin
  // skip frame
  if FSkipFrameCount > 0 then begin
    dec(FSkipFrameCount);
    exit;
  end;

  if State = psStoppedForEndOfGame then exit;

  inherited Update(aElapsedtime);

  if Freeze or (State = psUnknown) then exit;

  // check if pacman pass in the tunnel
  p := GetCurrentMapPosition(Self);
  p.x := round(CenterX);
  if p.y = 14 then begin
    if CenterX > FTileSize.cx*(MAZE_H_TILE_COUNT+2) then CenterX := -FTileSize.cx*1
      else if CenterX < -FTileSize.cx*2 then CenterX := FTileSize.cx*(MAZE_H_TILE_COUNT+2);
  end;

  // turn is done in diagonal on half tile to accelerate pacman during turn as in original game
  if FTurning then begin
    p.x := FTargetCellToTurn.x * FTileSize.cx + FHalfTileSize.cx;
    p.y := FTargetCellToTurn.y * FTileSize.cy + FHalfTileSize.cy;
    case Direction of
      dLeft, dRight: begin
        if CenterY < p.y then
          CenterY := Min(CenterY + Abs(Speed.x.Value)*aElapsedtime, p.y)
        else
        if CenterY > p.y then
          CenterY := Max(CenterY - Abs(Speed.x.Value)*aElapsedtime, p.y);
        FTurning := CenterY <> p.y;
      end;
      dUp, dDown: begin
        if CenterX < p.x then
          CenterX := Min(CenterX + Abs(Speed.y.Value)*aElapsedtime, p.x)
        else
        if CenterX > p.x then
          CenterX := Max(CenterX - Abs(Speed.y.Value)*aElapsedtime, p.x);
        FTurning := CenterX <> p.x;
      end;
    end;
    CheckGroundtypeOnCurrentPos;
  end else begin
    // check if pacman is over a dot or a super dot
    CheckGroundtypeOnCurrentPos;

    // check collision with wall
    if IsNearTileCenter(Center.Round, GetCurrentMapPosition(Self), Direction) then begin
      if not CanGoForward then begin
        State := psStopOnWall;
      end;
    end;
  end;

  //p := GetCurrentMapPosition;
  p := Center.Round;
  p.x := p.x div FTileSize.cx;
  p.y := p.y div FTileSize.cy;

  {$ifdef DEBUG_SHOW_STATE}
  WriteStr(s1, Direction);
  debug.caption := //s+lineending+
                   //GroundtypeToString(GetGroundtypeOneStepForward)+lineending+
                   //p.x.ToString+','+p.y.ToString+LineEnding+
                   //FormatFloat('0.0', CenterX)+','+FormatFloat('0.0', CenterY)+lineending+
                   s1;
  {$endif}
end;

procedure TPacMan.GoLeft;
begin
  if not (State in [psRunning, psStopOnWall]) then exit;
  if Direction = dLeft then exit;
  if not IsNearTileCenter(Center.Round, GetCurrentMapPosition(Self), Direction) and
    (Direction <> dUnknown) then exit;

  if CanTurn(Point(-1,0)) then begin
    Direction := dLeft;
    State := psRunning;
    StartEatAnim;
    FTurning := True;
    FTargetCellToTurn := GetCurrentMapPosition(Self) + Point(-1,0);
  end;
end;

procedure TPacMan.GoRight;
begin
  if not (State in [psRunning, psStopOnWall]) then exit;
  if Direction = dRight then exit;
  if not IsNearTileCenter(Center.Round, GetCurrentMapPosition(Self), Direction) and
    (Direction <> dUnknown) then exit;

  if CanTurn(Point(1,0)) then begin
    Direction := dRight;
    State := psRunning;
    StartEatAnim;
    FTurning := True;
    FTargetCellToTurn := GetCurrentMapPosition(Self) + Point(1,0);
  end;
end;

procedure TPacMan.GoUp;
begin
  if not (State in [psRunning, psStopOnWall]) then exit;
  if Direction = dUp then exit;
  if not IsNearTileCenter(Center.Round, GetCurrentMapPosition(Self), Direction) and
    (Direction <> dUnknown) then exit;

  if CanTurn(Point(0,-1)) then begin
    Direction := dUp;
    State := psRunning;
    StartEatAnim;
    FTurning := True;
    FTargetCellToTurn := GetCurrentMapPosition(Self) + Point(0,-1);
  end;
end;

procedure TPacMan.GoDown;
begin
  if not (State in [psRunning, psStopOnWall]) then exit;
  if Direction = dDown then exit;
  if not IsNearTileCenter(Center.Round, GetCurrentMapPosition(Self), Direction) and
    (Direction <> dUnknown) then exit;

  if CanTurn(Point(0, 1)) then begin
    Direction := dDown;
    State := psRunning;
    StartEatAnim;
    FTurning := True;
    FTargetCellToTurn := GetCurrentMapPosition(Self) + Point(0,1);
  end;
end;

procedure TPacMan.EnterFrightMode;
begin
  if State = psRunning then
    SetPacmanSpeed;
end;

procedure TPacMan.ExitFrightMode;
begin
  if State = psRunning then
    SetPacmanSpeed;
end;

{ TGhost }

procedure TGhost.SetState(AValue: TGhostState);
begin
  if FState = AValue then Exit;

  if AValue = ghsRetreatToHome then
    FStateBeforeEaten := State;

  FState := AValue;

  case AValue of
    ghsWaitingBeginOfGame: begin
      SetPositionAndDirectionAtBeginning;
      UpdateVisual;
      Frame := 1;
      FPreviousGhostMapPos := Point(-1,-1);
      FIsInTunnel := False;
      Speed.Value := PointF(0, 0);
    end;

    ghsInHome: begin
      StartDressAnimation;
      SetGhostSpeed;
    end;

    ghsExitingHome: begin
      if X.Value < FTileSize.cx*14  then Direction := dRight
      else
      if X.Value > FTileSize.cx*14 then Direction := dLeft
      else Direction := dUp;
      SetGhostSpeed;
      UpdateVisual;
      if Direction = dUp then PostMessage(10)
        else PostMessage(0);
    end;

    ghsScatterMode: begin
      if FScatterChaseCounter = 0 then begin
        // first time in scatter mode
        Direction := dLeft;
      end;
      SetGhostSpeed;

      if FScatterDuration <= 0 then
        FScatterDuration := GameManager.GetGhostScatterDuration(FScatterChaseCounter);
      UpdateVisual;
      StartDressAnimation;
    end;

    ghsChaseMode: begin
      if FChaseDuration <= 0 then begin
        FChaseDuration := GameManager.GetGhostChaseDuration(FScatterChaseCounter);
        ReverseDirection;
      end;
      UpdateVisual;
      StartDressAnimation;
    end;

    ghsRetreatToHome: begin
      SetGhostSpeed;
      UpdateVisual;
      FWasEaten := True;
    end;

    ghsStoppedForEndOfGame: begin
      Speed.Value := PointF(0, 0);
    end;
  end;
end;

procedure TGhost.CenterOnTile(aRowIndex, aColIndex: integer);
begin
  SetCenterCoordinate(FTileSize.cx*aColIndex+FHalfTileSize.cx, FTileSize.cy*aRowIndex+FHalfTileSize.cy);
end;

procedure TGhost.CenterToTileRightSide(aRowIndex, aColIndex: integer);
begin
  SetCenterCoordinate((FTileSize.cx+1)*aColIndex, FTileSize.cy*aRowIndex+FHalfTileSize.cy);
end;

procedure TGhost.SpriteLeftSideOnTileLeftSide(aRowIndex, aColIndex: integer);
begin
  SetCoordinate(FTileSize.cx*aColIndex, FTileSize.cy*aRowIndex+FHalfTileSize.cy);
end;

procedure TGhost.PlaceGhostOnTheCenterOfItsCell;
var mapPos: TPoint;
begin
  mapPos := GetCurrentMapPosition(Self);
  CenterX := (mapPos.x+0.5) * FTileSize.cx;
  CenterY := (mapPos.y+0.5) * FTileSize.cy;
end;

function TGhost.CanGoOnCell(aCell: TPoint): boolean;
var til: PTile;
  groundType: Integer;
begin
  til := FMaze.GetPTile(aCell.y, aCell.x);
  if til = NIL then exit(False);
  groundType := FMaze.GetGroundType(til^.TextureIndex, til^.ixFrame, til^.iyFrame);
  Result := not (groundType in [GROUND_WALL, GROUND_DOOR]);
end;

function TGhost.GhostIsInSpecialArea: boolean;
var currentMapPos: TPoint;
begin
  currentMapPos := GetCurrentMapPosition(Self);
  Result := ((currentMapPos.y = 11) or (currentMapPos.y = 23)) and
            (currentMapPos.x in [12..17]);
end;

function TGhost.CanTurn(aOffset: TPoint): boolean;
var groundType: Integer;
begin
  groundType := GetGroundTypeAt(GetCurrentMapPosition(Self) + aOffset);
  if groundType = -1 then exit(False);

  // in state ghsRetreatToHome, ghost can pass throught the door
  if State = ghsRetreatToHome then Result := groundType <> GROUND_WALL
    else Result := not (groundType in [GROUND_WALL, GROUND_DOOR]);
end;

function TGhost.GetPossibleTurn: TArrayOfPossible;
  procedure Add(aDir: TDirection);
  begin
    SetLength(Result, Length(Result)+1);
    Result[High(Result)].Direction := aDir;
  end;
begin
  Result := NIL;

  // we avoid reverse dir, no check for special area
  if (Direction <> dDown) and CanTurn(Point(0,-1)) then
    Add(dUp);

  if (Direction <> dRight) and CanTurn(Point(-1, 0)) then
    Add(dLeft);

  if (Direction <> dUp) and CanTurn(Point(0,1)) then
    Add(dDown);

  if (Direction <> dLeft) and CanTurn(Point(1, 0)) then
    Add(dRight);
end;

function TGhost.GetPossibleTurnWithDistance(atargetMapPos: TPoint; out aIndexWithMinDistance: integer): TArrayOfPossible;
var
  currentMapPosF, atargetMapPosF: TPointF;
  currentMapPos: TPoint;
  m: Single;
  j: integer;
  procedure Add(aDir: TDirection; aDist: single);
  begin
    SetLength(Result, Length(Result)+1);
    with Result[High(Result)] do begin
      Direction := aDir;
      Distance := aDist;
      // keep the min distance
      if Distance < m then begin
        m := Distance;
        j := High(Result);
      end;
    end;
  end;

begin
  Result := NIL;
  currentMapPos := GetCurrentMapPosition(Self);
  currentMapPosF := PointF(currentMapPos);
  atargetMapPosF := PointF(atargetMapPos);
  m := MaxSingle;
  j := -1;

  // we avoid reverse dir, and ghost can't go upward in special area (above the ghost house)
  if (Direction <> dDown) and CanTurn(Point(0,-1)) and not GhostIsInSpecialArea then
    Add(dUp, Distance(currentMapPosF+PointF(0,-1), atargetMapPosF));

  if (Direction <> dRight) and CanTurn(Point(-1, 0)) then
    Add(dLeft, Distance(currentMapPosF+PointF(-1, 0), atargetMapPosF));

  if (Direction <> dUp) and CanTurn(Point(0,1)) then
    Add(dDown, Distance(currentMapPosF+PointF(0,1), atargetMapPosF));

  if (Direction <> dLeft) and CanTurn(Point(1, 0)) then
    Add(dRight, Distance(currentMapPosF+PointF(1, 0), atargetMapPosF));

  aIndexWithMinDistance := j;
end;

procedure TGhost.ComputeNextDirection(aTargetMapPos: TPoint);
var i: integer;
  A: TArrayOfPossible;
begin
  A := GetPossibleTurnWithDistance(aTargetMapPos, i);
  if (i <> -1) and (Direction <> A[i].Direction) then begin
    PlaceGhostOnTheCenterOfItsCell;
    Direction := A[i].Direction;
    UpdateVisual;
    SetGhostSpeed;
    FPreviousGhostMapPos := GetCurrentMapPosition(Self);
  end;
end;

procedure TGhost.ComputeMoveInFrightMode;
var
  ghostPos: TPoint;
  A: TArrayOfPossible;
  i: Integer;
begin
  ghostPos := GetCurrentMapPosition(Self);
  // before try to change direction, we wait the ghost is near its tile center
  if not IsNearTileCenter(Center.Round, ghostPos, Direction) then exit;
  // before try to change direction, we wait the ghost move one tile forward
  if ghostPos = FPreviousGhostMapPos then exit;
  A := GetPossibleTurn;
  if Length(A) = 0 then exit;
  i := EnsureRange(Round(Random*(Length(A)*1000)) div 1000, 0, High(A));
  Direction := A[i].Direction;
  PlaceGhostOnTheCenterOfItsCell;
  UpdateVisual;
  SetGhostSpeed;
  FPreviousGhostMapPos := ghostPos;
end;

procedure TGhost.SetGhostSpeed;
var sp: single;
begin
  sp := 0;

  if FIsInTunnel then sp := GameManager.GetGhostTunnelSpeedValue
    else case State of
      ghsWaitingBeginOfGame: sp := 0;
      ghsInHome, ghsExitingHome: sp := GameManager.GetGhostHomeSpeedValue;
      ghsRetreatToHome: sp := GameManager.GetRetreatGhostSpeedValue;
      else begin
        if FrightManager.Enabled then sp := GameManager.GetFrightGhostSpeedValue
        else case FElroyLevel of
               0: sp := GameManager.GetGhostSpeedValue;
               1: sp := GameManager.GetElroy1Speed;
               2: sp := GameManager.GetElroy2Speed;
             end;
      end;
    end;

  case Direction of
    dLeft: Speed.Value := PointF(-sp, 0);
    dRight: Speed.Value := PointF(sp, 0);
    dUp: Speed.Value := PointF(0, -sp);
    dDown: Speed.Value := PointF(0, sp);
  end;
end;

procedure TGhost.ReverseDirection;
var A: TArrayOfPossible;
  i, j: integer;
begin
  if State = ghsStoppedForEndOfGame then exit;

  FPreviousGhostMapPos := Point(-1,-1);
  // reverse the current direction
  case Direction of
    dLeft: Direction := dRight;
    dRight: Direction := dLeft;
    dUp: Direction := dDown;
    dDown: Direction := dUp;
  end;
  // check if ghost can go on the reversed direction
  A := GetPossibleTurn;
  if Length(A) = 0 then exit;

  j := -1;
  for i:=0 to High(A) do
    if A[i].Direction = Direction then j := i;

  if j = -1 then j := 0;
  Direction := A[j].Direction;

//  PlaceGhostOnTheCenterOfItsCell;
  UpdateVisual;
  SetGhostSpeed;
end;

procedure TGhost.UpdateVisual;
begin
  if State = ghsRetreatToHome then begin  // retreat to home
    GhostBody.Visible := False;
    GhostMouthEye.Visible := False;
    GhostEyeLeft.Visible := Direction = dleft;
    GhostEyeRight.Visible := Direction = dRight;
    GhostEyeUp.Visible := Direction = dUp;
    GhostEyeDown.Visible := Direction = dDown;
  end
  else
  if FrightManager.Enabled and not FWasEaten then begin   // fright mode
    if not FrightManager.FlashEnabled then begin
      GhostBody.Tint.Value := FGhostColorFright;
      GhostMouthEye.Tint.Alpha.Value := 0;
    end else begin
      GhostBody.Tint.Value := FGhostColorFrightFlashBody;
      GhostMouthEye.Tint.Value := FGhostColorFrightFlashMouth;
    end;
    GhostBody.Visible := True;
    GhostMouthEye.Visible := True;
    GhostEyeLeft.Visible := False;
    GhostEyeRight.Visible := False;
    GhostEyeUp.Visible := False;
    GhostEyeDown.Visible := False;
  end
  else begin     // all other states
    GhostBody.Tint.Value := FGhostColor;
    GhostBody.Visible := True;
    GhostMouthEye.Visible := False;
    GhostEyeLeft.Visible := Direction = dleft;
    GhostEyeRight.Visible := Direction = dRight;
    GhostEyeUp.Visible := Direction = dUp;
    GhostEyeDown.Visible := Direction = dDown;
  end;
end;

constructor TGhost.Create(aGhostColor: TBGRAPixel; aLayerIndex: integer);
begin
  inherited Create(aLayerIndex);
  if aLayerIndex = -1 then SetChildOf(FMaze, 1);
  GhostBody.Frame := 1;

  FGhostColor := aGhostColor;
  FGhostColorFright := BGRA(33,33,255);
  FGhostColorFrightFlashBody := BGRA(222,222,255);
  FGhostColorFrightFlashMouth := BGRA(255,0,0);
  DressStretched.Visible := False;
  DressStretched.Freeze := True;
  GhostLeg.Visible := False;
  GhostLeg.Freeze := True;
  DressRepear.Visible := False;
  DressRepear.Freeze := True;

  FScatterChaseCounter := 0;

  {$ifdef DEBUG_SHOW_STATE}
  debug := TFreeText.Create(Fscene);
  debug.SetChildOf(GhostBody, 0);
  debug.Y.Value := GhostBody.Height;
  debug.TexturedFont := texturedfontBonus;
  {$endif}
end;

procedure TGhost.Update(const aElapsedtime: single);
var {$ifdef DEBUG_SHOW_STATE}s: string;{$endif}
  ghostPos: TPoint;
  i: integer;
  A: TArrayOfPossible;
begin
  if State = ghsStoppedForEndOfGame then exit;

  inherited Update(aElapsedtime);

  if State = ghsUnknown then exit;

  // check if ghost pass in the tunnel
  ghostPos := GetCurrentMapPosition(Self);
  if ghostPos.y = 14 then begin
    FIsInTunnel := (ghostPos.x <= 4) or (ghostPos.x >= 23);
    if FIsInTunnel then begin
      SetGhostSpeed;
      if CenterX > FTileSize.cx*(MAZE_H_TILE_COUNT+2) then CenterX := -FTileSize.cx*1
        else if CenterX < -FTileSize.cx*2 then CenterX := FTileSize.cx*(MAZE_H_TILE_COUNT+2);
    end;
  end;


  case State of

    ghsInHome:begin
      // do the anim up/down in home
      case Direction of
        dDown: begin
          if CenterY >= FTileSize.cy*15 then begin
            Direction := dUp;
            UpdateVisual;
            SetGhostSpeed;
          end;
        end;
        dUp: begin
          if CenterY <= FTileSize.cy*14 then begin
            Direction := dDown;
            UpdateVisual;
            SetGhostSpeed;
          end;
        end;
      end;
    end;

    ghsScatterMode, ghsChaseMode: begin
      if FrightManager.Enabled and not FWasEaten then begin
        ComputeMoveInFrightMode;
        exit;
      end;

      // alternate scatter and chaser mode only if not fright mode activated
      if FScatterChaseCounter < 4 then
        case State of
          ghsScatterMode: begin
            FScatterDuration := FScatterDuration - aElapsedtime;
            if FScatterDuration <= 0 then State := ghsChaseMode;
          end;
          ghsChaseMode: begin
            FChaseDuration := FChaseDuration - aElapsedtime;
            if FChaseDuration <= 0 then begin
              inc(FScatterChaseCounter);
              if FScatterChaseCounter < 4 then State := ghsScatterMode;
            end;
          end;
        end;

      if State = ghsScatterMode then begin
        // compute move in scatter mode
        ghostPos := GetCurrentMapPosition(Self);
        // before try to change direction, we wait the ghost is near its tile center
        if not IsNearTileCenter(Center.Round, ghostPos, Direction) then exit;
        // before try to change direction, we wait the ghost move one tile forward
        if ghostPos = FPreviousGhostMapPos then exit;
        ComputeNextDirection(GetScatterCornerTargetMapCell);
      end else begin
        // compute move in chase mode
        ghostPos := GetCurrentMapPosition(Self);
        // before try to change direction, we wait the ghost is near its tile center
        if not IsNearTileCenter(Center.Round, ghostPos, Direction) then exit;
        // before try to change direction, we wait the ghost move one tile forward
        if ghostPos = FPreviousGhostMapPos then exit;
        ComputeNextDirection(GetChaseTargetMapPosition);
      end;
    end;

    ghsRetreatToHome: begin
      ghostPos := GetCurrentMapPosition(Self);
      // before try to change direction, we wait the ghost is near its tile center
      if not IsNearTileCenter(Center.Round, ghostPos, Direction) then exit;

      // check if ghost is in house
      if ghostPos = GetHouseRetreatMapPosition then begin
        State := ghsExitingHome;
        UpdateVisual;
        exit;
      end;

      // before try to change direction, we wait the ghost move one tile forward
      if ghostPos = FPreviousGhostMapPos then exit;

      A := GetPossibleTurnWithDistance(GetHouseRetreatMapPosition, i);
      if (i <> -1) and (Direction <> A[i].Direction) then begin
        PlaceGhostOnTheCenterOfItsCell;
        Direction := A[i].Direction;
        UpdateVisual;
        SetGhostSpeed;
        FPreviousGhostMapPos := ghostPos;
      end;
    end;

  end;//case state

  {$ifdef DEBUG_SHOW_STATE}
  WriteStr(s, State);
  ghostPos := GetCurrentMapPosition(Self);
  debug.caption := {s}
                   {+lineending+ghostPos.X.ToString+','+ghostPos.y.ToString}
                   'sca '+FormatFloat('0.0', FScatterDuration)+lineending+
                   'cha '+FormatFloat('0.0',FChaseDuration)
                   ;
  {$endif}
end;

procedure TGhost.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // exiting home
    0: begin  // wait until ghost is centered in home
      if Abs(X.Value - FTileSize.cx*14) > 1.0 then PostMessage(0)
        else PostMessage(10);
    end;
    10: begin // ghost go up to exit home
      X.Value := FTileSize.cx*14;
      Direction := dUp;
      SetGhostSpeed;
      UpdateVisual;
      PostMessage(20);
    end;
    20: begin
      if Abs(CenterY - FTileSize.cy*12+FHalfTileSize.cy) < 1.0 then begin
        RestoreStateAfterExitingHouse;
        PlaceGhostOnTheCenterOfItsCell;
      end else PostMessage(20); // wait ghost is outside its home
    end;
  end;
end;

procedure TGhost.StartDressAnimation;
begin
  GhostBody.SetFrameLoopBounds(1, 2);
  GhostBody.FrameAddPerSecond(7);
end;

procedure TGhost.StopDressAnimation;
begin
  GhostBody.FrameAddPerSecond(0);
  GhostBody.Frame := 1;
end;

function TGhost.CanKillPacman: boolean;
begin
  Result := State in [ghsScatterMode, ghsChaseMode, ghsExitingHome];
end;

function TGhost.CanBeEaten: boolean;
begin
  Result := (State in [ghsScatterMode, ghsChaseMode]) and
            not FWasEaten;
end;

procedure TGhost.RestoreStateAfterExitingHouse;
begin
  if FWasEaten then begin  // the ghost exit house after repop
    if FStateBeforeEaten in [ghsScatterMode, ghsChaseMode] then State := FStateBeforeEaten
    else State := ghsScatterMode;
    FStateBeforeEaten := ghsUnknown;
  end else State := ghsScatterMode;  // beginning of the stage

end;

procedure TGhost.EnterFrightMode;
begin
  if State in [ghsScatterMode, ghsChaseMode] then
    ReverseDirection;
  FWasEaten := False;
end;

procedure TGhost.ExitFrightMode;
begin
  SetGhostSpeed;
  UpdateVisual;
  FWasEaten := False;
end;

procedure TGhost.ShowGhostEatenBonus(aBonus: integer);
var o: TFreeText;
begin
  o := TFreeText.Create(FScene);
  FScene.Add(o, LAYER_UI);
  o.TexturedFont := texturedfontBonus;
  o.Caption := aBonus.ToString;
  o.Tint.Value := BGRA(0,255,255);
  o.SetCenterCoordinate(SurfaceToScene(PointF(Width*0.5, Height*0.5)));
  o.KillDefered(1.0);
end;

procedure TGhost.SetNormalMode;
begin
  State := ghsUnknown;
  GhostBody.Tint.Value := FGhostColor;
  GhostBody.Visible := True;
  GhostMouthEye.Visible := False;
  GhostEyeLeft.Visible := Direction = dleft;
  GhostEyeRight.Visible := Direction = dRight;
  GhostEyeUp.Visible := Direction = dUp;
  GhostEyeDown.Visible := Direction = dDown;
end;

procedure TGhost.SetFrightMode;
begin
  State := ghsUnknown;
  GhostBody.Tint.Value := FGhostColorFright;
  GhostMouthEye.Tint.Alpha.Value := 0;
  GhostBody.Visible := True;
  GhostMouthEye.Visible := True;
  GhostEyeLeft.Visible := False;
  GhostEyeRight.Visible := False;
  GhostEyeUp.Visible := False;
  GhostEyeDown.Visible := False;
end;

procedure TGhost.SetDressRepeared;
begin
  SetNormalMode;
  DressRepear.Visible := True;
end;

procedure TGhost.SetCoor(aX, aY: single);
begin
  X.Value := aX - GhostBody.Width*0.5;
  Y.Value := aY - GhostBody.Height*0.5;
end;

procedure TGhost.SetYValue(AValue: single);
begin
  Y.Value := AValue - GhostBody.Height*0.5;
end;

function TGhost.BodyWidth: integer;
begin
  Result := GhostBody.Width;
end;

function TGhost.BodyHeight: integer;
begin
  Result := GhostBody.Height;
end;

function TGhost.BodyBottomY: single;
begin
  Result := Y.Value + GhostBody.Height*0.5;
end;

function TGhost.BodyLeft: single;
begin
  Result := CenterX - GhostBody.Width*0.5;
end;

function TGhost.BodyRight: single;
begin
  Result := CenterX + GhostBody.Width*0.5;
end;

function TGhost.DressRight: single;
begin
  Result := CenterX + GhostBody.Width* 0.4;
end;

{ TGhostHouseManager }

function TGhostHouseManager.GetTimerDuration: single;
begin
  case GameManager.CurrentLevel of
    1..4: Result := 4.0;
    else Result := 3.0;
  end;
end;

procedure TGhostHouseManager.CallWhenLifeIsLost;
begin
  FGlobalDotCounter := 0;
  FGlobalCounterEnabled := True;
  FTimer := 0.0;
end;

procedure TGhostHouseManager.IncrementDotEatenByPacman;
begin
  FTimer := 0;
  if FGlobalCounterEnabled then
    inc(FGlobalDotCounter)
  else
  if ScreenGame.Pinky.State = ghsInHome then
    inc(FPinkyDotCounter)
  else
  if ScreenGame.Inky.State = ghsInHome then
    inc(FInkyDotCounter)
  else
  if ScreenGame.Clide.State = ghsInHome then
    inc(FClideDotCounter);

  CheckDotCounter;
end;

procedure TGhostHouseManager.CheckDotCounter;
begin
  if FGlobalCounterEnabled then begin
    if (ScreenGame.Pinky.State = ghsInHome) and
       (FGlobalDotCounter >= 7) then
      ScreenGame.Pinky.State := ghsExitingHome
    else
    if (ScreenGame.Inky.State = ghsInHome) and
       (FGlobalDotCounter >= 17) then
      ScreenGame.Inky.State := ghsExitingHome
    else
    if (ScreenGame.Clide.State = ghsInHome) and
       (FGlobalDotCounter >= 32) then
      FGlobalCounterEnabled := False;
    exit;
  end;

  if (ScreenGame.Pinky.State = ghsInHome) and
     (FPinkyDotCounter >= ScreenGame.Pinky.GetDotsLimitToLeaveHouse) then
    ScreenGame.Pinky.State := ghsExitingHome
  else
  if (ScreenGame.Inky.State = ghsInHome) and
     (FInkyDotCounter >= ScreenGame.Inky.GetDotsLimitToLeaveHouse) then
    ScreenGame.Inky.State := ghsExitingHome
  else
  if (ScreenGame.Clide.State = ghsInHome) and
     (FClideDotCounter >= ScreenGame.Clide.GetDotsLimitToLeaveHouse) then
   ScreenGame.Clide.State := ghsExitingHome;
end;

procedure TGhostHouseManager.Update(const aElapsedTime: single);
begin
  CheckDotCounter;

  FTimer := FTimer + aElapsedTime;
  if FTimer < GetTimerDuration then exit;
  if (ScreenGame.Pinky.State = ghsInHome) then begin
    ScreenGame.Pinky.State := ghsExitingHome;
    FTimer := 0.0;
  end
  else
  if (ScreenGame.Inky.State = ghsInHome) then begin
    ScreenGame.Inky.State := ghsExitingHome;
    FTimer := 0.0;
  end
  else
  if (ScreenGame.Clide.State = ghsInHome) then begin
    ScreenGame.Clide.State := ghsExitingHome;
    FTimer := 0.0;
  end;
end;

{ TBlinky }

function TBlinky.GetHouseRetreatMapPosition: TPoint;
begin
  Result := Point(14,14);
end;

procedure TBlinky.SetPositionAndDirectionAtBeginning;
begin
  SpriteLeftSideOnTileLeftSide(11, 14);
  Direction := dLeft;
end;

function TBlinky.GetScatterCornerTargetMapCell: TPoint;
begin
  Result := Point(25, -2);
end;

function TBlinky.GetChaseTargetMapPosition: TPoint;
begin
  Result := GetCurrentMapPosition(ScreenGame.PacMan);
end;

function TBlinky.GetDotsLimitToLeaveHouse: integer;
begin
  Result := 0;
end;

constructor TBlinky.Create(aLayerIndex: integer);
begin
  inherited Create(BGRA(255,0,0), aLayerIndex);
end;

{ TPinky }

function TPinky.GetHouseRetreatMapPosition: TPoint;
begin
  Result := Point(14, 14);
end;

procedure TPinky.SetPositionAndDirectionAtBeginning;
begin
  SpriteLeftSideOnTileLeftSide(14, 14);
  Direction := dDown;
end;

function TPinky.GetScatterCornerTargetMapCell: TPoint;
begin
  Result := Point(2, -2);
end;

function TPinky.GetChaseTargetMapPosition: TPoint;
var pacmanPos: TPoint;
begin
  pacmanPos := GetCurrentMapPosition(ScreenGame.PacMan);
  case ScreenGame.PacMan.Direction of
    dLeft: Result := pacmanPos + Point(-4, 0);
    dRight: Result := pacmanPos + Point(4, 0);
    dDown: Result := pacmanPos + Point(0, 4);
    dUp: Result := pacmanPos + Point(-4, -4);   // reproduce the original bug, see http://donhodges.com/pacman_pinky_explanation.htm
  end;
end;

function TPinky.GetDotsLimitToLeaveHouse: integer;
begin
  Result := 0;
end;

constructor TPinky.Create(aLayerIndex: integer);
begin
  inherited Create(BGRA(255,183,255), aLayerIndex);
end;

{ TInky }

function TInky.GetHouseRetreatMapPosition: TPoint;
begin
  Result := Point(12, 14);
end;

procedure TInky.SetPositionAndDirectionAtBeginning;
begin
  SpriteLeftSideOnTileLeftSide(14, 12);
  Direction := dUp;
end;

function TInky.GetScatterCornerTargetMapCell: TPoint;
begin
  Result := Point(27, 30);
end;

function TInky.GetChaseTargetMapPosition: TPoint;
var offset, pacmanPos, blinkyPos: TPoint;
begin
  pacmanPos := GetCurrentMapPosition(ScreenGame.PacMan);
  case ScreenGame.PacMan.Direction of
    dLeft: offset := Point(-2,0);
    dRight: offset := Point(2,0);
    dUp: offset := Point(-2,-2); // same bug as in the original game
    dDown: offset := Point(0,2);
  end;
  blinkyPos := GetCurrentMapPosition(ScreenGame.Blinky);
  offset := ((pacmanPos + offset) - blinkyPos);
  offset.x := offset.x * 2;
  offset.y := offset.y * 2;
  Result := blinkyPos + offset;
end;

function TInky.GetDotsLimitToLeaveHouse: integer;
begin
  case GameManager.CurrentLevel of
    1: Result := 30;
    else Result := 0;
  end;
end;

constructor TInky.Create(aLayerIndex: integer);
begin
  inherited Create(BGRA(0,255,255), aLayerIndex);
end;

{ TClide }

function TClide.GetHouseRetreatMapPosition: TPoint;
begin
  Result := Point(16, 14);
end;

procedure TClide.SetPositionAndDirectionAtBeginning;
begin
  SpriteLeftSideOnTileLeftSide(14, 16);
  Direction := dUp;
end;

function TClide.GetScatterCornerTargetMapCell: TPoint;
begin
  Result := Point(0, 30);
end;

function TClide.GetChaseTargetMapPosition: TPoint;
var d: Single;
begin
  d := Distance(PointF(GetCurrentMapPosition(ScreenGame.PacMan)), PointF(GetCurrentMapPosition(Self)));
  if d >= 8 then Result := GetCurrentMapPosition(ScreenGame.PacMan)
    else Result := GetScatterCornerTargetMapCell;
end;

function TClide.GetDotsLimitToLeaveHouse: integer;
begin
  case GameManager.CurrentLevel of
    1: Result := 60;
    2: Result := 50;
    else Result := 0;
  end;
end;

constructor TClide.Create(aLayerIndex: integer);
begin
  inherited Create(BGRA(255,183,81), aLayerIndex);
end;

{ THighScore }

constructor THighScore.Create(aLayerIndex: integer);
begin
  inherited Create(aLayerIndex);
  // init with current value
  SetValue(GameManager.HighScore);
end;

procedure THighScore.SetValue(aValue: integer);
begin
  Caption := aValue.ToString;
end;

{ TFruits }

procedure TFruits.UpdateIcons;
const APPEAR_INDEX:array[0..18] of integer=(0,1,2,2,3,3,4,4,5,5,6,6,7,7,7,7,7,7,7);
var i, j, firstIndex, lastIndex: integer;
  xx, yy: single;
begin
  // kill current icons
  for i:=0 to High(FIcons) do
    if Assigned(FIcons[i]) then FIcons[i].Kill;
  // create the new ones
  lastIndex := GameManager.CurrentLevel-1;
  if FScene.CurrentScreen = ScreenIntermission then dec(lastIndex);
  if lastIndex > 18 then lastIndex := 18;
  firstIndex := lastIndex - 6;
  if firstIndex < 0 then firstIndex := 0;
  xx := FTileSize.cx*2*6;
  yy := FTileSize.cy*0.5;
  j := 0;
  for i:=firstIndex to lastIndex do begin
    FIcons[j] := TSprite.Create(texFruits[APPEAR_INDEX[i]], False);
    FIcons[j].SetChildOf(Self, 0);
    FIcons[j].SetCoordinate(xx, yy);
    xx := xx - FTileSize.cx*2;
    inc(j);
  end;
end;

constructor TFruits.Create(aLayerIndex: integer);
begin
  inherited Create(FScene);
  FScene.Add(Self, aLayerIndex);
  SetCoordinate(FTileSize.cx*13, FTileSize.cy*33);
  UpdateIcons;
end;

{ TFruitInMaze }

procedure TFruitInMaze.CreateFruit;
begin
  FFruit := TSprite.Create(texFruits[GameManager.GetFruitTextureIndex], False);
  FFruit.SetChildOf(Self, 0);
  FFruit.CenterOnParent;
  PostMessage(0, 15.0);
end;

constructor TFruitInMaze.Create;
begin
  inherited Create(FScene);
  SetChildOf(FMaze, 0);
  CenterX := FTileSize.cx*14;
  CenterY := FTileSize.cy*17.5;

  FFruit := NIL;
  FCount := 0;
end;

procedure TFruitInMaze.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  case FCount of
    0: begin
      if GameManager.DotEaten >= 70 then begin
        inc(FCount);
        CreateFruit;
      end;
    end;
    1: begin
      if GameManager.DotEaten >= 170 then begin
        inc(FCount);
        CreateFruit;
      end;
    end;
  end;
end;

procedure TFruitInMaze.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    0: begin
      if FFruit <> NIL then FFruit.Kill;
      FFruit := NIL;
    end;
  end;
end;

procedure TFruitInMaze.KillFruit;
begin
  if FFruit <> NIL then FFruit.Kill;
  FFruit := NIL;
  ClearMessageList;
end;

procedure TFruitInMaze.ShowBonus;
var o: TFreeText;
begin
  KillFruit;
  o := TFreeText.Create(Fscene);
  o.SetChildOf(Self, 0);
  o.Caption := GameManager.GetFruitBonusPoint.ToString;
  o.TexturedFont := texturedfontBonus;
  o.CenterOnParent;
  o.KillDefered(3);
end;

{ TLives }

procedure TLives.UpdateIcons;
var i: Integer;
  o: TSprite;
  xx, yy: single;
begin
  // kill current icons
  for i:=0 to ChildCount-1 do
    Childs[i].Kill;

  // create the new ones
  xx := 0;
  yy := FTileSize.cy*0.5;
  for i:=0 to GameManager.PlayerLife-1 do begin
    o := TSprite.Create(texLife, False);
    AddChild(o, 0);
    o.SetCoordinate(xx, yy);
    xx := xx + FTileSize.cx*2;
  end;
end;

class procedure TLives.LoadTexture(aAtlas: TAtlas);
begin
  texLife := aAtlas.AddFromSVG(TexturesFolder+'PacmanLife.svg',
                               Round(FTileSize.cx*1.5), Round(FTileSize.cy*1.5));
end;

constructor TLives.Create(aLayerIndex: integer);
begin
  inherited Create(FScene);
  FScene.Add(Self, aLayerIndex);
  SetCoordinate(FTileSize.cx*1, FTileSize.cy*33);
  UpdateIcons;
end;

procedure TLives.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if ChildCount <> GameManager.PlayerLife then
    UpdateIcons;
end;

{ TPanelPause }

procedure TPanelPause.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  if Sender = Button1 then begin
    Audio.ResumeAllPausedSounds;
    Hide(scenarioPanelZoomOUT, False);
  end;

  if Sender = Button2 then FScene.RunScreen(ScreenMainMenu);
end;

constructor TPanelPause.Create;
begin
  inherited Create;
  Button1.OnClick := @ProcessButtonClick;
  Button2.OnClick := @ProcessButtonClick;
  CenterX := FScene.Center.x;
  Button1.CenterX := Width*0.5;
  Button2.CenterX := Width*0.5;
end;

procedure TPanelPause.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);

  case UserValue of
    // wait player release PAUSE key
    0: begin
      if PauseKeyPressed then PostMessage(0)
      else begin
        FScene.KeyPressed[GameManager.KeyPause]; // reset key state in buffer
        PostMessage(1);
      end;
    end;
    // check if player press PAUSE key
    1: begin
      if PauseKeyPressed then begin
        Audio.ResumeAllPausedSounds;
        Hide(scenarioPanelZoomOUT, False);
      end else PostMessage(1);
    end;
  end;
end;

procedure TPanelPause.Show;
begin
  ClearMessageList;
  PostMessage(0, 1.0); // scan pause key
  Audio.PauseAllPlayingSounds;
  ShowModal(scenarioPanelZoomIN);
end;

{ TPanelMainMenu }


procedure TPanelMainMenu.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
   if Sender = BPlay then begin
    GameManager.InitForNewGame;
    FScene.RunScreen(ScreenGame);
  end;

  if Sender = BOptions then ScreenMainMenu.ShowOptionsPanel;

  if Sender = BQuit then FormMain.Close;
end;

constructor TPanelMainMenu.Create;
begin
  inherited Create;
  FScene.Add(Self, LAYER_UI);
  //CenterX := FScene.Center.x;

  BPlay.OnClick := @ProcessButtonClick;
  BOptions.OnClick := @ProcessButtonClick;
  BQuit.OnClick := @ProcessButtonClick;

  BPlay.CenterX := Width*0.5;
  BOptions.CenterX := Width*0.5;
  BQuit.CenterX := Width*0.5;

end;

{ TPanelOptions }

procedure TPanelOptions.UpdateTextDifficulty;
begin
  if RadioNormal.Checked then begin
    TextArea1.Text.Caption := 'Only one extra life at 10000 pts'#10'Ghost speed is normal';
    GameManager.GameDifficulty := 0;
  end;
  if RadioEasy.Checked then begin
    TextArea1.Text.Caption := 'extra life at 10000 and 20000 pts'#10'ghosts are slowed down';
    GameManager.GameDifficulty := 1;
  end;
  if RadioEasiest.Checked then begin
    TextArea1.Text.Caption := 'extra life at 10000, 20000 and 30000 pts'#10'ghosts are slowed down even more';
    GameManager.GameDifficulty := 2;
  end;
end;

procedure TPanelOptions.UpdateKeyNames;
begin
  LabelUp.Caption := FScene.KeyToString[GameManager.KeyUp];
  LabelUp.CenterX := BUp.CenterX;
  LabelLeft.Caption := FScene.KeyToString[GameManager.KeyLeft];
  LabelLeft.CenterX := BLeft.CenterX;
  LabelRight.Caption := FScene.KeyToString[GameManager.KeyRight];
  LabelRight.CenterX := BRight.CenterX;
  LabelDown.Caption := FScene.KeyToString[GameManager.KeyDown];
  LabelDown.CenterX := BDown.CenterX;
  LabelPause.Caption := FScene.KeyToString[GameManager.KeyPause];
  LabelPause.CenterX := BPause.CenterX;
end;

procedure TPanelOptions.UpdateHighscoreLabel;
begin
  Label2.Caption := 'Current highscore: '+GameManager.HighScore.ToString;
end;

procedure TPanelOptions.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  if (Sender = RadioNormal) and RadioNormal.Checked then
    GameManager.GameDifficulty := 0;
  if (Sender = RadioEasy) and RadioEasy.Checked then
    GameManager.GameDifficulty := 1;
  if (Sender = RadioEasiest) and RadioEasiest.Checked then
    GameManager.GameDifficulty := 2;
  UpdateTextDifficulty;

  if Sender = CheckRetroMode then
    GameManager.RetroMode := CheckRetroMode.Checked;

  if Sender = BResetHighScore then begin
    GameManager.HighScore := 0;
    GameManager.Save;
    UpdateHighscoreLabel;
  end;

  if Sender = BOK then ScreenMainMenu.HideOptionsPanel;

  if (Sender = BUp) or (Sender = BLeft) or (Sender = BRight) or (Sender = BDown) or
     (Sender = BPause) then begin
    FButtonEdited := TUIButton(Sender);
    with TPanelPressAKey.Create(Self) do
      ShowModal(scenarioPanelZoomIN);
  end;
end;

procedure TPanelOptions.ProcessPressAKeyDone(aKey: word);
begin
  if FButtonEdited = BUp then GameManager.KeyUp := aKey;
  if FButtonEdited = BLeft then GameManager.KeyLeft := aKey;
  if FButtonEdited = BRight then GameManager.KeyRight := aKey;
  if FButtonEdited = BDown then GameManager.KeyDown := aKey;
  if FButtonEdited = BPause then GameManager.KeyPause := aKey;
  GameManager.Save;
  UpdateKeyNames;
end;

constructor TPanelOptions.Create;
begin
  inherited Create;
  //CenterX := FScene.Center.x;

  RadioNormal.Checked := GameManager.GameDifficulty = 0;
  RadioEasy.Checked := GameManager.GameDifficulty = 1;
  RadioEasiest.Checked := GameManager.GameDifficulty = 2;

  BOK.OnClick := @ProcessButtonClick;
  RadioNormal.OnChange := @ProcessButtonClick;
  RadioEasy.OnChange := @ProcessButtonClick;
  RadioEasiest.OnChange := @ProcessButtonClick;
  UpdateTextDifficulty;

  BResetHighScore.OnClick := @ProcessButtonClick;
  UpdateHighscoreLabel;

  BUp.OnClick := @ProcessButtonClick;
  BLeft.OnClick := @ProcessButtonClick;
  BRight.OnClick := @ProcessButtonClick;
  BDown.OnClick := @ProcessButtonClick;
  BPause.OnClick := @ProcessButtonClick;
  UpdateKeyNames;

  BLeft.Image.FlipH := True;
  BUp.Image.Angle.Value := -90;
  BDown.Image.Angle.Value := 90;

  CheckRetroMode.Checked := GameManager.RetroMode;
  CheckRetroMode.OnChange := @ProcessButtonClick;
end;

{ TPanelPressAKey }

constructor TPanelPressAKey.Create(aParentOptionPanel: TPanelOptions);
begin
  inherited Create;
  FParentOptionPanel := aParentOptionPanel;
  FCounter := 5.99;
  FScanKey := True;
end;

procedure TPanelPressAKey.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  if not {FScanKey}MouseInteractionEnabled then exit;

  FCounter := FCounter - aElapsedTime;
  Label2.Caption := Trunc(FCounter).ToString;
  if FCounter <= 0 then begin
    FScanKey := False;
    Hide(scenarioPanelZoomOUT, True);
  end else if FScene.UserPressAKey then begin
         FParentOptionPanel.ProcessPressAKeyDone(FScene.LastKeyDown);
         Hide(scenarioPanelZoomOUT, True);
         FScanKey := False;
       end;
end;

end.

