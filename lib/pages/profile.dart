import 'dart:async';
import 'package:animations/animations.dart';
import 'package:cord2_mobile_app/models/event_model.dart';
import 'package:cord2_mobile_app/pages/sign_on.dart';
import 'package:cord2_mobile_app/classes/user_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> {
  List<EventModel>? _userReports = []; // All retrieved reports
  late List<EventModel>? _filteredReports = []; // displayed reports
  Color primary = const Color(0xff5f79BA);
  Color secondary = const Color(0xffD0DCF4);
  Color highlight = const Color(0xff20297A);
  late double _reportSectionPadding;
  // Pagination
  bool _isLoadingMore = false;
  bool _noMoreReports = false;
  bool _sortByRecent = true;
  String? _lastUsedDocID;
  final int _reportLimit = 15;
  // Search utility vars
  final TextEditingController _searchTextField = TextEditingController();
  int? _previousReportsLength;
  int _numOfNewlyAddedReports = 0;
  bool _isFiltering = false;
  bool _loadMore = false;

  // List of sort options for report section
  static const List<String> _dropdownItems = [
    "Most Recent",
    "Oldest First",
  ];
  String? _dropdownValue = _dropdownItems.first;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Change style based on device orientation
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      _reportSectionPadding = 0;
    } else {
      _reportSectionPadding = 48;
    }

    return Material(
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: RefreshIndicator(
            triggerMode: RefreshIndicatorTriggerMode.anywhere,
            onRefresh: () => refreshPage(context),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(top: 50)),
                  Text(
                    "Profile",
                    style: TextStyle(color: primary, fontSize: 28),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 20)),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.elliptical(40, 40),
                          topRight: Radius.elliptical(40, 40)),
                      color: secondary,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.person_crop_circle,
                          size: 90,
                          color: primary,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            "Report Statuses",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: _reportSectionPadding),
                          child: displayReportList(),
                        ),
                        displayUserData(),
                        displayResetPasswordButton(),
                        displayChangeEmailButton(context),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: ElevatedButton(
                            onPressed: () => signOutUser(),
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        highlight)),
                            child: Container(
                              alignment: Alignment.center,
                              width: 200,
                              child: const Text(
                                "Logout",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> refreshPage(BuildContext context) async {
    _noMoreReports = false;
    _lastUsedDocID = null;
    _isLoadingMore = false;
    setState(() {
      _searchTextField.text = "";
    });
    await _loadReports();
    setState(() {
      /* Refresh list of user's reports */
    });
    // Ensure user authentication status is valid
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      // Allow user to login and reauthenticate
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-token-expired") {
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Session Expired. Reauthentication needed."),
              backgroundColor: Colors.amber));
        });
        signOutUser();
      }
    }
    return;
  }

  // Loads the current user's reports the first time
  Future<void> _loadReports() async {
    setState(() {
      _isLoadingMore = true;
    });
    _userReports = await UserData.getUserReportsWithLimit(
        _reportLimit, _lastUsedDocID, _sortByRecent);
    setState(() {
      _isLoadingMore = false;
      if (_userReports != null && _userReports!.isNotEmpty) {
        _lastUsedDocID = _userReports?.last.id;
      }
      if (_userReports != null && _userReports!.length < _reportLimit) {
        _noMoreReports = true;
      }
      _filteredReports = _userReports;
    });
  }

  // Loads more of the current user's reports
  // and filters it if there is a search
  Future<void> _loadMoreReports() async {
    // All reports have been loaded
    if (_noMoreReports) {
      _loadMore = false;
      return;
      // Only load more when not already loading more
    } else if (_isLoadingMore) {
      return;
    }

    // Bottom of list reached, so load more reports
    if (!_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });

      List<EventModel>? newReports = await UserData.getUserReportsWithLimit(
          _reportLimit, _lastUsedDocID, _sortByRecent);

      setState(() {
        // Add new reports to the report list
        if (newReports != null && newReports.isNotEmpty) {
          _userReports?.addAll(newReports);
          _lastUsedDocID = newReports.last.id;
          // No more reports left
        } else if (newReports != null && newReports.length < _reportLimit) {
          _noMoreReports = true;
        }
        _isLoadingMore = false;
      });
      await filterLazyLoadedReports(_searchTextField.text);
    }
  }

  // Displays all of the necessary personal data to the user
  Widget displayUserData() {
    TextStyle dataNameStyle =
        TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: primary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            displayUserID(dataNameStyle),
            const SizedBox(height: 15),
            displayUserEmail(dataNameStyle),
            const SizedBox(height: 20),
          ],
        )
      ],
    );
  }

  Padding displayChangeEmailButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OpenContainer(
        closedElevation: 0,
        closedColor: Colors.transparent,
        closedBuilder: (context, action) => ElevatedButton(
          onPressed: null,
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(primary)),
          child: Container(
            alignment: Alignment.center,
            width: 150,
            child: const Text(
              "Change Email",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        openBuilder: (context, action) {
          return updateUserEmailForm();
        },
      ),
    );
  }

  // Returns a button to allow the current user to reset their password.
  // Also, displays a popup with the status of the sent email.
  Padding displayResetPasswordButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: () => showDialog(
            context: context,
            useSafeArea: true,
            builder: (context) {
              return FutureBuilder(
                future: resetUserPassword(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                    case ConnectionState.none:
                      return const AlertDialog(
                        elevation: 10,
                        content: SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );

                    case ConnectionState.active:
                    case ConnectionState.done:
                      return AlertDialog(
                        title: Text(
                          "Password Reset",
                          style: TextStyle(color: highlight),
                        ),
                        elevation: 10,
                        content: SizedBox(
                          width: 50,
                          child: Text(
                            snapshot.data,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Ok"))
                        ],
                      );
                  }
                },
              );
            }),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(primary),
        ),
        child: Container(
          alignment: Alignment.center,
          width: 150,
          child: const Text(
            "Change Password",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget displayReportList() {
    return SizedBox(
      height: 456,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          dividerTheme: const DividerThemeData(
            color: Colors.transparent,
            space: 0,
            thickness: 0,
            indent: 0,
            endIndent: 0,
          ),
          cardTheme: CardTheme(
            color: primary,
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          hintText: "Search reports",
                        ),
                        controller: _searchTextField,
                        onChanged: (value) async {
                          bool searchAllReports = false;
                          // Checks if a character was not appended or prepended
                          // meaning that we need to search all reports and not
                          // only the current filtered list.
                          if (_searchTextField.selection.start != 1 &&
                              _searchTextField.selection.start !=
                                  (value.length)) {
                            searchAllReports = true;
                          }
                          filterLoadedReports(value, searchAllReports);
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    dropdownSortButton()
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Container(
                  constraints:
                      const BoxConstraints(maxHeight: 364, minHeight: 0),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      ScrollMetrics scrollMetrics = notification.metrics;
                      // Load more reports when user is near the end of the list
                      if (scrollMetrics.maxScrollExtent - scrollMetrics.pixels <
                          30) {
                        if (!_isFiltering &&
                            !_noMoreReports &&
                            !_isLoadingMore) {
                          _loadMoreReports();
                        }
                      }
                      return true;
                    },
                    // Build reports to display
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredReports?.length,
                        itemBuilder: (context, index) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: showFullReport(index)),
                                  displayReportDeleteButton(index)
                                ],
                              ),
                              // Show loading indicator at the end of the list
                              // when more reports are being loaded
                              _isLoadingMore &&
                                      index + 1 == _filteredReports?.length
                                  ? const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ))
                                  : Container(height: 0),
                            ],
                          );
                        }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Filter the loaded reports on the first run of the search.
  // Loads more reports if not enough were shown.
  void filterLoadedReports(String? searchText, bool searchAllReports) {
    if (searchText == null || searchText.isEmpty || _userReports == null) {
      setState(() {
        _filteredReports = _userReports;
      });
      _previousReportsLength = null;
      return;
    }

    List<EventModel>? curFilteredReports = _filteredReports;
    String search = searchText.toLowerCase();
    List<EventModel>? newReports = [];

    // Filter based on all reports
    if (searchAllReports) {
      // Filter based on title, type, and description
      _userReports?.forEach((report) {
        if (report.title.toLowerCase().contains(search) ||
            report.type.toLowerCase().contains(search) ||
            report.description.toLowerCase().contains(search)) {
          newReports.add(report);
          _numOfNewlyAddedReports++;
        }
      });
      // Filter based on the cached last search
    } else {
      // Filter based on title, type, and description
      curFilteredReports?.forEach((report) {
        if (report.title.toLowerCase().contains(search) ||
            report.type.toLowerCase().contains(search) ||
            report.description.toLowerCase().contains(search)) {
          newReports.add(report);
          _numOfNewlyAddedReports++;
          // update the filtered list after we process a decent number of reports
          if (newReports.length % _reportLimit == 0) {
            setState(() {
              _filteredReports = newReports;
            });
          }
        }
      });
    }

    setState(() {
      // enough reports loaded
      if (_numOfNewlyAddedReports >= _reportLimit) {
        _loadMore = false;
        _numOfNewlyAddedReports = 0;
        // continue trying to load more reports
      } else {
        _loadMore = true;
      }
      // update search filter data
      _filteredReports = newReports;
      _previousReportsLength = _userReports?.length;
    });

    // Ensure there is enough reports being displayed on first search
    if (_loadMore) {
      _loadMoreReports();
    }
  }

  // Filter and add new lazily loaded reports to the current filtered list
  Future<void> filterLazyLoadedReports(String? search) async {
    if (search == null ||
        search.isEmpty ||
        _filteredReports == null ||
        _filteredReports!.isEmpty ||
        _previousReportsLength == null ||
        _isLoadingMore ||
        _isFiltering) return;

    setState(() {
      _isFiltering = true;
    });
    List<EventModel>? newReports = [];
    // Filter newly added reports based on title, type, and description
    _userReports!.skip(_previousReportsLength as int).forEach((report) {
      if (report.title.toLowerCase().contains(search) ||
          report.type.toLowerCase().contains(search) ||
          report.description.toLowerCase().contains(search)) {
        newReports.add(report);
        _numOfNewlyAddedReports++;
      }
    });

    // update filtered reports with new reports
    setState(() {
      _filteredReports!.addAll(newReports);
    });

    _previousReportsLength = _userReports!.length;
    setState(() {
      _isFiltering = false;
      // check if we loaded enough reports that match search
      if (_numOfNewlyAddedReports >= _reportLimit) {
        _loadMore = false;
        _numOfNewlyAddedReports = 0;
      } else {
        _loadMore = true;
      }
    });

    // Ensure enough reports are loaded
    if (_loadMore) {
      _loadMoreReports();
    }
  }

  // Returns a drop down button to sort reports
  DropdownButton<String> dropdownSortButton() {
    return DropdownButton<String>(
      dropdownColor: highlight,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1,
      ),
      iconEnabledColor: secondary,
      value: _dropdownValue,
      items: _dropdownItems.map<DropdownMenuItem<String>>((String sortName) {
        // print(sortName);
        return DropdownMenuItem<String>(
          value: sortName,
          child: Text(sortName),
        );
      }).toList(),
      onChanged: (String? value) async {
        // Same option was chosen, so don't load new reports
        if (value == _dropdownValue) return;

        // Initialize for a new list of reports
        // Update sort method
        setState(() {
          _dropdownValue = value;
          _lastUsedDocID = null;
          _noMoreReports = false;
        });
        // Sort by most recent
        if (value == _dropdownItems[0]) {
          _sortByRecent = true;
          // Sort by oldest first
        } else if (value == _dropdownItems[1]) {
          _sortByRecent = false;
        }

        await _loadReports();
      },
    );
  }

  // Returns a delete button that will delete a report from
  Widget displayReportDeleteButton(int index,
      {Color buttonColor = Colors.white}) {
    return SizedBox(
      height: 30,
      child: IconButton(
        padding: const EdgeInsets.all(0),
        onPressed: () async => {
          await showDialog(
            context: context,
            useSafeArea: true,
            builder: (context) {
              return AlertDialog(
                actionsAlignment: MainAxisAlignment.center,
                title: Text(
                  "Delete Report",
                  style: TextStyle(
                    color: highlight,
                  ),
                ),
                elevation: 10,
                content: const SizedBox(
                  width: 50,
                  child: Text(
                    "This report will be permanently deleted. Would you like to continue?",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                actions: [
                  ElevatedButton(
                      style: ButtonStyle(
                        fixedSize: MaterialStateProperty.resolveWith(
                            (states) => const Size.fromWidth(125)),
                        backgroundColor: MaterialStateColor.resolveWith(
                            (states) => highlight),
                      ),
                      // Delete the specified report
                      onPressed: () async {
                        Navigator.pop(context);
                        // Delete report from database and
                        // remove from userReports list
                        await deleteReport([_filteredReports![index].id]);
                        // Delete report locally
                        setState(() {
                          _filteredReports!.removeAt(index);
                        });
                      },
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      )),
                  const SizedBox(
                    width: 50,
                  ),
                  ElevatedButton(
                      style: ButtonStyle(
                        fixedSize: MaterialStateProperty.resolveWith(
                            (states) => const Size.fromWidth(125)),
                        backgroundColor: MaterialStateColor.resolveWith(
                            (states) => Colors.grey.shade600),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Back",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      )),
                ],
              );
            },
          ),
        },
        icon: Icon(
          CupertinoIcons.trash,
          color: buttonColor,
        ),
      ),
    );
  }

  // Deletes the current user's reports with the specified IDs
  Future<void> deleteReport(List<String> reportIDs) async {
    bool deletedSuccessfully = await UserData.deleteUserReports(reportIDs);

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      if (!deletedSuccessfully) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("An error occured deleting the report."),
            backgroundColor: Colors.red));
      } else {
        _userReports?.removeWhere(
            (userReport) => reportIDs.any((report) => report == userReport.id));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Successfully deleted"),
            backgroundColor: Colors.green));
      }
    });
  }

  Widget createReportInfoDisplay({required Widget info}) {
    return Material(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: info,
      ),
    );
  }

  // Displays the report in more detail on another route
  Widget showFullReport(int index) {
    TextStyle dataTitleStyle = TextStyle(
        color: Colors.grey.shade800, fontSize: 22, fontWeight: FontWeight.bold);
    TextStyle infoStyle = const TextStyle(color: Colors.black, fontSize: 16);
    SizedBox itemPadding = const SizedBox(
      height: 16,
    );
    SizedBox infoPadding = const SizedBox(
      height: 8,
    );

    return OpenContainer(
      closedShape:
          RoundedRectangleBorder(borderRadius: calculateRowBorderRadius(index)),
      closedElevation: 8.0,
      transitionType: ContainerTransitionType.fadeThrough,
      closedColor: Colors.white,
      openElevation: 9.0,
      closedBuilder: (context, action) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: calculateRowBorderRadius(index),
        ),
        child: SizedBox(
          height: 52,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  _filteredReports![index].title,
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                ),
              ),
            ),
          ),
        ),
      ),
      openBuilder: (context, action) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateColor.resolveWith(
                        (states) => Colors.transparent),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(
                    CupertinoIcons.back,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _filteredReports![index].title,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            wordSpacing: 2,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          "Type",
                          style: dataTitleStyle,
                        ),
                        infoPadding,
                        createReportInfoDisplay(
                          info: Text(
                            _filteredReports![index].type,
                            style: infoStyle,
                          ),
                        ),
                        itemPadding,
                        Text(
                          "Description",
                          style: dataTitleStyle,
                        ),
                        infoPadding,
                        createReportInfoDisplay(
                          info: Text(
                            _filteredReports![index].description,
                            style: infoStyle,
                          ),
                        ),
                        itemPadding,
                        Text(
                          "Date Created",
                          style: dataTitleStyle,
                        ),
                        infoPadding,
                        createReportInfoDisplay(
                          info: Text(
                            "${DateFormat.yMMMd().add_jmz().format(_filteredReports![index].time.toDate())} ${_filteredReports![index].time.toDate().timeZoneName}",
                            style: infoStyle,
                          ),
                        ),
                        itemPadding,
                        Text(
                          "Active",
                          style: dataTitleStyle,
                        ),
                        infoPadding,
                        createReportInfoDisplay(
                          info: setStatus(_filteredReports![index].active),
                        ),
                        itemPadding,
                        _filteredReports![index].images.isEmpty
                            ? Container()
                            : Text(
                                "Images",
                                style: dataTitleStyle,
                              ),
                        infoPadding,
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredReports![index].images.length,
                          itemBuilder: (context, imageIndex) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: createReportInfoDisplay(
                                info: Image.network(
                                  _filteredReports![index].images[imageIndex],
                                  width: 250,
                                  height: 250,
                                  semanticLabel:
                                      _filteredReports![index].description,
                                ),
                              ),
                            );
                          },
                        )
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
  }

  TextStyle reportItem = const TextStyle(fontSize: 16);

  Widget setStatus(bool status) {
    Icon statusIcon;
    Color color = Colors.black;

    if (status) {
      statusIcon = Icon(
        CupertinoIcons.check_mark,
        color: color,
      );
    } else {
      statusIcon = Icon(
        CupertinoIcons.xmark,
        color: color,
      );
    }

    return statusIcon;
  }

  // Returns a border radius for a specified index row
  BorderRadiusGeometry calculateRowBorderRadius(int index) {
    BorderRadiusGeometry? borderRadius;
    //if (events == null) return null;

    // There is only a single row on a page, so create a full border radius
    if (_filteredReports!.length == 1) {
      borderRadius = const BorderRadius.all(Radius.circular(10));
    }
    // Starting row has a top border radius
    else if (index == 0) {
      borderRadius = const BorderRadius.only(
          topLeft: Radius.circular(10), topRight: Radius.circular(10));
    }
    // Last row has a bottom border radius
    else if (index == _filteredReports!.length - 1) {
      borderRadius = const BorderRadius.only(
          bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10));
    }
    // Middle rows have no border radius
    else {
      borderRadius = const BorderRadius.all(Radius.zero);
    }

    return borderRadius;
  }

  // Displays the user's username
  Widget displayUserID(TextStyle dataNameStyle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "ID",
        style: dataNameStyle,
      ),
      const SizedBox(height: 8),
      //const Padding(padding: EdgeInsets.only(right: 10)),
      Container(
        alignment: Alignment.centerLeft,
        width: 225,
        height: 30,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.elliptical(10, 10)),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                  FirebaseAuth.instance.currentUser?.displayName.toString() ??
                      "Unavailable.")),
        ),
      )
    ]);
  }

  // Displays the user's email
  Widget displayUserEmail(TextStyle dataNameStyle) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Email",
            style: dataNameStyle,
          ),
          const SizedBox(height: 8),
          //const Padding(padding: EdgeInsets.only(right: 10)),
          Container(
            alignment: Alignment.centerLeft,
            width: 225,
            height: 30,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.elliptical(10, 10)),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                    FirebaseAuth.instance.currentUser?.email ?? "unavailable."),
              ),
            ),
          )
        ]);
  }

  // Signs out the current user and redirects them to the login
  void signOutUser() {
    FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const SignOnPage(),
        ),
        (route) => false);
  }

  // Returns a string that the email sent was successful or an error occured.
  // Sends a password reset email to the current user.
  Future resetUserPassword() async {
    String status;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
          email: FirebaseAuth.instance.currentUser?.email ?? "error");
      status =
          "An email has been sent to: \n${FirebaseAuth.instance.currentUser?.email}";
    } catch (e) {
      print(e);
      status = "An error occured. Please try again.";
    }
    return status;
  }

  Future<void> signInWithGoogle() async {
    GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
    try {
      await googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  // Returns a form that allows the user to reset their email.
  // Displays the status of the sent email reset in an alert.
  Widget updateUserEmailForm() {
    TextEditingController emailController = TextEditingController();

    return Container(
      color: secondary,
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                FilledButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateColor.resolveWith(
                          (states) => Colors.transparent)),
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(
                    CupertinoIcons.back,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32),
              child: Column(
                children: [
                  Text(
                    "Change Email",
                    style: TextStyle(
                        color: highlight,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white, height: 1.0),
                    decoration: InputDecoration(
                        isDense: true,
                        hintStyle: const TextStyle(color: Colors.white),
                        fillColor: primary,
                        filled: true,
                        border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15))),
                        hintText: "New Email"),
                  ),
                  ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateColor.resolveWith(
                            (states) => highlight)),
                    onPressed: () {
                      if (emailController.text.isEmpty) return;

                      showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (context) {
                          // Attempt to update email
                          return WillPopScope(
                            onWillPop: () async {
                              return false;
                            },
                            child: FutureBuilder(
                              future: updateUserEmail(emailController.text),
                              builder: (context, snapshot) {
                                switch (snapshot.connectionState) {
                                  case ConnectionState.waiting:
                                  case ConnectionState.none:
                                    return const AlertDialog(
                                      elevation: 10,
                                      content: SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    );

                                  case ConnectionState.active:
                                  case ConnectionState.done:
                                    // handle error cases
                                    if (snapshot.data != null) {
                                      switch (snapshot.data!.code) {
                                        case "requires-recent-login":
                                        case "user-token-expired":
                                          print("requires login");
                                          return displayAlert(
                                              "Reauthentication Needed",
                                              "For security purposes, please login to verify your identity.",
                                              actions: [
                                                ElevatedButton(
                                                  onPressed: () {
                                                    signOutUser();
                                                  },
                                                  child: const Text("Ok"),
                                                )
                                              ]);
                                        case "invalid-email":
                                          print("invalid email");
                                          return displayAlert("Invalid Email",
                                              "Please ensure your email is correct.");
                                        case "same-email":
                                          return displayAlert(
                                              "Cannot Update to Same Email",
                                              "You must update to a different email than your current email.");
                                        // not working
                                        case "email-already-exists":
                                        case "email-already-in-use":
                                          return displayAlert(
                                              "Email Already in Use",
                                              "This email is already taken. Please choose a different email.");
                                        default:
                                          print(snapshot.data!.code);
                                          return displayAlert("Error Occured",
                                              "Please try again later.");
                                      }
                                    }

                                    // Email verification sent successfully, so prepare for reauthentication.
                                    return displayAlert(
                                      "Verify New Email Address",
                                      "A verification email has been sent to ${emailController.text}.",
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () {
                                            signOutUser();
                                          },
                                          style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStateColor
                                                      .resolveWith((states) =>
                                                          highlight)),
                                          child: const Text("Ok"),
                                        ),
                                      ],
                                    );
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                    child: const SizedBox(
                      width: 190,
                      child: Center(
                        child: Text(
                          "Update",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("OR",
                      style: TextStyle(
                          color: primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    child: SignInButton(Buttons.Google,
                        onPressed: signInWithGoogle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updates the current user's email
  Future<FirebaseAuthException?> updateUserEmail(String newEmail) async {
    if (FirebaseAuth.instance.currentUser!.email?.compareTo(newEmail) == 0) {
      print("Tried update with same email.");
      return FirebaseAuthException(code: "same-email");
    }

    try {
      await FirebaseAuth.instance.currentUser
          ?.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      print("email update error: ${e.code}");
      return e;
    }

    return null;
  }

  // Returns a custom preset alert dialog
  AlertDialog displayAlert(String alertTitle, String alertMsg,
      {List<Widget>? actions}) {
    // Default "Ok" button when no actions are passed
    if (actions == null || actions.isEmpty) {
      actions = [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ButtonStyle(
              backgroundColor:
                  MaterialStateColor.resolveWith((states) => highlight)),
          child: const Text("Ok"),
        )
      ];
    }

    // Custom alert dialog
    return AlertDialog(
      title: Text(
        alertTitle,
        style: TextStyle(color: highlight),
      ),
      elevation: 10,
      content: SizedBox(
        width: 50,
        child: Text(
          alertMsg,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      actions: actions,
    );
  }
}
