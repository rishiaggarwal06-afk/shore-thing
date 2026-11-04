import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'brand.dart';

/// Builds the same illustrated shoreline SVG as the prototype's scene(n, view).
/// [palette] picks one of 3 sky/water colour sets; [view] 0 = umbrella right,
/// 1 = umbrella left, 2 = umbrella right + sailboat.
String sceneSvg(int palette, int view) {
  const skies = ['#aee2df', '#ffd28a', '#b8d5ed'], waters = ['#27a6aa', '#43b9ba', '#4b91ac'];
  final sky = skies[palette % 3], water = waters[palette % 3];
  final sunX = 710 - view * 170;
  final umbX = view == 1 ? 90 : 660, umbY = view == 2 ? 275 : 370, umbRot = view == 1 ? -15 : 12;
  final boat = view == 2
      ? '<path d="M100 460l65-160 20 165" fill="#FF7F50"/><path d="M165 300l90 166-70-1" fill="#FFE14D"/>'
          '<path d="M65 465h230l-45 25H95Z" fill="#123d40"/>'
      : '';
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 900 600">'
      '<rect width="900" height="600" fill="$sky"/>'
      '<circle cx="$sunX" cy="115" r="61" fill="#FFE14D"/>'
      '<path d="M0 240Q150 205 300 240T600 238T900 245V600H0Z" fill="$water"/>'
      '<path d="M0 338Q200 270 420 330T900 320" fill="none" stroke="#fff8db" stroke-width="10" opacity=".8"/>'
      '<path d="M0 470Q180 330 450 407T900 360V600H0Z" fill="#f8d693"/>'
      '<path d="M0 463Q170 324 450 400T900 352" fill="none" stroke="#fff9e9" stroke-width="17"/>'
      '<path d="M0 502Q200 390 430 453T900 411" fill="none" stroke="#eabb78" stroke-width="3"/>'
      '<g transform="translate($umbX,$umbY) rotate($umbRot)">'
      '<path d="M0 0V145" stroke="#815e3a" stroke-width="7"/>'
      '<path d="M-83 0A83 76 0 0 1 83 0Z" fill="#FF7F50"/>'
      '<path d="M0-76Q-35-45-29 0H29Q35-45 0-76" fill="#fff2bb"/></g>'
      '<g fill="#123d40" opacity=".7">'
      '<path d="M100 100q15-16 30 0q15-16 30 0q-15-7-30 5q-15-12-30-5"/>'
      '<path d="M190 150q10-12 20 0q10-12 20 0q-10-4-20 4q-10-8-20-4"/></g>'
      '$boat</svg>';
}

class BeachScene extends StatelessWidget {
  const BeachScene({super.key, required this.palette, required this.view, required this.label});
  final int palette;
  final int view;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: label,
        child: Container(
          decoration: Brand.chunky(shadow: 0),
          child: AspectRatio(aspectRatio: 3 / 2, child: SvgPicture.string(sceneSvg(palette, view), fit: BoxFit.cover)),
        ),
      );
}
