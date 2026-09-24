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
            Ra2snes.emitEnableModeSwitching();
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

    function test_loads_dashboard_without_warnings() {
        openMainWindow();
    }

    function test_live_unlock_toasts_after_setup() {
        var w = openMainWindow();
        var feed = findChild(w.contentItem, "unlockToasts");
        verify(feed !== null, "main window has an unlock toast feed");
        var spy = spyOn(feed);

        Ra2snes.emitEnableModeSwitching();
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

        Ra2snes.emitEnableModeSwitching();
        w.allowIcons = false;
        verify(TestHooks.unlock(1007));

        compare(spy.count, 1);
        verify(feed.visible, "toast feed hidden together with the challenge icons");
    }
}
