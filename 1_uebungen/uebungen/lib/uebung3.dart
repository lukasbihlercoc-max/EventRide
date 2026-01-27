//ähnlich wie Übung 2; doch diesmal wird "utils.dart" eingebunden und die übung etwas erweitert

import "package:uebungen/utils.dart";

void uebung3()  {

  double preis = 19.99;

  String name = frageName("Wie heißt du?: ");
  int alter = frageAlter("Wie alt bist du?: ");
  bool kunde = frageKunde("Bist du bereits Kunde?: ");

    if(kunde == true && alter >= 18)  {
      double preisrabatt = preis * 0.9;
      print("Willkommen, als treuer Kunde bekommen Sie 10% Rabatt. Preis: ${preisrabatt.toStringAsFixed(2)}");
    } else if(alter >= 18) {
      print("Wilkommen! Preis: $preis");
    } else {
      print("Zugang verweigert!");
    }

}



