import QtQuick
import QtTest
import CustomModels 1.0
import "../../ui"
import "../../ui/components"

// A tela sem jogo carregado: cartão de perfil grande + checklist de conexão.
TestCase {
    name: "IdleScreen"
    when: windowShown
    visible: true
    width: 1000
    height: 900

    Loader {
        id: themeLoader
        source: "../../ui/themes/Dark.qml"
    }

    AchievementSortFilterProxyModel {
        id: sortedAchievementModel
        sourceModel: AchievementModel
    }

    ThemeResolver {
        id: themeResolver
        theme: themeLoader.item
    }

    Component {
        id: checklistComponent
        ConnectionChecklist {
            width: 500
            resolver: themeResolver
        }
    }

    Component {
        id: dashboardComponent
        GameDashboard { width: 1000 }
    }

    function init() {
        failOnWarning(/.*/);
        Ra2snes.setConnection(false, false);
    }

    function cleanup() {
        Ra2snes.setConnection(false, false);
    }

    function statuses(checklist) {
        return ["ra", "usb2snes", "console", "game"].map(function(key) {
            var step = findChild(checklist, "step-" + key);
            verify(step !== null, "step " + key);
            return step.status;
        }).join(",");
    }

    // Cada etapa só é cobrada quando a anterior passou; a primeira que falta
    // fica "failed" (com dica), as seguintes ficam "pending".
    function test_checklist_follows_connection_state_data() {
        return [
            { tag: "nothing",         usb: false, console: false, expected: "done,failed,pending,pending" },
            { tag: "usb2snes only",   usb: true,  console: false, expected: "done,done,failed,pending" },
            { tag: "console ready",   usb: true,  console: true,  expected: "done,done,done,active" }
        ];
    }

    function test_checklist_follows_connection_state(data) {
        var checklist = createTemporaryObject(checklistComponent, this);
        Ra2snes.setConnection(data.usb, data.console);
        compare(statuses(checklist), data.expected);
    }

    function test_checklist_updates_live() {
        var checklist = createTemporaryObject(checklistComponent, this);
        compare(statuses(checklist), "done,failed,pending,pending");
        Ra2snes.setConnection(true, true);
        compare(statuses(checklist), "done,done,done,active");
    }

    function test_failed_step_explains_what_to_do() {
        var checklist = createTemporaryObject(checklistComponent, this);
        Ra2snes.setConnection(true, false);
        var step = findChild(checklist, "step-console");
        verify(step.detail.length > 0, "failed step has a hint");
    }

    function test_idle_dashboard_shows_profile_and_checklist() {
        var d = createTemporaryObject(dashboardComponent, this, { gameLoaded: false });
        waitForRendering(d);
        verify(findChild(d, "profileCard").visible, "profile card while idle");
        verify(findChild(d, "connectionChecklist").visible, "checklist while idle");
        verify(!findChild(d, "userHeader").visible, "small header hidden while idle");
        verify(!findChild(d, "gameHeader").visible);
    }

    function test_loaded_dashboard_hides_idle_cards() {
        var d = createTemporaryObject(dashboardComponent, this, { gameLoaded: true });
        waitForRendering(d);
        verify(!findChild(d, "profileCard").visible);
        verify(!findChild(d, "connectionChecklist").visible);
        verify(findChild(d, "userHeader").visible);
        verify(findChild(d, "gameHeader").visible);
    }

    function test_idle_cards_are_centered() {
        var d = createTemporaryObject(dashboardComponent, this, { width: 1400, gameLoaded: false });
        waitForRendering(d);
        var card = findChild(d, "profileCard");
        var left = card.mapToItem(d, 0, 0).x;
        var right = d.width - (left + card.width);
        fuzzyCompare(left, right, 2);
        verify(card.width > 400, "idle cards are " + card.width + "px wide");
    }

    function test_profile_card_shows_user() {
        var d = createTemporaryObject(dashboardComponent, this, { gameLoaded: false });
        var name = findChild(findChild(d, "profileCard"), "profileName");
        verify(name !== null);
        compare(name.text, "SuperNinTaylor");
    }

    // Status (ex.: "Game Hash does not exist!") continua visível sem jogo.
    function test_status_message_visible_while_idle() {
        var d = createTemporaryObject(dashboardComponent, this, { gameLoaded: false });
        Ra2snes.emitDisplayMessage("Game Hash does not exist!", true);
        var status = findChild(d, "statusMessage");
        tryCompare(status, "text", "Game Hash does not exist!");
        verify(status.visible, "status line hidden while idle");
    }
}
