import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:barcode_scanner/application/config/constants.dart';
import 'package:barcode_scanner/application/helper/AudioPlay.dart';
import 'package:barcode_scanner/application/views/pages/loginView.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:barcode_scanner/application/libraries/mylibrary.dart';
import 'package:imei_plugin/imei_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:barcode_scanner/application/config/session.dart' as session;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State {
  Uint8List bytes = Uint8List(0);

  TextEditingController titleControler = new TextEditingController();
  TextEditingController bodyControler = new TextEditingController();

  AudioPlay scanPlayer = new AudioPlay();
  AudioPlay errorScanPlayer = new AudioPlay();
  String mp3Uri;
  bool _isLoading;
  String _lattitude;
  String _longitude;
  int type;
  String _barcode;
  StreamSubscription<Position> _positionStreamSubscription;

  MyLibrary mylibrary = new MyLibrary();
  final _spServerUrl = TextEditingController();
  final _appServer = TextEditingController();
  int lastTap = DateTime.now().millisecondsSinceEpoch;
  int consecutiveTaps = 0;
  bool _isStart = false;

  @override
  void initState() {
    _longitude = "UNKNOWN";
    _lattitude = "UNKNOWN";
    super.initState();
    _toggleListening();

    _getAppSettings();
  }

  Future<void> _getAppSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _spServerUrl.text = prefs.getString("spServerUrl") ?? '';
    _appServer.text = prefs.getString("appServer") ?? '';
    setState(() {
      if (_spServerUrl.text == '') {
        _spServerUrl.text = API_URL;
      } else {
        API_URL = _spServerUrl.text;
      }
      if (_appServer.text == '') {
        _appServer.text = APP_SERVER;
      } else {
        APP_SERVER = _appServer.text;
      }
      setValuesApi();
    });
  }

  void setValuesApi() {
    setState(() {
      IN_OUT_URL = API_URL + '/insert-update-emp-visit';
      EMP_DEVICE_URL = API_URL + '/';
    });
    _setImei();
  }

  void _toggleListening() {
    if (_positionStreamSubscription == null) {
      const LocationOptions locationOptions =
          LocationOptions(accuracy: LocationAccuracy.medium);
      final Stream<Position> positionStream =
          Geolocator().getPositionStream(locationOptions);
      _positionStreamSubscription =
          positionStream.listen((Position position) => setState(() {
                this._lattitude = position.latitude.toString();
                this._longitude = position.longitude.toString();
                _isStart = true;
              }));
      _positionStreamSubscription.pause();
    }

    setState(() {
      if (_positionStreamSubscription.isPaused) {
        _positionStreamSubscription.resume();
      } else {
        _positionStreamSubscription.pause();
      }
    });
  }

  Future getEmpDevice() async {
    try {
      Dio dio = new Dio();
      var formData = FormData.fromMap({"androidID": session.userDeviceID});

      var response = await dio.post(EMP_DEVICE_URL, data: formData,
          onSendProgress: (int sent, int total) {
        print("$sent $total");
      });

      if (response.data.length == 0) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.ERROR,
          animType: AnimType.BOTTOMSLIDE,
          title: 'Failed!',
          desc:
              'Device not yet registered!. Please contact system administrator. \n User Device ID : ${session.userDeviceID}',
          dismissOnTouchOutside: false,
          btnOkText: "Close App",
          btnOkColor: Colors.red,
          btnOkOnPress: () {
            SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          },
        )..show();
      } else {
        setState(() {
          session.userEmployeeID = int.parse(response.data[0]['Employee_ID']);
          session.userEmployeeNo = response.data[0]['EmployeeNo'];
          session.userFullName = response.data[0]['FullName'];
        });
      }
    } catch (e) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.WARNING,
        animType: AnimType.BOTTOMSLIDE,
        title: 'Error!',
        desc: 'Server connection failed!. ',
        dismissOnTouchOutside: false,
        btnOkText: "Ok",
        btnOkColor: Colors.orangeAccent,
        btnOkOnPress: () {},
      )..show();
      print("Connecting to server failed!.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: GestureDetector(
            onTap: () {
              int now = DateTime.now().millisecondsSinceEpoch;
              if (now - lastTap < 500) {
                print("Consecutive tap");
                consecutiveTaps++;
                print("taps = " + consecutiveTaps.toString());
                if (consecutiveTaps == 3) {
                  print("go to login");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => LoginPage(),
                    ),
                  );
                }
              } else {
                consecutiveTaps = 0;
              }
              lastTap = now;
            },
            child: Text(
              APP_NAME,
              style: TextStyle(fontSize: 16.0),
            ),
          ),
        ),
        body: Builder(builder: (BuildContext context) {
          return SingleChildScrollView(
            child: AbsorbPointer(
              absorbing: false,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      session.userEmployeeID == null
                          ? Text(
                              "No user found!. ",
                              style: TextStyle(fontSize: 20),
                            )
                          : Row(
                              children: [
                                Text(
                                  "Welcome, ",
                                  style: TextStyle(fontSize: 20),
                                ),
                                Text("${session.userFullName}",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold))
                              ],
                            )
                    ],
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height - 150,
                  width: MediaQuery.of(context).size.width,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: new Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          new SizedBox(
                            height: 10.0,
                          ),
                          _isStart != true
                              ? Expanded(
                                  child: Center(
                                    child: Text(
                                      "Identifying Location.... \nMake sure device GPS is ON. ",
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                )
                              : _lattitude == "UNKNOWN"
                                  ? Expanded(
                                      child: Center(
                                        child: Text(
                                          "Device location not found!. Make sure device GPS is ON.",
                                          style: TextStyle(
                                              color: Colors.redAccent),
                                        ),
                                      ),
                                    )
                                  : Expanded(
                                      child: new ButtonBar(
                                        alignment: MainAxisAlignment.center,
                                        buttonPadding: EdgeInsets.all(40),
                                        children: <Widget>[
                                          ClipOval(
                                            child: Material(
                                              color: Colors.red, // button color
                                              child: InkWell(
                                                splashColor: Colors
                                                    .green, // inkwell color
                                                child: SizedBox(
                                                    width: 100,
                                                    height: 100,
                                                    child: Center(
                                                        child: Text(
                                                      'IN',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 24,
                                                          color: Colors.white),
                                                    ))),
                                                onTap: () {
                                                  setState(() {
                                                    type = 1;
                                                  });
                                                  _scan(context);
                                                },
                                              ),
                                            ),
                                          ),
                                          ClipOval(
                                            child: Material(
                                              color: Colors.red, // button color
                                              child: InkWell(
                                                splashColor: Colors
                                                    .green, // inkwell color
                                                child: SizedBox(
                                                    width: 100,
                                                    height: 100,
                                                    child: Center(
                                                        child: Text(
                                                      'OUT',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 24,
                                                          color: Colors.white),
                                                    ))),
                                                onTap: () {
                                                  setState(() {
                                                    type = 0;
                                                  });
                                                  _scan(context);
                                                },
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                          Text(
                              "lat: $_lattitude, long: $_longitude \n device ID:${session.userDeviceID} "),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          );
        }),
      ),
      onWillPop: () {},
    );
  }

  Future<void> _setImei() async {
    String platformImei;
    String deviceId;
    try {
      deviceId = await PlatformDeviceId.getDeviceId;
      print("ANDROID ID : $deviceId");
      platformImei =
          await ImeiPlugin.getImei(shouldShowRequestPermissionRationale: false);
    } catch (e) {
      deviceId = 'Failed to get platform version.';
      print(deviceId);
    }

    if (!mounted) return;

    if (deviceId == null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.ERROR,
        animType: AnimType.BOTTOMSLIDE,
        title: 'Error!',
        desc: 'Device ID not detected!. ',
        dismissOnTouchOutside: false,
        btnOkText: "Restart",
        btnOkColor: Colors.red,
        btnOkOnPress: () {
          Phoenix.rebirth(context);
        },
      )..show();
    } else {
      setState(() {
        session.userImei = platformImei;
        session.userDeviceID = deviceId;
      });

      getEmpDevice();
    }
  }

  Future _scan(context) async {
    _barcode = '';
    try {
      String barcode = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      _scanEffect(true);
      setState(() {
        _barcode = barcode;
        if (_barcode != '') {
          _inOut();
        } else {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.ERROR,
            animType: AnimType.BOTTOMSLIDE,
            btnOkColor: Colors.red,
            title: 'Error!',
            desc: 'Invalid barcode!',
            btnOkOnPress: () {},
          )..show();
        }
      });
    } catch (e) {
      print("Scanning is cancelled");
    }
  }

  Future _inOut() async {
    try {
      Dio dio = new Dio();
      print("employeeID: ${session.userEmployeeID}");
      print("type:  $type");
      print("locationID  0");
      print("lattitude  $_lattitude");
      print("longitude  $_longitude");
      print("isQRCode  0");
      print("locSessionID $_barcode");
      var formData = FormData.fromMap({
        "employeeID": session.userEmployeeID,
        "type": type,
        "locationID": 0,
        "lattitude": _lattitude,
        "longitude": _longitude,
        "isQRCode": 1,
        "locSessionID": _barcode
      });
      var response = await dio.post(IN_OUT_URL, data: formData,
          onSendProgress: (int sent, int total) {
        print("$sent $total");
      });

      if (response.data == null) {
        return null;
      }
      if (int.parse(response.data[0]['RETURN']) >= 0) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.SUCCES,
          animType: AnimType.BOTTOMSLIDE,
          title: 'Successfully!',
          desc: '${response.data[0]['MESSAGE']}',
          btnOkOnPress: () {},
        )..show();
      } else {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.ERROR,
          animType: AnimType.BOTTOMSLIDE,
          title: 'Failed!',
          desc: '${response.data[0]['MESSAGE']}',
          btnOkOnPress: () {},
        )..show();
      }
    } catch (e) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.WARNING,
        animType: AnimType.BOTTOMSLIDE,
        title: 'Error!',
        desc: 'Server connection failed!. ',
        dismissOnTouchOutside: false,
        btnOkText: "Ok",
        btnOkColor: Colors.orangeAccent,
        btnOkOnPress: () {},
      )..show();
      print("Connecting to server failed!.");
    }
  }

  void _scanEffect(bool type) async {
    type == true ? errorScanPlayer.play() : scanPlayer.play();
    await Vibration.vibrate();
  }
}
