import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class WebTableColumn {
  const WebTableColumn({
    required this.label,
    this.width,
    this.flex,
    this.align = Alignment.centerLeft,
    this.headAlign,
  });

  final String label;
  final double? width;
  final int? flex;
  final Alignment align;
  final Alignment? headAlign;
}

class WebDataTable extends StatelessWidget {
  const WebDataTable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.cellBuilder,
    required this.decoration,
    required this.headStyle,
    this.onRowTap,
    this.rowHeight = 48,
    this.headHeight = 36,
    this.scrollable = false,
    this.scrollPadding = EdgeInsets.zero,
    this.cellPadding = const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
  });

  final List<WebTableColumn> columns;
  final int rowCount;
  final Widget Function(BuildContext context, int row, int column) cellBuilder;
  final Decoration decoration;
  final TextStyle headStyle;
  final VoidCallback? Function(int row)? onRowTap;
  final double rowHeight;
  final double headHeight;
  final bool scrollable;
  final EdgeInsets scrollPadding;
  final EdgeInsets cellPadding;

  @override
  Widget build(BuildContext context) {
    final table = Container(
      decoration: decoration,
      // antiAliasWithSaveLayer: on web, plain antiAlias lets the opaque header
      // background bleed past the rounded corners (surface vs surfaceCard) —
      // the save layer clips the children cleanly so the corners stay rounded.
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Column(
        children: [
          _HeaderRow(
            columns: columns,
            headStyle: headStyle,
            height: headHeight,
            cellPadding: cellPadding,
          ),
          if (scrollable)
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: rowCount,
                itemBuilder: (context, row) => RepaintBoundary(
                  child: _DataRow(
                    columns: columns,
                    row: row,
                    rowCount: rowCount,
                    height: rowHeight,
                    cellPadding: cellPadding,
                    onTap: onRowTap?.call(row),
                    cellBuilder: cellBuilder,
                  ),
                ),
              ),
            )
          else
            for (var row = 0; row < rowCount; row++)
              RepaintBoundary(
                child: _DataRow(
                  columns: columns,
                  row: row,
                  rowCount: rowCount,
                  height: rowHeight,
                  cellPadding: cellPadding,
                  onTap: onRowTap?.call(row),
                  cellBuilder: cellBuilder,
                ),
              ),
        ],
      ),
    );

    if (!scrollable || scrollPadding == EdgeInsets.zero) return table;
    return Padding(padding: scrollPadding, child: table);
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.columns,
    required this.headStyle,
    required this.height,
    required this.cellPadding,
  });

  final List<WebTableColumn> columns;
  final TextStyle headStyle;
  final double height;
  final EdgeInsets cellPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildCells(
          columns,
          (column, _) => Padding(
            padding: cellPadding,
            child: Align(
              alignment: column.headAlign ?? column.align,
              child: Text(
                column.label.toUpperCase(),
                style: headStyle,
                // Cho header xuống 2 dòng thay vì cắt cụt khi cột hẹp hơn nhãn
                // (vd "MINIMUM VERSION" trong cột 120px). Header vừa 1 dòng thì
                // không đổi; chỉ header quá dài mới wrap.
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.columns,
    required this.row,
    required this.rowCount,
    required this.height,
    required this.cellPadding,
    required this.cellBuilder,
    this.onTap,
  });

  final List<WebTableColumn> columns;
  final int row;
  final int rowCount;
  final double height;
  final EdgeInsets cellPadding;
  final Widget Function(BuildContext context, int row, int column) cellBuilder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final last = row == rowCount - 1;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        hoverColor: AppColors.surfaceSubtle,
        onTap: onTap,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            border: last ? null : const Border(bottom: BorderSide(color: AppColors.outlineMuted)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildCells(
              columns,
              (column, index) => Padding(
                padding: cellPadding,
                child: Align(
                  alignment: column.align,
                  child: cellBuilder(context, row, index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> _buildCells(
  List<WebTableColumn> columns,
  Widget Function(WebTableColumn column, int index) builder,
) {
  final cells = <Widget>[];
  for (var i = 0; i < columns.length; i++) {
    final column = columns[i];
    final child = builder(column, i);
    cells.add(
      column.width != null
          ? SizedBox(width: column.width, child: child)
          : Expanded(flex: column.flex ?? 1, child: child),
    );
    if (i != columns.length - 1) {
      cells.add(_vCellDivider());
    }
  }
  return cells;
}

Widget _vCellDivider() => Container(width: 1, color: AppColors.outlineMuted);
