import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigac/models/api_response.dart';
import 'package:sigac/models/user.dart';
import 'package:sigac/screens/home.dart';
import 'package:sigac/services/user_service.dart';

import '../../constant.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> formkey = GlobalKey<FormState>();
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtPassword = TextEditingController();
  bool loading = false;

  void _loginUser() async {
    ApiResponse response = await login(txtEmail.text, txtPassword.text);
    if (response.error == null) {
      _saveAndRedirectToHome(response.data as User);
    } else {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${response.error}')));
    }
  }

  void _saveAndRedirectToHome(User user) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString('token', user.token ?? '');
    await pref.setInt('userId', user.id ?? 0);
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => Home()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SIGAC',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue, // Set the app bar color to blue
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/img.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 16),
              child: Image.asset(
                'assets/images/logo.png',
                height: 100,
                width: 100,
              ),
            ),
            Expanded(
              child: Form(
                key: formkey,
                child: ListView(
                  padding: EdgeInsets.all(32),
                  children: [
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      controller: txtEmail,
                      validator: (val) => val!.isEmpty
                          ? 'Dirección de correo electrónico no válida'
                          : null,
                      decoration: kInputDecoration('Correo Electrónico'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: txtPassword,
                      obscureText: true,
                      validator: (val) => val!.length < 6
                          ? 'Se requieren al menos 6 caracteres'
                          : null,
                      decoration: kInputDecoration('Contraseña'),
                    ),
                    SizedBox(height: 10),
                    loading
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : kTextButton('Login', () {
                            if (formkey.currentState!.validate()) {
                              setState(() {
                                loading = true;
                                _loginUser();
                              });
                            }
                          }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
