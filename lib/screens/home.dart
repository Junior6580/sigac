import 'package:flutter/material.dart';
import 'package:sigac/models/api_response.dart';
import 'package:sigac/models/user.dart';
import 'package:sigac/screens/attendance.dart';
import 'package:sigac/screens/login.dart';
import 'package:sigac/services/user_service.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int currentTab = 0;
  final List<Widget> screens = [
    FutureBuilder<ApiResponse<User>>(
      future: getUserDetail(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          String? instructorId = snapshot.data!.data?.personId.toString();
          return InstructorProgram(instructorId: instructorId ?? '');
        } else if (snapshot.hasError) {
          print(snapshot.error);
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return Center(
              child: Text('No se pudo obtener los detalles del usuario'));
        }
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SIGAC - Asistencia'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(
              Icons.exit_to_app,
              color: Colors.black, // Set the color to black
            ),
            onPressed: () {
              logout().then((value) => {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => Login()),
                      (route) => false,
                    )
                  });
            },
          )
        ],
      ),
      body: screens[currentTab],
    );
  }
}
