// events_page.dart
import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:my_app/views/widgets/app_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:my_app/data/event_daten.dart';
import 'package:my_app/data/event_service.dart';
import 'package:intl/intl.dart';
import 'package:my_app/views/widgets/background_widget.dart';

InputDecoration getInputStyle(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      color: Colors.white70,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.white70,
        width: 2,
      ),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.deepPurpleAccent,
        width: 4,
      ),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    contentPadding: const EdgeInsets.symmetric(
      vertical: 20,
      horizontal: 16,
    ),
    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
  );
}

const inputTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 20,
  fontWeight: FontWeight.w600,
);

class EventsPage extends StatefulWidget {
  final Event? event; // optional: edit existing
  const EventsPage({super.key, required this.event});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final NameController = TextEditingController();
  final standortController = TextEditingController();
  final datumController = TextEditingController();
  String? typ = "e0";
  final beschreibungController = TextEditingController();
  final adresseController = TextEditingController();
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();

    if (widget.event != null) {
      NameController.text = widget.event!.name;
      standortController.text = widget.event!.standort;
      datumController.text = DateFormat("dd.MM.yyyy").format(widget.event!.datum);
      typ = widget.event!.typ;
      beschreibungController.text = widget.event!.beschreibung;
      adresseController.text = widget.event!.adresse;
      _latitude = widget.event!.latitude;
      _longitude = widget.event!.longitude;
    }
  }

  @override
  void dispose() {
    NameController.dispose();
    standortController.dispose();
    datumController.dispose();
    beschreibungController.dispose();
    adresseController.dispose();
    super.dispose();
  }

  Future<void> _saveEvent() async {
    // Datum validieren
    if (datumController.text.trim().isEmpty) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: "Bitte ein Datum auswählen",
      );
      return;
    }

    try {
      final parsedDate =
          DateFormat("dd.MM.yyyy").parseStrict(datumController.text);

      final eventService = context.read<EventService>();


      if (widget.event == null) {
        // Neues Event erstellen
        final newEvent = Event(
          name: NameController.text.trim().isEmpty
              ? "Unbenanntes Event"
              : NameController.text.trim(),
          datum: parsedDate,
          standort: standortController.text.isNotEmpty
              ? standortController.text.trim()
              : "Unbekannt",
          typ: typ ?? "e0",
          beschreibung: beschreibungController.text.trim(),
          adresse: adresseController.text.trim().isNotEmpty
              ? adresseController.text.trim()
              : "Adresse nicht angegeben",
          latitude: _latitude,
          longitude: _longitude,
        );

        await eventService.add(newEvent);
      } else {
        // Bestehendes Event: immutable update via copyWith
        final updatedEvent = widget.event!.copyWith(
          name: NameController.text.trim().isEmpty
              ? widget.event!.name
              : NameController.text.trim(),
          datum: parsedDate,
          standort: standortController.text.trim().isNotEmpty
              ? standortController.text.trim()
              : widget.event!.standort,
          typ: typ ?? widget.event!.typ,
          beschreibung: beschreibungController.text.trim(),
          adresse: adresseController.text.trim().isNotEmpty
              ? adresseController.text.trim()
              : widget.event!.adresse,
          latitude: _latitude,
          longitude: _longitude,
        );

        await eventService.update(updatedEvent);


      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: "Ungültiges Datumformat",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.event == null ? "Neues Event erstellen" : "Event bearbeiten",
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: NameController,
                  style: inputTextStyle,
                  decoration: getInputStyle("Eventname"),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: datumController,
                  style: inputTextStyle,
                  decoration: getInputStyle("Datum"),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: widget.event?.datum ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      locale: const Locale('de', 'DE'),
                    );
                    if (pickedDate != null) {
                      String formattedDate =
                          DateFormat('dd.MM.yyyy').format(pickedDate);
                      setState(() {
                        datumController.text = formattedDate;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte ein Datum auswählen';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: standortController,
                  style: inputTextStyle,
                  decoration: getInputStyle("Standort"),
                ),
                const SizedBox(height: 16),
                GooglePlaceAutoCompleteTextField(
                  textEditingController: adresseController,
                  googleAPIKey: "AIzaSyB97RZAMf-fmZKhdFFniU20CqK0QWCV3KE",
                  inputDecoration: getInputStyle("genaue Adresse"),
                  textStyle: inputTextStyle,
                  boxDecoration: const BoxDecoration(color: Colors.transparent),
                  debounceTime: 600,
                  countries: const ["at"],
                  language: 'de',
                  isLatLngRequired: true,
                  itemBuilder: (context, index, prediction) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF1B3F78),
                        border: Border(
                          left: BorderSide(color: Color(0xFF5DA9FF), width: 3),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: Color(0xFF5DA9FF), size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              prediction.description ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  seperatedBuilder: const Divider(height: 1, color: Colors.white24),
                  getPlaceDetailWithLatLng: (prediction) {
                    setState(() {
                      _latitude = double.tryParse(prediction.lat ?? '');
                      _longitude = double.tryParse(prediction.lng ?? '');
                    });
                  },
                  itemClick: (prediction) {
                    adresseController.text = prediction.description ?? '';
                    adresseController.selection = TextSelection.fromPosition(
                      TextPosition(offset: adresseController.text.length),
                    );
                  },
                ),
                const SizedBox(height: 16),
                DropdownButton(
                  dropdownColor: const Color.fromARGB(164, 9, 61, 216),
                  style: inputTextStyle,
                  value: typ,
                  items: const [
                    DropdownMenuItem(value: "e0", child: Text("Standart")),
                    DropdownMenuItem(value: "e1", child: Text("Kirchtag")),
                    DropdownMenuItem(value: "e2", child: Text("Feuerwehrfest")),
                    DropdownMenuItem(value: "e3", child: Text("Disco")),
                    DropdownMenuItem(value: "e4", child: Text("Ball")),
                    DropdownMenuItem(value: "e5", child: Text("Krampuslauf")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      typ = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: beschreibungController,
                  style: inputTextStyle,
                  decoration: getInputStyle("Beschreibung"),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saveEvent,
                  child: Text(widget.event == null ? "Event abspeichern" : "Änderungen speichern"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
