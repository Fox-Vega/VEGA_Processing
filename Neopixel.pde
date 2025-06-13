import processing.serial.*;
import controlP5.*;
import java.awt.BasicStroke;
import java.awt.Graphics2D;

final int PIXELS = 16;
float radius;
PVector center;

// 色相(Hue)、明暗(Brightness)、オン／オフ、選択マスク、描画色
float[] pixelHue       = new float[PIXELS];
boolean[] pixelOn      = new boolean[PIXELS];
boolean[] selectedMask = new boolean[PIXELS];
color[] pixelCols      = new color[PIXELS];
float brightness       = 1.0;

// UI
ControlP5 cp5;
Slider sHue, sBright;
Serial  myPort;

// スライダー長さ・高さ・間隔
float hueLen, sliH = 20, sliSpacing = 30;

void setup(){
  size(600, 600);
  smooth();
  colorMode(HSB, 255);
  center = new PVector(width/2, height/2);
  radius = width * 0.35;

  // 初期化
  for(int i=0; i<PIXELS; i++){
    pixelHue[i]       = 0;
    pixelOn[i]        = true;
    selectedMask[i]   = false;
    pixelCols[i]      = color(0, 255, 255);
  }

  // シリアル初期化
  println(Serial.list());
  myPort = new Serial(this, Serial.list()[0], 9600);
  myPort.buffer(4);
  myPort.clear();

  // UI初期化
  cp5 = new ControlP5(this);
  hueLen = radius * 1.2;
  float hueX = center.x - hueLen/2;
  float hueY = center.y - sliH/2;

  // 虹色スライダー（横）
  sHue = cp5.addSlider("Hue")
           .setPosition(hueX, hueY)
           .setSize(hueLen, sliH)
           .setRange(0, 255)
           .hideLabel();

  // 明暗スライダー（虹色の下）
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
  noFill();

  // ① 16個の円表示
  for(int i=0; i<PIXELS; i++){
    float a = TWO_PI * i/PIXELS - HALF_PI;
    float x = center.x + cos(a)*radius;
    float y = center.y + sin(a)*radius;

    // 塗りつぶし：オフは黒
    fill(pixelOn[i] ? pixelCols[i] : color(0));
    ellipse(x, y, 50, 50);

    // 枠線：選択中＞オン＞オフ
    if(selectedMask[i]){
      stroke(255, 0, 0);          // 赤実線
      strokeWeight(3);
      ellipse(x, y, 60, 60);
      noStroke();
    } 
    else if(pixelOn[i]){
      stroke(255);                // 白実線
      strokeWeight(2);
      ellipse(x, y, 60, 60);
      noStroke();
    } 
    else {
      // 白点線
      Graphics2D g2 = (Graphics2D)g.drawingContext;
      g2.setStroke(new BasicStroke(
        1, BasicStroke.CAP_BUTT, BasicStroke.JOIN_BEVEL,
        0, new float[]{5,5}, 0
      ));
      stroke(255);
      noFill();
      ellipse(x, y, 60, 60);
      g2.setStroke(new BasicStroke());  // 実線に戻す
      noStroke();
    }
  }

  // ② スライダー背景グラデーション
  drawHueBar();
  drawBriBar();

  // ③ ControlP5 のノブを最前面に描画
  cp5.draw();
}

// スライダー操作イベント
void controlEvent(ControlEvent ev){
  if(ev.isFrom(sHue)){
    float h = sHue.getValue();
    for(int i=0; i<PIXELS; i++){
      if(selectedMask[i]){
        pixelHue[i]  = h;
        pixelCols[i] = color(h, 255, brightness*255);
        sendColor(i, (int)h, pixelOn[i] ? (int)(brightness*255) : 0);
      }
    }
  }
  if(ev.isFrom(sBright)){
    brightness = sBright.getValue();
    for(int i=0; i<PIXELS; i++){
      pixelCols[i] = color(pixelHue[i], 255, brightness*255);
      sendColor(i, (int)pixelHue[i], pixelOn[i] ? (int)(brightness*255) : 0);
    }
  }
}

// クリックイベント：左クリックで選択トグル、右クリックでオン／オフ
void mousePressed(){
  if(overHueBar() || overBriBar()) return;

  for(int i=0; i<PIXELS; i++){
    float a = TWO_PI * i/PIXELS - HALF_PI;
    float x = center.x + cos(a)*radius;
    float y = center.y + sin(a)*radius;
    if(dist(mouseX, mouseY, x, y) < 25){
      if(mouseButton == LEFT){
        selectedMask[i] = !selectedMask[i];
        if(selectedMask[i]) sHue.setValue(pixelHue[i]);
      }
      else if(mouseButton == RIGHT){
        pixelOn[i] = !pixelOn[i];
        sendColor(i,
          (int)pixelHue[i],
          pixelOn[i] ? (int)(brightness*255) : 0
        );
      }
      return;
    }
  }
}

// 虹色グラデーションバー描画
void drawHueBar(){
  pushStyle();
  colorMode(HSB, 255);
  float x0 = sHue.getPosition().x;
  float y0 = sHue.getPosition().y;
  for(int i=0; i<hueLen; i++){
    stroke(map(i, 0, hueLen, 0, 255), 255, 255);
    line(x0 + i, y0, x0 + i, y0 + sliH);
  }
  popStyle();
  colorMode(RGB, 255);
}

// 明暗グラデーションバー描画（黒→白）
void drawBriBar(){
  pushStyle();
  float x0 = sBright.getPosition().x;
  float y0 = sBright.getPosition().y;
  for(int i=0; i<hueLen; i++){
    float v = map(i, 0, hueLen, 0, 255);
    stroke(v);
    line(x0 + i, y0, x0 + i, y0 + sliH);
  }
  popStyle();
}

// マウスが虹色バー上かどうか
boolean overHueBar(){
  float x = sHue.getPosition().x, y = sHue.getPosition().y;
  return mouseX>=x && mouseX<=x+hueLen
      && mouseY>=y && mouseY<=y+sliH;
}
// マウスが明暗バー上かどうか
boolean overBriBar(){
  float x = sBright.getPosition().x, y = sBright.getPosition().y;
  return mouseX>=x && mouseX<=x+hueLen
      && mouseY>=y && mouseY<=y+sliH;
}

// シリアル送信：idx, hue(0–255), bri(0–255)
void sendColor(int idx, int hue, int bri){
  myPort.write(idx);
  myPort.write(hue);
  myPort.write(bri);
}
