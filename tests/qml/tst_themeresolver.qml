import QtQuick
import QtTest
import "../../ui/components"

TestCase {
    name: "ThemeResolver"

    // Tema "de terceiro": só os tokens antigos, nenhum dos novos.
    QtObject {
        id: legacyTheme
        property color progressBarColor: "#eab308"
        property color popupBackgroundColor: "#2a2a2a"
        property color mainWindowLightAccentColor: "#282828"
    }

    QtObject {
        id: modernTheme
        property color progressBarColor: "#eab308"
        property color popupBackgroundColor: "#2a2a2a"
        property color mainWindowLightAccentColor: "#282828"
        property color toastBorderColor: "#6ee7a8"
    }

    ThemeResolver {
        id: resolver
    }

    function test_uses_token_when_present() {
        resolver.theme = modernTheme;
        compare(resolver.color("toastBorderColor", "progressBarColor", "#ff00ff"),
                Qt.color("#6ee7a8"));
    }

    function test_falls_back_to_legacy_token() {
        resolver.theme = legacyTheme;
        compare(resolver.color("toastBorderColor", "progressBarColor", "#ff00ff"),
                Qt.color("#eab308"));
    }

    function test_falls_back_to_hard_default_when_both_missing() {
        resolver.theme = legacyTheme;
        compare(resolver.color("shadowColor", "alsoMissing", "#000000"),
                Qt.color("#000000"));
    }

    function test_null_theme_does_not_throw() {
        resolver.theme = null;
        compare(resolver.color("toastBorderColor", "progressBarColor", "#123456"),
                Qt.color("#123456"));
    }
}
