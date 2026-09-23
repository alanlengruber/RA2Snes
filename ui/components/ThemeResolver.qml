import QtQuick

QtObject {
    id: resolver

    // O Item carregado pelo themeLoader. Pode ser null enquanto o tema carrega.
    property var theme: null

    // Lê um token do tema. Se o tema não tiver esse token — caso dos temas de
    // terceiro, que foram escritos antes destes nomes existirem — cai para um
    // token do contrato antigo, e só então para uma cor literal.
    function color(name, fallbackName, hardFallback) {
        var value = _read(name);
        if (value !== undefined)
            return value;

        value = _read(fallbackName);
        if (value !== undefined)
            return value;

        return hardFallback;
    }

    function _read(name) {
        if (!theme || !name)
            return undefined;

        var value = theme[name];
        if (value === undefined || value === null)
            return undefined;

        return value;
    }
}
