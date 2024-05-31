import 'package:cord2_mobile_app/pages/home.dart';
import 'package:cord2_mobile_app/pages/map.dart';
import 'package:cord2_mobile_app/pages/chat.dart';
import 'package:cord2_mobile_app/pages/profile.dart';
import 'package:cord2_mobile_app/pages/report.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cord2_mobile_app/pages/profile.dart';
import 'package:cord2_mobile_app/pages/sign_on.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      home: AnimatedPage(),// SignOnPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  String? userId;

  HomePage({required this.userId}); // Track the current page

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String get currentUserId =>
      widget.userId ?? ""; // Using "currentUserId" instead of "userId"

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String currentPage = "Map";

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Your content goes here
          _getPageContent(currentPage,
              currentUserId), // Show content based on the current page
          // Circular menu button
          Positioned(
            top: 30.0,
            left: 10.0,
            child: InkWell(
              onTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              child: Container(
                height: 55,
                width: 55,
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xff242C73),
                ),
                child: const Icon(
                  size: 30,
                  Icons.menu,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Color(0xff060C3E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
                decoration: BoxDecoration(
                  color: Color(0xff060C3E),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CoRD2',
                        style: GoogleFonts.jost(
                          textStyle: TextStyle(
                              color: Colors.white, height: 1.0, fontSize: 25),
                        ),
                      ),
                      SizedBox(height: 15),
                      IconButton(
                        icon: Icon( CupertinoIcons.person_crop_circle, color: Colors.white, size: 50),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProfilePage()),
                          );
                        },
                      ),
                    ])),
            _buildDrawerItem("Map"),
            _buildDrawerItem("Report"),
            _buildDrawerItem("Chat"),
            _buildDrawerItem("Profile"),
            //Shenyag just adds these in DrawerItem.
            _buildDrawerItem("Evacuation Drill"),
            _buildDrawerItem("Pre-drill survey"),
            _buildDrawerItem("Post-drill survey"),
            const Divider(),
            ListTile(
              title: Text('Log Out',
                  style: GoogleFonts.jost(
                    textStyle: TextStyle(
                        color: Colors.white, height: 1.0, fontSize: 20),
                  )),
              onTap: () async {
                await _googleSignIn.signOut();
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => SignOnPage()),//AnimatedPage();
                    (Route route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String pageName) {
    return ListTile(
      title: Text(
        pageName,
        style: GoogleFonts.jost(
          textStyle: TextStyle(color: Colors.white, height: 1.0, fontSize: 20),
        ),
      ),
      onTap: () {
        // Add navigation to the selected page
        Navigator.pop(_scaffoldKey.currentContext!); // Close the drawer
        _navigateToPage(pageName);
      },
    );
  }
//Need to add
  Widget _getPageContent(String pageName, String? userId) {
    // Return the respective page content based on the selected page
    switch (pageName) {
      case "Map":
        return Center(child: DisplayMap());
        return Center(child: DisplayMap());
      case "Report":
        return Center(child: ReportForm(userId: currentUserId));
      case "Chat":
        return Center(child: ChatPage());
      case "Profile":
        return Center(child: ProfilePage());
      //Shenyang just adds these placeholders.
      //We need to add child for these pages (.dart file)
      case "Evacuation Drill":
        return Container();
      case "Pre-drill survey":
        return Container();
      case "Post-drill survey":
        return Container();
      default:
        return Container(); // Default empty container
    }
  }

  void _navigateToPage(String pageName) {
    // Navigate to the selected page
    setState(() {
      currentPage = pageName;
    });
  }
}
