import "dart:io";

String frageName(String name) {
  stdout.write(name);
  return stdin.readLineSync() ?? "";
}

int frageAlter(String alter) {
  stdout.write(alter);
  return int.tryParse(stdin.readLineSync() ?? "") ?? 0;
}

bool frageKunde(String kunde) {
  stdout.write(kunde);
  String antwort = stdin.readLineSync()?.toLowerCase() ?? "";
  return antwort == "ja";
}


/*
String frageName(String name) {                 // Funktion gibt einen String zurück, nimmt Parameter name
  stdout.write(name);                           // schreibt den übergebenen Text auf die Konsole (ohne Zeilenumbruch)
  return stdin.readLineSync() ?? "";            // liest Eingabe; wenn null, dann leerer String; Rückgabe an Aufrufer
}                                               // Ende der Funktion frageName

int frageAlter(String alter) {                  // Funktion gibt eine Zahl zurück, nimmt Parameter alter
  stdout.write(alter);                          // schreibt den übergebenen Text auf die Konsole
  return int.tryParse(stdin.readLineSync() ?? "") ?? 0;  // liest Eingabe, versucht Zahl in ganze Zahl umzuwandeln, sonst 0
}                                               // Ende der Funktion frageAlter

bool frageKunde(String kunde) {                 // Funktion gibt bool zurück, nimmt Parameter kunde
  stdout.write(kunde);                          // schreibt den übergebenen Text auf die Konsole
  String antwort = stdin.readLineSync()?.toLowerCase() ?? ""; // liest Eingabe, wandelt in Kleinbuchstaben, ersetzt null durch ""
  return antwort == "ja";                       // gibt true zurück, wenn Eingabe exakt "ja", sonst false
}                                               // Ende der Funktion frageKunde
*/