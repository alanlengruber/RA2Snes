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

    function test_user_header_fits_given_width_data() {
        return [
            { tag: "198", width: 198 },
            { tag: "150", width: 150 }
        ];
    }

    // Mais estreito que o conteúdo: o nome encurta, o selo de modo não vaza.
    function test_user_header_fits_given_width(data) {
        var header = createTemporaryObject(userComponent, this, { width: data.width });
        waitForRendering(header);
        var pill = findChild(header, "modePill");
        verify(pill !== null);
        var right = pill.mapToItem(header, pill.width, 0).x;
        verify(right <= header.width + 0.5,
               "pill ends at " + right + " but header is " + header.width + " wide");
    }

    function test_game_header_loads_without_warnings() {
        verify(createTemporaryObject(gameComponent, this) !== null);
    }

    function test_game_header_fits_given_width_data() {
        return [
            { tag: "296", width: 296 },
            { tag: "260", width: 260 }
        ];
    }

    // A 600px (largura mínima da janela) o cartão do jogo recebe ~296px.
    function test_game_header_fits_given_width(data) {
        var header = createTemporaryObject(gameComponent, this, { width: data.width });
        waitForRendering(header);
        var names = ["progressPercent", "progressTrack"];
        for (var i = 0; i < names.length; ++i) {
            var item = findChild(header, names[i]);
            verify(item !== null, names[i]);
            var right = item.mapToItem(header, item.width, 0).x;
            verify(right <= header.width - header.pad + 0.5,
                   names[i] + " ends at " + right + ", card content ends at " + (header.width - header.pad));
        }
    }

    // Fixture do tst_qml.cpp: 20 de 80 conquistas, 100 de 835 pontos.
    // Por quantidade dá 0.25; por pontos daria ~0.12.
    function test_progress_counts_achievements_not_points() {
        var header = createTemporaryObject(gameComponent, this);
        compare(header.progress, 0.25);
    }
}
