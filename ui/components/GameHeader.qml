import QtQuick
import QtQuick.Layouts
import CustomModels 1.0

Rectangle {
    id: header

    property var resolver: null
    property bool dense: false
    property bool showRichPresence: true

    signal linkActivated(url link)

    readonly property int pad: dense ? 9 : 13
    // Por quantidade de conquistas, como a barra antiga e o "0 of 80" do site.
    readonly property real progress: GameInfoModel.achievement_count > 0
                                     ? GameInfoModel.completion_count / GameInfoModel.achievement_count
                                     : 0

    implicitHeight: layout.implicitHeight + pad * 2
    radius: 10
    border.width: 1
    border.color: header._c("cardBorderColor", "mainWindowBorderColor", "#32323a")

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
            position: 0.0
            color: header._c("heroGradientStart", "mainWindowLightAccentColor", "#2b3a33")
        }
        GradientStop {
            position: 1.0
            color: header._c("heroGradientEnd", "mainWindowDarkAccentColor", "#1d1d22")
        }
    }

    function _c(name, fallbackName, hard) {
        return resolver ? resolver.color(name, fallbackName, hard) : hard;
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: header.pad
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 9

            Image {
                Layout.preferredWidth: header.dense ? 30 : 40
                Layout.preferredHeight: header.dense ? 30 : 40
                source: GameInfoModel.image_icon_url
                sourceSize.width: 80
                sourceSize.height: 80
                asynchronous: true
                cache: true
                smooth: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: GameInfoModel.title
                    elide: Text.ElideRight
                    font.bold: true
                    font.pixelSize: header.dense ? 12 : 14
                    color: gameHover.hovered
                           ? header._c("selectedLink", "basicTextColor", "#c8c8c8")
                           : header._c("toastTitleColor", "linkColor", "#ffffff")

                    Behavior on color { ColorAnimation { duration: 180 } }

                    HoverHandler { id: gameHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: header.linkActivated(GameInfoModel.game_link) }
                }

                RowLayout {
                    spacing: 5

                    Image {
                        Layout.preferredWidth: 13
                        Layout.preferredHeight: 13
                        source: GameInfoModel.console_icon
                        sourceSize.width: 26
                        sourceSize.height: 26
                        asynchronous: true
                        cache: true
                    }

                    Text {
                        text: GameInfoModel.console
                        font.pixelSize: 10
                        color: header._c("disabledTextColor", "basicTextColor", "#8fa39a")
                    }

                    Text {
                        text: "· " + GameInfoModel.completion_count + " / "
                              + GameInfoModel.achievement_count
                        font.pixelSize: 10
                        color: header._c("disabledTextColor", "basicTextColor", "#8fa39a")
                    }

                    Row {
                        spacing: 3
                        visible: GameInfoModel.missable_count > 0

                        Image {
                            width: 11
                            height: 11
                            source: "../images/missable.svg"
                            sourceSize.width: 22
                            sourceSize.height: 22
                        }

                        Text {
                            text: GameInfoModel.missable_count
                            font.pixelSize: 10
                            color: header._c("missableIconColor", "basicTextColor", "#ffffff")
                        }
                    }
                }
            }

            Text {
                text: Math.round(header.progress * 100) + "%"
                font.bold: true
                font.pixelSize: header.dense ? 12 : 14
                color: header._c("toastPointsColor", "progressBarColor", "#6ee7a8")
            }
        }

        // Barra de progresso — vinha só do compact.qml
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: 3
            color: header._c("progressBarBackgroundColor", "mainWindowDarkAccentColor", "#2a2a2a")

            Rectangle {
                height: parent.height
                radius: parent.radius
                width: parent.width * Math.max(0, Math.min(1, header.progress))
                color: header._c("progressBarColor", "basicTextColor", "#eab308")

                Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            }
        }

        Text {
            Layout.fillWidth: true
            text: GameInfoModel.point_count + " / " + GameInfoModel.point_total + qsTr(" pontos")
            font.pixelSize: 10
            color: header._c("timeStampColor", "disabledTextColor", "#7e7e7e")
        }

        // Rich presence — vinha só do noncompact.qml
        Text {
            Layout.fillWidth: true
            visible: header.showRichPresence && Ra2snes.richPresence !== ""
            text: Ra2snes.richPresence
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.italic: true
            font.pixelSize: 10
            color: header._c("timeStampColor", "disabledTextColor", "#7e7e7e")
        }
    }
}
