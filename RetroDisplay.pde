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

  void setValue(int inVal) {
    _val = int(constrain(inVal, 0, pow(10, _Ndigits+1)-1));
  }

  void setColor(String what, color col) {
    if(what == "bor") { c_bor = col; }
    if(what == "bck") { c_bck = col; }
    if(what == "ina") { c_ina = col; }
    if(what == "act") { c_act = col; }
  }

  // ADD function to change colours (String what, int colour)

  void update() {
    drawRetroDisplay(_val, _x_loc, _y_loc, _W);
  }

  void drawRetroDisplay(int val, int x_loc, int y_loc, int w) {
    // 7 segment display, the first segment is top-right and going clockwise with the center segment last
    int h = int(0.8 * w);

    

    float h_seg = h * 0.8; // height of segment
    float w_seg = h_seg / 2; // width of segment

    float x_seg = x_loc + w * 0.1;
    float y_seg = y_loc + h * 0.1;

    String valStr = nf(val, _Ndigits);

    for (int i = 0; i < _Ndigits; i++) {
      int c_dig = int(valStr.substring(i, i+1)); // get current digit it cal be [-1, 0, 1, ..., 9]
      if(val<pow(10, _Ndigits-1-i)) { c_dig = -1; } // if value doesnt reach the digit at all ie 10 doesn't reach the third digit
      
      if(val == 0 && (_Ndigits-i) == 1) { c_dig = 0; }
      
      int y_ofs = int(i * 1.5 * w_seg);
      drawDigit(c_dig, x_seg + y_ofs, y_seg, w_seg, h_seg, c_bor, c_bck, c_ina, c_act);
    }
  }

  void drawDigit(int val, float x_loc, float y_loc, float w, float h, color c_bor, color c_bck, color c_ina, color c_act) {
    float border = 0.25;

    fill(c_bck);
    stroke(c_bor);
    rect(x_loc-border*w, y_loc-border*h, (1+2*border)*w, (1+2*border)*h);

    val = constrain(val, -1, 9);

    float t_seg = w * 0.2; // thickness of the segment
    float h_seg = h/2 - 1.5 * t_seg;
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
