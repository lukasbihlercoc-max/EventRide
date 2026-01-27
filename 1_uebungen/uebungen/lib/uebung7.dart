//Gleich wie Übung 6 + Erweiterungen
//Zuerst werden die Bücher vorgestellt, dann kann man sich eins aussuchen, zu dem man nähere Infos will, es soll auf die Key Wörter geachtet werden,
//  falls die Eingabe falsch ist

import 'dart:io';

class Buch {
  String titel;
  String autor;
  int seitenanzahl;
  bool ausgeliehen;

  Buch(this.titel, this.autor, this.seitenanzahl, this.ausgeliehen);

  String verfuegbar() {
    return ausgeliehen ? "verliehen" : "verfügbar";
  }

}

Map<String, Buch> bibliothek = {
  "Hobbit":                    Buch("Hobbit", "J.R.R.", 280, true),
  "Die Bibel":                 Buch("Die Bibel", "Gott", 1500, false),
  "Morden im Norden":          Buch("Morden im Norden", "Otto", 7, false),
  "Der Zauberer von Döbriach": Buch("Die Zauberer von Döbriach", "Lukas", 289, true),
  "Mann am Mond":              Buch("Mann am Mond", "Willi", 40000, true),
};

void uebung7()  {

print("Es gibt folgende Titel: ");
bibliothek.forEach((titel, buch)  {
  print("- ${buch.titel}");
});

stdout.write("Zu welchem dieser Bücher wollen sie nähere Informationen?");
var ausgewaehlt = stdin.readLineSync()?.trim().toLowerCase() ?? "";

// Case-insensitiver Schlüsselvergleich
String? schluessel = bibliothek.keys.firstWhere((titel) => titel.toLowerCase() == ausgewaehlt,
  orElse: () => "",
);

  if(schluessel != "")  {
    Buch gefunden = bibliothek[schluessel]!;  
    print("""Hier sind Informationen zu       
    ${gefunden.titel}: 
    Autor: ${gefunden.autor}, 
    Seiten: ${gefunden.seitenanzahl}, 
    Verfügbarkeit: ${gefunden.verfuegbar()} """);
  } else {
    // Vorschläge bei Teiltreffern
    List<String> vorschlaege = bibliothek.keys
      .where((titel) => titel.toLowerCase().contains(ausgewaehlt)).toList();

    String vorgeschlagenerTitel = vorschlaege.first;
    print("Meintest du: $vorgeschlagenerTitel");
    String? ausbersserung = stdin.readLineSync()?.trim().toLowerCase();

    if(ausbersserung =="ja")  {
      Buch buch = bibliothek[vorgeschlagenerTitel]!;
      print("""Hier sind Informationen zu ${buch.titel}:
      Autor: ${buch.autor}
      Seiten: ${buch.seitenanzahl}
      Verfügbarkeit: ${buch.verfuegbar()}""");
      }if (vorschlaege.isNotEmpty) {
      String vorgeschlagenerTitel = vorschlaege.first;
      } else {
        print("Wir haben keine Titel für Sie gefunden!");
      }
    /*
    if (vorschlaege.isNotEmpty) {
      print("Meintest du vielleicht: ");
      for(var i in vorschlaege) {
        print(" $vorschlaege");
      stdout.write("");
      String? ausbersserung = stdin.readLineSync();
        Buch i = bibliothek[ausbersserung]!;
        if(ausbersserung == "ja") {
          print("""
          Titel: ${i.titel}
          Autor: ${i.autor}
          Seiten: ${i.seintenanzahl}
          Verfügbarkeit: ${i.ausgeliehen}""");
        }
      }
    } else {
      print("Es wurden keine Bücher oder Vorschläge gefunden! Versuchen Sie es erneut.");
    }*/
  }
}