//Klassen und Listen

class Kunde {
  String name;
  int alter;
  bool istKunde;

  Kunde(this.name, this.alter, this.istKunde);

  String stammkundeAusgabe (){
    return istKunde ? "ja" : "nein";
  }
}

List<Kunde> kunden = [
  Kunde("Lukas", 20, true),
  Kunde("Mia", 17, false),
];

void uebung4()  {
  for (var i in kunden) {
    print("${i.name} (${i.alter}) - Stammkund: ${i.stammkundeAusgabe()}");
  }
}