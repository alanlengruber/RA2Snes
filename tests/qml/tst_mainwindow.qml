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
