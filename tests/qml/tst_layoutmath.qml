import QtQuick
import QtTest
import "../../ui/LayoutMath.js" as LayoutMath

TestCase {
    name: "LayoutMath"

    function test_never_returns_zero_columns() {
        compare(LayoutMath.columnsFor(0, 300), 1);
        compare(LayoutMath.columnsFor(120, 300), 1);
        compare(LayoutMath.columnsFor(-50, 300), 1);
    }

    function test_columns_scale_with_width() {
        compare(LayoutMath.columnsFor(380, 300), 1);
        compare(LayoutMath.columnsFor(620, 300), 2);
        compare(LayoutMath.columnsFor(950, 300), 3);
        compare(LayoutMath.columnsFor(1400, 300), 4);
    }

    function test_dense_fits_more_columns() {
        compare(LayoutMath.columnsFor(1000, 240), 4);
        compare(LayoutMath.columnsFor(1000, 300), 3);
    }

    function test_cell_width_fills_available_width() {
        compare(LayoutMath.cellWidthFor(1200, 300), 300);
        compare(LayoutMath.cellWidthFor(1000, 300), 1000 / 3);
    }

    function test_header_mode_breakpoints() {
        compare(LayoutMath.headerMode(400), "stacked");
        compare(LayoutMath.headerMode(519), "stacked");
        compare(LayoutMath.headerMode(520), "side");
        compare(LayoutMath.headerMode(859), "side");
        compare(LayoutMath.headerMode(860), "inline");
        compare(LayoutMath.headerMode(1600), "inline");
    }

    function test_guards_against_bad_card_width() {
        compare(LayoutMath.columnsFor(1200, 0), 1);
        compare(LayoutMath.columnsFor(1200, -10), 1);
    }
}
