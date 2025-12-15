import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:queuetrack/screens/Authentication/signup_screen.dart';
import 'package:queuetrack/screens/all_dashboards.dart';

// ignore: must_be_immutable
class LoginPage extends StatefulWidget {
  String selectedRole;
   LoginPage({super.key,required this.selectedRole});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController driverIdController = TextEditingController();
  final TextEditingController stageMarshalIdController = TextEditingController();
  final TextEditingController driverNameController =TextEditingController();
  final TextEditingController stageMarshalNameController = TextEditingController();
  final TextEditingController vehicleNumberController =TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  final _formKey=GlobalKey<FormState>();

  // //lets fetch role
  // Future _fetchRole({required String category , required String selectedRole,required String email}) async {
  //  final response= await _firestore.collection(category).doc(_auth.currentUser!.uid).get();
  //  final data =response.data();
  //  final _role = data!['role'];
  //  return _role;
  // }
  //login each user  with email and any other
  Future _loginSaccoOfficialOrMatatuOwner({required String email,required String password})async{
    try{
      final response=await _auth.signInWithEmailAndPassword(email: email, password: password);

      if(response.user!.uid.isNotEmpty){
        Fluttertoast.showToast(msg: "Login success");
      Widget response =getDashboard(widget.selectedRole.toLowerCase(),'none');
      Navigator.push(context,MaterialPageRoute(builder: (context) =>response));
      }
    }on FirebaseAuthException catch(fError){
      Fluttertoast.showToast(msg: "${fError.message}");
    }catch (err){
      Fluttertoast.showToast(msg: "Error : ${err.toString()}");
    }
}
Future _loginDriverOrStageMarshal({required String role,required String email,required int id, required String vehicleNumber, required String marshalName})async{
    try{
      switch(role.toLowerCase()){
        case 'driver':
          final response=await _firestore.collection('driver').doc(vehicleNumber).get();
          if(response.data()==null) {
            Fluttertoast.showToast(msg: "Data not found");
          }
          final data=response.data();
          final fetchedId=data!['driverId'];
          final fetchedEmail=data['driverEmail'];
          if(fetchedId==id && fetchedEmail==email) {
            Widget response=getDashboard(role,vehicleNumber);
            Navigator.push(context,MaterialPageRoute(builder: (context) =>response));
          }else{
            Fluttertoast.showToast(msg: "Driver details not found");
          }
        case 'stage_marshal':
          final response =await _firestore.collection('stagemarshal').doc(id.toString()).get();
          if(response.data()==null){
            Fluttertoast.showToast(msg: "Data not found");
          }
          final data=response.data();
          print("Data : $data");
          final fetchedName=data!['stageMarshalName'];
          final fetchedEmail=data['stageMarshalEmail'];
          if(fetchedName==marshalName && fetchedEmail==email){
            Widget response =getDashboard(role,'none');
            Navigator.push(context,MaterialPageRoute(builder: (context) =>response));
          }else{
            Fluttertoast.showToast(msg: "Stage Marshal details not found");
          }
      }
      }on FirebaseException catch(fError){
        Fluttertoast.showToast(msg: "${fError.message}");
      }catch(error){
        Fluttertoast.showToast(msg: error.toString());
    }
}






//reusable widget badala ya kuduplicate code
Widget _textField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboard,
    required bool obscure,

}){
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0EA5A4),Color(0xFF009688)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: width > 600 ? 520 : double.infinity,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'QueueTrack',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.teal.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sign in to manage your matatu stage',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        _textField(label: 'Email',
                            controller: emailController,
                            keyboard: TextInputType.emailAddress,
                            obscure: false
                        ),
                        const SizedBox(height: 18),
                      if(widget.selectedRole.toLowerCase() == 'sacco_official' || widget.selectedRole.toLowerCase() == 'matatu_owner')
                          _textField(label: 'Password',
                              controller: passwordController,
                              keyboard: TextInputType.visiblePassword,
                              obscure: true
                          ),
                          const SizedBox(height: 18),
                      if(widget.selectedRole.toLowerCase() == 'driver')
                            _textField(
                                label: 'Driver Name',
                                controller: driverNameController,
                                keyboard: TextInputType.name,
                                obscure: false),
                      const SizedBox(height: 18),
                      if(widget.selectedRole.toLowerCase() == 'driver')
                          _textField(
                                label: 'Driver Id',
                             controller: driverIdController,
                             keyboard: TextInputType.number,
                             obscure: false
                            ),
                      const SizedBox(height: 18),
                        if(widget.selectedRole.toLowerCase() == 'driver')
                          _textField(
                              label: 'Vehicle Number',
                              controller: vehicleNumberController,
                              keyboard: TextInputType.text,
                              obscure: false
                          ),
                        const SizedBox(height: 18),
                      if(widget.selectedRole.toLowerCase() == 'stage_marshal')
                            _textField(
                                label:'Stage Marshal Name ',
                                controller: stageMarshalNameController,
                                keyboard: TextInputType.name,
                                obscure: false),
                      const SizedBox(height: 18),
                      if(widget.selectedRole.toLowerCase() == 'stage_marshal')
                          _textField(
                              label: 'Stage Marshal Id',
                              controller: stageMarshalIdController,
                              keyboard:TextInputType.number,
                              obscure: false
                          ),
                        const SizedBox(height: 18),
                        isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: ()async{
                                  if(_formKey.currentState!.validate()){
                                    isLoading=!isLoading;
                                    print("Role is : ${widget.selectedRole}");
                                    if(widget.selectedRole.toLowerCase() == 'sacco_official' || widget.selectedRole.toLowerCase() == 'matatu_owner'){
                                      await _loginSaccoOfficialOrMatatuOwner(email: emailController.text, password: passwordController.text);
                                      isLoading=!isLoading;
                                    }else if(widget.selectedRole.toLowerCase() == 'driver'){
                                      int ID=int.tryParse(driverIdController.text.toString())!;
                                      await _loginDriverOrStageMarshal(marshalName:"none" ,vehicleNumber: vehicleNumberController.text,id:ID,role: widget.selectedRole, email: emailController.text, );
                                      isLoading=!isLoading;
                                    }else{
                                      int ID=int.tryParse(stageMarshalIdController.text.toString())!;
                                      await _loginDriverOrStageMarshal(marshalName: stageMarshalNameController.text,id:ID,role: widget.selectedRole,email: emailController.text, vehicleNumber: 'none');
                                      isLoading=!isLoading;
                                    }
                                  }
                                  },
                                child: const Text('Login'),
                              ),
                        const SizedBox(height: 8),
                        (widget.selectedRole.toLowerCase() == 'sacco_official' || widget.selectedRole.toLowerCase() == 'matatu_owner')?
                          TextButton(
                            onPressed: () {

                              Navigator.push(context,MaterialPageRoute(builder: (context) =>SignUpScreen(selectedRole: widget.selectedRole,))); // ✅ fixed
                            },
                            child: const Text("Don't have an account? Sign up"),
                          ): Text("No sign in available for ${widget.selectedRole}"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
