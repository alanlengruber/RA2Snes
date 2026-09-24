import QtQuick
import QtTest
import TestSupport 1.0

TestCase {
    name: "BannerWindow"
    when: windowShown

    property var banner: null

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

    function openBanner() {
        // Como o popupmenu.qml abre a banner: janela própria, sem pai.
        var component = Qt.createComponent("../../ui/banner.qml");
        compare(component.status, Component.Ready, component.errorString());
        banner = component.createObject(null);
        verify(banner !== null);
        banner.show();
        return banner;
    }

    // A banner é a janela capturada no OBS: o desbloqueio tem que aparecer nela.
    function test_live_unlock_toasts_in_banner() {
        var window = openBanner();
        var feed = findChild(window.contentItem, "unlockToasts");
        verify(feed !== null, "banner has an unlock toast feed");

        var spy = createTemporaryQmlObject(
            'import QtTest; SignalSpy { signalName: "shown" }', this);
        spy.target = feed;

        verify(TestHooks.unlock(1004));
        compare(spy.count, 1);
        compare(spy.signalArguments[0][0].title, "Bramble Scramble");
    }
}
