unit screen_game;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common, u_sprite_def,
  u_sprite_labelready, u_sprite_labelhighscore, u_sprite_score,
  u_sprite_labelplayerone, u_sprite_labelgameover;


type

{ TFrightManager }

TFrightManager = class
private
  FTotalDuration,
  FDurationBeforeFlash,
  FFlashDuration: Single;
  FFlashCount: integer;
  procedure ExitFrightMode;
public
  Enabled: Boolean;
  FlashEnabled: boolean;
  procedure Update(const aElapsedTime: single);
  procedure EnterFrightMode;
end;

TGameState = (gsUnknown,
              gsStartLevel,
              gsRunning,
              gsEatGhostAnimation,
              gsPlayingLoseAnimation,
              gsEndLoseAnimation,
              gsPlayingWinAnimation,
              gsEndWinAnimation);

{ TScreenGame }

TScreenGame = class(TScreenTemplate)
private
  FGameState: TGameState;
  FPacMan: TPacMan;
  FBlinky: TBlinky;
  FPinky: TPinky;
  FInky: TInky;
  FClide: TClide;
  FLabelReady: TLabelReady;
  FLabelPlayerOne: TLabelPlayerOne;
  FLabelGameOver: TLabelGameOver;
  FLabelHighScore: TLabelHighScore;
  FScore: TScore;
  FHighScore: THighScore;
  FFruits: TFruits;
  FLives: TLives;
  FFruitInMaze: TFruitInMaze;
  FGhostHouseManager: TGhostHouseManager;

  FPanelPause: TPanelPause;
  debug: TFreeText;
  procedure SetGameState(AValue: TGameState);
private
  FGhostEaten: TGhost;
private
  FMazeFlashCount: integer;
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure Update(const AElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;

  procedure IncrementScore(aDelta: integer);

  property GameState: TGameState read FGameState write SetGameState;
  property Score: TScore read FScore;
  property HighScore: THighScore read FHighScore;
  property PacMan: TPacMan read FPacMan;
  property Blinky: TBlinky read FBlinky;
  property Pinky: TPinky read FPinky;
  property Inky: TInky read FInky;
  property Clide: TClide read FClide;
  property GhostHouseManager: TGhostHouseManager read FGhostHouseManager;
end;

var ScreenGame: TScreenGame = NIL;
    FrightManager: TFrightManager;

implementation
uses Forms, u_game_manager, u_audio, screen_mainmenu, screen_intermission;

{ TFrightManager }

procedure TFrightManager.Update(const aElapsedTime: single);
begin
  if not Enabled or (FTotalDuration <= 0.0) then exit;

    FTotalDuration := FTotalDuration - aElapsedtime;
    if FTotalDuration <= 0 then ExitFrightMode
      else begin
        FDurationBeforeFlash := FDurationBeforeFlash - aElapsedtime;
        if FDurationBeforeFlash <= 0 then begin
          FDurationBeforeFlash := 0;
          if FFlashCount > 0 then begin
            FFlashDuration := FFlashDuration - aElapsedtime;
            if FFlashDuration <= 0 then begin
              FlashEnabled := not FlashEnabled;
              if FlashEnabled then dec(FFlashCount);
              FFlashDuration := FRIGHT_MODE_FLASH_DURATION;
              ScreenGame.Blinky.UpdateVisual;
              ScreenGame.Pinky.UpdateVisual;
              ScreenGame.Inky.UpdateVisual;
              ScreenGame.Clide.UpdateVisual;
            end;
          end;
        end;
      end;
end;

procedure TFrightManager.EnterFrightMode;
begin
  if GameManager.CanFright then begin
    Enabled := True;
    GameManager.ResetBonusGhostEaten;
    FlashEnabled := False;
    FTotalDuration := GameManager.GetFrightDuration;
    FDurationBeforeFlash := FTotalDuration - GameManager.GetFlashCount*FRIGHT_MODE_FLASH_DURATION*2;
    FFlashCount := GameManager.GetFlashCount;
    FFlashDuration := FRIGHT_MODE_FLASH_DURATION;

    Audio.StopSirenLoop;  // stop siren
    Audio.PlayFrightMode; // play frightMode sound loop
    ScreenGame.Pacman.EnterFrightMode;
    ScreenGame.Blinky.EnterFrightMode;
    ScreenGame.Pinky.EnterFrightMode;
    ScreenGame.Inky.EnterFrightMode;
    ScreenGame.Clide.EnterFrightMode;
  end else begin
    // no more Fright mode: only reverse direction of all ghost
    ScreenGame.Blinky.ReverseDirection;
    ScreenGame.Pinky.ReverseDirection;
    ScreenGame.Inky.ReverseDirection;
    ScreenGame.Clide.ReverseDirection;
  end;
 end;

procedure TFrightManager.ExitFrightMode;
begin
  Enabled := False;
  ScreenGame.Pacman.ExitFrightMode;
  ScreenGame.Blinky.ExitFrightMode;
  ScreenGame.Pinky.ExitFrightMode;
  ScreenGame.Inky.ExitFrightMode;
  ScreenGame.Clide.ExitFrightMode;

  Audio.StopFrightMode;// stop fright mode sound
  Audio.PlaySirenLoop;// play siren loop
end;

{ TScreenGame }

procedure TScreenGame.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then Exit;
  FGameState := AValue;

  case AValue of
    gsStartLevel: begin
      FPacman.State := psWaitingBeginOfGame;
      FBlinky.State := ghsWaitingBeginOfGame;
      FPinky.State := ghsWaitingBeginOfGame;
      FInky.State := ghsWaitingBeginOfGame;
      FClide.State := ghsWaitingBeginOfGame;
      PostMessage(0);
    end;

    gsRunning: begin
      FPacMan.GoLeft;
      Audio.PlaySirenLoop;
    end;

    gsEatGhostAnimation: begin
      PostMessage(400);
    end;

    gsPlayingLoseAnimation: begin
      FPacman.State := psStoppedForEndOfGame;
      FBlinky.State := ghsStoppedForEndOfGame;
      FPinky.State := ghsStoppedForEndOfGame;
      FInky.State := ghsStoppedForEndOfGame;
      FClide.State := ghsStoppedForEndOfGame;
      Audio.StopFrightMode;
      Audio.StopSirenLoop;
      PostMessage(200);
    end;

    gsEndLoseAnimation: begin

    end;

    gsPlayingWinAnimation: begin
      FPacman.State := psStoppedForEndOfGame;
      FBlinky.State := ghsStoppedForEndOfGame;
      FPinky.State := ghsStoppedForEndOfGame;
      FInky.State := ghsStoppedForEndOfGame;
      FClide.State := ghsStoppedForEndOfGame;
      Audio.StopFrightMode;
      Audio.StopSirenLoop;
      PostMessage(100);
    end;

    gsEndWinAnimation: begin

    end;
  end;
end;

procedure TScreenGame.CreateObjects;
begin
  GameManager.InitForNextStage;

  // tile engine
  FMaze := TMaze.Create;

  // score and highscore
  FLabelHighScore := TLabelHighScore.Create(LAYER_UI);
  FLabelHighScore.SetCoordinate((FScene.Width-FLabelHighScore.Width)*0.5, 0);

  FScore := TScore.Create(LAYER_UI);
  FScore.RightX := FTileSize.cx*7;
  FScore.Y.Value := FTileSize.cy;
  FScore.Caption := GameManager.PlayerScore.ToString;

  FHighScore := THighScore.Create(LAYER_UI);
  FHighScore.CenterX := FTileSize.cx*TOTAL_H_TILE_COUNT*0.5;
  FHighScore.Y.Value := FTileSize.cy;


  // Life icons
  FLives := TLives.Create(LAYER_UI);
  // fruit icons
  FFruits := TFruits.Create(LAYER_UI);

  // player one
  FLabelPlayerOne := TLabelPlayerOne.Create(-1);
  FLabelPlayerOne.SetChildOf(FMaze, 1);
  FLabelPlayerOne.CenterX := FTileSize.cx*TOTAL_H_TILE_COUNT/2;
  FLabelPlayerOne.CenterY := FTileSize.cy*11.5;
  FLabelPlayerOne.Visible := False;

  // game over
  FLabelGameOver := TLabelGameOver.Create(-1);
  FLabelGameOver.SetChildOf(FMaze, 1);
  FLabelGameOver.CenterX := FTileSize.cx*TOTAL_H_TILE_COUNT/2;
  FLabelGameOver.CenterY := FTileSize.cy*11.5;
  FLabelGameOver.Visible := False;

  // ready
  FLabelReady := TLabelReady.Create(-1);
  FLabelReady.SetChildOf(FMaze, 1);
  FLabelReady.CenterX := FTileSize.cx*TOTAL_H_TILE_COUNT/2;
  FLabelReady.CenterY := FTileSize.cy*17.5;
  FLabelReady.Visible := False;

  // pause panel
  FPanelPause := TPanelPause.Create;

  // pacman
  FPacMan := TPacMan.Create;

  // ghosts
  FBlinky := TBlinky.Create;
  FBlinky.Visible := False;
  FPinky := TPinky.Create;
  FPinky.Visible := False;
  FInky := TInky.Create;
  FInky.Visible := False;
  FClide := TClide.Create;
  FClide.Visible := False;

  // fruit in maze
  FFruitInMaze := TFruitInMaze.Create;

  // managers
  FGhostHouseManager := TGhostHouseManager.Create;
  FrightManager := TFrightManager.Create;

  GameState := gsStartLevel;

  GameManager.ApplyRetroModeIfNeeded;

  debug := TFreeText.Create(FScene);
  FScene.Add(debug, LAYER_UI);
  debug.TexturedFont := texturedfontBonus;
end;

procedure TScreenGame.FreeObjects;
begin
  FScene.PostProcessing.StopEngine;
  FreeAndNil(FGhostHouseManager);
  FreeAndNil(FrightManager);
  FScene.ClearAllLayer;    // kill all surfaces on all layer
end;

procedure TScreenGame.Update(const AElapsedTime: single);
var threshold2: single;
  pacmanCenter: TPointF;
begin
  inherited Update(AElapsedTime);

  case GameState of
    gsRunning: begin
      if LeftKeyPressed then FPacman.GoLeft;
      if RightKeyPressed then FPacman.GoRight;
      if UpKeyPressed then FPacman.GoUp;
      if DownKeyPressed then FPacman.GoDown;

      if PauseKeyPressed then FPanelPause.Show;

      // ghost house manager
      FGhostHouseManager.Update(AElapsedTime);
      // Fright manager
      FrightManager.Update(AElapsedTime);

      // check collision pacman/fruit
      if FFruitInMaze.Fruit <> NIL then begin
        if Distance(FPacman.Center, FFruitInMaze.Center) < FTileSize.cx*0.75 then begin
          FFruitInMaze.ShowBonus;
          Audio.PlayEatFruit;
          IncrementScore(GameManager.GetFruitBonusPoint);
        end;
      end;

      // check collision pacman/ghost
      threshold2 := FHalfTileSize.cx * FHalfTileSize.cx;
      pacmanCenter := FPacman.Center;
      if not FrightManager.Enabled then begin
        if (FBlinky.CanKillPacman and (Distance2(pacmanCenter, FBlinky.Center) < threshold2)) or
           (FPinky.CanKillPacman and (Distance2(pacmanCenter, FPinky.Center) < threshold2)) or
           (FInky.CanKillPacman and (Distance2(pacmanCenter, FInky.Center) < threshold2)) or
           (FClide.CanKillPacman and (Distance2(pacmanCenter, FClide.Center) < threshold2))  then begin
          GameState := gsPlayingLoseAnimation;
          FGhostHouseManager.CallWhenLifeIsLost;
          exit;
        end;
      end else begin
        FGhostEaten := NIL;
        if FBlinky.CanBeEaten and (Distance2(pacmanCenter, FBlinky.Center) < threshold2) then FGhostEaten := FBlinky
        else
        if FPinky.CanBeEaten and (Distance2(pacmanCenter, FPinky.Center) < threshold2) then FGhostEaten := FPinky
        else
        if FInky.CanBeEaten and (Distance2(pacmanCenter, FInky.Center) < threshold2) then FGhostEaten := FInky
        else
        if FClide.CanBeEaten and (Distance2(pacmanCenter, FClide.Center) < threshold2) then FGhostEaten := FClide;
        if FGhostEaten <> NIL then begin
          GameState := gsEatGhostAnimation;
FPacMan.Freeze := True;
          exit;
        end;
      end;

      // play/stop sound ghost retreat
      if (FBlinky.State = ghsRetreatToHome) or
         (FPinky.State = ghsRetreatToHome) or
         (FInky.State = ghsRetreatToHome) or
         (FClide.State = ghsRetreatToHome)
        then Audio.PlayGhostRetreat
        else Audio.StopGhostRetreat;


      // Elroy level
      with GameManager do
        if (ElroyLevel = 0) and (DotEaten >= TOTAL_DOT_TO_EAT-GetElroy1DotsLeft) then begin
          ElroyLevel := 1;
          if not FrightManager.Enabled then Audio.PlaySirenLoop;
        end
        else
        if (ElroyLevel = 1) and (DotEaten >= TOTAL_DOT_TO_EAT-GetElroy2DotsLeft) then begin
          ElroyLevel := 2;
          if not FrightManager.Enabled then Audio.PlaySirenLoop;
        end;

        // check win game
        if GameManager.DotEaten = TOTAL_DOT_TO_EAT then
          GameState := gsPlayingWinAnimation;

// debug
debug.caption:='dot eat: '+GameManager.DotEaten.ToString+lineending;


    end;// gsRunning
  end;
end;

procedure TScreenGame.ProcessMessage(UserValue: TUserMessageValue);
var
  bonus: Integer;
begin
  case UserValue of
    // Start Level
    0: if GameManager.CurrentLevel = 1 then PostMessage(3, 0.5)
        else PostMessage(20, 0.5);
    3: begin
      Audio.PlayMusicBeginning;
      FLabelPlayerOne.Visible := True;
      FLabelReady.Visible := True;
      PostMessage(5, 2.0);
    end;
    5: begin
      FLabelPlayerOne.Visible := False;
      FPacman.Visible := True;
      FBlinky.Visible := True;
      FPinky.Visible := True;
      FInky.Visible := True;
      FClide.Visible := True;
      GameManager.PlayerLife := GameManager.PlayerLife - 1;
      PostMessage(10, 2.3);
    end;
    10: begin
      FLabelReady.Visible := False;
      FPacman.State := psRunning;
      FBlinky.State := ghsScatterMode;
      FPinky.State := ghsInHome;
      FInky.State := ghsInHome;
      FClide.State := ghsInHome;
      FMaze.StartBlinkSuperDots;
      GameState := gsRunning;
    end;
    20: begin  // from level2 and +
      FLabelReady.Visible := True;
      FPacman.Visible := True;
      FBlinky.Visible := True;
      FPinky.Visible := True;
      FInky.Visible := True;
      FClide.Visible := True;
      PostMessage(10, 2.0);
    end;


    // Playing win animation
    100: begin
      FPacman.FrameAddPerSecond(0);
      FPacman.Frame := 1;
      FBlinky.StopDressAnimation;
      FPinky.StopDressAnimation;
      FInky.StopDressAnimation;
      FClide.StopDressAnimation;
      FFruitInMaze.KillFruit;
      Audio.StopAllLoopedSounds;
      PostMessage(105, 2.0);
    end;
    105: begin
      FPacman.Visible := False;
      FBlinky.Visible := False;
      FPinky.Visible := False;
      FInky.Visible := False;
      FClide.Visible := False;
      FMazeFlashCount := 0;
      PostMessage(110);
    end;
    110: begin
      FMaze.Tint.Value := BGRA(255,255,255);
      PostMessage(115, 0.3);
    end;
    115: begin
      FMaze.Tint.Alpha.Value := 0;
      inc(FMazeFlashCount);
      if FMazeFlashCount < 3 then PostMessage(110, 0.3)
        else PostMessage(120, 1.0);
    end;
    120: begin
      GameManager.CurrentLevel := GameManager.CurrentLevel + 1;
      case GameManager.CurrentLevel of
        3, 6, 10, 18: FScene.RunScreen(ScreenIntermission);
        else FScene.RunScreen(ScreenGame, False);
      end;
    end;

    // gsPlayingLoseAnimation
    200: begin
      PostMessage(205, 1.0);
      FPacman.StopEatAnim;
      Audio.StopAllLoopedSounds;
      FPacman.Frame := 1;
      FPacman.Angle.Value := 0;
    end;
    205: begin
      FBlinky.Visible := False;
      FPinky.Visible := False;
      FInky.Visible := False;
      FClide.Visible := False;
      PostMessage(210, 1.0);
    end;
    210: begin
      Audio.PlaySoundDeath;
      FPacman.Frame := 4;
      PostMessage(215, 0.1);
    end;
    215: begin
      FPacman.Frame := FPacman.Frame + 1;
      if FPacman.Frame < 14 then PostMessage(215, 0.1)
        else PostMessage(220, 0.1);
    end;
    220: begin
      FPacman.Visible := False;
      FFruitInMaze.KillFruit;
      if GameManager.PlayerLife = 0 then PostMessage(300, 1.0)
        else PostMessage(225, 1.0);
    end;
    225: begin // decrease life and continue level
      GameManager.PlayerLife := GameManager.PlayerLife - 1;
      FBlinky.State := ghsWaitingBeginOfGame;
      FPinky.State := ghsWaitingBeginOfGame;
      FInky.State := ghsWaitingBeginOfGame;
      FClide.State := ghsWaitingBeginOfGame;
      FPacman.State := psWaitingBeginOfGame;
      GameManager.InitAfterLoseLife;
      PostMessage(20);
    end;

    // GAME OVER
    300: begin
      FLabelGameOver.Visible := True;
      PostMessage(305, 3.0);
    end;
    305: begin
      FScene.RunScreen(ScreenMainMenu);
    end;

    // GHOST EATEN
    400: begin  // 1s freeze
      Audio.PlayEatGhost;
      FGhostEaten.Visible := False;
      FPacman.Visible := False;
      bonus := GameManager.GetBonusGhostEaten;
      FGhostEaten.ShowGhostEatenBonus(bonus);
      IncrementScore(bonus);
      FPacman.Freeze := True;
      FBlinky.Freeze := True;
      FPinky.Freeze := True;
      FInky.Freeze := True;
      FClide.Freeze := True;
      PostMessage(405, 1.0);
    end;
    405: begin
      FGhostEaten.Visible := True;
      FPacman.Visible := True;
      FPacman.Freeze := False;
      FBlinky.Freeze := False;
      FPinky.Freeze := False;
      FInky.Freeze := False;
      FClide.Freeze := False;
      FGhostEaten.State := ghsRetreatToHome;
      GameState := gsRunning;
    end;
  end;//case
end;

procedure TScreenGame.IncrementScore(aDelta: integer);
begin
  GameManager.PlayerScore := GameManager.PlayerScore + aDelta;    // add bonus to score
  Score.Caption := GameManager.PlayerScore.ToString;   // update score
  HighScore.Caption := GameManager.HighScore.ToString; // update highscore

  if GameManager.NeedToAddExtraLife then begin
    Audio.PlayExtraLife;
    GameManager.PlayerLife := GameManager.PlayerLife + 1;
    // sprite extra life is auto-updated
  end;
end;


end.

