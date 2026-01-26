unit screen_intermission;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common, u_sprite_def, u_sprite_ghostworm;

type


{ TScreenIntermission }

TScreenIntermission = class(TScreenTemplate)
private
  FPacMan: TPacMan;
  FBlinky: TBlinky;
  FFruits: TFruits;
  FObstacle: TQuad4Color;
  FGhostWorm: TGhostWorm;
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

var ScreenIntermission: TScreenIntermission = NIL;



implementation

uses u_game_manager, u_audio, screen_game;

{ TScreenIntermission }

procedure TScreenIntermission.CreateObjects;
begin
  FPacMan := TPacMan.Create(LAYER_MAZE);
  FBlinky := TBlinky.Create(LAYER_MAZE);
  FFruits := TFruits.Create(LAYER_MAZE);
  FGhostWorm := TGhostWorm.Create(LAYER_MAZE);
  FGhostWorm.Visible := False;

 { case GameManager.CurrentLevel of
    3: PostMessage(0);    // first anim before level 3
    6: PostMessage(100);  // second anim before level 6
   10, 18: PostMessage(200);  // third anim before level 10 and 18
   else FScene.RunScreen(ScreenGame);
  end;  }
PostMessage(200);

  GameManager.ApplyRetroModeIfNeeded;
end;

procedure TScreenIntermission.FreeObjects;
begin
  FScene.PostProcessing.StopEngine;
  FScene.ClearAllLayer;
end;

procedure TScreenIntermission.ProcessMessage(UserValue: TUserMessageValue);
var
  yy, xx: Single;
begin
  case UserValue of
    // first intersession animation
    0: begin
      FPacMan.FlipH := True;
      FPacMan.SetCenterCoordinate(FScene.Width+FPacMan.Width, FScene.Height*0.55);
      FPacMan.X.ChangeTo(-FPacMan.Width*2, 3.8);
      FPacMan.StartEatAnim;
      FBlinky.SetCenterCoordinate(FPacMan.RightX + FScene.Width/10, FPacMan.CenterY);
      FBlinky.Direction := dLeft;
      FBlinky.SetNormalMode;
      FBlinky.StartDressAnimation;
      FBlinky.X.ChangeTo(-FBlinky.BodyWidth*2, 4.1);
      Audio.PlayMusicIntermission;
      PostMessage(5, 4+1);
    end;
    5: begin
      FPacMan.FlipH := False;
      FPacMan.X.Value := -FScene.Width*0.7;
      FPacMan.SetSize(FPacMan.Width*4, FPacMan.Height*4);
      FPacMan.BottomY := FBlinky.BodyBottomY;
      FPacMan.X.ChangeTo(FScene.Width+FPacMan.Width*FPacMan.Scale.X.Value, 5.0);
      FBlinky.X.Value := -FBlinky.BodyWidth;
      FBlinky.Direction := dRight;
      FBlinky.SetFrightMode;
      FBlinky.X.ChangeTo(FScene.Width+FBlinky.BodyWidth, 3.8);
      PostMessage(1000, 5.5); // run game
    end;

    // second intersession animation
    100: begin
      FPacMan.FlipH := True;
      FPacMan.SetCenterCoordinate(FScene.Width+FPacMan.Width, FScene.Height*0.55);
      FPacMan.X.ChangeTo(-FPacMan.Width*2, 3.8);
      FPacMan.StartEatAnim;
      FBlinky.SetCenterCoordinate(FPacMan.RightX + FScene.Width/4, FPacMan.CenterY);
      FBlinky.Direction := dLeft;
      FBlinky.SetNormalMode;
      FBlinky.StartDressAnimation;
      FBlinky.X.ChangeTo(-FBlinky.BodyWidth*2, 4.1);
      FObstacle := TQuad4Color.Create(FScene);
      FScene.Insert(0, FObstacle, LAYER_MAZE);
      FObstacle.SetAllColorsTo(BGRAWhite);
      FObstacle.SetSize(ScaleW(2), FBlinky.BodyHeight div 3);
      FObstacle.BottomY := FPacMan.BottomY-FBlinky.BodyHeight*0.1;
      FObstacle.X.Value := FScene.Width*0.57;
      Audio.PlayMusicIntermission;
      PostMessage(105);
    end;
    105: begin // check collision blinky/obstacle
      if FBlinky.DressRight > FObstacle.X.Value then PostMessage(105)
        else begin
          FBlinky.X.ChangeTo(FObstacle.X.Value-FBlinky.BodyWidth*1.05, 1.7, idcStartFastEndSlow);
          FBlinky.DressStretched.Visible := True;
          FBlinky.DressStretched.Freeze := False;
          FBlinky.DressStretched.X.ChangeTo(FBlinky.DressStretched.Width*0.2, 1.7, idcStartFastEndSlow);
          PostMessage(110, 1.7);
        end;
    end;
    110: begin
      FBlinky.StopDressAnimation;
      yy := FBlinky.DressStretched.BottomY;
      xx := FBlinky.DressStretched.RightX;
      FBlinky.DressStretched.SetSize(FBlinky.DressStretched.Width div 2, FBlinky.DressStretched.Height div 2);
      FBlinky.DressStretched.BottomY := yy;
      FBlinky.DressStretched.RightX := xx;
      FBlinky.GhostLeg.Visible := True;
      FBlinky.GhostLeg.Freeze := False;
      PostMessage(115, 1.25);
    end;
    115: begin
      FBlinky.GhostEyeLeft.Visible := False;
      FBlinky.GhostEyeUp.Visible := True;
      PostMessage(120, 1.25);
    end;
    116: begin
      FBlinky.GhostLeg.Angle.Value := -2;
      PostMessage(117, 0.3);
    end;
    117: begin
      FBlinky.GhostLeg.Angle.Value := 2;
      PostMessage(116, 0.3);
    end;
    120: begin
      FBlinky.GhostEyeUp.Visible := False;
      FBlinky.GhostEyeRight.Visible := True;
      PostMessage(116);
      PostMessage(1000, 3.0);
    end;

    // third intermission animation
    200: begin
      FPacMan.FlipH := True;
      FPacMan.SetCenterCoordinate(FScene.Width+FPacMan.Width, FScene.Height*0.55);
      FPacMan.X.ChangeTo(-FPacMan.Width*2, 3.8);
      FPacMan.StartEatAnim;
      FBlinky.SetCenterCoordinate(FPacMan.RightX + FScene.Width/10, FPacMan.CenterY);
      FBlinky.Direction := dLeft;
      FBlinky.SetDressRepeared;
      FBlinky.StartDressAnimation;
      FBlinky.X.ChangeTo(-FBlinky.BodyWidth*2, 4.1);
      Audio.PlayMusicIntermission;
      PostMessage(205, 4+1);
    end;
    205: begin
      FGhostWorm.SetSize(Round(FGhostWorm.Width*1.2), Round(FGhostWorm.Height*1.2));
      FGhostWorm.Visible := True;
      FGhostWorm.Y.Value := FPacMan.Y.Value;
      FGhostWorm.X.Value := -FGhostWorm.Width;
      FGhostWorm.X.ChangeTo(FScene.Width, 4.5);
      FGhostWorm.SetFrameLoopBounds(1, 2);
      FGhostWorm.FrameAddPerSecond(6);
      PostMessage(1000, 4.5);
    end;

    1000: FScene.RunScreen(ScreenGame);
  end;
end;

end.

