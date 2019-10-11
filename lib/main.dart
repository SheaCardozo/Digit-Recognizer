import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as im;
import 'dart:io';
import 'package:path_provider/path_provider.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digit Recognizer',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Draw your digit below!'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<DrawingPoints> points = List();
  Color selectedColor = Colors.black;
  Color pickerColor = Colors.black;
  bool showBottomList = false;
  StrokeCap strokeCap = StrokeCap.butt;
  SelectedMode selectedMode = SelectedMode.StrokeWidth;
  GlobalKey _drawKey = GlobalKey();
  im.Image shot;

  void _captureDigit() async {

    RenderRepaintBoundary boundary = _drawKey.currentContext.findRenderObject();
    shot = im.decodePng((await (await boundary.toImage()).toByteData(format: ui.ImageByteFormat.png)).buffer.asUint8List());
    shot = im.copyResize(shot, height: 28, width: 28, interpolation: im.Interpolation.linear);
    shot = im.grayscale(shot);
  }

  void _clear() {
    setState(() {
      points.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = (MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top);
    final screenWidth = MediaQuery.of(context).size.width;
    double strokeWidth = screenWidth * 20.0/420.0;
    double opacity = 1.0;

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body:
      Column(
        children: <Widget>[
          Container(
            alignment: Alignment.topCenter,
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
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
                          ..strokeCap = strokeCap
                          ..isAntiAlias = true
                          ..color = selectedColor.withOpacity(opacity)
                          ..strokeWidth = strokeWidth));
                  });
                  _captureDigit();
                },
                onPanStart: (details) {
                  setState(() {
                    RenderBox rb = _drawKey.currentContext.findRenderObject();
                    points.add(DrawingPoints(
                        points: rb.globalToLocal(details.globalPosition),
                        paint: Paint()
                          ..strokeCap = strokeCap
                          ..isAntiAlias = true
                          ..color = selectedColor.withOpacity(opacity)
                          ..strokeWidth = strokeWidth));
                    _captureDigit();
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    points.add(null);
                    _captureDigit();
                  });
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

                  color: Colors.green,
                ),
                Container(
                  alignment: Alignment.bottomRight,
                  // Center is a layout widget. It takes a single child and positions it
                  // in the middle of the parent.

                  constraints: BoxConstraints.expand(
                    height: screenHeight - screenWidth,
                    width: screenWidth/2,
                  ),

                  color: Colors.purple,
                )
              ]
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _clear,
        tooltip: 'Clear',
        child: Icon(Icons.clear),
      ), // This trailing comma makes auto-formatting nicer for build methods.
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

enum SelectedMode { StrokeWidth, Opacity, Color }