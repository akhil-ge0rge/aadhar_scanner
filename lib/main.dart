import 'dart:convert' as convert;
import 'dart:developer';
import 'dart:io';
import 'package:aadhar_scanner/const.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? image;
  void pickImage() async {
    final ImagePicker picker = ImagePicker();
    final imageX = await picker.pickImage(source: ImageSource.gallery);

    if (imageX != null) {
      setState(() {
        image = imageX;
      });
    }
  }

  Map<String, String> data = {};

  void processImage() async {
    data = {};
    final inputImage = InputImage.fromFile(File(image!.path));
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );

    for (int i = 0; i < recognizedText.blocks.length; i++) {
      log(recognizedText.blocks.elementAt(i).text);
      if (recognizedText.blocks.elementAt(i).text.contains("DOB")) {
        log(i.toString());
        data['dob'] = (recognizedText.blocks.elementAt(i).text.split(' ').last);
        data['name'] = recognizedText.blocks.elementAt(i - 1).text;
        data['gender'] = recognizedText.blocks.elementAt(i + 1).text;
        data['id'] = recognizedText.blocks.elementAt(i + 2).text;
      }
    }

    log(data.toString() + "DATA");
    setState(() {});
    textRecognizer.close();
  }

  String extractName(String text) {
    RegExp nameRegex = RegExp(r'(Name|नाम)\s*[:\-]?\s*(.*)');
    final match = nameRegex.firstMatch(text);
    return match != null ? match.group(2) ?? '' : '';
  }

  String extractAadhaarNumber(String text) {
    RegExp aadhaarRegex = RegExp(r'\b\d{4}\s\d{4}\s\d{4}\b');
    final match = aadhaarRegex.firstMatch(text);
    return match != null ? match.group(0) ?? '' : '';
  }

  String extractDOB(String text) {
    RegExp dobRegex = RegExp(
      r'(DOB|Date of Birth|जन्म तिथि)\s*[:\-]?\s*(\d{2}[\/\-]\d{2}[\/\-]\d{4}|\d{4})',
    );
    final match = dobRegex.firstMatch(text);
    return match != null ? match.group(2) ?? '' : '';
  }

  String extractGender(String text) {
    RegExp genderRegex = RegExp(
      r'\b(MALE|FEMALE|TRANSGENDER|पुरुष|महिला)\b',
      caseSensitive: false,
    );
    final match = genderRegex.firstMatch(text);
    return match != null ? match.group(0)?.toUpperCase() ?? '' : '';
  }

  void addToForm({
    required String name,
    required String gender,
    required String dob,
    required String id,
  }) async {
    String query = "?name=$name&sex=$gender&dob=$dob&id=xxxyyzz";
    var finalURI = Uri.parse(baseURL + query);
    var response = await http.get(finalURI);
    log(response.statusCode.toString());
    if (response.statusCode == 200) {
      log(response.body.toString());
      var bodyR = convert.jsonDecode(response.body);
      log(bodyR);
    } else {
      log(response.body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Image PIck")),
      body: Column(
        children: [
          Center(
            child: ElevatedButton(
              child: Text("Pick Image"),
              onPressed: pickImage,
            ),
          ),
          SizedBox(height: 30),
          if (image != null) ...[
            SizedBox(
              width: 300,
              height: 300,
              child: Image.file(File(image!.path)),
            ),
            ElevatedButton(
              onPressed: processImage,
              child: Text("Process Image"),
            ),
            if (data.isNotEmpty) ...[
              SizedBox(
                width: 300,
                height: 150,
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final key = data.keys.elementAt(index).toUpperCase();
                    final value = data.values.elementAt(index).toUpperCase();

                    return Text("$key : $value");
                  },
                ),
              ),

              SizedBox(height: 30),
              ElevatedButton(
                onPressed:
                    () => addToForm(
                      dob: data["dob"] ?? "",
                      gender: data["gender"] ?? "",
                      id: data["id"] ?? "",
                      name: data["name"] ?? "",
                    ),
                child: Text("add to excel"),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
