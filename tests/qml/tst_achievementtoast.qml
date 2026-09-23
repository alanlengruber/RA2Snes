import QtQuick
import QtTest
import "../../ui/components"

TestCase {
    name: "AchievementToast"
    when: windowShown
    width: 500
    height: 200

    Component {
        id: toastComponent
        AchievementToast {
            title: "KONGQuest"
            points: 7
        }
    }

    SignalSpy {
        id: finishedSpy
        signalName: "finished"
    }

    function init() {
        failOnWarning(/.*/);
        finishedSpy.clear();
    }

    function test_loads_without_warnings_data() {
        return [
            { tag: "achievement", variant: "achievement" },
            { tag: "beaten",      variant: "beaten" },
            { tag: "mastered",    variant: "mastered" }
        ];
    }

    function test_loads_without_warnings(data) {
        var toast = createTemporaryObject(toastComponent, this, { variant: data.variant });
        verify(toast !== null);
        waitForRendering(toast);
    }

    function test_labels_are_english_data() {
        return [
            { tag: "achievement", variant: "achievement", label: "ACHIEVEMENT UNLOCKED" },
            { tag: "beaten",      variant: "beaten",      label: "GAME BEATEN" },
            { tag: "mastered",    variant: "mastered",    label: "GAME MASTERED" }
        ];
    }

    function test_labels_are_english(data) {
        var toast = createTemporaryObject(toastComponent, this, { variant: data.variant });
        compare(toast.label, data.label);
    }

    // O renderizador por software (sem GPU: área de trabalho remota, VM,
    // driver quebrado) não desenha efeitos de shader. Um item com layer.effect
    // ali some por inteiro — o toast não pode depender disso para aparecer.
    function test_visible_without_shader_support() {
        var toast = createTemporaryObject(toastComponent, this);
        if (GraphicsInfo.api === GraphicsInfo.Software)
            verify(!toast.layer.enabled, "software renderer: shadow layer would hide the whole toast");
        else
            verify(toast.layer.enabled, "GPU renderer: shadow layer expected");
    }

    function test_starts_hidden_below_its_resting_place() {
        var toast = createTemporaryObject(toastComponent, this);
        compare(toast.opacity, 0);
        verify(toast.slideOffset > 0);
    }

    function test_entrance_settles_visible() {
        var toast = createTemporaryObject(toastComponent, this);
        toast.start();
        tryCompare(toast, "slideOffset", 0, 2000);
        tryCompare(toast, "opacity", 1, 2000);
    }

    // 420ms entrada + 3900ms espera + 280ms saída ≈ 4,6s.
    function test_full_cycle_finishes_and_hides() {
        var toast = createTemporaryObject(toastComponent, this);
        finishedSpy.target = toast;
        toast.start();
        finishedSpy.wait(8000);
        compare(finishedSpy.count, 1);
        compare(toast.opacity, 0);
    }

    function test_game_awards_hold_longer() {
        var achievement = createTemporaryObject(toastComponent, this, { variant: "achievement" });
        var mastered = createTemporaryObject(toastComponent, this, { variant: "mastered" });
        verify(mastered.holdMs > achievement.holdMs);
    }
}
