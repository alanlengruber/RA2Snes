import QtQuick
import QtQuick.Layouts
import CustomModels 1.0

// Perfil em destaque, mostrado enquanto nenhum jogo está carregado.
Rectangle {
    id: card

    property var resolver: null
    property bool dense: false

    signal linkActivated(url link)

    readonly property int pad: dense ? 14 : 20

    function _c(name, fallbackName, hard) {
        return resolver ? resolver.color(name, fallbackName, hard) : hard;
    }

    implicitHeight: row.implicitHeight + pad * 2
    radius: 14
    border.width: 1
    border.color: _c("cardBorderColor", "mainWindowBorderColor", "#32323a")

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: card._c("heroGradientStart", "mainWindowLightAccentColor", "#2b3a33") }
        GradientStop { position: 1.0; color: card._c("heroGradientEnd", "mainWindowDarkAccentColor", "#1d1d22") }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: card.pad
        spacing: card.pad

        Avatar {
            size: card.dense ? 96 : 128
            Layout.preferredWidth: size
            Layout.preferredHeight: size
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 4

            Text {
                objectName: "profileName"
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: UserInfoModel.username
                font.bold: true
                font.pixelSize: card.dense ? 22 : 28
                color: card._c("toastTitleColor", "linkColor", "#ffffff")
            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: qsTr("%1 hardcore points").arg(UserInfoModel.hardcore_score)
                font.bold: true
                font.pixelSize: card.dense ? 13 : 15
                color: card._c("toastPointsColor", "progressBarColor", "#6ee7a8")
            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: qsTr("%1 softcore points").arg(UserInfoModel.softcore_score)
                font.pixelSize: card.dense ? 11 : 12
                color: card._c("timeStampColor", "disabledTextColor", "#7e7e7e")
            }

            ModePill {
                Layout.topMargin: 4
                resolver: card.resolver
                fontSize: card.dense ? 10 : 11
            }

            Text {
                Layout.topMargin: 4
                text: qsTr("View profile on RetroAchievements ↗")
                font.pixelSize: card.dense ? 11 : 12
                color: linkHover.hovered
                       ? card._c("selectedLink", "basicTextColor", "#c8c8c8")
                       : card._c("linkColor", "basicTextColor", "#cc9900")

                Behavior on color { ColorAnimation { duration: 180 } }

                HoverHandler { id: linkHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: card.linkActivated(UserInfoModel.link) }
            }
        }
    }
}
