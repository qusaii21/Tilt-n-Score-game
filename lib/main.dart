import 'package:flutter/material.dart';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tilt n Score',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false, // Removed the debug banner
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _posX = 180.0;
  double _posY = 350.0;
  double _targetX = 0.0;
  double _targetY = 0.0;
  double _squareX = 0.0;
  double _squareY = 0.0;
  int _score = 0;
  int _highScore = 0;
  Random _random = Random();
  bool _gameOver = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    gyroscopeEvents.listen(_updatePosition);
    _initializeGame();
    _loadHighScore();
  }

  void _initializeGame() {
    setState(() {
      _targetX = _random.nextDouble() * 300;
      _targetY = _random.nextDouble() * 500;
      _squareX = _random.nextDouble() * 300;
      _squareY = _random.nextDouble() * 500;
    });
  }

  void _updatePosition(GyroscopeEvent event) {
    if (_gameOver) return;

    setState(() {
      _posX += event.y * 100;
      _posY += event.x * 100;

      // Ensure the ball stays within bounds
      if (_posX < 0) _posX = 0;
      if (_posX > 300) _posX = 300;
      if (_posY < 0) _posY = 0;
      if (_posY > 500) _posY = 500;

      // Check for collision with target
      if ((_posX - _targetX).abs() < 25 && (_posY - _targetY).abs() < 25) {
        _score++;
        _playSound('assets/hit_target.wav');
        _targetX = _random.nextDouble() * 300;
        _targetY = _random.nextDouble() * 500;
        _squareX = _random.nextDouble() * 300; // Update square position after scoring
        _squareY = _random.nextDouble() * 500;
      }

      // Check for collision with square
      if ((_posX - _squareX).abs() < 25 && (_posY - _squareY).abs() < 25) {
        _gameOver = true;
        _playSound('assets/game_over.wav');
        _checkHighScore();
      }
    });
  }

  void _resetGame() {
    setState(() {
      _posX = 180.0;
      _posY = 350.0;
      _score = 0;
      _gameOver = false;
      _initializeGame();
    });
  }

  void _checkHighScore() async {
    if (_score > _highScore) {
      _highScore = _score;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setInt('highScore', _highScore);
    }
  }

  void _loadHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = (prefs.getInt('highScore') ?? 0);
    });
  }

  void _playSound(String path) {
    _audioPlayer.play(AssetSource(path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          
          Container(
            width: double.infinity,
            color: Color(0xFF9E6DF7),
            padding: const EdgeInsets.all(20.0),
            
            child: Column(
              children: [
                SizedBox(height: 10),
                Text(
                  'Tilt n Score',
                  style: TextStyle(fontSize: 28, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Score: $_score',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                Text(
                  'High Score: $_highScore',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Color(0xff9E6DF7), // Added black borders
              padding: const EdgeInsets.all(10.0), // Added padding for the borders
              child: Container(
                color: Color(0xFFFDFF95), // Main game area color
                child: Stack(
                  children: [
                    Positioned(
                      left: _posX,
                      top: _posY,
                      child: Ball(),
                    ),
                    Positioned(
                      left: _targetX,
                      top: _targetY,
                      child: Target(),
                    ),
                    Positioned(
                      left: _squareX,
                      top: _squareY,
                      child: Square(),
                    ),
                    if (_gameOver)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Game Over',
                              style: TextStyle(fontSize: 36, color: Colors.red),
                            ),
                            ElevatedButton(
                              onPressed: _resetGame,
                              child: Text('Restart'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: Color(0xFF9E6DF7),
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Tilt your device to move the ball.\nHit the green target to score points.\nAvoid the red square.',
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class Ball extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 4.0,
            spreadRadius: 2.0,
            offset: Offset(2.0, 2.0),
          ),
        ],
      ),
    );
  }
}

class Target extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 4.0,
            spreadRadius: 2.0,
            offset: Offset(2.0, 2.0),
          ),
        ],
      ),
    );
  }
}

class Square extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.rectangle,
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 4.0,
            spreadRadius: 2.0,
            offset: Offset(2.0, 2.0),
          ),
        ],
      ),
    );
  }
}
