import 'package:animations/animations.dart';
import 'package:cord2_mobile_app/classes/user_data.dart';
import 'package:cord2_mobile_app/models/event_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

class UserReportList {
  late List<EventModel>? events;
  Color highlight = const Color(0xff20297A);
  late BuildContext context;
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

  TextStyle dataStyle = const TextStyle(
      color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500);

  // sets the context to build onto based on
  void setContext(BuildContext context) {
    this.context = context;
  }

  // Returns a border radius for a specified index row
  BorderRadiusGeometry calculateRowBorderRadius(int index) {
    BorderRadiusGeometry? borderRadius;
    //if (events == null) return null;

    // There is only a single row on a page, so create a full border radius
    if (index == events!.length - 1) {
      borderRadius = const BorderRadius.all(Radius.circular(10));
    }
    // Starting row has a top border radius
    else if (index == 0) {
      borderRadius = const BorderRadius.only(
          topLeft: Radius.circular(10), topRight: Radius.circular(10));
    }
    // Last row has a bottom border radius
    else if (index == events!.length - 1) {
      borderRadius = const BorderRadius.only(
          bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10));
    }
    // Middle rows have no border radius
    else {
      borderRadius = const BorderRadius.all(Radius.zero);
    }

    return borderRadius;
  }

  Widget tableDataColumnBackground(int index, Widget data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: calculateRowBorderRadius(index),
      ),
      child: Center(
        child: data,
      ),
    );
  }

  Decoration? tableDataColumnDecoration(int index) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: calculateRowBorderRadius(index),
    );
  }

  DataRow? getRow(int index) {
    print(index);
    if (events == null) {
      return DataRow(
        cells: [
          DataCell(
            Container(
              //width: 80,
              decoration: tableDataColumnDecoration(index),
              child: Center(
                child: Text("No data.", style: dataStyle),
              ),
            ),
          ),
          const DataCell(Text(""))
        ],
      );
    }

    return DataRow(
        color: MaterialStateColor.resolveWith((states) => Colors.transparent),
        cells: [
          DataCell(
            SizedBox(
              width: 200,
              child: showFullReport(index),
            ),
          ),
          DataCell(
            IconButton(
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
                                    (states) => highlight)),
                            onPressed: () {
                              Navigator.pop(context);
                              deleteReport([events![index].id]);
                              events!.removeAt(index);
                              print("Delete");
                            },
                            child: const Text(
                              "Delete",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            )),
                        const SizedBox(
                          width: 50,
                        ),
                        ElevatedButton(
                            style: ButtonStyle(
                                fixedSize: MaterialStateProperty.resolveWith(
                                    (states) => const Size.fromWidth(125)),
                                backgroundColor: MaterialStateColor.resolveWith(
                                    (states) => Colors.white12)),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Back",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            )),
                      ],
                    );
                  },
                ),
              },
              icon: const Icon(
                CupertinoIcons.trash,
                color: Colors.white,
              ),
            ),
          ),
        ]);
  }

  // Displays the full report that was tapped on in the data table
  Widget showFullReport(int index) {
    return OpenContainer(
      closedShape:
          RoundedRectangleBorder(borderRadius: calculateRowBorderRadius(index)),
      transitionType: ContainerTransitionType.fadeThrough,
      closedColor: Colors.white,
      openElevation: 4.0,
      closedBuilder: (context, action) => Container(
        decoration: tableDataColumnDecoration(index),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(events![index].title, style: dataStyle)),
          ),
        ),
      ),
      openBuilder: (context, action) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Theme(
                data: ThemeData(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BackButton(),
                    Text(
                      events![index].title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        wordSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 8),
                    DataTable(
                      columnSpacing: 40,
                      dataTextStyle: dataStyle,
                      dataRowMinHeight: 30,
                      dataRowMaxHeight: double.infinity,
                      headingRowHeight: 2,
                      columns: [
                        DataColumn(label: Container()),
                        DataColumn(label: Container()),
                      ],
                      rows: [
                        DataRow(
                          cells: [
                            const DataCell(Text("Type")),
                            DataCell(
                              Flex(
                                direction: Axis.horizontal,
                                children: [
                                  SizedBox(
                                    child: Text(events![index].type),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        DataRow(
                          cells: [
                            const DataCell(Text("Description")),
                            DataCell(Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(events![index].description),
                            ))
                          ],
                        ),
                        DataRow(cells: [
                          const DataCell(Text("Date Created")),
                          DataCell(
                            Text(
                                "${DateFormat.yMMMd().add_jmz().format(events![index].time.toDate())} ${events![index].time.toDate().timeZoneName}"),
                          )
                        ]),
                        DataRow(cells: [
                          const DataCell(Text("Active")),
                          DataCell(
                            setStatus(events![index].active),
                          )
                        ]),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void refreshData() async {
    events = await UserData.getUserReports();
  }

  void deleteReport(List<String> reportID) async {
    print(reportID);
    bool deletedSuccessfully = await UserData.deleteUserReports(reportID);

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      if (!deletedSuccessfully) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("An error occured deleting the event."),
            backgroundColor: Colors.red));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Successfully deleted"),
            backgroundColor: Colors.red));
      }
    });
  }
}