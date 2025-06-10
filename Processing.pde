import processing.serial.*;

Serial port;  
String arduinoPort = Serial.list()[0]; //シリアルポートに合わせて[]の値を変える
int[] sensorValues;  
boolean serialReady = false;

void setup() {
  size(1165, 860);
  background(0);
  frameRate(30);

  // シリアルポートを指定
  port = new Serial(this, arduinoPort, 9600);
  delay(100);  
  port.bufferUntil('\n');

  println("シリアル待機中...");
}

void draw() {
  background(0); // 画面をクリアして描画を更新
  noFill();
  stroke(255);
  strokeWeight(10);
  rect(100, 100, 965, 660); //外周
  line(1065, 250, 1015, 250); //右上ゴールサイド
  line(1065, 620, 1015, 620); //右下ゴールサイド
  line(100, 250, 150, 250); //左上ゴールサイド
  line(100, 620, 150, 620); //左下ゴールサイド
  line(225, 325, 225, 545); //左ゴールフロント
  line(940, 325, 940, 545); //右ゴールフロント
  arc(1015, 325, 150, 150, -PI, -PI/2); //右上ゴールアーク
  arc(1015, 545, 150, 150, PI/2, PI);   //右下ゴールアーク
  arc(150, 325, 150, 150, -PI/2, 0);    //左上ゴールアーク
  arc(150, 545, 150, 150, 0, PI/2);     //左下ゴールアーク
  strokeWeight(5);
  point(325, 275); //左上中立点
  point(325, 575); //左下中立点
  point(840, 275); //右上中立点
  point(840, 575); //右下中立点
  point(582, 430); //中心中立点
  strokeWeight(3);
  ellipse(582, 430, 300, 300); //中心円

  if (sensorValues != null) {
    noStroke();
    fill(255);
    ellipse(sensorValues[1], sensorValues[2], 110, 110); //機体
    
    pushMatrix();
    translate(sensorValues[1], sensorValues[2]);
    rotate(sensorValues[0] * PI / 180);
    stroke(255, 0, 0);
    strokeWeight(5);
    line(0, 0, 55, 0); //向いている方向（赤い線）
    popMatrix();
    
    if (sensorValues[3] != 0 || sensorValues[4] != 0) {
      fill(255, 128, 0);
      ellipse(sensorValues[1] - sensorValues[3], sensorValues[2] - sensorValues[4], 31, 31); //ボール
    }
  }
}

void serialEvent(Serial port) {
  String data = port.readStringUntil('\n');
  if (data != null) {
    String[] values = split(trim(data), ',');
    
    // READYメッセージの処理を削除
    
    try {
      int numValues = int(values[0]); 
      sensorValues = new int[numValues];
      
      for (int i = 0; i < numValues; i++) {
        sensorValues[i] = int(values[i + 1]);
      }
    } catch (Exception e) {
      println("シリアルデータの処理中にエラー: " + e);
    }
  }
}
