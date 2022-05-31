import controlP5.*;
import static controlP5.ControlP5.*;
import oscP5.*;
import netP5.*;
import java.util.*;
import java.util.Map.Entry;


OscP5 oscP5;
NetAddress myRemoteLocation;

//GUI variables
PShape blur;
PImage coverBig;
PImage logo;
PImage eq;
PImage blurred;
PImage blurred2;
PShape rgbRect;
PImage legoPixel;
PGraphics box;
Slider volumeSlider;
PFont f1, f2;
Table songs;
int blurCheck = 0;
float blurFactor;
ArrayList<Song> parsedSongs;
// speed of the plyaback rate rotation
float speed;
float lpfrate;
float realRate;
//Cutoff frequency displayed value
int cutoff;
//values for the rgb rectangle
int r = -1, g = -1, b = -1;
//indice per la canzone attiva
int isPlaying=0;
//numero di canzoni
int nRows;
// variabili cover piccole
ArrayList<PImage> coverSmall = new ArrayList();
String value;
int n;
boolean isSerialVolume = false;

ControlP5 cp5;
//background color
int myColor = color(73, 89, 81);

// Buttons
Button play;
Button indietro;
Button avanti;
Button eqtype;
boolean play_state=true;

void setup() {
  prepareExitHandler();

  size(1200, 650, P3D);
  f1 = createFont("Perfect DOS VGA 437", 24);
  f2 = createFont("Minecraft", 20);
  noStroke();

  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this, 12000);
  // send OSC messages to:
  myRemoteLocation = new NetAddress("127.0.0.1", 57120);

  cp5 = new ControlP5(this);
  box = createGraphics(600, 600);

  //CSV parsing
  songs = loadTable("songs.csv");
  parsedSongs = new ArrayList<Song>();
  nRows = songs.getRowCount();

  for (TableRow row : songs.rows()) {
    String title = row.getString(0);
    String artist = row.getString(1);
    String desc = row.getString(2);
    int id = row.getInt(3);
    Song song = new Song(title, artist, desc, id);
    parsedSongs.add(song);
  }


  //GUI
  PImage[] imgs2 = {loadImage("buttons/avanti_a.png"), loadImage("buttons/avanti_b.png"), loadImage("buttons/avanti_c.png")};
  PImage[] imgs3 = {loadImage("buttons/indietro_a.png"), loadImage("buttons/indietro_b.png"), loadImage("buttons/indietro_c.png")};
  PImage[] imgs4 = {loadImage("buttons/pausa_a.png"), loadImage("buttons/pausa_b.png"), loadImage("buttons/pausa_c.png")};
  legoPixel = loadImage("lego-mosaic-2.jpg");
  int j;
  for (j = 0; j < imgs4.length; j++) {
    imgs2[j].resize(40, 40);
    imgs3[j].resize(40, 40);
    imgs4[j].resize(40, 40);
  }
  play = cp5.addButton("play")
    .setPosition(width/2-25, 590)
    .setImages(imgs4)
    .updateSize()
    ;
  avanti = cp5.addButton("avanti")
    .setPosition(width/2 +40, 590)
    .setImages(imgs2)
    .updateSize()
    ;
  indietro = cp5.addButton("indietro")
    .setPosition(width/2-95, 590)
    .setImages(imgs3)
    .updateSize()
    ;

  // MenuList is a class declared at the end of this sketch
  MenuList m = new MenuList( cp5, "menu", 300, 550 );

  m.setPosition(20, 20);
  // add some items to our menuList
  for (int i=0; i<songs.getRowCount(); i++) {
    m.addItem(makeItem(parsedSongs.get(i).getTitle(), parsedSongs.get(i).getArtist(), parsedSongs.get(i).getDesc(), createImage(50, 50, RGB)));
  }

  // ciclo per caricare cover piccole
  for (n = 0; n < songs.getRowCount(); n++) {
    value = str(n);
    coverSmall.add ( loadImage("covers/"+value + ".jpg") );
  }

  //Image loading
  coverBig = loadImage("covers/" + parsedSongs.get(0).getImage() +".jpg");
  logo = loadImage("logo.png");
  eq = loadImage("eq.png");
  blurred = loadImage("bucket_res.png");
  blurred2 = loadImage("bucket_res.png");


  volumeSlider = cp5.addSlider("volumeSlider")
    //.setColorValue(color(255))
    .setColorActive(color(55, 240, 147))
    .setColorForeground(color(155))
    .setColorBackground(color(48, 54, 51))
    .setCaptionLabel("VOLUME")
    .setPosition(20, 600)
    .setSize(200, 20)
    .setNumberOfTickMarks(11)
    .setRange(0, 1)
    .setValue(0.2);


  //RGB COLOR CHANGING RECTANGLE
  rgbRect = createShape(RECT, 0, 0, 150, 150);
  //rgbRect.fill(0, 0, 255);
  rgbRect.setStroke(false);
  rgbRect.setFill(color(201, 196, 181));
  rgbRect.setStroke(false);

  //RGB FAKE BUTTON EQ TYPE
  eqtype = cp5.addButton("buttonValue")
    .setColorActive(color(237, 137, 117))
    .setColorForeground(color(237, 137, 117))
    .setColorBackground(color(237, 137, 117))
    .setPosition(880, 240)
    .setFont(f1)
    .setSize(100, 50)
    .setId(2);

  eqtype.getCaptionLabel()
    .setColor(color(0))
    .setFont(f1)
    .setSize(30)
    .toUpperCase(false)
    .setText("");
  //playback speed rotation
  speed = 0;
  lpfrate= 0;

  //blurred.resize(240, 240);

  blur = createShape();
  blur.beginShape();
  blur.texture(blurred);
  blur.vertex(1065, 420, 0, 0);
  blur.vertex(1165, 420, 240, 0);
  blur.vertex(1165, 520, 240, 240);
  blur.vertex(1065, 520, 0, 240);
  blur.endShape();

  OscMessage startup = new OscMessage("/startup");
  oscP5.send(startup, myRemoteLocation);
}

void draw() {
  background(myColor);

  //Separatore 1 grigio
  fill(158, 158, 157);
  rect(340, 0, 10, 650);
  //Separatore titolo-player
  fill(158, 158, 157);
  rect(350, 120, 1000, 10);
  // separatore player-visualizers
  fill(158, 158, 157);
  rect(830, 130, 10, 600);

  //blocco player
  fill(48, 77, 99);
  rect(350, 130, 480, 550);
  //blocco visualizers
  fill(237, 137, 117);
  rect(840, 130, 500, 600);
  //separatore visualizers
  fill(158, 158, 157);
  rect(830, 380, 1000, 10);

  //blocco titolo
  fill(244, 235, 190);
  rect(350, 0, 1000, 120);
  //blocco sottocover
  fill(35, 125, 150);
  rect(380, 150, 420, 420);
  //secondo blocco sotto
  fill(167, 206, 203);
  rect(390, 160, 400, 400);
  //blocco playback
  fill(154, 140, 152);
  rect(840, 390, 1000, 500);
  //separatore playback/LFO
  fill(158, 158, 157);
  rect(1020, 380, 10, 600);
  //blocco lpf
  fill(42, 157, 143);
  rect(1030, 390, 600, 600);
  //blocco eq esterno
  fill(255);
  rect(1020, 165, 160, 160);

  shape(rgbRect, 1025, 170);

  //fill(255,0,14);
  //rect(1000,170,170,170);
  //shape(rgbRect, 1025, 170);


  image(coverBig, 400, 170, 380, 380);
  image(logo, 480, -95, 600, 300);
  image(eq, 955, 115, 295, 295);

  legoPixel.resize(60, 60);

  pushMatrix();
  translate(925, 470);
  rotate(radians(speed));
  //RETTANGOLO ESTERNO (BORDO)
  fill(34, 34, 59);
  rect(-35, -35, 70, 70);
  //LEGO LOGO
  fill(255, 0, 0);
  //rect(-25, -25, 50, 50);
  beginShape();
  texture(legoPixel);
  vertex(-30, -30, 0, 0);
  vertex(-30, 30, 0, 60);
  vertex(30, 30, 60, 60);
  vertex(30, -30, 60, 0);
  endShape();
  speed+=lpfrate;
  popMatrix();


  //SCRITTE
  fill(0);
  textFont(f1, 24);
  text("PLAYBACK \n  RATE", 870, 540);
  text(nfc(realRate, 2), 895, 620);
  fill(0);
  textFont(f1, 24);
  text("LPF RATE", 1060, 565);
  fill(0);
  textFont(f1, 24);
  text("EQ TYPE:", 870, 210);



  if (blurCheck == 0) {
    blur.beginShape();
    blur.texture(blurred);
    blur.vertex(1065, 420, 0, 0);
    blur.vertex(1165, 420, 240, 0);
    blur.vertex(1165, 520, 240, 240);
    blur.vertex(1065, 520, 0, 240);
    blur.endShape();
    shape(blur);
  } else {
    //image(blurred,1060,450,100,100);
    blur = createShape();
    blur.beginShape();
    blur.texture(blurred2);
    blur.vertex(1065, 420, 0, 0);
    blur.vertex(1165, 420, 240, 0);
    blur.vertex(1165, 520, 240, 240);
    blur.vertex(1065, 520, 0, 240);
    blur.endShape();
    shape(blur);
    text(cutoff+" Hz", 1075, 620);
  }
}

/* a convenience function to build a map that contains our key-value pairs which we will
 * then use to render each item of the menuList.
 */
Map<String, Object> makeItem(String title, String artist, String theCopy, PImage cover) {
  Map m = new HashMap<String, Object>();
  m.put("Title", title);
  m.put("Artist", artist);
  m.put("copy", theCopy);
  m.put("image", cover);
  return m;
}



void menu(int i) {
  //println("got some menu event from item with index "+i);
}

//callback function when the slider is moved
void volumeSlider() {
  OscMessage myMessage = new OscMessage("/volumeOSC");
  if (volumeSlider!=null) {
    if (isSerialVolume) {
      isSerialVolume = false;
    } else {
      myMessage.add(volumeSlider.getValue());
      oscP5.send(myMessage, myRemoteLocation);
      println("Slider event. OSC volume " + volumeSlider.getValue() + "message sent");
    }
  }
}

void changePlayingState() {
  if (play_state) {
    play_state = false;
  } else {
    play_state = true;
  }
}

void changePauseImg() {
  PImage[] imgs1 = {loadImage("/buttons/button_a.png"), loadImage("buttons/button_b.png"), loadImage("buttons/button_c.png")};
  PImage[] imgs4 = {loadImage("/buttons/pausa_a.png"), loadImage("buttons/pausa_b.png"), loadImage("buttons/pausa_c.png")};
  int j;
  for (j = 0; j < imgs1.length; j++) {
    imgs1[j].resize(40, 40);
    imgs4[j].resize(40, 40);
  }

  if (!play_state) {
    play.setImages(imgs1);
  } else {
    play.setImages(imgs4);
  }
}

void changeImgIfPaused() {
  if (!play_state) {
    play_state = true;
    changePauseImg();
  }
}

public void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom("menu")) {
    Map m = ((MenuList)theEvent.getController()).getItem(int(theEvent.getValue()));
    // INDICI DA MANDARE A SUPERCOLLIDER: [0,N-1 colonne del csv]
    int index = int(theEvent.getValue());
    OscMessage message = new OscMessage("/menuSelect");
    message.add(index);
    oscP5.send(message, myRemoteLocation);
    //INDICE INTERNO PER GESTIRE LA CANZONE ATTIVA [1,N colonne del csv]
    isPlaying = index;
    coverBig = loadImage("covers/"+(isPlaying)+".jpg");
    println("Is Playing (Menu): "+isPlaying);
    changeImgIfPaused();
  }
}

public void play() {
  changePlayingState();
  changePauseImg();
  OscMessage myMessage = new OscMessage("/playPause");
  oscP5.send(myMessage, myRemoteLocation);
  println(myMessage);
}

public void avantiGUI() {
  // actually changes the information in the gui (also used when the song change is called from serial)
  if (isPlaying == nRows - 1) {
    isPlaying = 0;
  } else {
    isPlaying++;
  }
  println("Is Playing (Avanti): "+isPlaying);
  coverBig = loadImage("covers/"+(isPlaying)+".jpg");
  changeImgIfPaused();
}
public void avanti() {
  // calls for GUI changes and communicates the change to SC
  avantiGUI();
  OscMessage myMessage = new OscMessage("/nextPrev");
  myMessage.add(1);
  oscP5.send(myMessage, myRemoteLocation);
}

public void indietroGUI() {
  // actually changes the information in the gui (also used when the song change is called from serial)
  if (isPlaying == 0) {
    isPlaying = nRows - 1;
  } else {
    isPlaying--;
  }
  coverBig = loadImage("covers/"+(isPlaying)+".jpg");
  println("Is Playing (Indietro): "+isPlaying);
}

public void indietro() {
  // calls for GUI changes and communicates the change to SC
  indietroGUI();
  OscMessage myMessage = new OscMessage("/nextPrev");
  myMessage.add(-1);
  oscP5.send(myMessage, myRemoteLocation);
  changeImgIfPaused();
}

void changeBoostText() {
  if ((r>g) & (r>b)) {
    eqtype.getCaptionLabel()
      .setText("BASS \nBOOST");
  } else if ((g>r) & (g>b)) {
    eqtype.getCaptionLabel()
      .setText("MID \nBOOST");
  } else {
    eqtype.getCaptionLabel()
      .setText("TREBLE \nBOOST");
  }
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  /* print the address pattern and the typetag of the received OscMessage */
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());

  // messages we receive from SC (and really from the serial connection with arduino)
  if (theOscMessage.checkAddrPattern("/volumeSerial")==true) {         // volume
    float recVolume = theOscMessage.get(0).floatValue();
    isSerialVolume = true;
    volumeSlider.setValue(recVolume);
  } else if (theOscMessage.checkAddrPattern("/prate")==true) {         // rolling rate
    realRate = theOscMessage.get(0).floatValue();
    //lpfrate = 2*prate;
    switch(str(realRate)) {
    case "0.5":
      lpfrate = realRate;
      break;
    case "0.75":
      lpfrate = 1;
      break;
    case "1.0":
      lpfrate = 2;
      break;
    case "1.25":
      lpfrate = 3;
      break;
    case "1.5":
      lpfrate = 4;
      break;
    case "1.75":
      lpfrate = 5;
      break;
    case "2.0":
      lpfrate = 6;
      break;
    }
  } else if (theOscMessage.addrPattern().equals("/lpf")) {           // lpf
    blurFactor = 9 - theOscMessage.get(0).floatValue();
    cutoff = theOscMessage.get(1).intValue();
    println("Cutoff :"+cutoff);
    println("blurFactor:" + blurFactor);
    blurCheck = 1;
    println("blurCheck" + blurCheck);
    blurred2 = loadImage("bucket_res.png");
    //blurred2.resize(240, 240);
    blurred2.filter(BLUR, blurFactor);
  } else if (theOscMessage.checkAddrPattern("/red")==true) {           // red
    r = (int) theOscMessage.get(0).floatValue();
    // setting colore rettangolo rgb
    if (b != -1 && g != -1) {
      if (rgbRect != null) { // to avoid startup errors in case supercollider is already open
        rgbRect.setFill(color(r, g, b));
        changeBoostText();
      }
    }
    //println(r + " " + g + " " + b);
  } else if (theOscMessage.checkAddrPattern("/green")==true) {         // green
    g = (int) theOscMessage.get(0).floatValue();
    if (r != -1 && b != -1) {
      if (rgbRect != null) {
        rgbRect.setFill(color(r, g, b));
        changeBoostText();
      }
    }
    //println(r + " " + g + " " + b);
  } else if (theOscMessage.checkAddrPattern("/blue")==true) {          // blue
    b = (int) theOscMessage.get(0).floatValue();
    if (r != -1 && g != -1) {
      println(r + " " + g + " " + b);
      if (rgbRect != null) {
        rgbRect.setFill(color(r, g, b));
        changeBoostText();
      }
    }
    //println(r + " " + g + " " + b);
  } else if (theOscMessage.checkAddrPattern("/pause") == true) {       // play-pause
    changePlayingState();
    changePauseImg();
  } else if (theOscMessage.checkAddrPattern("/nextSong") == true) {    // next song
    avantiGUI();
  } else if (theOscMessage.checkAddrPattern("/prevSong") == true) {    // prev song
    indietroGUI();
  }
}

private void prepareExitHandler () {
  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
    public void run () {
      System.out.println("SHUTDOWN APP and SC");
      OscMessage startup = new OscMessage("/closeApp");
      oscP5.send(startup, myRemoteLocation);
    }
  }
  ));
}

/* A custom Controller that implements a scrollable menuList. Here the controller
 * uses a PGraphics element to render customizable list items. The menuList can be scrolled
 * using the scroll-wheel, touchpad, or mouse-drag. Items are triggered by a click. clicking
 * the scrollbar to the right makes the list scroll to the item correspoinding to the
 * click-location.
 */
class MenuList extends Controller<MenuList> {

  float pos, npos;
  int itemHeight = 120;
  int scrollerLength = 40;
  List< Map<String, Object>> items = new ArrayList< Map<String, Object>>();
  PGraphics menu;
  boolean updateMenu;

  MenuList(ControlP5 c, String theName, int theWidth, int theHeight) {
    super( c, theName, 0, 0, theWidth, theHeight );
    c.register( this );
    menu = createGraphics(getWidth(), getHeight() );

    setView(new ControllerView<MenuList>() {

      public void display(PGraphics pg, MenuList t ) {
        if (updateMenu) {
          updateMenu();
        }
        if (inside() ) {
          menu.beginDraw();
          int len = -(itemHeight * items.size()) + getHeight();
          int ty = int(map(pos, len, 0, getHeight() - scrollerLength - 2, 2 ) );
          menu.fill(255 );
          menu.rect(getWidth()-4, ty, 4, scrollerLength );
          menu.endDraw();
        }
        pg.image(menu, 0, 0);
      }
    }
    );
    updateMenu();
  }

  /* only update the image buffer when necessary - to save some resources */
  void updateMenu() {
    //PImage  coverSmall;
    //String value;
    int len = -(itemHeight * items.size()) + getHeight();
    npos = constrain(npos, len, 0);
    pos += (npos - pos) * 0.1;
    menu.beginDraw();
    menu.noStroke();
    menu.background(255, 64 );
    menu.textFont(cp5.getFont().getFont());
    menu.pushMatrix();
    menu.translate( 0, pos );
    menu.pushMatrix();

    int i0 = PApplet.max( 0, int(map(-pos, 0, itemHeight * items.size(), 0, items.size())));
    int range = ceil((float(getHeight())/float(itemHeight))+1);
    int i1 = PApplet.min( items.size(), i0 + range );

    menu.translate(0, i0*itemHeight);

    for (int i=i0; i<i1; i++) {
      //value = str(i +1);
      //coverSmall = loadImage(value + ".jpg");
      Map m = items.get(i);
      menu.fill(255, 100);
      menu.rect(0, 0, getWidth(), itemHeight-1 );
      menu.fill(255);
      menu.textFont(f1);
      menu.text(m.get("Title").toString(), 10, 20 );
      menu.textFont(f2);
      menu.textLeading(12);
      menu.text(m.get("Artist").toString(), 15, 50 );
      menu.text(m.get("copy").toString(), 20, 50, 120, 50 );
      //menu.image( coverSmall, 190, 30, 50, 50 );
      menu.image(coverSmall.get(i), 190, 10, 100, 100);
      menu.translate( 0, itemHeight );
    }
    menu.popMatrix();
    menu.popMatrix();
    menu.endDraw();
    updateMenu = abs(npos-pos)>0.01 ? true:false;
  }

  /* when detecting a click, check if the click happend to the far right, if yes, scroll to that position,
   * otherwise do whatever this item of the list is supposed to do.
   */
  public void onClick() {
    if (getPointer().x()>getWidth()-10) {
      npos= -map(getPointer().y(), 0, getHeight(), 0, items.size()*itemHeight);
      updateMenu = true;
    } else {
      int len = itemHeight * items.size();
      int index = int( map( getPointer().y() - pos, 0, len, 0, items.size() ) ) ;
      setValue(index);
    }
  }

  public void onMove() {
  }

  public void onDrag() {
    npos += getPointer().dy() * 2;
    updateMenu = true;
  }

  public void onScroll(int n) {
    npos += ( n * 4 );
    updateMenu = true;
  }

  void addItem(Map<String, Object> m) {
    items.add(m);
    updateMenu = true;
  }

  Map<String, Object> getItem(int theIndex) {
    return items.get(theIndex);
  }
}

class Song {

  //class variables
  String title;
  String artist;
  String desc;
  int image;

  Song(String title, String artist, String desc, int image) {
    this.title = title;
    this.artist = artist;
    this.desc = desc;
    this.image = image;
  }

  void setTitle(String title) {
    this.title = title;
  }

  String getTitle() {
    return this.title;
  }

  void setArtist(String artist) {
    this.artist = artist;
  }

  String getArtist() {
    return this.artist;
  }

  void setDesc(String desc) {
    this.desc =desc;
  }

  String getDesc() {
    return this.desc;
  }

  void setImage(int image) {
    this.image = image;
  }

  int getImage() {
    return this.image;
  }
}
