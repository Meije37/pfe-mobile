import 'package:flutter/material.dart';

/// Pictogramme d'une catégorie de réclamation, déduit de son nom.
/// Utilisé par la carte de réclamation et le formulaire de dépôt.
IconData iconeCategorie(String nom) {
  final n = nom.toLowerCase();
  if (n.contains('eau') || n.contains('fuite') || n.contains('assainissement')) {
    return Icons.water_drop_outlined;
  }
  if (n.contains('éclairage') || n.contains('eclairage') || n.contains('électri') || n.contains('electri')) {
    return Icons.lightbulb_outline_rounded;
  }
  if (n.contains('route') || n.contains('voirie') || n.contains('chaussée') || n.contains('trottoir')) {
    return Icons.add_road_rounded;
  }
  if (n.contains('déchet') || n.contains('dechet') || n.contains('propreté') || n.contains('ordure')) {
    return Icons.delete_outline_rounded;
  }
  if (n.contains('espace vert') || n.contains('arbre') || n.contains('parc') || n.contains('jardin')) {
    return Icons.park_outlined;
  }
  if (n.contains('bruit') || n.contains('nuisance')) return Icons.volume_up_outlined;
  if (n.contains('sécurité') || n.contains('securite')) return Icons.shield_outlined;
  if (n.contains('transport') || n.contains('stationnement')) return Icons.directions_bus_outlined;
  if (n.contains('santé') || n.contains('sante') || n.contains('hygiène')) return Icons.local_hospital_outlined;
  return Icons.report_outlined;
}
