import 'dart:async';
import 'dart:io' as io;

import 'package:audioplayers/audioplayers.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  SystemChrome.setEnabledSystemUIOverlays([]);
  return runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        body: SafeArea(
          child: new RecorderExample(),
        ),
      ),
    );
  }
}

class RecorderExample extends StatefulWidget {
  final LocalFileSystem localFileSystem;

  RecorderExample({localFileSystem})
      : this.localFileSystem = localFileSystem ?? LocalFileSystem();

  @override
  State<StatefulWidget> createState() => new RecorderExampleState();
}

class RecorderExampleState extends State<RecorderExample> {
  FlutterAudioRecorder _recorder;
  Recording _current;
  RecordingStatus _currentStatus = RecordingStatus.Unset;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: new FlatButton(
                      onPressed: () {
                        switch (_currentStatus) {
                          case RecordingStatus.Initialized:
                            {
                              _start();
                              break;
                            }
                          case RecordingStatus.Recording:
                            {
                              _pause();
                              break;
                            }
                          case RecordingStatus.Paused:
                            {
                              _resume();
                              break;
                            }
                          case RecordingStatus.Stopped:
                            {
                              _init();
                              break;
                            }
                          default:
                            break;
                        }
                      },
                      child: _buildText(_currentStatus),
                      color: Colors.lightBlue,
                    ),
                  ),
                  new FlatButton(
                    onPressed:
                    _currentStatus != RecordingStatus.Unset ? _stop : null,
                    child:
                    new Text("Stop", style: TextStyle(color: Colors.white)),
                    color: Colors.blueAccent.withOpacity(0.5),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  new FlatButton(
                    onPressed: onPlayAudio,
                    child:
                    new Text("Play", style: TextStyle(color: Colors.white)),
                    color: Colors.blueAccent.withOpacity(0.5),
                  ),
                ],
              ),
              new Text("Status : $_currentStatus"),
              new Text('Avg Power: ${_current?.metering?.averagePower}'),
              new Text('Peak Power: ${_current?.metering?.peakPower}'),
              new Text("File path of the record: ${_current?.path}"),
              new Text("Format: ${_current?.audioFormat}"),
              new Text(
                  "isMeteringEnabled: ${_current?.metering?.isMeteringEnabled}"),
              new Text("Extension : ${_current?.extension}"),
              new Text(
                  "Audio recording duration : ${_current?.duration.toString()}")
            ]),
      ),
    );
  }

  _init() async {
    try {
      if (await FlutterAudioRecorder.hasPermissions) {
        String customPath = '/flutter_audio_recorder_';
        io.Directory appDocDirectory;
//        io.Directory appDocDirectory = await getApplicationDocumentsDirectory();
        if (io.Platform.isIOS) {
          appDocDirectory = await getApplicationDocumentsDirectory();
        } else {
          appDocDirectory = await getExternalStorageDirectory();
        }

        // can add extension like ".mp4" ".wav" ".m4a" ".aac"
        customPath = appDocDirectory.path +
            customPath +
            DateTime.now().millisecondsSinceEpoch.toString();

        // .wav <---> AudioFormat.WAV
        // .mp4 .m4a .aac <---> AudioFormat.AAC
        // AudioFormat is optional, if given value, will overwrite path extension when there is conflicts.
        _recorder =
            FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);

        await _recorder.initialized;
        // after initialization
        var current = await _recorder.current(channel: 0);
        print(current);
        // should be "Initialized", if all working fine
        setState(() {
          _current = current;
          _currentStatus = current.status;
          print(_currentStatus);
        });
      } else {
        Scaffold.of(context).showSnackBar(
            new SnackBar(content: new Text("You must accept permissions")));
      }
    } catch (e) {
      print(e);
    }
  }

  _start() async {
    try {
      await _recorder.start();
      var recording = await _recorder.current(channel: 0);
      setState(() {
        _current = recording;
      });

      const tick = const Duration(milliseconds: 50);
      new Timer.periodic(tick, (Timer t) async {
        if (_currentStatus == RecordingStatus.Stopped) {
          t.cancel();
        }

        var current = await _recorder.current(channel: 0);
        // print(current.status);
        setState(() {
          _current = current;
          _currentStatus = _current.status;
        });
      });
    } catch (e) {
      print(e);
    }
  }

  _resume() async {
    await _recorder.resume();
    setState(() {});
  }

  _pause() async {
    await _recorder.pause();
    setState(() {});
  }

  _stop() async {
    var result = await _recorder.stop();
    print("Stop recording: ${result.path}");
    print("Stop recording: ${result.duration}");
    File file = widget.localFileSystem.file(result.path);
    print("File length: ${await file.length()}");
    setState(() {
      _current = result;
      _currentStatus = _current.status;
    });
  }

  Widget _buildText(RecordingStatus status) {
    var text = "";
    switch (_currentStatus) {
      case RecordingStatus.Initialized:
        {
          text = 'Start';
          break;
        }
      case RecordingStatus.Recording:
        {
          text = 'Pause';
          break;
        }
      case RecordingStatus.Paused:
        {
          text = 'Resume';
          break;
        }
      case RecordingStatus.Stopped:
        {
          text = 'Init';
          break;
        }
      default:
        break;
    }
    return Text(text, style: TextStyle(color: Colors.white));
  }

  void onPlayAudio() async {
    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.play(_current.path, isLocal: true);
  }
}

//import 'package:flutter/material.dart';
//
//void main() => runApp(MyApp());
//
//class MyApp extends StatelessWidget {
//  final appTitle = 'Drawer Demo';
//
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      title: appTitle,
//      home: MyHomePage(title: appTitle),
//    );
//  }
//}
//
//class MyHomePage extends StatelessWidget {
//  final String title;
//
//  MyHomePage({Key key, this.title}) : super(key: key);
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(title: Text(title)),
//      body: Center(child: Text('My Page!')),
//      drawer: Drawer(
//        // Add a ListView to the drawer. This ensures the user can scroll
//        // through the options in the drawer if there isn't enough vertical
//        // space to fit everything.
//        child: ListView(
//          // Important: Remove any padding from the ListView.
//          padding: EdgeInsets.zero,
//          children: <Widget>[
//            DrawerHeader(
//              child: Text('No Notes'),
//              decoration: BoxDecoration(
//                color: Colors.blue,
//              ),
//            ),
//            ExpansionTile(
//              title: Text("Folders"),
//              children: <Widget>[
//                ExpansionTile(
//                  title: Text("Recordings"),
//                  children: <Widget>[
//                    ListTile(
//                      title: Text('Audio'),
//                      onTap: () {
//                        // Update the state of the app
//                        // ...
//                        // Then close the drawer
//                        Navigator.pop(context);
//                      },
//                    ),
//                    ListTile(
//                      title: Text('Transcripts'),
//                      onTap: () {
//                        // Update the state of the app
//                        // ...
//                        // Then close the drawer
//                        Navigator.pop(context);
//                      },
//                    ),
//                    ListTile(
//                      title: Text('Summaries'),
//                      onTap: () {
//                        // Update the state of the app
//                        // ...
//                        // Then close the drawer
//                        Navigator.pop(context);
//                      },
//                    )
//                  ],
//                ),
//                ExpansionTile(
//                  title: Text("Import Recording"),
//                  children: <Widget>[
//                    ListTile(
//                      title: Text('Transcribe Recording'),
//                      onTap: () {
//                        // Update the state of the app
//                        // ...
//                        // Then close the drawer
//                        Navigator.pop(context);
//                      },
//                    ),
//                    ListTile(
//                      title: Text('Summarize Recording'),
//                      onTap: () {
//                        // Update the state of the app
//                        // ...
//                        // Then close the drawer
//                        Navigator.pop(context);
//                      },
//                    )
//                  ],
//                ),
//                ExpansionTile(
//                  title: Text("Notes"),
//                  children: <Widget>[
//                    ListTile(
//                      title: Text('Edit Notes/Summaries'),
//                      onTap: () {
//                        // Update the state of the app
//                        // ...
//                        // Then close the drawer
//                        Navigator.pop(context);
//                      },
//                    )
//                  ],
//                )
//              ],
//            ),
//            ExpansionTile(
//              title: Text("Record Now"),
//              children: <Widget>[
//                ListTile(
//                  title: Text('Pause/Resume'),
//                  onTap: () {
//                    // Update the state of the app
//                    // ...
//                    // Then close the drawer
//                    Navigator.pop(context);
//                  },
//                ),
//                ListTile(
//                  title: Text('Stop'),
//                  onTap: () {
//                    // Update the state of the app
//                    // ...
//                    // Then close the drawer
//                    Navigator.pop(context);
//                  },
//                ),
//                ListTile(
//                  title: Text('Add Notes'),
//                  onTap: () {
//                    // Update the state of the app
//                    // ...
//                    // Then close the drawer
//                    Navigator.pop(context);
//                  },
//                ),
//                ListTile(
//                  title: Text('Add Bookmark'),
//                  onTap: () {
//                    // Update the state of the app
//                    // ...
//                    // Then close the drawer
//                    Navigator.pop(context);
//                  },
//                )
//              ],
//            ),
//            ExpansionTile(
//              title: Text("Folder Management"),
//              children: <Widget>[
//                ListTile(
//                  title: Text('New Folder'),
//                  onTap: () {
//                    // Update the state of the app
//                    // ...
//                    // Then close the drawer
//                    Navigator.pop(context);
//                  },
//                ),
//                ListTile(
//                  title: Text('Rename Folder'),
//                  onTap: () {
//                    // Update the state of the app
//                    // ...
//                    // Then close the drawer
//                    Navigator.pop(context);
//                  },
//                ),
//                ListTile(
//                  title: Text('Folder Options'),
//                  onTap: () {
//                    // Update the state of the app
//                    // ...
//                    // Then close the drawer
//                    Navigator.pop(context);
//                  },
//                ),
//                ListTile(
//                  title: Text('Backup/Import/Export Folders'),
//                  onTap: () {
//                    // Update the state of the app
//                    // ...
//                    // Then close the drawer
//                    Navigator.pop(context);
//                  },
//                )
//              ],
//            ),
//            ListTile(
//              title: Text('Settings'),
//              onTap: () {
//                // Update the state of the app
//                // ...
//                // Then close the drawer
//                Navigator.pop(context);
//              },
//            ),
//          ],
//        ),
//      ),
//    );
//  }
//}
