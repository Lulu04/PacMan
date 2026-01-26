unit screen_mainmenu;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common, u_sprite_def, u_sprite_title;


type


{ TScreenMainMenu }

TScreenMainMenu = class(TScreenTemplate)
private
  FTitle: TTitle;
  FPanel: TPanelMainMenu;
  //FPanelOptions: TPanelOptions;

public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure Update(const AElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;

  procedure ShowOptionsPanel;
  procedure HideOptionsPanel;
end;

var ScreenMainMenu: TScreenMainMenu = NIL;

implementation
uses u_sprite_presentation, u_game_manager;

type

{ TAnimation }

TAnimation = class(TPresentation)
private
  FPacManSpeed: single;
  procedure SetAllChildsNotVisible;
public
  constructor Create;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

var FPresentation: TAnimation;

{ TAnimation }

procedure TAnimation.SetAllChildsNotVisible;
var i: integer;
begin
  for i:=0 to ChildCount-1 do
    Childs[i].Visible := False;
end;

constructor TAnimation.Create;
begin
  inherited Create(LAYER_UI);

  // all child not visible
  SetAllChildsNotVisible;
  PostMessage(0, 0.5); // start anim
end;

procedure TAnimation.ProcessMessage(UserValue: TUserMessageValue);
  procedure VisibleSmallDelay(aSurface: TSimpleSurfaceWithEffect; aUserMess: TUserMessageValue; aDelay: single=0.5);
  begin
    aSurface.Visible := True;
    PostMessage(aUserMess, aDelay);
  end;
begin
  case UserValue of
    0: VisibleSmallDelay(FreeText1, 5);
    5: VisibleSmallDelay(Ghost1, 10, 1.0);
    10: VisibleSmallDelay(FreeText2, 15);
    15: VisibleSmallDelay(FreeText3, 20);
    20: VisibleSmallDelay(Ghost2, 25, 1.0);
    25: VisibleSmallDelay(FreeText4, 30);
    30: VisibleSmallDelay(FreeText5, 35);
    35: VisibleSmallDelay(Ghost3, 40, 1.0);
    40: VisibleSmallDelay(FreeText6, 45);
    45: VisibleSmallDelay(FreeText7, 50);
    50: VisibleSmallDelay(Ghost4, 55, 1.0);
    55: VisibleSmallDelay(FreeText8, 60);
    60: VisibleSmallDelay(FreeText9, 65);
    65: begin
      Dot.Visible := True;
      FreeText10.Visible := True;
      SuperDot1.Visible := True;
      FreeText12.Visible := True;
      PostMessage(70, 0.5);
    end;
    70: VisibleSmallDelay(SuperDot2, 75);
    75: begin  // pacman and ghost appear
      SuperDot1.Blink(-1, 0.25, 0.25);
      SuperDot2.Blink(-1, 0.25, 0.25);
      PacMan.SetFrameLoopBounds(1, 3);
      PacMan.FrameAddPerSecond(18);
      PacMan.Visible := True;
      PacMan.Speed.X.Value := -(PacMan.X.Value-SuperDot2.CenterX) / 3.0;
      Blinky.Visible := True;
      Blinky.SetFrameLoopBounds(1, 2);
      Blinky.FrameAddPerSecond(7);
      Blinky.Speed.X.Value := PacMan.Speed.X.Value*1.15;
      GhostMouthEye.Visible := False;
      GhostEyeLeft.Visible := True;
      Pinky.Visible := True;
      Pinky.SetFrameLoopBounds(1, 2);
      Pinky.FrameAddPerSecond(7);
      Pinky.Speed.X.Value := Blinky.Speed.X.Value;
      GhostMouthEye1.Visible := False;
      GhostEyeLeft1.Visible := True;
      Inky.Visible := True;
      Inky.SetFrameLoopBounds(1, 2);
      Inky.FrameAddPerSecond(7);
      Inky.Speed.X.Value := Blinky.Speed.X.Value;
      GhostMouthEye2.Visible := False;
      GhostEyeLeft2.Visible := True;
      Clyde.Visible := True;
      Clyde.SetFrameLoopBounds(1, 2);
      Clyde.FrameAddPerSecond(7);
      Clyde.Speed.X.Value := Blinky.Speed.X.Value;
      GhostMouthEye3.Visible := False;
      GhostEyeLeft3.Visible := True;
      PostMessage(77);
    end;
    77: begin // check collision pacman/dot
      if PacMan.X.Value > SuperDot2.CenterX then PostMessage(77)
        else PostMessage(80);
    end;
    80: begin // pacman eat the super dot
      SuperDot2.StopBlink;
      SuperDot2.Visible := False;
      PacMan.FlipH := False;
      PacMan.Speed.X.Value := -PacMan.Speed.X.Value*1.5;
      FPacManSpeed := PacMan.Speed.X.Value;
      Blinky.Tint.Value := BGRA(33,33,255);
      GhostEyeLeft.Visible := False;
      GhostMouthEye.Visible := True;
      Blinky.Speed.X.Value := -Blinky.Speed.X.Value*0.6;
      Pinky.Tint.Value := BGRA(33,33,255);
      GhostEyeLeft1.Visible := False;
      GhostMouthEye1.Visible := True;
      Pinky.Speed.X.Value := Blinky.Speed.X.Value;
      Inky.Tint.Value := BGRA(33,33,255);
      GhostEyeLeft2.Visible := False;
      GhostMouthEye2.Visible := True;
      Inky.Speed.X.Value := Blinky.Speed.X.Value;
      Clyde.Tint.Value := BGRA(33,33,255);
      GhostEyeLeft3.Visible := False;
      GhostMouthEye3.Visible := True;
      Clyde.Speed.X.Value := Blinky.Speed.X.Value;
      PostMessage(85);
    end;
    85: begin // check collision pacman/blinky
      if PacMan.CenterX < Blinky.X.Value then PostMessage(85)
        else begin
          Blinky.Speed.X.Value := 0;
          Blinky.Visible := False;
          PacMan.Visible := False;
          PacMan.Freeze := True;
          Pinky.Freeze := True;
          Inky.Freeze := True;
          Clyde.Freeze := True;
          LabelBonus.Caption := '200';
          LabelBonus.CenterX := Blinky.CenterX;
          LabelBonus.Visible := True;
          PostMessage(90, 1.0);
        end;
    end;
    90: begin
      LabelBonus.Visible := False;
      PacMan.Visible := True;
      PacMan.Freeze := False;
      Pinky.Freeze := False;
      Inky.Freeze := False;
      Clyde.Freeze := False;
      PostMessage(95);
    end;
    95: begin // check collision pacman/pinky
      if PacMan.CenterX < Pinky.X.Value then PostMessage(95)
        else begin
          Pinky.Speed.X.Value := 0;
          Pinky.Visible := False;
          PacMan.Visible := False;
          PacMan.Freeze := True;
          Inky.Freeze := True;
          Clyde.Freeze := True;
          LabelBonus.Caption := '400';
          LabelBonus.CenterX := Pinky.CenterX;
          LabelBonus.Visible := True;
          PostMessage(100, 1.0);
        end;
    end;
    100: begin
      LabelBonus.Visible := False;
      PacMan.Visible := True;
      PacMan.Freeze := False;
      Inky.Freeze := False;
      Clyde.Freeze := False;
      PostMessage(105);
    end;
    105: begin // check collision pacman/inky
      if PacMan.CenterX < Inky.X.Value then PostMessage(105)
        else begin
          Inky.Speed.X.Value := 0;
          Inky.Visible := False;
          PacMan.Visible := False;
          PacMan.Freeze := True;
          Clyde.Freeze := True;
          LabelBonus.Caption := '800';
          LabelBonus.CenterX := Inky.CenterX;
          LabelBonus.Visible := True;
          PostMessage(110, 1.0);
        end;
    end;
    110: begin
      LabelBonus.Visible := False;
      PacMan.Visible := True;
      PacMan.Freeze := False;
      Clyde.Freeze := False;
      PostMessage(115);
    end;
    115: begin // check collision pacman/clyde
      if PacMan.CenterX < Clyde.X.Value then PostMessage(115)
        else begin
          Clyde.Speed.X.Value := 0;
          Clyde.Visible := False;
          PacMan.Visible := False;
          PacMan.Freeze := True;
          LabelBonus.Caption := '1600';
          LabelBonus.CenterX := Clyde.CenterX;
          LabelBonus.Visible := True;
          PostMessage(120, 1.0);
        end;
    end;
    120: begin
      LabelBonus.Visible := False;
      SuperDot1.StopBlink;
      PacMan.FrameAddPerSecond(0);
      PacMan.Frame := 2;
      PacMan.Freeze := False;
      PacMan.Speed.X.Value := 0;
      PostMessage(125, 2.0);
    end;
    125: begin // re-initialize and re-start the anim
      PacMan.Visible := True;
      PacMan.SetCoordinate(14.063*PacMan.Width, 6.507*PacMan.Height);
      PacMan.FlipH := True;
      Blinky.SetCoordinate(16.406*Blinky.Width, 6.507*Blinky.Height);
      Blinky.Tint.Value := BGRA(255,0,0);
      GhostMouthEye.Visible := False;
      GhostEyeLeft.Visible := True;
      Pinky.SetCoordinate(17.406*Pinky.Width, 6.507*Pinky.Height);
      Pinky.Tint.Value := BGRA(255,184,255);
      GhostMouthEye1.Visible := False;
      GhostEyeLeft1.Visible := True;
      Inky.SetCoordinate(18.406*Inky.Width, 6.507*Inky.Height);
      Inky.Tint.Value := BGRA(0,255,255);
      GhostMouthEye2.Visible := False;
      GhostEyeLeft2.Visible := True;
      Clyde.SetCoordinate(19.406*Clyde.Width, 6.507*Clyde.Height);
      Clyde.Tint.Value := BGRA(255,184,81);
      GhostMouthEye2.Visible := False;
      GhostEyeLeft2.Visible := True;
      SetAllChildsNotVisible;
      PostMessage(0, 2.0);
    end;

  end;
end;

{ TScreenMainMenu }

procedure TScreenMainMenu.CreateObjects;
begin
  FTitle := TTitle.Create(LAYER_UI);
  FTitle.CenterX := FScene.Center.x;

  FPresentation := TAnimation.Create;
  FPresentation.Y.Value := FTitle.BottomY;

  FPanel := TPanelMainMenu.Create;
  FPanel.Show('');

  FPanelOptions := TPanelOptions.Create;

  GameManager.ApplyRetroModeIfNeeded;
end;

procedure TScreenMainMenu.FreeObjects;
begin
  FScene.PostProcessing.StopEngine;
  FScene.ClearAllLayer;
end;

procedure TScreenMainMenu.Update(const AElapsedTime: single);
begin
  inherited Update(AElapsedTime);
end;

procedure TScreenMainMenu.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);
end;

procedure TScreenMainMenu.ShowOptionsPanel;
begin
  FPanel.MouseInteractionEnabled := False;
  FPanelOptions.ShowModal(scenarioPanelZoomIN);
end;

procedure TScreenMainMenu.HideOptionsPanel;
begin
  FPanel.MouseInteractionEnabled := True;
  FPanelOptions.Hide(scenarioPanelZoomOUT, False);
end;

end.

