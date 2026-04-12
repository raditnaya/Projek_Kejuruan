import 'package:flutter/material.dart';

void main() {
  runApp(const ReservationApp());
}

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

enum UserRole { admin, user }

class AppUser {
  const AppUser({
    required this.username,
    required this.password,
    required this.role,
    required this.displayName,
  });
  final String username, password, displayName;
  final UserRole role;
}

class Reservation {
  Reservation({
    required this.id,
    required this.customerName,
    required this.sportField,
    required this.note,
    required this.createdBy,
    required this.startTime,
    required this.endTime,
  });
  final String id;
  String customerName;
  String sportField;
  String note;
  final String createdBy;
  TimeOfDay startTime;
  TimeOfDay endTime;
}

class ReservationApp extends StatefulWidget {
  const ReservationApp({super.key});
  @override
  State<ReservationApp> createState() => _ReservationAppState();
}

class _ReservationAppState extends State<ReservationApp> {
  final List<AppUser> _users = const [
    AppUser(
      username: 'admin',
      password: '123',
      role: UserRole.admin,
      displayName: 'Admin Lapangan',
    ),
    AppUser(
      username: 'user',
      password: '123',
      role: UserRole.user,
      displayName: 'Eko (Pelanggan)',
    ),
  ];

  final List<Reservation> _reservations = [
    Reservation(
      id: '1',
      customerName: 'Budi',
      sportField: 'Futsal A',
      note: 'Lunas',
      createdBy: 'admin',
      startTime: const TimeOfDay(hour: 18, minute: 0),
      endTime: const TimeOfDay(hour: 19, minute: 0),
    ),
  ];

  AppUser? _activeUser;

  void _login(String user, String pass) {
    final found = _users.where((u) => u.username == user && u.password == pass);
    if (found.isEmpty) {
      messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text("Login Gagal!")),
      );
    } else {
      setState(() => _activeUser = found.first);
    }
  }

  void _add(Reservation r) => setState(() => _reservations.add(r));

  void _delete(String id) =>
      setState(() => _reservations.removeWhere((r) => r.id == id));

  // Update fungsi agar menerima waktu baru
  void _update(
    String id,
    String newField,
    String newNote,
    TimeOfDay start,
    TimeOfDay end,
  ) {
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index != -1) {
      setState(() {
        _reservations[index].sportField = newField;
        _reservations[index].note = newNote;
        _reservations[index].startTime = start;
        _reservations[index].endTime = end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: _activeUser == null
          ? LoginPage(onLogin: _login)
          : DashboardPage(
              user: _activeUser!,
              data: _reservations,
              onLogout: () => setState(() => _activeUser = null),
              onAdd: _add,
              onDelete: _delete,
              onUpdate: _update,
            ),
    );
  }
}

class LoginPage extends StatelessWidget {
  LoginPage({super.key, required this.onLogin});
  final Function(String, String) onLogin;
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_tennis, size: 50, color: Colors.green),
                const Text(
                  "Login Reservasi",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(labelText: "Username"),
                ),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => onLogin(userCtrl.text, passCtrl.text),
                  child: const Text("Masuk"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.user,
    required this.data,
    required this.onLogout,
    required this.onAdd,
    required this.onDelete,
    required this.onUpdate,
  });

  final AppUser user;
  final List<Reservation> data;
  final VoidCallback onLogout;
  final Function(Reservation) onAdd;
  final Function(String) onDelete;
  final Function(String, String, String, TimeOfDay, TimeOfDay) onUpdate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard ${user.displayName}"),
        actions: [
          IconButton(onPressed: onLogout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: ListView.builder(
        itemCount: data.length,
        itemBuilder: (ctx, i) {
          final r = data[i];
          final bool isOwner =
              user.role == UserRole.admin || r.createdBy == user.username;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: ListTile(
              title: Text(
                r.sportField,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "👤 Pemesan: ${r.customerName}\n"
                "⏰ Waktu: ${r.startTime.format(ctx)} - ${r.endTime.format(ctx)}\n"
                "📝 Catatan: ${r.note}",
              ),
              trailing: isOwner
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditDialog(ctx, r),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => onDelete(r.id),
                        ),
                      ],
                    )
                  : const Icon(Icons.lock_outline),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final g = TextEditingController();
    final f = TextEditingController();
    final n = TextEditingController();
    TimeOfDay start = const TimeOfDay(hour: 18, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 19, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Tambah Reservasi"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: g,
                  decoration: const InputDecoration(
                    labelText: "Nama Pelanggan",
                  ),
                ),
                TextField(
                  controller: f,
                  decoration: const InputDecoration(labelText: "Nama Lapangan"),
                ),
                TextField(
                  controller: n,
                  decoration: const InputDecoration(labelText: "Catatan"),
                ),
                ListTile(
                  title: Text("Mulai: ${start.format(context)}"),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: start,
                    );
                    if (time != null) setDialogState(() => start = time);
                  },
                ),
                ListTile(
                  title: Text("Selesai: ${end.format(context)}"),
                  trailing: const Icon(Icons.history_toggle_off),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: end,
                    );
                    if (time != null) setDialogState(() => end = time);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                onAdd(
                  Reservation(
                    id: DateTime.now().toString(),
                    customerName: g.text.isEmpty ? user.displayName : g.text,
                    sportField: f.text,
                    note: n.text,
                    createdBy: user.username,
                    startTime: start,
                    endTime: end,
                  ),
                );
                Navigator.pop(ctx);
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Reservation r) {
    final g = TextEditingController(text: r.customerName);
    final f = TextEditingController(text: r.sportField);
    final n = TextEditingController(text: r.note);
    TimeOfDay start = r.startTime;
    TimeOfDay end = r.endTime;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Reservasi"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: g,
                  decoration: const InputDecoration(
                    labelText: "Nama Pelanggan",
                  ),
                ),
                TextField(
                  controller: f,
                  decoration: const InputDecoration(labelText: "Nama Lapangan"),
                ),
                TextField(
                  controller: n,
                  decoration: const InputDecoration(labelText: "Catatan"),
                ),
                ListTile(
                  title: Text("Mulai: ${start.format(context)}"),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: start,
                    );
                    if (time != null) setDialogState(() => start = time);
                  },
                ),
                ListTile(
                  title: Text("Selesai: ${end.format(context)}"),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: end,
                    );
                    if (time != null) setDialogState(() => end = time);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                onUpdate(r.id, f.text, n.text, start, end);
                Navigator.pop(ctx);
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}
