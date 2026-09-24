import QtQuick
import QtTest
import CustomModels 1.0
import TestSupport 1.0
import "../../ui/components"

TestCase {
    name: "Headers"
    when: windowShown
    // TestCase nasce invisível, e item invisível não recebe clique.
    visible: true
    width: 600
    height: 300

    QtObject {
        id: fakeTheme
    }

    // O botão de refresh (refreshbutton.qml, código antigo) lê themeLoader do contexto.
    Loader {
        id: themeLoader
        source: "../../ui/themes/Dark.qml"
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

    // Mesmo motivo do toast: a máscara redonda da foto é um efeito de shader.
    function test_avatar_visible_without_shader_support() {
        var header = createTemporaryObject(userComponent, this);
        var avatar = findChild(header, "avatar");
        verify(avatar !== null);
        if (GraphicsInfo.api === GraphicsInfo.Software)
            verify(!avatar.layer.enabled, "software renderer: round mask would hide the avatar");
        else
            verify(avatar.layer.enabled, "GPU renderer: round mask expected");
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

    // Final review C1: o botão de refresh sumiu na fusão dos layouts.
    function test_refresh_button_calls_refresh() {
        var header = createTemporaryObject(gameComponent, this);
        waitForRendering(header);
        var button = findChild(header, "refreshButton");
        verify(button !== null, "game card has a refresh button");
        var before = Ra2snes.refreshCalls;
        var target = button.mapToItem(header, button.width - 15, 15);
        mouseClick(header, target.x, target.y);
        tryCompare(Ra2snes, "refreshCalls", before + 1);
    }

    // Final review I4: status de conclusão, firmware e md5, que os dois layouts antigos tinham.
    function test_shows_completion_status() {
        var header = createTemporaryObject(gameComponent, this);
        var status = findChild(header, "completionStatus");
        verify(status !== null, "game card shows completion status");
        try {
            compare(status.text, "Unfinished");
            TestHooks.setBeaten(true);
            compare(status.text, "Beaten");
            TestHooks.setMastered(true);
            compare(status.text, "Mastered");
        } finally {
            TestHooks.setMastered(false);
            TestHooks.setBeaten(false);
        }
    }

    function test_shows_firmware() {
        var header = createTemporaryObject(gameComponent, this);
        var firmware = findChild(header, "firmware");
        verify(firmware !== null, "game card shows firmware");
        compare(firmware.text, "Firmware: Standard");
    }

    function test_title_tooltip_shows_md5() {
        var header = createTemporaryObject(gameComponent, this);
        var tip = findChild(header, "gameTitleTooltip");
        verify(tip !== null, "game title has an md5 tooltip");
        compare(tip.text, "d323e6bb4ccc85fd7b416f58350bc1a2");
    }

    // Fixture do tst_qml.cpp: 20 de 80 conquistas, 100 de 835 pontos.
    // Por quantidade dá 0.25; por pontos daria ~0.12.
    function test_progress_counts_achievements_not_points() {
        var header = createTemporaryObject(gameComponent, this);
        compare(header.progress, 0.25);
    }
}
