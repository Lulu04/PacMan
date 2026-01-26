unit u_audio;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  ALSound;

type

TALSSound = ALSound.TALSSound;

{ TAudioManager }

TAudioManager = class
private
  FPlayback: TALSPlaybackContext;
  FsndChomp23, FsndChomp25, FsndChomp27,
  FsndEatGhost,
  FsndSirenLoop,
  FsndFrightmode,
  FsndGhostRetreat: TALSSound;
  function AddSound(const aFilenameWithoutPath: string): TALSSound; overload;
  procedure LoadSounds;
public
  constructor Create;
  destructor Destroy; override;

  procedure PlayMusicBeginning;
  procedure PlayMusicIntermission;
  // take in acount GameManager.ElroyLevel [0..2]
  procedure PlaySirenLoop;
  procedure StopSirenLoop;
  procedure PlaySoundChomp;
  procedure PlaySoundDeath;
  procedure PlayEatFruit;
  procedure PlayEatGhost;
  procedure PlayExtraLife;
  procedure PlayFrightMode;
  procedure StopFrightMode;
  procedure PlayGhostRetreat;
  procedure StopGhostRetreat;

  procedure StopAllLoopedSounds;
  procedure PauseAllPlayingSounds;
  procedure ResumeAllPausedSounds;
end;

var Audio: TAudioManager;

implementation

uses Forms, u_common, u_game_manager, OGLCScene, ctypes;

var AudioLogFile: TLog = NIL;

procedure ProcessLogMessageFromALSoft({%H-}aUserPtr: pointer; aLevel: char; aMessage: PChar; {%H-}aMessageLength: cint);
begin
  if AudioLogFile <> NIL then
    case aLevel of
      'I': AudioLogFile.Info(StrPas(aMessage));
      'W': AudioLogFile.Warning(StrPas(aMessage));
      'E': AudioLogFile.Error(StrPas(aMessage));
      else AudioLogFile.Warning(StrPas(aMessage));
    end;
end;


{ TAudioManager }

function TAudioManager.AddSound(const aFilenameWithoutPath: string): TALSSound;
begin
  Result := FPlayback.AddSound(AudioFolder + aFilenameWithoutPath);
end;

procedure TAudioManager.LoadSounds;
begin
  FsndSirenLoop := FPlayback.AddSound(AudioFolder+'pacman_sirenloop.ogg');
  FsndSirenLoop.Loop := True;
  FsndSirenLoop.Volume.Value := 0.6;

  FsndChomp23 := FPlayback.AddSound(AudioFolder+'pacman_chomp23.ogg');
  FsndChomp25 := FPlayback.AddSound(AudioFolder+'pacman_chomp25.ogg');
  FsndChomp27 := FPlayback.AddSound(AudioFolder+'pacman_chomp27.ogg');

  FsndEatGhost := FPlayback.AddSound(AudioFolder+'pacman_eatghost.ogg');

  FsndFrightmode := FPlayback.AddSound(AudioFolder+'Fright.ogg');
  FsndFrightmode.Loop := True;

  FsndGhostRetreat := FPlayback.AddSound(AudioFolder+'ghost_retreat.ogg');
  FsndGhostRetreat.Loop := True;
end;

constructor TAudioManager.Create;
begin
  AudioLogFile := OGLCScene.TLog.Create(IncludeTrailingPathdelimiter(Application.Location)+'alsound.log',NIL, NIL);
  AudioLogFile.DeleteLogFile;
  ALSManager.SetOpenALSoftLogCallback(@ProcessLogMessageFromALSoft, NIL);

  ALSManager.SetLibrariesSubFolder(FScene.App.ALSoundLibrariesSubFolder);
  ALSManager.LoadLibraries;
  FPlayback := ALSManager.CreateDefaultPlaybackContext;

  LoadSounds;
end;

destructor TAudioManager.Destroy;
begin
  FreeAndNil(FPlayback);
  FreeAndNil(AudioLogFile);
  inherited Destroy;
end;

procedure TAudioManager.PlayMusicBeginning;
begin
  with FPlayback.AddSound(AudioFolder+'pacman_beginning.ogg') do
   PlayThenKill(True);
end;

procedure TAudioManager.PlayMusicIntermission;
begin
  with FPlayback.AddSound(AudioFolder+'pacman_intermission.ogg') do
    PlayThenKill(True);
end;

procedure TAudioManager.PlaySirenLoop;
begin
  case GameManager.ElroyLevel of
    0: FsndSirenLoop.Pitch.Value := 1.0;
    1: FsndSirenLoop.Pitch.Value := 1.2;
    2: FsndSirenLoop.Pitch.Value := 1.4;
  end;
  FsndSirenLoop.Play(False);
end;

procedure TAudioManager.StopSirenLoop;
begin
  FsndSirenLoop.Stop;
end;

procedure TAudioManager.PlaySoundChomp;
begin
  case GameManager.CurrentLevel of
    1: FsndChomp27.Play(False); // MaxSpeed*0.8;
    2,3,4: FsndChomp25.Play(False); // MaxSpeed*0.9;
    5..20: FsndChomp23.Play(False); // MaxSpeed;
    else FsndChomp25.Play(False); // MaxSpeed*0.9;
  end;
end;

procedure TAudioManager.PlaySoundDeath;
begin
  with FPlayback.AddSound(AudioFolder+'pacman_death.ogg') do
   PlayThenKill(True);
end;

procedure TAudioManager.PlayEatFruit;
begin
  with FPlayback.AddSound(AudioFolder+'pacman_eatfruit.ogg') do
   PlayThenKill(True);
end;

procedure TAudioManager.PlayEatGhost;
begin
  FsndEatGhost.Play(True);
end;

procedure TAudioManager.PlayExtraLife;
begin
  with FPlayback.AddSound(AudioFolder+'pacman_extrapac.ogg') do
   PlayThenKill(True);
end;

procedure TAudioManager.PlayFrightMode;
begin
  FsndFrightmode.Play(True);
end;

procedure TAudioManager.StopFrightMode;
begin
  FsndFrightmode.Stop;
end;

procedure TAudioManager.PlayGhostRetreat;
begin
  if FsndGhostRetreat.State = ALS_STOPPED then
    FsndGhostRetreat.Play(True);
end;

procedure TAudioManager.StopGhostRetreat;
begin
  FsndGhostRetreat.Stop;
end;

procedure TAudioManager.StopAllLoopedSounds;
begin
  StopSirenLoop;
  StopFrightMode;
  StopGhostRetreat;
end;

procedure TAudioManager.PauseAllPlayingSounds;
begin
  if FsndEatGhost.State = ALS_PLAYING  then FsndEatGhost.Pause;
  if FsndSirenLoop.State = ALS_PLAYING  then FsndSirenLoop.Pause;
  if FsndFrightmode.State = ALS_PLAYING  then FsndFrightmode.Pause;
  if FsndGhostRetreat.State = ALS_PLAYING  then FsndGhostRetreat.Pause;
end;

procedure TAudioManager.ResumeAllPausedSounds;
begin
  if FsndEatGhost.State = ALS_PAUSED  then FsndEatGhost.Play(False);
  if FsndSirenLoop.State = ALS_PAUSED  then FsndSirenLoop.Play(False);
  if FsndFrightmode.State = ALS_PAUSED  then FsndFrightmode.Play(False);
  if FsndGhostRetreat.State = ALS_PAUSED  then FsndGhostRetreat.Play(False);
end;

end.

