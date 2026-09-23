import QtQuick
import QtQuick.Layouts
import CustomModels 1.0
import "./LayoutMath.js" as LayoutMath
import "./components"

Item {
    id: dashboard

    property var mainWindow
    property bool dense: false

    // Largura NÃO escalada. Usar a largura escalada faria o grid refluir
    // durante o zoom Ctrl +/-, que aplica mainGroup.scale.
    readonly property real availableWidth: width
    readonly property int minCardWidth: dense ? 240 : 300
    readonly property int columns: LayoutMath.columnsFor(availableWidth - 24, minCardWidth)
    readonly property string headerMode: LayoutMath.headerMode(availableWidth)

    implicitHeight: column.implicitHeight

    ThemeResolver {
        id: themeResolver
        theme: themeLoader.item
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Cabeçalho: empilha abaixo de 520px, lado a lado acima.
        GridLayout {
            Layout.fillWidth: true
            columns: dashboard.headerMode === "stacked" ? 1 : 2
            columnSpacing: 10
            rowSpacing: 10

            UserHeader {
                Layout.fillWidth: dashboard.headerMode === "stacked"
                Layout.preferredWidth: dashboard.headerMode === "stacked"
                                       ? -1
                                       : Math.min(300, dashboard.availableWidth * 0.33)
                resolver: themeResolver
                dense: dashboard.dense
                onLinkActivated: (link) => Qt.openUrlExternally(link)
            }

            GameHeader {
                Layout.fillWidth: true
                resolver: themeResolver
                dense: dashboard.dense
                showRichPresence: true
                onLinkActivated: (link) => Qt.openUrlExternally(link)
            }
        }

        Loader {
            Layout.fillWidth: true
            source: "./sorting.qml"
        }

        GridView {
            id: grid

            Layout.fillWidth: true
            Layout.preferredHeight: Math.ceil(count / Math.max(1, dashboard.columns))
                                    * cellHeight
            interactive: false
            clip: false

            model: sortedAchievementModel

            cellWidth: LayoutMath.cellWidthFor(width, dashboard.minCardWidth)
            cellHeight: dashboard.dense ? 84 : 104

            delegate: Item {
                width: grid.cellWidth
                height: grid.cellHeight

                AchievementCard {
                    anchors.fill: parent
                    anchors.margins: 4

                    resolver: themeResolver
                    dense: dashboard.dense

                    badgeUrl: model.badgeUrl
                    lockedBadgeUrl: model.badgeLockedUrl
                    title: model.title
                    description: model.description
                    points: model.points
                    unlocked: model.unlocked
                    primed: model.primed
                    achievementType: model.type
                    value: model.value
                    target: model.target
                    percent: model.percent
                    timeUnlockedString: model.timeUnlockedString
                    achievementLink: model.achievementLink

                    onLinkActivated: (link) => Qt.openUrlExternally(link)
                }
            }
        }
    }
}
