import processing.serial.*;
import themidibus.*;
import javax.sound.midi.MidiMessage; 
import java.util.Map;

/************** Global Variables **************/
enum i {  // instruments
  GRAVITY_XYL, 
    //XYLOCUBE, 
    //FLOPPY, 
    //MELODICA, 
    //XYLOPHONE, 
    //GUITAR, 
    NUMINSTRUMENTS  // add instruments above this line
};

enum Modes {
  CONNECT, 
    PERFORM
};
ArrayList<Instrument> instruments = new ArrayList<Instrument>();
int baudRate = 115200;
color activeColor = color(255, 0, 0, 255);
color inactiveColor = color(255, 0, 0, 100);
byte inByte, midi_note, midi_vel;
int instrument_index;
Instrument instrument;
Table song;
TableRow notes;

/*********** Configuration Parameters **************/
int speed = 2;
int beat_length = 4;  // 1/4 notes
int desired_BPM = 60;  // set beat per minute rate
int beat = 0;
int notes_on_beat;
byte test_note = 60; // Midi middle C
byte mode = (byte) Modes.CONNECT.ordinal();

void setup() {  
  size(1000, 500);  
  frameRate(speed);
  song = loadTable("DemoSong.csv", "header");  
  printArray(Serial.list());
  initialize(this);
}

void draw() {    
  background(0);
  //println(frameRate);
  //checkInstruments();
  conductInstruments();
  drawInstruments();
}  // end draw()

void initialize(PApplet parent) {
  for (int instr = 0; instr<i.NUMINSTRUMENTS.ordinal(); instr++) 
    instruments.add(new Instrument());    
  
  instruments.get(i.GRAVITY_XYL.ordinal()).id = 1;  // nth connect in serial list
  //instruments.get(i.XYLOCUBE.ordinal()).id = 2;
  //instruments.get(i.FLOPPY.ordinal()).id = 3;
  //instruments.get(i.MELODICA.ordinal()).id = 4;
  //instruments.get(i.XYLOPHONE.ordinal()).id = 5;
  //instruments.get(i.GUITAR.ordinal()).id = 6;

  for (int instr = 0; instr<i.NUMINSTRUMENTS.ordinal(); instr++) {
    instruments.get(instr).comm = new Serial(parent, Serial.list()[instruments.get(instr).id], baudRate);
    instruments.get(instr).init();
  }

  notes_on_beat = (song.getColumnCount()-1)/3;
  int spacing = 10;
  float instrument_width = (width-(2*spacing)-((instruments.size()-1)*spacing))/((float)instruments.size());
  for (int i = 0; i < instruments.size(); i++) {
    instruments.get(i).x = spacing+i*(instrument_width+spacing);
    instruments.get(i).w = instrument_width;
  }
}

void conductInstruments() {  
  for (int col = 0; col<notes_on_beat; col++) {
    instrument_index = getInstrumentIndex(song.getInt(beat, col*3 + 1));    
    if(instrument_index < 0) break; // invalid channel number
    instrument = instruments.get(instrument_index);
    byte n = (byte) song.getInt(beat, col*3 + 2);
    byte v = (byte) song.getInt(beat, col*3 + 3);
    instrument.comm.write(n);
    instrument.comm.write(v);
    print(instrument.id);
    print("\t");
    println(n);
  }
  ++beat;
  if (beat==song.getRowCount())
    beat = 0;
}

void checkInstruments() {
  for (int i = 0; i<instruments.size(); i++) {       
    if (instruments.get(i).comm.available() > 0) {      
      //inByte = instruments.get(i).comm.read();
      setStatus(i, inByte);
    }
  }
}

void drawInstruments() {
  for (int i = 0; i<instruments.size(); i++) {        
    fill(instruments.get(i).fill);
    rect(instruments.get(i).x, instruments.get(i).y, instruments.get(i).w, instruments.get(i).h);
  }
}

void setStatus(int i, int vel) {
  if (vel > 0) instruments.get(i).fill = activeColor;
  else instruments.get(i).fill = inactiveColor;
}

void mouseClicked() {  
  beat = 0;  // restart song
}  // end keyPressed()

boolean mouseCollision(float x, float y, float w, float h) {
  if (mouseX > x && mouseX < (x+w) && mouseY > y && mouseY < (y+h)) return true;
  else return false;
}

float bpmToFrameRate(int bpm) {  
  return 1/(4/(beat_length*(bpm/60.0)));  // assumes 4/4 signature
}

int getInstrumentIndex(int channel) {
  switch(channel) {
  case 1:
    return i.GRAVITY_XYL.ordinal();   

    //case 2:
    //return i.XYLOCUBE.ordinal();

  default:
    return -1;
  }
}

class Instrument { 
  Serial comm;
  int id, baud;
  float x, y, w,h,d, o; // x, y, diameter, opacity
  color fill, stroke, strokeWeight;
  Instrument (){
  }

  void init() {
    comm.buffer(1);    
    this.h = 150;
    this.w = 150;
    this.x = width/2 - this.w/2;
    this.y = height/2 - this.h/2;
    this.fill = inactiveColor;
  }
}