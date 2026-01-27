//Die gleiche Übung wie vorher, aber nur mit Maps statt einer Liste

class Buch{
  String titel;
  String autor;
  int seitenanzahl;
  bool ausgeliehen;

  Buch(this.titel, this.autor, this.seitenanzahl, this.ausgeliehen);

  String verfuegbar()  {
    return ausgeliehen ? "ausgeliehen" : "verfügbar";
  }
}

//Map
Map<String, Buch> bibliothek = {
  "Affenalarm": Buch("Affenalarm", "J.J.", 205, true),
  "Schlangen im Teich": Buch("Schlangen im Teich", "Hömut", 3, false),
  "WosEssMaHeit": Buch("WosEssMaHeit", "Hunga", 789, true),
};

void uebung6()  {
  //Durch alle Einträge der Map gehen
  bibliothek.forEach((titel, buch) {
    print("${buch.titel} - ${buch.seitenanzahl} Seiten - Status: ${buch.verfuegbar()}");
  });

/* In Übung 7 nochmal 
  stdout.write("Welches Buch suchen Sie?:");
  var eingabe = stdin.readLineSync()?.trim() ?? "";

  //Ist Buch verfügbar?:
  if (bibliothek.containsKey(eingabe))  {
    Buch gefunden = bibliothek[eingabe]!;
      if (gefunden.ausgeliehen == false) {
        print("$eingabe existiert und ist verfügbar");
      } else if (gefunden.ausgeliehen == true) {
        print("$eingabe existiert, ist aber momentan verliehen");
      }
  } else {
    print("Ihr eingegebenes Buch existiert in unserer Bücherei nicht");
  }*/
}