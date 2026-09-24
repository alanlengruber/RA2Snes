import QtQuick
import QtTest
import TestSupport 1.0

TestCase {
    name: "BannerWindow"
    when: windowShown

    property var banner: null

    // O popupmenu abre a banner passando a janela principal; só o setupFinished
    // dela interessa aqui.
    QtObject {
        id: setupDone
        property bool setupFinished: true
    }

    QtObject {
        id: setupPending
        property bool setupFinished: false
    }

    function init() {
        failOnWarning(/.*/);
    }

    function cleanup() {
        if (banner) {
            banner.close();
            banner.destroy();
            banner = null;
        }
    }

    function openBanner(mainWindowStub) {
        // Como o popupmenu.qml abre a banner: janela própria, sem pai.
        var component = Qt.createComponent("../../ui/banner.qml");
        compare(component.status, Component.Ready, component.errorString());
        banner = component.createObject(null, { mainWindow: mainWindowStub });
        verify(banner !== null);
        banner.show();
        return banner;
    }

    function feedOf(window) {
        var feed = findChild(window.contentItem, "unlockToasts");
        verify(feed !== null, "banner has an unlock toast feed");
        return feed;
    }

    function spyOn(target) {
        var spy = createTemporaryQmlObject('import QtTest; SignalSpy { signalName: "shown" }', this);
        spy.target = target;
        return spy;
    }

    // Rotação e escala efetivas de um item: o acumulado da cadeia de pais.
    function effective(item, property) {
        var total = property === "scale" ? 1 : 0;
        for (var i = item; i; i = i.parent)
            total = property === "scale" ? total * i.scale : total + i.rotation;
        return total;
    }

    // A banner é a janela capturada no OBS: o desbloqueio tem que aparecer nela.
    function test_live_unlock_toasts_in_banner() {
        var window = openBanner(setupDone);
        var spy = spyOn(feedOf(window));
        verify(TestHooks.unlock(1004));
        compare(spy.count, 1);
        compare(spy.signalArguments[0][0].title, "Bramble Scramble");
    }

    // Final review C2: ao carregar um jogo já terminado, o C++ emite
    // masteredGame antes de liberar o setup. Isso não pode virar toast no OBS.
    function test_game_awards_ignored_before_setup() {
        var window = openBanner(setupPending);
        var spy = spyOn(feedOf(window));
        TestHooks.emitMastered();
        TestHooks.emitBeaten();
        compare(spy.count, 0);
    }

    // Final review I5: o toast substitui a troca de painel antiga, que mostrava
    // uma segunda conquista (sempre a da linha 0) ao mesmo tempo.
    function test_unlock_keeps_game_panel() {
        var window = openBanner(setupDone);
        var panel = findChild(window.contentItem, "gamePanel");
        verify(panel !== null);
        verify(TestHooks.unlock(1008));
        wait(100);
        verify(panel.visible, "game panel swapped out on unlock");
    }

    // Final review I5: Ctrl+R gira o conteúdo da banner; o toast gira junto.
    function test_toast_follows_banner_rotation() {
        var window = openBanner(setupDone);
        var panel = findChild(window.contentItem, "gamePanel");
        panel.rotation = 90;
        compare(effective(feedOf(window), "rotation"), 90);
    }

    // Final review I5: banner grande ou em tela cheia escala o conteúdo; o toast também.
    function test_toast_follows_banner_scale() {
        var window = openBanner(setupDone);
        window.width = 640;
        window.height = 360;
        tryCompare(window, "scaleFactor", 2);
        fuzzyCompare(effective(feedOf(window), "scale"), 2, 0.01);
    }
}
