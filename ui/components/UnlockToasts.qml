import QtQuick
import CustomModels 1.0

// A fila de toasts já ligada aos sinais de desbloqueio. A janela principal e a
// janela banner usam este mesmo componente, então as duas se comportam igual.
ToastStack {
    id: feed

    // Enquanto falso, desbloqueios são ignorados — o mesmo guard
    // (setupFinished) que o som já usa na janela principal.
    property bool active: true

    Connections {
        target: AchievementModel

        function onAchievementUnlocked(achievement) {
            if (!feed.active)
                return;

            feed.push({
                badgeUrl: achievement.badgeUrl,
                title: achievement.title,
                points: achievement.points,
                variant: "achievement"
            });
        }
    }

    Connections {
        target: GameInfoModel

        function onBeatenGame() {
            feed.pushGameAward("beaten");
        }

        function onMasteredGame() {
            feed.pushGameAward("mastered");
        }
    }

    function pushGameAward(variant) {
        if (!feed.active)
            return;

        feed.push({
            badgeUrl: GameInfoModel.image_icon_url,
            title: GameInfoModel.title,
            points: 0,
            variant: variant
        });
    }
}
