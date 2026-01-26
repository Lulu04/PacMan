unit screen_intersession;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common, u_sprite_def;

type


{ TScreenIntersession }

TScreenIntersession = class(TScreenTemplate)
private
  FPacMan: TPacMan;
  FBlinky: TBlinky;
  FFruits: TFruits;
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure Update(const AElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

var ScreenIntersession: TScreenIntersession = NIL;



implementation

uses u_game_manager, u_audio, screen_game;

{ TScreenIntersession }

procedure TScreenIntersession.CreateObjects;
begin
  FPacMan := TPacMan.Create(LAYER_MAZE);
  FBlinky := TBlinky.Create(LAYER_MAZE);
  FFruits := TFruits.Create(LAYER_MAZE);

  case GameManager.CurrentLevel of
    3: PostMessage(0);    // first anim
  end;
end;

procedure TScreenIntersession.FreeObjects;
begin
  FScene.ClearAllLayer;
end;

procedure TScreenIntersession.Update(const AElapsedTime: single);
begin
  inherited Update(AElapsedTime);
end;

procedure TScreenIntersession.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // first intersession animation
    0: begin
      FPacMan.FlipH := True;
      FPacMan.SetCoordinate(FScene.Width, FScene.Height*0.55);
      FPacMan.X.ChangeTo(-FPacMan.Width*2, 3.8);
      FPacMan.StartEatAnim;
      FBlinky.SetCoordinate(FPacMan.RightX + FScene.Width/15, FPacMan.Y.Value);
      FBlinky.Direction := dLeft;
      FBlinky.SetNormalMode;
      FBlinky.StartDressAnimation;
      FBlinky.X.ChangeTo(-FBlinky.Width*2, 3.9);
      Audio.PlayMusicBeginning;
      PostMessage(1000, 4.8); // repeat music
      PostMessage(5, 4+1);
    end;
    5: begin
      FPacMan.FlipH := False;
      FPacMan.X.Value := -FScene.Width*0.5;
      FPacMan.SetSize(FPacMan.Width*4, FPacMan.Height*4);
      FPacMan.BottomY := FBlinky.BottomY;
      FPacMan.X.ChangeTo(FScene.Width, 3.9);
      FBlinky.X.Value := -FBlinky.Width;
      FBlinky.Direction := dRight;
      FBlinky.SetFrightMode;
      FBlinky.X.ChangeTo(FScene.Width, 3.9);
      PostMessage(1100, 5.5);
    end;

    1000: Audio.PlayMusicBeginning;
    1100: FScene.RunScreen(ScreenGame);
  end;
end;

end.

