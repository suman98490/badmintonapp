import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddInfoScreen extends StatefulWidget {
  const AddInfoScreen({super.key});

  @override
  State<AddInfoScreen> createState() =>
      _AddInfoScreenState();
}

class _AddInfoScreenState
    extends State<AddInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final DatabaseReference databaseRef =
  FirebaseDatabase.instance.ref();

  // =========================
  // CONTROLLERS
  // =========================

  final TextEditingController
  playerNameController =
  TextEditingController();

  final TextEditingController
  teamNameController =
  TextEditingController();

  final TextEditingController
  leagueNameController =
  TextEditingController();

  final TextEditingController
  entryFeeController =
  TextEditingController();

  final TextEditingController
  leagueDateController =
  TextEditingController();

  // =========================
  // DATA LISTS
  // =========================

  List<String> playerList = [];

  List<String> selectedPlayers = [];

  List<String> teamList = [];

  List<String> selectedTeams = [];

  // =========================
  // MATCH TYPE
  // =========================

  bool isSingles = false;

  bool isDoubles = true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
    );

    loadPlayers();

    loadTeams();
  }

  // =========================
  // DATE PICKER
  // =========================

  Future<void> selectLeagueDate() async {
    DateTime? pickedDate =
    await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        leagueDateController.text =
        "${pickedDate.day.toString().padLeft(2, '0')}-"
            "${pickedDate.month.toString().padLeft(2, '0')}-"
            "${pickedDate.year}";
      });
    }
  }

  // =========================
  // LOAD PLAYERS
  // =========================

  Future<void> loadPlayers() async {
    final snapshot =
    await databaseRef.child("players").get();

    playerList = [];

    if (snapshot.exists &&
        snapshot.value != null) {
      final data =
      snapshot.value
      as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        playerList.add(
          value["name"].toString(),
        );
      });
    }

    setState(() {});
  }

  // =========================
  // LOAD TEAMS
  // =========================

  Future<void> loadTeams() async {
    final snapshot =
    await databaseRef.child("teams").get();

    teamList = [];

    if (snapshot.exists &&
        snapshot.value != null) {
      final data =
      snapshot.value
      as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        teamList.add(
          value["teamName"].toString(),
        );
      });
    }

    setState(() {});
  }

  // =========================
  // ADD PLAYER
  // =========================

  Future<void> addPlayer() async {
    if (playerNameController.text
        .trim()
        .isEmpty) {
      showMessage("Enter player name");
      return;
    }

    await databaseRef.child("players").push().set({
      "name":
      playerNameController.text.trim(),
      "wins": 0,
      "losses": 0,
      "pendingAmount": 0,
    });

    playerNameController.clear();

    showMessage("Player added");

    loadPlayers();
  }

  // =========================
  // ADD TEAM
  // =========================

  Future<void> addTeam() async {
    if (teamNameController.text
        .trim()
        .isEmpty ||
        selectedPlayers.isEmpty) {
      showMessage(
        "Enter team details",
      );

      return;
    }

    await databaseRef.child("teams").push().set({
      "teamName":
      teamNameController.text.trim(),
      "players": selectedPlayers,
    });

    teamNameController.clear();

    selectedPlayers.clear();

    showMessage("Team added");

    loadTeams();

    setState(() {});
  }

  // =========================
  // CREATE LEAGUE
  // =========================

  Future<void> createLeague() async {
    bool isSinglesMatch = isSingles;

    if (leagueNameController.text
        .trim()
        .isEmpty ||
        entryFeeController.text
            .trim()
            .isEmpty ||
        leagueDateController.text
            .trim()
            .isEmpty) {
      showMessage(
        "Please enter all details",
      );

      return;
    }

    // =========================
    // VALIDATIONS
    // =========================

    if (isSinglesMatch &&
        selectedPlayers.length < 2) {
      showMessage(
        "Select minimum 2 players",
      );

      return;
    }

    if (!isSinglesMatch &&
        selectedTeams.length < 2) {
      showMessage(
        "Select minimum 2 teams",
      );

      return;
    }

    // =========================
    // SAVE LEAGUE
    // =========================

    await databaseRef.child("leagues").push().set({
      "leagueName":
      leagueNameController.text.trim(),

      "entryFee":
      double.tryParse(
        entryFeeController.text,
      ) ??
          0,

      "leagueDate":
      leagueDateController.text.trim(),

      "matchType":
      isSinglesMatch
          ? "Singles"
          : "Doubles",

      "players":
      isSinglesMatch
          ? selectedPlayers
          : [],

      "teams":
      isSinglesMatch
          ? []
          : selectedTeams,

      "winner": "",

      "loser": "",

      "isPaid": false,

      "status": "Active",

      "createdAt":
      DateTime.now()
          .toIso8601String(),
    });

    leagueNameController.clear();

    entryFeeController.clear();

    leagueDateController.clear();

    selectedPlayers.clear();

    selectedTeams.clear();

    showMessage(
      "League created successfully",
    );

    setState(() {});
  }

  // =========================
  // SNACKBAR
  // =========================

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Information",
        ),

        centerTitle: true,

        bottom: TabBar(
          controller: _tabController,

          tabs: const [
            Tab(text: "Player"),
            Tab(text: "Team"),
            Tab(text: "League"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,

        children: [
          buildPlayerTab(),
          buildTeamTab(),
          buildLeagueTab(),
        ],
      ),
    );
  }

  // =========================
  // PLAYER TAB
  // =========================

  Widget buildPlayerTab() {
    return Padding(
      padding: const EdgeInsets.all(16),

      child: Column(
        children: [
          TextField(
            controller:
            playerNameController,

            decoration:
            const InputDecoration(
              labelText:
              "Player Name",

              border:
              OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,

            child: ElevatedButton(
              onPressed: addPlayer,

              child: const Text(
                "Add Player",
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // TEAM TAB
  // =========================

  Widget buildTeamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),

      child: Column(
        children: [
          TextField(
            controller:
            teamNameController,

            decoration:
            const InputDecoration(
              labelText: "Team Name",

              border:
              OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          const Align(
            alignment:
            Alignment.centerLeft,

            child: Text(
              "Select Players",

              style: TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          ...playerList.map((player) {
            return CheckboxListTile(
              value: selectedPlayers
                  .contains(player),

              title: Text(player),

              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    selectedPlayers.add(
                      player,
                    );
                  } else {
                    selectedPlayers
                        .remove(player);
                  }
                });
              },
            );
          }),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,

            child: ElevatedButton(
              onPressed: addTeam,

              child: const Text(
                "Add Team",
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // LEAGUE TAB
  // =========================

  Widget buildLeagueTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),

      child: Column(
        children: [
          TextField(
            controller:
            leagueNameController,

            decoration:
            const InputDecoration(
              labelText:
              "League Name",

              border:
              OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller:
            entryFeeController,

            keyboardType:
            TextInputType.number,

            decoration:
            const InputDecoration(
              labelText: "Entry Fee",

              border:
              OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          // =========================
          // LEAGUE DATE PICKER
          // =========================

          TextField(
            controller:
            leagueDateController,

            readOnly: true,

            onTap: selectLeagueDate,

            decoration:
            const InputDecoration(
              labelText:
              "League Date",

              border:
              OutlineInputBorder(),

              suffixIcon: Icon(
                Icons.calendar_month,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // =========================
          // MATCH TYPE
          // =========================

          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title:
                  const Text("Singles"),

                  value: isSingles,

                  onChanged: (value) {
                    setState(() {
                      isSingles =
                          value ?? false;

                      if (isSingles) {
                        isDoubles = false;

                        selectedTeams.clear();
                      }
                    });
                  },
                ),
              ),

              Expanded(
                child: CheckboxListTile(
                  title:
                  const Text("Doubles"),

                  value: isDoubles,

                  onChanged: (value) {
                    setState(() {
                      isDoubles =
                          value ?? false;

                      if (isDoubles) {
                        isSingles = false;

                        selectedPlayers.clear();
                      }
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Align(
            alignment:
            Alignment.centerLeft,

            child: Text(
              isSingles
                  ? "Select Players"
                  : "Select Teams",

              style: const TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // =========================
          // SINGLES
          // =========================

          if (isSingles)
            ...playerList.map((player) {
              return CheckboxListTile(
                value:
                selectedPlayers
                    .contains(player),

                title: Text(player),

                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedPlayers.add(
                        player,
                      );
                    } else {
                      selectedPlayers
                          .remove(player);
                    }
                  });
                },
              );
            }),

          // =========================
          // DOUBLES
          // =========================

          if (isDoubles)
            ...teamList.map((team) {
              return CheckboxListTile(
                value:
                selectedTeams
                    .contains(team),

                title: Text(team),

                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedTeams.add(
                        team,
                      );
                    } else {
                      selectedTeams
                          .remove(team);
                    }
                  });
                },
              );
            }),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,

            child: ElevatedButton(
              onPressed: createLeague,

              child: const Text(
                "Create League",
              ),
            ),
          ),
        ],
      ),
    );
  }
}