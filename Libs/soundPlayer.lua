local currentFolder = (...):gsub(".soundPlayer", "")

local device = require(currentFolder..".device")
local audio = _G.audio

-- SoundPlayer ---------------------------------------------------------------------------------------------------------
local SoundPlayer = {}
local soundTable       = {}
local playTimeRegistry = {}
local eventSoundTable  = {}

local volume = 1
local paused = false

local path = "Assets/Audio/"
if device.isAndroid and not device.isSimulator then
  path = path .. ""
  SoundPlayer.defExt = ".ogg"
else
  path = path .. ""
  SoundPlayer.defExt = ".aac"
end

SoundPlayer.folder = path..""


-- Helpers -------------------------------------------------------------------------------------------------------------

local function newAudioCallback(onComplete, onCancel)
  if not onComplete and not onCancel then return end

  return function(e)
    if e.completed then
      if onComplete then onComplete() end
    else
      if onCancel then onCancel() end
    end
  end
end

-- Media implementation ------------------------------------------------------------------------------------------------
-- NOTE: Sometimes `media` works better on Android for sounds that needs to be played without any delay. (Like the sfx of a gun)
-- BUT, media does not have any volume control, so it plays if the volumes is over .2, and is ignored otherwise.

local function loadWithMedia(sound, ext)
  if eventSoundTable[sound] then return false end

  ext = ext or SoundPlayer.defExt
  eventSoundTable[sound] = media.newEventSound(SoundPlayer.folder..sound..ext)
  if not eventSoundTable[sound] then
    error( "not sound", sound )
  end
end


local function playWithMedia(sound)
  if volume < .2 then return end

  if not eventSoundTable[sound] then
    eventSoundTable[sound] = media.newEventSound(SoundPlayer.folder..sound..SoundPlayer.defExt)
  end

  return media.playEventSound(eventSoundTable[sound])
end

-- track information ---------------------------------------------------------------------------------------------------

function SoundPlayer.getDuration(sound)
  if not soundTable[sound] then return -1 end

  return audio.getDuration( soundTable[sound] )
end

-- Sfx -----------------------------------------------------------------------------------------------------------------

local function canPlay(sound)
  return system.getTimer() - (playTimeRegistry[sound] or 0) > 80
end


function SoundPlayer.load(sound, ext, useMediaForAndroid)
  if soundTable[sound] then return end

  if useMediaForAndroid and device.isAndroid and not device.isSimulator then
    return loadWithMedia(sound)
  end

  ext = ext or SoundPlayer.defExt
  soundTable[sound] = audio.loadSound(SoundPlayer.folder..sound..ext)

  assert(soundTable[sound], "Can't load sound: \""..sound..ext.."\"" )
end


function SoundPlayer.play(sound, params)
  if paused or not canPlay(sound) then return end
  playTimeRegistry[sound] = system.getTimer()

  params = params or {}
  params.onComplete = newAudioCallback(params.onComplete, params.onCancel)

  if eventSoundTable[sound] then
    return playWithMedia(sound)
  end

  if not soundTable[sound] then
    soundTable[sound] = audio.loadSound(SoundPlayer.folder..sound..(params.ext or SoundPlayer.defExt))
  end

  return audio.play(soundTable[sound], params)
end

-- Volume control ------------------------------------------------------------------------------------------------------

function SoundPlayer.setVolume(v)
  volume = volume
  for i = 3, 32 do
    audio.setVolume(v, {channel = i})
  end
end


function SoundPlayer.mute()
  SoundPlayer.setVolume(0)
end


-- Flow control --------------------------------------------------------------------------------------------------------

function SoundPlayer.resume()
  if not paused then return end
  paused = false

  for i = 3, 32 do
    if audio.isChannelActive(i) then
      audio.resume(i)
    end
  end
end


function SoundPlayer.pause()
  if paused then return end

  paused = true
  for i = 3, 32 do
    if audio.isChannelActive(i) then
      audio.pause(i)
    end
  end
end


function SoundPlayer.stop()
  paused = false

  for i = 3, 32 do
    if audio.isChannelActive(i) then
      audio.stop(i)
    end
  end
end


-- Game state observer -------------------------------------------------------------------------------------------------

local function volumeEvent(_, e)
  SoundPlayer.setVolume(e.value)
end


function SoundPlayer.setState(state)
  state:observe("sfxVolume", SoundPlayer, volumeEvent, true)
end


return SoundPlayer
