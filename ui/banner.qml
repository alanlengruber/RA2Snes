import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import CustomModels 1.0
import "./components"

ApplicationWindow {
    id: banner
    width: 320
    height: 180
    minimumWidth: 360
    minimumHeight: 180
    title: "RA2Snes - Banner"

    Shortcut {
        sequence: StandardKey.Cancel
        onActivated: {
            if (banner.visibility === Window.FullScreen)
                banner.visibility = Window.Windowed
            else
                banner.visibility = Window.FullScreen
        }
    }

    Shortcut {
        sequence: "Ctrl+R"
        onActivated: {
            let content = content1;
            if(content.rotation === 270)
                content.rotation = 0;
            else
                content.rotation += 90;
            if(content.rotation === 90 || content.rotation === 270)
            {
                banner.baseWidth = 180
                banner.baseHeight = 320
            }
            else
            {
                banner.baseWidth = 320
                banner.baseHeight = 180
            }
        }
    }

    property string themeSource: "./themes/Dark.qml"
    // A janela principal, passada pelo popupmenu ao abrir a banner. Os toasts
    // só valem depois que o jogo termina de carregar (setupFinished): antes
    // disso o app emite "masterizado/zerado" para jogos já terminados.
    property var mainWindow: null
    Loader {
        id: themeLoader
        source: banner.themeSource
        onSourceChanged: {
            if(themeLoader.item === null)
                themeLoader.source = "./themes/Dark.qml";
        }
        active: true
    }

    color: themeLoader.item.mainWindowDarkAccentColor
    Material.theme: themeLoader.item.darkScrollBar ? Material.Dark : Material.Light
    Material.accent: themeLoader.item.accentColor

    property int baseWidth: 320
    property int baseHeight: 180

    property real scaleFactor: Math.min(width / baseWidth, height / baseHeight)
    Item {
        id: content1
        objectName: "gamePanel"
        width: 320
        height: 180
        anchors.centerIn: parent
        scale: banner.scaleFactor
        transformOrigin: Item.Center
        rotation: 0
        visible: true
        property real layoutScale: 1.0

        function resetLayout() {
            content1.layoutScale = 1.0;
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6

            onImplicitWidthChanged: {
                if(implicitWidth < 300) {
                    content1.layoutScale += 0.05;
                }
                else if(implicitWidth > 320 && content1.layoutScale > 0.0) {
                    content1.layoutScale -= 0.05;
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                Image {
                    source: GameInfoModel.image_icon_url
                    Layout.preferredWidth: 38 * content1.layoutScale
                    Layout.preferredHeight: Layout.preferredWidth
                    fillMode: Image.PreserveAspectFit
                    cache: true
                    asynchronous: true
                    smooth: true
                }

                ColumnLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: GameInfoModel.title
                        font.pixelSize: 13 * content1.layoutScale
                        color: themeLoader.item.linkColor
                        Layout.fillWidth: true
                        font.family: "Verdana"
                        onTextChanged: {
                            content1.resetLayout();
                        }
                    }

                    RowLayout {
                        spacing: 4
                        Layout.fillWidth: true

                        Image {
                            id: consoleIcon
                            source: GameInfoModel.console_icon
                            Layout.preferredWidth: 18 * content1.layoutScale
                            Layout.preferredHeight: Layout.preferredWidth
                            fillMode: Image.PreserveAspectFit
                            cache: true
                            asynchronous: true
                        }

                        Text {
                            id: consoleName
                            text: GameInfoModel.console
                            font.pixelSize: 13 * content1.layoutScale
                            color: themeLoader.item.basicTextColor
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            font.family: "Verdana"
                        }
                    }
                }
            }

            Text {
                text: Ra2snes.richPresence
                font.pixelSize: 11 * content1.layoutScale
                color: themeLoader.item.basicTextColor
                wrapMode: Text.WordWrap
                Layout.alignment: Qt.AlignLeft
                Layout.maximumWidth: parent.width
                font.family: "Verdana"
            }
        }
    }

    ThemeResolver {
        id: bannerToastResolver
        theme: themeLoader.item
    }

    // A banner é a janela capturada no OBS: é onde o público vê a conquista.
    // O quadro tem o mesmo tamanho, escala e rotação do painel do jogo, então
    // o toast gira com Ctrl+R e cresce junto numa banner grande ou em tela cheia.
    Item {
        width: 320
        height: 180
        anchors.centerIn: parent
        scale: banner.scaleFactor
        rotation: content1.rotation
        transformOrigin: Item.Center
        z: 200

        UnlockToasts {
            objectName: "unlockToasts"
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8
            width: 300
            height: 70
            active: banner.mainWindow ? banner.mainWindow.setupFinished : false
            resolver: bannerToastResolver
        }
    }
}
