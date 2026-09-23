import QtQuick
import QtTest
import "../../ui/components"

TestCase {
    name: "Headers"
    when: windowShown
    width: 600
    height: 300

    QtObject {
        id: fakeTheme
    }

    ThemeResolver {
        id: themeResolver
        theme: fakeTheme
    }

    Component {
        id: userComponent
        UserHeader {
            width: 300
            resolver: themeResolver
        }
    }

    Component {
        id: gameComponent
        GameHeader {
            width: 500
            resolver: themeResolver
        }
    }

    function init() {
        failOnWarning(/.*/);
    }

    function test_user_header_loads_without_warnings() {
        verify(createTemporaryObject(userComponent, this) !== null);
    }

    function test_game_header_loads_without_warnings() {
        verify(createTemporaryObject(gameComponent, this) !== null);
    }

    // Fixture do tst_qml.cpp: 20 de 80 conquistas, 100 de 835 pontos.
    // Por quantidade dá 0.25; por pontos daria ~0.12.
    function test_progress_counts_achievements_not_points() {
        var header = createTemporaryObject(gameComponent, this);
        compare(header.progress, 0.25);
    }
}
