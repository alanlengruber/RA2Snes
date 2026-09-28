import QtQuick
import QtQuick.Layouts
import CustomModels 1.0

RowLayout {
    id: header
    objectName: "userHeader"

    property var resolver: null
    property bool dense: false
    readonly property int avatarSize: dense ? 64 : 96

    signal linkActivated(url link)

    spacing: dense ? 8 : 10

    function _c(name, fallbackName, hard) {
        return resolver ? resolver.color(name, fallbackName, hard) : hard;
    }

    Avatar {
        objectName: "avatar"
        size: header.avatarSize
        Layout.preferredWidth: size
        Layout.preferredHeight: size
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
            font.pixelSize: header.dense ? 15 : 18
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
            font.pixelSize: header.dense ? 11 : 12
            color: header._c("disabledTextColor", "basicTextColor", "#8fa39a")
        }

        ModePill {
            objectName: "modePill"
            Layout.topMargin: 3
            resolver: header.resolver
            fontSize: header.dense ? 9 : 10
        }
    }
}
