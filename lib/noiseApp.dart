import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class MyNoiseApp extends StatefulWidget {
  @override
  _MyNoiseAppState createState() => new _MyNoiseAppState();
}

class _MyNoiseAppState extends State<MyNoiseApp> {
  double totalData = 0;
  int numDataPoints = 0;
  double avg = 0;
  double max = 0;

  bool _isRecording = false;
  StreamSubscription<NoiseReading>? _noiseSubscription;
  late NoiseMeter _noiseMeter;
  bool flag = false;
  double reading = 0;
  RecorderController? recorderController;
  @override
  void initState() {
    recorderController = RecorderController();
    super.initState();
    _noiseMeter = NoiseMeter(onError);
  }

  @override
  Future<void> dispose() async {
    _noiseSubscription?.cancel();
    recorderController!.dispose();

    super.dispose();
  }

  average() {
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isRecording) {
        setState(() {
          avg = totalData / numDataPoints;
          if (avg > 70) {
            flag = true;
          } else {
            flag = false;
          }
        });
        totalData = 0;
        numDataPoints = 0;
        print(avg);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> onData(NoiseReading noiseReading) async {
    await recorderController!.record();
    max = noiseReading.maxDecibel;
    this.setState(() {
      reading = noiseReading.maxDecibel;
      if (!this._isRecording) {
        this._isRecording = true;
        average();
      }

      if (noiseReading.meanDecibel.isInfinite ||
          noiseReading.meanDecibel.isNaN ||
          noiseReading.meanDecibel.isNegative) {
        print('error');
      } else {
        reading = noiseReading.meanDecibel;
        totalData += reading;
        numDataPoints++;
      }
    });

    print(reading.toString());
  }

  void onError(Object error) {
    print(error.toString());
    _isRecording = false;
    flag = false;
  }

  void start() async {
    try {
      _noiseSubscription = _noiseMeter.noiseStream.listen(onData);
      flag = false;
    } catch (err) {
      print(err);
    }
  }

  void stop() {
    try {
      if (_noiseSubscription != null) {
        _noiseSubscription!.cancel();
        _noiseSubscription = null;
        recorderController!.stop();
        // _timer!.cancel;
      }
      setState(() {
        avg = 0;
        max = 0;
        numDataPoints = 0;
        totalData = 0;
        reading = 0;
        flag = false;
        _isRecording = false;
      });
    } catch (err) {
      print('stopRecorder error: $err');
    }
  }

  List<Widget> getContent() => <Widget>[
        Container(
            width: double.infinity,
            margin: EdgeInsets.all(25),
            child: Column(children: [
              Container(
                child: Text(_isRecording ? "Mic: ON" : "Mic: OFF",
                    style: TextStyle(
                        fontSize: 45,
                        fontWeight: FontWeight.w400,
                        color: Colors.black)),
                margin: EdgeInsets.only(top: 20),
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Card(
                    elevation: 5,
                    child: Container(
                      width: 70,
                      height: 60,
                      child: Center(
                        child: Text(
                          "${max.round()}",
                          style: TextStyle(
                              fontSize: 40, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                  Card(
                    elevation: 5,
                    child: Container(
                      width: 70,
                      height: 60,
                      child: Center(
                        child: Text(
                          "${avg.round()}",
                          style: TextStyle(
                              fontSize: 40, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              CircleAvatar(
                radius: 30,
                backgroundColor: flag ? Colors.red : Colors.green,
                child: Icon(
                  Icons.flag,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                height: 40,
              ),
              AudioWaveforms(
                enableGesture: false,
                size: Size(double.infinity, 70),
                recorderController: recorderController!,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Color.fromARGB(255, 223, 217, 217),
                ),
                waveStyle: WaveStyle(
                  durationLinesColor: Colors.white,
                  waveColor: flag ? Colors.red : Colors.green,
                  waveThickness: 4,
                  scaleFactor: 30,
                  durationStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  showDurationLabel: true,
                  // spacing: 8.0,
                  showBottom: true,
                  extendWaveform: true,
                  showMiddleLine: false,
                ),
              )
            ]))
      ];
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: getContent())),
        floatingActionButton: FloatingActionButton(
          backgroundColor: _isRecording ? Colors.red : Colors.green,
          onPressed: _isRecording ? stop : start,
          child: _isRecording ? Icon(Icons.stop) : Icon(Icons.mic),
        ),
      ),
    );
  }
}
