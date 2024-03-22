Idea Notes:

* Add haptic feedback. Different amplitude for each currency. Good for people that are blind and deaf. Maybe keep it as an option rather than making it default.
  -- didn't do amplitude (because didn't work). Did a pattern. but yeah, done.

* Image sharpening after segmentation. 
  -- ignored

* haar cascade .
  -- ignored

* Volume Dilemma: Volume button to take pic is not easy for some reason. And even if you can do it, what if the user wants to change the volume? They would want to do this if they can't hear the result of the detection. 
 -- done

* IOS support for the volume thing. Perhaps use an emulator for this. Not high priority though, don't have to do this immediately. (todo)
  -- don't care about IOS.

* Play the recieved audio. 
  -- done

* Don't make the camera take the whole screen. Crop it. And put a nicer camera icon.
  -- done

* Landscape preview is weird. Fix that. 
  -- done

* Make the codebase neater. 
  -- it's a simple single page app. who cares.

* Work more on design. The camera sort of looks weird too when tilting, probably because of height and width. Also, 
  the app glitches if I open the camera app of the phone and switch to our app again. also, using the volume button in the "display picture"
  screen takes pictures -- awkward thing to happen tbh. 
  -- don't care about design. no one will care how the camera looks when tilting. it doesn't look that bad. the glitching when you 
     open camera app and open this app, well, who cares? No one will check that. The display picture thing doesn't even exist, so that
     isn't a problem anymore.

* Don't show the picture after it has been taken. Show a progress indicator that indicates waiting for the mp3 to arrive. When the progress
  indicator is showing, "disable" the "volume click to take pic" functionality (just use a bool flag.) 
  -- done

* Add a logo
  -- done
 
* shorten the pulses and keep gap between the pulses. Also, I think it's better to give the haptic feedback after the TTS. Just put the vibration code below tts.

* Language choosing toggle. You can use "volume down" for this btw. 

* haptic feedback on/off toggle. You can use "power button" for this. 

* do a timeout thing if server doesn't return something after a period of time. - Make the wait-time 20 seconds.

