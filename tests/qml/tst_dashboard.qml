import QtQuick
import QtTest
import CustomModels 1.0
import "../../ui"

TestCase {
    name: "GameDashboard"
    when: windowShown
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

    Component {
        id: zoomedComponent
        Item {
            property alias dashboard: inner
            scale: 2
            GameDashboard {
                id: inner
                width: 1000
            }
        }
    }

    function init() {
        failOnWarning(/.*/);
    }

    function makeDashboard(props) {
        var d = createTemporaryObject(dashboardComponent, this, props);
        verify(d !== null);
        // O GridView cria os delegates no polish do próximo frame. Esperar a
        // renderização garante que os bindings de role rodem dentro do teste.
        waitForRendering(d);
        return d;
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

    // Critério 5 da spec: o zoom Ctrl +/- (scale no pai) não muda as colunas.
    function test_zoom_does_not_change_columns() {
        var wrapper = createTemporaryObject(zoomedComponent, this);
        verify(wrapper !== null);
        waitForRendering(wrapper);
        compare(wrapper.dashboard.columns, 3);
    }
}
