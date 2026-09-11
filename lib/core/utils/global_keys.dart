import 'package:flutter/material.dart';

/// Accessible depuis n'importe où (y compris l'intercepteur Dio, qui n'a
/// pas de BuildContext) pour afficher un message global, ex: "Session
/// expirée" au moment d'une déconnexion forcée sur 401.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();