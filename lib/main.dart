import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as im;
import 'package:tflite/tflite.dart';
import 'dart:typed_data';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digit Recognizer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Draw your digit below!'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<DrawingPoints> points = List();
  Color selectedColor = Colors.black;
  im.Image shot;
  String model;
  var _drawKey = GlobalKey();
  var predictions;

  void _loadModel() async {
    model = await Tflite.loadModel(
        model: "Python/my_model.tflite",
        labels: "Python/labels.txt",
    );
  }

  void _captureDigit() async {

    if (model == null) return;

    RenderRepaintBoundary boundary = _drawKey.currentContext.findRenderObject();
    shot = im.decodePng((await (await boundary.toImage()).toByteData(format: ui.ImageByteFormat.png)).buffer.asUint8List());
    shot = im.copyResize(shot, height: INPUT_SIZE, width: INPUT_SIZE, interpolation: im.Interpolation.linear);
    shot = im.grayscale(shot);

    var convertedBytes = Float32List(1 * INPUT_SIZE * INPUT_SIZE * 1);
    var buffer = Float32List.view(convertedBytes.buffer);
    bool empty = true;
    int pixelIndex = 0;

    for (int i = 0; i < INPUT_SIZE; i++) {
      for (int j = 0; j < INPUT_SIZE; j++) {
        var pixel = shot.getPixel(j, i);
        buffer[pixelIndex] = (im.getAlpha(pixel)) / 255.0;
        empty = empty && buffer[pixelIndex] == 0;
        pixelIndex++;
      }
    }

    if (empty){
      predictions = null;
    } else {
      predictions = await Tflite.runModelOnBinary(
          binary: convertedBytes.buffer.asUint8List(),
          numResults: 2,
          threshold: 0,
          asynch: true
      );
    }
    setState(() {});
  }

  void _clear() {
    predictions = null;
    setState(() {
      points.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = (MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top);
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = 2*(screenHeight - screenWidth)/3;
    final smallFont = (screenHeight - screenWidth)/20;
    final strokeWidth = screenWidth * 20.0/420.0;

    if (model == null){
      _loadModel();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body:
      Column(
        children: <Widget>[
          Container(
            alignment: Alignment.topCenter,

            color: Colors.white,
            constraints: BoxConstraints.expand(
              height: screenWidth,
            ),

            child: RepaintBoundary(
              key: _drawKey,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,

                onPanUpdate: (details) {
                  setState(() {
                    RenderBox rb = _drawKey.currentContext.findRenderObject();
                    points.add(DrawingPoints(
                        points: rb.globalToLocal(details.globalPosition),
                        paint: Paint()
                          ..isAntiAlias = true
                          ..color = selectedColor
                          ..strokeWidth = strokeWidth));
                  });
                },
                onPanStart: (details) {
                  setState(() {
                    RenderBox rb = _drawKey.currentContext.findRenderObject();
                    points.add(DrawingPoints(
                        points: rb.globalToLocal(details.globalPosition),
                        paint: Paint()
                          ..isAntiAlias = true
                          ..color = selectedColor
                          ..strokeWidth = strokeWidth));
                  });
                },
                onPanEnd: (details) {
                  points.add(null);
                  _captureDigit();
                },
                child: CustomPaint(
                  size: Size.square(screenWidth),
                  painter: DrawingPainter(
                    pointsList: points,
                  ),
                ),
              ),
            ),
          ),
          Row(
              children: <Widget>[
                Container(
                  alignment: Alignment.bottomLeft,

                  constraints: BoxConstraints.expand(
                    height: screenHeight - screenWidth,
                    width: screenWidth/2,
                  ),

                  child: Container (
                    alignment: Alignment.bottomCenter,
                    child: Column(
                    children: <Widget> [
                      Text(
                        predictions != null ? predictions[0]['label'] : "",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
                      ),
                      Text("First Prediction", textAlign: TextAlign.center, style: TextStyle(fontSize: smallFont)),
                    ]
                  ),
          ),
                  color: Colors.blueGrey,
                ),
                Container(
                  alignment: Alignment.bottomRight,

                  constraints: BoxConstraints.expand(
                    height: screenHeight - screenWidth,
                    width: screenWidth/2,
                  ),

                  child: Container (
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      children: <Widget> [
                        Text(
                          predictions != null ? predictions[1]['label'] : "",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
                        ),
                        Text("Second Prediction", textAlign: TextAlign.center, style: TextStyle(fontSize: smallFont)),
                      ]
                  ),
                ),
                  color: Colors.grey,
                )
              ]
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _clear,
        tooltip: 'Clear',
        child: Icon(Icons.clear),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class DrawingPainter extends CustomPainter {
  DrawingPainter({this.pointsList});
  List<DrawingPoints> pointsList;
  List<Offset> offsetPoints = List();
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < pointsList.length - 1; i++) {
      if (pointsList[i] != null && pointsList[i+1] != null) {
        int steps = (pointsList[i].points - pointsList[i+1].points).distance ~/ (pointsList[i].paint.strokeWidth / 10.0);
        for (int j = 0; j < steps; j++){
          canvas.drawCircle(pointsList[i].points - (pointsList[i].points - pointsList[i+1].points) * j.toDouble() / steps.toDouble(), pointsList[i].paint.strokeWidth,
              pointsList[i].paint);
        }
      } else if (pointsList[i] != null && pointsList[i + 1] == null) {
        canvas.drawCircle(pointsList[i].points, pointsList[i].paint.strokeWidth,
            pointsList[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}


class DrawingPoints {
  Paint paint;
  Offset points;

  DrawingPoints({this.points, this.paint});
}
const INPUT_SIZE = 28;