import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:flutter/material.dart';
import 'package:smart_cuff/Tabs/DashBoard.dart';
import 'package:smart_cuff/Tabs/EmgPage.dart';

class WorkoutPage extends StatefulWidget {
  @override
  _WorkoutPageState createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  static List<Widget> _tabContents = [
    DashBoard(),
    EmgAnalyticsPage()
  ];
  int tabIndex = 0;
  int numberOfTabs = _tabContents.length;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex:  tabIndex ,
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: tabbedAppBar(),
        body: TabBarView(
         //physics: NeverScrollableScrollPhysics(),
          children: _tabContents,
        ),
      ),
    );
  }


  PreferredSize tabbedAppBar(){
    List<Widget> _tabs = [
      Text("Session",style: TextStyle(color: Colors.redAccent),),
      Text("EMG Analytics", style: TextStyle(color: Colors.redAccent),)
    ];
    return PreferredSize(
      preferredSize: Size.fromHeight(90),
      child: AppBar(
        title: Text("Workout Session", style: TextStyle(color: Colors.black87),),
        backgroundColor: Color(0xfff7f2f2),
        elevation: 0.0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: Container(
            height: 40,
            margin: EdgeInsets.fromLTRB(8, 0, 8, 8),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.all(Radius.circular(220)),
            ),
            child: TabBar(
              unselectedLabelColor: Colors.black,
              indicator: BubbleTabIndicator(
                  indicatorHeight: 40.0,
                  indicatorRadius: 18,
                  tabBarIndicatorSize: TabBarIndicatorSize.tab,
                  indicatorColor: Colors.white),
              tabs: _tabs,
            ),
          ),
        ) ,
      ),
    );

  }

}

