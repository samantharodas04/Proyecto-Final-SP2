import 'package:flutter/material.dart';

class InputDecorations {
  //tres parametros //hintText, labelText y prefixIcon
  static InputDecoration inputDecoration({
    required String hintext,
    required String labeltext,
    required Icon icono
  }) {
    return InputDecoration(
      enabledBorder: UnderlineInputBorder( 
          borderSide:BorderSide(color: Colors.deepPurpleAccent),),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color:Colors.deepPurple,width: 2),),// para que la linea sea de color morado
        hintText: hintext,
        labelText: labeltext,
        prefixIcon: icono,
    );
  }
}