import QtQuick
import CustomModels 1.0

Item {
    id: outer
    property var mainWindow
    // Sem altura própria, o item ocupava 0px e o texto vazava sobre o que
    // estivesse abaixo. Dentro de um layout isso precisa ser explícito.
    implicitHeight: errorMessage.text !== "" ? errorMessage.implicitHeight : 0
    function updateMessage()
    {
        errorMessage.showRichPresence();
    }

    Text {
        id: errorMessage
        objectName: "statusMessage"
        font.family: "Verdana"
        font.pixelSize: 13
        color: themeLoader.item.basicTextColor
        width: parent.width
        wrapMode: Text.WordWrap
        opacity: 0
        Behavior on opacity {
            NumberAnimation {
                duration: 500
            }
        }
        onHeightChanged: {
            if (outer.mainWindow)
                outer.mainWindow.errorHeight = height;
        }

        // No layout compacto antigo, a linha de status ociosa exibia o rich
        // presence. O GameHeader agora o mostra sempre, então ociosa ela fica vazia.
        function showRichPresence()
        {
            errorMessage.text = "";
            errorMessage.opacity = 0;
        }

        Component.onCompleted: {
            errorMessage.showRichPresence();
        }

        NumberAnimation {
            id: fadeAnimation
            target: errorMessage
            property: "opacity"
            to: 0.0
            duration: 500
            onStopped: {
                errorMessage.text = "";
                errorMessage.color = themeLoader.item.basicTextColor;
                errorMessage.showRichPresence();
            }
        }

        Timer {
            id: fadeOutTimer
            interval: 10000
            running: false
            repeat: false
            onTriggered: {
                fadeAnimation.start();
            }
        }

        function showErrorMessage(error, iserror)
        {
            errorMessage.font.pixelSize = 13;
            if(iserror)
                errorMessage.color = themeLoader.item.errorMessageTextColor;
            else
                errorMessage.color = themeLoader.item.nonErrorMessageTextColor;
            errorMessage.text = error;
            errorMessage.opacity = 1;
            fadeOutTimer.restart();
        }

        Connections {
            target: Ra2snes
            function onUpdatedRichText()
            {
                errorMessage.showRichPresence();
            }
        }

        Connections {
            target: Ra2snes
            function onDisplayMessage(error, iserror)
            {
                errorMessage.showErrorMessage(error, iserror);
            }
        }
    }
}

