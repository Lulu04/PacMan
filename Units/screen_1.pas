unit screen_1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common, u_sprite_def,
  u_sprite_labelready, u_sprite_labelhighscore, u_sprite_score;


type

TGameState = (gsUnknown,
              gsStartLevel,
              gsRunning,
              gsPlayingLoseAnimation,
              gsEndLoseAnimation,
              gsPlayingWinAnimation,
              gsEndWinAnimation);

{ TScreen1 }

TScreen1 = class(TScreenTemplate)
private
  FGameState: TGameState;
  FPacMan: TPacMan;
  FLabelReady: TLabelReady;
  FLabelHighScore: TLabelHighScore;
  FScore: TScore;
  FHighScore: THighScore;
  FFruits: TFruits;
  FLives: TLives;
  procedure SetGameState(AValue: TGameState);
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure Update(const AElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;

  property GameState: TGameState read FGameState write SetGameState;
 // property Score: integer
end;

var Screen1: TScreen1 = NIL;

implementation
uses Forms, u_game_manager;

{ TScreen1 }

procedure TScreen1.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then Exit;
  FGameState := AValue;

  case AValue of
    gsStartLevel: begin
      FPacman.State := psWaitingBeginOfGame;

      PostMessage(0);
    end;
    gsRunning: begin
      FPacMan.GoLeft;

    end;
    gsPlayingLoseAnimation: begin

    end;
    gsEndLoseAnimation: begin

    end;
    gsPlayingWinAnimation: begin

    end;
    gsEndWinAnimation: begin

    end;
  end;
end;

procedure TScreen1.CreateObjects;
begin
  // tile engine
  FTileEngine := TTileEngine.Create(FScene);
  FScene.Add(FTileEngine, LAYER_MAZE);
  FTileEngine.LoadMapFile(DataFolder+'Main_Map.map', texMazeTileSet);
  FTileEngine.SetTileSize(FTileSize.cx, FTileSize.cy);
  FTileEngine.SetCoordinate(0, FTileSize.cy*2);
  FTileEngine.PositionOnMap.Value := PointF(0, 0);
  FTileEngine.SetViewSize(FTileSize.cx*MAZE_H_TILE_COUNT, FTileSize.cy*MAZE_V_TILE_COUNT);

  // score and highscore
  FLabelHighScore := TLabelHighScore.Create(LAYER_UI);
  FLabelHighScore.SetCoordinate((FScene.Width-FLabelHighScore.Width)*0.5, 0);

  FScore := TScore.Create(LAYER_UI);
  FScore.RightX := FTileSize.cx*7;
  FScore.Y.Value := FTileSize.cy;

  FHighScore := THighScore.Create(LAYER_UI);
  FHighScore.CenterX := FTileSize.cx*TOTAL_H_TILE_COUNT*0.5;
  FHighScore.Y.Value := FTileSize.cy;


  // Life icons
  FLives := TLives.Create(LAYER_UI);
  // fruit icons
  FFruits := TFruits.Create(LAYER_UI);

  // ready
  FLabelReady := TLabelReady.Create(-1);
  FLabelReady.SetChildOf(FTileEngine, 1);
  FLabelReady.CenterX := FTileSize.cx*TOTAL_H_TILE_COUNT/2;
  FLabelReady.CenterY := FTileSize.cy*17.5;
  //FLabelReady.SetCoordinate(ScaleW(367), ScaleH(535));
  FLabelReady.Visible := False;



  // pacman
  FPacMan := TPacMan.Create(-1);     // LAYER_PLAYER
  FPacMan.SetChildOf(FTileEngine, 1);
 { FPacMan.SetCoordinate(FTileSize.cx*13, FTileSize.cy*22.5);
  FPacMan.SetFrameLoopBounds(1, 3);
  FPacMan.FrameAddPerSecond(12);  }

 GameManager.InitForNewGame; // ne pas mettre ici mais dans le menu de départ

  GameState := gsStartLevel;
end;

procedure TScreen1.FreeObjects;
begin
  FScene.ClearAllLayer;    // kill all surfaces on all layer
end;

procedure TScreen1.Update(const AElapsedTime: single);
begin
  inherited Update(AElapsedTime);

  case GameState of
    gsRunning: begin
      if LeftKeyPressed then FPacman.GoLeft;
      if RightKeyPressed then FPacman.GoRight;
      if UpKeyPressed then FPacman.GoUp;
      if DownKeyPressed then FPacman.GoDown;

    end;// gsRunning
  end;
end;

procedure TScreen1.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // Start Level
    0: begin
       PostMessage(5, 2.0);
    end;
    5: begin
      FPacman.Visible := True;
      PostMessage(10, 2.0);
    end;
    10: begin
      FLabelReady.Visible := True;
      PostMessage(15, 2.0);
    end;
    15: begin
      FLabelReady.Visible := False;
      FPacman.State := psRunning;
      GameState := gsRunning;
    end;
  end;//case
end;


end.

