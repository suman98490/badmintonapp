import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:share_plus/share_plus.dart';

class ReportsScreen extends StatefulWidget {
const ReportsScreen({super.key});

@override
State<ReportsScreen> createState() =>
_ReportsScreenState();
}

class _ReportsScreenState
extends State<ReportsScreen>
with SingleTickerProviderStateMixin {
late TabController _tabController;

final DatabaseReference databaseRef =
FirebaseDatabase.instance.ref();

double totalCollected = 0;
double totalSpent = 0;
double remainingAmount = 0;
double pendingCollectionAmount = 0;

int totalPlayers = 0;
int totalTeams = 0;
int totalLeagues = 0;

bool isLoading = true;

List<Map<dynamic, dynamic>> leagueList = [];
List<Map<dynamic, dynamic>> playerList = [];
List<Map<dynamic, dynamic>> teamList = [];

String selectedLeagueFilter =
    'Active';

@override
void initState() {
super.initState();

_tabController = TabController(
length: 4,
vsync: this,
);

loadReports();
}

Future<void> loadReports() async {
setState(() {
isLoading = true;
});

await loadLeagues();
await loadPlayers();
await loadTeams();

calculateFundSummary();

setState(() {
isLoading = false;
});
}

void calculateFundSummary() {
  totalCollected = 0;
  pendingCollectionAmount = 0;

  // =========================
  // TEMPORARY STATIC VALUE
  // UNTIL EXPENSE MODULE ADDED
  // =========================

  totalSpent = 0;

  for (var league in leagueList) {
    double entryFee =
        double.tryParse(
          league['entryFee']
              ?.toString() ??
              '0',
        ) ??
            0;

    bool isPaid =
        league['isPaid'] ?? false;

    if (isPaid) {
      totalCollected += entryFee;
    } else {
      pendingCollectionAmount +=
          entryFee;
    }
  }

  remainingAmount =
      totalCollected - totalSpent;
}

Future<void> loadPlayers() async {
  final snapshot =
  await databaseRef.child('players').get();

  playerList = [];

  if (snapshot.exists &&
      snapshot.value != null) {
    final data =
    snapshot.value
    as Map<dynamic, dynamic>;

    totalPlayers = data.length;

    data.forEach((key, value) {
      Map<dynamic, dynamic> playerData =
      Map<dynamic, dynamic>.from(
        value,
      );

      playerData['firebaseKey'] = key;

      // =========================
      // CALCULATE WINS/LOSSES
      // =========================

      int wins = 0;
      int losses = 0;

      String playerName =
          playerData['name'] ?? '';

      for (var league in leagueList) {
        if (league['winner'] ==
            playerName) {
          wins++;
        }

        if (league['loser'] ==
            playerName) {
          losses++;
        }
      }

      playerData['wins'] = wins;
      playerData['losses'] = losses;

      playerList.add(playerData);
    });
  } else {
    totalPlayers = 0;
  }
}

Future<void> loadTeams() async {
final snapshot =
await databaseRef.child('teams').get();

teamList = [];

if (snapshot.exists &&
snapshot.value != null) {
final data =
snapshot.value
as Map<dynamic, dynamic>;

totalTeams = data.length;

data.forEach((key, value) {
Map<dynamic, dynamic> teamData =
Map<dynamic, dynamic>.from(
value,
);

teamData['firebaseKey'] = key;

int wins = 0;
int losses = 0;

String teamName =
teamData['teamName'] ?? '';

for (var league in leagueList) {
if (league['winner'] ==
teamName) {
wins++;
}

if (league['loser'] ==
teamName) {
losses++;
}
}

teamData['wins'] = wins;
teamData['losses'] = losses;

teamList.add(teamData);
});
}
}

Future<void> loadLeagues() async {
final snapshot =
await databaseRef.child('leagues').get();

leagueList = [];

if (snapshot.exists &&
snapshot.value != null) {
final data =
snapshot.value
as Map<dynamic, dynamic>;

totalLeagues = data.length;

data.forEach((key, value) {
Map<dynamic, dynamic> leagueData =
Map<dynamic, dynamic>.from(
value,
);

leagueData['firebaseKey'] = key;

leagueList.add(leagueData);
});

leagueList.sort((a, b) {
DateTime dateA =
DateTime.tryParse(
a['createdAt'] ?? '',
) ??
DateTime.now();

DateTime dateB =
DateTime.tryParse(
b['createdAt'] ?? '',
) ??
DateTime.now();

return dateB.compareTo(dateA);
});
}
}

Future<void> updateLeagueResult({
required String firebaseKey,
required String winner,
required String loser,
required bool isPaid,
}) async {
await databaseRef
    .child('leagues')
    .child(firebaseKey)
    .update({
'winner': winner,
'loser': loser,
'isPaid': isPaid,
'status':
isPaid
? 'Closed'
    : 'Active',
});

loadReports();
}

void showMessage(String message) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(
    SnackBar(
      content: Text(message),
    ),
  );
}

Future<void> openPhonePePayment({
  required String amount,
  required String teamName,
}) async {

  // =========================
  // YOUR UPI ID
  // =========================

  String upiId =
      'yourupiid@oksbi';

  String receiverName =
      'Badminton Fund';

  String note =
      'League Payment - $teamName';

  final Uri uri = Uri.parse(
    'upi://pay?pa=$upiId&pn=$receiverName&am=$amount&cu=INR&tn=$note',
  );

  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode:
      LaunchMode.externalApplication,
    );
  } else {
    showMessage(
      'PhonePe/UPI app not found',
    );
  }
}

void openPaymentDetailsScreen({
  required String title,
  required bool isPaid,
}) {

  List<Map<dynamic, dynamic>>
  filteredLeagues =
  leagueList.where((league) {

    bool paid =
        league['isPaid'] ?? false;

    String loser =
        league['loser'] ?? '';

    return paid == isPaid &&
        loser.isNotEmpty;
  }).toList();

  Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (context) =>
          PaymentDetailsScreen(
            title: title,

            leagueList:
            filteredLeagues,

            isPaid: isPaid,
          ),
    ),
  );
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Reports'),

centerTitle: true,

bottom: TabBar(
controller: _tabController,

tabs: const [
Tab(text: 'Fund'),
Tab(text: 'League'),
Tab(text: 'Teams'),
Tab(text: 'Players'),
],
),
),

body:
isLoading
? const Center(
child:
CircularProgressIndicator(),
)
    : TabBarView(
controller: _tabController,
children: [
buildFundReport(),
buildLeagueReport(),
buildTeamReport(),
buildPlayerReport(),
],
),
);
}

Widget buildFundReport() {
  return ListView(
    padding: const EdgeInsets.all(16),

    children: [
      // =========================
      // COLLECTED AMOUNT
      // =========================

      GestureDetector(
        onTap: () {
          openPaymentDetailsScreen(
            title:
            'Collected Amount Details',
            isPaid: true,
          );
        },

        child: buildReportCard(
          title: 'Collected Amount',

          amount:
          '₹ ${totalCollected.toStringAsFixed(0)}',

          icon: Icons.savings,

          color: Colors.green,
        ),
      ),

      const SizedBox(height: 10),

      // =========================
      // PENDING COLLECTION
      // =========================

      GestureDetector(
        onTap: () {
          openPaymentDetailsScreen(
            title:
            'Pending Collection Details',
            isPaid: false,
          );
        },

        child: buildReportCard(
          title: 'Pending Collection',

          amount:
          '₹ ${pendingCollectionAmount.toStringAsFixed(0)}',

          icon:
          Icons.pending_actions,

          color: Colors.orange,
        ),
      ),

      const SizedBox(height: 10),

      // =========================
      // TOTAL SPENT
      // =========================

      buildReportCard(
        title: 'Total Spent',

        amount:
        '₹ ${totalSpent.toStringAsFixed(0)}',

        icon: Icons.money_off,

        color: Colors.red,
      ),

      const SizedBox(height: 10),

      // =========================
      // AVAILABLE BALANCE
      // =========================

      buildReportCard(
        title: 'Available Balance',

        amount:
        '₹ ${remainingAmount.toStringAsFixed(0)}',

        icon:
        Icons.account_balance_wallet,

        color: Colors.blue,
      ),
    ],
  );
}


Widget buildLeagueReport() {

  // =========================
  // FILTER LEAGUES
  // =========================

  List<Map<dynamic, dynamic>>
  filteredLeagues =
  leagueList.where((league) {

    String status =
        league['status'] ??
            'Active';

    return status ==
        selectedLeagueFilter;
  }).toList();

  return ListView(
    padding: const EdgeInsets.all(16),

    children: [

      // =========================
      // FILTER DROPDOWN
      // =========================

      Row(
        children: [

          // =========================
          // ACTIVE CHIP
          // =========================

          ChoiceChip(
            label: const Text(
              'Active',
            ),

            selected:
            selectedLeagueFilter ==
                'Active',

            selectedColor:
            Colors.green.shade200,

            onSelected: (selected) {

              setState(() {

                selectedLeagueFilter =
                'Active';
              });
            },
          ),

          const SizedBox(width: 12),

          // =========================
          // CLOSED CHIP
          // =========================

          ChoiceChip(
            label: const Text(
              'Closed',
            ),

            selected:
            selectedLeagueFilter ==
                'Closed',

            selectedColor:
            Colors.red.shade200,

            onSelected: (selected) {

              setState(() {

                selectedLeagueFilter =
                'Closed';
              });
            },
          ),
        ],
      ),

      const SizedBox(height: 20),

      // =========================
      // LEAGUES
      // =========================

      ...filteredLeagues.map((league) {

        String matchType =
            league['matchType'] ??
                'Doubles';

        List<dynamic> teams =
        matchType == 'Singles'
            ? (league['players'] ?? [])
            : (league['teams'] ?? []);

        List<String> uniqueTeams =
        teams
            .map((e) => e.toString())
            .toSet()
            .toList();

        bool isPaid =
            league['isPaid'] ?? false;

        bool isClosed =
            league['status'] ==
                'Closed';

        String selectedWinner =
            league['winner'] ?? '';

        String selectedLoser =
            league['loser'] ?? '';

        return Card(
          elevation: 6,

          shadowColor:
          Colors.black26,

          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              20,
            ),
          ),

          child: Padding(
            padding:
            const EdgeInsets.all(
              16,
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [

                // =========================
                // TOP SECTION
                // =========================

                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [

                    // =========================
                    // BADMINTON ICON
                    // =========================

                    Padding(
                      padding:
                      const EdgeInsets.only(
                        top: 12,
                      ),

                      child: Icon(
                        Icons
                            .sports_tennis,

                        size: 30,

                        color:
                        Colors.black54,
                      ),
                    ),

                    const SizedBox(
                      width: 16,
                    ),

                    // =========================
                    // LEAGUE DETAILS
                    // =========================

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [

                          // =========================
                          // LEAGUE NAME
                          // =========================

                          Text(
                            league['leagueName'] ??
                                '',

                            style:
                            const TextStyle(
                              fontSize:
                              17,

                              fontWeight:
                              FontWeight
                                  .normal,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          // =========================
                          // LEAGUE DATE
                          // =========================

                          Text(
                            'League Date: ${league['leagueDate'] ?? ''}',

                            style:
                            const TextStyle(
                              fontSize:
                              17,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          // =========================
                          // ENTRY FEE
                          // =========================

                          Text(
                            'Entry Fee: ₹${league['entryFee'] ?? 0}',

                            style:
                            const TextStyle(
                              fontSize:
                              17,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          // =========================
                          // STATUS
                          // =========================

                          Text(
                            'Status: ${league['status'] ?? 'Active'}',

                            style: TextStyle(
                              fontSize:
                              17,

                              fontWeight:
                              FontWeight
                                  .bold,

                              color:
                              isClosed
                                  ? Colors
                                  .red
                                  : Colors
                                  .green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 15,
                ),

                // =========================
                // WINNER DROPDOWN
                // =========================

                DropdownButtonFormField<
                    String
                >(
                  value:
                  selectedWinner
                      .isEmpty
                      ? null
                      : selectedWinner,

                  items:
                  uniqueTeams.map((
                      team,
                      ) {
                    return DropdownMenuItem<
                        String
                    >(
                      value: team,

                      child: Text(
                        team,
                      ),
                    );
                  }).toList(),

                  onChanged:
                  isClosed
                      ? null
                      : (value) {
                    selectedWinner =
                        value ?? '';
                  },

                  decoration:
                  InputDecoration(
                    labelText:
                    matchType ==
                        'Singles'
                        ? 'Winner Player'
                        : 'Winner Team',

                    border:
                    const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                // =========================
                // LOSER DROPDOWN
                // =========================

                DropdownButtonFormField<
                    String
                >(
                  value:
                  selectedLoser
                      .isEmpty
                      ? null
                      : selectedLoser,

                  items:
                  uniqueTeams.map((
                      team,
                      ) {
                    return DropdownMenuItem<
                        String
                    >(
                      value: team,

                      child: Text(
                        team,
                      ),
                    );
                  }).toList(),

                  onChanged:
                  isClosed
                      ? null
                      : (value) {
                    selectedLoser =
                        value ?? '';
                  },

                  decoration:
                  InputDecoration(
                    labelText:
                    matchType ==
                        'Singles'
                        ? 'Loser Player'
                        : 'Loser Team',

                    border:
                    const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                // =========================
                // PAYMENT CHECKBOX
                // =========================

                Row(
                  children: [

                    Checkbox(
                      value: isPaid,

                      onChanged:
                      isClosed
                          ? null
                          : (value) async {

                        await updateLeagueResult(
                          firebaseKey:
                          league['firebaseKey'],

                          winner:
                          selectedWinner,

                          loser:
                          selectedLoser,

                          isPaid:
                          value ?? false,
                        );
                      },
                    ),

                    Text(
                      isClosed
                          ? 'Payment Received (Locked)'
                          : 'Payment Received',

                      style:
                      const TextStyle(
                        fontSize:
                        16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                // =========================
                // UPDATE BUTTON
                // =========================

                SizedBox(
                  width:
                  double.infinity,

                  height: 40,

                  child: ElevatedButton(
                    onPressed:
                    isClosed
                        ? null
                        : () async {

                      await updateLeagueResult(
                        firebaseKey:
                        league['firebaseKey'],

                        winner:
                        selectedWinner,

                        loser:
                        selectedLoser,

                        isPaid:
                        isPaid,
                      );
                    },

                    child: Text(
                      isClosed
                          ? 'League Closed'
                          : 'Update Result',

                      style:
                      const TextStyle(
                        fontSize:
                        16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ],
  );
}

Widget buildTeamReport() {
  return ListView(
    padding: const EdgeInsets.all(16),

    children: [
      // =========================
      // TOTAL TEAMS CARD
      // =========================

      buildInfoTile(
        title: 'Total Teams',

        value: totalTeams.toString(),

        icon: Icons.groups,

        color: Colors.blue,
      ),

      const SizedBox(height: 20),

      // =========================
      // EMPTY STATE
      // =========================

      if (teamList.isEmpty)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(20),

            child: Text(
              'No teams available',
            ),
          ),
        ),

      // =========================
      // TEAM LIST
      // =========================

      ...teamList.map((team) {
        TextEditingController
        teamController =
        TextEditingController(
          text:
          team['teamName'] ?? '',
        );

        return Card(
          elevation: 5,

          margin:
          const EdgeInsets.only(
            bottom: 16,
          ),

          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
          ),

          child: Padding(
            padding:
            const EdgeInsets.all(
              16,
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [
                // =========================
                // TEAM HEADER
                // =========================

                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,

                      backgroundColor:
                      Colors.blue
                          .shade100,

                      child: const Icon(
                        Icons.groups,

                        size: 28,

                        color:
                        Colors.blue,
                      ),
                    ),

                    const SizedBox(
                      width: 16,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [
                          Text(
                            team['teamName'] ??
                                '',

                            style:
                            const TextStyle(
                              fontSize:
                              18,

                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Text(
                            'Wins: ${team['wins'] ?? 0}',

                            style:
                            const TextStyle(
                              fontSize:
                              15,
                            ),
                          ),

                          Text(
                            'Losses: ${team['losses'] ?? 0}',

                            style:
                            const TextStyle(
                              fontSize:
                              15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                // =========================
                // PLAYERS SECTION
                // =========================

                const Text(
                  'Players',

                  style: TextStyle(
                    fontSize: 16,

                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,

                  children:
                  (team['players'] ??
                      [])
                      .map<Widget>((
                      player,
                      ) {
                    return Chip(
                      label: Text(
                        player.toString(),
                      ),
                    );
                  })
                      .toList(),
                ),

                const SizedBox(
                  height: 20,
                ),

                // =========================
                // UPDATE TEAM NAME
                // =========================

                TextField(
                  controller:
                  teamController,

                  decoration:
                  const InputDecoration(
                    labelText:
                    'Update Team Name',

                    border:
                    OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                // =========================
                // UPDATE BUTTON
                // =========================

                SizedBox(
                  width:
                  double.infinity,

                  height: 50,

                  child: ElevatedButton(
                    onPressed:
                        () async {
                      await databaseRef
                          .child(
                        'teams',
                      )
                          .child(
                        team['firebaseKey'],
                      )
                          .update({
                        'teamName':
                        teamController
                            .text,
                      });

                      showMessage(
                        'Team updated successfully',
                      );

                      loadReports();
                    },

                    child: const Text(
                      'Update Team',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ],
  );
}

Widget buildPlayerReport() {
  return ListView(
    padding: const EdgeInsets.all(16),

    children: [
      // =========================
      // TOTAL PLAYERS CARD
      // =========================

      buildInfoTile(
        title: 'Total Players',

        value: totalPlayers.toString(),

        icon: Icons.groups,

        color: Colors.blue,
      ),

      const SizedBox(height: 20),

      // =========================
      // EMPTY STATE
      // =========================

      if (playerList.isEmpty)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(20),

            child: Text(
              'No Players available',
            ),
          ),
        ),

      // =========================
      // PLAYER LIST
      // =========================

      ...playerList.map((player) {
        TextEditingController
        playerController =
        TextEditingController(
          text:
          player['name'] ?? '',
        );

        return Card(
          elevation: 5,

          margin:
          const EdgeInsets.only(
            bottom: 16,
          ),

          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
          ),

          child: Padding(
            padding:
            const EdgeInsets.all(
              16,
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [
                // =========================
                  // PLAYER
                // =========================

                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,

                      backgroundColor:
                      Colors.blue
                          .shade100,

                      child: const Icon(
                        Icons.groups,

                        size: 28,

                        color:
                        Colors.blue,
                      ),
                    ),

                    const SizedBox(
                      width: 16,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [
                          Text(
                            player['name'] ??
                                '',

                            style:
                            const TextStyle(
                              fontSize:
                              18,

                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Text(
                            'Wins: ${player['wins'] ?? 0}',

                            style:
                            const TextStyle(
                              fontSize:
                              15,
                            ),
                          ),

                          Text(
                            'Losses: ${player['losses'] ?? 0}',

                            style:
                            const TextStyle(
                              fontSize:
                              15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),


                // =========================
                // UPDATE TEAM NAME
                // =========================

                TextField(
                  controller:
                  playerController,

                  decoration:
                  const InputDecoration(
                    labelText:
                    'Update Player Name',

                    border:
                    OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                // =========================
                // UPDATE BUTTON
                // =========================

                SizedBox(
                  width:
                  double.infinity,

                  height: 50,

                  child: ElevatedButton(
                    onPressed:
                        () async {
                      await databaseRef
                          .child(
                        'players',
                      )
                          .child(
                        player['firebaseKey'],
                      )
                          .update({
                        'name':
                        playerController
                            .text,
                      });

                      showMessage(
                        'Player Details updated successfully',
                      );

                      loadReports();
                    },

                    child: const Text(
                      'Update Player',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ],
  );
}

Widget buildInfoTile({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
}) {
  return Card(
    elevation: 4,

    shape: RoundedRectangleBorder(
      borderRadius:
      BorderRadius.circular(16),
    ),

    child: ListTile(
      leading: CircleAvatar(
        backgroundColor:
        color.withOpacity(0.2),

        child: Icon(
          icon,
          color: color,
        ),
      ),

      title: Text(
        title,

        style: const TextStyle(
          fontSize: 16,
          fontWeight:
          FontWeight.w500,
        ),
      ),

      trailing: Text(
        value,

        style: const TextStyle(
          fontSize: 20,
          fontWeight:
          FontWeight.bold,
        ),
      ),
    ),
  );
}


Widget buildReportCard({
  required String title,
  required String amount,
  required IconData icon,
  required Color color,
}) {
  return Card(
    elevation: 8,

    shadowColor: Colors.black26,

    shape: RoundedRectangleBorder(
      borderRadius:
      BorderRadius.circular(20),
    ),

    child: Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.center,

        children: [
          // =========================
          // ICON SECTION
          // =========================

          Container(
            height: 80,
            width: 80,

            decoration: BoxDecoration(
              color: color.withOpacity(0.15),

              shape: BoxShape.circle,
            ),

            child: Icon(
              icon,
              color: color,
              size: 35,
            ),
          ),

          const SizedBox(width: 24),

          // =========================
          // TEXT SECTION
          // =========================

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              mainAxisAlignment:
              MainAxisAlignment.center,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  amount,

                  style: const TextStyle(
                    fontSize: 17,
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
  );
}
}

class PaymentDetailsScreen
    extends StatefulWidget {

  final String title;

  final bool isPaid;

  final List<Map<dynamic, dynamic>>
  leagueList;

  const PaymentDetailsScreen({
    super.key,

    required this.title,

    required this.leagueList,

    required this.isPaid,
  });

  @override
  State<PaymentDetailsScreen>
  createState() =>
      _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState
    extends State<PaymentDetailsScreen> {

  String selectedView =
      'League';

  @override
  Widget build(BuildContext context) {

    // =========================
    // PLAYER WISE DATA
    // =========================

    Map<String, double>
    playerWiseAmount = {};

    for (var league
    in widget.leagueList) {

      String loser =
          league['loser'] ?? '';

      double amount =
          double.tryParse(
            league['entryFee']
                ?.toString() ??
                '0',
          ) ??
              0;

      if (playerWiseAmount
          .containsKey(loser)) {

        playerWiseAmount[loser] =
            playerWiseAmount[
            loser]! +
                amount;

      } else {

        playerWiseAmount[
        loser] = amount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title:
        Text(widget.title),
      ),

      body: Padding(
        padding:
        const EdgeInsets.all(
          12,
        ),

        child: Column(
          children: [

            // =========================
            // FILTER CHIPS
            // =========================

            Row(
              children: [

                ChoiceChip(
                  label: const Text(
                    'League Wise',
                  ),

                  selected:
                  selectedView ==
                      'League',

                  selectedColor:
                  Colors.blue
                      .shade200,

                  onSelected: (
                      value,
                      ) {

                    setState(() {

                      selectedView =
                      'League';
                    });
                  },
                ),

                const SizedBox(
                  width: 12,
                ),

                ChoiceChip(
                  label: const Text(
                    'Player Wise',
                  ),

                  selected:
                  selectedView ==
                      'Player',

                  selectedColor:
                  Colors.green
                      .shade200,

                  onSelected: (
                      value,
                      ) {

                    setState(() {

                      selectedView =
                      'Player';
                    });
                  },
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            // =========================
            // LEAGUE WISE
            // =========================

            if (selectedView ==
                'League')

              Expanded(
                child:
                ListView.builder(
                  itemCount:
                  widget
                      .leagueList
                      .length,

                  itemBuilder: (
                      context,
                      index,
                      ) {

                    final league =
                    widget
                        .leagueList[index];

                    bool isPaid =
                        league['isPaid'] ??
                            false;

                    return Card(
                      elevation:
                      4,

                      margin:
                      const EdgeInsets.only(
                        bottom:
                        12,
                      ),

                      child:
                      ListTile(

                        leading:
                        CircleAvatar(
                          backgroundColor:
                          isPaid
                              ? Colors.green
                              : Colors.orange,

                          child:
                          Icon(
                            isPaid
                                ? Icons.check
                                : Icons.pending,

                            color:
                            Colors.white,
                          ),
                        ),

                        title:
                        Text(
                          league['loser'] ??
                              '',
                        ),

                        subtitle:
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            Text(
                              'League : ${league['leagueName'] ?? ''}',
                            ),

                            Text(
                              'Date : ${league['leagueDate'] ?? ''}',
                            ),

                            Text(
                              'Winner : ${league['winner'] ?? ''}',
                            ),

                            Text(
                              'Status : ${isPaid ? "Paid" : "Pending"}',
                            ),
                          ],
                        ),

                        trailing:
                        Text(
                          '₹ ${league['entryFee'] ?? 0}',

                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,

                            fontSize:
                            16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // =========================
            // PLAYER WISE
            // =========================

            if (selectedView ==
                'Player')

              Expanded(
                child:
                ListView(
                  children:
                  playerWiseAmount.entries.map((
                      entry,
                      ) {

                    return Card(
                      elevation:
                      4,

                      margin:
                      const EdgeInsets.only(
                        bottom:
                        12,
                      ),

                      child:
                      ListTile(

                        leading:
                        CircleAvatar(
                          backgroundColor:
                          widget.isPaid
                              ? Colors.green
                              : Colors.orange,

                          child:
                          Icon(
                            widget.isPaid
                                ? Icons.check
                                : Icons.pending,

                            color:
                            Colors.white,
                          ),
                        ),

                        title:
                        Text(
                          entry.key,
                        ),

                        subtitle:
                        Text(
                          widget.isPaid
                              ? 'Collected Amount'
                              : 'Pending Amount',
                        ),

                        trailing:
                        Text(
                          '₹ ${entry.value.toStringAsFixed(0)}',

                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,

                            fontSize:
                            18,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
