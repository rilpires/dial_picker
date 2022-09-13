import 'package:flutter/material.dart';
import 'dart:math';

const Duration _kDialAnimateDuration = Duration(milliseconds: 200);

class DialPainter extends CustomPainter {
  final List<TextPainter> labels;
  final Color backgroundColor;
  final Color accentColor;
  final double angle;
  final TextDirection textDirection;
  final int selectedValue;
  final BuildContext context;

  final int multiplier;
  final int minuteHand;

  const DialPainter({
    required this.context,
    required this.labels,
    required this.backgroundColor,
    required this.accentColor,
    required this.angle,
    required this.textDirection,
    required this.selectedValue,
    required this.multiplier,
    required this.minuteHand,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double epsilon = .001;
    const double sweep = (2 * pi) - epsilon;
    const double startAngle = -pi / 2.0;

    final double radius = size.shortestSide / 2.0;
    final Offset center = Offset(size.width / 2.0, size.height / 2.0);
    final Offset centerPoint = center;

    double pctAngle = (0.25 - (angle % (2 * pi)) / (2 * pi)) % 1.0;

    // Get the offset point for an angle value of angle, and a distance of _radius
    Offset getOffsetForAngle(double angle, double radius) {
      return center + Offset(radius * cos(angle), -radius * sin(angle));
    }

    // Draw the handle that is used to drag and to indicate the position around the circle
    final Paint handlePaint = Paint()..color = accentColor;
    final Offset handlePoint = getOffsetForAngle(angle, radius - 10.0);

    // Draw the background outer && inner ring
    canvas.drawCircle(centerPoint, radius, Paint()..color = backgroundColor);

    // Draw a translucent circle for every hour
    for (int i = 0; i < multiplier; i = i + 1) {
      canvas.drawCircle(centerPoint, radius,
          Paint()..color = accentColor.withOpacity((i == 0) ? 0.3 : 0.1));
    }

    // Draw the inner background circle
    canvas.drawCircle(centerPoint, radius * 0.88,
        Paint()..color = Theme.of(context).canvasColor);

    canvas.drawCircle(handlePoint, 20.0, handlePaint);

    // Draw the Text in the center of the circle which displays hours and mins
    String hours = (multiplier == 0) ? '' : "${multiplier}h ";
    String minutes = "$minuteHand";

    TextPainter textDurationValuePainter = TextPainter(
        textAlign: TextAlign.center,
        text: TextSpan(
//            text: '${hours}${minutes > 0 ? minutes : ""}',
            text: '$hours$minutes',
            style: Theme.of(context)
                .textTheme
                .displayLarge!
                .copyWith(fontSize: size.shortestSide * 0.15)),
        textDirection: TextDirection.ltr)
      ..layout();
    Offset middleForValueText = Offset(
        centerPoint.dx - (textDurationValuePainter.width / 2),
        centerPoint.dy - textDurationValuePainter.height / 2);
    textDurationValuePainter.paint(canvas, middleForValueText);

    TextPainter textMinPainter = TextPainter(
        textAlign: TextAlign.center,
        text: TextSpan(
            text: 'min.', //th: ${angle}',
            style: Theme.of(context).textTheme.bodySmall),
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
      sweep * pctAngle,
      false,
      elapsedPainter,
    );

    // Paint the labels (the minute strings)
    final double labelAngleIncrement = -(2 * pi) / labels.length;
    double labelAngle = (pi * 0.5);

    for (TextPainter label in labels) {
      final Offset labelOffset =
          Offset(-label.width / 2.0, -label.height / 2.0);

      label.paint(
          canvas, getOffsetForAngle(labelAngle, radius - 40.0) + labelOffset);

      labelAngle += labelAngleIncrement;
    }

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
  }

  @override
  bool shouldRepaint(DialPainter oldDelegate) {
    return oldDelegate.labels != labels ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.angle != angle;
  }
}

class Dial extends StatefulWidget {
  const Dial(
      {super.key,
      required this.startDuration,
      required this.onChanged,
      this.snapToMins = 1.0});

  final Duration startDuration;
  final ValueChanged<Duration> onChanged;

  /// The resolution of mins of the dial, i.e. if snapToMins = 5.0, only durations of 5min intervals will be selectable.
  final double? snapToMins;
  @override
  DialState createState() => DialState();
}

class DialState extends State<Dial> with SingleTickerProviderStateMixin {
  late ThemeData themeData;
  late MaterialLocalizations localizations;
  late MediaQueryData media;
  late Tween<double> _angleTween;
  late Animation<double> _angleAnimation;
  late AnimationController _angleController;
  int _hours = 0;
  bool _dragging = false;
  int _minutes = 0;
  double _cartesianAngle = 0.0;
  late Offset _panPosition;
  late Offset _clockCenter;

  @override
  void initState() {
    super.initState();
    _angleController = AnimationController(
      duration: _kDialAnimateDuration,
      vsync: this,
    );
    _angleTween =
        Tween<double>(begin: _angleFromDuration(widget.startDuration));
    _angleAnimation = _angleTween.animate(
        CurvedAnimation(parent: _angleController, curve: Curves.fastOutSlowIn))
      ..addListener(() => setState(() {}));
    _angleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _hours = _hourHand(_cartesianAngle);
        _minutes = _minuteHand(_cartesianAngle);
        setState(() {});
      }
    });

    _cartesianAngle =
        (pi * 0.5) - widget.startDuration.inMinutes / 60.0 * (2 * pi);
    _hours = _hourHand(_cartesianAngle);
    _minutes = _minuteHand(_cartesianAngle);
  }

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
    _angleController.dispose();
    super.dispose();
  }

  static double _nearest(double target, double a, double b) {
    return ((target - a).abs() < (target - b).abs()) ? a : b;
  }

  void _animateTo(double targetAngle) {
    final double currentAngle = _angleAnimation.value;
    double beginAngle =
        _nearest(targetAngle, currentAngle, currentAngle + (2 * pi));
    beginAngle = _nearest(targetAngle, beginAngle, currentAngle - (2 * pi));
    _angleTween
      ..begin = beginAngle
      ..end = targetAngle;
    _angleController
      ..value = 0.0
      ..forward();
  }

  double _angleFromDuration(Duration duration) {
    return ((pi * 0.5) - (duration.inMinutes % 60) / 60.0 * (2 * pi)) %
        (2 * pi);
  }

  Duration _durationFromAngle(double angle) {
    return _angleToDuration(_cartesianAngle);
  }

  Duration _notifyOnChangedIfNeeded() {
    _hours = _hourHand(_cartesianAngle);
    _minutes = _minuteHand(_cartesianAngle);

    var d = _angleToDuration(_cartesianAngle);

    widget.onChanged(d);

    return d;
  }

  void _setAngleFromPan() {
    final Offset offset = _panPosition - _clockCenter;
    final double angle = (atan2(offset.dx, offset.dy) - (pi * 0.5)) % (2 * pi);

    // Stop accidental abrupt pans from making the dial seem like it starts from 1h.
    // (happens when wanting to pan from 0 clockwise, but when doing so quickly, one actually pans from before 0 (e.g. setting the duration to 59mins, and then crossing 0, which would then mean 1h 1min).
    if (angle >= (pi * 0.5) &&
        _angleAnimation.value <= (pi * 0.5) &&
        // to allow the radians sign change at 15mins.
        _angleAnimation.value >= 0.1 &&
        _hours == 0) return;

    _angleTween
      ..begin = angle
      ..end = angle;
  }

  void _handlePanStart(DragStartDetails details) {
    assert(!_dragging);
    _dragging = true;
    final RenderBox box = context.findRenderObject() as RenderBox;
    _panPosition = box.globalToLocal(details.globalPosition);
    _clockCenter = box.size.center(Offset.zero);

    _notifyOnChangedIfNeeded();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    double oldAngle = _angleAnimation.value;
    _panPosition += details.delta;
    _setAngleFromPan();
    double newAngle = _angleAnimation.value;

    _updateCartesianAngle(oldAngle, newAngle);
    _notifyOnChangedIfNeeded();
    setState(() {});
  }

  int _hourHand(double angle) {
    return _angleToDuration(angle).inHours.toInt();
  }

  int _minuteHand(double angle) {
    // Result is in [0; 59], even if overall time is >= 1 hour
    return (_angleToMinutes(angle) % 60.0).toInt();
  }

  Duration _angleToDuration(double angle) {
    return _minutesToDuration(_angleToMinutes(angle));
  }

  Duration _minutesToDuration(minutes) {
    return Duration(
        hours: (minutes ~/ 60).toInt(), minutes: (minutes % 60.0).toInt());
  }

  double _angleToMinutes(double angle) {
    // Coordinate transformation from mathematical COS to dial COS
    double dialAngle = (pi * 0.5) - angle;

    // Turn dial angle into minutes, may go beyond 60 minutes (multiple turns)
    return dialAngle / (2 * pi) * 60.0;
  }

  void _updateCartesianAngle(double oldAngle, double newAngle) {
    // Register any angle by which the user has turned the dial.
    //
    // The resulting turning angle fully captures the state of the dial,
    // including multiple turns (= full hours). The [_cartesianAngle] is in
    // mathematical coordinate system, i.e. 3-o-clock position being zero, and
    // increasing counter clock wise.

    // From positive to negative (in mathematical COS)
    if (newAngle > 1.5 * pi && oldAngle < 0.5 * pi) {
      _cartesianAngle = _cartesianAngle - (((2 * pi) - newAngle) + oldAngle);
    }
    // From negative to positive (in mathematical COS)
    else if (newAngle < 0.5 * pi && oldAngle > 1.5 * pi) {
      _cartesianAngle = _cartesianAngle + (((2 * pi) - oldAngle) + newAngle);
    } else {
      _cartesianAngle = _cartesianAngle + (newAngle - oldAngle);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_dragging) {
      _dragging = false;
      _panPosition = Offset.zero;
      _clockCenter = Offset.zero;
      _animateTo(_angleFromDuration(widget.startDuration));
    }
  }

  void _handleTapUp(TapUpDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    _panPosition = box.globalToLocal(details.globalPosition);
    _clockCenter = box.size.center(Offset.zero);
    _setAngleFromPan();
    _notifyOnChangedIfNeeded();

    _animateTo(_angleFromDuration(_durationFromAngle(_angleAnimation.value)));
    _dragging = false;
    _panPosition = Offset.zero;
    _clockCenter = Offset.zero;
    setState(() {});
  }

  List<TextPainter> _buildMinutes(TextTheme textTheme) {
    final TextStyle style = textTheme.subtitle1!;

    const List<Duration> minuteMarkerValues = <Duration>[
      Duration(hours: 0, minutes: 0),
      Duration(hours: 0, minutes: 5),
      Duration(hours: 0, minutes: 10),
      Duration(hours: 0, minutes: 15),
      Duration(hours: 0, minutes: 20),
      Duration(hours: 0, minutes: 25),
      Duration(hours: 0, minutes: 30),
      Duration(hours: 0, minutes: 35),
      Duration(hours: 0, minutes: 40),
      Duration(hours: 0, minutes: 45),
      Duration(hours: 0, minutes: 50),
      Duration(hours: 0, minutes: 55),
    ];

    final List<TextPainter> labels = <TextPainter>[];
    for (Duration duration in minuteMarkerValues) {
      var painter = TextPainter(
        text: TextSpan(style: style, text: duration.inMinutes.toString()),
        textDirection: TextDirection.ltr,
      )..layout();
      labels.add(painter);
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    switch (themeData.brightness) {
      case Brightness.light:
        backgroundColor = Colors.grey.shade200;
        break;
      case Brightness.dark:
        backgroundColor = themeData.backgroundColor;
        break;
    }

    final ThemeData theme = Theme.of(context);

    _hours = _hourHand(_cartesianAngle);
    _minutes = _minuteHand(_cartesianAngle);

    return GestureDetector(
        excludeFromSemantics: true,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        onTapUp: _handleTapUp,
        child: CustomPaint(
          painter: DialPainter(
            multiplier: _hours,
            minuteHand: _minutes,
            context: context,
            selectedValue: 0,
            labels: _buildMinutes(theme.textTheme),
            backgroundColor: backgroundColor,
            accentColor: themeData.colorScheme.secondary,
            angle: _angleAnimation.value,
            textDirection: Directionality.of(context),
          ),
        ));
  }
}

enum BaseUnit { millisecond, second, minute, hour }
