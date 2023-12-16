//Modelo para guardar la informacion
class Apprentice {
  final int id;
  final String firstName;
  final String firstLastName;
  final String secondLastName;
  bool isAttended;
  String state;
  bool showPersonIcon; // Nueva propiedad

  Apprentice({
    required this.id,
    required this.firstName,
    required this.firstLastName,
    required this.secondLastName,
    this.isAttended = false,
    this.state = '',
    this.showPersonIcon = true, // Valor predeterminado es true
  });
}
