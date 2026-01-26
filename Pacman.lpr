program Pacman;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, form_main, u_common, screen_game, u_sprite_title, u_sprite_baseghost,
  u_sprite_basepacman, u_sprite_labelhighscore, u_sprite_basehighscore,
  u_sprite_score, u_sprite_labelplayerone, u_sprite_labelgameover,
  u_sprite_presentation, u_sprite_ghostworm, u_panel_basepause,
  u_panel_baseoptions, lazopenglcontext, u_sprite_def, u_game_manager, u_audio,
  screen_mainmenu, screen_intermission
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.

