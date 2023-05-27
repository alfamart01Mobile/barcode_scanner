import 'dart:async';
import 'package:barcode_scanner/application/views/pages/home.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scanner/application/config/constants.dart';
import 'package:barcode_scanner/application/config/session.dart' as session;
import 'package:shared_preferences/shared_preferences.dart';

class LoginView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivery Scanner',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: LoginPage(title: "Admin Login"),
    );
  }
}

class LoginPage extends StatefulWidget {
  LoginPage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final bool _isValidUser = false;
  bool _isPasswordVisible;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _spServerUrl = TextEditingController();
  final _appServer = TextEditingController();
  int lastTap = DateTime.now().millisecondsSinceEpoch;
  int consecutiveTaps = 0;
  @override
  void initState() {
    super.initState();
    this._usernameController.text = '';
    this._passwordController.text = '';
    _isPasswordVisible = true;
    _getAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return WillPopScope(
      onWillPop: () => _appExitConfirm(),
      child: Scaffold(
        body: Builder(builder: (BuildContext context) {
          return Center(
              child: Container(
            padding: new EdgeInsets.all(20.0),
            child: Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(120, 0, 120, 20),
                      child: Image.asset(
                        'assets/img/app-icon.png',
                      ),
                    ),
                    new TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(labelText: 'username'),
                      keyboardType: TextInputType.text,
                      readOnly: false,
                      maxLines: 1,
                    ),
                    new TextFormField(
                      controller: _passwordController,
                      obscureText: _isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            }),
                      ),
                      keyboardType: TextInputType.text,
                      readOnly: false,
                      maxLines: 1,
                    ),
                    new SizedBox(
                      height: 10.0,
                    ),
                    new ButtonBar(
                      alignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new RaisedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (BuildContext context) => HomePage(),
                              ),
                            );
                          },
                          child: Text("    Back    "),
                          shape: new RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(30.0)),
                          color: Colors.redAccent,
                        ),
                        new RaisedButton(
                            onPressed: _isValidUser
                                ? null
                                : () async {
                                    if (_usernameController.text ==
                                            adminUserName &&
                                        _passwordController.text ==
                                            adminPassword) {
                                      _appSettings();
                                    }
                                  },
                            child: Text("     Login     "),
                            shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(30.0)),
                            color: Colors.red),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text(
                        '$APP_SERVER - $APP_VERSION',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  ],
                )),
          ));
        }),
      ),
    );
  }

  Future<bool> _appExitConfirm() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure?'),
        content: Text('Do you want to close an App'),
        actions: <Widget>[
          FlatButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          FlatButton(
            onPressed: () => SystemChannels.platform
                .invokeMethod('SystemNavigator.pop', true),
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<bool> _appSettings() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('App Settings'),
        content: Container(
            width: MediaQuery.of(context).size.width,
            height: 200,
            child: Column(
              children: <Widget>[
                new TextFormField(
                  style: TextStyle(fontSize: 11),
                  controller: _appServer,
                  decoration: InputDecoration(labelText: 'Server Name'),
                  keyboardType: TextInputType.text,
                  readOnly: false,
                  maxLines: 1,
                ),
                new TextFormField(
                  style: TextStyle(fontSize: 11),
                  controller: _spServerUrl,
                  decoration: InputDecoration(labelText: 'API Url'),
                  keyboardType: TextInputType.url,
                  readOnly: false,
                  maxLines: 2,
                ),
              ],
            )),
        actions: <Widget>[
          FlatButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          FlatButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              _updateAppSettings();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
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
  }

  Future<void> _updateAppSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString('spServerUrl', _spServerUrl.text);
      API_URL = _spServerUrl.text;
      setValuesApi();
    });
  }
}
