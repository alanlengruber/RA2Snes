import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import CustomModels 1.0

RowLayout {
    id: header

    property var resolver: null
    property bool dense: false

    signal linkActivated(url link)

    spacing: dense ? 8 : 10

    function _c(name, fallbackName, hard) {
        return resolver ? resolver.color(name, fallbackName, hard) : hard;
    }

    Image {
        objectName: "avatar"
        Layout.preferredWidth: header.dense ? 30 : 38
        Layout.preferredHeight: header.dense ? 30 : 38
        source: UserInfoModel.pfp
        sourceSize.width: 76
        sourceSize.height: 76
        asynchronous: true
        cache: true
        smooth: true

        // Sem GPU a máscara (shader) não é desenhada e a foto sumiria;
        // lá ela fica quadrada.
        layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: header.dense ? 30 : 38
                height: header.dense ? 30 : 38
                radius: width / 2
            }
        }
    }

    // Ocupa o espaço que sobra e encurta com "…" quando falta: o selo de
    // modo à direita nunca pode ser empurrado para fora do bloco.
    ColumnLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        spacing: 1

        Text {
            objectName: "userName"
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: UserInfoModel.username
            font.bold: true
            font.pixelSize: header.dense ? 14 : 16
            color: nameHover.hovered
                   ? header._c("selectedLink", "basicTextColor", "#c8c8c8")
                   : header._c("toastTitleColor", "linkColor", "#ffffff")

            Behavior on color { ColorAnimation { duration: 180 } }

            HoverHandler { id: nameHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: header.linkActivated(UserInfoModel.link) }
        }

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: (UserInfoModel.hardcore
                   ? UserInfoModel.hardcore_score
                   : UserInfoModel.softcore_score) + qsTr(" points")
            font.pixelSize: header.dense ? 10 : 11
            color: header._c("disabledTextColor", "basicTextColor", "#8fa39a")
        }
    }

    Rectangle {
        objectName: "modePill"
        Layout.preferredHeight: 20
        Layout.preferredWidth: modeLabel.implicitWidth + 16
        radius: 10
        color: UserInfoModel.hardcore
               ? header._c("hardcoreTextColor", "errorMessageTextColor", "#ff0000")
               : header._c("softcoreTextColor", "nonErrorMessageTextColor", "#00ff00")

        Text {
            id: modeLabel
            anchors.centerIn: parent
            text: UserInfoModel.hardcore ? qsTr("Hardcore") : qsTr("Softcore")
            font.bold: true
            font.pixelSize: 9
            color: header._c("surfaceElevatedColor", "mainWindowDarkAccentColor", "#161616")
        }
    }
}
