import 'package:flutter/material.dart';

// Minimal IME repro: the same TextField with enableInteractiveSelection true vs false.
// Every controller change is printed with an IMELOG prefix (text code points,
// selection, composing) so the real iOS Korean keyboard's edit sequence is visible.
void main() => runApp(const MaterialApp(home: Repro()));

class Repro extends StatefulWidget {
  const Repro({super.key});
  @override
  State<Repro> createState() => _ReproState();
}

class _ReproState extends State<Repro> {
  final a = TextEditingController(), b = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final (name, c) in [('A', a), ('B', b)]) {
      c.addListener(() {
        final v = c.value;
        debugPrint('IMELOG $name "${v.text}" sel=${v.selection.start},${v.selection.end} '
            'comp=${v.composing.start},${v.composing.end}');
        setState(() {});
      });
    }
  }

  Widget field(String id, TextEditingController c, bool interactive) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: c,
        enableInteractiveSelection: interactive,
        decoration: InputDecoration(hintText: 'field$id interactive=$interactive'),
      ),
      Semantics(
        identifier: 'out$id',
        label: 'out$id=${c.text}',
        child: Text('out$id=${c.text}'),
      ),
      const SizedBox(height: 24),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [field('A', a, true), field('B', b, false)]),
      ),
    ),
  );
}
