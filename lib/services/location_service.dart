import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Demande la permission et récupère la position actuelle
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifie si la localisation est activée
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Localisation désactivée.");
      return null;
    }

    // Vérifie les permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Permission refusée.");
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Permission refusée de manière permanente.");
      return null;
    }

    // Récupère la position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}