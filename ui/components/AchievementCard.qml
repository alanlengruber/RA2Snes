import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Rectangle {
    id: card

    property url badgeUrl
    property url lockedBadgeUrl
    property string title: ""
    property string description: ""
    property int points: 0
    property bool unlocked: false
    property bool primed: false
    property string achievementType: ""
    property int value: 0
    property int target: 0
    property int percent: 0
    property string timeUnlockedString: ""
    property url achievementLink
    property var resolver: null
    property bool dense: false

    signal linkActivated(url link)

    readonly property int pad: dense ? 8 : 12
    readonly property int badgeSize: dense ? 40 : 52
    readonly property bool hasProgress: target > 0 && !unlocked

    implicitHeight: layout.implicitHeight + pad * 2
    radius: dense ? 8 : 10
    border.width: 1
    // O GridView exige célula de tamanho fixo, então o card preenche a célula e
    // ignora o próprio implicitHeight. O clip impede que um título ou descrição
    // longa vaze para a célula vizinha.
    clip: true

    color: hover.hovered
           ? _c("cardHoverBackgroundColor", "highlightedButtonBackgroundColor", "#2e2e36")
           : _c("cardBackgroundColor", "mainWindowLightAccentColor", "#242428")
    border.color: _c("cardBorderColor", "mainWindowBorderColor", "#32323a")
    opacity: unlocked ? 1.0 : 0.82

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on opacity { NumberAnimation { duration: 140 } }

    function _c(name, fallbackName, hard) {
        return resolver ? resolver.color(name, fallbackName, hard) : hard;
    }

    HoverHandler { id: hover }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: card.pad
        spacing: card.pad

        Image {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: card.badgeSize
            Layout.preferredHeight: card.badgeSize
            source: card.unlocked ? card.badgeUrl : card.lockedBadgeUrl
            sourceSize.width: card.badgeSize * 2
            sourceSize.height: card.badgeSize * 2
            asynchronous: true
            cache: true
            smooth: true

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: "transparent"
                border.width: card.primed ? 2 : 0
                border.color: card._c("toastBorderColor", "progressBarColor", "#6ee7a8")
                visible: card.primed
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: card.title
                    elide: Text.ElideRight
                    font.bold: true
                    font.pixelSize: card.dense ? 12 : 14
                    color: titleHover.hovered
                           ? card._c("selectedLink", "basicTextColor", "#c8c8c8")
                           : card._c("toastTitleColor", "linkColor", "#ffffff")

                    Behavior on color { ColorAnimation { duration: 180 } }

                    HoverHandler { id: titleHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: card.linkActivated(card.achievementLink)
                    }
                }

                Text {
                    text: card.points
                    font.bold: true
                    font.pixelSize: card.dense ? 12 : 14
                    color: card._c("toastPointsColor", "progressBarColor", "#6ee7a8")
                }
            }

            Text {
                Layout.fillWidth: true
                text: card.description
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: card.dense ? 10 : 11
                color: card._c("disabledTextColor", "basicTextColor", "#9a9aa6")
            }

            Text {
                Layout.fillWidth: true
                visible: card.unlocked && card.timeUnlockedString !== ""
                text: card.timeUnlockedString
                elide: Text.ElideRight
                font.pixelSize: 9
                color: card._c("timeStampColor", "disabledTextColor", "#7e7e7e")
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 3
                visible: card.hasProgress
                Layout.preferredHeight: 5
                radius: 3
                color: card._c("progressBarBackgroundColor", "mainWindowDarkAccentColor", "#2a2a2a")

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * Math.max(0, Math.min(1, card.percent / 100))
                    color: card._c("progressBarColor", "basicTextColor", "#eab308")

                    Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                visible: card.hasProgress
                text: card.value + " / " + card.target
                font.pixelSize: 9
                color: card._c("timeStampColor", "disabledTextColor", "#7e7e7e")
            }

            Row {
                spacing: 4
                visible: card.achievementType !== ""

                Image {
                    width: 12
                    height: 12
                    source: {
                        if (card.achievementType === "missable")
                            return "../images/missable.svg";
                        if (card.achievementType === "progression")
                            return "../images/progression.svg";
                        if (card.achievementType === "win_condition")
                            return "../images/win_condition.svg";
                        return "";
                    }
                    visible: source != ""
                    sourceSize.width: 24
                    sourceSize.height: 24
                }

                Text {
                    text: card.achievementType
                    font.pixelSize: 9
                    color: card._c("timeStampColor", "disabledTextColor", "#7e7e7e")
                }
            }
        }
    }
}
