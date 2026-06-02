import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  final DatabaseReference databaseRef =
  FirebaseDatabase.instance.ref();

  double amountCollected = 0;
  double amountSpent = 0;
  double amountRemaining = 0;
  double pendingCollection = 0;

  int totalLeagues = 0;
  int totalPlayers = 0;
  int totalTeams = 0;

  bool isLoading = true;
  List<String> tossPlayers = [];

  String tossResult = '';

  @override
  void initState() {
    super.initState();

    loadDashboardData();
  }

  // =========================
  // LOAD DASHBOARD DATA
  // =========================

  Future<void> loadDashboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([
        loadPlayersCount(),
        loadTeamsCount(),
        loadLeaguesData(),
        loadExpenseData(),
      ]);
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  // =========================
  // LOAD PLAYERS COUNT
  // =========================

  Future<void> loadPlayersCount() async {
    final snapshot =
    await databaseRef.child("players").get();

    if (snapshot.exists &&
        snapshot.value != null) {
      final data =
      snapshot.value
      as Map<dynamic, dynamic>;

      totalPlayers = data.length;
    } else {
      totalPlayers = 0;
    }
  }

  // =========================
  // LOAD TEAMS COUNT
  // =========================

  Future<void> loadTeamsCount() async {
    final snapshot =
    await databaseRef.child("teams").get();

    if (snapshot.exists &&
        snapshot.value != null) {
      final data =
      snapshot.value
      as Map<dynamic, dynamic>;

      totalTeams = data.length;
    } else {
      totalTeams = 0;
    }
  }

  // =========================
  // LOAD LEAGUES & FUND DATA
  // =========================

  Future<void> loadLeaguesData() async {
    final snapshot =
    await databaseRef.child("leagues").get();

    amountCollected = 0;
    amountSpent = 0;
    amountRemaining = 0;
    pendingCollection = 0;

    if (snapshot.exists &&
        snapshot.value != null) {
      final data =
      snapshot.value
      as Map<dynamic, dynamic>;

      totalLeagues = data.length;

      data.forEach((key, value) {
        Map<dynamic, dynamic> league =
        Map<dynamic, dynamic>.from(
          value,
        );

        double entryFee =
            double.tryParse(
              league["entryFee"]
                  ?.toString() ??
                  "0",
            ) ??
                0;

        bool isPaid =
            league["isPaid"] ?? false;

        if (isPaid) {
          amountCollected += entryFee;
        } else {
          pendingCollection +=
              entryFee;
        }
      });

      amountRemaining =
          amountCollected - amountSpent;
    } else {
      totalLeagues = 0;
    }
  }

  // =========================
// LOAD EXPENSE DATA
// =========================

  Future<void> loadExpenseData() async {

    final snapshot =
    await databaseRef
        .child("expenses")
        .get();

    amountSpent = 0;

    if (snapshot.exists &&
        snapshot.value != null) {

      final data =
      snapshot.value
      as Map<dynamic, dynamic>;

      data.forEach((key, value) {

        Map<dynamic, dynamic> expense =
        Map<dynamic, dynamic>.from(
          value,
        );

        double amount =
            double.tryParse(
              expense["expenseAmount"]
                  ?.toString() ??
                  "0",
            ) ??
                0;

        amountSpent += amount;
      });
    }

    amountRemaining =
        amountCollected -
            amountSpent;
  }

  void playSmashToss() async {

    // =========================
    // FETCH PLAYERS FROM FIREBASE
    // =========================

    DataSnapshot snapshot =
    await FirebaseDatabase.instance
        .ref()
        .child('players')
        .get();

    List<String> allPlayers = [];

    if (snapshot.exists) {

      Map<dynamic, dynamic> data =
      snapshot.value
      as Map<dynamic, dynamic>;

      data.forEach((key, value) {

        allPlayers.add(
          value['name']
              .toString(),
        );
      });
    }

    // =========================
    // SELECTED PLAYERS
    // =========================

    List<String> selectedPlayers =
    [];

    // =========================
    // PLAYER SELECTION DIALOG
    // =========================
    bool showResult = false;

    bool startAnimation = false;
    showDialog(
      context: context,

      builder: (context) {

        return StatefulBuilder(
          builder: (
              context,
              setState,
              ) {

            return AlertDialog(

              title: const Text(
                '🏸 Select Players',
              ),

              content: SizedBox(
                width: double.maxFinite,

                height: 350,

                child: Column(
                  children: [

                    Expanded(
                      child:
                      ListView.builder(
                        itemCount:
                        allPlayers
                            .length,

                        itemBuilder: (
                            context,
                            index,
                            ) {

                          String player =
                          allPlayers[
                          index];

                          bool isSelected =
                          selectedPlayers
                              .contains(
                            player,
                          );

                          return CheckboxListTile(
                            value:
                            isSelected,

                            title: Text(
                              player,
                            ),

                            onChanged: (
                                value,
                                ) {

                              setState(() {

                                if (value ==
                                    true) {

                                  selectedPlayers
                                      .add(
                                    player,
                                  );

                                } else {

                                  selectedPlayers
                                      .remove(
                                    player,
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      'Selected Players : ${selectedPlayers.length}',
                    ),
                  ],
                ),
              ),

              actions: [

                TextButton(
                  onPressed: () {

                    Navigator.pop(
                      context,
                    );
                  },

                  child: const Text(
                    'Cancel',
                  ),
                ),

                ElevatedButton(
                  onPressed:
                  selectedPlayers
                      .length <
                      2
                      ? null
                      : () {

                    Navigator.pop(
                      context,
                    );

                    startTossAnimation(

                      selectedPlayers,
                    );
                  },

                  child: const Text(
                    'Start Toss',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

// ======================================================
// START TOSS ANIMATION
// ======================================================

  void startTossAnimation(
      List<String> players,
      ) {

    players.shuffle();

    String court1 = '';
    String court2 = '';
    String waiting = '';

    // =========================
    // MATCH LOGIC
    // =========================

    // =========================
// COURT ASSIGNMENT
// =========================

    if (players.length == 2) {

      court1 =
      '${players[0]} (Court 1) vs ${players[1]} (Court 2)';
    }

    else if (players.length == 3) {

      court1 =
      '${players[0]} (Court 1) vs ${players[1]} (Court 2)';

      waiting =
      players[2];
    }

    else if (players.length >= 4) {

      court1 =
      '${players[0]} (Court 1) vs ${players[1]} (Court 2)';

      court2 =
      '${players[2]} (Court 1) vs ${players[3]} (Court 2)';

      if (players.length > 4) {

        waiting =
            players
                .sublist(4)
                .join(', ');
      }
    }

    bool showResult = false;
    bool startAnimation = false;

    showDialog(
      context: context,

      barrierDismissible: true,

      builder: (dialogContext) {

        // =========================
        // START TIMER
        // =========================

        Future.delayed(
          const Duration(
            seconds: 2,
          ),
              () {

            if (dialogContext.mounted) {

              (dialogContext as Element)
                  .markNeedsBuild();

              showResult = true;
            }
          },
        );

        return StatefulBuilder(
          builder: (
              context,
              setState,
              ) {

            if (!startAnimation) {

              startAnimation = true;

              Future.delayed(
                const Duration(
                  milliseconds: 100,
                ),
                    () {

                  if (context.mounted) {

                    setState(() {

                      showResult = false;
                    });
                  }
                },
              );

              Future.delayed(
                const Duration(
                  milliseconds: 1800,
                ),
                    () {

                  if (context.mounted) {

                    setState(() {

                      showResult = true;
                    });
                  }
                },
              );
            }

            return Dialog(

              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  24,
                ),
              ),

              child: Container(

                padding:
                const EdgeInsets.all(
                  20,
                ),

                height: 520,

                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,

                  children: [

                    // =========================
                    // ANIMATION
                    // =========================





                    // =========================
                    // LOADING TEXT
                    // =========================

                    if (!showResult)

                      const Text(
                        '🏸 Tossing Players...',

                        style: TextStyle(
                          fontSize: 22,

                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                    // =========================
                    // RESULT SECTION
                    // =========================

                    if (showResult)

                      Expanded(
                        child: Container(

                          width: double.infinity,

                          margin:
                          const EdgeInsets.only(
                            top: 10,
                          ),

                          decoration:
                          BoxDecoration(

                            borderRadius:
                            BorderRadius.circular(
                              24,
                            ),

                            gradient:
                            LinearGradient(
                              begin:
                              Alignment.topCenter,

                              end:
                              Alignment.bottomCenter,

                              colors: [

                                Colors.green
                                    .shade800,

                                Colors.green
                                    .shade600,
                              ],
                            ),
                          ),

                          child: Stack(
                            children: [

                              // =========================
                              // OUTER COURT BORDER
                              // =========================

                              Positioned.fill(
                                child: Padding(
                                  padding:
                                  const EdgeInsets.all(
                                    12,
                                  ),

                                  child: Container(
                                    decoration:
                                    BoxDecoration(
                                      border: Border.all(
                                        color:
                                        Colors.white,

                                        width: 4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // =========================
                              // CENTER NET
                              // =========================

                              Center(
                                child: Container(

                                  width:
                                  double.infinity,

                                  height: 5,

                                  color:
                                  Colors.white,
                                ),
                              ),

                              // =========================
                              // TOP COURT
                              // =========================

                              Positioned(
                                top: 50,

                                left: 20,

                                right: 20,

                                child: Column(
                                  children: [

                                    const Text(
                                      '🏸 COURT 1',

                                      style: TextStyle(
                                        color:
                                        Colors.white,

                                        fontSize: 24,

                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 30,
                                    ),

                                    Container(
                                      width:
                                      double.infinity,

                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 20,
                                      ),

                                      child: Text(
                                        court1
                                            .split(' vs ')[0]
                                            .replaceAll(
                                          '(Court 1)',
                                          '',
                                        )
                                            .trim(),

                                        textAlign:
                                        TextAlign.center,

                                        style:
                                        const TextStyle(
                                          color:
                                          Colors.white,

                                          fontSize:
                                          20,

                                          fontWeight:
                                          FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // =========================
                              // BOTTOM COURT
                              // =========================

                              if (court1.contains(' vs '))

                                Positioned(
                                  bottom: 40,

                                  left: 20,

                                  right: 20,

                                  child: Column(
                                    children: [

                                      const SizedBox(
                                        height: 30,
                                      ),

                                      Container(
                                        width:
                                        double.infinity,

                                        padding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 20,
                                        ),


                                        child: Column(
                                          children: [
                                            // =========================
                                            // PLAYER NAME
                                            // =========================

                                            Container(
                                              width:
                                              double.infinity,

                                              padding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 22,
                                              ),



                                              child: Text(
                                                court1
                                                    .split(' vs ')[1]
                                                    .replaceAll(
                                                  '(Court 2)',
                                                  '',
                                                )
                                                    .trim(),

                                                textAlign:
                                                TextAlign.center,

                                                style:
                                                const TextStyle(
                                                  color:
                                                  Colors.white,

                                                  fontSize:
                                                  20,

                                                  fontWeight:
                                                  FontWeight.normal,
                                                ),
                                              ),
                                            ),

                                            const SizedBox(
                                              height: 35,
                                            ),

                                            // =========================
                                            // COURT 2 TITLE
                                            // =========================

                                            const Text(
                                              '🏸 COURT 2',

                                              style: TextStyle(
                                                color:
                                                Colors.white,

                                                fontSize: 24,

                                                fontWeight:
                                                FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// ======================================================
// COURT CARD
// ======================================================

  Widget buildCourtCard(
      String court,
      String players,
      ) {

    return Container(

      width: double.infinity,

      padding:
      const EdgeInsets.all(
        16,
      ),

      decoration: BoxDecoration(
        color:
        Colors.green.shade50,

        borderRadius:
        BorderRadius.circular(
          18,
        ),
      ),

      child: Column(
        children: [

          Text(
            court,

            style:
            const TextStyle(
              fontSize: 20,

              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            players,

            textAlign:
            TextAlign.center,

            style:
            const TextStyle(
              fontSize: 20,

              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
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
          "Badminton Fund Tracker",
        ),

        centerTitle: true,
      ),

      body:
      isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh:
        loadDashboardData,

        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),

          padding:
          const EdgeInsets.all(
            16,
          ),

          child: Column(
            children: [
              GridView.count(
                shrinkWrap: true,

                physics:
                const NeverScrollableScrollPhysics(),

                crossAxisCount: 2,

                crossAxisSpacing: 12,

                mainAxisSpacing: 12,

                childAspectRatio: 1.1,

                children: [
                  DashboardCard(
                    title:
                    "Collected Amount",

                    value:
                    "₹ ${amountCollected.toStringAsFixed(0)}",

                    icon:
                    Icons.savings,

                    color:
                    Colors.green,
                  ),

                  DashboardCard(
                    title:
                    "Pending Collection",

                    value:
                    "₹ ${pendingCollection.toStringAsFixed(0)}",

                    icon: Icons
                        .pending_actions,

                    color:
                    Colors.orange,
                  ),

                  DashboardCard(
                    title:
                    "Amount Spent",

                    value:
                    "₹ ${amountSpent.toStringAsFixed(0)}",

                    icon:
                    Icons.money_off,

                    color:
                    Colors.red,
                  ),

                  DashboardCard(
                    title:
                    "Available Balance",

                    value:
                    "₹ ${amountRemaining.toStringAsFixed(0)}",

                    icon: Icons
                        .account_balance_wallet,

                    color:
                    Colors.blue,
                  ),

                  DashboardCard(
                    title:
                    "Total Leagues",

                    value:
                    totalLeagues
                        .toString(),

                    icon:
                    Icons.emoji_events,

                    color:
                    Colors.orange,
                  ),

                  DashboardCard(
                    title:
                    "Total Players",

                    value:
                    totalPlayers
                        .toString(),

                    icon:
                    Icons.people,

                    color:
                    Colors.purple,
                  ),

                  DashboardCard(
                    title:
                    "Total Teams",

                    value:
                    totalTeams
                        .toString(),

                    icon:
                    Icons.groups,

                    color:
                    Colors.teal,
                  ),
                  GestureDetector(
                    onTap: playSmashToss,

                    child: DashboardCard(
                      title:
                      "Smash Toss",

                      value:
                      "Tap to Decide",

                      icon:
                      Icons.sports_tennis,

                      color:
                      Colors.deepOrange,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {

                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder:
                              (context) =>
                          const AddExpenseScreen(),
                        ),
                      ).then((value) {

                        loadDashboardData();
                      });
                    },

                    child: DashboardCard(
                      title:
                      "Add Expense",

                      value:
                      "Add New",

                      icon:
                      Icons.receipt_long,

                      color:
                      Colors.brown,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {

                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder:
                              (context) =>
                          const ExpenseReportScreen(),
                        ),
                      );
                    },

                    child: DashboardCard(
                      title:
                      "Expense Reports",

                      value:
                      "View List",

                      icon:
                      Icons.list_alt,

                      color:
                      Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================
// DASHBOARD CARD
// =========================

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,

      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(16),
      ),

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            CircleAvatar(
              radius: 22,

              backgroundColor:
              color.withOpacity(0.2),

              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              value,

              textAlign: TextAlign.center,

              maxLines: 1,

              overflow:
              TextOverflow.ellipsis,

              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              title,

              textAlign: TextAlign.center,

              maxLines: 2,

              overflow:
              TextOverflow.ellipsis,

              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// ADD EXPENSE SCREEN
// =========================

class AddExpenseScreen
    extends StatefulWidget {

  const AddExpenseScreen({
    super.key,
  });

  @override
  State<AddExpenseScreen>
  createState() =>
      _AddExpenseScreenState();
}

class _AddExpenseScreenState
    extends State<AddExpenseScreen> {

  final TextEditingController
  descriptionController =
  TextEditingController();

  final TextEditingController
  amountController =
  TextEditingController();

  DateTime selectedDate =
  DateTime.now();

  bool isSaving = false;

  Future<void> pickDate() async {

    DateTime? pickedDate =
    await showDatePicker(
      context: context,

      initialDate:
      selectedDate,

      firstDate:
      DateTime(2020),

      lastDate:
      DateTime(2100),
    );

    if (pickedDate != null) {

      setState(() {

        selectedDate =
            pickedDate;
      });
    }
  }

  Future<void> addExpense() async {

    String description =
    descriptionController.text
        .trim();

    String amount =
    amountController.text
        .trim();

    if (description.isEmpty ||
        amount.isEmpty) {

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(

        const SnackBar(
          content: Text(
            'Please fill all fields',
          ),
        ),
      );

      return;
    }

    setState(() {

      isSaving = true;
    });

    try {

      DatabaseReference ref =
      FirebaseDatabase.instance
          .ref()
          .child("expenses")
          .push();

      await ref.set({

        "expenseDescription":
        description,

        "expenseAmount":
        amount,

        "expenseDate":
        "${selectedDate.day.toString().padLeft(2, '0')}-"
            "${selectedDate.month.toString().padLeft(2, '0')}-"
            "${selectedDate.year}",
      });

      if (context.mounted) {

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(

          const SnackBar(
            content: Text(
              'Expense added successfully',
            ),
          ),
        );

        Navigator.pop(
          context,
        );
      }

    } catch (e) {

      debugPrint(
        e.toString(),
      );
    }

    setState(() {

      isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title:
        const Text(
          'Add Expense',
        ),
      ),

      body: SingleChildScrollView(

        padding:
        const EdgeInsets.all(
          16,
        ),

        child: Column(
          children: [

            TextField(
              controller:
              descriptionController,

              decoration:
              const InputDecoration(
                labelText:
                'Expense Description',

                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            TextField(
              controller:
              amountController,

              keyboardType:
              TextInputType.number,

              decoration:
              const InputDecoration(
                labelText:
                'Expense Amount',

                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            InkWell(
              onTap: pickDate,

              child: Container(

                width:
                double.infinity,

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),

                decoration:
                BoxDecoration(
                  border: Border.all(
                    color:
                    Colors.grey,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    4,
                  ),
                ),

                child: Text(
                  'Expense Date : '
                      '${selectedDate.day.toString().padLeft(2, '0')}-'
                      '${selectedDate.month.toString().padLeft(2, '0')}-'
                      '${selectedDate.year}',
                ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            SizedBox(
              width:
              double.infinity,

              height: 50,

              child: ElevatedButton(
                onPressed:
                isSaving
                    ? null
                    : addExpense,

                child:
                isSaving
                    ? const CircularProgressIndicator(
                  color:
                  Colors.white,
                )
                    : const Text(
                  'Add Expense',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// =========================
// EXPENSE REPORT SCREEN
// =========================

class ExpenseReportScreen
    extends StatefulWidget {

  const ExpenseReportScreen({
    super.key,
  });

  @override
  State<ExpenseReportScreen>
  createState() =>
      _ExpenseReportScreenState();
}

class _ExpenseReportScreenState
    extends State<ExpenseReportScreen> {

  List<Map<dynamic, dynamic>>
  expenseList = [];

  bool isLoading = true;

  double totalExpense = 0;

  @override
  void initState() {

    super.initState();

    loadExpenses();
  }

  // =========================
  // LOAD EXPENSES
  // =========================

  Future<void> loadExpenses() async {

    final snapshot =
    await FirebaseDatabase
        .instance
        .ref()
        .child("expenses")
        .get();

    expenseList.clear();

    totalExpense = 0;

    if (snapshot.exists &&
        snapshot.value != null) {

      Map<dynamic, dynamic> data =
      snapshot.value
      as Map<dynamic, dynamic>;

      data.forEach((key, value) {

        Map<dynamic, dynamic>
        expense =
        Map<dynamic, dynamic>.from(
          value,
        );

        expenseList.add({
          "firebaseKey": key,
          ...expense,
        });

        double amount =
            double.tryParse(
              expense["expenseAmount"]
                  ?.toString() ??
                  "0",
            ) ??
                0;

        totalExpense += amount;
      });

      // =========================
      // LATEST FIRST
      // =========================

      expenseList =
          expenseList.reversed
              .toList();
    }

    setState(() {

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title:
        const Text(
          'Expense Reports',
        ),
      ),

      body:
      isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : Column(
        children: [

          // =========================
          // TOTAL EXPENSE CARD
          // =========================

          Container(

            width:
            double.infinity,

            margin:
            const EdgeInsets.all(
              16,
            ),

            padding:
            const EdgeInsets.all(
              20,
            ),

            decoration:
            BoxDecoration(
              color:
              Colors.red
                  .shade100,

              borderRadius:
              BorderRadius.circular(
                20,
              ),
            ),

            child: Column(
              children: [

                const Text(
                  'Total Expenses',

                  style:
                  TextStyle(
                    fontSize:
                    18,

                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Text(
                  '₹ ${totalExpense.toStringAsFixed(0)}',

                  style:
                  const TextStyle(
                    fontSize:
                    30,

                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // =========================
          // EXPENSE LIST
          // =========================

          Expanded(
            child:
            expenseList.isEmpty
                ? const Center(
              child: Text(
                'No Expenses Added',
              ),
            )
                : ListView.builder(
              itemCount:
              expenseList
                  .length,

              itemBuilder: (
                  context,
                  index,
                  ) {

                final expense =
                expenseList[
                index];

                return Card(

                  margin:
                  const EdgeInsets.symmetric(
                    horizontal:
                    16,

                    vertical:
                    8,
                  ),

                  elevation:
                  4,

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      18,
                    ),
                  ),

                  child:
                  ListTile(

                    leading:
                    CircleAvatar(
                      backgroundColor:
                      Colors.red
                          .shade100,

                      child:
                      const Icon(
                        Icons.receipt_long,

                        color:
                        Colors.red,
                      ),
                    ),

                    title:
                    Text(
                      expense['expenseDescription'] ??
                          '',
                    ),

                    subtitle:
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        const SizedBox(
                          height:
                          6,
                        ),

                        Text(
                          'Date : ${expense['expenseDate'] ?? ''}',
                        ),
                      ],
                    ),

                    trailing:
                    Text(
                      '₹ ${expense['expenseAmount'] ?? 0}',

                      style:
                      const TextStyle(
                        fontSize:
                        18,

                        fontWeight:
                        FontWeight.bold,

                        color:
                        Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}