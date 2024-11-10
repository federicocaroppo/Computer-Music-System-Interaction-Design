import java.nio.*;
import KinectPV2.*;
import oscP5.*;
import netP5.*;
import controlP5.*;
import java.util.*;

KinectPV2 kinect;
ControlP5 cp5;
OscP5 oscP5;
NetAddress myRemoteLocation;

PFont mono;
PFont font;
PShape rec;
PShape play;
boolean recVisible=false;
boolean playVisible=false;

float r_h_x;
float r_h_y;
float l_h_x;
float l_h_y;
Slider r_h_x_slider;
Slider r_h_y_slider;
Slider l_h_x_slider;
Slider l_h_y_slider;
int sliderH=40;
int sliderW=450;
int marginX=100;
int marginY=100;

int  vertLoc;

//transformations
float a = 3.14;
int zval = 1100;
float scaleVal = 300;


//value to scale the depth point when accessing each individual point in the PC.
float scaleDepthPoint = 100.0;

//Distance Threashold
int maxD = 2500; // 4m
int minD = 0;  //  0m

//openGL object and shader
PGL     pgl;
PShader sh;

//VBO buffer location in the GPU
int vertexVboId;

public void setup() {
  size(1820, 980, P3D);
  frameRate(30);
  oscP5 = new OscP5(this, 7001);
  cp5 = new ControlP5(this);
  mono = createFont("Doctor Glitch.otf", 64);
  font=createFont("Doctor Glitch.otf", 12);
  rec=createShape(ELLIPSE, 300, 300, 300, 300);
  play=createShape(TRIANGLE, 0, 0, 0, 360, 280, 180);
  rec.setFill(color(200));
  rec.setStroke(color(200));
  play.setFill(color(200));
  play.setStroke(color(200));
  List l = Arrays.asList("Delay", "Reverb", "Phaser", "Flanger", "Distortion", "Harmonizer", "Tremolo", "Chorus", "None");
  
  cp5.addSlider("maxD")
     .setCaptionLabel("Visualizer max thresh")
     .setPosition(marginX, height - 65)
     .setRange(0,4000)
     .setSize(300,30)
     .setColorBackground(color(120, 120, 120))
     .setColorForeground(color(180, 180, 180))
     ;
  cp5.getController("maxD").setFont(font);
     
  cp5.addSlider("minD")
     .setCaptionLabel("Visualizer min thresh")
     .setPosition(width-marginX-370, height - 65)
     .setRange(0,4000)
     .setSize(300,30)
     .setColorBackground(color(120, 120, 120))
     .setColorForeground(color(180, 180, 180))
     ;
  cp5.getController("minD").setFont(font);
     
  r_h_y_slider = cp5.addSlider("r_h_y")
     .setCaptionLabel("")
     .setPosition(marginX, marginY)
     .setRange(0,1)
     .setValue(r_h_y)
     .setSize(sliderH,sliderW)
     .setColorBackground(color(120, 120, 120))
     .setColorForeground(color(180, 180, 180))
     ;
     cp5.getController("r_h_y").setFont(font);
     
  r_h_x_slider=cp5.addSlider("r_h_x")
     .setCaptionLabel("")
     .setPosition(marginX+sliderH+10, marginY)
     .setRange(0,1)
     .setValue(r_h_x)
     .setSize(sliderW,sliderH)
     .setColorBackground(color(120, 120, 120))
     .setColorForeground(color(180, 180, 180))
     ;  
     cp5.getController("r_h_x").setFont(font);
     
  l_h_y_slider=cp5.addSlider("l_h_y")
     .setCaptionLabel("")
     .setPosition(width-marginX-sliderH, marginY)
     .setRange(0,1)
     .setValue(l_h_y)
     .setSize(sliderH,sliderW)
     .setColorBackground(color(120, 120, 120))
     .setColorForeground(color(180, 180, 180))
     ;   
     cp5.getController("l_h_y").setFont(font);
     
  l_h_x_slider=cp5.addSlider("l_h_x")
     .setCaptionLabel("")
     .setPosition(width-marginX-sliderH-sliderW-10, marginY)
     .setRange(0,1)
     .setValue(l_h_x)
     .setSize(sliderW,sliderH)
     .setColorBackground(color(120, 120, 120))
     .setColorForeground(color(180, 180, 180))
     ;  
     cp5.getController("l_h_x").setFont(font);
  
  cp5.addScrollableList("dropdown1")
    .setCaptionLabel("Select Effect")
    .setPosition(marginX+sliderH+10, marginY+sliderH+10)
    .setSize(sliderW/2, 500)
    .setBarHeight(sliderH)
    .setItemHeight(sliderH)
    .addItems(l)
    .setOpen(false)
    .setColorBackground(color(120, 120, 120))
    .setColorForeground(color(180, 180, 180))
    ;
    cp5.getController("dropdown1").setFont(font);
    
  cp5.addScrollableList("dropdown2")
    .setCaptionLabel("Select Effect")
    .setPosition(width-marginX-sliderH-0.5*sliderW-10, marginY+sliderH+10)
    .setSize(sliderW/2, 500)
    .setBarHeight(sliderH)
    .setItemHeight(sliderH)
    .addItems(l)
    .setOpen(false)
    .setColorBackground(color(120, 120, 120))
    .setColorForeground(color(180, 180, 180))
    ;
    cp5.getController("dropdown2").setFont(font);
    
  myRemoteLocation = new NetAddress("127.0.0.1", 57120);

  kinect = new KinectPV2(this);

  kinect.enableDepthImg(true);

  kinect.enablePointCloud(true);

  kinect.setLowThresholdPC(minD);
  kinect.setHighThresholdPC(maxD);

  kinect.init();

  sh = loadShader("frag.glsl", "vert.glsl");

  PGL pgl = beginPGL();

  IntBuffer intBuffer = IntBuffer.allocate(1);
  pgl.genBuffers(1, intBuffer);

  //memory location of the VBO
  vertexVboId = intBuffer.get(0);

  endPGL();
}

public void draw() {
  background(0);
  
  //draw the depth capture images
  //image(kinect.getDepthImage(), 0, 0, 320, 240);
  //image(kinect.getPointCloudDepthImage(), 320, 0, 320, 240);

  //translate the scene to the center
  translate(width / 2, height * 3 / 4, zval);
  scale(scaleVal, -1 * scaleVal, scaleVal);
  rotate(a, 0.0f, 1.0f, 0.0f);

  // Threahold of the point Cloud.
  kinect.setLowThresholdPC(minD);
  kinect.setHighThresholdPC(maxD);

  //get the points in 3d space
  FloatBuffer pointCloudBuffer = kinect.getPointCloudDepthPos();

  // obtain XYZ the values of the point cloud
  /*
  stroke(0, 0, 0);
  for(int i = 0; i < kinect.WIDTHDepth * kinect.HEIGHTDepth; i+=3){
      float x = pointCloudBuffer.get(i*3 + 0) * scaleDepthPoint;
      float y = pointCloudBuffer.get(i*3 + 1) * scaleDepthPoint;
      float z = pointCloudBuffer.get(i*3 + 2) * scaleDepthPoint;
      
   
      point(x, y, z);
   }
   */

  //begin openGL calls and bind the shader
  pgl = beginPGL();
  sh.bind();

  //obtain the vertex location in the shaders.
  //useful to know what shader to use when drawing the vertex positions
  vertLoc = pgl.getAttribLocation(sh.glProgram, "vertex");

  pgl.enableVertexAttribArray(vertLoc);

  //data size times 3 for each XYZ coordinate
  int vertData = kinect.WIDTHDepth * kinect.HEIGHTDepth * 3;

  //bind vertex positions to the VBO
  {
    pgl.bindBuffer(PGL.ARRAY_BUFFER, vertexVboId);
    // fill VBO with data
    pgl.bufferData(PGL.ARRAY_BUFFER,   Float.BYTES * vertData, pointCloudBuffer, PGL.DYNAMIC_DRAW);
    // associate currently bound VBO with shader attribute
    pgl.vertexAttribPointer(vertLoc, 3, PGL.FLOAT, false,  Float.BYTES * 3, 0 );
  }
  
   // unbind VBOs
  pgl.bindBuffer(PGL.ARRAY_BUFFER, 0);

  //draw the point buffer as a set of POINTS
  pgl.drawArrays(PGL.POINTS, 0, vertData);

  //disable the vertex positions
  pgl.disableVertexAttribArray(vertLoc);

  //finish drawing
  sh.unbind();
  endPGL();

  
  camera();
  noLights();
  stroke(255);
  noFill();
  fill(200);
  text(round(frameRate) + " fps", 50, height - 50);
  push();
  textSize(50);
  textFont(mono);
  textAlign(CENTER);
  text("TELEKINESIS", width/2, 150);
  pop();
  
  push();
  scale(0.1);
  rec.setVisible(recVisible);
  play.setVisible(playVisible);
  shape(rec, width/2*10-450, 1650);
  shape(play, width/2*10+150, 1770);
  pop();
}

void dropdown1(int n) {
  
  OscMessage myMessage = new OscMessage("/dx");
  
  myMessage.add(n); /* add an int to the osc message */

  /* send the message */
  oscP5.send(myMessage, myRemoteLocation); 
}

void dropdown2(int n) {
  
  OscMessage myMessage = new OscMessage("/sx");
  
  myMessage.add(n); /* add an int to the osc message */

  /* send the message */
  oscP5.send(myMessage, myRemoteLocation); 
}
float prev_r_closed=0.0f;
float prev_l_closed=0.0f;

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  /* print the address pattern and the typetag of the received OscMessage */
  if(theOscMessage.checkAddrPattern("/p1/hand_r:tx")==true) {r_h_x_slider.setValue(theOscMessage.get(0).floatValue());}
  if(theOscMessage.checkAddrPattern("/p1/hand_r:ty")==true) {r_h_y_slider.setValue(theOscMessage.get(0).floatValue());}
  if(theOscMessage.checkAddrPattern("/p1/hand_l:tx")==true) {l_h_x_slider.setValue(theOscMessage.get(0).floatValue());}
  if(theOscMessage.checkAddrPattern("/p1/hand_l:ty")==true) {l_h_y_slider.setValue(theOscMessage.get(0).floatValue());}
  
  if(theOscMessage.checkAddrPattern("/p1/hand_r_closed")==true) {
    if(theOscMessage.get(0).floatValue()!=prev_r_closed){
      if(theOscMessage.get(0).floatValue()==1.0f){recVisible=true; playVisible=false;}else{recVisible=false; playVisible = true;}
      prev_r_closed=theOscMessage.get(0).floatValue();
    }
  }
  
  if(theOscMessage.checkAddrPattern("/p1/hand_l_closed")==true) {
    if(theOscMessage.get(0).floatValue()!=prev_l_closed){
      if(theOscMessage.get(0).floatValue()==1.0f){recVisible=true;}else{recVisible=false;}
      prev_l_closed=theOscMessage.get(0).floatValue();
    }
  }
    
  if(theOscMessage.checkAddrPattern("/p1/hands_touching")==true) {
  if(theOscMessage.get(0).floatValue()==1.0f){recVisible=false; playVisible=false;}
  }
}
