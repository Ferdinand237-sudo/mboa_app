/// Implémenté par les State des écrans affichés dans un IndexedStack
/// (MainScreen, AdminScreen) dont les données sont chargées une seule fois
/// dans initState. Comme IndexedStack garde tous les onglets montés en
/// permanence, revenir sur un onglet ne redéclenche pas initState : l'écran
/// parent appelle refresh() explicitement au moment du changement d'onglet.
mixin RefreshableState {
  Future<void> refresh();
}
