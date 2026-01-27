import "dart:io";

void uebung2(){
//String name = "Lukas";
//int alter = 20;
//bool stammkunde = false;
//double preis = 12.99;

  //Name abfragen:
stdout.write("Wie heißt du?: ");
String? name = stdin.readLineSync();    //liest Eingabe als String (? -> wenn nichts, dann 0)

  //Alter abfragen:
stdout.write("Wie alt bist du?: ");
String? alterInput = stdin.readLineSync();
int alter = int.parse(alterInput ?? "0");

  //Stammkunde?
stdout.write("Haben sie bereits ein Konto? (ja/nein): ");
String? angemeldetInput = stdin.readLineSync()?.toLowerCase() ?? "";
bool istAngemeldet = (angemeldetInput == "ja");

  //if-Schleife:
  if(angemeldetInput == "ja" && alter >= 18)  {
    print("Willkommen");
  } else {
    print("kein Zugang");
  }
}