import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AssignVehicleScreen extends StatefulWidget {
  const AssignVehicleScreen({super.key});

  @override
  State<AssignVehicleScreen> createState() => _AssignVehicleScreenState();
}

class _AssignVehicleScreenState extends State<AssignVehicleScreen> {
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController driverIdController = TextEditingController();
  final TextEditingController driverNameController = TextEditingController();
  final TextEditingController driverEmailController = TextEditingController();
  bool isLoading = false;
  final _formKey=GlobalKey<FormState>();
  final _fstore=FirebaseFirestore.instance;

  //method ya kuongeza record kwa firebase
  Future registerVehicle({required String vehicleNumber, required int driverId, required String driverName, required String driverEmail}) async {
    try {
      final docs = await _fstore.collection('driver').get();
      if(docs.docs.isNotEmpty){
      for (final d in docs.docs){
        final docId=d.id;
        final data=d.data();
        final existingDriverId=data['driverId'];
        if( docId==vehicleNumber) {
          Fluttertoast.showToast(msg: "Vehicle  already exists");
        }else if(existingDriverId==driverId){
          Fluttertoast.showToast(msg: "Driver registered to another vehicle");
        }else{
          await _fstore.collection('driver').doc(vehicleNumber).set({
            'driverId': driverId,
            'driverName': driverName,
            'driverEmail': driverEmail,
          });
          Fluttertoast.showToast(msg: "Registration success");
        }
      }
      print("Fucntion stopped here");
      }
    }on FirebaseException catch (fError){
      print("Firebase error : ${fError.message}");
      Fluttertoast.showToast(msg: fError.message!);
    }catch (e){
      print("Error : ${e.toString()}");
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  Widget _textFields({
    required int length,
    required String label,
    required TextEditingController controller,
    required TextInputType keyboard,

}) {
    return TextFormField(
      maxLength: length,
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: label,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      }
    );
  }
  @override
  void dispose() {
    vehicleNumberController.dispose();
    driverIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
          title: const Text("Register / Assign Vehicle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _textFields(
                length: 8,
                  label: 'Vehicle Number',
                  controller: vehicleNumberController,
                  keyboard:TextInputType.text
              ),
              const SizedBox(height: 16),
              _textFields(
                length: 8,
                  label: 'Driver ID',
                  controller: driverIdController,
                  keyboard: TextInputType.number
              ),
              const SizedBox(height: 24),
              _textFields(
                  length: 15,
                  label: 'Driver Name',
                  controller: driverNameController,
                  keyboard: TextInputType.name
              ),
              const SizedBox(height: 24),
              _textFields(
                label: "Driver's Email",
                length:20,
                controller: driverEmailController,
                keyboard: TextInputType.emailAddress
              ),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Register Vehicle"),
                      onPressed: ()async{
                        if(_formKey.currentState!.validate()){
                            isLoading = true;
                          //add the method here ya kujaza kwa firebase db
                        await registerVehicle(
                          vehicleNumber: vehicleNumberController.text,
                          driverId: int.tryParse(driverIdController.text.toString())!,
                          driverName: driverNameController.text,
                          driverEmail: driverEmailController.text
                        );
                        }
                          isLoading = false;

                      }
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
