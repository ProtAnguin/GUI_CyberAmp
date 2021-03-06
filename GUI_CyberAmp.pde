/* DECLARATIONS
******************************************************************************/
String GUINAME = "CyberAmp GUI";
import controlP5.*;
import processing.serial.*;

ControlP5 cp5;

DropdownList port_list; // port list for COM ports
Serial myPort; // selected COM port
boolean connected = false;
String incoming = "";

static int BAUDRATE =   9600; // Serial baudrate, needs to be same on both ends (PC and device)
int DEV_LOC =    0; // device location 0-9 if multiple devices are used on the same COM port

PFont font;
int fontNum =           4;
int fontSize =          11;

int Nch =               2; // number of channels
int sizeX =             700;
int sizeY =             Nch*30+100; //370;

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
color C_LPF_on  = color(255, 255, 0);
color C_LPF_off = color(125, 125, 125);

boolean pointToSerialPortDropdown = false;

static final private boolean DEBUG = false;

/* SETTINGS - runs only once
******************************************************************************/
void settings() {
  size(sizeX, sizeY, P2D);
  smooth(8);
}

/* SETUP - runs only once
******************************************************************************/
void setup() {
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

  int currYval = 0;
  //for (int i = Nch-1; i>=0; i--) {
  for (int i = 0; i<=Nch-1; i++) {
    currYval = 80+i*30;
    constructChannel(i, 50, currYval, 10, 10);
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
    .setPosition(450, currYval + 20)
    .setSize(150, 20)
    .setFont(font)
    .setColorBackground(color(50, 50, 50))
    .setColorActive(color(255, 0, 128))
    ;
}

/* DRAW - runs constantly
******************************************************************************/
void draw() {
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
  
  Ylab = 58;
  Xlab = 75;    text("POZ", Xlab, Ylab);
  Xlab += 60;   text("NEG", Xlab, Ylab);
  Xlab += 58;   text("PreAmp", Xlab, Ylab);
  Xlab += 100;  text("Offset", Xlab, Ylab);
  Xlab += 122;  text("LPF", Xlab, Ylab);
  Xlab += 58;   text("BPass", Xlab, Ylab);
  Xlab += 40;   text("Notch", Xlab, Ylab);
  Xlab += 48;   text("PostAmp", Xlab, Ylab);
  Xlab += 71;   text("TotalAmp", Xlab, Ylab);

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
