import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import CustomModels 1.0

RowLayout {
    id: header

    property var resolver: null
    property bool dense: false
    readonly property int avatarSize: dense ? 48 : 64

    signal linkActivated(url link)

    spacing: dense ? 8 : 10

    function _c(name, fallbackName, hard) {
        return resolver ? resolver.color(name, fallbackName, hard) : hard;
    }

    Image {
        objectName: "avatar"
        Layout.preferredWidth: header.avatarSize
        Layout.preferredHeight: header.avatarSize
        source: UserInfoModel.pfp
        sourceSize.width: header.avatarSize * 2
        sourceSize.height: header.avatarSize * 2
        asynchronous: true
        cache: true
        smooth: true

        // Sem GPU a máscara (shader) não é desenhada e a foto sumiria;
        // lá ela fica quadrada.
        layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: header.avatarSize
                height: header.avatarSize
                radius: width / 2
            }
        }
    }

    // Nome, pontos e selo de modo empilhados ao lado do avatar. Ocupa o espaço
    // que sobra e encurta com "…" quando falta.
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
}
