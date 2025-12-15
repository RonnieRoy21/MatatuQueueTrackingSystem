import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class RegisterStageMarshal extends StatelessWidget {
   RegisterStageMarshal({super.key});

  String formatDate(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return 'N/A';
    return DateFormat('d/M/yyyy  h:mm a').format(timestamp.toDate());
  }

  final _formKey = GlobalKey<FormState>();
  final _fStore=FirebaseFirestore.instance;
  final TextEditingController emailController=TextEditingController();
  final TextEditingController nameController=TextEditingController();
  final TextEditingController idController=TextEditingController();

  bool isLoading=false;

  Future _registerStageMarshal({required String email,required String name,required int id})async{
    try{
      await _fStore.collection('stagemarshal').doc(id.toString()).set({
        'stageMarshalEmail':email,
        'stageMarshalName':name,
      });
      print("REistration response");
      Fluttertoast.showToast(msg: 'Registration success');
    }on FirebaseException catch(fError){
      Fluttertoast.showToast(msg: 'Firebase Error : ${fError.message}');
    }catch  (err){
      Fluttertoast.showToast(msg: 'Error : ${err.toString()}');
    }
  }

  textFormField(
  {
    required String label,
    required TextEditingController controller,
    required TextInputType keyboard,
    required bool obscure,}
      ){
    return TextFormField(
      keyboardType: keyboard,
      obscureText: obscure,
      controller: controller,
      decoration: InputDecoration(
        border:OutlineInputBorder(),
        labelText: label,
      ),
      validator: (value){
        if(value==null || value.isEmpty){
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register Stage Marshal"),),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            textFormField(label: 'Email',
                controller: emailController,
                keyboard: TextInputType.emailAddress,
                obscure: false),
            const SizedBox(height: 10,),
            textFormField(
                label: 'Name',
                controller: nameController,
                keyboard: TextInputType.name,
                obscure: false
            ),
            const SizedBox(height: 10,),
            textFormField(
                label: 'National ID',
                controller: idController,
                keyboard: TextInputType.number,
                obscure:false
            ),
            const SizedBox(height: 15,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(onPressed: (!isLoading)?(){
                  isLoading=true;
                  //register method here
                  if(_formKey.currentState!.validate()){
                    _registerStageMarshal(email: emailController.text, name: nameController.text, id: int.tryParse(idController.text)!);
                  }
                  isLoading=false;
                }:null, child: Text('Sign them up')),
                ElevatedButton(onPressed:(!isLoading)? (){
                  Navigator.pop(context);
                }:null, child: Text('Exit'))
              ],
            )
          ]
        )
      )
    );
  }
}
