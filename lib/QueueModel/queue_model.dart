import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluttertoast/fluttertoast.dart';
class QueueModel {

  final _fStore=FirebaseFirestore.instance;

  //kuadd driver kwa queue
Future requestCheckIn({
  required String vehicleNumber,
})async{

  try {
    final response=await _fStore.collection('driver').doc(vehicleNumber).get();
    final driverName=response.data()!['driverName'];
    await _fStore.collection('queue').doc(vehicleNumber).set({
      'driverName': driverName,
      'vehicleNumber': vehicleNumber,
      'status': 'pending approval',
      'createdAt': DateTime.now().toString(),
    });
    Fluttertoast.showToast(msg: "Request sent");
  }on FirebaseException catch(fError){
    Fluttertoast.showToast(msg: "${fError.message}");
  }catch(error){
    Fluttertoast.showToast(msg: error.toString());
  }
}

//fetch data ya queue
  Stream<List<Map<String, dynamic>>> fetchQueue() {
    return _fStore
        .collection('queue')
        .orderBy('createdAt',descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => doc.data()).toList());
  }
//fetch queue where status is departed only
  Future<List<Map<String, dynamic>>> fetchDepartedQueue() {
    final response= _fStore.collection('driver').where('status', isEqualTo: 'departed').get();
    return response.then((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

//approve driver in queue
Future approveDriver({required String vehicleNumber,required String driverName,required String stamp})async{
  try{
  await _fStore.collection('queue').doc(vehicleNumber).set({
    'vehicleNumber': vehicleNumber,
    'driverName': driverName,
    'createdAt': stamp,
    'status': 'approved',
  });

  Fluttertoast.showToast(msg: "Driver has been approved ");
  }on FirebaseException catch(fError){
    Fluttertoast.showToast(msg: "${fError.message}");
  }catch(error){
    Fluttertoast.showToast(msg: error.toString());
  }
  }

Future departDriver({required String vehicleNumber,required String driverName,required String stamp})async{
  try{
    await _fStore.collection('queue').doc(vehicleNumber).set({
      'vehicleNumber': vehicleNumber,
      'driverName': driverName,
      'createdAt': stamp,
      'status': 'departed',
    });
    Fluttertoast.showToast(msg: "Driver has been departed ");
}on FirebaseException catch(fError){
    Fluttertoast.showToast(msg: "${fError.message}");
  }catch(error){
    Fluttertoast.showToast(msg: error.toString());
}
}



}