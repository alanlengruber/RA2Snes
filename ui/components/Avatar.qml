import QtQuick
import Qt5Compat.GraphicalEffects
import CustomModels 1.0

// Foto do usuário, redonda. Usada no cabeçalho e no cartão de perfil.
// Item em volta da Image porque o tamanho implícito de uma Image é somente
// leitura (vem do arquivo); aqui ele segue `size`.
Item {
    id: avatar

    property int size: 64

    implicitWidth: size
    implicitHeight: size

    Image {
        anchors.fill: parent
        source: UserInfoModel.pfp
        sourceSize.width: avatar.size * 2
        sourceSize.height: avatar.size * 2
        asynchronous: true
        cache: true
        smooth: true
    }

    // Sem GPU a máscara (shader) não é desenhada e a foto sumiria;
    // lá ela fica quadrada.
    layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: avatar.size
            height: avatar.size
            radius: width / 2
        }
    }
}
