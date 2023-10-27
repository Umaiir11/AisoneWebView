import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';

class URL extends StatefulWidget {
  const URL({Key? key}) : super(key: key);

  @override
  State<URL> createState() => _URLState();
}

class _URLState extends State<URL> {
  @override

  late WebViewController _webViewController;
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: Scaffold(
            body: Stack(
              children: [
                WebView(
                  gestureNavigationEnabled: true,
                  initialUrl: 'https://hvacr-election.aisonesystems.com/',
                  initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
                  javascriptMode: JavascriptMode.unrestricted,
                  zoomEnabled: false,
                  onWebViewCreated: (WebViewController controller) async {
                    // Inject CSS to disable zooming
                    controller.runJavascript("""
        document.querySelector('body').style.touchAction = 'pan-x pan-y';
    """);

                    _webViewController = controller;
                    _webViewController.runJavascript(
                        "navigator.geolocation.getCurrentPosition(function(position) { console.log(position); });");

                    controller.runJavascript('''
        navigator.geolocation.getCurrentPosition(function(position) {
          var locationName = position.coords.latitude + ', ' + position.coords.longitude;
          setLocation(locationName);
        }, function(error) {
          showLocationError();
        });
    ''');

                    // Check if location service is enabled
                    bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
                    if (isLocationEnabled) {
                      // Get current position
                      Position position = await Geolocator.getCurrentPosition();
                      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

                      Placemark placemark = placemarks[0];
                      String locationName = '${placemark.name ?? ''}, ${placemark.locality ?? ''}, ${placemark.country ?? ''}';

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Your location is $locationName."),
                        duration: Duration(seconds: 3),
                      ));
                      // Call JavaScript function to handle location data
                      _webViewController.runJavascript("setLocation('$locationName');");
                    } else {
                      // Show location service disabled message
                      _webViewController.runJavascript("showLocationError();");
                    }
                  },
                  onPageFinished: (String url) {
                    // Inject CSS to disable zooming
                    _webViewController.runJavascript("""
        document.querySelector('body').style.touchAction = 'pan-x pan-y';
    """);
                    _webViewController.runJavascript(
                        "if (navigator.geolocation) { navigator.geolocation.watchPosition = function(successCallback, errorCallback, options) { return new Promise((resolve, reject) => { navigator.geolocation.getCurrentPosition(successCallback, errorCallback, options); }); } };");
                    setState(() {
                      isLoading = false;
                    });
                  },
                ),
                if (isLoading)
                  Center(
                    child: LoadingAnimationWidget.twistingDots(
                      leftDotColor:  Colors.lightBlueAccent,
                      rightDotColor: Colors.black,
                      size: 40,
                    ),
                  ),
              ],
            )),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (await _webViewController.canGoBack()) {
      _webViewController.goBack();
      return false;
    } else {
      SystemNavigator.pop();
      return true;
    }
  }

  Future<void> FncPermissions() async {
    PermissionStatus l_mediaPermission = await Permission.location.request();

    if (l_mediaPermission == PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Permission granted"),
        duration: Duration(milliseconds: 900),
      ));
    } else if (l_mediaPermission == PermissionStatus.denied) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("This permission is recommended."),
        duration: Duration(milliseconds: 900),
      ));
    } else if (l_mediaPermission == PermissionStatus.permanentlyDenied) {
      bool isShown = await Permission.location.shouldShowRequestRationale;
      if (isShown) {
        // Show a dialog explaining why the permission is needed
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text("Location Permission Required"),
            content: Text("This app needs to access your location to function properly."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("OK"),
              ),
            ],
          ),
        ).then((value) async {
          if (value == true) {
            // Request permission again
            FncPermissions();
          }
        });
      } else {
        // Prompt the user to go to the app settings and grant the permission manually
        openAppSettings();
      }
    }
  }
}
