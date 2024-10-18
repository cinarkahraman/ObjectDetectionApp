import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';

import 'secondpage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MultiFunctionDemo(),
    );
  }
}

class MultiFunctionDemo extends StatefulWidget {
  const MultiFunctionDemo({super.key});

  @override
  _MultiFunctionDemoState createState() => _MultiFunctionDemoState();
}

class _MultiFunctionDemoState extends State<MultiFunctionDemo> {
  File? _cameraImage;
  File? _galleryImage;
  final picker = ImagePicker();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var _recognitions;
  var v = "";
  bool showPredictions = false;

  @override
  void initState() {
    super.initState();
    loadModel().then((value) {
      setState(() {});
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
  }

  Future<void> _pickImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _cameraImage = File(pickedFile.path);
        _galleryImage = null;
        showPredictions = false;
      } else {
        print('Fotoğraf Seçilmedi.');
      }
    });

    if (_cameraImage != null) {
      detectImage(_cameraImage!);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _galleryImage = File(pickedFile.path);
        _cameraImage = null;
        showPredictions = false;
      } else {
        print('Fotoğraf Seçilmedi.');
      }
    });

    if (_galleryImage != null) {
      detectImage(_galleryImage!);
    }
  }

  Future<void> detectImage(File image) async {
    int startTime = DateTime.now().millisecondsSinceEpoch;
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 6,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    List<String> labels = recognitions
            ?.map<String>((recognition) => recognition['label'].toString())
            .toList() ??
        [];

    setState(() {
      _recognitions = recognitions;
      v = labels.join(', ');
      print(_recognitions);
      showPredictions = _recognitions != null && _recognitions!.isNotEmpty;
    });

    int endTime = DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}ms");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/v904-nunny-010-e.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_cameraImage != null || _galleryImage != null)
                Image.file(
                  _cameraImage ?? _galleryImage!,
                  height: 180,
                  width: 180,
                )
              else
                const Text('Fotoğraf Seçilmedi.'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImageFromCamera,
                icon: const Icon(Icons.camera),
                label: const Text('Kamera Çek'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),

              ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo),
                label: const Text('Galeri Seç'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),

              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    showPredictions = !showPredictions;
                  });
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Tahminleri Göster/Gizle'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),

              // Geçiş için buton ve sayfa ekledik
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SecondPage()),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Cinsiyet Oyununa Git'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),

              // Tahminleri gösteren bölümü showPredictions değişkenine göre kontrol et
              if (showPredictions && _recognitions != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  padding: const EdgeInsets.all(9),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tahminler:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      for (var recognition in _recognitions)
                        Text(
                          '- ${recognition['label']} : ${(recognition['confidence'] * 100).toStringAsFixed(2)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                )
              else
                Container(),
            ],
          ),
        ),
      ),
    );
  }
}
