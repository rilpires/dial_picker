// ignore_for_file: unused_element

import 'package:dial_picker/dial_picker.dart';
import 'package:flutter/material.dart';

const double _kDialPickerWidthPortrait = 328.0;
const double _kDialPickerHeightPortrait = 380;
const double _kDialPickerWidthLandscape = 512.0;
const double _kDialPickerHeightLandscape = 304.0;

Future<Duration?> showDialPicker({
  required BuildContext context,
  required Duration initialTime,
  BaseUnit baseUnit = BaseUnit.minute,
  double? snapToMins,
}) async {
  return await showDialog<Duration>(
    context: context,
    builder: (BuildContext context) => _DialPickerDialog(
      initialTime: initialTime,
      baseUnit: baseUnit,
      snapToMins: snapToMins,
    ),
  );
}

class _DialPickerDialog extends StatefulWidget {
  /// The duration initially selected when the dialog is shown.
  final Duration initialTime;
  final double? snapToMins;
  final BaseUnit baseUnit;

  /// Creates a duration picker.
  ///
  /// [initialTime] must not be null.
  const _DialPickerDialog(
      {Key? key,
      required this.initialTime,
      this.snapToMins = 1,
      this.baseUnit = BaseUnit.minute})
      : super(key: key);

  @override
  _DialPickerDialogState createState() => _DialPickerDialogState();
}

class _DialPickerDialogState extends State<_DialPickerDialog> {
  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.initialTime;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localizations = MaterialLocalizations.of(context);
  }

  Duration get selectedDuration => _selectedDuration;
  Duration _selectedDuration = Duration.zero;

  late MaterialLocalizations localizations;

  void _handleTimeChanged(Duration value) {
    setState(() {
      _selectedDuration = value;
    });
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  void _handleOk() {
    Navigator.pop(context, _selectedDuration);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final ThemeData theme = Theme.of(context);

    final Widget picker = Padding(
        padding: const EdgeInsets.all(16.0),
        child: AspectRatio(
            aspectRatio: 1.0,
            child: Dial(
              baseUnit: widget.baseUnit,
              startDuration: _selectedDuration,
              onChanged: _handleTimeChanged,
              snapToMins: widget.snapToMins,
            )));

    final Widget actions = ButtonBar(children: <Widget>[
      ElevatedButton(
          onPressed: _handleCancel,
          child: Text(localizations.cancelButtonLabel)),
      ElevatedButton(
          onPressed: _handleOk, child: Text(localizations.okButtonLabel)),
    ]);

    final Dialog dialog = Dialog(child: OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
      final Widget pickerAndActions = Container(
        color: theme.dialogBackgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
                child:
                    picker), // picker grows and shrinks with the available space
            actions,
          ],
        ),
      );

      switch (orientation) {
        case Orientation.portrait:
          return SizedBox(
              width: _kDialPickerWidthPortrait,
              height: _kDialPickerHeightPortrait,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: pickerAndActions,
                    ),
                  ]));
        case Orientation.landscape:
          return SizedBox(
              width: _kDialPickerWidthLandscape,
              height: _kDialPickerHeightLandscape,
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Flexible(
                      child: pickerAndActions,
                    ),
                  ]));
      }
    }));

    return Theme(
      data: theme.copyWith(
        dialogBackgroundColor: Colors.transparent,
      ),
      child: dialog,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
