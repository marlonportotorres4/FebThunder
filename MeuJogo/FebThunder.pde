// ===================== Imports =====================
import java.util.HashSet;
import ddf.minim.*;
import java.util.Collections;
import java.util.Iterator;
import processing.video.*;

// ===================== VARIÁVEIS GLOBAIS =====================
enum Screen { INTRO, START, STORY, GAME, CREDITS, HIGHSCORES }
Screen currentScreen = Screen.INTRO;

Movie introVideo;
boolean videoFinished = false;
int videoEndTime = 0;

Button continueBtn;
String storyText = "Prepare-se para o combate, O LEGADO DA NAÇÃO BRASILEIRA DEPENDE DE VOCÊ!\nDestrua o máximo de aeronaves fascistas que conseguir e não deixe nenhum inimigo passar pelas nossas linhas de defesa.";
// Elementos de áudio
Minim minim;
AudioPlayer shootSound, playerDeathSound, enemyDeathSound, music, coinCollectSound;
boolean musicStarted = false;

// Assets gráficos
PImage bg, playerImg, coinImg, logoFeb, creditsBg, highscoresBg;
PImage[] enemies = new PImage[4];
PImage[] explosionFrames = new PImage[7];
PImage[] bulletFrames = new PImage[13];

// Entidades
ArrayList<Bullet> bullets = new ArrayList<Bullet>();
ArrayList<Enemy> enemiesList = new ArrayList<Enemy>();
ArrayList<Coin> coins = new ArrayList<Coin>();
ArrayList<Explosion> explosions = new ArrayList<Explosion>();

// Estado do jogo
Player player;
int score = 0;
boolean gameOver = false;
int lastEnemySpawn = 0;

// UI
Button startBtn, creditsBtn, highscoresBtn;
ArrayList<Integer> highScores = new ArrayList<Integer>();
PFont pixelFont;
color uiColor = #00FF88;

// ===================== CONFIGURAÇÃO INICIAL =====================
void setup() {
  size(1280, 720, P2D);
  frameRate(60);
  surface.setResizable(true);
  
  // Carregamento de assets
  bg = loadImage("data/backgrounds/sky.jpg");
  bg.resize(width, height);
  creditsBg = loadImage("data/backgrounds/credits_bg.jpg");
  creditsBg.resize(width, height);
  highscoresBg = loadImage("data/backgrounds/highscores_bg.jpg");
  highscoresBg.resize(width, height);
  
  playerImg = loadImage("data/sprites/player/player.png");
  logoFeb = loadImage("data/logo/logoFeb.png");
  
  for(int i = 0; i < 4; i++) {
    enemies[i] = loadImage("data/sprites/enemies/enemy"+(i+1)+".png");
  }
  
  PImage bulletSheet = loadImage("data/sprites/bullets/shoots.png");
  int bulletWidth = bulletSheet.width / 13;
  int bulletHeight = bulletSheet.height;
  for(int i = 0; i < 13; i++) {
    bulletFrames[i] = bulletSheet.get(i * bulletWidth, 0, bulletWidth, bulletHeight);
  }
  
  coinImg = loadImage("data/sprites/coin/coin.png");
  
  PImage explosionSheet = loadImage("data/sprites/explosions/explosions.png");
  int explosionWidth = explosionSheet.width / 7;
  for(int i = 0; i < 7; i++) {
    explosionFrames[i] = explosionSheet.get(i * explosionWidth, 0, explosionWidth, explosionSheet.height);
  }

  // Configuração de áudio
  minim = new Minim(this);
  shootSound = minim.loadFile("data/sounds/shoot.wav");
  playerDeathSound = minim.loadFile("data/sounds/playerDeath.wav");
  enemyDeathSound = minim.loadFile("data/sounds/enemyDeath.wav");
  music = minim.loadFile("data/sounds/music_loop.wav");
  coinCollectSound = minim.loadFile("data/sounds/coinCollect.wav");
  
  // Inicialização do jogador
  player = new Player();
  
  // Configuração da UI
  pixelFont = createFont("data/fonts/PressStart2P.ttf", 28);
  textFont(pixelFont);
  
  
  int btnWidth = 300;
  int btnHeight = 60;
  int btnYStart = height/2;
  
  startBtn = new Button("Iniciar Jogo", width/2 - btnWidth/2, btnYStart, btnWidth, btnHeight);
  creditsBtn = new Button("Créditos", width/2 - btnWidth/2, btnYStart + 100, btnWidth, btnHeight);
  highscoresBtn = new Button("Recordes", width/2 - btnWidth/2, btnYStart + 200, btnWidth, btnHeight);
  
  loadHighScores();
  //music.loop();
  
  introVideo = new Movie(this, sketchPath("data/videos/logo_intro.mp4"));
  introVideo.play();
}

void movieEvent(Movie m) {
  if (m == introVideo) {
    m.read();
    // Força redesenho imediato
    redraw();
  }
}

void playIntro() {
  image(introVideo, 0, 0, width, height);
  if (introVideo.duration() == introVideo.time()) {
    if (!videoFinished) {
      videoFinished = true;
      videoEndTime = millis();
    }
  }
}

// ===================== LOOP PRINCIPAL =====================
void draw() {
  switch(currentScreen) {
    case INTRO: introScreen(); break;
    case START: startScreen(); break;
    case STORY: storyScreen(); break;
    case GAME: gameScreen(); break;
    case CREDITS: creditsScreen(); break;
    case HIGHSCORES: highScoresScreen(); break;
  }
}

// ===================== TELAS =====================

void introScreen() {
  if (introVideo.available()) {
    introVideo.read();
  }
  image(introVideo, 0, 0, width, height);
  
  if (introVideo.time() >= introVideo.duration() - 0.2) {
    currentScreen = Screen.START;
    introVideo.pause();
    
    // Inicia a música apenas uma vez
    if (!musicStarted) {
      music.loop();
      musicStarted = true;
    }
  }
}

void startScreen() {
  background(bg);
  imageMode(CENTER);
  image(logoFeb, width/2, height/4, logoFeb.width * 0.8, logoFeb.height * 0.8);
  textFont(pixelFont);
  textSize(32);
  
  startBtn.display();
  creditsBtn.display();
  highscoresBtn.display();
}

void gameScreen() {
  if(gameOver) {
    gameOverScreen();
    return;
  }
  
  background(bg);
  player.update();
  player.display();
  
  handleEnemies();
  handleBullets();
  handleCoins();
  handleExplosions();
  checkCollisions();
  
  // UI
  fill(0, 180);
  noStroke();
  rect(15, 15, 240, 90, 10);
  fill(uiColor);
  textSize(18);
  textAlign(LEFT, TOP);
  text("PONTOS: " + score, 30, 30);
  text("VIDA: " + player.health, 30, 70);
  stroke(uiColor);
  noFill();
  strokeWeight(3);
  rect(15, 15, 240, 90, 10);
}

void storyScreen() {
  background(bg);
  
  // Balão de texto
  float balloonW = width * 0.7;
  float balloonH = height * 0.5;
  float balloonX = width/2 - balloonW/2;
  float balloonY = height/2 - balloonH/2;
  
  // Corpo do balão
  fill(255);
  stroke(0);
  strokeWeight(2);
  rect(balloonX, balloonY, balloonW, balloonH, 20);
  
  // Triângulo inferior
  float triangleY = balloonY + balloonH;
  beginShape();
  vertex(width/2 - 30, triangleY);
  vertex(width/2, triangleY + 40);
  vertex(width/2 + 30, triangleY);
  endShape(CLOSE);
  
  // Texto
  fill(0);
  textSize(28);
  textAlign(CENTER, CENTER);
  text(storyText, balloonX + 40, balloonY + 40, balloonW - 80, balloonH - 80);
  
  // Botão Continuar
  continueBtn = new Button("Continuar", width/2 - 100, balloonY + balloonH + 60, 200, 50);
  continueBtn.display();
}

void creditsScreen() {
  background(creditsBg);
  textFont(pixelFont);
  textSize(35);
  fill(#FFD700);
  textAlign(CENTER, TOP);
  text("Créditos", width/2, 50);
  
  
  fill(255);
  textSize(32);
  text("Desenvolvedora: Lógica de Amigação", width/2, 180);
  text("Integrantes:", width/2, 240);
  text("Marlon Torres", width/2, 300);
  text("Nivaldo Arruda", width/2, 360);
  text("Kaian Guthierry", width/2, 420);
  
  startBtn.label = "Voltar";
  startBtn.y = height - 120;
  startBtn.display();
}

void highScoresScreen() {
  background(highscoresBg);
  textFont(pixelFont);
  textSize(35);
  fill(#FFD700);
  textAlign(CENTER, TOP);
  text("Recordes", width/2, 50);
  
  
  fill(255);
  textSize(36);
  int y = 180;
  for(int i = 0; i < highScores.size(); i++) {
    text((i+1) + ". " + nf(highScores.get(i), 5), width/2, y);
    y += 60;
  }
  
  startBtn.label = "Voltar";
  startBtn.y = height - 120;
  startBtn.display();
}

void gameOverScreen() {
  fill(0, 150);
  rect(0, 0, width, height);
  fill(#FF0000);
  textFont(pixelFont);
  textAlign(CENTER, CENTER);
  text("FIM DE JOGO", width/2, height/2 - 50);
  fill(255);
  text("Pontuação: " + score, width/2, height/2 + 30);
  
  startBtn.label = "Menu Principal";
  startBtn.y = height - 150;
  startBtn.display();
  saveHighScore();
}

// ===================== CONTROLES =====================
void mousePressed() {
  if(currentScreen == Screen.START) {
    if(startBtn.isMouseOver()) {
      currentScreen = Screen.STORY; // Muda para tela de história
      resetGame();
    }
    if(creditsBtn.isMouseOver()) currentScreen = Screen.CREDITS;
    if(highscoresBtn.isMouseOver()) currentScreen = Screen.HIGHSCORES;
  }
   else if(currentScreen == Screen.STORY) {
    if(continueBtn.isMouseOver()) {
      currentScreen = Screen.GAME;
    }
  }
  else if(currentScreen == Screen.CREDITS || currentScreen == Screen.HIGHSCORES) {
    if(startBtn.isMouseOver()) {
      currentScreen = Screen.START;
      resetButtons();
    }
  }
  else if(currentScreen == Screen.GAME && gameOver) {
    if(startBtn.isMouseOver()) {
      currentScreen = Screen.START;
      gameOver = false;
      resetGame();
      resetButtons();
      music.rewind();
      music.play();
    }
  }
}

void keyPressed() {
  if(keyCode == UP) player.moveUp = true;
  if(keyCode == DOWN) player.moveDown = true;
  if(keyCode == LEFT) player.moveLeft = true;
  if(keyCode == RIGHT) player.moveRight = true;
  if(key == ' ') player.shoot();
}

void keyReleased() {
  if(keyCode == UP) player.moveUp = false;
  if(keyCode == DOWN) player.moveDown = false;
  if(keyCode == LEFT) player.moveLeft = false;
  if(keyCode == RIGHT) player.moveRight = false;
}

void resetButtons() {
  startBtn.label = "Iniciar Jogo";
  startBtn.y = height/2;
  creditsBtn.y = height/2 + 100;
  highscoresBtn.y = height/2 + 200;
}

// ===================== CLASSES =====================
class Button {
  String label;
  float x, y, w, h;
  
  Button(String label, float x, float y, float w, float h) {
    this.label = label;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }
  
  void display() {
    fill(isMouseOver() ? #6464C8 : #323296);
    stroke(255);
    rect(x, y, w, h, 10);
    fill(255);
    textFont(pixelFont);
    textSize(20);
    textAlign(CENTER, CENTER);
    text(label, x + w/2, y + h/2);
  }
  
  boolean isMouseOver() {
    return mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h;
  }
}

class Player {
  PVector pos = new PVector(100, height/2);
  float speed = 5;
  int health = 100;
  boolean moveUp, moveDown, moveLeft, moveRight;
  int shootCooldown = 0;

  void update() {
    if(moveUp) pos.y -= speed;
    if(moveDown) pos.y += speed;
    if(moveLeft) pos.x -= speed;
    if(moveRight) pos.x += speed;
    
    pos.x = constrain(pos.x, 0, width-80);
    pos.y = constrain(pos.y, 0, height-80);
    
    if(shootCooldown > 0) shootCooldown--;
  }
  
  void shoot() {
    if(shootCooldown <= 0) {
      bullets.add(new Bullet(pos.x + 80, pos.y + 40));
      shootSound.rewind();
      shootSound.play();
      shootCooldown = 15;
    }
  }
  
  void display() {
    pushMatrix();
    translate(pos.x + 40, pos.y + 40);
    rotate(HALF_PI);
    imageMode(CENTER);
    image(playerImg, 0, 0, 80, 80);
    popMatrix();
  }
}

class Bullet {
  PVector pos;
  float speed = 10;
  int frame = 0;
  int lastUpdate = 0;

  Bullet(float x, float y) {
    pos = new PVector(x, y);
    lastUpdate = millis();
  }
  
  void update() {
    pos.x += speed;
    if(millis() - lastUpdate > 50) {
      frame = (frame + 1) % 13;
      lastUpdate = millis();
    }
  }
  
  void display() {
    pushMatrix();
    translate(pos.x, pos.y);
    imageMode(CENTER);
    image(bulletFrames[frame], 0, 0, 150, 50);
    popMatrix();
  }
}

class Enemy {
  PVector pos = new PVector(width + 100, random(100, height-100));
  int type = (int)random(4);
  float speed = map(type, 0, 3, 2, 5);
  int health = 1;

  void update() { pos.x -= speed; }
  
  void display() {
    pushMatrix();
    translate(pos.x + 40, pos.y + 40);
    rotate(-HALF_PI);
    imageMode(CENTER);
    image(enemies[type], 0, 0, 80, 80);
    popMatrix();
  }
}

class Coin {
  PVector pos = new PVector(width + 50, random(100, height-100));
  float speed = 3;

  void update() { pos.x -= speed; }
  
  void display() {
    image(coinImg, pos.x, pos.y, 30, 30);
  }
}

class Explosion {
  PVector pos;
  int frame = 0;
  int lastUpdate = 0;
  boolean finished = false;

  Explosion(float x, float y) {
    pos = new PVector(x, y);
    lastUpdate = millis();
  }
  
  void update() {
    if(millis() - lastUpdate > 50) {
      frame++;
      lastUpdate = millis();
      if(frame >= 7) finished = true;
    }
  }
  
  void display() {
    if(!finished) image(explosionFrames[frame], pos.x-0, pos.y-0, 80, 80);
  }
}

// ===================== LÓGICA DO JOGO =====================
void resetGame() {
  gameOver = false;
  player.health = 100;
  score = 0;
  bullets.clear();
  enemiesList.clear();
  coins.clear();
  explosions.clear();
  player.pos.set(100, height/2);
  music.rewind();
  music.loop();
  if (currentScreen == Screen.INTRO) {
    introVideo.jump(0); // Reinicia para início
    introVideo.play();
  }
  musicStarted = true;
  if (!music.isPlaying()) {
    music.rewind();
    music.play();
  }
  if(currentScreen == Screen.STORY) {
    gameOver = false;
    player.health = 100;
    score = 0;
    bullets.clear();
    enemiesList.clear();
    coins.clear();
    explosions.clear();
    player.pos.set(100, height/2);
  }
}


// ===================== CORREÇÃO DE HIGHSCORES =====================
void loadHighScores() {
  String[] scores = loadStrings("highscores.txt");
  highScores.clear();
  
  if(scores != null) {
    for(String s : scores) {
      int scoreValue = Integer.parseInt(s.trim());
      if (!highScores.contains(scoreValue)) {
        highScores.add(scoreValue);
      }
    }
    Collections.sort(highScores, Collections.reverseOrder());
    
    // Garantir máximo de 5 scores
    while(highScores.size() > 5) {
      highScores.remove(highScores.size() - 1);
    }
  } else {
    // Valores padrão únicos
    int[] defaultScores = {1500, 1200, 900, 700, 500};
    for(int s : defaultScores) {
      highScores.add(s);
    }
  }
}

void saveHighScore() {
  // Adicionar apenas se for maior que o menor score
  int minScore = highScores.size() > 0 ? highScores.get(highScores.size()-1) : 0;
  if(score > minScore || highScores.size() < 5) {
    highScores.add(score);
    Collections.sort(highScores, Collections.reverseOrder());
    
    // Remover duplicatas
    HashSet<Integer> uniqueScores = new HashSet<>(highScores);
    highScores.clear();
    highScores.addAll(uniqueScores);
    Collections.sort(highScores, Collections.reverseOrder());
    
    // Manter apenas top 5
    while(highScores.size() > 5) {
      highScores.remove(highScores.size()-1);
    }
    
    // Salvar arquivo
    String[] scores = new String[highScores.size()];
    for(int i=0; i<highScores.size(); i++) {
      scores[i] = str(highScores.get(i));
    }
    saveStrings("highscores.txt", scores);
  }
}

void handleEnemies() {
  if (millis() - lastEnemySpawn > 1000) {
    enemiesList.add(new Enemy());
    lastEnemySpawn = millis();
  }
  
  Iterator<Enemy> enemyIterator = enemiesList.iterator();
  while (enemyIterator.hasNext()) {
    Enemy e = enemyIterator.next();
    e.update();
    e.display();
    
    if (e.pos.x < -100) {
      player.health -= 20;
      explosions.add(new Explosion(0, e.pos.y));
      enemyDeathSound.rewind();
      enemyDeathSound.play();
      enemyIterator.remove();
      
      if (player.health <= 0) {
        gameOver = true;
        playerDeathSound.rewind();
        playerDeathSound.play();
        explosions.add(new Explosion(player.pos.x + 40, player.pos.y + 40));
        music.pause();
      }
    }
  }
}

void handleBullets() {
  Iterator<Bullet> bulletIterator = bullets.iterator();
  while (bulletIterator.hasNext()) {
    Bullet b = bulletIterator.next();
    b.update();
    b.display();
    if (b.pos.x > width + 100) bulletIterator.remove();
  }
}

void handleCoins() {
  if (frameCount % 300 == 0) coins.add(new Coin());
  
  Iterator<Coin> coinIterator = coins.iterator();
  while (coinIterator.hasNext()) {
    Coin c = coinIterator.next();
    c.update();
    c.display();
    if (c.pos.x < -50) coinIterator.remove();
  }
}

void handleExplosions() {
  Iterator<Explosion> explosionIterator = explosions.iterator();
  while (explosionIterator.hasNext()) {
    Explosion exp = explosionIterator.next();
    exp.update();
    exp.display();
    if (exp.finished) explosionIterator.remove();
  }
}

void checkCollisions() {
  Iterator<Bullet> bulletIterator = bullets.iterator();
  while (bulletIterator.hasNext()) {
    Bullet b = bulletIterator.next();
    Iterator<Enemy> enemyIterator = enemiesList.iterator();
    while (enemyIterator.hasNext()) {
      Enemy e = enemyIterator.next();
      if (dist(b.pos.x, b.pos.y, e.pos.x + 40, e.pos.y + 40) < 40) {
        explosions.add(new Explosion(e.pos.x, e.pos.y));
        enemyIterator.remove();
        bulletIterator.remove();
        score += 100;
        enemyDeathSound.rewind();
        enemyDeathSound.play();
        break;
      }
    }
  }
  
  Iterator<Coin> coinIterator = coins.iterator();
  while (coinIterator.hasNext()) {
    Coin c = coinIterator.next();
    if (dist(player.pos.x + 40, player.pos.y + 40, c.pos.x + 15, c.pos.y + 15) < 30) {
      coinIterator.remove();
      score += 200;
      coinCollectSound.rewind();
      coinCollectSound.play();
      break;
    }
  }

// Nova verificação de colisão entre player e inimigos
  Iterator<Enemy> enemyCollisionIterator = enemiesList.iterator();
  while (enemyCollisionIterator.hasNext()) {
    Enemy e = enemyCollisionIterator.next();
    // Calcula distância entre centros do player e inimigo
    float distance = dist(
        player.pos.x + 40,  // Centro X do player
        player.pos.y + 40,  // Centro Y do player
        e.pos.x + 40,       // Centro X do inimigo
        e.pos.y + 40        // Centro Y do inimigo
    );

    // Colisão ocorre se a distância for menor que a soma dos raios (40 + 40)
    if (distance < 80) {
        explosions.add(new Explosion(e.pos.x, e.pos.y));
        enemyCollisionIterator.remove();
        enemyDeathSound.rewind();
        enemyDeathSound.play();
        player.health -= 20; // Dano ao player
        
        // Verifica morte do player
        if (player.health <= 0) {
            gameOver = true;
            playerDeathSound.rewind();
            playerDeathSound.play();
            explosions.add(new Explosion(player.pos.x + 40, player.pos.y + 40));
            music.pause();
        }
    }
}

}
