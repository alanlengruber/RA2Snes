import QtQuick
import QtTest
import CustomModels 1.0
import TestSupport 1.0

TestCase {
    name: "MainWindow"
    when: windowShown

    property var window: null

    function init() {
        failOnWarning(/.*/);
    }

    function cleanup() {
        if (window) {
            window.close();
            window.destroy();
            window = null;
        }
    }

    // Como o main.cpp faz depois do login: a janela principal, sem pai.
    function openMainWindow() {
        var component = Qt.createComponent("../../ui/mainwindow.qml");
        compare(component.status, Component.Ready, component.errorString());
        window = component.createObject(null);
        verify(window !== null);
        window.show();
        tryVerify(function() { return findChild(window.contentItem, "userName") !== null; }, 3000,
                  "dashboard loaded into the main window");
        return window;
    }

    function spyOn(target) {
        var spy = createTemporaryQmlObject('import QtTest; SignalSpy { signalName: "shown" }', this);
        spy.target = target;
        return spy;
    }

    function dashboardOf(w) {
        var d = findChild(w.contentItem, "dashboard");
        verify(d !== null, "dashboard in main window");
        return d;
    }

    // Critério 12: Compact=true de um settings.ini antigo vira cards densos.
    function test_compact_setting_gives_dense_cards() {
        TestHooks.setCompact(true);
        try {
            compare(dashboardOf(openMainWindow()).dense, true);
        } finally {
            TestHooks.setCompact(false);
        }
    }

    // O item "Compact Cards" do menu troca mainWindow.dense.
    function test_density_toggle_updates_dashboard() {
        var w = openMainWindow();
        var d = dashboardOf(w);
        compare(d.dense, false);
        w.dense = true;
        compare(d.dense, true);
        compare(dashboardOf(w), d, "toggle must not rebuild the dashboard");
    }

    // Critério 11: um tema de terceiro, escrito antes dos tokens novos, carrega
    // sem nenhum warning e os cards caem nas cores do contrato antigo.
    function test_legacy_theme_loads_with_fallback_colors() {
        TestHooks.setTheme("LegacyDark");
        try {
            var w = openMainWindow();
            Ra2snes.emitGameLoaded();
            var grid = null;
            var d = dashboardOf(w);
            // Primeiro card do grid: cardBackgroundColor ausente → mainWindowLightAccentColor.
            tryVerify(function() {
                grid = findCard(d);
                return grid !== null;
            }, 3000, "a card rendered");
            compare(grid.color, Qt.color("#282828"));

            // O toast também cai nos fallbacks: borda dourada do contrato antigo.
            var feed = findChild(w.contentItem, "unlockToasts");
            var spy = spyOn(feed);
            Ra2snes.emitGameLoaded();
            TestHooks.emitMastered();
            compare(spy.count, 1);
            verify(feed._current !== null);
            compare(feed._current.border.color, Qt.color("#eab308"));
        } finally {
            TestHooks.setTheme("Dark");
        }
    }

    function findCard(item) {
        for (var i = 0; i < item.children.length; ++i) {
            var c = item.children[i];
            if (c.hasOwnProperty("achievementLink") && c.opacity > 0)
                return c;
            var inner = findCard(c);
            if (inner)
                return inner;
        }
        if (item.contentItem && item.contentItem !== item)
            return findCard(item.contentItem);
        return null;
    }

    // O C++ checa "masterizado" antes de liberar o setup: isso não é conquista ao vivo.
    function test_game_awards_ignored_before_setup() {
        var w = openMainWindow();
        var spy = spyOn(findChild(w.contentItem, "unlockToasts"));
        verify(!w.setupFinished);
        TestHooks.emitMastered();
        compare(spy.count, 0);
    }

    // Final review I3: desconectar ou voltar ao menu desliga o setup, o que
    // esconde o hud e limpa os ícones de challenge que ficariam presos na tela.
    function test_cleared_game_resets_setup() {
        var w = openMainWindow();
        Ra2snes.emitGameLoaded();
        verify(w.setupFinished);
        Ra2snes.emitGameCleared();
        verify(!w.setupFinished, "setup still marked finished after the game was cleared");
    }

    // Final review I6: zoom reflui as colunas como num navegador, em vez de
    // empurrar o menu para fora da janela.
    function test_zoom_keeps_menu_on_screen() {
        var w = openMainWindow();
        var group = findChild(w.contentItem, "mainGroup");
        var menu = findChild(w.contentItem, "menuButton");
        verify(group !== null && menu !== null);
        group.scale = 1.25;
        waitForRendering(w.contentItem);
        var right = menu.mapToItem(null, menu.width, 0).x;
        verify(right <= w.width, "menu ends at " + right + " in a " + w.width + "px window");
        fuzzyCompare(dashboardOf(w).width * group.scale, w.width, 1);
    }

    function windowRect(item) {
        var p = item.mapToItem(null, 0, 0);
        var q = item.mapToItem(null, item.width, item.height);
        return { left: Math.min(p.x, q.x), top: Math.min(p.y, q.y),
                 right: Math.max(p.x, q.x), bottom: Math.max(p.y, q.y) };
    }

    // Teste no Windows: o cartão do jogo ficava por baixo do botão do menu.
    function test_menu_button_does_not_cover_game_card() {
        var w = openMainWindow();
        Ra2snes.emitGameLoaded();
        var game = findChild(w.contentItem, "gameHeader");
        var menu = findChild(w.contentItem, "menuButton");
        tryVerify(function() { return game.visible && game.width > 0; });
        var g = windowRect(game), m = windowRect(menu);
        var overlaps = g.left < m.right && m.left < g.right && g.top < m.bottom && m.top < g.bottom;
        verify(!overlaps, "menu " + JSON.stringify(m) + " covers game card " + JSON.stringify(g));
    }

    function test_loads_dashboard_without_warnings() {
        openMainWindow();
    }

    function test_live_unlock_toasts_after_setup() {
        var w = openMainWindow();
        var feed = findChild(w.contentItem, "unlockToasts");
        verify(feed !== null, "main window has an unlock toast feed");
        var spy = spyOn(feed);

        Ra2snes.emitGameLoaded();
        verify(w.setupFinished);
        verify(TestHooks.unlock(1005));

        compare(spy.count, 1);
        compare(spy.signalArguments[0][0].title, "Krow's Nest");
    }

    // Desligar "Window Icons" esconde o hud dos ícones de challenge; as
    // notificações de conquista não podem ir junto.
    function test_toasts_survive_window_icons_off() {
        var w = openMainWindow();
        var feed = findChild(w.contentItem, "unlockToasts");
        verify(feed !== null, "main window has an unlock toast feed");
        var spy = spyOn(feed);

        Ra2snes.emitGameLoaded();
        w.allowIcons = false;
        verify(TestHooks.unlock(1007));

        compare(spy.count, 1);
        verify(feed.visible, "toast feed hidden together with the challenge icons");
    }
}
