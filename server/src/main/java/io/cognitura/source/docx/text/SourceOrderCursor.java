package io.cognitura.source.docx.text;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

final class SourceOrderCursor {

    private int next;
    private int reservedChildren;
    private final List<Integer> issuedBlockOrders = new ArrayList<>();

    int nextBlock() {
        int blockOrder = next;
        try {
            next = Math.addExact(next, 1);
        } catch (ArithmeticException ignored) {
            throw new IllegalArgumentException("SOURCE_ORDER_OVERFLOW");
        }
        issuedBlockOrders.add(blockOrder);
        return blockOrder;
    }

    void reserveChildren(int count) {
        if (count < 0) {
            throw new IllegalArgumentException("SOURCE_ORDER_RESERVATION_MUST_NOT_BE_NEGATIVE");
        }
        try {
            int nextValue = Math.addExact(next, count);
            int reservedValue = Math.addExact(reservedChildren, count);
            next = nextValue;
            reservedChildren = reservedValue;
        } catch (ArithmeticException ignored) {
            throw new IllegalArgumentException("SOURCE_ORDER_OVERFLOW");
        }
    }

    void requireIssuedBlockOrder(List<DocumentBlockCandidate> blocks) {
        Objects.requireNonNull(blocks, "blocks");
        int expectedCardinality;
        try {
            expectedCardinality = Math.addExact(blocks.size(), reservedChildren);
        } catch (ArithmeticException ignored) {
            throw new IllegalArgumentException("SOURCE_ORDER_OVERFLOW");
        }
        if (expectedCardinality != next || blocks.size() != issuedBlockOrders.size()) {
            throw new IllegalArgumentException("SOURCE_ORDER_CARDINALITY_MISMATCH");
        }
        for (int index = 0; index < blocks.size(); index++) {
            if (blocks.get(index).sourceOrder() != issuedBlockOrders.get(index)) {
                throw new IllegalArgumentException("SOURCE_ORDER_ISSUED_SEQUENCE_MISMATCH");
            }
        }
    }
}
