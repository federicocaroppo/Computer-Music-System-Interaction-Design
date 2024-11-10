## Homework 3 - Group 3 - La Lobby
# TeleKINesis (Real-time Kinetic Voice Processing)

The implemented computer music system allows the performer to manage the processing his/her voice undergoes in real time via the simple motion of the hands. The architecture of such system involves an interaction system unit, represented by a Microsoft Kinect sensor, a computer music unit consisting of a SuperCollider script and a graphical feedback unit, i.e. a GUI implemented via a Processing script.
  
<p align="center">
  <img src="/imgs/architecture.jpg" width=65% margin-top="15%">
</p>

## Communication Protocol
The communication between the different units takes place by means of the OSC protocol, as illustrated in the diagram above.

## Interaction System Unit
The Microsoft Kinect V2, is a sensor able to perform real-time gesture recognition and body-skeletal detection. 
This is done by using a color map and a depth map, captured respectively by an RGB camera and an infrared projector.
The data collected by the Kinect is processed by TouchDesigner before being sent via OSC messages to SuperCollider and Processing.
In particular, hands position are normalized with respect to the arm length and the position of the user, and are then mapped in order to obtain smooth values between 0 and 1. 
<p align="center">
  <img src="/imgs/kinect.JPG" width=65% margin-top="15%">
</p>

## Computer Music Unit
Supercollider is responsible for the sound processing.
The effects are set in parallel, allowing the performer to control the effects on its hands inependently.
The loop, on the other hand, is set in series with the effects, therefore the effects applied during the recording will be kept in the loop.
For our implementation, we've decided to use a microphone and an external audio interface, but for future usage, the input device must
be specified when booting the server on SuperCollider.

## Graphical Feedback Unit
The graphical feedback is realized in Processing and it's implemented as to visualize the body of the performer via point cloud rapresentation.
Two sliders are responsible of setting the thresholds for the visualizer.
The other sliders show the data affecting the sound.
Finally two boxes are responsible of choosing the effects.
Also, a pop-up has been added to note the performer when the loop is recording, playing or being overdubbed.

<p align="center">
  <img src="/imgs/GUI_imag.png" width=65% margin-top="15%">
</p>

### Group members
Nicolò Chillè, Rocco Scarano, Enrico Dalla Mora, Federico Caroppo
