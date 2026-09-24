import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Rectangle {
    id: toast

    property url badgeUrl
    property string title: ""
    property int points: 0
    property string variant: "achievement"
    property var resolver: null

    // O ToastStack ancora este item no canto. Âncoras sobrescrevem `y`, então
    // animar `y` diretamente não teria efeito — o deslocamento vai num
    // Translate, que convive com as âncoras.
    property real slideOffset: 30
    property real glowStrength: 0

    // Quem posiciona o toast diz quanto espaço há (a janela banner tem 320px);
    // títulos que não cabem encurtam com "…".
    property real maximumWidth: Infinity

    signal finished()

    readonly property bool isGameAward: variant === "beaten" || variant === "mastered"
    readonly property int badgeSize: isGameAward ? 52 : 40
    readonly property int holdMs: isGameAward ? 6000 : 3900

    readonly property string label: {
        if (variant === "mastered")
            return qsTr("GAME MASTERED");
        if (variant === "beaten")
            return qsTr("GAME BEATEN");
        return qsTr("ACHIEVEMENT UNLOCKED");
    }

    function _c(name, fallbackName, hard) {
        return resolver ? resolver.color(name, fallbackName, hard) : hard;
    }

    implicitWidth: layout.implicitWidth + 24
    implicitHeight: layout.implicitHeight + 18
    width: Math.min(implicitWidth, maximumWidth)
    radius: 12
    opacity: 0
    transformOrigin: Item.Center

    transform: Translate { y: toast.slideOffset }

    color: _c("toastBackgroundColor", "popupBackgroundColor", "#16201c")
    border.width: isGameAward ? 2 : 1
    border.color: {
        if (variant === "mastered")
            return _c("masteredToastBorderColor", "statusMasteredIconBackgroundColor", "#ffd700");
        if (variant === "beaten")
            return _c("beatenToastBorderColor", "statusBeatenIconBackgroundColor", "#d4d4d4");
        return _c("toastBorderColor", "progressBarColor", "#6ee7a8");
    }

    // No renderizador por software (sem GPU) efeitos de shader não são
    // desenhados, e um item com layer.effect some por inteiro. Lá o toast
    // aparece sem sombra, em vez de não aparecer.
    layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
    layer.effect: DropShadow {
        radius: 18
        samples: 25
        verticalOffset: 8
        color: toast._c("shadowColor", "mainWindowDarkAccentColor", "#000000")
    }

    RowLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        // O wrapper existe para que escala e rotação apliquem ao badge E ao
        // brilho juntos. Aplicar no Image direto deixaria o glow parado.
        Item {
            id: badgeWrap
            Layout.preferredWidth: toast.badgeSize
            Layout.preferredHeight: toast.badgeSize
            transformOrigin: Item.Center

            Image {
                id: badge
                anchors.fill: parent
                source: toast.badgeUrl
                sourceSize.width: toast.badgeSize * 2
                sourceSize.height: toast.badgeSize * 2
                asynchronous: true
                cache: true
                smooth: true
            }

            Glow {
                anchors.fill: badge
                source: badge
                radius: 12
                samples: 17
                color: toast.border.color
                opacity: toast.glowStrength
                visible: opacity > 0
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 2

            Text {
                text: toast.label
                font.bold: true
                font.pixelSize: toast.isGameAward ? 10 : 9
                font.letterSpacing: 1.2
                color: toast.isGameAward
                       ? toast.border.color
                       : toast._c("toastLabelColor", "nonErrorMessageTextColor", "#6ee7a8")
            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: toast.title
                font.bold: true
                font.pixelSize: toast.isGameAward ? 16 : 13
                color: toast._c("toastTitleColor", "basicTextColor", "#ffffff")
            }
        }

        Text {
            visible: toast.points > 0
            Layout.leftMargin: 6
            text: "+" + toast.points
            font.bold: true
            font.pixelSize: 18
            color: toast._c("toastPointsColor", "progressBarColor", "#6ee7a8")
        }
    }

    function start() {
        sequence.restart();
        badgePop.restart();
    }

    SequentialAnimation {
        id: sequence

        ParallelAnimation {
            NumberAnimation {
                target: toast; property: "slideOffset"
                from: 30; to: 0
                duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.4
            }
            NumberAnimation {
                target: toast; property: "opacity"
                from: 0; to: 1; duration: 420
            }
            NumberAnimation {
                target: toast; property: "scale"
                from: 0.94; to: 1.0
                duration: 420; easing.type: Easing.OutBack
            }
        }

        PauseAnimation { duration: toast.holdMs }

        ParallelAnimation {
            NumberAnimation {
                target: toast; property: "slideOffset"
                to: 22; duration: 280; easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: toast; property: "opacity"
                to: 0; duration: 280; easing.type: Easing.InQuad
            }
        }

        onFinished: toast.finished()
    }

    // O pop do badge começa em 340ms, enquanto a caixa ainda assenta.
    SequentialAnimation {
        id: badgePop

        PauseAnimation { duration: 340 }

        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation {
                    target: badgeWrap; property: "scale"
                    from: 1.0; to: 1.34
                    duration: 175; easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: badgeWrap; property: "scale"
                    to: 1.0; duration: 325; easing.type: Easing.OutQuad
                }
            }
            SequentialAnimation {
                NumberAnimation {
                    target: badgeWrap; property: "rotation"
                    from: 0; to: -7
                    duration: 175; easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: badgeWrap; property: "rotation"
                    to: 0; duration: 325; easing.type: Easing.OutQuad
                }
            }
            SequentialAnimation {
                NumberAnimation {
                    target: toast; property: "glowStrength"
                    from: 0.0; to: 1.0
                    duration: 175; easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: toast; property: "glowStrength"
                    to: 0.0; duration: 325; easing.type: Easing.OutQuad
                }
            }
        }
    }
}
