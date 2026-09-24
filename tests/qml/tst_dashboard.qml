import QtQuick
import QtTest
import CustomModels 1.0
import TestSupport 1.0
import "../../ui"
import "../../ui/components"

TestCase {
    name: "GameDashboard"
    when: windowShown
    // TestCase nasce invisível; o teste do ciclo de vida verifica visibilidade.
    visible: true
    width: 1400
    height: 900

    // Os mesmos nomes que o mainwindow.qml põe no contexto do dashboard.
    Loader {
        id: themeLoader
        source: "../../ui/themes/Dark.qml"
    }

    AchievementSortFilterProxyModel {
        id: sortedAchievementModel
        sourceModel: AchievementModel
    }

    Component {
        id: dashboardComponent
        GameDashboard { }
    }


    function makeDashboard(props) {
        // Estes testes olham o jogo carregado; o ciclo de vida tem teste próprio.
        if (props.gameLoaded === undefined)
            props.gameLoaded = true;
        var d = createTemporaryObject(dashboardComponent, this, props);
        verify(d !== null);
        // O GridView cria os delegates no polish do próximo frame. Esperar a
        // renderização garante que os bindings de role rodem dentro do teste.
        waitForRendering(d);
        return d;
    }

    // Final review I3: sem jogo carregado, nada de cartão, ordenação e grid vazios.
    function test_game_section_follows_game_lifecycle() {
        var d = makeDashboard({ width: 1000, gameLoaded: false });
        var game = findChild(d, "gameHeader");
        var grid = findChild(d, "achievementGrid");
        verify(game !== null && grid !== null);
        verify(!game.visible, "game card hidden before a game loads");
        verify(!grid.visible, "grid hidden before a game loads");

        Ra2snes.emitGameLoaded();
        verify(game.visible);
        verify(grid.visible);

        Ra2snes.emitGameCleared();
        verify(!game.visible, "game card hidden after the game is cleared");
        verify(!grid.visible);
    }

    // Final review I7: toda atualização de rich presence apagava a mensagem de status.
    function test_status_message_survives_rich_presence_update() {
        var d = makeDashboard({ width: 1000 });
        var status = findChild(d, "statusMessage");
        Ra2snes.emitDisplayMessage("Console Not Connected", true);
        tryCompare(status, "text", "Console Not Connected");
        Ra2snes.emitUpdatedRichText();
        compare(status.text, "Console Not Connected");
    }

    // A última linha do grid tem que caber na altura que o dashboard declara,
    // senão o Flickable da janela não rola até ela.
    function test_last_row_inside_declared_height() {
        var d = makeDashboard({ width: 1000 });
        var grid = findChild(d, "achievementGrid");
        var bottom = grid.mapToItem(d, 0, grid.height).y;
        verify(bottom + 12 <= d.implicitHeight,
               "grid ends at " + bottom + " (+12 margin) but dashboard declares " + d.implicitHeight);
    }

    function test_loads_and_renders_grid_without_warnings() {
        makeDashboard({ width: 1000 });
    }

    function test_columns_follow_width_data() {
        return [
            { tag: "380",  width: 380,  columns: 1 },
            { tag: "700",  width: 700,  columns: 2 },
            { tag: "1000", width: 1000, columns: 3 },
            { tag: "1400", width: 1400, columns: 4 }
        ];
    }

    function test_columns_follow_width(data) {
        var d = makeDashboard({ width: data.width });
        compare(d.columns, data.columns);
    }

    function test_header_mode_follows_width_data() {
        return [
            { tag: "400",  width: 400,  mode: "stacked" },
            { tag: "700",  width: 700,  mode: "side" },
            { tag: "1000", width: 1000, mode: "inline" }
        ];
    }

    function test_header_mode_follows_width(data) {
        var d = makeDashboard({ width: data.width });
        compare(d.headerMode, data.mode);
    }

    function test_dense_fits_more_columns() {
        var d = makeDashboard({ width: 1000, dense: true });
        compare(d.columns, 4);
    }

    function test_idle_status_does_not_duplicate_rich_presence() {
        var d = makeDashboard({ width: 1000 });
        var status = findChild(d, "statusMessage");
        verify(status !== null, "status message lives inside the dashboard");
        compare(status.text, "");
    }

    function test_status_message_does_not_move_grid() {
        var d = makeDashboard({ width: 1000 });
        var before = d.implicitHeight;

        Ra2snes.emitDisplayMessage("Game Loaded", false);

        var status = findChild(d, "statusMessage");
        verify(status !== null);
        tryCompare(status, "text", "Game Loaded");
        compare(d.implicitHeight, before);
    }

    Component {
        id: worstCaseCard
        AchievementCard {
            title: "A title long enough that it has to be elided at the end"
            description: "Collect every Kremkoin in the Lost World without losing a single balloon or taking damage from any Kremling"
            points: 25
            target: 10
            value: 4
            percent: 40
            achievementType: "missable"
        }
    }

    function test_cell_fits_worst_case_card_data() {
        return [
            { tag: "normal", dense: false },
            { tag: "dense",  dense: true }
        ];
    }

    // O card preenche a célula menos 4px de margem de cada lado. O pior caso
    // (descrição em 2 linhas + barra + valor + tipo) tem que caber inteiro.
    function test_cell_fits_worst_case_card(data) {
        var d = makeDashboard({ width: 1000, dense: data.dense });
        var card = createTemporaryObject(worstCaseCard, this,
                                         { dense: data.dense, width: d.cellWidth - 8 });
        waitForRendering(card);
        verify(card.implicitHeight <= d.cellHeight - 8,
               "card needs " + card.implicitHeight + "px, cell gives " + (d.cellHeight - 8));
    }

    // 600px é o minimumWidth da janela principal: ali o nome tem que caber inteiro.
    function test_username_not_truncated_at_minimum_width() {
        var d = makeDashboard({ width: 600 });
        var name = findChild(d, "userName");
        verify(name !== null);
        verify(!name.truncated, "username elided at 600px");
    }

}
