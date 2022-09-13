import 'package:clock_picker/clock_picker.dart';
import 'package:flutter/material.dart';

const double _kClockPickerWidthPortrait = 328.0;
const double _kClockPickerHeightPortrait = 380;
const double _kClockPickerWidthLandscape = 512.0;
const double _kClockPickerHeightLandscape = 304.0;

Future<Duration?> showClockPicker(
    {required BuildContext context,
    required Duration initialTime,
    double? snapToMins}) async {
  return await showDialog<Duration>(
    context: context,
    builder: (BuildContext context) =>
        _ClockPickerDialog(initialTime: initialTime, snapToMins: snapToMins),
  );
}

class _ClockPickerDialog extends StatefulWidget {
  /// The duration initially selected when the dialog is shown.
  final Duration initialTime;
  final double? snapToMins;

  /// Creates a duration picker.
  ///
  /// [initialTime] must not be null.
  const _ClockPickerDialog(
      {Key? key, required this.initialTime, this.snapToMins = 1})
      : super(key: key);

  @override
  _ClockPickerDialogState createState() => _ClockPickerDialogState();
}

class _ClockPickerDialogState extends State<_ClockPickerDialog> {
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
              width: _kClockPickerWidthPortrait,
              height: _kClockPickerHeightPortrait,
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
              width: _kClockPickerWidthLandscape,
              height: _kClockPickerHeightLandscape,
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
