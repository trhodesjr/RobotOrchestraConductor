import processing.serial.*;
import themidibus.*;
import javax.sound.midi.MidiMessage; 
import java.util.Map;
ArrayList<Instrument> instruments = new ArrayList<Instrument>();
HashMap<Integer, Integer> MidiKeys = new HashMap<Integer, Integer>();
int speed = 100;
int baudRate = 9600;
Instrument railgun = new Instrument(1);
Instrument organ = new Instrument(2);
color activeColor = color(255, 0, 0, 255);
color inactiveColor = color(255, 0, 0, 100);
int inByte, midi_note, midi_press;
MidiBus keyboard;

void setup() {  
  size(500, 500);  
  frameRate(speed);  
  initInstruments(this);
  printArray(Serial.list());
  keyboard = new MidiBus(this, 0, 0);
}

void draw() {    
  background(0);
  checkInstruments();
  drawInstruments();
}  // end draw()

void initInstruments(PApplet parent) {
  railgun.comm = new Serial(parent, Serial.list()[railgun.id], baudRate);
  organ.comm = new Serial(parent, Serial.list()[organ.id], baudRate);  

  railgun.init();  
  MidiKeys.put(60, railgun.id-1);   // C4    
  instruments.add(railgun);
  organ.init();
  organ.x = 0;
  organ.y = 0;
  instruments.add(organ);
  MidiKeys.put(62, organ.id-1);   // C4
}

void conductInstruments() {
  for (int i = 0; i<instruments.size(); i++) {       
    if (mouseCollision(instruments.get(i).x, instruments.get(i).y, instruments.get(i).d, instruments.get(i).d)) {
      instruments.get(i).comm.write("H");
    }
  }
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

void setStatus(int i, int status) {
  if (status == 'S') instruments.get(i).fill = activeColor;
  else if (status == 'F') instruments.get(i).fill = inactiveColor;
  else instruments.get(i).fill = color(0);
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
  conductInstruments();
}  // end keyPressed()

boolean mouseCollision(float x, float y, float w, float h) {
  if (mouseX > x && mouseX < (x+w) && mouseY > y && mouseY < (y+h)) return true;
  else return false;
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