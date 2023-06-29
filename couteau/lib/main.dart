import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

final List<TextEditingController> controllers = [
  TextEditingController(),
  TextEditingController(),
  TextEditingController(),
  TextEditingController(),
];

urlgetter(
    String site, TextEditingController textboxcontroller, Function postaction,
    {String paramname = 'name', String path = '/', bool ishttp = false}) {
  Function getter = ishttp ? Uri.http : Uri.https;
  Future<void> get() async {
    Uri url = getter(site, path, {paramname: textboxcontroller.text});
    var result = jsonDecode(await http.read(url));
    postaction(result);
  }

  return get;
}

Future<Center> weatherlayout() async {
  TextStyle titlestyle =
      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
  Center errorlayout(String text) {
    return Center(
        child: Column(
      children: [
        Text(
          text,
          style: titlestyle,
        ),
        const Icon(Icons.error, size: 100, color: Colors.red),
      ],
    ));
  }

  bool serviceEnabled;
  LocationPermission permission;
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return errorlayout('El servicio de ubicación no está disponible.');
  }
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return errorlayout(
          'No se puede obtener el clima sin conocer la ubicación');
    }
  }
  if (permission == LocationPermission.deniedForever) {
    return errorlayout(
        'El servicio de ubicación está bloqueado permanentemente.');
  }

  Position position = await Geolocator.getCurrentPosition();
  print(position);
  Uri url = Uri.https('api.openweathermap.org', '/data/3.0/onecall?', {
    'lat': position.latitude,
    'lon': position.longitude,
    'appid': '97d276ae75d7248842102e194cac6ada',
  });
  print(position);
  Map result = jsonDecode(await http.read(url)) as Map;
  result = result['current'];
  String iconurl =
      "http://openweathermap.org/img/w/${result["weather"]["icon"]}.png";
  Image weathericon = Image.network(iconurl);
  return Center(
      child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              const Icon(Icons.cloud, size: 50),
              Text('Nubosidad', style: titlestyle),
              Text(result['clouds'].toString()),
            ],
          ),
          Column(
            children: [
              const Icon(Icons.water_drop, size: 50),
              Text('Humedad', style: titlestyle),
              Text(result['humidity'].toString()),
            ],
          ),
          Column(
            children: [
              weathericon,
              Text('Estado', style: titlestyle),
            ],
          ),
        ],
      ),
      Text(result['weather']['description'].toString()),
    ],
  ));
}

popupimg(BuildContext context, String resultkey, Map<String, String> messages,
    {String message = '', String img = ''}) {
  void g(Map<String, dynamic> result) {
    var resultvalue = result[resultkey];
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Resultado:'),
            content: Column(children: <Widget>[
              Image.network('../imgs/${img.isEmpty ? resultvalue : img}.jpeg',
                  width: 400, height: 300),
              Text(message.isEmpty
                  ? messages[resultvalue].toString()
                  : message.toString())
            ]),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'))
            ],
          );
        });
  }

  return g;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.home)),
              Tab(icon: Icon(Icons.person)),
              Tab(icon: Icon(Icons.onetwothree)),
              Tab(icon: Icon(Icons.school)),
              Tab(icon: Icon(Icons.sunny)),
              Tab(icon: Icon(Icons.info)),
            ],
          ),
          title: const Text('Tabs Demo'),
        ),
        body: Builder(
          builder: (context) => TabBarView(
            children: <Widget>[
              Center(
                  child: Image.network(
                '../imgs/toolbox.jpg',
                width: 500,
                height: 400,
              )),
              Center(
                  child: Column(children: [
                TextField(
                  controller: controllers[0],
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Introduzca su nombre'),
                ),
                ElevatedButton(
                    onPressed: urlgetter(
                        'api.genderize.io',
                        controllers[0],
                        popupimg(context, 'gender', {
                          'male': 'Usted es un hombre',
                          'female': 'Ustes es una mujer'
                        })),
                    child: const Text('Mostrar Género')),
              ])),
              Center(
                  child: Column(children: [
                TextField(
                  controller: controllers[1],
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Introduzca su nombre'),
                ),
                ElevatedButton(
                  onPressed: urlgetter('api.agify.io', controllers[1],
                      (Map<String, dynamic> result) {
                    int age = int.parse(result['age'].toString());
                    String key = 'envejeciente';

                    if (0 > age && age < 15) {
                      key = 'infante';
                    } else if (age < 30) {
                      key = 'joven';
                    } else if (age < 60) {
                      key = 'adulto';
                    }
                    Function popup = popupimg(context, '', {},
                        message: 'Usted es un $key de $age edad', img: key);
                    popup(result);
                  }),
                  child: const Text('Mostrar Edad'),
                ),
              ])),
              Center(
                  child: Column(children: [
                TextField(
                  controller: controllers[2],
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Introduzca el nombre del país'),
                ),
                ElevatedButton(
                  onPressed:
                      urlgetter('universities.hipolabs.com', controllers[2],
                          (List result) {
                    List<String> strings = [];
                    for (Map item in result) {
                      strings.add('Nombre: ${item['name']}\n'
                          'Dominio: ${item['domain']}\n'
                          'Webs: ${item['web_pages'].join(',')}');
                    }
                    controllers[3].text = (strings.join('\n' * 2));
                  }, paramname: 'country', path: '/search', ishttp: true),
                  child: const Text('Mostrar universidades'),
                ),
                TextField(
                  controller: controllers[3],
                  keyboardType: TextInputType.multiline,
                  scrollController: ScrollController(),
                  maxLines: 20,
                ),
              ])),
              FutureBuilder<Center>(
                future: weatherlayout(),
                builder: (context, snapshot) {
                  return Container(child: snapshot.data);
                },
              ),
              Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.network(
                    '../imgs/foto.JPG',
                    width: 220,
                    height: 320,
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Nombre: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Dariel Enmanuel Buret Rivera'),
                    ],
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Correo: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('darielburetrivera@gmail.com'),
                    ],
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Teléfono: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('829-531-6671'),
                    ],
                  )
                ],
              ))
            ],
          ),
        ),
      ),
    ));
  }
}
