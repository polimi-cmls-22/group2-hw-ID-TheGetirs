# LegoPlayer
### CMLS 2022 - HW3
<img width="596" alt="GUI" src="https://user-images.githubusercontent.com/99413338/171284538-5df2a3ce-39a8-4f0f-84d7-84190643d113.PNG">

# Introduction 
In this project, we focused on the creation of an application that allows the
user to choose a song among the ones in a playlist, play it and modify it with
some effects in a fun way, by using specific Arduino sensors. The main goal is to reproduce a kind of Dj consolle that works without using any button,knob or slider.

# System's Architecture 
The Arduino module processes and passes data through serial connection to the
SuperCollider computation module.
A GUI,developed in Processing 4, is connected to our SC engine through OSC messages (in a 2 way fashion)
and it’s used both to visualize the parameters modified via hardware by the user
and to offer the basic playlist controls.

![schema](https://user-images.githubusercontent.com/99413338/171286198-98d384b5-ccd7-47f7-aafe-04f0a2a5d394.PNG)

# Features
Here's a list of the main features of our project:
## EQ
An RGB sensor is used to control a dynamic EQ section. The result of the color
acquisition will be shown on screen and result in a low, mid or high frequencies
boost, depending respectively on the red,blue and green values detected.

![tcs34725-rgb-color-sensor-arduino](https://user-images.githubusercontent.com/99413338/171287592-000ec96e-cef9-4f4c-865e-b287b5c049b6.jpg)

## LPF
A Photoresistor is used to control the cutoff frequency of an integrated Low Pass
Filter with a graphical feedback directly in the GUI. The cutoff frequency is lower when the sensor detects less luminosity.

![zoom_83442426_KY-018](https://user-images.githubusercontent.com/99413338/171288344-22391994-1fe1-442b-bfe5-239ce1b42752.jpg)

## PlaybackRate
A proximity sensor detects and measures the distance
of a target object. When the object is less distant, the playback rate of the selected is increased.
<img ![177109536](https://user-images.githubusercontent.com/99413338/171288697-2d40c216-6e1d-4956-95c8-579a67791007.png)

## Playlist

Thanks to a playlist the user can choose which song he prefer to listen to.
Exploiting an IR sensor he can also pause, play, mute or change the volume of the chosen song. The same actions, except from the muting, can be done also by interacting with the GUI.

![infrared-ir-sensor-receiver-module-for-arduino-500x500](https://user-images.githubusercontent.com/99413338/171289010-1b7c5e75-8a3d-4a84-9265-e9599cdb1fa0.jpg)

## Hardware
All the sensors are connected as shown in the following picture:

![IMG_20220531_233259](https://user-images.githubusercontent.com/99413338/171289647-0f0977a8-6be5-4ae3-b4d9-5559c3de58c3.jpg)


# GUI 
The Graphical User Interface is designed in a modular fashion, recalling the
style and the concept of the LEGO building blocks

<img width="596" alt="GUI" src="https://user-images.githubusercontent.com/99413338/171284538-5df2a3ce-39a8-4f0f-84d7-84190643d113.PNG">

The main blocks of the GUI are:
- Playlist module
- Player module
- Equalization module
- Playback Rate module
- LPF module

# Songs Download 

If you want to play with our project:

* go to <a href="https://polimi365-my.sharepoint.com/:f:/g/personal/10628782_polimi_it/EkbXbOT7VuRHmAASjOxEm7ABg6l92bMhkz2xUtCFpgdMQA?e=e2wB2o%22%3Ethis"> link</a>
* download the zip file songs.zip
* unzip and place the songs in this folder (~/GUI/data/songs/)

NB: do not modify the name of the songs, or the SC program will not find them and be able to play them.

