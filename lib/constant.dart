// ---- STRINGS -----
import 'package:flutter/material.dart';

const baseURL = 'http://192.168.0.108:8081/api/sigac';
const loginURL = baseURL + '/login';
const registerURL = '$baseURL/register';
const logoutURL = baseURL + '/logout';
const userURL = baseURL + '/user';
const asistenciaURL = baseURL + '/asistencia/';
const asistenciaupdateURL = baseURL + '/asistencia/update/';
const buscarasistenciaURL = baseURL + '/asistencia/buscar/';
const aprendiceslistURL = baseURL + '/aprendices/list/';
// ---- Errors ----------
const serverError = 'Error de servidor';
const unauthorized = 'No autorizado';
const somethingWentWrong = '¡Algo salió mal, intenta de nuevo!';

// -----Input decoration

InputDecoration kInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    contentPadding: EdgeInsets.all(10),
    labelStyle: TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        width: 1,
        color: Color.fromARGB(255, 0, 0, 0),
      ),
      borderRadius: BorderRadius.all(Radius.circular(5)),
    ),
  );
}

// Button login
TextButton kTextButton(String label, Function onPressed) {
  return TextButton(
    child: Text(
      label,
      style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
    ),
    style: ButtonStyle(
        backgroundColor: MaterialStateColor.resolveWith(
            (states) => Color.fromARGB(255, 0, 132, 255)),
        padding: MaterialStateProperty.resolveWith(
            (states) => EdgeInsets.symmetric(vertical: 10))),
    onPressed: () => onPressed(),
  );
}

// loginRegisterhint
Row kLoginRegisterHint(String text, String label, Function onTap) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        text,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.grey,
              blurRadius: 3,
              offset: Offset(1, 1),
            ),
          ],
        ),
      ),
      GestureDetector(
        child: Text(
          label,
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        onTap: () => onTap(),
      ),
    ],
  );
}

// likes and comment btn

Expanded kLikeAndComment(
    int value, IconData icon, Color color, Function onTap) {
  return Expanded(
    child: Material(
      child: InkWell(
        onTap: () => onTap(),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              SizedBox(width: 4),
              Text('$value')
            ],
          ),
        ),
      ),
    ),
  );
}
