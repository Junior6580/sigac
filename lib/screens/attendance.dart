// Importing necessary Flutter and Dart packages
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sigac/models/apprentice.dart';
import 'package:sigac/services/user_service.dart';
import 'package:sigac/constant.dart';

class InstructorProgram extends StatefulWidget {
  final String instructorId;

  const InstructorProgram({required this.instructorId});

  @override
  _InstructorProgramState createState() => _InstructorProgramState();
}

class _InstructorProgramState extends State<InstructorProgram> {
  String apiUrl = aprendiceslistURL;
  DateTime currentDate = DateTime.now();
  List<dynamic> _programs = [];

  // Estos métodos se encargan de obtener y actualizar la lista de
  // programas desde la API. fetchData realiza la solicitud HTTP
  // updatePrograms actualiza la interfaz de usuario después de obtener los datos.
  Future<List<dynamic>?> fetchData() async {
    try {
      // Formatear la fecha y hora actual
      String date = DateFormat('yyyy-MM-dd').format(currentDate);
      String time = DateFormat('HH:mm:ss').format(currentDate);

      // Construir la URL de la API con el instructorId, la fecha y la hora
      String url = '$apiUrl${widget.instructorId}/$date/$time';

      // Obtener el token de autenticación
      String token = await getToken();

      // Realizar la solicitud HTTP GET a la API
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // Verificar si la solicitud fue exitosa (código de estado 200)
      if (response.statusCode == 200) {
        // Decodificar la respuesta JSON y obtener la lista de programas
        Map<String, dynamic> data = jsonDecode(response.body);
        return data['list'];
      } else {
        // Lanzar una excepción si la solicitud no fue exitosa
        throw Exception('Error al obtener datos de la API');
      }
    } catch (e) {
      // Capturar y mostrar cualquier error durante la obtención de datos
      print('Error al obtener datos: $e');
      return null;
    }
  }

  /// Toma la asistencia para un aprendiz en un programa en una fecha específica.
  ///
  /// Parámetros:
  /// - [apprenticeId]: Identificación del aprendiz.
  /// - [state]: Estado de la asistencia.
  /// - [programId]: Identificación del programa.
  /// - [selectedDate]: Fecha seleccionada para la asistencia.
  ///
  /// Devuelve un [Future] de tipo [void].
  Future<void> takeAttendance(int apprenticeId, String state, int programId,
      DateTime selectedDate) async {
    try {
      String token = await getToken();
      String date = DateFormat('yyyy-MM-dd').format(currentDate);

      // Lógica para consultar la API de verificación
      String apiUrl = buscarasistenciaURL;
      String checkApiUrl = '$apiUrl';
      Map<String, String> checkHeaders = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };
      Map<String, dynamic> checkBody = {
        'userid': apprenticeId.toString(),
        'instructorprogramid': programId.toString(),
        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
        'time': DateFormat('HH:mm:ss').format(DateTime.now()),
      };
      String checkJsonBody = jsonEncode(checkBody);

      final checkResponse = await http.post(Uri.parse(checkApiUrl),
          headers: checkHeaders, body: checkJsonBody);

      if (checkResponse.statusCode == 200) {
        // Ya existe una asistencia para esta persona en este programa en esta fecha y hora
        // updateExistingAttendance lógica para actualizar una asistencia existente
        await updateExistingAttendance(
            apprenticeId, state, programId, selectedDate, token);
      } else if (checkResponse.statusCode == 404) {
        // No existe asistencia, procede a registrarla
        await registerAttendance(
            apprenticeId, state, programId, selectedDate, token);
      } else {
        // Manejar otros casos según sea necesario
        print(
            'Error en la verificación de asistencia: ${checkResponse.statusCode}');
      }
    } catch (e) {
      print('Error al tomar la asistencia: $e');
    }
  }

  /// Actualiza la asistencia existente para un aprendiz en un programa específico.
  ///
  /// Parámetros:
  /// - [apprenticeId]: ID del aprendiz cuya asistencia se actualizará.
  /// - [state]: Estado de la asistencia (por ejemplo, presente, ausente).
  /// - [programId]: ID del programa al que está asociado el aprendiz.
  /// - [selectedDate]: Fecha seleccionada para la actualización de la asistencia.
  /// - [token]: Token de autorización para la llamada a la API.
  Future<void> updateExistingAttendance(int apprenticeId, String state,
      int programId, DateTime selectedDate, String token) async {
    try {
      // Definir la URL de la API de actualización de asistencia
      String apiUrl = asistenciaupdateURL;
      String checkApiUrl = '$apiUrl';

      // Configurar los encabezados para la solicitud HTTP
      Map<String, String> checkHeaders = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };

      // Configurar el cuerpo de la solicitud HTTP
      Map<String, dynamic> checkBody = {
        'userid': apprenticeId.toString(),
        'state': state,
        'instructorprogramid': programId.toString(),
        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
        'time': DateFormat('HH:mm:ss').format(DateTime.now()),
      };

      // Convertir el cuerpo a formato JSON
      String checkJsonBody = jsonEncode(checkBody);

      // Realizar la solicitud HTTP de tipo PUT
      final checkResponse = await http.put(Uri.parse(checkApiUrl),
          headers: checkHeaders, body: checkJsonBody);

      // Verificar el código de estado de la respuesta HTTP
      if (checkResponse.statusCode == 200 || checkResponse.statusCode == 404) {
        // Actualizar la UI después de una llamada API exitosa o 404
        await updatePrograms();

        // Obtener el objeto del aprendiz
        var apprenticeObj = findApprenticeObj(apprenticeId);

        // Actualizar la interfaz de usuario si se encuentra el objeto del aprendiz
        if (apprenticeObj != null) {
          setState(() {
            apprenticeObj.showPersonIcon = false;
            apprenticeObj.state = state;
          });
        }
      } else {
        // Manejar otros casos según sea necesario
        print(
            'Error en la verificación de asistencia: ${checkResponse.statusCode}');
      }
    } catch (e) {
      // Capturar y manejar errores durante la ejecución
      print('Error al tomar la asistencia: $e');
    }
  }

// Modificar el método findApprenticeObj para actualizar directamente el objeto existente
  Apprentice? findApprenticeObj(int apprenticeId) {
    for (var program in _programs) {
      var programId = program?['id'];
      if (program != null && program['course'] != null) {
        var apprentices = program['course']['apprentices'];
        for (var apprenticeData in apprentices) {
          if (apprenticeData != null &&
              apprenticeData['person_id'] == apprenticeId) {
            var apprentice = apprenticeData['person'];

            // Verificar si hay asistencias al cargar la lista
            bool hasAttendances = hasAttendance(apprentice['attendances']);
            String attendanceState =
                hasAttendances ? apprentice['attendances'].last['state'] : '';

            // Verificar si la asistencia pertenece al programa actual
            bool isAttendanceForProgram = false;
            if (hasAttendances) {
              var lastAttendanceProgramId =
                  apprentice['attendances'].last['instructor_program_id'];
              isAttendanceForProgram = lastAttendanceProgramId == programId;
            }

            // Actualizar directamente el objeto apprentice existente
            apprenticeData['isAttended'] = isAttendanceForProgram;
            apprenticeData['state'] = attendanceState;

            return Apprentice(
              id: apprenticeId,
              firstName: apprentice['first_name'] ?? '',
              firstLastName: apprentice['first_last_name'] ?? '',
              secondLastName: apprentice['second_last_name'] ?? '',
              isAttended: isAttendanceForProgram,
              state: attendanceState,
              showPersonIcon: !hasAttendances,
            );
          }
        }
      }
    }
    return null;
  }

// Función para verificar si el aprendiz ya tiene asistencia
// ... método para verificar si el aprendiz ya tiene asistencias ...
  bool hasAttendance(List<dynamic>? attendances) {
    return attendances != null && attendances.isNotEmpty;
  }

  Future<void> registerAttendance(int apprenticeId, String state, int programId,
      DateTime selectedDate, String token) async {
    try {
      String apiUrl = asistenciaURL;
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };
      Map<String, dynamic> body = {
        'userid': apprenticeId.toString(),
        'state': state,
        'instructorprogramid': programId.toString(),
        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
        'time': DateFormat('HH:mm:ss').format(DateTime.now()),
      };
      String jsonBody = jsonEncode(body);

      final response =
          await http.post(Uri.parse(apiUrl), headers: headers, body: jsonBody);

      if (response.statusCode == 200) {
        // Éxito al tomar la asistencia
        await updatePrograms();
        print('Asistencia tomada con éxito');
      } else {
        print('Error al tomar la asistencia');
      }
    } catch (e) {
      print('Error al tomar la asistencia: $e');
    }
  }

  Future<void> updatePrograms() async {
    var completer = Completer<void>();

    try {
      var data = await fetchData();
      print('data : $data');

      if (data != null && data.isNotEmpty) {
        setState(() {
          _programs.clear(); // Limpiar la lista antes de agregar nuevos datos
          _programs.addAll(data);
        });
        completer.complete(); // Marcar la operación como completada con éxito
      } else {
        setState(() {
          _programs = [];
          print('Error al obtener datos o los datos están vacíos.');
        });
        completer
            .completeError('Error al obtener datos o los datos están vacíos.');
      }
    } catch (e) {
      setState(() {
        _programs = [];
        print('Error al obtener datos: $e');
      });
      completer.completeError('Error al obtener datos: $e');
    }

    return completer.future;
  }

  void updateProgramsAfterAttendance(int apprenticeId, String state) {
    setState(() {
      _programs = _programs.map((program) {
        if (program != null &&
            program['course'] != null &&
            program['course']['apprentices'] != null) {
          var apprentices =
              List<Map<String, dynamic>>.from(program['course']['apprentices']);
          for (var i = 0; i < apprentices.length; i++) {
            var apprentice = apprentices[i];
            if (apprentice != null && apprentice['person_id'] == apprenticeId) {
              apprentice['isAttended'] = true;
              apprentice['state'] = state;
            }
          }
          program['course']['apprentices'] = apprentices;
        }
        return program;
      }).toList();
    });
  }

  Future<void> goToPreviousDate() async {
    setState(() {
      currentDate = currentDate.subtract(Duration(days: 1));
    });
    await updatePrograms();
  }

  Future<void> goToNextDate() async {
    setState(() {
      currentDate = currentDate.add(Duration(days: 1));
    });
    await updatePrograms();
  }

  @override
  void initState() {
    super.initState();
    updatePrograms();
  }

  @override
  Widget build(BuildContext context) {
    if (_programs.isEmpty) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: goToPreviousDate,
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(currentDate),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: goToNextDate,
              ),
            ],
          ),
          Text(
            'No se encontró programación para esta fecha.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      );
    } else {
      print('_programs: ${_programs.first?['person']?['first_name']}');

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: goToPreviousDate,
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(currentDate),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: goToNextDate,
              ),
            ],
          ),
          // Agregar el título aquí
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                    'Programa: ${_programs.isNotEmpty ? _programs.first?['course']['program']?['name'] ?? 'Nombre del Programa no disponible' : 'Nombre del Programa no disponible'}\n'),
                SizedBox(height: 8),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: _programs.length,
              itemBuilder: (context, index) {
                var program = _programs[index];
                if (program != null && program?['course'] != null) {
                  var apprentices = program?['course']['apprentices'];
                  var programId = program?['id'];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ListView.builder(
                        key: UniqueKey(),
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: apprentices?.length ?? 0,
                        itemBuilder: (context, index) {
                          var apprentice = apprentices?[index];
                          if (apprentice != null &&
                              apprentice['person'] != null) {
                            var person = apprentice['person'];
                            var apprenticeId = apprentice['person_id'];
                            var firstName = person['first_name'] ?? '';
                            var firstLastName = person['first_last_name'] ?? '';
                            var secondLastName =
                                person['second_last_name'] ?? '';
                            var attendances =
                                person['attendances'] as List<dynamic>;
                            var attendanceprogram = attendances.isNotEmpty
                                ? attendances.first['instructor_program_id']
                                    as int
                                : 0;
                            print(
                                'attendanceprogram: $attendanceprogram, programId: $programId');

                            String attendanceState =
                                ''; // Declara la variable fuera del bloque condicional
                            if (attendanceprogram == programId) {
                              attendanceState = attendances.isNotEmpty
                                  ? attendances.first['state'].toString()
                                  : '';
                            } else {
                              attendanceState = '';
                            }

                            // Simplificar la lógica de la propiedad showPersonIcon
                            var showPersonIcon = !(attendanceState.isNotEmpty);
                            print('icono $showPersonIcon');

                            var apprenticeObj = Apprentice(
                              id: apprenticeId,
                              firstName: firstName,
                              firstLastName: firstLastName,
                              secondLastName: secondLastName,
                              isAttended: attendanceState.isNotEmpty,
                              state: attendanceState,
                              showPersonIcon: showPersonIcon,
                            );

                            var fullName =
                                '$firstName $firstLastName $secondLastName';
                            var state = apprenticeObj.state;

                            return ListTile(
                              key: UniqueKey(),
                              leading: apprenticeObj.isAttended
                                  ? Icon(FontAwesomeIcons.squareCheck,
                                      color: Color.fromARGB(255, 0, 0, 0))
                                  : (apprenticeObj.showPersonIcon
                                      ? Icon(FontAwesomeIcons.circleUser,
                                          color: Color.fromARGB(255, 0, 0, 0))
                                      : null),
                              title: Row(
                                children: [
                                  Text(
                                    fullName,
                                    style: TextStyle(
                                      fontWeight: apprenticeObj.isAttended
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text('Aprendiz'),
                              trailing: PopupMenuButton<String>(
                                itemBuilder: (context) => [
                                  PopupMenuItem<String>(
                                    value: 'P',
                                    child: Row(
                                      children: [
                                        Text('Presente'),
                                        SizedBox(
                                            width:
                                                10), // Ajusta el espacio según sea necesario
                                        Icon(
                                          FontAwesomeIcons.squareCheck,
                                          color:
                                              Color.fromARGB(255, 40, 233, 98),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'MF',
                                    child: Row(
                                      children: [
                                        Text('Media Falla'),
                                        SizedBox(
                                            width:
                                                10), // Ajusta el espacio según sea necesario
                                        Icon(
                                          FontAwesomeIcons.clock,
                                          color:
                                              Color.fromARGB(249, 254, 102, 31),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'FJ',
                                    child: Row(
                                      children: [
                                        Text('Falla Justificada'),
                                        SizedBox(
                                            width:
                                                10), // Ajusta el espacio según sea necesario
                                        Icon(
                                          FontAwesomeIcons.solidTimesCircle,
                                          color:
                                              Color.fromARGB(248, 87, 57, 235),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'FI',
                                    child: Row(
                                      children: [
                                        Text('Falla Injustificada'),
                                        SizedBox(
                                            width:
                                                10), // Ajusta el espacio según sea necesario
                                        Icon(
                                          FontAwesomeIcons.ban,
                                          color:
                                              Color.fromARGB(248, 240, 53, 53),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) async {
                                  await takeAttendance(
                                    apprenticeId ?? 0,
                                    value,
                                    programId ?? 0,
                                    currentDate,
                                  );

                                  WidgetsBinding.instance!
                                      .addPostFrameCallback((_) {
                                    // Después de tomar la asistencia, actualiza la información en la UI
                                    setState(() {
                                      apprentice['isAttended'] = true;
                                      apprentice['state'] =
                                          value; // Usa el valor seleccionado directamente
                                      apprenticeObj.showPersonIcon = false;
                                    });
                                  });
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Visibility(
                                      visible: apprenticeObj.showPersonIcon,
                                      child: Icon(
                                        FontAwesomeIcons.clipboardList,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(apprenticeObj.state),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            return Container(); // Omitir elementos nulos
                          }
                        },
                      ),
                      Divider(),
                    ],
                  );
                } else {
                  return Container(); // Omitir elementos nulos
                }
              },
            ),
          ),
        ],
      );
    }
  }
}
