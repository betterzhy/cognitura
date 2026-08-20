package io.cognitura.source.docx.text;

import java.util.List;

final class SourceOrderCursor {

    private int next;

    int next() {
        return next++;
    }

    void requireContiguous(List<DocumentBlockCandidate> blocks) {
        if (blocks.size() != next) {
            throw new IllegalArgumentException("SOURCE_ORDER_CARDINALITY_MISMATCH");
        }
        for (int index = 0; index < blocks.size(); index++) {
            if (blocks.get(index).sourceOrder() != index) {
                throw new IllegalArgumentException("SOURCE_ORDER_MUST_BE_CONTIGUOUS");
            }
        }
    }
}
