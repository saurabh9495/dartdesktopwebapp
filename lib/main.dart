
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Step 1: Define Enemy Types
enum EnemyType {
  grunt,
  tank,
}

// Step 2: Define Properties for Each Enemy Type
class EnemyProperties {
  final int health;
  final double speed;
  final int score;
  final String imagePath;
  ui.Image? image;

  EnemyProperties({
    required this.health,
    required this.speed,
    required this.score,
    required this.imagePath,
    this.image,
  });
}

Map<EnemyType, EnemyProperties> enemyData = {
  EnemyType.grunt: EnemyProperties(
    health: 1,
    speed: 1.5,
    score: 10,
    imagePath: 'assets/images/enemy_grunt.png',
  ),
  EnemyType.tank: EnemyProperties(
    health: 3,
    speed: 0.8,
    score: 30,
    imagePath: 'assets/images/enemy_tank.png',
  ),
};

void main() {
  runApp(const MyApp());
}

// Step 5: Function to load image assets
Future<ui.Image> _loadImage(String assetPath) async {
  final ByteData data = await rootBundle.load(assetPath);
  final Completer<ui.Image> completer = Completer();
  ui.decodeImageFromList(data.buffer.asUint8List(), (ui.Image img) {
    return completer.complete(img);
  });
  return completer.future;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2D Shooter',
      theme: ThemeData.dark(),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  late Timer _timer;
  _Player _player = _Player();
  final List<_Bullet> _bullets = [];
  final List<_Enemy> _enemies = [];
  Offset _joystickOffset = Offset.zero;
  int _score = 0;
  bool _isGameOver = false;
  late double _screenWidth, _screenHeight;

  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _loadGameAssets();

    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isGameOver && _imagesLoaded) {
        _updateGame();
      }
    });
  }

  Future<void> _loadGameAssets() async {
    // Load player and bullet images
    _player.image = await _loadImage('assets/images/player.png');
    final bulletImage = await _loadImage('assets/images/bullet.png');
    _Bullet.bulletImage = bulletImage;
    
    // Load enemy images
    for (var entry in enemyData.entries) {
      entry.value.image = await _loadImage(entry.value.imagePath);
    }

    setState(() {
      _imagesLoaded = true;
    });
  }

  void _startGame() {
    setState(() {
      _isGameOver = false;
      _player = _Player();
      _enemies.clear();
      _bullets.clear();
      _score = 0;
       _loadGameAssets(); // Reload images on restart
      _player.position = Offset(_screenWidth / 2, _screenHeight - 100);
    });
    _focusNode.requestFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;
    _player.position = Offset(_screenWidth / 2, _screenHeight - 100);
  }

  void _updateGame() {
    // Spawn enemies
    if (Random().nextDouble() < 0.03 && _enemies.length < 15) {
      final type = Random().nextDouble() < 0.3 ? EnemyType.tank : EnemyType.grunt;
      _enemies.add(_Enemy(type: type, position: Offset(Random().nextDouble() * _screenWidth, -50)));
    }

    setState(() {
      // Player and Bullet Movement
      Offset keyboardMovement = _getKeyboardMovement();
      if (keyboardMovement != Offset.zero) {
        _player.move(keyboardMovement, context);
      } else {
        _player.move(_joystickOffset.scale(0.1, 0.1), context);
      }

      _bullets.removeWhere((bullet) {
        bullet.move();
        return bullet.isOffScreen(context);
      });

      // Enemy Movement and Player Collision
      final List<_Enemy> enemiesToRemoveFromGame = [];
      for (final enemy in _enemies) {
        enemy.move(_player.position);
        if ((_player.position - enemy.position).distance < 30) { // Adjusted collision radius
          _player.health -= 1;
          enemiesToRemoveFromGame.add(enemy); // Remove enemy on collision with player
          if (_player.health <= 0) {
            setState(() {
              _isGameOver = true;
            });
          }
        }
      }
       _enemies.removeWhere((e) => enemiesToRemoveFromGame.contains(e));

      // Bullet and Enemy Collision
      final List<_Bullet> bulletsToRemove = [];
      final List<_Enemy> enemiesToRemove = [];

      for (final bullet in _bullets) {
        for (final enemy in _enemies) {
          if ((bullet.position - enemy.position).distance < 20) { // Adjusted collision radius
            bulletsToRemove.add(bullet);
            enemy.health -= 1;
            if (enemy.health <= 0) {
              enemiesToRemove.add(enemy);
              _score += enemy.properties.score;
            }
          }
        }
      }
      _bullets.removeWhere((b) => bulletsToRemove.contains(b));
      _enemies.removeWhere((e) => enemiesToRemove.contains(e));
    });
  }

    Offset _getKeyboardMovement() {
    Offset movement = Offset.zero;
    const double speed = 4.0;
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      movement += const Offset(0, -speed);
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      movement += const Offset(0, speed);
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      movement += const Offset(-speed, 0);
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      movement += const Offset(speed, 0);
    }
    return movement;
  }

  @override
  void dispose() {
    _timer.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _shoot() {
    if (_isGameOver) return;
    setState(() {
      _bullets.add(_Bullet(
        position: _player.position,
        velocity: const Offset(0, -7), // Increased bullet speed
      ));
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    setState(() {
      if (event is RawKeyDownEvent) {
        _pressedKeys.add(event.logicalKey);
        if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter) {
          _shoot();
        }
      } else if (event is RawKeyUpEvent) {
        _pressedKeys.remove(event.logicalKey);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    if (!_imagesLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      autofocus: true,
      child: Scaffold(
        body: Stack(
          children: [
            CustomPaint(
              painter: _GamePainter(player: _player, bullets: _bullets, enemies: _enemies),
              child: Container(),
            ),
            _buildUI(),
            if (_isGameOver) _buildGameOverMenu(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUI() {
    return Stack(
      children: [
        Positioned(
          top: 40,
          left: 20,
          child: Text('Score: $_score', style: const TextStyle(color: Colors.white, fontSize: 20)),
        ),
        Positioned(
          top: 40,
          right: 20,
          child: Text('Health: ${_player.health}', style: const TextStyle(color: Colors.white, fontSize: 20)),
        ),
        Positioned(
          bottom: 50,
          left: 50,
          child: GestureDetector(
            onPanUpdate: (details) {
              if (_isGameOver) return;
              setState(() {
                _joystickOffset += details.delta;
                if (_joystickOffset.distance > 40) {
                  _joystickOffset = Offset.fromDirection(_joystickOffset.direction, 40);
                }
              });
            },
            onPanEnd: (details) {
              setState(() {
                _joystickOffset = Offset.zero;
              });
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Transform.translate(
                  offset: _joystickOffset,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          right: 50,
          child: GestureDetector(
            onTap: _shoot,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.gps_fixed, color: Colors.white, size: 40),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverMenu() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Game Over', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text('Your Score: $_score', style: const TextStyle(color: Colors.white, fontSize: 24)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _startGame,
              child: const Text('Restart', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}


class _GamePainter extends CustomPainter {
  final _Player player;
  final List<_Bullet> bullets;
  final List<_Enemy> enemies;

  _GamePainter({required this.player, required this.bullets, required this.enemies});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw player
    if (player.image != null) {
      final position = player.position - const Offset(25, 25); // Adjust to center the image
      canvas.drawImage(player.image!, position, Paint());
    }

    // Draw bullets
    if (_Bullet.bulletImage != null) {
      for (final bullet in bullets) {
        final position = bullet.position - const Offset(10, 10);
        canvas.drawImage(_Bullet.bulletImage!, position, Paint());
      }
    }

    // Draw enemies
    for (final enemy in enemies) {
      if (enemy.properties.image != null) {
        final position = enemy.position - const Offset(25, 25);
        canvas.drawImage(enemy.properties.image!, position, Paint());
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Player {
  Offset position = const Offset(200, 400);
  int health = 100;
  ui.Image? image;

  void move(Offset offset, BuildContext context) {
    final size = MediaQuery.of(context).size;
    final newPosition = position + offset;
    // Clamp player position to screen bounds
    if (newPosition.dx > 25 && newPosition.dx < size.width - 25) {
      position = Offset(newPosition.dx, position.dy);
    }
    if (newPosition.dy > 25 && newPosition.dy < size.height - 25) {
      position = Offset(position.dx, newPosition.dy);
    }
  }
}

class _Bullet {
  Offset position;
  Offset velocity;
  static ui.Image? bulletImage;

  _Bullet({required this.position, required this.velocity});

  void move() {
    position += velocity;
  }

  bool isOffScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return position.dx < 0 || position.dx > size.width || position.dy < 0 || position.dy > size.height;
  }
}

class _Enemy {
  final EnemyType type;
  final EnemyProperties properties;
  Offset position;
  int health;
  
  _Enemy({required this.type, required this.position}) 
      : properties = enemyData[type]!,
        health = enemyData[type]!.health;

  void move(Offset playerPosition) {
    final direction = (playerPosition - position).direction;
    position += Offset.fromDirection(direction, properties.speed);
  }
}
