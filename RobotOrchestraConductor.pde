import processing.serial.*;

/************** Global Variables **************/
enum i {  // instruments
  BALLBEARING, // CH2
    XYLOCUBE, //CH3
    FLOPPY,   //CH7
    MELODICA, //CH4
    XYLOPHONE, //CH1
    GUITAR,   //CH6
    RECORDER,  //CH5
    PERCUSSION, //CH8
    NUMINSTRUMENTS  // add instruments above this line
};

enum m {  // modes
  CONNECT, 
    PERFORM
};

ArrayList<Instrument> instruments = new ArrayList<Instrument>();
int baudRate = 115200;
byte inByte, midi_note, midi_vel;
int speed, current_note, beat, notes, mode, max_notes_on_beat, instrument_index, solo_channel, channel, port;
String song_title, ip_address;
Instrument instrument;
Table song;

void initialize(PApplet parent) {
  for (int instr = 0; instr<i.NUMINSTRUMENTS.ordinal(); instr++) 
    instruments.add(new Instrument());
    
  /*********** Start Configuration Parameters **************/
  speed = 4;  // frame rate, 4 for 8th notes at 120 bpm
  current_note = 0;
  beat = -1;
  solo_channel = 1;
  mode = m.PERFORM.ordinal();
  song_title = "PotterScore05272016_5.csv";

  instruments.get(i.XYLOPHONE.ordinal()).id = 1;  // nth device in serial list
  instruments.get(i.BALLBEARING.ordinal()).id = 2;  
  instruments.get(i.XYLOCUBE.ordinal()).id = 3;
  instruments.get(i.MELODICA.ordinal()).id = 4;
  instruments.get(i.RECORDER.ordinal()).id = 5;
  instruments.get(i.GUITAR.ordinal()).id = 6;  
  instruments.get(i.FLOPPY.ordinal()).id = 7;
  instruments.get(i.PERCUSSION.ordinal()).id = 8;

  /*********** End Configuration Parameters **************/
  for (int instr = 0; instr<i.NUMINSTRUMENTS.ordinal(); instr++) {
    instruments.get(instr).comm = new Serial(parent, Serial.list()[instruments.get(instr).id], baudRate);
    instruments.get(instr).init();
  }

  song = loadTable(song_title);
  max_notes_on_beat = (song.getColumnCount()-1)/3;
  notes = song.getRowCount();
  int spacing = 10;
  float instrument_width = (width-(2*spacing)-((instruments.size()-1)*spacing))/((float)instruments.size());
  for (int i = 0; i < instruments.size(); i++) {
    instruments.get(i).x = spacing+i*(instrument_width+spacing);
    instruments.get(i).w = instrument_width;
  }
  if (mode == m.CONNECT.ordinal()) speed = 100;
}

void setup() {  
  size(1000, 500);    
  initialize(this);
  frameRate(speed);  
  printArray(Serial.list());
  delay(2000);
}

void draw() {    
  background(0);  
  switch(mode) {
  case 0:
    checkInstruments();
    break;
  case 1:
    conductInstruments();
    break;
  case 2:
    conductInstruments();
    break;
  default:
    drawInstruments();
  }
}  // end draw()

void conductInstruments() {    
  if (current_note<notes) {
    ++beat;
    if (song.getInt(current_note, 0) != beat) return;  // no notes on this beat
    for (int col = 0; col<max_notes_on_beat; col++) {            
      channel = song.getInt(current_note, col*3 + 1);       
      instrument_index = getInstrumentIndex(channel);    
      if (instrument_index < 0) break;                // invalid channel number
      instrument = instruments.get(instrument_index);
      byte n = (byte) song.getInt(current_note, col*3 + 2);
      byte v = (byte) song.getInt(current_note, col*3 + 3);
      instrument.comm.write(n);
      instrument.comm.write(v);
      //print(current_note);
      //print("\t");
      //print(beat);
      //print("\t");
      //print(instrument.id);
      //print("\t");
      //print(n);
      //print("\t");
      //println(v);
    } // end for
    ++current_note;
    //drawInstruments();
  } // end if
  if (current_note==notes) {
    //beat = current_note = 0;  // repeat song    
    delay(2000);
  }
}

void pingInstrument() {
  Instrument test_connection;
  for (int i = 0; i<instruments.size(); i++) {   
    test_connection = instruments.get(i);
    if (mouseCollision(test_connection)) {
      test_connection.comm.write(test_connection.test_val);   // send test val as note
      test_connection.comm.write(test_connection.test_val);   // send test val as vel
      test_connection.fill = test_connection.inactive;
    }
  }
}

void checkInstruments() {
  Instrument test_connection;
  for (int i = 0; i<instruments.size(); i++) {       
    test_connection = instruments.get(i);
    if (test_connection.comm.available() > 0) {      
      inByte = (byte) test_connection.comm.read();
      setStatus(test_connection, inByte);
    }
  }
  drawInstruments();
}

void drawInstruments() {
  Instrument draw_instrument;
  for (int i = 0; i<instruments.size(); i++) {     
    draw_instrument = instruments.get(i); 
    fill(draw_instrument.fill);
    rect(draw_instrument.x, draw_instrument.y, draw_instrument.w, draw_instrument.h);
  }
}

void setStatus(Instrument i, int val) {
  if (val == i.test_val) i.fill = i.active;
  else i.fill = i.inactive;
}

void mouseClicked() {  
  pingInstrument();
}  // end mouseClicked()

boolean mouseCollision(Instrument i) {
  if (mouseX > i.x && mouseX < (i.x+i.w) && mouseY > i.y && mouseY < (i.y+i.h)) return true;
  else return false;
}

int getInstrumentIndex(int channel) {
  //print("channel:\t");
  //println(channel);
  switch(channel) {
  case 1:
    return i.XYLOPHONE.ordinal();   
  case 2:
    return i.BALLBEARING.ordinal();    
  case 3:
    return i.XYLOCUBE.ordinal();
  case 4:
    return i.MELODICA.ordinal();
  case 5:
    return i.RECORDER.ordinal();
  case 6:
    return i.GUITAR.ordinal();
  case 7:
    return i.FLOPPY.ordinal();
  case 8:
    return i.PERCUSSION.ordinal();
  default:
    return -1;
  }
}

class Instrument { 
  Serial comm;
  int id, baud;
  byte test_val;
  float x, y, w, h, d, o; // x, y, diameter, opacity
  color fill, active, inactive, stroke, strokeWeight;
  Instrument () {
    test_val = 99;
  }

  void init() {
    comm.buffer(1);    
    this.h = 150;
    this.w = 150;
    this.x = width/2 - this.w/2;
    this.y = height/2 - this.h/2;
    this.active = randomColor();
    this.inactive = color(this.active, 100);
    this.fill = this.active;
  }
}

color randomColor() {
  float r = random(0, 255);
  float g = random(0, 255);
  float b = random(0, 255);
  return color(r, g, b);
}