// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icon.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'icons.dart';
import 'list_tile.dart';
import 'theme.dart';
import 'theme_data.dart';

const Duration _kExpand = const Duration(milliseconds: 200);

/// An item in a [TwoLevelList] or a [TwoLevelSublist].
///
/// A two-level list item is similar to a [ListTile], but a two-level list item
/// automatically sizes itself to fit properly within its ancestor
/// [TwoLevelList].
///
/// See also:
///
///  * [TwoLevelList]
///  * [TwoLevelSublist]
///  * [ListTile]
class TwoLevelListItem extends StatelessWidget {
  /// Creates an item in a two-level list.
  const TwoLevelListItem({
    Key key,
    this.leading,
    @required this.title,
    this.trailing,
    this.enabled: true,
    this.onTap,
    this.onLongPress
  }) : assert(title != null),
       super(key: key);

  /// A widget to display before the title.
  ///
  /// Typically a [CircleAvatar] widget.
  final Widget leading;

  /// The primary content of the list item.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// A widget to display after the title.
  ///
  /// Typically an [Icon] widget.
  final Widget trailing;

  /// Whether this list item is interactive.
  ///
  /// If false, this list item is styled with the disabled color from the
  /// current [Theme] and the [onTap] and [onLongPress] callbacks are
  /// inoperative.
  final bool enabled;

  /// Called when the user taps this list item.
  ///
  /// Inoperative if [enabled] is false.
  final GestureTapCallback onTap;

  /// Called when the user long-presses on this list item.
  ///
  /// Inoperative if [enabled] is false.
  final GestureLongPressCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final TwoLevelList parentList = context.ancestorWidgetOfExactType(TwoLevelList);
    assert(parentList != null);

    return new SizedBox(
      height: kListTileExtent[parentList.type],
      child: new ListTile(
        leading: leading,
        title: title,
        trailing: trailing,
        enabled: enabled,
        onTap: onTap,
        onLongPress: onLongPress
      )
    );
  }
}

/// An item in a [TwoLevelList] that can expand and collapse.
///
/// A two-level sublist is similar to a [ListTile], but the trailing widget is
/// a button that expands or collapses a sublist of items.
///
/// See also:
///
///  * [TwoLevelList]
///  * [TwoLevelListItem]
///  * [ListTile]
class TwoLevelSublist extends StatefulWidget {
  /// Creates an item in a two-level list that can expland and collapse.
  const TwoLevelSublist({
    Key key,
    this.leading,
    @required this.title,
    this.backgroundColor,
    this.onOpenChanged,
    this.children: const <Widget>[],
  }) : super(key: key);

  /// A widget to display before the title.
  ///
  /// Typically a [CircleAvatar] widget.
  final Widget leading;

  /// The primary content of the list item.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// Called when the sublist expands or collapses.
  ///
  /// When the sublist starts expanding, this function is called with the value
  /// `true`. When the sublist starts collapsing, this function is called with
  /// the value false.
  final ValueChanged<bool> onOpenChanged;

  /// The widgets that are displayed when the sublist expands.
  ///
  /// Typically [TwoLevelListItem] widgets.
  final List<Widget> children;

  /// The color to display behind the sublist when expanded.
  final Color backgroundColor;

  @override
  _TwoLevelSublistState createState() => new _TwoLevelSublistState();
}

class _TwoLevelSublistState extends State<TwoLevelSublist> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  CurvedAnimation _easeOutAnimation;
  CurvedAnimation _easeInAnimation;
  ColorTween _borderColor;
  ColorTween _headerColor;
  ColorTween _iconColor;
  ColorTween _backgroundColor;
  Animation<double> _iconTurns;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(duration: _kExpand, vsync: this);
    _easeOutAnimation = new CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _easeInAnimation = new CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _borderColor = new ColorTween(begin: Colors.transparent);
    _headerColor = new ColorTween();
    _iconColor = new ColorTween();
    _iconTurns = new Tween<double>(begin: 0.0, end: 0.5).animate(_easeInAnimation);
    _backgroundColor = new ColorTween();

    _isExpanded = PageStorage.of(context)?.readState(context) ?? false;
    if (_isExpanded)
      _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleOnTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded)
        _controller.forward();
      else
        _controller.reverse();
      PageStorage.of(context)?.writeState(context, _isExpanded);
    });
    if (widget.onOpenChanged != null)
      widget.onOpenChanged(_isExpanded);
  }

  Widget buildList(BuildContext context, Widget child) {
    return new Container(
      decoration: new BoxDecoration(
        color: _backgroundColor.evaluate(_easeOutAnimation),
        border: new Border(
          top: new BorderSide(color: _borderColor.evaluate(_easeOutAnimation)),
          bottom: new BorderSide(color: _borderColor.evaluate(_easeOutAnimation))
        )
      ),
      child: new Column(
        children: <Widget>[
          IconTheme.merge(
            data: new IconThemeData(color: _iconColor.evaluate(_easeInAnimation)),
            child: new TwoLevelListItem(
              onTap: _handleOnTap,
              leading: widget.leading,
              title: new DefaultTextStyle(
                style: Theme.of(context).textTheme.subhead.copyWith(color: _headerColor.evaluate(_easeInAnimation)),
                child: widget.title
              ),
              trailing: new RotationTransition(
                turns: _iconTurns,
                child: const Icon(Icons.expand_more)
              )
            )
          ),
          new ClipRect(
            child: new Align(
              heightFactor: _easeInAnimation.value,
              child: new Column(children: widget.children)
            )
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    _borderColor.end = theme.dividerColor;
    _headerColor
      ..begin = theme.textTheme.subhead.color
      ..end = theme.accentColor;
    _iconColor
      ..begin = theme.unselectedWidgetColor
      ..end = theme.accentColor;
    _backgroundColor
      ..begin = Colors.transparent
      ..end = widget.backgroundColor ?? Colors.transparent;

    return new AnimatedBuilder(
      animation: _controller.view,
      builder: buildList
    );
  }
}

/// A scrollable list of items that can expand and collapse.
///
/// See also:
///
///  * [TwoLevelSublist]
///  * [TwoLevelListItem]
///  * [ListView], for lists that only have one level.
class TwoLevelList extends StatelessWidget {
  /// Creates a scrollable list of items that can expand and collapse.
  ///
  /// The [type] argument must not be null.
  const TwoLevelList({
    Key key,
    this.children: const <Widget>[],
    this.type: MaterialListType.twoLine,
    this.padding
  }) : assert(type != null),
       super(key: key);

  /// The widgets to display in this list.
  ///
  /// Typically [TwoLevelListItem] or [TwoLevelSublist] widgets.
  final List<Widget> children;

  /// The kind of [ListTile] contained in this list.
  final MaterialListType type;

  /// The amount of space by which to inset the children inside the viewport.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return new ListView(
      padding: padding,
      shrinkWrap: true,
      children: KeyedSubtree.ensureUniqueKeysForList(children),
    );
  }
}
