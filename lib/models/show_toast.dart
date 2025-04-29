import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ShowToast{
  final String message;
  final bool duration;

  const ShowToast(this.message, this.duration);

    void flutterToastmsg(){
    Fluttertoast.showToast(
        msg: 'Please allow permission to access media',
        toastLength: duration? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: const Color.fromARGB(100, 255, 255, 225),
        textColor: const Color.fromARGB(255, 255, 255, 255),
        fontSize: 16.0,
      );
  }
}