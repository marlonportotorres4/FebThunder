

// ===================== BIBLIOTECAS =====================
import ddf.minim.*;  // Para controle de áudio

// ===================== VARIÁVEIS GLOBAIS =====================
// Sistema de áudio
Minim minim;
AudioPlayer shootSound, playerDeathSound, enemyDeathSound, music;

// Assets gráficos
PImage bg;                  // Imagem de fundo
PImage playerImg;           // Sprite do jogador
PImage[] enemies = new PImage[4];   // Sprites dos 4 tipos de inimigos
PImage[] explosionFrames = new PImage[7];  // Frames de explosão
PImage[] bulletFrames = new PImage[13];    // Frames de animação do tiro
PImage coinImg;             // Sprite da moeda

// Listas de entidades
ArrayList<Bullet> bullets = new ArrayList<Bullet>();     // Tiros ativos
ArrayList<Enemy> enemiesList = new ArrayList<Enemy>();   // Inimigos ativos
ArrayList<Coin> coins = new ArrayList<Coin>();           // Moedas coletáveis
ArrayList<Explosion> explosions = new ArrayList<Explosion>(); // Explosões

// Estado do jogo
Player player;      // Objeto do jogador
int score = 0;      // Pontuação
boolean gameOver = false; // Controle de fim de jogo

// ===================== CONFIGURAÇÃO INICIAL =====================
void setup() {
  size(1280, 720, P2D);  // Tamanho inicial com aceleração gráfica
  frameRate(60);         // FPS fixo
  surface.setResizable(true);  // Permite redimensionar janela
  
  // Carrega background e redimensiona
  bg = loadImage("data/backgrounds/sky.jpg");
  bg.resize(width, height);  // Ajusta ao tamanho da janela
  
  // Carrega sprites do jogador
  playerImg = loadImage("data/sprites/player/player.png");
  
  // Carrega sprites dos inimigos (4 tipos)
  for(int i = 0; i < 4; i++) {
    enemies[i] = loadImage("data/sprites/enemies/enemy"+(i+1)+".png");
  }
  
  // Carrega spritesheet de tiros (13 frames)
  PImage bulletSheet = loadImage("data/sprites/bullets/shoots.png");
  int bulletWidth = bulletSheet.width / 13;
  for(int i = 0; i < 13; i++) {
    bulletFrames[i] = bulletSheet.get(i * bulletWidth, 0, bulletWidth, bulletSheet.height);
  }
  
  // Carrega sprite da moeda
  coinImg = loadImage("data/sprites/coin/coin.png");
  
  // Carrega spritesheet de explosão (7 frames)
  PImage explosionSheet = loadImage("data/sprites/explosions/explosions.png");
  int explosionWidth = explosionSheet.width / 7;
  for(int i = 0; i < 7; i++) {
    explosionFrames[i] = explosionSheet.get(i * explosionWidth, 0, explosionWidth, explosionSheet.height);
  }

  // Configura áudio
  minim = new Minim(this);
  shootSound = minim.loadFile("data/sounds/shoot.wav");
  playerDeathSound = minim.loadFile("data/sounds/playerDeath.wav");
  enemyDeathSound = minim.loadFile("data/sounds/enemyDeath.wav");
  music = minim.loadFile("data/sounds/music_loop.wav");
  music.loop();  // Inicia música
  
  player = new Player();  // Cria o jogador
}

// ===================== LOOP PRINCIPAL =====================
void draw() {
  if(gameOver) {
    gameOverScreen();
    return;  // Pausa o jogo
  }
  
  // Atualiza fundo
  background(0);  // Limpa artefatos gráficos
  imageMode(CORNER);
  image(bg, 0, 0, width, height);  // Desenha fundo
  
  // Atualiza entidades
  player.update();
  player.display();
  
  // Gerencia sistemas
  handleEnemies();    // Inimigos
  handleBullets();    // Tiros
  handleCoins();      // Moedas
  handleExplosions(); // Explosões
  checkCollisions();  // Colisões
  
  // Desenha UI
  fill(255);
  textSize(24);
  text("Score: " + score, 20, 40);
  text("Health: " + player.health, 20, 80);
}

// ===================== FUNÇÕES DE GERENCIAMENTO =====================
// --- Controla inimigos ---
void handleEnemies() {
  // Spawn a cada 2 segundos (60 FPS * 120 frames)
  if(frameCount % 120 == 0) {
    enemiesList.add(new Enemy());
  }
  
  // Atualiza e remove inimigos fora da tela
  for(int i = enemiesList.size()-1; i >= 0; i--) {
    Enemy e = enemiesList.get(i);
    e.update();
    e.display();
    
    if(e.pos.x < -100) {
      enemiesList.remove(i);
    }
  }
}

// --- Controla tiros ---
void handleBullets() {
  for(int i = bullets.size()-1; i >= 0; i--) {
    Bullet b = bullets.get(i);
    b.update();
    b.display();
    
    if(b.pos.x > width) {
      bullets.remove(i);
    }
  }
}

// --- Controla moedas ---
void handleCoins() {
  // Spawn a cada 3 segundos (60 FPS * 180 frames)
  if(frameCount % 180 == 0) {
    coins.add(new Coin());
  }
  
  // Atualiza e remove moedas
  for(int i = coins.size()-1; i >= 0; i--) {
    Coin c = coins.get(i);
    c.update();
    c.display();
    
    if(c.pos.x < -50) {
      coins.remove(i);
    }
  }
}

// --- Controla explosões ---
void handleExplosions() {
  for(int i = explosions.size()-1; i >= 0; i--) {
    Explosion ex = explosions.get(i);
    ex.update();
    ex.display();
    
    if(ex.finished) {
      explosions.remove(i);
    }
  }
}

// --- Verifica colisões ---
void checkCollisions() {
  // Colisão bala-inimigo
  for(int i = bullets.size()-1; i >= 0; i--) {
    Bullet b = bullets.get(i);
    for(int j = enemiesList.size()-1; j >= 0; j--) {
      Enemy e = enemiesList.get(j);
      if(dist(b.pos.x, b.pos.y, e.pos.x, e.pos.y) < 50) {
        explosions.add(new Explosion(e.pos.x, e.pos.y));
        enemyDeathSound.rewind();
        enemyDeathSound.play();
        bullets.remove(i);
        enemiesList.remove(j);
        score += 100;
        break;
      }
    }
  }
  
  // Colisão jogador-moeda
  for(int i = coins.size()-1; i >= 0; i--) {
    Coin c = coins.get(i);
    if(dist(player.pos.x, player.pos.y, c.pos.x, c.pos.y) < 40) {
      coins.remove(i);
      score += 50;
    }
  }
  
  // Colisão jogador-inimigo
  for(int i = enemiesList.size()-1; i >= 0; i--) {
    Enemy e = enemiesList.get(i);
    if(dist(player.pos.x, player.pos.y, e.pos.x, e.pos.y) < 50) {
      player.health -= 20;
      explosions.add(new Explosion(e.pos.x, e.pos.y));
      enemiesList.remove(i);
      
      if(player.health <= 0) {
        gameOver = true;
        playerDeathSound.play();
        music.pause();
      }
    }
  }
}

// ===================== TELA DE GAME OVER =====================
void gameOverScreen() {
  fill(255, 0, 0);
  textSize(72);
  textAlign(CENTER, CENTER);
  text("GAME OVER", width/2, height/2);
  textSize(36);
  text("Score: " + score, width/2, height/2 + 60);
}

// ===================== CONTROLES DO TECLADO =====================
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

// ===================== CLASSE JOGADOR =====================
class Player {
  PVector pos = new PVector(100, height/2); // Posição inicial
  float speed = 5;       // Velocidade
  int health = 100;      // Vida
  boolean moveUp, moveDown, moveLeft, moveRight; // Estados de movimento

  void update() {
    // Movimentação
    if(moveUp) pos.y -= speed;
    if(moveDown) pos.y += speed;
    if(moveLeft) pos.x -= speed;
    if(moveRight) pos.x += speed;
    
    // Limites da tela
    pos.x = constrain(pos.x, 0, width-80);
    pos.y = constrain(pos.y, 0, height-80);
  }
  
  void display() {
    // Desenho com rotação
    pushMatrix();
    translate(pos.x + 40, pos.y + 40); // Centraliza
    rotate(HALF_PI); // Rotação 90°
    imageMode(CENTER);
    image(playerImg, 0, 0, 80, 80);
    popMatrix();
  }
  
  void shoot() {
    bullets.add(new Bullet(pos.x + 80, pos.y + 40)); // Cria tiro
    shootSound.rewind();
    shootSound.play();
  }
}

// ===================== CLASSE INIMIGO =====================
class Enemy {
  PVector pos = new PVector(width + 100, random(100, height-100)); // Spawn fora da tela
  int type = (int)random(4);  // Tipo aleatório
  float speed = random(2, 4); // Velocidade variável

  void update() {
    pos.x -= speed; // Move para esquerda
  }
  
  void display() {
    pushMatrix();
    translate(pos.x + 40, pos.y + 40); // Centraliza
    rotate(-HALF_PI); // Rotação -90°
    imageMode(CENTER);
    image(enemies[type], 0, 0, 80, 80);
    popMatrix();
  }
}

// ===================== CLASSE TIRO =====================
class Bullet {
  PVector pos;
  float speed = 10;     // Velocidade fixa
  int frame = 0;        // Frame atual
  int lastUpdate = 0;   // Timer animação

  Bullet(float x, float y) {
    pos = new PVector(x, y);
    lastUpdate = millis();
  }
  
  void update() {
    pos.x += speed; // Move para direita
    // Atualiza frame a cada 50ms
    if(millis() - lastUpdate > 50) {
      frame = (frame + 1) % 13;
      lastUpdate = millis();
    }
  }
  
  void display() {
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(HALF_PI); // Alinha animação
    imageMode(CENTER);
    image(bulletFrames[frame], 0, 0, 40, 40);
    popMatrix();
  }
}

// ===================== CLASSE MOEDA =====================
class Coin {
  PVector pos = new PVector(width + 50, random(100, height-100)); // Spawn fora da tela
  float speed = 3; // Velocidade fixa

  void update() {
    pos.x -= speed; // Move para esquerda
  }
  
  void display() {
    image(coinImg, pos.x, pos.y, 30, 30); // Desenha moeda
  }
}

// ===================== CLASSE EXPLOSÃO =====================
class Explosion {
  PVector pos;
  int frame = 0;        // Frame atual
  int lastUpdate = 0;   // Timer animação
  boolean finished = false; // Estado

  Explosion(float x, float y) {
    pos = new PVector(x, y);
    lastUpdate = millis();
  }
  
  void update() {
    // Avança frame a cada 50ms
    if(millis() - lastUpdate > 50) {
      frame++;
      lastUpdate = millis();
      if(frame >= 7) finished = true;
    }
  }
  
  void display() {
    if(!finished) {
      image(explosionFrames[frame], pos.x-50, pos.y-50, 100, 100);
    }
  }
}
