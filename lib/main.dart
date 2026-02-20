import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const TetrisApp());
}

class TetrisApp extends StatelessWidget {
  const TetrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const GameBoard(),
    );
  }
}

enum Tetromino { L, J, I, O, S, Z, T }

const Map<Tetromino, Color> tetrominoColors = {
  Tetromino.L: Colors.orange,
  Tetromino.J: Colors.blue,
  Tetromino.I: Colors.cyan,
  Tetromino.O: Colors.yellow,
  Tetromino.S: Colors.green,
  Tetromino.Z: Colors.red,
  Tetromino.T: Colors.purple,
};

const Map<Tetromino, List<List<int>>> tetrominoRotations = {
  Tetromino.L: [ [4, 14, 24, 25], [15, 14, 13, 24], [4, 5, 15, 25], [14, 24, 23, 13] ],
  Tetromino.J: [ [5, 15, 25, 24], [14, 15, 16, 26], [5, 6, 16, 26], [14, 24, 25, 26] ],
  Tetromino.I: [ [4, 14, 24, 34], [13, 14, 15, 16], [4, 14, 24, 34], [13, 14, 15, 16] ],
  Tetromino.O: [ [4, 5, 14, 15], [4, 5, 14, 15], [4, 5, 14, 15], [4, 5, 14, 15] ],
  Tetromino.S: [ [15, 14, 24, 23], [13, 14, 24, 25], [15, 14, 24, 23], [13, 14, 24, 25] ],
  Tetromino.Z: [ [14, 15, 25, 26], [15, 14, 24, 23], [14, 15, 25, 26], [15, 14, 24, 23] ],
  Tetromino.T: [ [4, 14, 24, 15], [14, 15, 16, 25], [5, 14, 24, 15], [14, 13, 15, 24] ],
};

class Piece {
  Tetromino type;
  List<int> position;
  Color color;
  int rotationIndex;

  Piece({
    required this.type,
    required this.position,
    required this.color,
    this.rotationIndex = 0,
  });
}

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  final int rowLength = 10;
  final int colLength = 20;

  late Piece currentPiece;
  Map<int, Color> board = {};
  Timer? gameLoop;

  int score = 0;
  int level = 1;
  int highScore = 0;

  late Tetromino nextPieceType;
  Tetromino? holdPieceType;
  bool canHold = true;
  List<int> ghostPosition = [];

  @override
  void initState() {
    super.initState();
    nextPieceType = _getRandomTetromino();
    spawnNewPiece();
    startGame();
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    super.dispose();
  }

  Tetromino _getRandomTetromino() {
    return Tetromino.values[Random().nextInt(Tetromino.values.length)];
  }

  void spawnNewPiece() {
    final typeToSpawn = nextPieceType;
    nextPieceType = _getRandomTetromino();

    currentPiece = Piece(
      type: typeToSpawn,
      position: List<int>.from(tetrominoRotations[typeToSpawn]![0]),
      color: tetrominoColors[typeToSpawn]!,
      rotationIndex: 0,
    );

    canHold = true;
    updateGhostPosition();
  }

  void startGame() {
    gameLoop?.cancel();
    final int speed = max(100, 450 - (level * 50));

    gameLoop = Timer.periodic(Duration(milliseconds: speed), (timer) {
      setState(() {
        if (!checkCollision(Direction.down)) {
          movePieceDown();
        } else {
          lockPiece();
        }
      });
    });
  }

  void lockPiece() {
    for (final pos in currentPiece.position) {
      board[pos] = currentPiece.color;
    }

    if (currentPiece.position.any((pos) => pos < rowLength)) {
      gameOver();
      return;
    }

    clearFullLines();
    spawnNewPiece();
  }

  void clearFullLines() {
    final List<int> fullRows = [];

    for (int row = 0; row < colLength; row++) {
      bool isFull = true;
      for (int col = 0; col < rowLength; col++) {
        if (!board.containsKey(row * rowLength + col)) {
          isFull = false;
          break;
        }
      }
      if (isFull) fullRows.add(row);
    }

    if (fullRows.isEmpty) return;

    for (final row in fullRows) {
      for (int col = 0; col < rowLength; col++) {
        board.remove(row * rowLength + col);
      }
    }

    final Map<int, Color> newBoard = {};
    for (final entry in board.entries) {
      final int row = (entry.key / rowLength).floor();
      final int col = entry.key % rowLength;
      final int linesBelow = fullRows.where((r) => r > row).length;
      newBoard[(row + linesBelow) * rowLength + col] = entry.value;
    }
    board = newBoard;

    const List<int> lineScores = [0, 100, 300, 500, 800];
    score += lineScores[min(fullRows.length, 4)] * level;

    if (score > highScore) highScore = score;

    final int newLevel = (score ~/ 500) + 1;
    if (newLevel > level) {
      level = newLevel;
      startGame();
    }
  }

  void gameOver() {
    gameLoop?.cancel();
    if (score > highScore) highScore = score;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Game Over', style: TextStyle(color: Colors.white)),
        content: Text(
          'Score: $score\nLevel: $level\nHigh Score: $highScore',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                board.clear();
                score = 0;
                level = 1;
                holdPieceType = null;
                nextPieceType = _getRandomTetromino();
                spawnNewPiece();
                startGame();
              });
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void holdPiece() {
    if (!canHold) return;

    setState(() {
      if (holdPieceType == null) {
        holdPieceType = currentPiece.type;
        spawnNewPiece();
      } else {
        final Tetromino temp = currentPiece.type;
        currentPiece = Piece(
          type: holdPieceType!,
          position: List<int>.from(tetrominoRotations[holdPieceType!]![0]),
          color: tetrominoColors[holdPieceType!]!,
        );
        holdPieceType = temp;
      }
      canHold = false;
      updateGhostPosition();
    });
  }

  void updateGhostPosition() {
    List<int> simulated = List.from(currentPiece.position);

    while (true) {
      bool collision = false;
      for (final pos in simulated) {
        final int row = (pos / rowLength).floor();
        if (row + 1 >= colLength || board.containsKey(pos + rowLength)) {
          collision = true;
          break;
        }
      }
      if (collision) break;
      simulated = simulated.map((p) => p + rowLength).toList();
    }

    ghostPosition = simulated;
  }

  void movePieceDown() {
    currentPiece.position = currentPiece.position.map((p) => p + rowLength).toList();
  }

  void moveLeft() {
    if (!checkCollision(Direction.left)) {
      setState(() {
        currentPiece.position = currentPiece.position.map((p) => p - 1).toList();
        updateGhostPosition();
      });
    }
  }

  void moveRight() {
    if (!checkCollision(Direction.right)) {
      setState(() {
        currentPiece.position = currentPiece.position.map((p) => p + 1).toList();
        updateGhostPosition();
      });
    }
  }

  void rotatePiece() {
    final rotations = tetrominoRotations[currentPiece.type]!;
    final int nextIndex = (currentPiece.rotationIndex + 1) % rotations.length;
    final template = rotations[nextIndex];

    final int topRow = currentPiece.position.map((p) => (p / rowLength).floor()).reduce(min);
    final int leftCol = currentPiece.position.map((p) => p % rowLength).reduce(min);
    final int templateTopRow = template.map((p) => (p / rowLength).floor()).reduce(min);
    final int templateLeftCol = template.map((p) => p % rowLength).reduce(min);

    final int rowOffset = topRow - templateTopRow;
    final int colOffset = leftCol - templateLeftCol;

    final newPosition = template.map((p) {
      final int r = (p / rowLength).floor() + rowOffset;
      final int c = p % rowLength + colOffset;
      return r * rowLength + c;
    }).toList();

    final bool valid = newPosition.every((pos) {
      final int r = (pos / rowLength).floor();
      final int c = pos % rowLength;
      return r >= 0 && r < colLength && c >= 0 && c < rowLength && !board.containsKey(pos);
    });

    if (valid) {
      setState(() {
        currentPiece.position = newPosition;
        currentPiece.rotationIndex = nextIndex;
        updateGhostPosition();
      });
    }
  }

  void hardDrop() {
    setState(() {
      while (!checkCollision(Direction.down)) {
        movePieceDown();
      }
      lockPiece();
    });
  }

  bool checkCollision(Direction direction) {
    for (final pos in currentPiece.position) {
      final int row = (pos / rowLength).floor();
      final int col = pos % rowLength;

      if (direction == Direction.left) {
        if (col - 1 < 0 || board.containsKey(pos - 1)) return true;
      } else if (direction == Direction.right) {
        if (col + 1 >= rowLength || board.containsKey(pos + 1)) return true;
      } else if (direction == Direction.down) {
        if (row + 1 >= colLength || board.containsKey(pos + rowLength)) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MiniBox(title: 'HOLD', tetromino: holdPieceType),
                  Column(
                    children: [
                      _HudLabel(label: 'SCORE', value: '$score'),
                      const SizedBox(height: 6),
                      _HudLabel(label: 'LEVEL', value: '$level'),
                      const SizedBox(height: 6),
                      _HudLabel(label: 'BEST', value: '$highScore'),
                    ],
                  ),
                  MiniBox(title: 'NEXT', tetromino: nextPieceType),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: rowLength / colLength,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: GridView.builder(
                      itemCount: rowLength * colLength,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: rowLength,
                      ),
                      itemBuilder: (context, index) {
                        if (currentPiece.position.contains(index)) {
                          return Pixel(color: currentPiece.color);
                        } else if (board.containsKey(index)) {
                          return Pixel(color: board[index]!);
                        } else if (ghostPosition.contains(index)) {
                          return Pixel(color: currentPiece.color.withOpacity(0.25));
                        } else {
                          return const Pixel(color: Color(0xFF1A1A2E));
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlButton(
                    icon: Icons.swap_horiz,
                    size: 36,
                    color: canHold ? Colors.orange : Colors.grey,
                    onPressed: holdPiece,
                  ),
                  _ControlButton(icon: Icons.arrow_left, size: 44, onPressed: moveLeft),
                  _ControlButton(icon: Icons.rotate_right, size: 40, onPressed: rotatePiece),
                  _ControlButton(icon: Icons.vertical_align_bottom, size: 40, onPressed: hardDrop),
                  _ControlButton(icon: Icons.arrow_right, size: 44, onPressed: moveRight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudLabel extends StatelessWidget {
  final String label;
  final String value;

  const _HudLabel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1.5)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.onPressed,
    this.color = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: size, color: color),
    );
  }
}

class MiniBox extends StatelessWidget {
  final String title;
  final Tetromino? tetromino;

  const MiniBox({super.key, required this.title, this.tetromino});

  @override
  Widget build(BuildContext context) {
    List<int> normalizedPositions = [];
    if (tetromino != null) {
      final template = tetrominoRotations[tetromino]![0];
      final int minCol = template.map((p) => p % 10).reduce(min);
      final int minRow = template.map((p) => (p / 10).floor()).reduce(min);
      for (final int p in template) {
        int r = (p / 10).floor() - minRow;
        int c = (p % 10) - minCol;
        if (tetromino == Tetromino.O) c += 1;
        if (tetromino == Tetromino.I) r += 1;
        normalizedPositions.add(r * 4 + c);
      }
    }

    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: GridView.builder(
            itemCount: 16,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
            itemBuilder: (context, index) {
              if (normalizedPositions.contains(index)) {
                return Pixel(color: tetrominoColors[tetromino]!);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

enum Direction { left, right, down }

class Pixel extends StatelessWidget {
  final Color color;
  const Pixel({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black26, width: 0.5),
      ),
      margin: const EdgeInsets.all(1),
    );
  }
}