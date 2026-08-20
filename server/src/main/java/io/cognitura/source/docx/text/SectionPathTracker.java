package io.cognitura.source.docx.text;

import java.util.ArrayList;
import java.util.List;

public final class SectionPathTracker {

    private final List<Heading> headings = new ArrayList<>();

    public List<String> currentPath() {
        return headings.stream().map(Heading::text).toList();
    }

    public void acceptHeading(int level, String text) {
        if (level < 1 || level > 9) {
            throw new IllegalArgumentException("HEADING_LEVEL_OUT_OF_RANGE");
        }
        if (text == null || text.isBlank()) {
            throw new IllegalArgumentException("HEADING_TEXT_REQUIRED");
        }
        while (!headings.isEmpty() && headings.getLast().level() >= level) {
            headings.remove(headings.size() - 1);
        }
        headings.add(new Heading(level, text));
    }

    private record Heading(int level, String text) {}
}
