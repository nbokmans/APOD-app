// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('APOD Viewer'),
        ),
        body: Center(child: Apod()),
      ),
    );
  }
}

class Apod extends StatefulWidget {
  @override
  _ApodState createState() => _ApodState();
}

class _ApodState extends State<Apod> {
  DateTime? selectedDate = DateTime.now();
  late Future<List<APODResult>> futureResults;

  @override
  void initState() {
    super.initState();
    futureResults = fetchApodData(selectedDate);
  }

  _resetDate() {
    setState(() {
      selectedDate = DateTime.now();
    });
  }

  _selectDate(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    assert(theme.platform != null);
    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return buildMaterialDatePicker(context);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return buildCupertinoDatePicker(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: FutureBuilder<List<APODResult>>(
              future: futureResults,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var selected = snapshot.data?.elementAt(0);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text("${selectedDate?.toLocal()}".split(' ')[0]),
                      Image.network(selected?.image ??
                          'https://picsum.photos/250?image=9'),
                      Text(
                        "${selected?.description.toString()} ${selectedDate?.toLocal()}"
                            .split(' ')[0],
                        style:
                            TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      RaisedButton(
                        onPressed: () => _selectDate(context),
                        child: Text(
                          'Select date',
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        color: Colors.greenAccent,
                      ),
                      RaisedButton(
                        onPressed: () => _resetDate(),
                        child: Text(
                          'Reset date',
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        color: Colors.greenAccent,
                      ),
                      RaisedButton(
                        onPressed: () => setState(() {
                          selectedDate = selectedDate?.add(Duration(days: -1));
                          futureResults = fetchApodData(selectedDate);
                        }),
                        child: Text(
                          '<',
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        color: Colors.greenAccent,
                      ),
                      RaisedButton(
                        onPressed: () => setState(() {
                          selectedDate = selectedDate?.add(Duration(days: -1));
                          futureResults = fetchApodData(selectedDate);
                        }),
                        child: Text(
                          '>',
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        color: Colors.greenAccent,
                      )
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }

                return const CircularProgressIndicator();
              })),
    );
  }

  buildCupertinoDatePicker(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext builder) {
          return Container(
            height: MediaQuery.of(context).copyWith().size.height / 3,
            color: Colors.white,
            child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                onDateTimeChanged: (picked) {
                  if (picked != null && picked != selectedDate) {
                    setState(() {
                      selectedDate = picked;
                    });
                    futureResults = fetchApodData(picked);
                  }
                },
                initialDateTime: selectedDate,
                minimumYear: 2000,
                maximumDate: DateTime.now()),
          );
        });
  }

  buildMaterialDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendar,
      initialDatePickerMode: DatePickerMode.day,
      helpText: 'Select booking date',
      cancelText: 'Not now',
      confirmText: 'Book',
      errorFormatText: 'Enter valid date',
      errorInvalidText: 'Enter date in valid range',
      fieldLabelText: 'Booking date',
      fieldHintText: 'Month/Date/Year',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light(),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      print(picked);
      futureResults = fetchApodData(picked);
    }
  }
}

Future<List<APODResult>> fetchApodData(DateTime? date) async {
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  print(date);
  final String formattedDate = formatter.format(date ?? DateTime.now());
  final response =
      await http.get(Uri.parse('http://localhost:8080/apod/$formattedDate'));

  print(Uri.parse('http://localhost:8080/apod/$formattedDate'));

  if (response.statusCode == 200) {
    var json = jsonDecode(response.body);
    var data = json.map<APODResult>((j) => APODResult.fromJson(j)).toList();
    return data;
  } else {
    throw Exception('Failed to load album');
  }
}

class APODAuthor {
  final String name;
  final String website;

  APODAuthor({required this.name, required this.website});

  factory APODAuthor.fromJson(Map<String, dynamic> json) {
    return APODAuthor(name: json['name'], website: json['website']);
  }
}

class APODResult {
  final DateTime date;
  final String image;
  final String fullSizeImage;
  final String? name;
  final String description;
  final List<APODAuthor> authors;

  APODResult(
      {required this.date,
      required this.image,
      required this.fullSizeImage,
      required this.name,
      required this.description,
      required this.authors});

  factory APODResult.fromJson(Map<String, dynamic> json) {
    return APODResult(
        date: DateTime.parse(json['date']),
        image: json['image'],
        fullSizeImage: json['fullSizeImage'],
        name: json['name'],
        description: json['description'],
        authors: (json['authors'] as List)
            .map((j) => APODAuthor.fromJson(j))
            .toList());
  }
}
