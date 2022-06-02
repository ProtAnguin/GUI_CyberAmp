/* FUNCTIONS
******************************************************************************/

// Customize a dropdown list, here used specifically for serial port
void customize(DropdownList ddl) {
  ddl.setBackgroundColor(color(190));
  ddl.setItemHeight(20);
  ddl.setBarHeight(15);
  ddl.getCaptionLabel().set("serial port");
  ddl.setColorBackground(color(60));
  ddl.setColorActive(color(255, 128));
}

// keyboard key presses automatically calls this
void keyPressed() {
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

void controlEvent(ControlEvent theEvent) {
  String eventName = theEvent.getName();
  // println(theEvent);
  println(eventName);

  if(eventName.substring(0, 3).equals("btn")) {
    int currCh = int(eventName.substring(6)); // get channel number
    float temp_corrFac = 1;
    int   ofsStepFac = 1;
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
    if(eventName.substring(3, 6).equals("Dpl") || eventName.substring(3, 6).equals("Dmi")) { // D increase offset
      forceUpdateOffset = true; // this will call an update
      
      int t_val = int(temp_corrFac * float(cp5.get(Textfield.class,"txtD"+str(currCh)).getText()));
      int t_add = int(pow(10, 2-vals[linP][currCh])) * 100;
      if (eventName.substring(3, 6).equals("Dpl")) {
        t_val += t_add;
      }
      else {
        t_val -= t_add;
      }
      
      cp5.get(Textfield.class,"txtD"+str(currCh)).setValue( str(t_val) );
    }
    
    if(eventName.substring(3, 6).equals("Dup") || forceUpdateOffset) { // D <up>date offset
      int t_val = int(temp_corrFac * float(cp5.get(Textfield.class,"txtD"+str(currCh)).getText()));
      cp5.get(Textfield.class,"txtD"+str(currCh)).setValue( str(t_val) );
      limitValues();
      
      t_val = int(float(cp5.get(Textfield.class,"txtD"+str(currCh)).getText()));
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
    int currCh = int(eventName.substring(6));
    String t_pol = "+";
    if(eventName.substring(5, 6).equals("n")) { t_pol = "-"; }
    writeToPort("AT" + str(DEV_LOC) + "C" + str(currCh+1) + t_pol + optsC[int(theEvent.getValue())]);
  }

  //-------------------------------------------------------------------------------------------------------------------------------------------- COM
  if (theEvent.isController()) {
    // COM connection
    if (theEvent.getName() == "port_list") {
      if (connected) {
        myPort.stop();
        connected = false;
      }
      
      DEV_LOC = constrain(int(cp5.get(Textfield.class,"address_t").getText()), 0, 9);
      cp5.get(Textfield.class,"address_t").setValue(str(DEV_LOC));
      
      myPort = new Serial(this, Serial.list()[int(port_list.getValue())], BAUDRATE, 'N', 8, 1);
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
          int currCh = int(incoming.substring(1, 2))-1;
          int t_val = int(incoming.substring(3, 11));
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
void enterPressed() {
  writeToPort(cp5.get(Textfield.class,"out_t").getText());
  cp5.get(Textfield.class,"out_t").clear();
}

// add an asterix and write to port if connected
void writeToPort(String message) {
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
int[] wl2RGB(double Wavelength){
    double factor;
    double Red,Green,Blue;
    double Gamma = 0.8;
    double IntensityMax = 255;
    
    if ((Wavelength >= 340) && (Wavelength < 380)){
        Red = 0.5;
        Green = 0.5;
        Blue = 0.5;
    }
    else if((Wavelength >= 380) && (Wavelength < 440)){
        Red = -(Wavelength - 440) / (440 - 380);
        Green = 0.0;
        Blue = 1.0;
    }else if((Wavelength >= 440) && (Wavelength < 490)){
        Red = 0.0;
        Green = (Wavelength - 440) / (490 - 440);
        Blue = 1.0;
    }else if((Wavelength >= 490) && (Wavelength < 510)){
        Red = 0.0;
        Green = 1.0;
        Blue = -(Wavelength - 510) / (510 - 490);
    }else if((Wavelength >= 510) && (Wavelength < 580)){
        Red = (Wavelength - 510) / (580 - 510);
        Green = 1.0;
        Blue = 0.0;
    }else if((Wavelength >= 580) && (Wavelength < 645)){
        Red = 1.0;
        Green = -(Wavelength - 645) / (645 - 580);
        Blue = 0.0;
    }else if((Wavelength >= 645) && (Wavelength < 781)){
        Red = 1.0;
        Green = 0.0;
        Blue = 0.0;
    }else{
        Red = 0.0;
        Green = 0.0;
        Blue = 0.0;
    };

    // Let the intensity fall off near the vision limits

    if ((Wavelength >= 340) && (Wavelength < 380)){
      factor = 1;
    }
    else if((Wavelength >= 380) && (Wavelength < 420)){
        factor = 0.3 + 0.7*(Wavelength - 380) / (420 - 380);
    }else if((Wavelength >= 420) && (Wavelength < 701)){
        factor = 1.0;
    }else if((Wavelength >= 701) && (Wavelength < 781)){
        factor = 0.3 + 0.7*(780 - Wavelength) / (780 - 700);
    }else{
        factor = 0.0;
    };


    int[] rgb = new int[3];

    // Don't want 0^x = 1 for x <> 0
    rgb[0] = Red==0.0 ? 0 : (int) Math.round(IntensityMax * Math.pow(Red * factor, Gamma));
    rgb[1] = Green==0.0 ? 0 : (int) Math.round(IntensityMax * Math.pow(Green * factor, Gamma));
    rgb[2] = Blue==0.0 ? 0 : (int) Math.round(IntensityMax * Math.pow(Blue * factor, Gamma));

    return rgb;
}

void constructChannel(int N, int Xpos, int Ypos, int W, int H) {
  int btnW = W;
  int btnH = H;

  int lblOfs = -5;

  int colBck = color(0);
  int colFor = color(200,0,100);
  int colAct = color(255,128,0);
  int colLbl = color(100,200,0);

  // POS & NEG input part
  cp5.addDropdownList("listCp"+str(N)) // Channel POZ input
    .setBroadcast(false)
    .setPosition(Xpos, Ypos-btnH)
    .setSize(50, 80)
    .close()
    .setFont(font)
    .setValue(vals[linCp][N])
    .setItems(optsC)
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
  cp5.addDropdownList("listCn"+str(N)) // Channel NEG input
    .setBroadcast(false)
    .setPosition(Xpos, Ypos-btnH)
    .setSize(50, 80)
    .close()
    .setFont(font)
    .setValue(vals[linCn][N])
    .setItems(optsC)
    .setBarHeight(2*btnH)
    .setItemHeight(2*btnH)
    .setCaptionLabel(optsC[vals[linCn][N]])
    .setColorBackground( colBck )
    .setColorForeground( colFor )
    .setColorActive( colAct )
    .setColorCaptionLabel( colLbl )
    .setBroadcast(true)
    ;

  // P part (pre-amp)
  Xpos += 65;
  allDisplays[linP][N] = new RetroDisplay(3, Xpos, Ypos-btnH, int(2.5*btnW)); // figure out how to get the max number of difits from optsP[] array
  
  Xpos += int(4*btnW);
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

  // DC part (with "update" and "zero" buttons)
  Xpos += 2*btnH;
  cp5.addTextfield("txtD"+str(N))
    .setLabel("")
    .setPosition(Xpos, Ypos-btnH)
    .setSize(70,int(2.5*btnH))
    .setFont(font)
    .setValue("0")
    .setColorBackground( colBck )
    .setColorActive( colAct )
    .setColorValue( colLbl )
    .setAutoClear(false)
    ;
  
  Xpos += 75;
  cp5.addButton("btnDmi"+str(N))
    .setLabel("-")
    .setPosition(Xpos, Ypos)
    .setSize(btnW, btnH)
    ;

  cp5.addButton("btnDpl"+str(N))
    .setLabel("+")
    .setPosition(Xpos, Ypos-btnH)
    .setSize(btnW, btnH)
    ;

  Xpos += 2*btnW;
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
  allDisplays[linF][N] = new RetroDisplay(5, Xpos+btnW, Ypos-btnH, int(2.5*btnW)); // figure out how to get the max number of difits from optsP[] array
  allDisplays[linF][N].setColor("act", color(255,255,0));

  Xpos += int(7.2*btnW);
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
  allDisplays[linO][N] = new RetroDisplay(3, Xpos+btnW, Ypos-btnH, int(2.5*btnW)); // figure out how to get the max number of difits from optsP[] array
  
  Xpos += int(5*btnW);
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
  allDisplays[linT][N] = new RetroDisplay(5, Xpos+btnW, Ypos-btnH, int(2.5*btnW)); // figure out how to get the max number of difits from optsP[] array
  allDisplays[linT][N].setColor("act", color(200,200,255));

  
  
}

void updateLabels(){
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

void limitValues() {
  for(int i = 0; i<Nch; i++) {
    int currCh = i;
    int t_val = int(cp5.get(Textfield.class,"txtD"+str(currCh)).getText());
    int t_fac = optsP[ vals[linP][currCh] ];
    t_val = constrain(t_val, -3000000/t_fac, 3000000/t_fac);
    cp5.get(Textfield.class,"txtD"+str(currCh)).setValue(str(t_val));
  }
}

void parseReportForOneChannel(String in) {
  int currCh = int(in.substring(0, 1))-1;
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
        if(optsP[j] == int(in.substring(cpos+1, cpos+4))) { // if there is a match
          vals[linP][currCh] = j;
        }
      }
    }
    if(in.substring(cpos-1, cpos).equals("O")) {
      for(int j = 0; j < optsO.length; j++) {
        if(optsO[j] == int(in.substring(cpos+1, cpos+4))) { // if there is a match
          vals[linO][currCh] = j;
        }
      }
    }
    if(in.substring(cpos-1, cpos).equals("N")) {
      if(int(in.substring(cpos+1, cpos+2)) == 1) {
        cp5.get(Button.class, "btnNsw"+str(currCh)).setBroadcast(false).setOn().setBroadcast(true);
      }
      else {
        cp5.get(Button.class, "btnNsw"+str(currCh)).setBroadcast(false).setOff().setBroadcast(true);
      }
    }

    if(in.substring(cpos-1, cpos).equals("D")) {
      int t_val = int(in.substring(cpos+1, cpos+9));
      cp5.get(Textfield.class,"txtD"+str(currCh)).setValue(str(t_val));
    }

    if(in.substring(cpos-1, cpos).equals("F")) {
      for(int j = 0; j < optsF.length; j++) {
        if(optsF[j] == int(in.substring(cpos+1, in.length()-1))) { // if there is a match
          vals[linF][currCh] = j;
        }
      }
    }
  }
}
