//Klassen, Listen, for-Schleifen

class Buch  {
  String titel;
  String autor;
  int seitenanzahl;
  bool ausgeliehen;

  Buch(this.titel, this.autor, this.seitenanzahl, this.ausgeliehen);

  String ausgeliehenText()  {
    return ausgeliehen  ? "ausgeliehen" : "verfügbar";
  }
}

  List<Buch> bibliothek = [
    Buch("Affenarlarm", "J.J.", 205, true),
    Buch("Schlangen im Teich", "Hömut", 3, false),
    Buch("WosEssMaHeit", "Hung", 789, true)
  ];

void uebung5()  {
  for(var i in bibliothek)  {
    print("${i.titel} - ${i.seitenanzahl} Seiten - Status: ${i.ausgeliehenText()}}");
  }
}