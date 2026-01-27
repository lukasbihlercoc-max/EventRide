//Buch suchen; Suchfilter: Genre, Seitenanzahl (nur verfügbare Bücher)

import 'dart:io';

import 'package:uebungen/utils.dart';

  class Buch  {
    String titel;
    String autor;
    int seitenanzahl;
    String genre;
    bool verfuegbarkeit;

    Buch(this.titel, this.autor, this.seitenanzahl, this.genre, this.verfuegbarkeit);

    String ausgeliehen () {
      return verfuegbarkeit? "verfügbar" : "verliehen";
    }
  }

  Map<String, Buch> bibliothek = {
  "hobbit":                       Buch("Hobbit", "J.R.R.", 280, "Fantasy", true),
  "die bibel":                    Buch("Die Bibel", "Gott", 1500, "Sachbuch", false),
  "morden im norden":             Buch("Morden im Norden", "Otto", 7, "Krimi", false),
  "der Zauberer von döbriach":    Buch("Die Zauberer von Döbriach", "Lukas", 289, "Komödie", true),
  "mann am mond":                 Buch("Mann am Mond", "Willi", 310, "Fantasy", true),
  "hinter die rüstung römern":    Buch("Hinter die Rüstung Römern", "Suff", 79999, "vagessn", false)
  };

  void uebung8()  {

    stdout.write("Welches Buch wollen Sie suchen? ");
    String ausgewaehlt = stdin.readLineSync()?.trim().toLowerCase() ?? "";

    /*List<String> passendeTitel = bibliothek.keys.where((titel) => titel.toLowerCase().contains(ausgewaehlt)).toList();


    if(passendeTitel.isEmpty) {
      print("Es wurden keine passenden Bücher gefunden");
    } else{
      for (var schluessel in passendeTitel){
        Buch gefunden = bibliothek[schluessel]!;
        print("""
        Titel: ${gefunden.titel}
        Autor: ${gefunden.autor}
        Seitenanzahl: ${gefunden.seitenanzahl}
        Genre: ${gefunden.seitenanzahl}
        Verfügbarkeit: ${{gefunden.ausgeliehen()}}""");
      }
    }
    */

  if(bibliothek.containsKey(ausgewaehlt)) {             // wenn variable "ausgewaehlt" in einem Schlüssel enthalten ist dann,...
    Buch gefunden = bibliothek[ausgewaehlt]!;           // speichert variable, um in schleife auf bibliothek zuzugreifen 
    print("""
    Hier sind einige Informationen zu ${gefunden.titel}: 
    Autor: ${gefunden.autor}
    Seiten: ${gefunden.seitenanzahl}
    Genre: ${gefunden.genre}
    Verfügbarkeit: ${gefunden.ausgeliehen()}
    """);
      } else {                                                  // sonst...
        print("Buch nicht gefunden!");
        stdout.write("Welches Genre Interessiert Sie ");        // Eingabeaufforderung
        String? filterGenre = stdin.readLineSync()?.trim();     // trim entfernt Leerzeichen in Eingabe

        stdout.write("Und wieviele Seiten soll das Buch ca. haben? ");      
        int filterSeiten = int.tryParse(stdin.readLineSync() ?? "") ?? 0;   //wandelt eingabe in eine ganzzahlige Zahl um
      
      // Es werden alle Bücher nach bestimmten kriterien gefiltert
      // Das Ergebnis ist eine Liste von passenden Büchern, die ich "passendeBuecher" nenne
      List<Buch> passendeBuecher = bibliothek.values.where((buch) => buch.genre.toLowerCase() == 
        filterGenre?.toLowerCase() &&
        buch.seitenanzahl >= (filterSeiten - 50) && 
        buch.seitenanzahl <= (filterSeiten + 50) &&
        buch.verfuegbarkeit
      ).toList();
      
      if(passendeBuecher.isEmpty){                         //Wenn nichts zutrifft, die Liste also leer ist, gibt es folgende anzeige:
        print("Keine Bücher gefunden");
      } else {                                             //sonst:
        print("Folgende Bücher passen zu Ihrer Suche");
        for(var buch in passendeBuecher)  {                // for-in Schleife, um alle passenden aus der Liste (passendeBuecher) nacheinander aufzulisten
          print("""
          Titel: ${buch.titel}
          Autor: ${buch.autor}
          Seitenanzahl: ${buch.seitenanzahl}
          Genre: ${buch.genre}
          Verfügbarkeit: ${buch.ausgeliehen()}
          """);
        }
      }
    }
  }