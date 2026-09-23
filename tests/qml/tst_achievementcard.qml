import QtQuick
import QtTest
import "../../ui/components"

TestCase {
    name: "AchievementCard"
    when: windowShown
    width: 400
    height: 200

    QtObject {
        id: fakeTheme
        property color cardBackgroundColor: "#123456"
        property color cardBorderColor: "#654321"
    }

    // O id NÃO pode se chamar `resolver`: dentro do AchievementCard,
    // `resolver: resolver` resolve para a própria propriedade (binding loop)
    // e o card cai nas cores literais. test_uses_theme_tokens pega isso.
    ThemeResolver {
        id: themeResolver
        theme: fakeTheme
    }

    Component {
        id: cardComponent
        AchievementCard {
            width: 320
            height: 104
            resolver: themeResolver
        }
    }

    function init() {
        failOnWarning(/.*/);
    }

    function test_loads_without_warnings() {
        var card = createTemporaryObject(cardComponent, this,
                                         { title: "KONGQuest", description: "Clear Gangplank Galley",
                                           points: 7, achievementType: "progression" });
        verify(card !== null);
    }

    function test_progress_only_for_locked_with_target() {
        var card = createTemporaryObject(cardComponent, this,
                                         { target: 3, value: 1, percent: 33, unlocked: false });
        verify(card.hasProgress);

        card.unlocked = true;
        verify(!card.hasProgress);

        card.unlocked = false;
        card.target = 0;
        verify(!card.hasProgress);
    }

    function test_uses_theme_tokens() {
        var card = createTemporaryObject(cardComponent, this, {});
        compare(card.color, Qt.color("#123456"));
        compare(card.border.color, Qt.color("#654321"));
    }

    function test_locked_card_is_dimmed() {
        var card = createTemporaryObject(cardComponent, this, { unlocked: true });
        tryCompare(card, "opacity", 1.0);

        card.unlocked = false;
        tryCompare(card, "opacity", 0.82);
    }
}
