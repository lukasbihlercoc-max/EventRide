//Buchsuche mit Bewertung und Sprache
// -> Filtersuche

import 'dart:io';

class Buch {
  String titel;
  String autor;
  int seitenanzahl;
  String genre;
  bool verfuegbarkeit;
  double bewertung;     //z.B. 4.5
  String sprache;       //z.B. "Deutsch", "Englisch"

  Buch(this.titel, this.autor, this.seitenanzahl, this.genre, this.verfuegbarkeit, this.bewertung, this.sprache);

  String ausgeliehen () {
    return verfuegbarkeit? "verfügbar" : "verliehen";
  }
}

List<Buch> bibliothek = [
  Buch("Hobbit", "J.R.R.", 280, "Fantasy", true, 4.9, "Deutsch"),
  Buch("Die Bibel", "Gott", 1500, "Sachbuch", false, 2.8, "Englisch"),
  Buch("Morden im Norden", "Otto", 7, "Krimi", false, 4.4, "Englisch"),
  Buch("Die Zauberer von Döbriach", "Lukas", 289, "Komoedie", true, 4.6, "Deutsch"),
  Buch("Mann am Mond", "Willi", 310, "Fantasy", true, 4.1, "Deutsch"),
  Buch("Hinter die Rüstung Römern", "i söba", 79999, "Komoedie", false, 2.0, "Englisch")
];

void uebung9 () {

stdout.write("Welches Genre interessiert Sie ? ");
String genre = stdin.readLineSync()?.trim().toLowerCase() ?? "";

stdout.write("Wieviel Seiten soll das Buch ca. haben? ");
int seiten = int.tryParse(stdin.readLineSync() ?? "") ?? 0;

stdout.write("Welche Sprache bevorzugen Sie? ");
String sprache  =  stdin.readLineSync()?.trim().toLowerCase() ?? "";

List<Buch> passendeBuecher = bibliothek.where((buch) => 
buch.genre.toLowerCase().trim() == genre.trim() &&
buch.seitenanzahl >= (seiten - 50) &&
buch.seitenanzahl <= (seiten + 50) &&
buch.verfuegbarkeit &&
buch.bewertung >= 3.0 &&
buch.sprache.trim().toLowerCase() == sprache
).toList();

for (var buch in bibliothek) {
  print("Teste Buch: ${buch.titel}");
  print("Genre passt: ${buch.genre.trim().toLowerCase() == genre}");
  print("Seitenanzahl passt: ${buch.seitenanzahl >= (seiten - 50) && buch.seitenanzahl <= (seiten + 50)}");
  print("Verfügbar: ${buch.verfuegbarkeit}");
  print("Bewertung passt: ${buch.bewertung >= 3.0}");
  print("Sprache passt: ${buch.sprache.trim().toLowerCase() == sprache}");
  print("------");
}

if(passendeBuecher.isEmpty) {
  print("Es wurden keine passenden Bücher gefunden! Versuche es erneut.");
} else {
  print("Folgende Bücher passen zu ihrer Suche: ");
  for(var buch in passendeBuecher)  {
    print("""
    Titel: ${buch.titel}
    Autor: ${buch.autor}
    Seiten: ${buch.seitenanzahl}
    Genre: ${buch.genre}
    Verfügbarkeit: ${buch.ausgeliehen()}
    Bewertung: ${buch.bewertung}
    Sprache: ${buch.sprache}
    """);
  }
}
}