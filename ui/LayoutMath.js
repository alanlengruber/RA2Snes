.pragma library

function columnsFor(availableWidth, minCardWidth) {
    if (!(minCardWidth > 0))
        return 1;
    if (!(availableWidth > 0))
        return 1;

    return Math.max(1, Math.floor(availableWidth / minCardWidth));
}

function cellWidthFor(availableWidth, minCardWidth) {
    return availableWidth / columnsFor(availableWidth, minCardWidth);
}

function headerMode(availableWidth) {
    if (availableWidth < 520)
        return "stacked";
    if (availableWidth < 860)
        return "side";
    return "inline";
}
