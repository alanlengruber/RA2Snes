import QtQuick

Item {
    id: stack

    // Intervalo entre o fim de um toast e o começo do próximo.
    property int gapMs: 400
    property var resolver: null

    // _queue é um array JS puro: mutá-lo não dispara notificação de binding.
    // Por isso `pending` é atualizado à mão em todo ponto que mexe na fila,
    // em vez de ser um readonly ligado a _queue.length.
    property var _queue: []
    property Item _current: null

    property int pending: 0
    readonly property bool busy: _current !== null || gapTimer.running

    signal shown(var data)

    function push(data) {
        _queue.push(data);
        pending = _queue.length;

        if (!busy)
            _showNext();
    }

    function reset() {
        gapTimer.stop();

        if (_current) {
            _current.destroy();
            _current = null;
        }

        _queue = [];
        pending = 0;
    }

    function _showNext() {
        if (_queue.length === 0)
            return;

        var data = _queue.shift();
        pending = _queue.length;

        var toast = toastComponent.createObject(stack, {
            badgeUrl: data.badgeUrl,
            title: data.title,
            points: data.points,
            variant: data.variant,
            resolver: stack.resolver
        });

        if (!toast)
            return;

        _current = toast;
        toast.finished.connect(_onToastFinished);
        toast.start();

        stack.shown(data);
    }

    function _onToastFinished() {
        if (_current) {
            _current.destroy();
            _current = null;
        }

        if (_queue.length > 0)
            gapTimer.restart();
    }

    Timer {
        id: gapTimer
        interval: stack.gapMs
        repeat: false
        onTriggered: stack._showNext()
    }

    Component {
        id: toastComponent

        // As âncoras ficam aqui, não em createObject: o parent passado ao
        // createObject é o stack, então parent.right/bottom resolvem sozinhos.
        AchievementToast {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
        }
    }
}
