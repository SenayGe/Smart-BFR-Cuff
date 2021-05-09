import 'dart:async';

import 'package:bitalino/bitalino.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:smart_cuff/BottomNavigationItems/WorkoutTabbedPage.dart';
import 'package:smart_cuff/Screens/Fatigue.dart';
import 'package:smart_cuff/Screens/LopCalibrationScreen.dart';
import 'package:smart_cuff/Tabs/EmgPage.dart';
import '../Tabs/DashBoard.dart';
import '../DiscoveryPage.dart';
import '../DeviceItemList.dart';
import 'package:smart_cuff/HelperClasses/Utilities.dart';

class PairingScreen extends StatefulWidget {
  @override
  _PairingScreenState createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();
  bool bitalinoBonded= false;
  bool arduinoBonded = false;
  bool isDiscovering = false;
  List<BluetoothDevice> bondedDevices;
  StreamSubscription<BluetoothDiscoveryResult> _streamSubscription;
  List<BluetoothDiscoveryResult> discoveredDevices = List<BluetoothDiscoveryResult>();

  List<BluetoothDevice> devices;
  final String bitalinoMacAddress = "98:D3:51:FD:9D:72";
  final String arduinoMacAddress = "7C:9E:BD:E3:D0:7E";


  BluetoothConnection connection;
  bool isDeviceConnected = false;
  List<DeviceItem> _devices = [
    DeviceItem(
        name: "Smart Cuff",
        icon: "cuff_icon.png",
        battery: "70",
    ),
    DeviceItem(
        name: "Smartwatch",
        icon: "smartwatch_icon.png",
        battery: "57",
       ),
    DeviceItem(
        name: "Pulse Oxymeter",
        icon: "pulseoxymeter_icon.png",
        battery: "98",
        )
  ];
  @override
  Future<void> initState() {
    // TODO: implement initState
    FlutterBluetoothSerial.instance.state.then((state) {
      _bluetoothState = state;
    });
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
    });
/*    FlutterBluetoothSerial.instance
        .setPairingRequestHandler((BluetoothPairingRequest request) {
      print("Trying to auto-pair with Pin 1234");
      if (request.pairingVariant == PairingVariant.Pin) {
        return Future.value("1234");
      }
      return null;
    });*/

    discoverDevices();
    super.initState();
  }

  Future<void> discoverDevices() async {
    bitalinoBonded = await checkBondingStatus(deviceAddress: bitalinoMacAddress);
    if(!bitalinoBonded){
      if(!isDiscovering){
        isDiscovering = true;
        _streamSubscription =  FlutterBluetoothSerial.instance.startDiscovery().listen((r){
          setState(() {
            var deviceExists = discoveredDevices.where((element) => element.device.address==r.device.address);
            if(deviceExists.isEmpty)discoveredDevices.add(r);
          });
        });
        _streamSubscription.onDone(()  {
          print("Discovery Complete");
          isDiscovering = false;
          bondDevices();
        });
      }
    }

super.initState();

  }
  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and cancel discovery
    _streamSubscription?.cancel();
    super.dispose();
  }
  Future<bool> checkBondingStatus({String deviceAddress}) async {
    bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
    return bondedDevices.where((element) => element.address==deviceAddress).isNotEmpty;
  }

  Future<void> bondDevices()  async {
      bitalinoBonded = await checkBondingStatus(deviceAddress: bitalinoMacAddress);
      arduinoBonded = await checkBondingStatus(deviceAddress: arduinoMacAddress);
      print("Bitalino is bonded: $bitalinoBonded");
      if(!bitalinoBonded){
        print("bitalino bonding");
        bitalinoBonded = await FlutterBluetoothSerial.instance
            .bondDeviceAtAddress(bitalinoMacAddress);
        bitalinoBonded?print("bitalino bonded successfully $bitalinoBonded"):print("failed to bond to bitalino");
        Utilities.showSnackBar(_globalKey, "Bitalino is Bonded");
      }
      if(!arduinoBonded){
        print("arduino bonding");
        arduinoBonded = await FlutterBluetoothSerial.instance
            .bondDeviceAtAddress(arduinoMacAddress);
      }
      setState(() {});



  }

  @override
  Widget build(BuildContext context) {
    FlutterBluetoothSerial.instance.state.then((state){
      _bluetoothState = state;
    });
    future()async{
      bitalinoBonded = await checkBondingStatus(deviceAddress: bitalinoMacAddress);
    }
    future();
    return Scaffold(
      key: _globalKey,
      appBar: AppBar(
        title: Text(
          'Connect Devices',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Color(0xffbF8F8F8),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String value) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return DiscoveryPage();
                  },
                ),
              );
            },
            itemBuilder: (BuildContext context) {
              return {'Scan'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text('Scan'),
                );
              }).toList();
            },
          )
        ],
      ),
      body:_showDevicesPairingPage()
    );
  }
  Widget _showDevicesPairingPage(){
    return Column(
      children: <Widget>[
        SwitchListTile(
          title: Text("Enable bluetooth"),
          value: _bluetoothState.isEnabled,
          activeColor: Colors.blueAccent,
          onChanged: (bool isBluetoothOn) {
            future() async {
              if (isBluetoothOn)
                await FlutterBluetoothSerial.instance
                    .requestEnable();
              else
                await FlutterBluetoothSerial.instance
                    .requestDisable();
            }
            future().then((_) {
              setState(() {});
            });
          },
        ),
        _devicesList(_devices),
        SizedBox(height: MediaQuery.of(context).size.height/5,),
        _continueButton(),

      ],
    );
  }
  Widget _devicesList(List<DeviceItem> items) {
    return  ListView.builder(
        itemCount: items.length,
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return GestureDetector(
            child: _deviceItem(items[index], index),
            onTap: () {},
          );
        });
  }
  Widget _deviceItem(DeviceItem item, int index) {
    return Container(
        margin: EdgeInsets.only(left: 8, right: 8, top: 2),
        height: MediaQuery.of(context).size.height/6,
        decoration: BoxDecoration(
          color: Color(0xffbecf1f6),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              ClipRRect(
                child: Image.asset(
                  "assets/${item.icon}",
                  width: 80,
                  height: 90,
                  fit: BoxFit.fill,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              // SizedBox(width: 4,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("${item.name}",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          letterSpacing: 0.8)),
                  Row(
                    children: <Widget>[
                      Icon(
                        item.isBonded
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: Colors.black45,
                      ),
                      SizedBox(
                        width: 4,
                      ),
                      Text( // item.isBonded ? "Connected" : "Not Connected"
                        "Connected" , // TODO: Change it back
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.black87,
                        ),
                      )
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.battery_charging_full,
                        color: Colors.black45,
                      ),
                      //SizedBox(width: 4,),
                      Text(
                        "${item.battery}%",
                        style: TextStyle(fontSize: 14.0, color: Colors.black87),
                      )
                    ],
                  ),
                  SizedBox(height: 6),
                  GestureDetector(
                      child: Text(
                        '  Pair',
                        style: TextStyle(
                          fontSize: 16,
                          letterSpacing: 1,
                          color: Color(0xffbFF4d4d),
                        ),
                      ),
                      onTap: () async {
                         BluetoothDevice bluetoothDevice = await Navigator.of(context).push(MaterialPageRoute(
                           builder: (context)=>DiscoveryPage(),
                         ));
                         setState(() { //todo this only assigns the clicked element
                           item.isConnected = bluetoothDevice.isConnected;
                           item.isBonded = bluetoothDevice.isBonded;
                         });

                      }),
                ],
              ),
              SizedBox(
                height: 16,
              ),
              GestureDetector(
                  child: IconButton(
                    icon: Icon(Icons.more_vert),
                  ),
                  onTap: () {
                   //Todo show popup menu
                  }),
            ],
          ),
        ));
  }

  Widget _addDeviceButton() {
    return RaisedButton(
      child: Text(
        'Add a Device',
        style: TextStyle(
          fontSize: 14,
          letterSpacing: 1,
          color: Color(0xffbFF4d4d),
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Color(0xffbF8F8F8),
      elevation: 0.8,
      onPressed: () async {
       BluetoothDevice bluetoothDevice =
            await Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => DiscoveryPage(),
        ));

         setState(() {
           _devices.add(DeviceItem(name:bluetoothDevice.name,isBonded: bluetoothDevice.isBonded));
         });
      },

    );
  }
  Widget _showNoDevicesFound(){
    return Center(
      child: Column(
        children: <Widget>[
          Center(
            child: Text(
              "No Devices found",
              style: TextStyle(fontSize: 24, color: Colors.red),
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Center(child: IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              if(!isDiscovering){
                await discoverDevices();
                setState(() {});
              }
              else{
                Utilities.showSnackBar(_globalKey, "Discovery already in progress");
              }
            },
          ))
        ],
      ),
    );

  }
  Widget _continueButton(){
    return Container(
      height: MediaQuery.of(context).size.height/20,
      width: MediaQuery.of(context).size.width/0.4,
      child: RaisedButton(
        child: Text(
          'Continue',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Color(0xffbfa6f82),
        textColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Server()),
          );
        },
      ),
    );

  }
  Widget popUpMenu(){
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      height: 50,
      width: 50,
      child: PopupMenuButton(
        child: FlutterLogo(),
        itemBuilder: (context) {
          return <PopupMenuItem>[new PopupMenuItem(child: Text('Delete'))];
        },
      ),
    );

  }

}
