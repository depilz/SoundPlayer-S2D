local SoundPlayer = require("Libs.soundPlayer")
local MusicPlayer = require("Libs.musicPlayer")

-- Loading Songs and sfx
MusicPlayer.load("track1", ".mp3")
MusicPlayer.load("track2", ".mp3")
MusicPlayer.load("track3", ".mp3")

SoundPlayer.load("sfx1", ".mp3")
SoundPlayer.load("sfx2", ".mp3")
SoundPlayer.load("sfx3", ".mp3")
SoundPlayer.load("sfx4", ".mp3")

-- Creating some random sequences
local sequences = {
  {"track1"},
  {"track2", {"track3", nil, 500}},
  {"track1", {"track2", nil, 700}, {"track3", 3}},
}




-- helpers  --

local index = 0

local function newGroup(parent, x, y)
  local group = display.newGroup()
  if parent then parent:insert(group) end

  group.x, group.y = x, y

  return group
end


local function newButton(parent, x, y, image, width, height, action)
  local btn = display.newImageRect(parent,image,width,height)
  btn.x, btn.y = x, y

  btn:addEventListener("tap", action)

  return btn
end


local function newSlider(parent, x, y, cb)
  local length = 300

  local group = display.newGroup()
  group.x, group.y = x, y
  group.anchorChildren = true

  parent:insert(group)

  local line = display.newLine(group, 0, 0, length, 0)
  line.strokeWidth = 5
  local circle = display.newCircle(group, length, 0, 15)
  circle.anchorX = 1

  group:addEventListener("touch", function(e)
    if e.phase == "began" then
      display.getCurrentStage():setFocus(group)
    end
    if e.phase == "ended" then
      display.getCurrentStage():setFocus(nil)
    end
    local x = group:contentToLocal(e.x)
    if x < 0 then x = 0 end
    if x > length then x = length end

    local value = x/length

    circle.x = x
    circle.anchorX = value

    cb(value)
  end)

  return group
end

-- Scene creation ------------------------------------------------------------------------------------------------------

local content = newGroup(nil, display.actualContentWidth/2, display.actualContentHeight/2)
content.anchorChildren = true

-- Music control --

local musicControl = newGroup(content, 0, 0)
musicControl.anchorChildren = true
local btnPause, btnPlay, btnStop, btnNext

local function pauseMusic()
  btnPause.isVisible = false
  btnPlay.isVisible = true
  MusicPlayer.pause()
end


local function playMusic()
  btnPause.isVisible = true
  btnPlay.isVisible = false
  MusicPlayer.resume()
end


local function stopMusic()
  btnPause.isVisible = false
  btnPlay.isVisible = false
  btnStop.isVisible = false
  MusicPlayer.stop()
end


local function playNext()
  btnPause.isVisible = true
  btnPlay.isVisible = false
  btnStop.isVisible = true
  local track = MusicPlayer.playNext()
  if not track then
    index = (index%#sequences)+1
    track = MusicPlayer.playSequence(sequences[index])
  end
  print(" \n---- Playing ----")
  print("track:    "..track)
  print("sequence: "..index)
end


btnPause = newButton(musicControl, 0, 0, "Assets/pause.png", 70, 70, pauseMusic)
btnPlay = newButton(musicControl, 0, 0, "Assets/play.png", 70, 70, playMusic)
btnStop = newButton(musicControl, -100, 0, "Assets/stop.png", 70, 70, stopMusic)
btnNext = newButton(musicControl, 100, 0, "Assets/next.png", 70, 70, playNext)


-- Volume control --

local musicVolume = newGroup(content, 0, 150)
musicVolume.label = display.newText(musicVolume, "Music", -200, 0, nil, 40)
musicVolume.label.anchorX = 0
musicVolume.slider = newSlider(musicVolume, 100, 0, MusicPlayer.setVolume)

local sfxVolume = newGroup(content, 0, 250)
sfxVolume.label = display.newText(sfxVolume, "Sfx", -200, 0, nil, 40)
sfxVolume.label.anchorX = 0
sfxVolume.slider = newSlider(sfxVolume, 100, 0, SoundPlayer.setVolume)


-- Play sound effect --
local playSfx = function()
  local sfx = "sfx"..math.random(4)
  SoundPlayer.play(sfx)
end

local widget = require("widget")
btnNext = widget.newButton{
  label      = "Play sfx",
  fontSize   = 50,
  labelColor = { default={ 1, 1, 1 }, over={ .9, .9, .9, 1   } },
  onPress    = playSfx,

  shape        = "roundedRect",
  width        = 250,
  height       = 70,
  cornerRadius = 2,
  fillColor    = { default={1,0,0,1}, over={.85,0,0,1} },
  strokeColor  = { default={1,0.4,0,1}, over={0.8,0.8,1,1} },
  strokeWidth = 4
}
content:insert(btnNext)
btnNext.x = 0
btnNext.y = 400



stopMusic()
playNext()