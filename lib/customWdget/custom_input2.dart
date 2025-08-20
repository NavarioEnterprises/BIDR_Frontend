import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/Constants.dart';


class CustomInput2 extends StatelessWidget {
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final FocusNode focusNode;
  TextEditingController? controller;
  final TextInputAction textInputAction;
  final bool isPasswordField;
  final Widget? prefix;
  final Widget? suffix;

  CustomInput2(
      {super.key,
      required this.hintText,
      required this.onChanged,
      required this.onSubmitted,
      required this.focusNode,
      required this.textInputAction,
      required this.isPasswordField,
      this.controller,
      this.prefix,
      this.suffix});

  @override
  Widget build(BuildContext context) {
    //bool isPasswordField = isPasswordField1;
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(4)),
      ),
      padding: const EdgeInsets.only(left: 2, right: 2, top: 8, bottom: 8),
      width: MediaQuery.of(context).size.width,
      height: 64,
      child: TextField(
        obscureText: isPasswordField,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        controller: controller,
        textInputAction: textInputAction,
/*        validator: (val) {
            return RegExp(
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                .hasMatch(val!)
                ? null
                : "Please Enter Correct Email";
          },*/
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          prefixIcon: prefix,
          suffixIcon: suffix,
          hintStyle: GoogleFonts.inter(
            textStyle: const TextStyle(
              fontSize: 12.5,
              color: Colors.grey,
              letterSpacing: 0,
              fontWeight: FontWeight.w500,
              fontFamily: 'YuGothic',
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.55)),
            borderRadius: BorderRadius.circular(4),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Constants.ctaColorLight),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontFamily: 'YuGothic',
            fontSize: 13.5),
      ),
    );
  }
}

class CustomInputTransparent extends StatelessWidget {
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final FocusNode focusNode;
  TextEditingController? controller;
  final TextInputAction textInputAction;
  final bool isPasswordField;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxLines;
  final bool? integersOnly;

  CustomInputTransparent({
    super.key,
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    required this.focusNode,
    required this.textInputAction,
    required this.isPasswordField,
    this.controller,
    this.prefix,
    this.suffix,
    this.maxLines,
    this.integersOnly,
  });

  @override
  Widget build(BuildContext context) {
    //bool isPasswordField = isPasswordField;
    return Container(
      decoration: const BoxDecoration(
        // border: Border.all(color: ,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32)),

        color: Colors.white,
      ),
      padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0),
      width: MediaQuery.of(context).size.width,
      height: 45,
      child: TextField(
        obscureText: isPasswordField,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        controller: controller,
        textInputAction: textInputAction,
/*        validator: (val) {
            return RegExp(
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                .hasMatch(val!)
                ? null
                : "Please Enter Correct Email";
          },*/
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          prefixIcon: prefix,
          suffixIcon: suffix,
          hintStyle: GoogleFonts.inter(
            textStyle: const TextStyle(
              fontSize: 13.5,
              color: Colors.grey,
              letterSpacing: 0,
              fontWeight: FontWeight.w500,
              fontFamily: 'YuGothic',
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
          enabledBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Colors.grey.withOpacity(0.45), width: 0.5),
            borderRadius: BorderRadius.circular(32),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Constants.ctaColorLight),
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        style: GoogleFonts.lato(
          textStyle: const TextStyle(
              fontSize: 13.5,
              letterSpacing: 0,
              fontWeight: FontWeight.w500,
              fontFamily: 'YuGothic',
              color: Colors.black),
        ),
      ),
    );
  }
}

class CustomInputTransparent1 extends StatelessWidget {
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final FocusNode focusNode;
  TextEditingController? controller;
  final TextInputAction textInputAction;
  final bool isPasswordField;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxLines;
  final bool? integersOnly;
  final bool? isEditable;

  CustomInputTransparent1({
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    required this.focusNode,
    required this.textInputAction,
    required this.isPasswordField,
    this.controller,
    this.prefix,
    this.suffix,
    this.maxLines,
    this.integersOnly,
    this.isEditable,
  });

  @override
  Widget build(BuildContext context) {
    bool _isPasswordField = isPasswordField;
    return Container(
      padding: EdgeInsets.only(left: 2, right: 2, top: 8, bottom: 0),
      width: MediaQuery.of(context).size.width,
      height: 55,
      child: TextField(
        obscureText: _isPasswordField,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        controller: controller,
        maxLines: 1,
        enabled: isEditable ?? true,
        textInputAction: textInputAction,
/*        validator: (val) {
            return RegExp(
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                .hasMatch(val!)
                ? null
                : "Please Enter Correct Email";
          },*/
        inputFormatters: integersOnly == true
            ? <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ]
            : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          prefixIcon: prefix,
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.grey.withOpacity(0.1),
          hintStyle: GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: 13.5,
              color: Colors.grey,
              letterSpacing: 0,
              fontWeight: FontWeight.w300,
              fontFamily: 'YuGothic',
            ),
          ),
          contentPadding: EdgeInsets.only(left: 16, top: 16),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(360),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(360),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xffED7D32)),
            borderRadius: BorderRadius.circular(360),
          ),
        ),
        style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontFamily: 'YuGothic',
            fontSize: 13.5),
      ),
    );
  }
}

class CustomInputTransparentID extends StatefulWidget {
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final Function(bool) onIsSAIDChanged;
  final FocusNode focusNode;
  final TextEditingController? controller;
  final TextInputAction textInputAction;
  final bool isPasswordField;

  CustomInputTransparentID({
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    required this.onIsSAIDChanged,
    required this.focusNode,
    this.controller,
    required this.textInputAction,
    required this.isPasswordField,
  });

  @override
  _CustomInputTransparentIDState createState() =>
      _CustomInputTransparentIDState();
}

class _CustomInputTransparentIDState extends State<CustomInputTransparentID> {
  bool isSAID = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(360),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                textInputAction: widget.textInputAction,
                obscureText: widget.isPasswordField,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(bottom: 6),
                  border: InputBorder.none,
                  hintText: isSAID ? "ID Number" : "Passport Number",
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'YuGothic',
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'YuGothic',
                ),
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(360),
            onTap: () {
              setState(() {
                isSAID = !isSAID;
                widget.onIsSAIDChanged(isSAID);
              });
            },
            child: Container(
              height: 46,
              width: 74,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(360),
                  bottomRight: Radius.circular(360),
                ),
                color:
                    isSAID ? Constants.ftaColorLight : Constants.ctaColorLight,
              ),
              child: Center(
                child: Text(
                  isSAID ? "SA ID" : "Passport",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomInputTransparentID2 extends StatefulWidget {
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final Function(bool) onIsSAIDChanged;
  final FocusNode focusNode;
  final TextEditingController? controller;
  final TextInputAction textInputAction;
  final bool isPasswordField;

  CustomInputTransparentID2({
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    required this.onIsSAIDChanged,
    required this.focusNode,
    this.controller,
    required this.textInputAction,
    required this.isPasswordField,
  });

  @override
  _CustomInputTransparentID2State createState() =>
      _CustomInputTransparentID2State();
}

class _CustomInputTransparentID2State extends State<CustomInputTransparentID2> {
  bool isSAID = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.55)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                textInputAction: widget.textInputAction,
                obscureText: widget.isPasswordField,
                inputFormatters: isSAID
                    ? [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(13),
                      ]
                    : null,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(bottom: 4),
                  border: InputBorder.none,
                  hintText: isSAID ? "ID Number" : "Passport Number",
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'YuGothic',
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'YuGothic',
                ),
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                isSAID = !isSAID;
                widget.onIsSAIDChanged(isSAID);
              });
            },
            child: Container(
              height: 46,
              width: 74,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                color:
                    isSAID ? Constants.ftaColorLight : Constants.ctaColorLight,
              ),
              child: Center(
                child: Text(
                  isSAID ? "SA ID" : "Passport",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomInputMaxCover extends StatefulWidget {
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final Function(String) calculateMaxCover; // Function to calculate max cover
  final FocusNode focusNode;
  final TextEditingController? controller;
  final TextInputAction textInputAction;
  final bool isPasswordField;

  CustomInputMaxCover({
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    required this.calculateMaxCover,
    required this.focusNode,
    this.controller,
    required this.textInputAction,
    required this.isPasswordField,
  });

  @override
  _CustomInputMaxCoverState createState() => _CustomInputMaxCoverState();
}

class _CustomInputMaxCoverState extends State<CustomInputMaxCover> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(360),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                textInputAction: widget.textInputAction,
                obscureText: widget.isPasswordField,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(bottom: 6),
                  border: InputBorder.none,
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'YuGothic',
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'YuGothic',
                ),
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(360),
            onTap: () async {
              print("Max Cover Calculating");
              if (widget.controller != null &&
                  widget.controller!.text.isNotEmpty) {
                String idNumber = widget.controller!.text;
                String maxCover = await widget.calculateMaxCover(idNumber);
                print("Max Cover: $maxCover");
                setState(() {
                  widget.controller!.text = maxCover;
                });
              }
            },
            child: Container(
              height: 46,
              width: 74,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(360),
                  bottomRight: Radius.circular(360),
                ),
                color: Constants.ctaColorLight,
              ),
              child: const Center(
                child: Text(
                  "Check",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomInputTransparent2 extends StatefulWidget {
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final FocusNode focusNode;
  final TextEditingController? controller;
  final TextInputAction textInputAction;
  final bool isPasswordField;
  final Widget? prefix;
  final int? maxLines;
  final bool? integersOnly;

  CustomInputTransparent2({
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    required this.focusNode,
    required this.textInputAction,
    required this.isPasswordField,
    this.controller,
    this.prefix,
    this.maxLines,
    this.integersOnly,
  });

  @override
  _CustomInputTransparent2State createState() =>
      _CustomInputTransparent2State();
}

class _CustomInputTransparent2State extends State<CustomInputTransparent2> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 2, right: 2, top: 8, bottom: 0),
      width: MediaQuery.of(context).size.width,
      height: 55,
      child: TextField(
        obscureText: widget.isPasswordField && !_isPasswordVisible,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        controller: widget.controller,
        maxLines: 1,
        textInputAction: widget.textInputAction,
        inputFormatters: widget.integersOnly == true
            ? <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ]
            : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          prefixIcon: widget.prefix,
          suffixIcon: widget.isPasswordField
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.withOpacity(0.5),
          hintStyle: GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: 13,
              color: Colors.black38,
              letterSpacing: 0,
              fontWeight: FontWeight.w500,
              fontFamily: 'YuGothic',
            ),
          ),
          contentPadding: EdgeInsets.only(left: 16, top: 16),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.0)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xffED7D32)),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        style: TextStyle(
          color: Colors.black,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          fontFamily: 'YuGothic',
        ),
      ),
    );
  }
}

class CustomInputTransparentOption extends StatelessWidget {
  final String hintText, labelText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final FocusNode focusNode;
  TextEditingController? controller;
  final TextInputAction textInputAction;
  final bool isPasswordField;
  final Widget? prefix;
  final Widget? suffix;

  CustomInputTransparentOption(
      {super.key,
      required this.hintText,
      required this.onChanged,
      required this.onSubmitted,
      required this.focusNode,
      required this.textInputAction,
      required this.isPasswordField,
      this.controller,
      this.prefix,
      this.suffix,
      required this.labelText});

  @override
  Widget build(BuildContext context) {
    //bool isPasswordField = isPasswordField;
    return Container(
      decoration: const BoxDecoration(
        // border: Border.all(color: ,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(4)),

        color: Colors.white,
      ),
      padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0),
      width: MediaQuery.of(context).size.width,
      height: 45,
      child: TextField(
        obscureText: isPasswordField,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        controller: controller,
        textInputAction: textInputAction,
/*        validator: (val) {
            return RegExp(
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                .hasMatch(val!)
                ? null
                : "Please Enter Correct Email";
          },*/
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          labelText: labelText,
          prefixIcon: prefix,
          suffixIcon: suffix,
          hintStyle: GoogleFonts.inter(
            textStyle: const TextStyle(
              fontSize: 13.5,
              color: Colors.grey,
              letterSpacing: 0,
              fontWeight: FontWeight.w500,
              fontFamily: 'YuGothic',
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
          enabledBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Colors.grey.withOpacity(0.45), width: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Constants.ctaColorLight),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        style: GoogleFonts.lato(
          textStyle: const TextStyle(
              fontSize: 13.5,
              letterSpacing: 0,
              fontWeight: FontWeight.w500,
              fontFamily: 'YuGothic',
              color: Colors.black),
        ),
      ),
    );
  }
}

class MultilineInputTransparent extends StatelessWidget {
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final FocusNode focusNode;
  TextEditingController? controller;
  final TextInputAction textInputAction;
  final bool isPasswordField;
  final Widget? prefix;
  final Widget? suffix;

  MultilineInputTransparent(
      {required this.hintText,
      required this.onChanged,
      required this.onSubmitted,
      required this.focusNode,
      required this.textInputAction,
      required this.isPasswordField,
      this.controller,
      this.prefix,
      this.suffix});

  @override
  Widget build(BuildContext context) {
    bool _isPasswordField = isPasswordField;
    return Container(
      padding: EdgeInsets.only(left: 2, right: 2, top: 8, bottom: 0),
      width: MediaQuery.of(context).size.width,
      child: TextField(
        obscureText: _isPasswordField,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        controller: controller,
        textInputAction: textInputAction,
        maxLines: 8,
        minLines: 7,
/*        validator: (val) {
            return RegExp(
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                .hasMatch(val!)
                ? null
                : "Please Enter Correct Email";
          },*/
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          prefixIcon: prefix,
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.grey.withOpacity(0.1),
          hintStyle: GoogleFonts.inter(
            textStyle: TextStyle(
                fontSize: 13.5,
                color: Colors.grey,
                letterSpacing: 0,
                fontWeight: FontWeight.w500),
          ),
          contentPadding: EdgeInsets.only(top: 16, left: 12),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.0)),
            borderRadius: BorderRadius.circular(16),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xffED7D32)),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        style: TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13.5),
      ),
    );
  }
}

class CustomInputTransparent3 extends StatefulWidget {
  final bool? allow_editing;
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final FocusNode focusNode;
  final TextEditingController? controller;
  final TextInputAction textInputAction;
  final bool isPasswordField;
  final Widget? prefix;
  Widget? suffix;
  final int? maxLines;
  final bool? integersOnly;
  final bool? isName; // ✅ New property for name validation

  CustomInputTransparent3({
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    required this.focusNode,
    required this.textInputAction,
    required this.isPasswordField,
    this.controller,
    this.prefix,
    this.maxLines,
    this.suffix,
    this.integersOnly,
    this.allow_editing,
    this.isName = false, // ✅ Default to false
  });

  @override
  _CustomInputTransparent3State createState() =>
      _CustomInputTransparent3State();
}

class _CustomInputTransparent3State extends State<CustomInputTransparent3> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 2, right: 2, top: 8, bottom: 0),
      width: MediaQuery.of(context).size.width,
      height: 55,
      child: TextField(
        obscureText: widget.isPasswordField && !_isPasswordVisible,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        enabled: widget.allow_editing,
        onSubmitted: widget.onSubmitted,
        controller: widget.controller,
        maxLines: 1,
        textInputAction: widget.textInputAction,

        // ✅ Apply input validation
        inputFormatters: widget.isName == true
            ? <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s]")),
              ]
            : widget.integersOnly == true
                ? <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'^\+?[0-9]*$')),
                  ]
                : null,

        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          prefixIcon: widget.prefix,
          suffixIcon: widget.suffix != null
              ? widget.suffix
              : widget.isPasswordField
                  ? IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    )
                  : null,
          filled: true,
          fillColor: Colors.transparent,
          hintStyle: GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              letterSpacing: 0,
              fontWeight: FontWeight.w300,
              fontFamily: 'YuGothic',
            ),
          ),
          contentPadding: EdgeInsets.only(left: 16, top: 16),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.55)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xffED7D32)),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        style: TextStyle(
          color: Colors.black,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          fontFamily: 'YuGothic',
        ),
      ),
    );
  }
}

class CustomInputTransparent4 extends StatefulWidget {
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final FocusNode focusNode;
  final TextEditingController? controller;
  final TextInputAction textInputAction;
  final bool isPasswordField;
  final Widget? prefix;
  Widget? suffix;
  final int? maxLines;
  final bool? integersOnly;
  final String? labelText;
  final bool? isEditable;

  CustomInputTransparent4({
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    required this.focusNode,
    required this.textInputAction,
    required this.isPasswordField,
    this.controller,
    this.prefix,
    this.maxLines,
    this.suffix,
    this.integersOnly,
    this.labelText,
    this.isEditable,
  });

  @override
  _CustomInputTransparent4State createState() =>
      _CustomInputTransparent4State();
}

class _CustomInputTransparent4State extends State<CustomInputTransparent4> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 2, right: 2, top: 8, bottom: 0),
      width: MediaQuery.of(context).size.width,
      height: 55,
      child: TextField(
        enabled: widget.isEditable ?? true,
        obscureText: widget.isPasswordField && !_isPasswordVisible,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        controller: widget.controller,
        maxLines: 1,
        textInputAction: widget.textInputAction,
        inputFormatters: widget.integersOnly == true
            ? <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ]
            : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          labelText: widget.labelText,
          prefixIcon: widget.prefix,
          suffixIcon: widget.suffix != null
              ? widget.suffix
              : widget.isPasswordField
                  ? IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    )
                  : null,
          filled: true,
          fillColor: Colors.transparent,
          hintStyle: GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: 13,
              color: Colors.black38,
              letterSpacing: 0,
              fontWeight: FontWeight.w500,
              fontFamily: 'YuGothic',
            ),
          ),
          labelStyle: TextStyle(
            color: Colors.black,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            fontFamily: 'YuGothic',
          ),
          contentPadding: EdgeInsets.only(left: 16, top: 16),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(36),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.55)),
            borderRadius: BorderRadius.circular(36),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xffED7D32)),
            borderRadius: BorderRadius.circular(36),
          ),
        ),
        style: TextStyle(
          color: Colors.black,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          fontFamily: 'YuGothic',
        ),
      ),
    );
  }
}

class CustomInputSquare extends StatefulWidget {
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final FocusNode focusNode;
  TextEditingController? controller;
  final TextInputAction textInputAction;
  final bool isPasswordField;
  final bool? integersOnly;

  CustomInputSquare(
      {required this.hintText,
      required this.onChanged,
      required this.onSubmitted,
      required this.focusNode,
      required this.textInputAction,
      required this.isPasswordField,
      this.controller,
      this.integersOnly});

  @override
  State<CustomInputSquare> createState() => _CustomInputSquareState();
}

class _CustomInputSquareState extends State<CustomInputSquare> {
  bool _isPasswordHidden = true;

  @override
  Widget build(BuildContext context) {
    bool _isPasswordField = widget.isPasswordField;

    return Container(
        decoration: MediaQuery.of(context).size.width < 500
            ? BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8)),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.75),
                ),
              )
            : MediaQuery.of(context).size.width < 1100 &&
                    MediaQuery.of(context).size.width < 1100
                ? BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.35),
                        spreadRadius: 2,
                        blurRadius: 2,
                        offset: Offset(0, 4), // changes position of shadow
                      ),
                    ],
                    color: Color(0xffFFFFFF),
                  )
                : BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        spreadRadius: 2,
                        blurRadius: 2,
                        offset: Offset(0, 4), // changes position of shadow
                      ),
                    ],
                    color: Color(0xffFFFFFF),
                  ),
        padding: EdgeInsets.only(
            left: 2,
            right: 2,
            top: _isPasswordField == true ? 2 : 0,
            bottom: _isPasswordField == true ? 10 : 0),
        width: MediaQuery.of(context).size.width,
        height: 45,
        child: TextField(
          obscureText: (_isPasswordField == true && _isPasswordHidden == true)
              ? true
              : false,
          onChanged: widget.onChanged,
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType:
              widget.integersOnly == false ? null : TextInputType.number,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: widget.hintText,
            hintStyle: GoogleFonts.nunito(
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                letterSpacing: 0,
                fontWeight: FontWeight.normal,
              ),
            ),
            contentPadding: EdgeInsets.only(left: 16.0, bottom: 9.0),
            suffixIcon: _isPasswordField == true
                ? IconButton(
                    icon: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Icon(
                        _isPasswordHidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Constants.ctaColorLight,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordHidden = !_isPasswordHidden;
                        print("_isPasswordHidden ${_isPasswordHidden}");
                      });
                    },
                  )
                : null,
          ),
          style: GoogleFonts.inter(
            textStyle: TextStyle(
                fontSize: 13.5,
                color: Colors.black,
                letterSpacing: 0,
                fontWeight: FontWeight.w500),
          ),
        ));
  }
}

class CustomInputTransparent3b extends StatefulWidget {
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final FocusNode focusNode;
  final TextEditingController? controller;
  final TextInputAction textInputAction;
  final bool isPasswordField;
  final Widget? prefix;
  final int? maxLines;
  final bool? integersOnly;

  CustomInputTransparent3b({
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    required this.focusNode,
    required this.textInputAction,
    required this.isPasswordField,
    this.controller,
    this.prefix,
    this.maxLines,
    this.integersOnly,
  });

  @override
  _CustomInputTransparent3bState createState() =>
      _CustomInputTransparent3bState();
}

class _CustomInputTransparent3bState extends State<CustomInputTransparent3b> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 2, right: 2, top: 8, bottom: 0),
      width: MediaQuery.of(context).size.width,
      height: 55,
      child: TextField(
        obscureText: widget.isPasswordField && !_isPasswordVisible,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        controller: widget.controller,
        maxLines: widget.maxLines ?? 1,
        textInputAction: widget.textInputAction,
        inputFormatters: widget.integersOnly == true
            ? <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ]
            : null,
        decoration: InputDecoration(
          prefixIcon: widget.prefix,
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.blue[900]!.withOpacity(0.55),
            fontWeight: FontWeight.w500,
            fontFamily: 'YuGothic',
            fontSize: 14,
          ),
          suffixIcon: widget.isPasswordField
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(360),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(360),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(360),
            borderSide: const BorderSide(color: Color(0xffED7D32), width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          contentPadding: const EdgeInsets.only(left: 16, top: 16),
        ),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'YuGothic',
        ),
      ),
    );
  }
}
