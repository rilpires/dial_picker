library duration_picker;

import 'dart:math';

import 'package:flutter/material.dart';

const Duration _kDialAnimateDuration = Duration(milliseconds: 200);

class _DialPainter extends CustomPainter {
  final List<TextPainter> labels;
  final Color? backgroundColor;
  final Color accentColor;
  final double theta;
  final TextDirection textDirection;
  final int? selectedValue;
  final BuildContext context;

  final double pct;
  final int baseUnitMultiplier;
  final int baseUnitHand;
  final BaseUnit baseUnit;

  const _DialPainter({
    required this.context,
    required this.labels,
    required this.backgroundColor,
    required this.accentColor,
    required this.theta,
    required this.textDirection,
    required this.selectedValue,
    required this.pct,
    required this.baseUnitMultiplier,
    required this.baseUnitHand,
    required this.baseUnit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const epsilon = .001;
    const sweep = (2 * pi) - epsilon;
    const startAngle = -pi / 2.0;

    final radius = size.shortestSide / 2.0;
    final center = Offset(size.width / 2.0, size.height / 2.0);
    final centerPoint = center;

    var pctTheta = (0.25 - (theta % (2 * pi)) / (2 * pi)) % 1.0;

    // Draw the background outer ring
    canvas.drawCircle(centerPoint, radius, Paint()..color = backgroundColor!);

    // Draw a translucent circle for every secondary unit
    for (var i = 0; i < baseUnitMultiplier; i = i + 1) {
      canvas.drawCircle(centerPoint, radius,
          Paint()..color = accentColor.withOpacity((i == 0) ? 0.3 : 0.1));
    }

    // Draw the inner background circle
    canvas.drawCircle(centerPoint, radius * 0.88,
        Paint()..color = Theme.of(context).canvasColor);

    // Get the offset point for an angle value of theta, and a distance of _radius
    Offset getOffsetForTheta(double theta, double radius) {
      return center + Offset(radius * cos(theta), -radius * sin(theta));
    }

    // Draw the handle that is used to drag and to indicate the position around the circle
    final handlePaint = Paint()..color = accentColor;
    final handlePoint = getOffsetForTheta(theta, radius - 10.0);
    canvas.drawCircle(handlePoint, 20.0, handlePaint);

    // Get the appropriate base unit string
    String getBaseUnitString() {
      switch (baseUnit) {
        case BaseUnit.millisecond:
          return 'ms.';
        case BaseUnit.second:
          return 'sec.';
        case BaseUnit.minute:
          return 'min.';
        case BaseUnit.hour:
          return 'hr.';
      }
    }

    // Get the appropriate secondary unit string
    String getSecondaryUnitString() {
      switch (baseUnit) {
        case BaseUnit.millisecond:
          return 's ';
        case BaseUnit.second:
          return 'm ';
        case BaseUnit.minute:
          return 'h ';
        case BaseUnit.hour:
          return 'd ';
      }
    }

    // Draw the Text in the center of the circle which displays the duration string
    var secondaryUnits = (baseUnitMultiplier == 0)
        ? ''
        : '$baseUnitMultiplier${getSecondaryUnitString()} ';
    var baseUnits = '$baseUnitHand';

    var textDurationValuePainter = TextPainter(
        textAlign: TextAlign.center,
        text: TextSpan(
            text: '$secondaryUnits$baseUnits',
            style: Theme.of(context)
                .textTheme
                .headline2!
                .copyWith(fontSize: size.shortestSide * 0.15)),
        textDirection: TextDirection.ltr)
      ..layout();
    var middleForValueText = Offset(
        centerPoint.dx - (textDurationValuePainter.width / 2),
        centerPoint.dy - textDurationValuePainter.height / 2);
    textDurationValuePainter.paint(canvas, middleForValueText);

    var textMinPainter = TextPainter(
        textAlign: TextAlign.center,
        text: TextSpan(
            text: getBaseUnitString(), //th: ${theta}',
            style: Theme.of(context).textTheme.bodyText2),
        textDirection: TextDirection.ltr)
      ..layout();
    textMinPainter.paint(
        canvas,
        Offset(
            centerPoint.dx - (textMinPainter.width / 2),
            centerPoint.dy +
                (textDurationValuePainter.height / 2) -
                textMinPainter.height / 2));

    // Draw an arc around the circle for the amount of the circle that has elapsed.
    var elapsedPainter = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = accentColor.withOpacity(0.3)
      ..isAntiAlias = true
      ..strokeWidth = radius * 0.12;

    canvas.drawArc(
      Rect.fromCircle(
        center: centerPoint,
        radius: radius - radius * 0.12 / 2,
      ),
      startAngle,
      sweep * pctTheta,
      false,
      elapsedPainter,
    );

    // Thin line pointing to current angle
    canvas.drawLine(
        center,
        handlePoint,
        Paint()
          ..style = PaintingStyle.fill
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4
          ..color = accentColor.withOpacity(0.3)
          ..isAntiAlias = true);

    // Paint the labels (the minute strings)
    void paintLabels(List<TextPainter> labels) {
      final labelThetaIncrement = -(2 * pi) / labels.length;
      var labelTheta = (pi * 0.5);

      for (var label in labels) {
        final labelOffset = Offset(-label.width / 2.0, -label.height / 2.0);

        label.paint(
            canvas, getOffsetForTheta(labelTheta, radius - 40.0) + labelOffset);

        labelTheta += labelThetaIncrement;
      }
    }

    paintLabels(labels);
  }

  @override
  bool shouldRepaint(_DialPainter oldPainter) {
    return oldPainter.labels != labels ||
        oldPainter.backgroundColor != backgroundColor ||
        oldPainter.accentColor != accentColor ||
        oldPainter.theta != theta;
  }
}

class Dial extends StatefulWidget {
  const Dial(
      {super.key,
      required this.startDuration,
      required this.onChanged,
      this.baseUnit = BaseUnit.minute,
      this.snapToMins = 1.0});

  final Duration startDuration;
  final ValueChanged<Duration> onChanged;
  final BaseUnit baseUnit;

  /// The resolution of mins of the dial, i.e. if snapToMins = 5.0, only durations of 5min intervals will be selectable.
  final double? snapToMins;

  @override
  DialState createState() => DialState();
}

class DialState extends State<Dial> with SingleTickerProviderStateMixin {
  late Tween<double> _thetaTween;
  late Animation<double> _theta;
  late AnimationController _thetaController;

  final double _pct = 0.0;
  int _secondaryUnitValue = 0;
  bool _dragging = false;
  int _baseUnitValue = 0;
  double _turningAngle = 0.0;

  late ThemeData themeData;
  MaterialLocalizations? localizations;
  MediaQueryData? media;
  Offset? _position;
  Offset? _center;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(debugCheckHasMediaQuery(context));
    themeData = Theme.of(context);
    localizations = MaterialLocalizations.of(context);
    media = MediaQuery.of(context);
  }

  @override
  void dispose() {
    _thetaController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _thetaController = AnimationController(
      duration: _kDialAnimateDuration,
      vsync: this,
    );
    _thetaTween = Tween<double>(
        begin: _getThetaForDuration(widget.startDuration, widget.baseUnit));
    _theta = _thetaTween.animate(
        CurvedAnimation(parent: _thetaController, curve: Curves.fastOutSlowIn))
      ..addListener(() => setState(() {}));
    _thetaController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _secondaryUnitValue = _secondaryUnitHand();
        _baseUnitValue = _baseUnitHand();
        setState(() {});
      }
    });

    _turningAngle = (pi * 0.5) - _turningAngleFactor() * (2 * pi);
    _secondaryUnitValue = _secondaryUnitHand();
    _baseUnitValue = _baseUnitHand();
  }

  static double _nearest(double target, double a, double b) {
    return ((target - a).abs() < (target - b).abs()) ? a : b;
  }

  void _animateTo(double targetTheta) {
    final currentTheta = _theta.value;
    var beginTheta =
        _nearest(targetTheta, currentTheta, currentTheta + (2 * pi));
    beginTheta = _nearest(targetTheta, beginTheta, currentTheta - (2 * pi));
    _thetaTween
      ..begin = beginTheta
      ..end = targetTheta;
    _thetaController
      ..value = 0.0
      ..forward();
  }

  // Converts the duration to the chosen base unit. For example, for base unit minutes, this gets the number of minutes
  // in the duration
  int _getDurationInBaseUnits(Duration duration, BaseUnit baseUnit) {
    switch (baseUnit) {
      case BaseUnit.millisecond:
        return duration.inMilliseconds;
      case BaseUnit.second:
        return duration.inSeconds;
      case BaseUnit.minute:
        return duration.inMinutes;
      case BaseUnit.hour:
        return duration.inHours;
    }
  }

  // Converts the duration to the chosen secondary unit. For example, for base unit minutes, this gets the number
  // of hours in the duration
  int _getDurationInSecondaryUnits(Duration duration, BaseUnit baseUnit) {
    switch (baseUnit) {
      case BaseUnit.millisecond:
        return duration.inSeconds;
      case BaseUnit.second:
        return duration.inMinutes;
      case BaseUnit.minute:
        return duration.inHours;
      case BaseUnit.hour:
        return duration.inDays;
    }
  }

  // Gets the relation between the base unit and the secondary unit, which is the unit just greater than the base unit.
  // For example if the base unit is second, it will get the number of seconds in a minute
  int _getBaseUnitToSecondaryUnitFactor(BaseUnit baseUnit) {
    switch (baseUnit) {
      case BaseUnit.millisecond:
        return Duration.millisecondsPerSecond;
      case BaseUnit.second:
        return Duration.secondsPerMinute;
      case BaseUnit.minute:
        return Duration.minutesPerHour;
      case BaseUnit.hour:
        return Duration.hoursPerDay;
    }
  }

  double _getThetaForDuration(Duration duration, BaseUnit baseUnit) {
    int baseUnits = _getDurationInBaseUnits(duration, baseUnit);
    int baseToSecondaryFactor = _getBaseUnitToSecondaryUnitFactor(baseUnit);

    return ((pi * 0.5) -
            (baseUnits % baseToSecondaryFactor) /
                baseToSecondaryFactor.toDouble() *
                (2 * pi)) %
        (2 * pi);
  }

  double _turningAngleFactor() {
    return _getDurationInBaseUnits(widget.startDuration, widget.baseUnit) /
        _getBaseUnitToSecondaryUnitFactor(widget.baseUnit);
  }

  Duration _getTimeForTheta(double theta) {
    return _angleToDuration(_turningAngle);
  }

  Duration _notifyOnChangedIfNeeded() {
    _secondaryUnitValue = _secondaryUnitHand();
    _baseUnitValue = _baseUnitHand();
    var d = _angleToDuration(_turningAngle);
    widget.onChanged(d);

    return d;
  }

  void _updateThetaForPan() {
    setState(() {
      final offset = _position! - _center!;
      final angle = (atan2(offset.dx, offset.dy) - (pi * 0.5)) % (2 * pi);

      // Stop accidental abrupt pans from making the dial seem like it starts from 1h.
      // (happens when wanting to pan from 0 clockwise, but when doing so quickly, one actually pans from before 0 (e.g. setting the duration to 59mins, and then crossing 0, which would then mean 1h 1min).
      if (angle >= (pi * 0.5) &&
          _theta.value <= (pi * 0.5) &&
          _theta.value >= 0.1 && // to allow the radians sign change at 15mins.
          _secondaryUnitValue == 0) return;

      _thetaTween
        ..begin = angle
        ..end = angle;
    });
  }

  void _handlePanStart(DragStartDetails details) {
    assert(!_dragging);
    _dragging = true;
    final box = context.findRenderObject() as RenderBox;
    _position = box.globalToLocal(details.globalPosition);
    _center = box.size.center(Offset.zero);

    _notifyOnChangedIfNeeded();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    var oldTheta = _theta.value;
    _position = _position! + details.delta;
    // _position! += details.delta;
    _updateThetaForPan();
    var newTheta = _theta.value;

    _updateTurningAngle(oldTheta, newTheta);
    _notifyOnChangedIfNeeded();
  }

  int _secondaryUnitHand() {
    return _getDurationInSecondaryUnits(widget.startDuration, widget.baseUnit);
  }

  int _baseUnitHand() {
    // Result is in [0; num base units in secondary unit - 1], even if overall time is >= 1 secondary unit
    return _getDurationInBaseUnits(widget.startDuration, widget.baseUnit) %
        _getBaseUnitToSecondaryUnitFactor(widget.baseUnit);
  }

  Duration _angleToDuration(double angle) {
    return _baseUnitToDuration(_angleToBaseUnit(angle));
  }

  Duration _baseUnitToDuration(baseUnitValue) {
    int unitFactor = _getBaseUnitToSecondaryUnitFactor(widget.baseUnit);

    switch (widget.baseUnit) {
      case BaseUnit.millisecond:
        return Duration(
            seconds: (baseUnitValue ~/ unitFactor).toInt(),
            milliseconds: (baseUnitValue % unitFactor.toDouble()).toInt());
      case BaseUnit.second:
        return Duration(
            minutes: (baseUnitValue ~/ unitFactor).toInt(),
            seconds: (baseUnitValue % unitFactor.toDouble()).toInt());
      case BaseUnit.minute:
        return Duration(
            hours: (baseUnitValue ~/ unitFactor).toInt(),
            minutes: (baseUnitValue % unitFactor.toDouble()).toInt());
      case BaseUnit.hour:
        return Duration(
            days: (baseUnitValue ~/ unitFactor).toInt(),
            hours: (baseUnitValue % unitFactor.toDouble()).toInt());
    }
  }

  String _durationToBaseUnitString(Duration duration) {
    switch (widget.baseUnit) {
      case BaseUnit.millisecond:
        return duration.inMilliseconds.toString();
      case BaseUnit.second:
        return duration.inSeconds.toString();
      case BaseUnit.minute:
        return duration.inMinutes.toString();
      case BaseUnit.hour:
        return duration.inHours.toString();
    }
  }

  double _angleToBaseUnit(double angle) {
    // Coordinate transformation from mathematical COS to dial COS
    var dialAngle = (pi * 0.5) - angle;

    // Turn dial angle into minutes, may go beyond 60 minutes (multiple turns)
    return dialAngle /
        (2 * pi) *
        _getBaseUnitToSecondaryUnitFactor(widget.baseUnit);
  }

  void _updateTurningAngle(double oldTheta, double newTheta) {
    // Register any angle by which the user has turned the dial.
    //
    // The resulting turning angle fully captures the state of the dial,
    // including multiple turns (= full hours). The [_turningAngle] is in
    // mathematical coordinate system, i.e. 3-o-clock position being zero, and
    // increasing counter clock wise.

    // From positive to negative (in mathematical COS)
    if (newTheta > 1.5 * pi && oldTheta < 0.5 * pi) {
      _turningAngle = _turningAngle - (((2 * pi) - newTheta) + oldTheta);
    }
    // From negative to positive (in mathematical COS)
    else if (newTheta < 0.5 * pi && oldTheta > 1.5 * pi) {
      _turningAngle = _turningAngle + (((2 * pi) - oldTheta) + newTheta);
    } else {
      _turningAngle = _turningAngle + (newTheta - oldTheta);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    assert(_dragging);
    _dragging = false;
    _position = null;
    _center = null;
    _animateTo(_getThetaForDuration(widget.startDuration, widget.baseUnit));
  }

  void _handleTapUp(TapUpDetails details) {
    final box = context.findRenderObject() as RenderBox;
    _position = box.globalToLocal(details.globalPosition);
    _center = box.size.center(Offset.zero);
    _updateThetaForPan();
    _notifyOnChangedIfNeeded();

    _animateTo(
        _getThetaForDuration(_getTimeForTheta(_theta.value), widget.baseUnit));
    _dragging = false;
    _position = null;
    _center = null;
  }

  List<TextPainter> _buildBaseUnitLabels(TextTheme textTheme) {
    final style = textTheme.subtitle1;

    var baseUnitMarkerValues = <Duration>[];

    switch (widget.baseUnit) {
      case BaseUnit.millisecond:
        int interval = 100;
        int factor = Duration.millisecondsPerSecond;
        int length = factor ~/ interval;
        baseUnitMarkerValues = List.generate(
            length, (index) => Duration(milliseconds: index * interval));
        break;
      case BaseUnit.second:
        int interval = 5;
        int factor = Duration.secondsPerMinute;
        int length = factor ~/ interval;
        baseUnitMarkerValues = List.generate(
            length, (index) => Duration(seconds: index * interval));
        break;
      case BaseUnit.minute:
        int interval = 5;
        int factor = Duration.minutesPerHour;
        int length = factor ~/ interval;
        baseUnitMarkerValues = List.generate(
            length, (index) => Duration(minutes: index * interval));
        break;
      case BaseUnit.hour:
        int interval = 3;
        int factor = Duration.hoursPerDay;
        int length = factor ~/ interval;
        baseUnitMarkerValues =
            List.generate(length, (index) => Duration(hours: index * interval));
        break;
    }

    final labels = <TextPainter>[];
    for (var duration in baseUnitMarkerValues) {
      var painter = TextPainter(
        text: TextSpan(style: style, text: _durationToBaseUnitString(duration)),
        textDirection: TextDirection.ltr,
      )..layout();
      labels.add(painter);
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    switch (themeData.brightness) {
      case Brightness.light:
        backgroundColor = Colors.grey[200];
        break;
      case Brightness.dark:
        backgroundColor = themeData.backgroundColor;
        break;
    }

    final theme = Theme.of(context);

    int? selectedDialValue;
    _secondaryUnitValue = _secondaryUnitHand();
    _baseUnitValue = _baseUnitHand();

    return GestureDetector(
        excludeFromSemantics: true,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        onTapUp: _handleTapUp,
        child: CustomPaint(
          painter: _DialPainter(
            pct: _pct,
            baseUnitMultiplier: _secondaryUnitValue,
            baseUnitHand: _baseUnitValue,
            baseUnit: widget.baseUnit,
            context: context,
            selectedValue: selectedDialValue,
            labels: _buildBaseUnitLabels(theme.textTheme),
            backgroundColor: backgroundColor,
            accentColor: themeData.colorScheme.secondary,
            theta: _theta.value,
            textDirection: Directionality.of(context),
          ),
        ));
  }
}

enum BaseUnit { millisecond, second, minute, hour }

extension BaseUnitExtension on BaseUnit {
  String get baseUnitString {
    switch (this) {
      case BaseUnit.millisecond:
        return 'ms.';
      case BaseUnit.second:
        return 'sec.';
      case BaseUnit.minute:
        return 'min.';
      case BaseUnit.hour:
        return 'hr.';
    }
  }

  String get secondaryUnitString {
    switch (this) {
      case BaseUnit.millisecond:
        return 's ';
      case BaseUnit.second:
        return 'm ';
      case BaseUnit.minute:
        return 'h ';
      case BaseUnit.hour:
        return 'd ';
    }
  }

  int get upperUnitFactor {
    switch (this) {
      case BaseUnit.millisecond:
        return Duration.millisecondsPerSecond;
      case BaseUnit.second:
        return Duration.secondsPerMinute;
      case BaseUnit.minute:
        return Duration.minutesPerHour;
      case BaseUnit.hour:
        return Duration.hoursPerDay;
    }
  }
}
