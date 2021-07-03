# MUSIC & SOUND PLAYERS FOR SOLAR2D
In the effort of making the sound control in Solar2D more enjoyable, I have created the SoundPlayer and the MusicPlayer libraries that I'm sharing in this project.

I have separated both in 2 different files (Music and sfx) so it is easier to understand and handle, and you can use each one separately, just respecting the 2 reserved channels for the MusicPlayer.

## SETUP

You need to copy the `tween` and `device` lua files in the same folder of `soundPlayer` and `musicPlayer`.

By default the audio folder is `Assets/Audio`, but you can change this by setting the `folder` attribute in both the sound and music players.

The default extensions are `.ogg` for android and `.aac` for evertying else. You can change this by setting the `defExt` attribute in both libraries.

## Extra notes

* It uses the [audio](https://docs.coronalabs.com/api/library/audio/index.html) library in the core.

* The volume increases logaritmically which makes more sense for our ears.

* It also uses the [transition](https://docs.coronalabs.com/api/library/transition/to.html) library to fade the tracks, so be careful using `transition.pause()`, `transition.resume()`, and `transition.cancel()`.

# DOCUMENTATION

## MusicPlayer

* ### getDuration(sound)
returns the durations of a <B>loaded</B> track. It doesn't work to get the duration of a full sequence.

* ### isPlaying()
Returs true if a music is being played.

* ### load(track [,ext])
Loads a track located in the audio folder. The track is the actual name of the file and the extension is optional, if not provided it uses ".ogg" for Android and ".aac" for iOS.
```lua
MusicPlayer.load("my song", ".wav")
```

* ### play(track [,params])
Plays some of the loaded tracks. The `track` is the same you used before on `load`.
You can also send some parameters containing the following entries:
 - loops: How many times it is going to play/repeat until completion. (default is -1)
 - ext: If the track has not been loaded yet, this method will also try to load it, so specifying the extension could be useful in such case.
 - onComplete: Only called if the track has succesfully finish playing.
 - onCancel: Called if the track has being stoped for wathever reason witouth completion.
 
```lua
MusicPlayer.play("my song", {
  loops      = 3, 
  onComplete = playNextSong, 
  onCancel   = printSomething,
})
```

* ### fade(track [,params])
This method fades-out the current playing track and fades-in the one provided. It could also be used to simply fade-in a track when no music is being played at the moment.
The params are the same as in the `play` method with the only difference that this could also contain the entre `time`.
  - time: The time it takes to fade the tracks. default is 700 (ms).

```lua
MusicPlayer.fade("my song", {
  time       = 2000,
  loops      = 3,
})
```

* ### fadeOut(time)
Fades out the current the entire music, so it works normally even if you are currently fading 2 tracks.

* ### setVolume(v)
Sets the master volume of the music.

* ### resume()
Resumes playing.

* ### pause()
Pauses the music.

* ### stop()
Completely stops playing a music or a sequence.


## MusicPlayer sequences
Still part of the MusicPlayer library, the music sequences are useful when you have a set of tracks that need to be played one after the other, eiher if the structure is something like: 
`intro` -> `loop for ever`

Or if you want to increase the tension in a battle by leveling up (by command) the strenght of the song.

`starts slow` -> `battle started` -> `boss phase 2` -> `boss phase 3` -> `track ends`

The sequence is an array with the necessary data to play each track.
The node could be either a string or a table:
  * String: Just plays the specified track.
  * Table: Containing the `track`, the `loops`, and the `fadeInTime` in that order. Only the `track` is mandatory, `loops` is -1 by default.

```lua
local sequence1 = {track1, track2, {track3, nil, 800}}
local sequence2 = {{track1, 1}, {track2, 1}, {track3, 1}}
```

Now, the following methods are useful to handle this sequences:

* ### playSequence(sequence [,onComplete])
Plays a sequence of tracks that could be played one after the other or controlled by the method `playNext`.
The onComplete functional is optional and is going to be called when the last track ends. (Also works when `PlayNext` is called to end a sequence)

* ### fadeSequence(sequence [,time] [,onComplete])
Fades the sequence provided with the current track or simply fades-in if not existent. `time` is the time it takes to fade and `onComplete` is the same as for `playSequence`

* ### playNext()
It plays the next track in a sequence. Returns the name of the track and `nil` if the sequence has ended or has never been started.

* ### loadSequences(data)
You can preload a set of sequences so you can play them later just using a string.

```lua
local sequences = {
  sequence1 = {track1, track2, {track3, nil, 800}}
  sequence2 = {{track1, 1}, {track2, 1}, {track3, 1}}
}

MusicPlayer.loadSequences(sequences)

MusicPlayer.playSequence("sequence1")
```

## SoundPlayer
Specifically designed to play sound effects, but could also be used to play enviromental sounds, such as wind or crickets.

* ### getDuration(sound)
Returns the duration of a <B>loaded</B> sound.


* ### load(sound [,ext] [,useMediaForAndroid])
Pre-loads a sound. The extension works the same as in the MusicPlayer and `useMediaForAndroid` is a flag used if you <B>NEED</B> a sound to be loaded and played using the `media` library instead of `audio`, this <I>could</I> be useful if a sound is not being played instantly on Android, but `media` does't have a volume control so it just plays or not depending of the SoundPlayer volume.

```lua
SoundPlayer.load("mySfx", ".mp3")
```

* ### play(sound [,params])
Plays a sound. The optional parameters are:
  * loops: The number of times you want the audio to loop
  * duration: This will cause the system to play the audio for the specified amount of time and then auto-stop the playback regardless of whether the audio has finished or not.
  * ext: Specify the extension in case the sound has not been loaded yet.
  * onComplete: Listener for the audio succesful completion.
  * onCancel: Listener for the audio playing cancellation.
  
```lua
SoundPlayer.play("mySfx", {loops = 2})
```

* ### setVolume(v)
Sets the sounds master volume.

* ### mute()
Sets master volume to 0.

* ### resume()
Resume playing all sounds.

* ### pause()
Pause all current sounds.

* ### stop()
Completly stops playing all sounds.


## License
[MIT](https://choosealicense.com/licenses/mit/)