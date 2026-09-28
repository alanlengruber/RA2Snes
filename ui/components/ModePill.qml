import QtQuick
import CustomModels 1.0

// Selo Hardcore / Softcore.
Rectangle {
    id: pill

    property var resolver: null
    property int fontSize: 9

    function _c(name, fallbackName, hard) {
        return resolver ? resolver.color(name, fallbackName, hard) : hard;
    }

    implicitWidth: label.implicitWidth + fontSize * 1.8
    implicitHeight: label.implicitHeight + fontSize * 0.9
    radius: height / 2
    color: UserInfoModel.hardcore
           ? _c("hardcoreTextColor", "errorMessageTextColor", "#ff0000")
           : _c("softcoreTextColor", "nonErrorMessageTextColor", "#00ff00")

    Text {
        id: label
        anchors.centerIn: parent
        text: UserInfoModel.hardcore ? qsTr("Hardcore") : qsTr("Softcore")
        font.bold: true
        font.pixelSize: pill.fontSize
        color: pill._c("surfaceElevatedColor", "mainWindowDarkAccentColor", "#161616")
    }
}
