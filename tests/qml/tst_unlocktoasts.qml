import QtQuick
import QtTest
import TestSupport 1.0
import "../../ui/components"

TestCase {
    name: "UnlockToasts"
    when: windowShown
    width: 500
    height: 300

    UnlockToasts {
        id: feed
        anchors.fill: parent
        gapMs: 20
    }

    SignalSpy {
        id: shownSpy
        target: feed
        signalName: "shown"
    }

    function init() {
        failOnWarning(/.*/);
        feed.reset();
        feed.active = true;
        shownSpy.clear();
    }

    // Ids da fixture do tst_qml.cpp: 1000 + i; i % 3 == 0 já vem desbloqueada.
    // Cada teste desbloqueia uma conquista diferente, porque desbloquear é definitivo.

    function test_live_unlock_shows_achievement_toast() {
        verify(TestHooks.unlock(1001));
        compare(shownSpy.count, 1);
        var data = shownSpy.signalArguments[0][0];
        compare(data.title, "Kremling Kurrency");
        compare(data.points, 3);
        compare(data.variant, "achievement");
    }

    function test_inactive_feed_ignores_unlocks() {
        feed.active = false;
        verify(TestHooks.unlock(1002));
        compare(shownSpy.count, 0);
    }

    function test_already_unlocked_does_not_toast() {
        verify(!TestHooks.unlock(1000));
        compare(shownSpy.count, 0);
    }

    function test_beaten_shows_game_toast() {
        TestHooks.emitBeaten();
        compare(shownSpy.count, 1);
        compare(shownSpy.signalArguments[0][0].variant, "beaten");
        compare(shownSpy.signalArguments[0][0].title, "Donkey Kong Country 2");
    }

    function test_mastered_shows_game_toast() {
        TestHooks.emitMastered();
        compare(shownSpy.count, 1);
        compare(shownSpy.signalArguments[0][0].variant, "mastered");
    }
}
