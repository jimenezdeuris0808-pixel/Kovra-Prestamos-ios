import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo corporativo de Kovra, reutilizado en Login y Recibo de Pago.
class KovraLogo extends StatelessWidget {
  const KovraLogo({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo_kovra_corporativo.svg',
      height: height,
    );
  }
}
