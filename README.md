Idea Notes:

* Add haptic feedback. Different amplitude for each currency. Good for people that are blind and deaf. Maybe keep it as an option rather than making it default.
* Image sharpening after segmentation.
* haar cascade .
* Volume Dilemma: Volume button to take pic is not easy for some reason. And even if you can do it, what if the user wants to change the volume? They would want to do this if they can't hear the result of the detection. - (Solved.)
* IOS support for the volume thing. Perhaps use an emulator for this. Not high priority though, don't have to do this immediately. (todo)
* Play the recieved audio. - (Solved.)
* Don't make the camera take the whole screen. Crop it. And put a nicer camera icon. (Done.)
* Landscape preview is weird. Fix that. (Solved. Just disabled landscape mode.)
* Make the codebase neater. (It seems like there is no "simple" way to separate logic from UI code, at least for a simple app like ours.)
* todo: 
  # Work more on design. The camera sort of looks weird too when tilting, probably because of height and width. Also, 
  the app glitches if I open the camera app of the phone and switch to our app again. also, using the volume button in the "display picture"
  screen takes pictures -- awkward thing to happen tbh. 
  # Don't show the picture after it has been taken. Show a progress indicator that indicates waiting for the mp3 to arrive. When the progress
  indicator is showing, "disable" the "volume click to take pic" functionality (just use a bool flag.) 
  -- the progress indicator part has been done. make the background opacity low here, and also the disable volume click to take pic functionality
     is yet to be added. also, as soon as you click the volume button, do the setstate, not when the picture has been officially taken. -- done
  # Language choosing option. You can use "volume down" for this btw. 
  # do a timeout thing if server doesn't return something after a period of time. 




DO A DESIGN REFINING IN GENERAL WHEN THE FUNCTIONALITY IS GOOD. 
