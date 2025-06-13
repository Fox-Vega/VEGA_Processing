import processing.serial.*;
import controlP5.*;

final int PIXELS = 16;
float radius;
PVector center;

// HSB 管理
float[] pixelHue       = new float[PIXELS];
float brightness       = 1.0;
color[] pixelCols      = new color[PIXELS];
boolean[] selectedMask = new boolean[PIXELS];

// UI
ControlP5 cp5;
Slider sHue, sBright;
Serial  myPort;

// スライダー諸元
float hueLen, sliH = 20;
float sliSpacing = 30;

void setup(){
  size(600, 600);
  colorMode(HSB, 255);
  center = new PVector(width/2, height/2);
  radius = width * 0.35;
  
  // 初期色・選択解除
  for(int i=0; i<PIXELS; i++){
    pixelHue[i]       = 0;
    pixelCols[i]      = color(0, 255, 255);
    selectedMask[i]   = false;
  }
  
  // シリアル
  println(Serial.list());
  myPort = new Serial(this, Serial.list()[0], 9600);
  myPort.buffer(4);
  myPort.clear();
  
  // ControlP5
  cp5 = new ControlP5(this);
  hueLen = radius * 1.2;
  
  float hueX = center.x - hueLen/2;
  float hueY = center.y - sliH/2;
  sHue = cp5.addSlider("Hue")
           .setPosition(hueX, hueY)
           .setSize(hueLen, sliH)
           .setRange(0, 255)
           .hideLabel();
  
  float briX = hueX;
  float briY = hueY + sliH + sliSpacing;
  sBright = cp5.addSlider("Brightness")
               .setPosition(briX, briY)
               .setSize(hueLen, sliH)
               .setRange(0, 1)
               .setValue(brightness)
               .hideLabel();
}

void draw(){
  background(32);
  noStroke();
  
  // --- 円描画 & ハイライト ---
  for(int i=0; i<PIXELS; i++){
    float a = TWO_PI * i/PIXELS - HALF_PI;
    float x = center.x + cos(a)*radius;
    float y = center.y + sin(a)*radius;
    fill(pixelCols[i]);
    ellipse(x, y, 50, 50);
    if(selectedMask[i]){
      stroke(255);
      strokeWeight(3);
      noFill();
      ellipse(x, y, 60, 60);
      noStroke();
    }
  }
  
  // --- スライダー背景グラデーション ---
  drawHueBar();
  drawBriBar();
  
  // --- ControlP5 のノブだけ上書き ---
  cp5.draw();
}

void controlEvent(ControlEvent ev){
  // Hue
  if(ev.isFrom(sHue)){
    float h = sHue.getValue();
    for(int i=0; i<PIXELS; i++){
      if(selectedMask[i]){
        pixelHue[i]  = h;
        pixelCols[i] = color(h, 255, brightness*255);
        sendColor(i, (int)h, (int)(brightness*255));
      }
    }
  }
  // Brightness
  if(ev.isFrom(sBright)){
    brightness = sBright.getValue();
    for(int i=0; i<PIXELS; i++){
      if(selectedMask[i]){
        pixelCols[i] = color(pixelHue[i], 255, brightness*255);
        sendColor(i, (int)pixelHue[i], (int)(brightness*255));
      }
    }
  }
}

// クリックでトグル選択／解除。スライダー領域は無視。
void mousePressed(){
  if(overHueBar() || overBriBar()) return;
  for(int i=0; i<PIXELS; i++){
    float a = TWO_PI * i/PIXELS - HALF_PI;
    float x = center.x + cos(a)*radius;
    float y = center.y + sin(a)*radius;
    if(dist(mouseX, mouseY, x, y) < 25){
      // トグル
      selectedMask[i] = !selectedMask[i];
      // 選択したらスライダーを同期
      if(selectedMask[i]){
        sHue.setValue(pixelHue[i]);
        sBright.setValue(brightness);
      }
      return;
    }
  }
}

// 虹色バー（横）
void drawHueBar(){
  pushStyle();
  colorMode(HSB,255);
  float x0 = sHue.getPosition().x;
  float y0 = sHue.getPosition().y;
  for(int i=0; i<hueLen; i++){
    stroke(map(i,0,hueLen,0,255),255,255);
    line(x0+i, y0, x0+i, y0+sliH);
  }
  popStyle();
  colorMode(RGB,255);
}

// 明暗バー（横：黒→白）
void drawBriBar(){
  pushStyle();
  float x0 = sBright.getPosition().x;
  float y0 = sBright.getPosition().y;
  for(int i=0; i<hueLen; i++){
    float v = map(i,0,hueLen,0,255);
    stroke(v);
    line(x0+i, y0, x0+i, y0+sliH);
  }
  popStyle();
}

// スライダー領域判定
boolean overHueBar(){
  float x=sHue.getPosition().x, y=sHue.getPosition().y;
  return mouseX>=x && mouseX<=x+hueLen
      && mouseY>=y && mouseY<=y+sliH;
}
boolean overBriBar(){
  float x=sBright.getPosition().x, y=sBright.getPosition().y;
  return mouseX>=x && mouseX<=x+hueLen
      && mouseY>=y && mouseY<=y+sliH;
}

// シリアル送信：idx, hue, brightness(0–255)
void sendColor(int idx, int hue, int bri){
  myPort.write(idx);
  myPort.write(hue);
  myPort.write(bri);
}
