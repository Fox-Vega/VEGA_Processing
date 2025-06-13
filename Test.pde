import processing.serial.*;

Serial port;
String arduinoPort;
int[] sensorValues;
boolean serialReady = false;

void setup() {
  size(1165, 860);
  background(0);
  frameRate(30);

  ball_offset = 0.5;

  // シリアルポートの確認
  String[] availablePorts = Serial.list();
  if (availablePorts.length > 0) {
    arduinoPort = availablePorts[0]; // 最初のポートを選択
    port = new Serial(this, arduinoPort, 9600);
    delay(100);
    port.bufferUntil('\n');
    println("シリアル待機中...");
  } else {
    println("エラー: 利用可能なシリアルポートがありません！");
    exit(); // プログラムを停止
  }

  sensorValues = new int[8]; // 初期化
}

void draw() {
  background(0); // 画面をクリアして描画を更新
  if (sensorValues != null && sensorValues.length >= 8) {
    if (sensorValues[0] == 0 || sensorValues[0] == 1) {
      noFill();
      stroke(255);
      strokeWeight(10);
      rect(100, 100, 965, 660); // 外周
      line(1065, 250, 1015, 250);
      line(1065, 620, 1015, 620);
      line(100, 250, 150, 250);
      line(100, 620, 150, 620);
      line(225, 325, 225, 545);
      line(940, 325, 940, 545);
      arc(1015, 325, 150, 150, -PI, -PI/2);
      arc(1015, 545, 150, 150, PI/2, PI);
      arc(150, 325, 150, 150, -PI/2, 0);
      arc(150, 545, 150, 150, 0, PI/2);
      strokeWeight(5);
      point(325, 275);
      point(325, 575);
      point(840, 275);
      point(840, 575);
      point(582, 430);
      strokeWeight(3);
      ellipse(582, 430, 300, 300);

      noStroke();
      fill(255);
      ellipse(sensorValues[2], sensorValues[3], 110, 110);

      pushMatrix();
      translate(sensorValues[2], sensorValues[3]);
      rotate(sensorValues[1] * PI / 180);
      stroke(255, 0, 0);
      strokeWeight(5);
      line(0, 0, 55, 0);

      if (sensorValues[0] == 1) {
        rotate(sensorValues[6] * PI / 180);
        stroke(0, 255, 0);
        strokeWeight(5);
        line(0, 0, sensorValues[7], 0);
      }
      popMatrix();

      if (sensorValues[4] != 0 || sensorValues[5] != 0) {
        noStroke();
        fill(255, 128, 0);
        ellipse(sensorValues[2] - (sensorValues[4] * ball_offset), sensorValues[3] - (sensorValues[5] * ball_offset), 31, 31);
      }
    } else if (sensorValues[0] == 2) {
      textAlign(CENTER, CENTER);
      textSize(12);
      translate(width / 2, height / 2);

      int total = 24;
      float radius = 150;

      stroke(255);
      fill(0);
      for (int i = 0; i < total; i++) {
        float angle = TWO_PI / total * i;
        float x = cos(angle) * radius;
        float y = sin(angle) * radius;

        ellipse(x, y, 30, 30);
        fill(255);
        noStroke();
        text(i + 1, x, y);

        stroke(255);
        fill(0);
      }
    }
  }
}

void serialEvent(Serial port) {
  String data = port.readStringUntil('\n');
  if (data != null) {
    String[] values = split(trim(data), ',');

    if (values.length > 1) {
      try {
        int numValues = int(values[0]);
        sensorValues = new int[numValues];

        for (int i = 0; i < numValues; i++) {
          sensorValues[i] = int(values[i + 1]);
        }
      } catch (Exception e) {
        println("シリアルデータ処理エラー: " + e);
      }
    } else {
      println("受信データが不足しています！");
    }
  }
}
