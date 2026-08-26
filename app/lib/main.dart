import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'install_button.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChecklistApp());
}

// ============================================================
// APPLICATION
// ============================================================

class ChecklistApp extends StatelessWidget {
  const ChecklistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checklist à toute épreuve',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FF),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Color(0xFFCBD5E1),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Color(0xFFCBD5E1),
            ),
          ),
        ),
      ),
      home: const AppController(),
    );
  }
}

// ============================================================
// CONTROLEUR PRINCIPAL
// ============================================================

class AppController extends StatefulWidget {
  const AppController({super.key});

  @override
  State<AppController> createState() => _AppControllerState();
}

class _AppControllerState extends State<AppController> {
  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> dossiers = [];

  bool loading = true;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ----------------------------------------------------------
  // STOCKAGE LOCAL
  // ----------------------------------------------------------

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final profileString = prefs.getString('profile');
    final dossiersString = prefs.getString('dossiers');

    Map<String, dynamic>? loadedProfile;

    if (profileString != null) {
      try {
        loadedProfile =
            Map<String, dynamic>.from(jsonDecode(profileString));
      } catch (_) {
        loadedProfile = null;
      }
    }

    List<Map<String, dynamic>> loadedDossiers = [];

    if (dossiersString != null) {
      try {
        final decoded = jsonDecode(dossiersString);

        if (decoded is List) {
          loadedDossiers = decoded
              .map(
                (item) => Map<String, dynamic>.from(item),
              )
              .toList();
        }
      } catch (_) {
        loadedDossiers = [];
      }
    }

    if (!mounted) return;

    setState(() {
      profile = loadedProfile;
      dossiers = loadedDossiers;
      loading = false;
    });
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    if (profile != null) {
      await prefs.setString(
        'profile',
        jsonEncode(profile),
      );
    }

    await prefs.setString(
      'dossiers',
      jsonEncode(dossiers),
    );
  }

  Future<void> deleteAllData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('profile');
    await prefs.remove('dossiers');

    if (!mounted) return;

    setState(() {
      profile = null;
      dossiers = [];
      currentIndex = 0;
    });
  }

  // ----------------------------------------------------------
  // CREATION PROFIL
  // ----------------------------------------------------------

  Future<void> createProfile(
    Map<String, dynamic> newProfile,
  ) async {
    setState(() {
      profile = newProfile;
      dossiers = [];
    });

    await saveData();
  }

  // ----------------------------------------------------------
  // DOSSIER
  // ----------------------------------------------------------

  void addDossier(Map<String, dynamic> dossier) {
    setState(() {
      dossiers.add(dossier);
    });

    saveData();
  }

  void updateDossier(
    Map<String, dynamic> dossier,
  ) {
    final index = dossiers.indexWhere(
      (d) => d['id'] == dossier['id'],
    );

    if (index >= 0) {
      setState(() {
        dossiers[index] = dossier;
      });

      saveData();
    }
  }

  void removeDossier(String id) {
    setState(() {
      dossiers.removeWhere(
        (dossier) => dossier['id'] == id,
      );
    });

    saveData();
  }

  // ----------------------------------------------------------
  // APPLICATION
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SplashScreen();
    }

    if (profile == null) {
      return ProfileCreationScreen(
        onCreate: createProfile,
      );
    }

    final pages = [
      HomeScreen(
        profile: profile!,
        dossiers: dossiers,
        onNavigate: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
      NewDossierScreen(
        profile: profile!,
        onCreated: (dossier) {
          addDossier(dossier);

          setState(() {
            currentIndex = 2;
          });
        },
      ),
      DossiersScreen(
        dossiers: dossiers,
        onUpdate: updateDossier,
        onDelete: removeDossier,
      ),
      AssistantScreen(),
      ProfileScreen(
        profile: profile!,
        onSave: (updatedProfile) async {
          setState(() {
            profile = updatedProfile;
          });

          await saveData();
        },
        onDeleteAll: deleteAllData,
      ),
    ];

    return Scaffold(
      body: SafeArea(
  child: Column(
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(
            top: 8,
            right: 16,
          ),
          child: const InstallButton(),
        ),
      ),
      Expanded(
        child: pages[currentIndex],
      ),
    ],
  ),
),

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Nouvelle',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Dossiers',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'Assistant',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SPLASH
// ============================================================

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// ============================================================
// LOGO
// ============================================================

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({
    super.key,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          size * .3,
        ),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF7C3AED),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB)
                .withOpacity(.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(
        Icons.check,
        color: Colors.white,
        size: size * .52,
      ),
    );
  }
}

// ============================================================
// PROFIL - CREATION
// ============================================================

class ProfileCreationScreen extends StatefulWidget {
  final Future<void> Function(
    Map<String, dynamic>,
  ) onCreate;

  const ProfileCreationScreen({
    super.key,
    required this.onCreate,
  });

  @override
  State<ProfileCreationScreen> createState() =>
      _ProfileCreationScreenState();
}

class _ProfileCreationScreenState
    extends State<ProfileCreationScreen> {
  final prenomController = TextEditingController();
  final nomController = TextEditingController();
  final emailController = TextEditingController();

  int age = 18;

  String nationalite = 'Française';

  String logement =
      'Je suis locataire';

  bool saving = false;

  Future<void> submit() async {
    if (prenomController.text.trim().isEmpty) {
      showMessage(
        context,
        '⚠️ Indiquez votre prénom.',
      );
      return;
    }

    if (emailController.text.trim().isEmpty) {
      showMessage(
        context,
        '⚠️ Indiquez votre adresse email.',
      );
      return;
    }

    setState(() {
      saving = true;
    });

    await widget.onCreate({
      'prenom': prenomController.text.trim(),
      'nom': nomController.text.trim(),
      'email':
          emailController.text.trim().toLowerCase(),
      'age': age,
      'nationalite': nationalite,
      'logement': logement,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),

              const AppLogo(
                size: 90,
              ),

              const SizedBox(height: 20),

              const Text(
                'Checklist à toute épreuve',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF172554),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Votre assistant pour préparer vos démarches administratives.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF475569),
                ),
              ),

              const SizedBox(height: 30),

              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        '👋 Bienvenue !',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Créez votre profil pour commencer.',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        '💾 Vos données sont enregistrées uniquement sur cet appareil.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: emailController,
                keyboardType:
                    TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<int>(
                value: age,
                decoration: const InputDecoration(
                  labelText: 'Âge',
                ),
                items: List.generate(
                  120,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text(
                      '${index + 1} ans',
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      age = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: nationalite,
                decoration: const InputDecoration(
                  labelText: 'Nationalité',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Française',
                    child: Text('Française'),
                  ),
                  DropdownMenuItem(
                    value: 'Européenne',
                    child: Text('Européenne'),
                  ),
                  DropdownMenuItem(
                    value: 'Autre',
                    child: Text('Autre'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      nationalite = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: logement,
                decoration: const InputDecoration(
                  labelText: 'Situation de logement',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Je suis propriétaire',
                    child: Text(
                      'Je suis propriétaire',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Je suis locataire',
                    child: Text(
                      'Je suis locataire',
                    ),
                  ),
                  DropdownMenuItem(
                    value:
                        'Je suis hébergé chez quelqu’un',
                    child: Text(
                      'Je suis hébergé chez quelqu’un',
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      logement = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      saving ? null : submit,
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text(
                    'Créer mon profil',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ACCUEIL
// ============================================================

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> profile;

  final List<Map<String, dynamic>> dossiers;

  final void Function(int) onNavigate;

  const HomeScreen({
    super.key,
    required this.profile,
    required this.dossiers,
    required this.onNavigate,
  });

  int getFinished() {
    return dossiers.where((dossier) {
      final documents =
          List<String>.from(
        dossier['documents'] ?? [],
      );

      final checked =
          List<String>.from(
        dossier['documents_coches'] ?? [],
      );

      return documents.isNotEmpty &&
          documents.every(
            checked.contains,
          );
    }).length;
  }

  int totalDocuments() {
    return dossiers.fold(
      0,
      (sum, dossier) {
        return sum +
            List<String>.from(
              dossier['documents'] ?? [],
            ).length;
      },
    );
  }

  int checkedDocuments() {
    return dossiers.fold(
      0,
      (sum, dossier) {
        return sum +
            List<String>.from(
              dossier['documents_coches'] ?? [],
            ).length;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prenom =
        profile['prenom'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 15),

          const AppLogo(),

          const SizedBox(height: 15),

          const Text(
            'Checklist à toute épreuve',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF172554),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Simple • Clair • Organisé',
            style: TextStyle(
              color: Color(0xFF475569),
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(25),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF4F46E5),
                  Color(0xFF7C3AED),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '👋 Bonjour $prenom !',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Préparons votre prochaine démarche simplement.',
                  style: TextStyle(
                    color: Color(0xFFEEF2FF),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: '📋',
                  title: 'Dossiers',
                  value: '${dossiers.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: '🎉',
                  title: 'Terminés',
                  value: '${getFinished()}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: '✅',
                  title: 'Documents',
                  value:
                      '${checkedDocuments()}/${totalDocuments()}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '✨ Que voulez-vous faire ?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172554),
              ),
            ),
          ),

          const SizedBox(height: 15),

          FeatureCard(
            icon: '📋',
            title: 'Préparer',
            description:
                'Créez une checklist adaptée à votre démarche.',
            buttonText: '📋 Préparer',
            onPressed: () => onNavigate(1),
          ),

          FeatureCard(
            icon: '🤖',
            title: 'Vérifier',
            description:
                'Faites analyser vos documents avec l’assistant IA.',
            buttonText: '🤖 Vérifier',
            onPressed: () => onNavigate(3),
          ),

          FeatureCard(
            icon: '📂',
            title: 'Organiser',
            description:
                'Retrouvez toutes vos démarches dans vos dossiers.',
            buttonText: '📂 Organiser',
            onPressed: () => onNavigate(2),
          ),

          FeatureCard(
            icon: '🧾',
            title: 'Tout préparer',
            description:
                'Suivez votre progression jusqu’à terminer votre checklist.',
            buttonText: '🧾 Mes dossiers',
            onPressed: () => onNavigate(2),
          ),

          if (dossiers.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '📊 Mes derniers dossiers',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...dossiers.reversed
                .take(3)
                .map(
                  (dossier) =>
                      MiniDossierCard(
                    dossier: dossier,
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// CARTES
// ============================================================

class StatCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 23),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onPressed;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              icon,
              style: const TextStyle(
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onPressed,
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniDossierCard extends StatelessWidget {
  final Map<String, dynamic> dossier;

  const MiniDossierCard({
    super.key,
    required this.dossier,
  });

  @override
  Widget build(BuildContext context) {
    final documents =
        List<String>.from(
      dossier['documents'] ?? [],
    );

    final checked =
        List<String>.from(
      dossier['documents_coches'] ?? [],
    );

    final total = documents.length;

    final done = checked.length;

    final progress =
        total == 0 ? 0.0 : done / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              dossier['nom'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius:
                  BorderRadius.circular(10),
            ),
            const SizedBox(height: 6),
            Text(
              '$done/$total documents • ${(progress * 100).round()}%',
              style: const TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// NOUVELLE DEMARCHE
// ============================================================

class NewDossierScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  final void Function(
    Map<String, dynamic>,
  ) onCreated;

  const NewDossierScreen({
    super.key,
    required this.profile,
    required this.onCreated,
  });

  @override
  State<NewDossierScreen> createState() =>
      _NewDossierScreenState();
}

class _NewDossierScreenState
    extends State<NewDossierScreen> {
  String situation = "Carte d'identité";

  final customController =
      TextEditingController();

  final situations = const [
    "Carte d'identité",
    "Passeport",
    "Permis de conduire",
    "Changement d'adresse",
    "Inscription scolaire",
    "Création d'entreprise",
    "Autre",
  ];

  List<String> checklist() {
    if (situation == 'Autre') {
      return [];
    }

    final documents = <String>[
      'Pièce d’identité',
      'Justificatif de domicile récent',
    ];

    if (situation == "Carte d'identité") {
      documents.addAll([
        'Photo d’identité conforme',
        'Ancienne carte d’identité si disponible',
      ]);
    } else if (situation == 'Passeport') {
      documents.addAll([
        'Photo d’identité conforme',
        'Ancien passeport si disponible',
      ]);
    } else if (situation ==
        'Permis de conduire') {
      documents.addAll([
        'Photo-signature numérique',
        'Justificatif d’identité',
        'Avis médical si nécessaire',
      ]);
    } else if (situation ==
        "Changement d'adresse") {
      documents.addAll([
        'Ancienne adresse',
        'Nouvelle adresse',
      ]);
    } else if (situation ==
        'Inscription scolaire') {
      documents.addAll([
        'Livret de famille ou document équivalent',
        'Documents concernant l’enfant',
      ]);
    } else if (situation ==
        "Création d'entreprise") {
      documents.addAll([
        'Adresse de l’entreprise',
        'Informations sur l’activité',
        'Statut juridique choisi',
      ]);
    }

    if (widget.profile['logement'] ==
        "Je suis hébergé chez quelqu’un") {
      documents.addAll([
        'Attestation d’hébergement',
        'Justificatif de domicile de l’hébergeant',
      ]);
    }

    return documents.toSet().toList();
  }

  void create() {
    final documents = checklist();

    if (situation == 'Autre') {
      if (customController.text.trim().isEmpty) {
        showMessage(
          context,
          '⚠️ Décrivez votre démarche.',
        );
        return;
      }

      final dossier = {
        'id': DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        'nom':
            customController.text.trim(),
        'date_creation':
            DateTime.now().toIso8601String(),
        'documents': <String>[
          'Pièce d’identité',
          'Justificatif de domicile récent',
        ],
        'documents_coches': <String>[],
        'analyses': <Map<String, dynamic>>[],
      };

      widget.onCreated(dossier);
      return;
    }

    final dossier = {
      'id': DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      'nom': situation,
      'date_creation':
          DateTime.now().toIso8601String(),
      'documents': documents,
      'documents_coches': <String>[],
      'analyses': <Map<String, dynamic>>[],
    };

    widget.onCreated(dossier);
  }

  @override
  Widget build(BuildContext context) {
    final documents = checklist();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          const Text(
            '➕ Nouvelle démarche',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF172554),
            ),
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            value: situation,
            decoration: const InputDecoration(
              labelText:
                  'Quelle démarche souhaitez-vous préparer ?',
            ),
            items: situations
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  situation = value;
                });
              }
            },
          ),

          const SizedBox(height: 20),

          if (situation == 'Autre')
            TextField(
              controller: customController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText:
                    'Décrivez votre démarche',
                hintText:
                    'Exemple : demander une aide au logement',
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧾 $situation',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Votre checklist contiendra ${documents.length} document(s).',
                    ),
                    const SizedBox(height: 15),
                    ...documents.map(
                      (document) => Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 8,
                        ),
                        child: Text(
                          '☐ $document',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: create,
              icon: const Icon(
                Icons.rocket_launch,
              ),
              label: const Text(
                'Créer mon dossier',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DOSSIERS
// ============================================================

class DossiersScreen extends StatefulWidget {
  final List<Map<String, dynamic>> dossiers;

  final void Function(
    Map<String, dynamic>,
  ) onUpdate;

  final void Function(String) onDelete;

  const DossiersScreen({
    super.key,
    required this.dossiers,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<DossiersScreen> createState() =>
      _DossiersScreenState();
}

class _DossiersScreenState
    extends State<DossiersScreen> {
  String recherche = '';

  @override
  Widget build(BuildContext context) {
    final filtered =
        widget.dossiers.where((dossier) {
      return (dossier['nom'] ?? '')
          .toString()
          .toLowerCase()
          .contains(
            recherche.toLowerCase(),
          );
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            15,
            20,
            10,
          ),
          child: TextField(
            decoration: const InputDecoration(
              labelText:
                  '🔎 Rechercher un dossier',
              prefixIcon:
                  Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                recherche = value;
              });
            },
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    '📭 Aucun dossier trouvé.',
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder:
                      (context, index) {
                    return DossierCard(
                      dossier:
                          filtered[index],
                      onUpdate:
                          widget.onUpdate,
                      onDelete:
                          widget.onDelete,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ============================================================
// DOSSIER CARD
// ============================================================

class DossierCard extends StatefulWidget {
  final Map<String, dynamic> dossier;

  final void Function(
    Map<String, dynamic>,
  ) onUpdate;

  final void Function(String) onDelete;

  const DossierCard({
    super.key,
    required this.dossier,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<DossierCard> createState() =>
      _DossierCardState();
}

class _DossierCardState
    extends State<DossierCard> {
  late Map<String, dynamic> dossier;

  @override
  void initState() {
    super.initState();

    dossier = Map<String, dynamic>.from(
      widget.dossier,
    );
  }

  int get total =>
      List<String>.from(
        dossier['documents'] ?? [],
      ).length;

  int get checked =>
      List<String>.from(
        dossier['documents_coches'] ?? [],
      ).length;

  double get progress =>
      total == 0 ? 0 : checked / total;

  void toggle(String document) {
    final checkedDocuments =
        List<String>.from(
      dossier['documents_coches'] ?? [],
    );

    if (checkedDocuments.contains(document)) {
      checkedDocuments.remove(document);
    } else {
      checkedDocuments.add(document);
    }

    setState(() {
      dossier['documents_coches'] =
          checkedDocuments;
    });

    widget.onUpdate(dossier);
  }

  Future<void> confirmDelete() async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text('Supprimer le dossier ?'),
        content: const Text(
          'Cette action est définitive.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (result == true) {
      widget.onDelete(
        dossier['id'].toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents =
        List<String>.from(
      dossier['documents'] ?? [],
    );

    return Card(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      child: ExpansionTile(
        title: Text(
          dossier['nom'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$checked/$total • ${(progress * 100).round()}%',
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20,
        ),
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius:
                BorderRadius.circular(10),
          ),

          const SizedBox(height: 15),

          ...documents.map(
            (document) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(document),
              value:
                  List<String>.from(
                dossier['documents_coches'] ?? [],
              ).contains(document),
              onChanged: (_) =>
                  toggle(document),
            ),
          ),

          const SizedBox(height: 10),

          DocumentAnalyzer(
            dossier: dossier,
          ),

          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: confirmDelete,
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
            label: const Text(
              'Supprimer ce dossier',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ANALYSE DOCUMENT
// ============================================================

class DocumentAnalyzer extends StatefulWidget {
  final Map<String, dynamic> dossier;

  const DocumentAnalyzer({
    super.key,
    required this.dossier,
  });

  @override
  State<DocumentAnalyzer> createState() =>
      _DocumentAnalyzerState();
}

class _DocumentAnalyzerState
    extends State<DocumentAnalyzer> {
  final ImagePicker picker = ImagePicker();

  XFile? file;

  Future<void> pickImage(
    ImageSource source,
  ) async {
    final selected =
        await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (selected != null) {
      setState(() {
        file = selected;
      });

      if (!mounted) return;

      showMessage(
        context,
        '📄 Document sélectionné.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          '📄 Vérifier un document',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'La connexion à Gemini sera ajoutée dans l’étape suivante.',
          style: TextStyle(
            color: Color(0xFF64748B),
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    pickImage(
                  ImageSource.camera,
                ),
                icon: const Icon(
                  Icons.camera_alt,
                ),
                label: const Text('Photo'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    pickImage(
                  ImageSource.gallery,
                ),
                icon: const Icon(
                  Icons.photo_library,
                ),
                label: const Text('Galerie'),
              ),
            ),
          ],
        ),

        if (file != null) ...[
          const SizedBox(height: 8),
          Text(
            '📎 ${file!.name}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// ASSISTANT
// ============================================================

class AssistantScreen extends StatelessWidget {
  final TextEditingController controller =
      TextEditingController();

  AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          const Text(
            '🤖 Assistant',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF172554),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    '💬 Une question ?',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Posez votre question concernant une démarche administrative.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    maxLines: 6,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Votre question',
                      hintText:
                          'Exemple : quels documents prévoir pour un passeport ?',
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (controller.text
                            .trim()
                            .isEmpty) {
                          showMessage(
                            context,
                            '⚠️ Écrivez une question.',
                          );
                          return;
                        }

                        showMessage(
                          context,
                          '🤖 Gemini sera connecté dans la prochaine étape.',
                        );
                      },
                      icon: const Icon(
                        Icons.smart_toy,
                      ),
                      label: const Text(
                        'Poser ma question',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            '⚠️ Les réponses de l’assistant sont indicatives. Vérifiez toujours les informations auprès de l’administration concernée.',
            style: TextStyle(
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROFIL
// ============================================================

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  final Future<void> Function(
    Map<String, dynamic>,
  ) onSave;

  final Future<void> Function()
      onDeleteAll;

  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onSave,
    required this.onDeleteAll,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  late TextEditingController prenom;
  late TextEditingController nom;
  late TextEditingController email;

  late int age;
  late String nationalite;
  late String logement;

  @override
  void initState() {
    super.initState();

    prenom = TextEditingController(
      text: widget.profile['prenom'] ?? '',
    );

    nom = TextEditingController(
      text: widget.profile['nom'] ?? '',
    );

    email = TextEditingController(
      text: widget.profile['email'] ?? '',
    );

    age =
        (widget.profile['age'] ?? 18) as int;

    nationalite =
        widget.profile['nationalite'] ??
            'Française';

    logement =
        widget.profile['logement'] ??
            'Je suis locataire';
  }

  Future<void> save() async {
    await widget.onSave({
      'prenom': prenom.text.trim(),
      'nom': nom.text.trim(),
      'email':
          email.text.trim().toLowerCase(),
      'age': age,
      'nationalite': nationalite,
      'logement': logement,
    });

    if (!mounted) return;

    showMessage(
      context,
      '✅ Profil enregistré !',
    );
  }

  Future<void> deleteAll() async {
    final confirmation =
        await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Supprimer toutes les données ?',
        ),
        content: const Text(
          'Votre profil et tous vos dossiers seront supprimés de cet appareil.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmation == true) {
      await widget.onDeleteAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            '👤 Mon profil',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF172554),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: prenom,
            decoration: const InputDecoration(
              labelText: 'Prénom',
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: nom,
            decoration: const InputDecoration(
              labelText: 'Nom',
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: email,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<int>(
            value: age,
            decoration: const InputDecoration(
              labelText: 'Âge',
            ),
            items: List.generate(
              120,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text(
                  '${index + 1} ans',
                ),
              ),
            ),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  age = value;
                });
              }
            },
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: nationalite,
            decoration: const InputDecoration(
              labelText: 'Nationalité',
            ),
            items: const [
              DropdownMenuItem(
                value: 'Française',
                child: Text('Française'),
              ),
              DropdownMenuItem(
                value: 'Européenne',
                child: Text('Européenne'),
              ),
              DropdownMenuItem(
                value: 'Autre',
                child: Text('Autre'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  nationalite = value;
                });
              }
            },
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: logement,
            decoration: const InputDecoration(
              labelText:
                  'Situation de logement',
            ),
            items: const [
              DropdownMenuItem(
                value:
                    'Je suis propriétaire',
                child: Text(
                  'Je suis propriétaire',
                ),
              ),
              DropdownMenuItem(
                value:
                    'Je suis locataire',
                child: Text(
                  'Je suis locataire',
                ),
              ),
              DropdownMenuItem(
                value:
                    'Je suis hébergé chez quelqu’un',
                child: Text(
                  'Je suis hébergé chez quelqu’un',
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  logement = value;
                });
              }
            },
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: save,
              icon: const Icon(Icons.save),
              label: const Text(
                'Enregistrer mon profil',
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Divider(),

          const SizedBox(height: 15),

          const Text(
            '🗑️ Zone de suppression',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Les données sont enregistrées localement sur cet appareil.',
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: deleteAll,
              icon: const Icon(
                Icons.delete_forever,
                color: Colors.red,
              ),
              label: const Text(
                'Supprimer toutes mes données',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// UTILITAIRE
// ============================================================

void showMessage(
  BuildContext context,
  String message,
) {
  ScaffoldMessenger.of(context)
      .showSnackBar(
    SnackBar(
      content: Text(message),
    ),
  );
}
