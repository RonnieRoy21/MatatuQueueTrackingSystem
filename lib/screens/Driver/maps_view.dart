import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';
class MapsView extends StatefulWidget {
  const MapsView({super.key});

  @override
  State<MapsView> createState() => _MapsViewState();
}

class _MapsViewState extends State<MapsView> {
  //initialize webview controller
  late final WebViewController controller;
  //url for opening google maps
  final String urlMaps = 'https://maps.google.com/';


  //function to implement webview
  void _loadWebview() {
    try{
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)

      ..loadRequest(Uri.parse(urlMaps))

      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onHttpError: (error) {
          // Handle error.
          Fluttertoast.showToast(
              msg: 'Error navigating to  ${error.response?.uri}');
        },
        onPageStarted: (String url) {
          Fluttertoast.showToast(msg: "loading Google Maps");
        },
        onPageFinished: (String url) {
          Fluttertoast.showToast(msg: "Google Maps loaded");
        },
      )
      );
    }catch(err){
      Fluttertoast.showToast(msg: "Error : ${err.toString()}");
    }
  }

  @override
  void initState(){
    super.initState();
    _loadWebview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maps View'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: WebViewWidget(controller: controller),
      )

    );
  }
}
