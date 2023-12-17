import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:faker/faker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter MySQL',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const App(),
    );
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  List? data;

  final faker = Faker();

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController ageController = TextEditingController();

  final dbSetting = ConnectionSettings(
    host: '192.168.245.40',
    port: 3306,
    user: 'root',
    db: 'flutter_users',
    // password: '', //Comment If No Password Needed
  );

  createTable() async {
    final conn = await MySqlConnection.connect(dbSetting);

    final response = await conn.query(
      'CREATE TABLE users (id int NOT NULL AUTO_INCREMENT PRIMARY KEY, name varchar(255), email varchar(255), age int)',
    );

    print(response.fields);

    await conn.close();
  }

  createData() async {
    final conn = await MySqlConnection.connect(dbSetting);

    final result = await conn.query(
      'INSERT INTO users (name, email, age) VALUES (?, ?, ?)',
      [
        faker.person.name(),
        faker.internet.email(),
        faker.randomGenerator.integer(100, min: 5),
      ],
    );

    setState(() {
      readData();
    });

    print('Inserted ROW id=${result.insertId}');

    await conn.close();
  }

  readData() async {
    final conn = await MySqlConnection.connect(dbSetting);

    var results = await conn.query(
      'SELECT id, name, email, age FROM users ',
    );

    for (var row in results) {
      print('Id: ${row[0]}, Name: ${row[1]}, email: ${row[2]} age: ${row[3]}');
    }

    setState(() {
      data = results.toList();
    });

    await conn.close();
  }

  updateData(String name, String email, int age, int id) async {
    final conn = await MySqlConnection.connect(dbSetting);

    await conn.query(
      'UPDATE users SET name=?, email=?, age=? WHERE id=?',
      [name, email, age, id],
    );

    setState(() {
      readData();
    });

    await conn.close();
  }

  deleteData(int id) async {
    final conn = await MySqlConnection.connect(dbSetting);
    await conn.query(
      'DELETE FROM users WHERE id=?',
      [id],
    );
    await readData();
    await conn.close();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Local MySQL'),
        actions: [
          IconButton(
            onPressed: () {
              //REFRESH DATA
              setState(() {
                readData();
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await createData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Random Data'),
      ),
      body: data == null
          ? const Center(child: Text('No Data'))
          : ListView.separated(
              itemCount: data?.length ?? 0,
              separatorBuilder: (context, index) {
                return const Divider();
              },
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () {
                    nameController.text = data?[index][1];
                    emailController.text = data?[index][2];
                    ageController.text = data?[index][3].toString() ?? '0';

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('Update Data'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                ),
                                initialValue: data?[index][1],
                                onChanged: (value) {
                                  nameController.text = value;
                                },
                              ),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                initialValue: data?[index][2],
                                onChanged: (value) {
                                  emailController.text = value;
                                },
                              ),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Age',
                                ),
                                keyboardType: TextInputType.number,
                                initialValue: data?[index][3].toString(),
                                onChanged: (value) {
                                  ageController.text = value;
                                },
                              ),
                            ],
                          ),
                          actions: [
                            OutlinedButton(
                              onPressed: () {
                                nameController.clear();
                                emailController.clear();
                                ageController.clear();
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await updateData(
                                  nameController.text,
                                  emailController.text,
                                  int.tryParse(ageController.text) ?? 0,
                                  data?[index][0],
                                );
                                nameController.clear();
                                emailController.clear();
                                ageController.clear();
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  leading: CircleAvatar(
                    //User ID
                    child: Text('${data?[index][0]}'),
                  ),
                  //Username & Age
                  title: Text(
                    '${data?[index][1]} - ${data?[index][3]} yO',
                  ),
                  //User Email
                  subtitle: Text('${data?[index][2]}'),
                  trailing: IconButton(
                    onPressed: () async {
                      await deleteData(data?[index][0]);
                    },
                    icon: const Icon(Icons.delete),
                  ),
                );
              },
            ),
    );
  }
}
