import processing.serial.*;
import themidibus.*;
import javax.sound.midi.MidiMessage; 
import java.util.Map;
ArrayList<Instrument> instruments = new ArrayList<Instrument>();
HashMap<Integer, Integer> MidiKeys = new HashMap<Integer, Integer>();
int speed = 100;
int baudRate = 115200;
color activeColor = color(255, 0, 0, 255);
color inactiveColor = color(255, 0, 0, 100);
int inByte, midi_note, midi_press;
MidiBus keyboard;
Table song;

/*********** Configuration Parameters **************/
int GRAVITY_XYL = 7;
int XYLOCUBE = 2;
int FLOPPY = 4;
int MELODICA = 6;
int XYLOPHONE = 1;
int GUITAR = 8;
int beat_length = 4;  // 1/4 notes
int desired_BPM = 60;  // set beat per minute rate
int beat = 0;
Instrument instrument;
TableRow notes;
int channels;

Instrument gravity = new Instrument(GRAVITY_XYL);
Instrument cube = new Instrument(XYLOCUBE);
Instrument floppy = new Instrument(FLOPPY);
Instrument melodica = new Instrument(MELODICA);
Instrument xylophone = new Instrument(XYLOPHONE);
Instrument guitar = new Instrument(GUITAR);

void setup() {  
  size(1000, 500);  
  frameRate(2);
  song = loadTable("DemoSong.csv", "header");
  initInstruments(this);
  printArray(Serial.list());

  keyboard = new MidiBus(this, 0, 0);
}

void draw() {    
  background(0);
  //println(frameRate);
  //checkInstruments();
  conductInstruments();
  drawInstruments();
}  // end draw()

void initInstruments(PApplet parent) {
  //gravity.comm = new Serial(parent, Serial.list()[gravity.id], baudRate);
  cube.comm = new Serial(parent, Serial.list()[cube.id], baudRate); 
  //floppy.comm = new Serial(parent, Serial.list()[floppy.id], baudRate);
  //melodica.comm = new Serial(parent, Serial.list()[melodica.id], baudRate); 
  xylophone.comm = new Serial(parent, Serial.list()[xylophone.id], baudRate);
  //guitar.comm = new Serial(parent, Serial.list()[guitar.id], baudRate); 

  //gravity.init();
  cube.init(); 
  //floppy.init(); 
  //melodica.init(); 
  xylophone.init(); 
  //guitar.init(); 

  //instruments.add(gravity);
  instruments.add(cube);
  //instruments.add(floppy);
  //instruments.add(melodica);
  instruments.add(xylophone);
  //instruments.add(guitar);

  channels = (song.getColumnCount()-1)/3;
  int spacing = 10;
  float instrument_width = (width-(2*spacing)-((instruments.size()-1)*spacing))/((float)instruments.size());
  for (int i = 0; i < instruments.size(); i++) {
    instruments.get(i).x = spacing+i*(instrument_width+spacing);
    instruments.get(i).d = instrument_width;
  }
}

void conductInstruments() {  
  for (int c = 0; c<channels; c++) {
    println((song.getColumnCount()));
    instrument = instruments.get(song.getInt(beat,1+c*3)-1);
    byte n = (byte) song.getInt(beat,2+c*3);
    byte v = (byte) song.getInt(beat,3+c*3);
    instrument.comm.write(n);
    instrument.comm.write(v);
    print(instrument.id);print("\t");print(c);print("\t");println(n);
  }
  ++beat;
  if (beat==song.getRowCount())
    beat = 0;
}

void checkInstruments() {
  for (int i = 0; i<instruments.size(); i++) {       
    if (instruments.get(i).comm.available() > 0) {      
      inByte = instruments.get(i).comm.read();
      setStatus(i, inByte);
    }
  }
}

void drawInstruments() {
  for (int i = 0; i<instruments.size(); i++) {        
    fill(instruments.get(i).fill);
    rect(instruments.get(i).x, instruments.get(i).y, instruments.get(i).d, instruments.get(i).d);
  }
}

void setStatus(int i, int vel) {
  if (vel > 0) instruments.get(i).fill = activeColor;
  else instruments.get(i).fill = inactiveColor;
}

void midiMessage(MidiMessage message) { 
  if (message.getMessage().length > 2) {                            // if valid data
    midi_note = (int)(message.getMessage()[1] & 0xFF);
    midi_press = (int)(message.getMessage()[2] & 0xFF);

    if (midi_press > 0) {                                           // if an "on" note
      if (MidiKeys.containsKey(midi_note)) {                        // if valid key pressed
        println(midi_note);
        instruments.get(MidiKeys.get(midi_note)).comm.write("H");
      }  // end if
    }  // end if
  }  // end if
}  // end if

void mouseClicked() {  
  //conductInstruments();
}  // end keyPressed()

boolean mouseCollision(float x, float y, float w, float h) {
  if (mouseX > x && mouseX < (x+w) && mouseY > y && mouseY < (y+h)) return true;
  else return false;
}

float bpmToFrameRate(int bpm) {  
  return 1/(4/(beat_length*(bpm/60.0)));  // assumes 4/4 signature
}

class Instrument { 
  Serial comm;
  int id, baud;
  float x, y, d, o; // x, y, diameter, opacity
  color fill, stroke, strokeWeight;
  Instrument (int ID) {    
    this.id = ID;
  }

  void init() {
    comm.buffer(1);    
    this.d = 150;
    this.x = width/2 - this.d/2;
    this.y = height/2 - this.d/2;
    this.fill = inactiveColor;
  }
}