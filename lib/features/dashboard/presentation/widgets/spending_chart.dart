import 'package:flutter/material.dart';

import 'package:rodantex_app/core/theme/rodantex_colors.dart';
import 'package:rodantex_app/core/theme/rodantex_palette.dart';
import 'package:rodantex_app/features/dashboard/data/models/monthly_spending.dart';
import 'package:rodantex_app/features/dashboard/data/models/spending_history.dart';
import 'package:rodantex_app/features/dashboard/presentation/money_formatter.dart';

/// Gráfica de barras agrupadas: compras vs mantenimiento por mes.
///
/// Se dibuja con un [CustomPainter] para no añadir dependencias ni cargar un
/// motor de gráficas. Los colores salen de la paleta: compras en Lime
/// (principal) y mantenimiento en Teal (secundaria).
///
/// Tocar una barra fija el valor de ese mes en la fila de leyenda; volver a
/// tocar fuera de las barras lo limpia.
class SpendingChart extends StatefulWidget {
  const SpendingChart({super.key, required this.history});

  final SpendingHistory history;

  @override
  State<SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<SpendingChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final months = widget.history.months;
    final selected = _selectedIndex != null && _selectedIndex! < months.length
        ? months[_selectedIndex!]
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // En pantallas anchas la leyenda va a la derecha de la gráfica.
        final wide = constraints.maxWidth >= 520;
        final chart = SizedBox(
          height: 190,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => setState(() {
              // El área de barras es `chart`; con leyenda lateral ocupa todo
              // el ancho disponible menos la leyenda y el espacio entre ambos.
              final chartWidth = wide ? constraints.maxWidth - 156 : constraints.maxWidth;
              _selectedIndex = _indexAt(
                details.localPosition.dx,
                chartWidth,
                months.length,
              );
            }),
            child: CustomPaint(
              size: Size.infinite,
              painter: _SpendingChartPainter(
                months: months,
                maxValue: widget.history.maxMonthlyTotal,
                selectedIndex: _selectedIndex,
                gridColor: theme.colorScheme.outlineVariant,
                labelColor: theme.colorScheme.onSurfaceVariant,
                selectedLabelColor: theme.colorScheme.onSurface,
                onLime: RodantexColors.textOnLime,
              ),
            ),
          ),
        );

        final legend = _Legend(
          history: widget.history,
          selected: selected,
          showTotals: !wide,
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: chart),
              const SizedBox(width: 16),
              SizedBox(width: 140, child: legend),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [chart, const SizedBox(height: 12), legend],
        );
      },
    );
  }

  /// Índice del mes tocado; `null` si el toque cayó fuera de las barras.
  ///
  /// El orden coincide con el que usa el painter: grupos de izquierda a derecha,
  /// con un margen del 8 % a cada lado.
  int? _indexAt(double dx, double width, int count) {
    if (count == 0) return null;
    final left = width * 0.06;
    final usable = width * 0.88;
    final groupWidth = usable / count;
    final index = ((dx - left) / groupWidth).floor();
    if (index < 0 || index >= count) return null;
    return index;
  }
}

/// Leyenda con los colores de cada serie y el detalle del mes seleccionado.
class _Legend extends StatelessWidget {
  const _Legend({
    required this.history,
    required this.selected,
    required this.showTotals,
  });

  final SpendingHistory history;
  final MonthlySpending? selected;
  final bool showTotals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = history.currency;
    final month = selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendRow(
          color: RodantexChartColors.primary,
          label: 'Compras',
          value: month == null
              ? MoneyFormatter.format(history.totalPurchases,
                  currency: currency)
              : MoneyFormatter.format(month.purchases, currency: currency),
          caption: month == null ? 'Total' : month.monthLabel,
        ),
        const SizedBox(height: 8),
        _LegendRow(
          color: RodantexChartColors.secondary,
          label: 'Mantenimiento',
          value: month == null
              ? MoneyFormatter.format(history.totalMaintenance,
                  currency: currency)
              : MoneyFormatter.format(month.maintenance, currency: currency),
          caption: month == null ? 'Total' : month.monthLabel,
        ),
        if (showTotals || month != null) ...[
          const SizedBox(height: 10),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 8),
          Text(
            month == null ? 'Gasto total' : 'Gasto de ${month.monthLabel}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            MoneyFormatter.format(
              month?.total ?? history.total,
              currency: currency,
            ),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.caption,
  });

  final Color color;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                caption,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pintor de la gráfica: rejilla, barras agrupadas y etiquetas de mes.
class _SpendingChartPainter extends CustomPainter {
  _SpendingChartPainter({
    required this.months,
    required this.maxValue,
    required this.selectedIndex,
    required this.gridColor,
    required this.labelColor,
    required this.selectedLabelColor,
    required this.onLime,
  });

  final List<MonthlySpending> months;
  final double maxValue;
  final int? selectedIndex;
  final Color gridColor;
  final Color labelColor;
  final Color selectedLabelColor;
  final Color onLime;

  static const _labelArea = 26.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (months.isEmpty) return;

    final plotHeight = size.height - _labelArea;
    final left = size.width * 0.06;
    final usable = size.width * 0.88;
    final groupWidth = usable / months.length;
    final barWidth = (groupWidth * 0.28).clamp(3.0, 18.0);

    _paintGrid(canvas, size, plotHeight);

    for (var i = 0; i < months.length; i++) {
      final month = months[i];
      final center = left + groupWidth * (i + 0.5);
      final isSelected = selectedIndex == i;

      if (isSelected) {
        final highlight = Paint()
          ..color = gridColor.withValues(alpha: 0.45);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              center - groupWidth / 2,
              0,
              groupWidth,
              size.height,
            ),
            const Radius.circular(8),
          ),
          highlight,
        );
      }

      final purchasesHeight = _heightFor(month.purchases, plotHeight);
      final maintenanceHeight = _heightFor(month.maintenance, plotHeight);

      _paintBar(
        canvas,
        x: center - barWidth - 1,
        width: barWidth,
        height: purchasesHeight,
        plotHeight: plotHeight,
        color: RodantexChartColors.primary,
        // El Lime es muy claro: el borde oscuro le da el contraste que exige
        // la paleta cuando la barra es fina.
        border: isSelected ? RodantexColors.textPrimary : null,
      );
      _paintBar(
        canvas,
        x: center + 1,
        width: barWidth,
        height: maintenanceHeight,
        plotHeight: plotHeight,
        color: RodantexChartColors.secondary,
        border: isSelected ? RodantexColors.textPrimary : null,
      );

      _paintMonthLabel(canvas, month.monthLabel, center, size.height, isSelected);
    }
  }

  void _paintGrid(Canvas canvas, Size size, double plotHeight) {
    final line = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    // Base de las barras.
    canvas.drawLine(
      Offset(0, plotHeight),
      Offset(size.width, plotHeight),
      line,
    );
    // Línea media y de cuarto, solo como referencia visual.
    for (final fraction in const [0.25, 0.5, 0.75]) {
      final y = plotHeight * fraction;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        line..color = gridColor.withValues(alpha: 0.5),
      );
    }
  }

  double _heightFor(double value, double plotHeight) {
    if (maxValue <= 0 || value <= 0) return 0;
    return (value / maxValue) * (plotHeight - 8);
  }

  void _paintBar(
    Canvas canvas, {
    required double x,
    required double width,
    required double height,
    required double plotHeight,
    required Color color,
    required Color? border,
  }) {
    if (height <= 0) return;
    final rect = Rect.fromLTWH(x, plotHeight - height, width, height);
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(4),
    );
    canvas.drawRRect(rrect, Paint()..color = color);
    if (border != null) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = border,
      );
    }
  }

  void _paintMonthLabel(
    Canvas canvas,
    String label,
    double centerX,
    double height,
    bool isSelected,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? selectedLabelColor : labelColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(centerX - painter.width / 2, height - _labelArea + 8),
    );
  }

  @override
  bool shouldRepaint(_SpendingChartPainter oldDelegate) =>
      oldDelegate.months != months ||
      oldDelegate.maxValue != maxValue ||
      oldDelegate.selectedIndex != selectedIndex;
}
