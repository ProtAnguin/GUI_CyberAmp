import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import controlP5.*; 
import processing.serial.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class GUI_CyberAmp extends PApplet {

/* DECLARATIONS
******************************************************************************/
String GUINAME = "CyberAmp GUI";



ControlP5 cp5;

DropdownList port_list; // port list for COM ports
Serial myPort; // selected COM port
boolean connected = false;
String incoming = "";

static int BAUDRATE =   9600; // Serial baudrate, needs to be same on both ends (PC and device)
int DEV_LOC =    0; // device location 0-9 if multiple devices are used on the same COM port

PFont font;
int fontNum =           2;
int fontSize =          11;

int Nch =               8; // number of channels
int sizeX =             650;
int sizeY =             370;

int Nlin =              6; // 
int linP =              0; // line in vals to get optsP index
int linO =              1;
int linCp =             2;
int linCn =             3;
int linF =              4;
int linT =              5;

int[][] vals = {  {0, 0, 0, 0, 0, 0, 0, 0},       // optsP index
                  {0, 0, 0, 0, 0, 0, 0, 0},       // optsO index
                  {0, 0, 0, 0, 0, 0, 0, 0},       // optsC index for POS
                  {0, 0, 0, 0, 0, 0, 0, 0},       // optsC index for NEG
                  {0, 0, 0, 0, 0, 0, 0, 0}        // optsF
               };

int optsP[] =  {  1,    10,   100};
int optsO[] =  {  1,     2,     5,    10,    20,    50,   100,   200};
int optsF[] =  {  0,     2,     4,     6,     8,    10,    12,    14,    16,    18,    20,    22,    24,    26,    28,    30,
                               40,    60,    80,   100,   120,   140,   160,   180,   200,   220,   240,   260,   280,   300,
                              400,   600,   800,  1000,  1200,  1400,  1600,  1800,  2000,  2200,  2400,  2600,  2800,  3000,
                             4000,  6000,  8000, 10000, 12000, 14000, 16000, 18000, 20000, 22000, 24000, 26000, 28000, 30000 };
String[] optsC = {"GND", "DC ", "0.1", "1", "10", "30", "100", "300"}; // coupling options

RetroDisplay[][] allDisplays;

boolean pointToSerialPortDropdown = false;

static final private boolean DEBUG = false;

/* SETTINGS - runs only once
******************************************************************************/
public void settings() {
  size(sizeX, sizeY, P2D);
  smooth(8);
}

/* SETUP - runs only once
******************************************************************************/
public void setup() {
  cp5 = new ControlP5( this ); // makes new instance of ControlP5

  // initial font settings
  String[] fontList = PFont.list(); // Get list of fonts
  font = createFont(fontList[fontNum], fontSize, true); // create font
  textSize(40);
  textMode(SHAPE);

  
  if (DEBUG) {
    cp5.addTextfield("out_t")
      .setLabel("")
      .setPosition(10, sizeY-50)
      .setSize(200,20)
      .setFont(font)
      .setColorBackground(color(50, 50, 50))
      .setColorActive(color(255, 0, 128))
      .setColorValue(color(120, 255, 50))
      .setAutoClear(false)
      ;
  }

  allDisplays = new RetroDisplay[Nlin][Nch];

  for (int i = Nch-1; i>=0; i--) {
    constructChannel(i, 50, 80+i*30, 10, 10);
  }

  port_list = cp5.addDropdownList("port_list") // make port list dropdown
              .setPosition(410, 20)
              .setSize(200, 200)
              .close()
              .setItems(Serial.list()) // populate with items in Serial.list (one of them will be the Arduino)
              ;
  customize(port_list);

  cp5.addTextfield("address_t")
      .setLabel("")
      .setPosition(390, 20)
      .setSize(15,15)
      .setFont(font)
      .setColorBackground(color(50, 50, 50))
      .setColorActive(color(255, 0, 128))
      .setColorValue(color(255, 255, 255))
      .setAutoClear(false)
      .setValue(str(DEV_LOC))
      ;

  cp5.addButton("btnWtm") // write to memory
    .setLabel("Save to CyberAmp")
    .setPosition(450, 320)
    .setSize(150, 20)
    .setFont(font)
    .setColorBackground(color(50, 50, 50))
    .setColorActive(color(255, 0, 128))
    ;
}

/* DRAW - runs constantly
******************************************************************************/
public void draw() {
  if(connected) {
    background(color(10,50,100)); // background colour
  }
  else {
    background(color(10,50,100)); // background colour
  }
  textFont(font); // set font
  textAlign(LEFT, CENTER); // set text allignment

  fill(255); // set for text color
  textSize(fontSize+10);
  text(GUINAME, 10, 15); // Write text at X and Y location
  // text("Echo: " + incoming, 50, 305);

  updateLabels();
  
  fill(255); // set for text color
  textSize(fontSize);
  textAlign(CENTER, CENTER); // set text allignment
  
  int Xlab = 35;
  int Ylab = 78;
  for (int i = 1; i<=Nch; i++) {
    text("Ch" + str(i), Xlab, Ylab+(i-1)*30);
  }
  
  Xlab = 75;
  Ylab = 58;
  text("POZ", Xlab, Ylab);
  text("NEG", Xlab+60, Ylab);
  text("PreAmp", Xlab+118, Ylab);
  text("Offset", Xlab+218, Ylab);
  text("LPF", Xlab+325, Ylab);
  text("NOTCH", Xlab+381, Ylab);
  text("PostAmp", Xlab+432, Ylab);
  text("TotalAmp", Xlab+500, Ylab);

  if (!connected && pointToSerialPortDropdown) {
    for(int i = 1; i <= 10; i++) {
      stroke(color(255, 0, 0));
      fill(color( 255*sin(radians(millis()/3)), 0, 0));
      rect(400, 10, 220, 30);
    }
  }

  if (!cp5.get(Textfield.class,"address_t").getText().equals( str(DEV_LOC) )){
    cp5.get(Textfield.class,"address_t").setColorValue(color(255, 0, 0));
  }
  else {
    cp5.get(Textfield.class,"address_t").setColorValue(color(255, 255, 255));
  }
}
/* FUNCTIONS
******************************************************************************/

// Customize a dropdown list, here used specifically for serial port
public void customize(DropdownList ddl) {
  ddl.setBackgroundColor(color(190));
  ddl.setItemHeight(20);
  ddl.setBarHeight(15);
  ddl.getCaptionLabel().set("serial port");
  ddl.setColorBackground(color(60));
  ddl.setColorActive(color(255, 128));
}

// keyboard key presses automatically calls this
public void keyPressed() {
  if (DEBUG) {
    if (!cp5.get(Textfield.class,"out_t").isActive()) {
      if (key == ENTER) {  }
      if (key == TAB) { cp5.get(Textfield.class,"out_t").setFocus(true ); }
    }
    else {
      if (key == ENTER) { enterPressed(); }
      if (key == TAB) { cp5.get(Textfield.class,"out_t").setFocus(false); }
    }
  }
}

public void controlEvent(ControlEvent theEvent) {
  String eventName = theEvent.getName();
  // println(theEvent);
  println(eventName);

  if(eventName.substring(0, 3).equals("btn")) {
    int currCh = PApplet.parseInt(eventName.substring(6)); // get channel number
    float temp_corrFac = 1;
    boolean forceUpdateOffset = false;
    //-------------------------------------------------------------------------------------------------------------------------------------------- P
    if(eventName.substring(3, 4).equals("P")) {
      forceUpdateOffset = true;
      int t_old_I = vals[linP][currCh];
      if(eventName.substring(4, 6).equals("up")) { vals[linP][currCh] = constrain(++vals[linP][currCh], 0, optsP.length-1);}
      if(eventName.substring(4, 6).equals("dw")) { vals[linP][currCh] = constrain(--vals[linP][currCh], 0, optsP.length-1);}
      int t_new_I = vals[linP][currCh];

      temp_corrFac = pow(10, t_old_I-t_new_I);

      writeToPort("AT" + str(DEV_LOC) + "G" + str(currCh+1) + "P" + optsP[ vals[linP][currCh] ]);
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------- O
    if(eventName.substring(3, 4).equals("O")) {
      if(eventName.substring(4, 6).equals("up")) { vals[linO][currCh] = constrain(++vals[linO][currCh], 0, optsO.length-1); }
      if(eventName.substring(4, 6).equals("dw")) { vals[linO][currCh] = constrain(--vals[linO][currCh], 0, optsO.length-1); }
      writeToPort("AT" + str(DEV_LOC) + "G" + str(currCh+1) + "O" + optsO[ vals[linO][currCh] ]);
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------- F
    if(eventName.substring(3, 4).equals("F")) {
      if(eventName.substring(4, 6).equals("up")) { vals[linF][currCh] = constrain(++vals[linF][currCh], 0, optsF.length-1); }
      if(eventName.substring(4, 6).equals("dw")) { vals[linF][currCh] = constrain(--vals[linF][currCh], 0, optsF.length-1); }
      int t_val = optsF[ vals[linF][currCh] ];
      String t_filt = str(t_val);
      if(t_val == 0) { t_filt = "-"; }
      writeToPort("AT" + str(DEV_LOC) + "F" + str(currCh+1) + t_filt);
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------- W
    if(eventName.substring(3, 4).equals("W")) {
      writeToPort("AT" + str(DEV_LOC) + "W");
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------- N
    if(eventName.substring(3, 4).equals("N")) {
      String t_state = "-";
      if(cp5.get(Button.class,"btnNsw"+str(currCh)).getBooleanValue()) { t_state = "+"; }
      writeToPort("AT" + str(DEV_LOC) + "N" + str(currCh+1) + t_state);
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------- D
    if(eventName.substring(3, 6).equals("Dup") || forceUpdateOffset) { // D <up>date offset
      int t_val = PApplet.parseInt(temp_corrFac * PApplet.parseFloat(cp5.get(Textfield.class,"txtD"+str(currCh)).getText()));
      cp5.get(Textfield.class,"txtD"+str(currCh)).setValue( str(t_val) );
      limitValues();
      
      String t_pol = "+";
      if(t_val < 0) { t_pol = "-"; };
      writeToPort("AT" + str(DEV_LOC) + "D" + str(currCh+1) + t_pol + abs(t_val));
    }

    if(eventName.substring(3, 6).equals("Dze")) { // update offset
      if (connected) {
        if (myPort.available() > 0) { myPort.clear(); } // flush the buffer as the next value will be a report from calling Zero
      }
      writeToPort("AT" + str(DEV_LOC) + "Z" + str(currCh+1));
    }
  }
  
  //-------------------------------------------------------------------------------------------------------------------------------------------- C
  if(eventName.substring(0, 5).equals("listC")) {
    int currCh = PApplet.parseInt(eventName.substring(6));
    String t_pol = "+";
    if(eventName.substring(5, 6).equals("n")) { t_pol = "-"; }
    writeToPort("AT" + str(DEV_LOC) + "C" + str(currCh+1) + t_pol + optsC[PApplet.parseInt(theEvent.getValue())]);
  }

  //-------------------------------------------------------------------------------------------------------------------------------------------- COM
  if (theEvent.isController()) {
    // COM connection
    if (theEvent.getName() == "port_list") {
      if (connected) {
        myPort.stop();
        connected = false;
      }
      
      DEV_LOC = constrain(PApplet.parseInt(cp5.get(Textfield.class,"address_t").getText()), 0, 9);
      cp5.get(Textfield.class,"address_t").setValue(str(DEV_LOC));
      
      myPort = new Serial(this, Serial.list()[PApplet.parseInt(port_list.getValue())], BAUDRATE, 'N', 8, 1);
      myPort.bufferUntil('\r');
      connected = true;
      writeToPort("AT" + str(DEV_LOC) + "S+");
    }
  }
}

public void serialEvent(Serial port) {
  if (port == myPort) {
    if (myPort.available() > 0) {
      incoming = "";
      incoming = myPort.readStringUntil('\r');
      println("Echo: " + incoming);
      
      if(incoming.substring(0, 1).equals("D")) {
        if(!incoming.substring(3, 4).equals("!")) {
          int currCh = PApplet.parseInt(incoming.substring(1, 2))-1;
          int t_val = PApplet.parseInt(incoming.substring(3, 11));
          cp5.get(Textfield.class,"txtD"+str(currCh)).setValue(str(t_val));
        }
      }
      else if (incoming.substring(0, 3).equals("CYB")) {
        println(incoming);
      }
      else if (incoming.substring(0, 3).equals("SER")) {
        println(incoming);
      }
      else if (incoming.substring(1, 4).equals(" X=")) {
        parseReportForOneChannel(incoming);
      }
      else {
        println("FELL THROUGH");
      }
    }
  }
}

// Send text from serial comunication textfield and clear field
public void enterPressed() {
  writeToPort(cp5.get(Textfield.class,"out_t").getText());
  cp5.get(Textfield.class,"out_t").clear();
}

// add an asterix and write to port if connected
public void writeToPort(String message) {
  if (connected) {
    myPort.write(message+"\r\n");
  }
  else {
    println("Not yet connected");
    pointToSerialPortDropdown = true;
  }
  println("  Sent: "+message+"\n");
}

// calculate RGB from WL
public int[] wl2RGB(double Wavelength){
    double factor;
    double Red,Green,Blue;
    double Gamma = 0.8f;
    double IntensityMax = 255;
    
    if ((Wavelength >= 340) && (Wavelength < 380)){
        Red = 0.5f;
        Green = 0.5f;
        Blue = 0.5f;
    }
    else if((Wavelength >= 380) && (Wavelength < 440)){
        Red = -(Wavelength - 440) / (440 - 380);
        Green = 0.0f;
        Blue = 1.0f;
    }else if((Wavelength >= 440) && (Wavelength < 490)){
        Red = 0.0f;
        Green = (Wavelength - 440) / (490 - 440);
        Blue = 1.0f;
    }else if((Wavelength >= 490) && (Wavelength < 510)){
        Red = 0.0f;
        Green = 1.0f;
        Blue = -(Wavelength - 510) / (510 - 490);
    }else if((Wavelength >= 510) && (Wavelength < 580)){
        Red = (Wavelength - 510) / (580 - 510);
        Green = 1.0f;
        Blue = 0.0f;
    }else if((Wavelength >= 580) && (Wavelength < 645)){
        Red = 1.0f;
        Green = -(Wavelength - 645) / (645 - 580);
        Blue = 0.0f;
    }else if((Wavelength >= 645) && (Wavelength < 781)){
        Red = 1.0f;
        Green = 0.0f;
        Blue = 0.0f;
    }else{
        Red = 0.0f;
        Green = 0.0f;
        Blue = 0.0f;
    };

    // Let the intensity fall off near the vision limits

    if ((Wavelength >= 340) && (Wavelength < 380)){
      factor = 1;
    }
    else if((Wavelength >= 380) && (Wavelength < 420)){
        factor = 0.3f + 0.7f*(Wavelength - 380) / (420 - 380);
    }else if((Wavelength >= 420) && (Wavelength < 701)){
        factor = 1.0f;
    }else if((Wavelength >= 701) && (Wavelength < 781)){
        factor = 0.3f + 0.7f*(780 - Wavelength) / (780 - 700);
    }else{
        factor = 0.0f;
    };


    int[] rgb = new int[3];

    // Don't want 0^x = 1 for x <> 0
    rgb[0] = Red==0.0f ? 0 : (int) Math.round(IntensityMax * Math.pow(Red * factor, Gamma));
    rgb[1] = Green==0.0f ? 0 : (int) Math.round(IntensityMax * Math.pow(Green * factor, Gamma));
    rgb[2] = Blue==0.0f ? 0 : (int) Math.round(IntensityMax * Math.pow(Blue * factor, Gamma));

    return rgb;
}

public void constructChannel(int N, int Xpos, int Ypos, int W, int H) {
  int btnW = W;
  int btnH = H;

  int lblOfs = -5;

  int colBck = color(0);
  int colFor = color(200,0,100);
  int colAct = color(255,128,0);
  int colLbl = color(100,200,0);

  // POS & NEG input part
  cp5.addDropdownList("listCp"+str(N)) // make post list dropdown
    .setBroadcast(false)
    .setPosition(Xpos, Ypos-btnH)
    .setSize(50, 80)
    .close()
    .setFont(font)
    .setValue(vals[linCp][N])
    .setItems(optsC) // populate with items in Serial.list (one of them will be the Arduino)
    .setBarHeight(2*btnH)
    .setItemHeight(2*btnH)
    .setCaptionLabel(optsC[vals[linCp][N]])
    .setColorBackground( colBck )
    .setColorForeground( colFor )
    .setColorActive( colAct )
    .setColorCaptionLabel( colLbl )
    .setBroadcast(true)
    ;

  Xpos += 60;
  cp5.addDropdownList("listCn"+str(N)) // make post list dropdown
    .setBroadcast(false)
    .setPosition(Xpos, Ypos-btnH)
    .setSize(50, 80)
    .close()
    .setFont(font)
    .setValue(vals[linCn][N])
    .setItems(optsC) // populate with items in Serial.list (one of them will be the Arduino)
    .setBarHeight(2*btnH)
    .setItemHeight(2*btnH)
    .setCaptionLabel(optsC[vals[linCn][N]])
    .setColorBackground( colBck )
    .setColorForeground( colFor )
    .setColorActive( colAct )
    .setColorCaptionLabel( colLbl )
    .setBroadcast(true)
    ;

  // P part
  Xpos += 65;
  allDisplays[linP][N] = new RetroDisplay(3, Xpos, Ypos-btnH, PApplet.parseInt(2.5f*btnW)); // figure out how to get the max number of difits from optsP[] array
  
  Xpos += PApplet.parseInt(4*btnW);
  cp5.addButton("btnPdw"+str(N))
    .setLabel("-")
    .setPosition(Xpos, Ypos)
    .setSize(btnW, btnH)
    ;

  cp5.addButton("btnPup"+str(N))
    .setLabel("+")
    .setPosition(Xpos, Ypos-btnH)
    .setSize(btnW, btnH)
    ;

  // DC part (with "zero" button)
  Xpos += 2*btnH;
  cp5.addTextfield("txtD"+str(N))
    .setLabel("")
    .setPosition(Xpos, Ypos-btnH)
    .setSize(70,PApplet.parseInt(2.5f*btnH))
    .setFont(font)
    .setValue("0")
    .setColorBackground( colBck )
    .setColorActive( colAct )
    .setColorValue( colLbl )
    .setAutoClear(false)
    ;

  Xpos += 75;
  cp5.addButton("btnDup"+str(N))
    .setLabel("U")
    .setPosition(Xpos, Ypos-btnH+3)
    .setSize(2*btnW, 2*btnH)
    .setColorBackground( colBck )
    .setColorActive( colAct )
    .setColorValue( colLbl )
    ;

  Xpos += 2*btnW+5;
  cp5.addButton("btnDze"+str(N))
    .setLabel("Z")
    .setPosition(Xpos, Ypos-btnH+3)
    .setSize(2*btnW, 2*btnH)
    .setColorBackground( colBck )
    .setColorActive( colAct )
    .setColorValue( colLbl )
    ;

  // LPF part
  Xpos += 2*btnW;
  allDisplays[linF][N] = new RetroDisplay(5, Xpos+btnW, Ypos-btnH, PApplet.parseInt(2.5f*btnW)); // figure out how to get the max number of difits from optsP[] array
  allDisplays[linF][N].setColor("act", color(255,255,0));

  Xpos += PApplet.parseInt(7.2f*btnW);
  cp5.addButton("btnFdw"+str(N))
    .setLabel("-")
    .setPosition(Xpos, Ypos)
    .setSize(btnW, btnH)
    ;

  cp5.addButton("btnFup"+str(N))
    .setLabel("+")
    .setPosition(Xpos, Ypos-btnH)
    .setSize(btnW, btnH)
    ;

  // Notch part
  Xpos += 2*btnW;
  cp5.addButton("btnNsw"+str(N))
    .setLabel("N")
    .setPosition(Xpos, Ypos-btnH+3)
    .setSize(2*btnW, 2*btnH)
    .setSwitch(true)
    .setColorBackground( colBck )
    .setColorActive( colAct )
    .setColorValue( colLbl )
    ;


  // O part
  Xpos += 3*btnW;
  allDisplays[linO][N] = new RetroDisplay(3, Xpos+btnW, Ypos-btnH, PApplet.parseInt(2.5f*btnW)); // figure out how to get the max number of difits from optsP[] array
  
  Xpos += PApplet.parseInt(5*btnW);
  cp5.addButton("btnOdw"+str(N))
    .setLabel("-")
    .setPosition(Xpos, Ypos)
    .setSize(btnW, btnH)
    ;

  cp5.addButton("btnOup"+str(N))
    .setLabel("+")
    .setPosition(Xpos, Ypos-btnH)
    .setSize(btnW, btnH)
    ;

  // TOT gain report part
  Xpos += 1*btnW;
  allDisplays[linT][N] = new RetroDisplay(5, Xpos+btnW, Ypos-btnH, PApplet.parseInt(2.5f*btnW)); // figure out how to get the max number of difits from optsP[] array
  allDisplays[linT][N].setColor("act", color(200,200,255));

  
  
}

public void updateLabels(){
  for (int i = 0; i<Nch; i++) {
    allDisplays[linP][i].setValue( optsP[ vals[linP][i] ] );
    allDisplays[linP][i].update();
    
    allDisplays[linO][i].setValue( optsO[ vals[linO][i] ] );
    allDisplays[linO][i].update();

    allDisplays[linF][i].setValue( optsF[ vals[linF][i] ] );
    allDisplays[linF][i].update();

    allDisplays[linT][i].setValue( optsP[ vals[linP][i] ] * optsO[ vals[linO][i] ] );
    allDisplays[linT][i].update();
  }
}

public void limitValues() {
  for(int i = 0; i<Nch; i++) {
    int currCh = i;
    int t_val = PApplet.parseInt(cp5.get(Textfield.class,"txtD"+str(currCh)).getText());
    int t_fac = optsP[ vals[linP][currCh] ];
    t_val = constrain(t_val, -3000000/t_fac, 3000000/t_fac);
    cp5.get(Textfield.class,"txtD"+str(currCh)).setValue(str(t_val));
  }
}

public void parseReportForOneChannel(String in) {
  int currCh = PApplet.parseInt(in.substring(0, 1))-1;
  int pos[] = {0, 0, 0, 0, 0, 0, 0, 0};
  pos[0] = in.indexOf("=");

  for(int i = 1; i <= 7; i++) {
    pos[i] = in.indexOf("=", pos[i-1]+1);
  }

  for (int i = 0; i <= pos.length-1; i++) {
    int cpos = pos[i];

    if(in.substring(cpos-1, cpos).equals("+")) {
      for(int j = 0; j < optsC.length-1; j++) {
        if(optsC[j].equals(in.substring(cpos+1, cpos+4))) { // if there is a match
          vals[linCp][currCh] = j;
          cp5.get(DropdownList.class, "listCp"+str(currCh)).setCaptionLabel(optsC[vals[linCp][currCh]]);
        }
      }
    }
    if(in.substring(cpos-1, cpos).equals("-")) {
      for(int j = 0; j < optsC.length-1; j++) {
        if(optsC[j].equals(in.substring(cpos+1, cpos+4))) { // if there is a match
          vals[linCn][currCh] = j;
          cp5.get(DropdownList.class, "listCn"+str(currCh)).setCaptionLabel(optsC[vals[linCn][currCh]]);
        }
      }
    }

    if(in.substring(cpos-1, cpos).equals("P")) {
      for(int j = 0; j < optsP.length; j++) {
        if(optsP[j] == PApplet.parseInt(in.substring(cpos+1, cpos+4))) { // if there is a match
          vals[linP][currCh] = j;
        }
      }
    }
    if(in.substring(cpos-1, cpos).equals("O")) {
      for(int j = 0; j < optsO.length; j++) {
        if(optsO[j] == PApplet.parseInt(in.substring(cpos+1, cpos+4))) { // if there is a match
          vals[linO][currCh] = j;
        }
      }
    }
    if(in.substring(cpos-1, cpos).equals("N")) {
      if(PApplet.parseInt(in.substring(cpos+1, cpos+2)) == 1) {
        cp5.get(Button.class, "btnNsw"+str(currCh)).setBroadcast(false).setOn().setBroadcast(true);
      }
      else {
        cp5.get(Button.class, "btnNsw"+str(currCh)).setBroadcast(false).setOff().setBroadcast(true);
      }
    }

    if(in.substring(cpos-1, cpos).equals("D")) {
      int t_val = PApplet.parseInt(in.substring(cpos+1, cpos+9));
      cp5.get(Textfield.class,"txtD"+str(currCh)).setValue(str(t_val));
    }

    if(in.substring(cpos-1, cpos).equals("F")) {
      for(int j = 0; j < optsF.length; j++) {
        if(optsF[j] == PApplet.parseInt(in.substring(cpos+1, in.length()-1))) { // if there is a match
          vals[linF][currCh] = j;
        }
      }
    }
  }
}
class RetroDisplay {
  int _Ndigits, _val, _x_loc, _y_loc, _W;
  
  int c_bor = color(  0,   0,   0); // border color
  int c_bck = color(  0,   0,   0); // background color
  int c_ina = color( 50,  50,  50); // color 
  int c_act = color(255,  50,  50); // color active

  RetroDisplay (int inNdigits, int Xpos, int Ypos, int inW) {
    _Ndigits = inNdigits;
    _x_loc = Xpos;
    _y_loc = Ypos;
    _W = inW;
  }

  public void setValue(int inVal) {
    _val = PApplet.parseInt(constrain(inVal, 0, pow(10, _Ndigits+1)-1));
  }

  public void setColor(String what, int col) {
    if(what == "bor") { c_bor = col; }
    if(what == "bck") { c_bck = col; }
    if(what == "ina") { c_ina = col; }
    if(what == "act") { c_act = col; }
  }

  // ADD function to change colours (String what, int colour)

  public void update() {
    drawRetroDisplay(_val, _x_loc, _y_loc, _W);
  }

  public void drawRetroDisplay(int val, int x_loc, int y_loc, int w) {
    // 7 segment display, the first segment is top-right and going clockwise with the center segment last
    int h = PApplet.parseInt(0.8f * w);

    

    float h_seg = h * 0.8f; // height of segment
    float w_seg = h_seg / 2; // width of segment

    float x_seg = x_loc + w * 0.1f;
    float y_seg = y_loc + h * 0.1f;

    String valStr = nf(val, _Ndigits);

    for (int i = 0; i < _Ndigits; i++) {
      int c_dig = PApplet.parseInt(valStr.substring(i, i+1)); // get current digit it cal be [-1, 0, 1, ..., 9]
      if(val<pow(10, _Ndigits-1-i)) { c_dig = -1; } // if value doesnt reach the digit at all ie 10 doesn't reach the third digit
      
      if(val == 0 && (_Ndigits-i) == 1) { c_dig = 0; }
      
      int y_ofs = PApplet.parseInt(i * 1.5f * w_seg);
      drawDigit(c_dig, x_seg + y_ofs, y_seg, w_seg, h_seg, c_bor, c_bck, c_ina, c_act);
    }
  }

  public void drawDigit(int val, float x_loc, float y_loc, float w, float h, int c_bor, int c_bck, int c_ina, int c_act) {
    float border = 0.25f;

    fill(c_bck);
    stroke(c_bor);
    rect(x_loc-border*w, y_loc-border*h, (1+2*border)*w, (1+2*border)*h);

    val = constrain(val, -1, 9);

    float t_seg = w * 0.2f; // thickness of the segment
    float h_seg = h/2 - 1.5f * t_seg;
    float w_seg = w - 2 * t_seg;

    // seg 1
    if (val == 0 || val == 1 || val == 2 || val == 3 || val == 4 || val == 7 || val == 8 || val == 9) { fill(c_act); stroke(c_act); } else { fill(c_ina); stroke(c_ina); }
    rect(x_loc + w - t_seg, y_loc + t_seg, t_seg, h_seg );
    // seg 2
    if (val == 0 || val == 1 || val == 3 || val == 4 || val == 5 || val == 6 || val == 7 || val == 8 || val == 9) { fill(c_act); stroke(c_act); } else { fill(c_ina); stroke(c_ina); }
    rect(x_loc + w - t_seg, y_loc + 2* t_seg + h_seg, t_seg, h_seg );
    // seg 3
    if (val == 0 || val == 2 || val == 3 || val == 5 || val == 6 || val == 8 || val == 9) { fill(c_act); stroke(c_act); } else { fill(c_ina); stroke(c_ina); }
    rect(x_loc + t_seg, y_loc + 2 * t_seg + 2* h_seg, w_seg, t_seg );
    // seg 4
    if (val == 0 || val == 2 || val == 6 || val == 8) { fill(c_act); stroke(c_act); } else { fill(c_ina); stroke(c_ina); }
    rect(x_loc, y_loc + 2* t_seg + h_seg, t_seg, h_seg );
    // seg 5
    if (val == 0 || val == 4 || val == 5 || val == 6 || val == 8 || val == 9) { fill(c_act); stroke(c_act); } else { fill(c_ina); stroke(c_ina); }
    rect(x_loc, y_loc + t_seg, t_seg, h_seg );
    // seg 6
    if (val == 0 || val == 2 || val == 3 || val == 5 || val == 6 || val == 7 || val == 8 || val == 9) { fill(c_act); stroke(c_act); } else { fill(c_ina); stroke(c_ina); }
    rect(x_loc + t_seg, y_loc, w_seg, t_seg );
    // seg 7
    if (val == 2 || val == 3 || val == 4 || val == 5 || val == 6 || val == 8 || val == 9) { fill(c_act); stroke(c_act); } else { fill(c_ina); stroke(c_ina); }
    rect(x_loc + t_seg, y_loc + 1 * t_seg + 1* h_seg, w_seg, t_seg );

  }
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "GUI_CyberAmp" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
