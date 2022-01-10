# GUI_CyberAmp
A Graphical User Interface for a CyberAmp380 as the CyberAmp Control program does not work on newer versions of Windows. The manual for CyberAmp380 was downloaded from [docplayer].

## Table of content
* [Technologies](#technologies)
* [Setup and Launch](#setup-and-launch)
* [How to use](#how-to-use)

## Technologies
- ATEN USB to RS-232 Adapter (UC232A) [ATEN-website]
- CyberAmp 380 (8 channel)
- NAME adaptor
- Windows 10
- [Processing] with ControlP5 and G4P libraries

## Setup and Launch
- ATEN Adapter settings (Device Manager > Ports (COM & LPT) > ATEN USB to Serial Bridge (COM 7)):
    Setting | Value
    --- | ---
    Driver | 3.8.15.5 (02/10/2017)
    Bits per second | 9600
    Data bits | 8
    Parity | None
    Stop bits | 1
    Flow control | None
    
- Install Processing
    - Install libraries (Cketch > Import Library... > Add Library > search for "controlP5" or "G4P" and Install)
- Download the repository, open "GUI_CyberAmp.pde" in Processing and Sketch > Run

![ScreenshotGUI](GUI_CyberAmp_preConnect.png)

## How to use
The first thing to do is connect to the appropriate Serial COM port (that was COM 7 in this example  [Setup and Launch](#setup-and-launch)).
Select the correct one from the "Serial port" drop-down menu.

The GUI will update every channel to the last stored values in the CyberAmp.

The schematics for each channel can be found on page 6 of the "CyberAmp 380 operator's manual" and it will help in understanding the categories of the GUI:

![ScreenshotSIGPROCPATH](SignalProcessingPathway_fromManual.png)

 - POZ and NEG select the coupling of the + and - inputs, respectively
 - PreAmp is the pre-filter amplifier
 - Offset in microvolts with Update and Zero buttons
    - Update is used when the user inputs a new value and want to send it to the device
    - Zero will zero-offset the channel if possible
- LPF is the Low Pass Filter
- Notch filter selector toggle button
- PostAmp is the output amplifier
- TotalAmp reports the total amplification

## Future ideas
- overload detection
- user definable colours

[docplayer]: https://docplayer.fr/155872871-Cyberamp-380-operator-s-manual.html
[ATEN-website]: https://www.aten.com/global/en/products/usb-&-thunderbolt/usb-converters/uc232a/
[Processing]: https://processing.org/
