import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cupertino_date_picker/flutter_cupertino_date_picker.dart';
import 'package:intl/intl.dart';
import 'package:pikobar_flutter/blocs/profile/Bloc.dart';
import 'package:pikobar_flutter/components/CustomAppBar.dart';
import 'package:pikobar_flutter/components/DialogTextOnly.dart';
import 'package:pikobar_flutter/constants/Dictionary.dart';
import 'package:pikobar_flutter/constants/UrlThirdParty.dart';
import 'package:pikobar_flutter/constants/firebaseConfig.dart';
import 'package:pikobar_flutter/environment/Environment.dart';
import 'package:pikobar_flutter/repositories/ProfileRepository.dart';
import 'package:pikobar_flutter/screens/myAccount/VerificationScreen.dart';
import 'package:pikobar_flutter/utilities/Connection.dart';
import 'package:pikobar_flutter/utilities/Validations.dart';
import 'package:grouped_buttons/grouped_buttons.dart';
import 'package:pikobar_flutter/components/custom_dropdown.dart' as custom;

class Edit extends StatefulWidget {
  final AsyncSnapshot<DocumentSnapshot> state;
  Edit({this.state});
  @override
  _EditState createState() => _EditState();
}

class _EditState extends State<Edit> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _genderController = TextEditingController();
  final _birthDayController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();
  String verificationID, smsCode;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ProfileRepository _profileRepository = ProfileRepository();
  ProfileBloc _profileBloc;
  PhoneVerificationCompleted verificationCompleted;
  PhoneVerificationFailed verificationFailed;
  PhoneCodeSent codeSent;
  String _format = 'yyyy-MMMM-dd';
  String minDate = '1900-01-01';
  DateTimePickerLocale _locale = DateTimePickerLocale.en_us;
  bool otpEnabled;
  bool isCityFieldEmpty = false;
  bool isBirthdayEmpty = false;
  bool isGenderEmpty = false;



  @override
  void initState() {
    _nameController.text = widget.state.data['name'];
    _emailController.text = widget.state.data['email'];
    _phoneNumberController.text = widget.state.data['phone_number'] != null
        ? widget.state.data['phone_number'].toString().substring(3)
        : null;
    _addressController.text = widget.state.data['address'];
    _birthDayController.text = widget.state.data['birthdate'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
                widget.state.data['birthdate'].seconds * 1000)
            .toString();
    _genderController.text = widget.state.data['gender'];
    _cityController.text = widget.state.data['city_id'];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        key: _scaffoldState,
        appBar: CustomAppBar.defaultAppBar(
          title: Dictionary.edit,
        ),
        body: FutureBuilder<RemoteConfig>(
            future: setupRemoteConfig(),
            builder:
                (BuildContext context, AsyncSnapshot<RemoteConfig> snapshot) {
              otpEnabled = snapshot.data != null &&
                      snapshot.data.getBool(FirebaseConfig.otpEnabled) != null
                  ? snapshot.data.getBool(FirebaseConfig.otpEnabled)
                  : false;
              return BlocProvider<ProfileBloc>(
                  create: (BuildContext context) => _profileBloc =
                      ProfileBloc(profileRepository: _profileRepository)
                        ..add(CityLoad()),
                  child: BlocListener<ProfileBloc, ProfileState>(
                    listener: (context, state) {
                      if (state is ProfileFailure) {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) => DialogTextOnly(
                                  description: state.error.toString(),
                                  buttonText: Dictionary.ok,
                                  onOkPressed: () {
                                    Navigator.of(context)
                                        .pop(); // To close the dialog
                                  },
                                ));
                        Scaffold.of(context).hideCurrentSnackBar();
                      } else if (state is ProfileWaiting) {
                      } else if (state is ProfileVerified) {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) => DialogTextOnly(
                                  description: Dictionary.codeVerified,
                                  buttonText: Dictionary.ok,
                                  onOkPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                  },
                                ));
                        Scaffold.of(context).hideCurrentSnackBar();
                      } else if (state is ProfileSaved) {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) => DialogTextOnly(
                                  description: Dictionary.profileSaved,
                                  buttonText: Dictionary.ok,
                                  onOkPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context)
                                        .pop(); // To close the dialog
                                  },
                                ));
                        Scaffold.of(context).hideCurrentSnackBar();
                      } else if (state is ProfileOTPSent) {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) => DialogTextOnly(
                                  description: Dictionary.codeSend +
                                      Dictionary.inaCode +
                                      _phoneNumberController.text,
                                  buttonText: Dictionary.ok,
                                  onOkPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Verification(
                                                phoneNumber:
                                                    _phoneNumberController.text,
                                                uid: widget.state.data['id'],
                                                verificationID:
                                                    state.verificationID,
                                                gender: _genderController.text,
                                                address:
                                                    _addressController.text,
                                                cityId: _cityController.text,
                                                provinceId:
                                                    Dictionary.provinceId,
                                                birthdate: DateTime.parse(
                                                    _birthDayController.text),
                                              )),
                                    );
                                  },
                                ));
                        Scaffold.of(context).hideCurrentSnackBar();
                      } else if (state is ProfileVerifiedFailed) {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) => DialogTextOnly(
                                  description: Dictionary.codeSendFailed,
                                  buttonText: Dictionary.ok,
                                  onOkPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ));
                        Scaffold.of(context).hideCurrentSnackBar();
                      } else if (state is ProfileLoading) {
                        Scaffold.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Theme.of(context).primaryColor,
                            content: Row(
                              children: <Widget>[
                                CircularProgressIndicator(),
                                Container(
                                  margin: EdgeInsets.only(left: 15.0),
                                  child: Text(Dictionary.loading),
                                )
                              ],
                            ),
                            duration: Duration(seconds: 5),
                          ),
                        );
                      } else {
                        Scaffold.of(context).hideCurrentSnackBar();
                      }
                    },
                    child: ListView(
                      padding: EdgeInsets.all(10),
                      children: <Widget>[
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Column(
                              children: <Widget>[
                                buildTextField(
                                    title: Dictionary.name,
                                    controller: _nameController,
                                    isEdit: false),
                                SizedBox(
                                  height: 20,
                                ),
                                buildTextField(
                                    title: Dictionary.email,
                                    controller: _emailController,
                                    isEdit: false),
                                SizedBox(
                                  height: 20,
                                ),
                                buildPhoneField(
                                    title: Dictionary.phoneNumber,
                                    controller: _phoneNumberController,
                                    validation: Validations.phoneValidation,
                                    isEdit: true,
                                    hintText:
                                        Dictionary.phoneNumberPlaceholder),
                                SizedBox(
                                  height: 20,
                                ),
                                buildRadioButton(
                                    title: Dictionary.gender,
                                    label: <String>[
                                      "Laki - Laki",
                                      "Perempuan",
                                    ],isEmpty: isGenderEmpty),
                                SizedBox(
                                  height: 20,
                                ),
                                buildDateField(
                                  title: Dictionary.birthday,
                                  placeholder: _birthDayController.text == ''
                                      ? Dictionary.birthdayPlaceholder
                                      : DateFormat.yMMMMd().format(
                                          DateTime.parse(_birthDayController
                                              .text
                                              .substring(0, 10))),
                                              isEmpty: isBirthdayEmpty
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                buildTextField(
                                    title: Dictionary.addressDomicile,
                                    controller: _addressController,
                                    maxLines: 2,
                                    hintText: Dictionary.addressPlaceholder,
                                    validation: Validations.addressValidation,
                                    isEdit: true),
                                SizedBox(
                                  height: 20,
                                ),
                                BlocBuilder(
                                    bloc: _profileBloc,
                                    builder: (BuildContext context,
                                        ProfileState state) {
                                      if (state is CityLoaded) {
                                        state.record.data.sort((a, b) => a
                                            .namaWilayah
                                            .compareTo(b.namaWilayah));
                                        return buildDropdownField(
                                            Dictionary.cityDomicile,
                                            Dictionary.cityPlaceholder,
                                            state.record.data,
                                            _cityController,
                                            isCityFieldEmpty);
                                      } else {
                                        return buildDropdownField(
                                            Dictionary.cityDomicile,
                                            Dictionary.loading,
                                            [],
                                            _cityController,
                                            false);
                                      }
                                    }),
                                SizedBox(
                                  height: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        RaisedButton(
                          color: Color(0xff27AE60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          onPressed: () {
                            _onSaveProfileButtonPressed(otpEnabled);
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 13),
                            child: Text(
                              Dictionary.save,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      ],
                    ),
                  ));
            }),
      ),
    );
  }

  void _showDatePickerBirthday() {
    DatePicker.showDatePicker(
      context,
      pickerTheme: DateTimePickerTheme(
        showTitle: true,
        confirm: Text(Dictionary.save, style: TextStyle(color: Colors.red)),
        cancel: Text(Dictionary.cancel, style: TextStyle(color: Colors.cyan)),
      ),
      minDateTime: DateTime.parse(minDate),
      maxDateTime: DateTime.now(),
      initialDateTime: _birthDayController.text == ''
          ? DateTime.now()
          : DateTime.parse(_birthDayController.text),
      dateFormat: _format,
      locale: _locale,
      onClose: () {
        setState(() {
          _birthDayController.text = _birthDayController.text;
        });
      },
      onCancel: () {
        setState(() {
          _birthDayController.text = _birthDayController.text;
        });
      },
      onConfirm: (dateTime, List<int> index) {
        setState(() {
          _birthDayController.text = dateTime.toString();
        });
      },
    );
  }

  _onSaveProfileButtonPressed(bool otpEnabled) async {
    if (_cityController.text == '') {
      setState(() {
        isCityFieldEmpty = true;
      });
    } else {
      setState(() {
        isCityFieldEmpty = false;
      });
    }
      if (_genderController.text == '') {
      setState(() {
        isGenderEmpty = true;
      });
    } else {
      setState(() {
        isGenderEmpty = false;
      });
    }
        if (_birthDayController.text == '') {
      setState(() {
        isBirthdayEmpty = true;
      });
    } else {
      setState(() {
        isBirthdayEmpty = false;
      });
    }
    if (_formKey.currentState.validate()) {
      FocusScope.of(context).unfocus();
      if (isGenderEmpty ||
         isBirthdayEmpty ||
          isCityFieldEmpty) {
      
      } else if (widget.state.data['phone_number'] ==
          Dictionary.inaCode + _phoneNumberController.text) {
        _profileBloc.add(Save(
            id: widget.state.data['id'],
            phoneNumber: _phoneNumberController.text,
            gender: _genderController.text,
            address: _addressController.text,
            cityId: _cityController.text,
            provinceId: Dictionary.provinceId,
            birthdate: DateTime.parse(_birthDayController.text)));
      } else {
        if (otpEnabled) {
          bool isConnected =
              await Connection().checkConnection(UrlThirdParty.urlGoogle);
          if (isConnected) {
            verificationCompleted = (AuthCredential credential) async {
              await _profileRepository.linkCredential(
                widget.state.data['id'],
                _phoneNumberController.text,
                _genderController.text,
                _addressController.text,
                _cityController.text,
                Dictionary.provinceId,
                DateTime.parse(_birthDayController.text),
                credential,
              );
              _profileBloc.add(VerifyConfirm());
            };
            verificationFailed = (AuthException authException) {
              _profileBloc.add(VerifyFailed());
            };

            codeSent =
                (String verificationId, [int forceResendingToken]) async {
              _profileBloc.add(CodeSend(verificationID: verificationId));
            };
            _profileBloc.add(Verify(
                id: widget.state.data['id'],
                phoneNumber: _phoneNumberController.text,
                verificationCompleted: verificationCompleted,
                verificationFailed: verificationFailed,
                codeSent: codeSent));
          }
        } else {
          _profileBloc.add(Save(
              id: widget.state.data['id'],
              phoneNumber: _phoneNumberController.text,
              gender: _genderController.text,
              address: _addressController.text,
              cityId: _cityController.text,
              provinceId: Dictionary.provinceId,
              birthdate: DateTime.parse(_birthDayController.text)));
        }
      }
    }
  }

  Widget buildRadioButton({String title, List<String> label,bool isEmpty}) {
    return Padding(
      padding: EdgeInsets.only(left: 16.0, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                title,
                style: TextStyle(fontSize: 15.0, color: Color(0xff828282)),
              ),
              Text(
                '*',
                style: TextStyle(fontSize: 15.0, color: Colors.red),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          RadioButtonGroup(
            activeColor: Color(0xff27AE60),
            orientation: GroupedButtonsOrientation.HORIZONTAL,
            onSelected: (String selected) => setState(() {
              _genderController.text = selected.contains('Laki') ? 'M' : 'F';
            }),
            labels: label,
            picked: _genderController.text == 'M'
                ? 'Laki - Laki'
                : _genderController.text == 'F' ? 'Perempuan' : null,
            itemBuilder: (Radio rb, Text txt, int i) {
              return Padding(
                padding: EdgeInsets.only(right: 10),
                child: Container(
                    height: 40,
                    width: MediaQuery.of(context).size.width / 2.8,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Color(0xffE0E0E0), width: 1.5)),
                    child: Row(
                      children: <Widget>[
                        rb,
                        txt,
                      ],
                    )),
              );
            },
          ),
           isEmpty
              ?
          SizedBox(
            height: 10,
          ):Container(),
          isEmpty
              ? Text(
                  title + Dictionary.pleaseCompleteAllField,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                )
              : Container()
        ],
      ),
    );
  }

  Widget buildDateField({String title, placeholder,bool isEmpty}) {
    return Container(
      padding: EdgeInsets.only(left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                title,
                style: TextStyle(fontSize: 15.0, color: Color(0xff828282)),
              ),
              Text(
                '*',
                style: TextStyle(fontSize: 15.0, color: Colors.red),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          InkWell(
            onTap: () {
              _showDatePickerBirthday();
            },
            child: Container(
              height: 60,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xffE0E0E0), width: 1.5)),
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Container(
                        height: 20,
                        child: Image.asset(
                            '${Environment.iconAssets}calendar.png')),
                  ),
                  Text(
                    placeholder,
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
           isEmpty
              ?
          SizedBox(
            height: 10,
          ):Container(),
          isEmpty
              ? Text(
                  title +  Dictionary.pleaseCompleteAllField,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                )
              : Container()
        ],
      ),
    );
  }

  Widget buildTextField(
      {String title,
      TextEditingController controller,
      String hintText,
      validation,
      TextInputType textInputType,
      TextStyle textStyle,
      bool isEdit,
      int maxLines}) {
    return Container(
      padding: EdgeInsets.only(left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                title,
                style: TextStyle(fontSize: 15.0, color: Color(0xff828282)),
              ),
              Text(
                '*',
                style: TextStyle(fontSize: 15.0, color: Colors.red),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            height: title == Dictionary.addressDomicile ? null : 50,
            child: TextFormField(
              maxLines: maxLines != null ? maxLines : 1,
              style: isEdit
                  ? TextStyle(
                      color: Colors.black,
                    )
                  : TextStyle(color: Color(0xffBDBDBD)),
              enabled: isEdit,
              validator: validation,
              textCapitalization: TextCapitalization.words,
              controller: controller,
              decoration: InputDecoration(
                  hintText: hintText,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Color(0xffE0E0E0), width: 1.5)),
                  disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Color(0xffE0E0E0), width: 1.5)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Color(0xffE0E0E0), width: 1.5))),
              keyboardType:
                  textInputType != null ? textInputType : TextInputType.text,
            ),
          )
        ],
      ),
    );
  }

  Widget buildDropdownField(String title, String hintText, List items,
      TextEditingController controller, bool isEmpty,
      [validation]) {
    return Container(
      padding: EdgeInsets.only(left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                title,
                style: TextStyle(fontSize: 15.0, color: Color(0xff828282)),
              ),
              Text(
                '*',
                style: TextStyle(fontSize: 15.0, color: Colors.red),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            height: 60,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xffE0E0E0), width: 1.5)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: custom.DropdownButton<dynamic>(
                underline: SizedBox(),
                isExpanded: true,
                hint: Text(hintText,style: TextStyle(fontSize: 13),),
                items: items.map((item) {
                  return custom.DropdownMenuItem(
                    child: Text(item.namaWilayah),
                    value: item.kodeKemendagri.toString(),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    controller.text = value;
                  });
                },
                value: controller.text == '' ? null : controller.text,
              ),
            ),
          ),
          isEmpty
              ?
          SizedBox(
            height: 10,
          ):Container(),
          isEmpty
              ? Text(
                  title +  Dictionary.pleaseCompleteAllField,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                )
              : Container()
        ],
      ),
    );
  }

  Widget buildPhoneField(
      {String title,
      TextEditingController controller,
      String hintText,
      validation,
      TextInputType textInputType,
      TextStyle textStyle,
      bool isEdit}) {
    return Container(
      padding: EdgeInsets.only(left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                title,
                style: TextStyle(fontSize: 15.0, color: Color(0xff828282)),
              ),
              Text(
                '*',
                style: TextStyle(fontSize: 15.0, color: Colors.red),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 60,
                width: MediaQuery.of(context).size.width / 7,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xffE0E0E0), width: 1.5)),
                child: Center(
                    child: Text(
                  Dictionary.inaCode,
                  style: TextStyle(fontSize: 15),
                )),
              ),
              SizedBox(
                width: 20,
              ),
              Expanded(
                child: TextFormField(
                  style: isEdit
                      ? TextStyle(color: Colors.black)
                      : TextStyle(color: Color(0xffBDBDBD)),
                  enabled: isEdit,
                  validator: validation,
                  controller: controller,
                  decoration: InputDecoration(
                      hintText: hintText,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Color(0xffE0E0E0), width: 1.5)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Color(0xffE0E0E0), width: 1)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Color(0xffE0E0E0), width: 2))),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<RemoteConfig> setupRemoteConfig() async {
    final RemoteConfig remoteConfig = await RemoteConfig.instance;
    remoteConfig.setDefaults(<String, dynamic>{
      FirebaseConfig.otpEnabled: false,
    });

    try {
      await remoteConfig.fetch(expiration: Duration(minutes: 5));
      await remoteConfig.activateFetched();
    } catch (exception) {}

    return remoteConfig;
  }
}
