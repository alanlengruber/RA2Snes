import QtQuick
import QtQuick.Layouts
import CustomModels 1.0
import "./LayoutMath.js" as LayoutMath
import "./components"

Item {
    id: dashboard
    objectName: "dashboard"

    property var mainWindow
    property bool dense: false

    // Largura NÃO escalada. Usar a largura escalada faria o grid refluir
    // durante o zoom Ctrl +/-, que aplica mainGroup.scale.
    readonly property real availableWidth: width
    readonly property int minCardWidth: dense ? 240 : 300
    readonly property int columns: LayoutMath.columnsFor(availableWidth - 24, minCardWidth)
    readonly property string headerMode: LayoutMath.headerMode(availableWidth)
    readonly property real cellWidth: LayoutMath.cellWidthFor(availableWidth - 24, minCardWidth)
    // Medida, não estimada: a altura do texto depende da fonte do sistema, que
    // muda entre Linux e Windows. A sonda abaixo tem o conteúdo de pior caso.
    readonly property real cellHeight: Math.ceil(sizeProbe.implicitHeight) + 8

    implicitHeight: column.implicitHeight

    // Pior caso de altura: descrição em 2 linhas + barra de progresso + valor +
    // linha de tipo. Transparente e desabilitada; existe só para ser medida.
    // Não usar visible: false — layouts ignoram itens invisíveis e a altura
    // implícita viraria zero.
    AchievementCard {
        id: sizeProbe
        width: dashboard.cellWidth - 8
        opacity: 0
        enabled: false
        dense: dashboard.dense
        title: "M"
        description: "M\nM\nM"
        target: 1
        achievementType: "missable"
    }

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

            // Usuário + linha de status. Lado a lado, o cartão do jogo é mais
            // alto que o bloco do usuário, então o status cabe no espaço que
            // sobra embaixo do nome sem empurrar o grid.
            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: dashboard.headerMode === "stacked"
                // Pelo menos a largura natural do conteúdo (nome + selo), para o
                // nome não encurtar à toa; no máximo 45%, para o cartão do jogo
                // nunca ficar espremido. Nomes longos demais encurtam com "…".
                Layout.preferredWidth: dashboard.headerMode === "stacked"
                                       ? -1
                                       : Math.min(Math.max(300, userHeader.implicitWidth),
                                                  dashboard.availableWidth * 0.45)
                spacing: 8

                UserHeader {
                    id: userHeader
                    Layout.fillWidth: true
                    resolver: themeResolver
                    dense: dashboard.dense
                    onLinkActivated: (link) => Qt.openUrlExternally(link)
                }

                Loader {
                    Layout.fillWidth: true
                    source: "./errormessage.qml"
                    onLoaded: item.mainWindow = dashboard.mainWindow
                }
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

            cellWidth: dashboard.cellWidth
            cellHeight: dashboard.cellHeight

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
