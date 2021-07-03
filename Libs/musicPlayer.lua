local audio = _G.audio

local currentFolder = (...):gsub(".musicPlayer", "")
local device = require(currentFolder..".device")
local Tween = require(currentFolder..".tween")

------------------------------------------------------------------------------------------------------------------------
-- MusicPlayer --
------------------------------------------------------------------------------------------------------------------------

local MusicPlayer = {}

local path = "Assets/Audio/"
if device.isAndroid and not device.isSimulator then
  path = path .. ""
  MusicPlayer.defExt = ".ogg"
else
  path = path .. ""
  MusicPlayer.defExt = ".aac"
end
MusicPlayer.folder = path..""


local tracks = {}

audio.reserveChannels(2)
-- 1. Music
-- 2. Music fade channel

local musicChannel = 1
local musicSequence
local onSequenceComplete
local predefinedSequences
local seqIndex

-- Helpers -------------------------------------------------------------------------------------------------------------
local channels = {
  Tween:new(1, easing.inQuad, 1, {
    onUpdate = function(v)
      audio.setVolume(v, {channel = 1})
    end,
  }),
  Tween:new(1, easing.inQuad, 1, {
    onUpdate = function(v)
      audio.setVolume(v, {channel = 2})
    end,
  })
}

local masterVolume = Tween:new(1, nil, 1, {
  onUpdate = function(v)
    channels[1]:setScale(v)
    channels[2]:setScale(v)
  end,
})


local function channelFadeIn(ch, time)
  channels[ch]:setDelta(0)
  channels[ch]:transitionTo{
    time  = time,
    value = 1,
  }
end


local function channelFadeOut(ch, time)
  local cb = function()
    audio.stop(ch)
    timer.performWithDelay(0, function()
      channels[1]:setDelta(1)
    end)
  end

  channels[ch]:transitionTo{
    time       = time or 2000,
    value      = 0,
    onComplete = cb,
    onCancel   = cb
  }
end


local function stop()
  channels[1]:setDelta(1)
  channels[2]:setDelta(1)
  masterVolume:setDelta(1)

  audio.stop(1)
  audio.stop(2)
end


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


local function mergeFunctions(f1, f2)
  if not (f1 and f2) then return f1 or f2 end

  return function() f1(); f2() end
end


-- track information ---------------------------------------------------------------------------------------------------

function MusicPlayer.getDuration(sound)
  if not tracks[sound] then return -1 end

  return audio.getDuration( tracks[sound] )
end


-- Music ---------------------------------------------------------------------------------------------------------------

local function play(sound, params)
  params = params or {}

  MusicPlayer.load(sound, params.ext)

  audio.stop(musicChannel)
  return audio.play(tracks[sound],{
    channel    = musicChannel,
    loops      = params.loops or -1,
    onComplete = newAudioCallback(params.onComplete, params.onCancel)
  })
end


function MusicPlayer.isPlaying()
  return audio.isChannelPlaying(musicChannel)
end


function MusicPlayer.load(sound, ext)
  if tracks[sound] then return end

  ext = ext or MusicPlayer.defExt
  tracks[sound] = audio.loadSound(MusicPlayer.folder..sound..ext)

  assert(tracks[sound], "Can't load sound: \""..sound..ext.."\"" )
end


function MusicPlayer.play(sound, params)
  MusicPlayer.stop()

  play(sound, params)
end


-- You can use this to fade 2 tracks or just to fade-in
function MusicPlayer.fade(sound, params)
  params = params or {}
  local time = params.time or 700

  -- FadeOut currentMusic
  if audio.isChannelPlaying(musicChannel) then
    channelFadeOut(musicChannel, time)
    musicChannel = musicChannel%2+1
  end

  -- FadeIn new music
  play(sound, params)

  channelFadeIn(musicChannel, time)
end


function MusicPlayer.fadeOut(time)
  if not MusicPlayer.isPlaying() then return end

  masterVolume:transitionTo{
    time       = time or 2000,
    value      = 0,
    onComplete = MusicPlayer.stop,
    onCancel   = MusicPlayer.stop
  }
end


local function getSequenceParams(data)
  if type(data) == "string" then
    return data, {}
  elseif type(data) == "table" then
    return data[1], {
      loops = data[2],
      fade  = not not data[3],
      time  = data[3],
    }
  end

  return nil, {}
end


local function playNext(track, params)
  params.onComplete = mergeFunctions(MusicPlayer.playNext, params.onComplete)

  if params.fade then
    MusicPlayer.fade(track, params)
  else
    play(track, params)
  end
end


local function finishSequence(params)
  if onSequenceComplete then onSequenceComplete() end

  if params.fade then
    MusicPlayer.fadeOut(params.time)
  else
    MusicPlayer.stop()
  end
end


function MusicPlayer.playNext()
  if not musicSequence then return end

  seqIndex = seqIndex+1
  local data = musicSequence[seqIndex]

  local track, params = getSequenceParams(data)

  if track then playNext(track, params)
  else          finishSequence(params)
  end

  return track
end


function MusicPlayer.playSequence(sequence, onComplete)
  stop()
  onSequenceComplete = onComplete
  if type(sequence) == "string" then
    musicSequence = predefinedSequences[sequence]
    assert(musicSequence, "Sequence \"" .. sequence .. "\" doesn't exist")
  else
    musicSequence = sequence
  end

  seqIndex = 0
  return MusicPlayer.playNext()
end


function MusicPlayer.fadeSequence(sequence, time, onComplete)
  onSequenceComplete = onComplete
  musicSequence = type(sequence) == "string" and predefinedSequences[sequence] or sequence

  seqIndex = 1

  local data = musicSequence[seqIndex]

  local track, params = getSequenceParams(data)

  playNext(track, {
    fade       = true,
    time       = time,
    loops      = params.loops,
  })
end


function MusicPlayer.loadSequences(data)
  predefinedSequences = data
end


-- Volume control ------------------------------------------------------------------------------------------------------

function MusicPlayer.setVolume(v)
  masterVolume:setScale(v)
end

-- Flow control --------------------------------------------------------------------------------------------------------

function MusicPlayer.resume()
  if audio.isChannelActive(1) then
    audio.resume(1)
    channels[1]:resume()
  end
  if audio.isChannelActive(2) then
    audio.resume(2)
    channels[2]:resume()
  end
  masterVolume:resume()
end


function MusicPlayer.pause()
  if audio.isChannelActive(1) then
    audio.pause(1)
    channels[1]:pause()
  end
  if audio.isChannelActive(2) then
    audio.pause(2)
    channels[2]:pause()
  end
  masterVolume:pause()
end


function MusicPlayer.stop()
  stop()
  musicSequence = nil
  seqIndex = 0
end

-- Game state observer -------------------------------------------------------------------------------------------------

local function volumeEvent(_, e)
  MusicPlayer.setVolume(e.value)
end

function MusicPlayer.setState(state)
  state:observe("musicVolume", MusicPlayer, volumeEvent, true)
end


return MusicPlayer
