import 'package:flutter/material.dart';

import 'brand.dart';
import 'tide_transition.dart';

/// "Where's your beach day?" search field with the yellow "Find it ↗︎" button.
class SearchBox extends StatefulWidget {
  const SearchBox({super.key});

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  final _text = TextEditingController();

  void _submit() {
    final q = _text.text.trim();
    if (q.isNotEmpty) openBeach(context, q);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: Brand.chunky(shadow: 4),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _text,
              maxLength: 100,
              onSubmitted: (_) => _submit(),
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 16, color: Brand.ink),
              decoration: const InputDecoration(
                hintText: 'Where’s your beach day?',
                counterText: '',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Find it',
            child: InkWell(
              onTap: _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: const BoxDecoration(
                  color: Brand.yellow,
                  border: Border(left: BorderSide(color: Brand.ink, width: 3)),
                ),
                child: const Text('Find it ↗︎', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ]),
      );
}
