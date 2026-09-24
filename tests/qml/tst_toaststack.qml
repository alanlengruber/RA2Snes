import QtQuick
import QtTest
import "../../ui/components"

TestCase {
    name: "ToastStack"
    when: windowShown
    width: 400
    height: 300

    ToastStack {
        id: stack
        anchors.fill: parent
        gapMs: 20
    }

    SignalSpy {
        id: shownSpy
        target: stack
        signalName: "shown"
    }

    function init() {
        failOnWarning(/.*/);
        stack.reset();
        shownSpy.clear();
    }

    function makeData(title) {
        return { badgeUrl: "", title: title, points: 7, variant: "achievement" };
    }

    function test_first_push_shows_immediately() {
        stack.push(makeData("KONGQuest"));
        compare(shownSpy.count, 1);
        compare(shownSpy.signalArguments[0][0].title, "KONGQuest");
    }

    function test_second_push_waits_for_first() {
        stack.push(makeData("A"));
        stack.push(makeData("B"));

        // O segundo não pode aparecer enquanto o primeiro está na tela.
        compare(shownSpy.count, 1);
        compare(stack.pending, 1);
        verify(stack.busy);
    }

    function test_queue_drains_in_order() {
        stack.push(makeData("A"));
        stack.push(makeData("B"));
        stack.push(makeData("C"));

        tryCompare(shownSpy, "count", 3, 30000);

        compare(shownSpy.signalArguments[0][0].title, "A");
        compare(shownSpy.signalArguments[1][0].title, "B");
        compare(shownSpy.signalArguments[2][0].title, "C");
        compare(stack.pending, 0);
    }

    // A janela banner tem 320px: o toast não pode passar da largura da fila.
    function test_toast_never_wider_than_stack() {
        stack.push(makeData("The Legend of Zelda: A Link to the Past - Master Sword"));
        verify(stack._current !== null);
        verify(stack._current.width <= stack.width,
               "toast is " + stack._current.width + "px in a " + stack.width + "px stack");
    }

    function test_idle_after_drain() {
        stack.push(makeData("A"));
        tryCompare(stack, "busy", false, 30000);
        compare(stack.pending, 0);
    }
}
