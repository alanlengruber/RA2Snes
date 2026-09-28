import QtQuick
import QtQuick.Layouts
import CustomModels 1.0

// O caminho até um jogo valer conquistas. Cada etapa só é cobrada quando a
// anterior passou: a primeira que falta diz o que fazer, as seguintes esperam.
Rectangle {
    id: checklist

    property var resolver: null
    property bool dense: false

    readonly property int pad: dense ? 12 : 18

    // done / failed / active / pending
    readonly property string usb2snesStatus: Ra2snes.usb2snesConnected ? "done" : "failed"
    readonly property string consoleStatus: !Ra2snes.usb2snesConnected ? "pending"
                                          : Ra2snes.consoleConnected ? "done" : "failed"
    readonly property string gameStatus: Ra2snes.usb2snesConnected && Ra2snes.consoleConnected
                                         ? "active" : "pending"

    function _c(name, fallbackName, hard) {
        return resolver ? resolver.color(name, fallbackName, hard) : hard;
    }

    implicitHeight: column.implicitHeight + pad * 2
    radius: 14
    border.width: 1
    color: _c("cardBackgroundColor", "mainWindowLightAccentColor", "#242428")
    border.color: _c("cardBorderColor", "mainWindowBorderColor", "#32323a")

    component Step: RowLayout {
        id: step

        property string status: "pending"
        property string title: ""
        property string detail: ""

        readonly property color tint: status === "done"
                                      ? checklist._c("toastLabelColor", "nonErrorMessageTextColor", "#6ee7a8")
                                      : status === "failed"
                                        ? checklist._c("errorMessageTextColor", "hardcoreTextColor", "#ff5555")
                                        : status === "active"
                                          ? checklist._c("basicTextColor", "linkColor", "#2c97fa")
                                          : checklist._c("timeStampColor", "disabledTextColor", "#7e7e7e")

        Layout.fillWidth: true
        spacing: 12

        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: checklist.dense ? 22 : 26
            Layout.preferredHeight: Layout.preferredWidth
            radius: width / 2
            color: step.status === "done" || step.status === "failed" ? step.tint : "transparent"
            border.width: 2
            border.color: step.tint

            Text {
                anchors.centerIn: parent
                text: step.status === "done" ? "✓"
                    : step.status === "failed" ? "✕"
                    : step.status === "active" ? "…" : ""
                font.bold: true
                font.pixelSize: checklist.dense ? 12 : 14
                color: step.status === "active"
                       ? step.tint
                       : checklist._c("surfaceElevatedColor", "mainWindowDarkAccentColor", "#161616")
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: step.title
                font.bold: true
                font.pixelSize: checklist.dense ? 12 : 14
                color: step.status === "pending"
                       ? checklist._c("timeStampColor", "disabledTextColor", "#7e7e7e")
                       : checklist._c("toastTitleColor", "linkColor", "#ffffff")
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: step.detail
                font.pixelSize: checklist.dense ? 10 : 12
                color: step.status === "failed"
                       ? checklist._c("disabledTextColor", "basicTextColor", "#e5e5e5")
                       : checklist._c("timeStampColor", "disabledTextColor", "#7e7e7e")
            }
        }
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: checklist.pad
        spacing: checklist.dense ? 10 : 14

        Step {
            objectName: "step-ra"
            status: "done"
            title: qsTr("RetroAchievements")
            detail: qsTr("Signed in as %1").arg(UserInfoModel.username)
        }

        Step {
            objectName: "step-usb2snes"
            status: checklist.usb2snesStatus
            title: qsTr("QUsb2Snes / SNI")
            detail: status === "done" ? qsTr("Connected")
                                      : qsTr("Start QUsb2Snes or SNI on this computer")
        }

        Step {
            objectName: "step-console"
            status: checklist.consoleStatus
            title: qsTr("Console")
            detail: status === "done" ? qsTr("SD2Snes detected")
                  : status === "failed" ? qsTr("Power on the SNES with the SD2Snes plugged in via USB")
                  : qsTr("Waiting for QUsb2Snes / SNI")
        }

        Step {
            objectName: "step-game"
            status: checklist.gameStatus
            title: qsTr("Game")
            detail: status === "active" ? qsTr("Start a supported game on the console")
                                        : qsTr("Waiting for the console")
        }
    }
}
