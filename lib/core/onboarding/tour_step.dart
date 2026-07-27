import 'package:flutter/material.dart';

// Une étape de visite guidée : `key` doit être posée par l'écran appelant
// sur le widget réel à mettre en évidence (logo, bouton nav, champ...).
// Portage du `TourStep` web (tours.ts) : `target: string` (sélecteur
// data-tour) devient ici directement une GlobalKey, plus naturel côté
// Flutter qu'un registre de chaînes.
class TourStep {
  final GlobalKey key;
  final String title;
  final String body;

  const TourStep({required this.key, required this.title, required this.body});
}

// Titre + description d'une étape, sans cible : voir tour_texts.dart. Zippé
// avec les GlobalKeys propres à chaque écran via [buildTourSteps].
class TourStepText {
  final String title;
  final String body;

  const TourStepText({required this.title, required this.body});
}

List<TourStep> buildTourSteps(List<GlobalKey?> keys, List<TourStepText> texts) {
  final steps = <TourStep>[];
  for (var i = 0; i < keys.length && i < texts.length; i++) {
    final key = keys[i];
    if (key == null) continue;
    steps.add(TourStep(key: key, title: texts[i].title, body: texts[i].body));
  }
  return steps;
}
