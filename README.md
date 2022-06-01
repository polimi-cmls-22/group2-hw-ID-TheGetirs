<div align="center">
  <img width="800" alt="GUI" src="https://user-images.githubusercontent.com/61743467/171377245-03e6910a-d0cb-4a4e-b234-600507ede0bd.png">
</div>

## CMLS 2022 - HW3

## Folder Structure
```bash
.
├── ARDUINO
│   └── def
│       └── def.ino
├── GUI
│   ├── GUI.pde
│   ├── data
│   │   ├── bucket_res.png
│   │   ├── buttons
│   │   │   ├── avanti_a.png
│   │   │   ├── avanti_b.png
│   │   │   ├── ...
│   │   ├── covers
│   │   │   ├── 0.jpg
│   │   │   ├── ...
│   │   ├── eq.png
│   │   ├── lego-mosaic-2.jpg
│   │   ├── logo.png
│   │   └── songs
│   │       └── instructions.md
│   ├── fonts
│   │   ├── Minecraft.ttf
│   │   └── Perfect DOS VGA 437.ttf
│   └── songs.csv
├── README.md
├── playlist.scd
└── report HW3 - TheGetirs.pdf
```

# Introduction 
In this project, we focused on the creation of an application that allows the
user to choose a song among the ones in a playlist, play it and modify it with
some effects in a fun way, by using specific Arduino sensors. The main goal is to reproduce a kind of DJ consolle that works without using any button, knob or slider.

# System's Architecture 
The Arduino module processes and passes data through serial connection to the SuperCollider computation module.
A GUI, developed in Processing 4, is connected to our SC engine through OSC messages (in a 2 way fashion) and it’s used both to visualize the parameters modified via hardware by the user and to offer classic playlist controls.

<div align="center">
  <img width="300" alt="scheme" src="https://user-images.githubusercontent.com/99413338/171286198-98d384b5-ccd7-47f7-aafe-04f0a2a5d394.PNG">
</div>

# Features
Here's a list of the main features of our project:

## EQ
An RGB sensor is used to control a dynamic Equalizer. The result of the color acquisition will be shown on screen and produce a low, mid or high frequencies boost, depending on the red, green and blue values detected.

<div align="center">
  <img width="150" alt="rgb" src="https://user-images.githubusercontent.com/99413338/171287592-000ec96e-cef9-4f4c-865e-b287b5c049b6.jpg">
</div>

## LPF
A Photoresistor is used to control the cutoff frequency of an integrated Low Pass Filter with a graphical feedback directly in the GUI. The cutoff frequency is lower when the sensor detects less light intensity.

<div align="center">
  <img width="150" alt="photores" src="https://user-images.githubusercontent.com/99413338/171288344-22391994-1fe1-442b-bfe5-239ce1b42752.jpg">
</div>

## Playback Rate
A proximity sensor detects and measures the distance of a target object. When an object is brought closer, the playback rate of the current song decreases and viceversa.

<div align="center">
  <img width="150" alt="prox" src="https://user-images.githubusercontent.com/61743467/171379407-a36b2ae2-430f-4d2a-a02e-2a4be87e60d6.jpg">
</div>

## Player and Playlist interactions

Thanks to a playlist menu the user can choose which song he prefer to listen to.
Exploiting the IR sensor he can also play/pause a song, go to the next/previews song, mute or change the volume of the current song through a remote controller. The same actions, except from the muting, can be done also by interacting with the GUI.

<div align="center">
  <img width="150" alt="ir" src="https://user-images.githubusercontent.com/99413338/171289010-1b7c5e75-8a3d-4a84-9265-e9599cdb1fa0.jpg">
</div>

## Hardware
The complete Arduino and breadboard connections are as follows:

<div align="center">
  <img width="600" alt="arduino" src="https://user-images.githubusercontent.com/99413338/171289647-0f0977a8-6be5-4ae3-b4d9-5559c3de58c3.jpg">
</div>


# GUI 
<div align="center">
  <img width="800" alt="gui" src="https://user-images.githubusercontent.com/99413338/171284538-5df2a3ce-39a8-4f0f-84d7-84190643d113.PNG">
</div>

The Graphical User Interface is designed in a modular fashion, recalling the style and the concept of the LEGO building bricks.

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
* unzip and place the songs in the ~/GUI/data/songs/ folder

NB: do not modify the name of the songs, or the SC program will not find them and be able to play them.

## Authors
![realegetir](https://user-images.githubusercontent.com/61743467/171381905-818c8187-2649-498d-a974-57ce1dec3f30.png)

Di Palma - Gargiulo - Orsatti - Morena - Perego
