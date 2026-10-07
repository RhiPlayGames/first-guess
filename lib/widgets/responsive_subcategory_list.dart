import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const double _desktopSubcategoryBreakpoint = 1200;

bool isDesktopSubcategoryLayout(BuildContext context) {
  return kIsWeb &&
      MediaQuery.sizeOf(context).width >= _desktopSubcategoryBreakpoint;
}

double subcategoryTitleFontSize(BuildContext context) {
  return isDesktopSubcategoryLayout(context) ? 24 : 18.5;
}

double subcategoryProgressFontSize(BuildContext context) {
  return isDesktopSubcategoryLayout(context) ? 16.5 : 14.5;
}

class ResponsiveSubcategoryPage extends StatelessWidget {
  const ResponsiveSubcategoryPage({
    super.key,
    required this.header,
    required this.statsPanel,
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 28),
  });

  final Widget header;
  final Widget statsPanel;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final bool useDesktopLayout = isDesktopSubcategoryLayout(context);
    final Widget list = ResponsiveSubcategoryList(
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: separatorBuilder,
      itemBuilder: itemBuilder,
      desktopHeader: useDesktopLayout
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[header, statsPanel],
            )
          : null,
    );

    if (useDesktopLayout) {
      return list;
    }

    return Column(
      children: <Widget>[
        header,
        statsPanel,
        Expanded(child: list),
      ],
    );
  }
}

class ResponsiveSubcategoryList extends StatelessWidget {
  const ResponsiveSubcategoryList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 28),
    this.desktopHeader,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;
  final EdgeInsetsGeometry padding;
  final Widget? desktopHeader;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useDesktopGrid =
            kIsWeb && constraints.maxWidth >= _desktopSubcategoryBreakpoint;

        if (!useDesktopGrid) {
          return ListView.separated(
            padding: padding,
            itemCount: itemCount,
            separatorBuilder: separatorBuilder,
            itemBuilder: itemBuilder,
          );
        }

        return CustomScrollView(
          slivers: <Widget>[
            if (desktopHeader != null)
              SliverToBoxAdapter(child: desktopHeader),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 32),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 112,
                ),
                delegate: SliverChildBuilderDelegate(
                  itemBuilder,
                  childCount: itemCount,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
