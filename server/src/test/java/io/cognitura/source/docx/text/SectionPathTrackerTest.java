package io.cognitura.source.docx.text;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class SectionPathTrackerTest {

    @Test
    void returnsTheIncomingPathAndReplacesSameOrDeeperHeadingLevels() {
        SectionPathTracker tracker = new SectionPathTracker();

        assertThat(tracker.currentPath()).isEmpty();
        tracker.acceptHeading(1, "One");
        assertThat(tracker.currentPath()).containsExactly("One");
        tracker.acceptHeading(2, "One Two");
        assertThat(tracker.currentPath()).containsExactly("One", "One Two");
        tracker.acceptHeading(2, "One Two Replacement");
        assertThat(tracker.currentPath()).containsExactly("One", "One Two Replacement");
        tracker.acceptHeading(1, "Replacement Root");
        assertThat(tracker.currentPath()).containsExactly("Replacement Root");
    }

    @Test
    void snapshotsCannotMutateTheTrackedPath() {
        SectionPathTracker tracker = new SectionPathTracker();
        tracker.acceptHeading(1, "Stable");
        var snapshot = tracker.currentPath();

        assertThatThrownBy(() -> snapshot.add("Injected"))
                .isInstanceOf(UnsupportedOperationException.class);
        assertThat(tracker.currentPath()).containsExactly("Stable");
    }

    @Test
    void rejectsEmptyAndOutOfRangeHeadingLevelsWithoutRejectingSourceLevelGaps() {
        SectionPathTracker tracker = new SectionPathTracker();

        assertThatThrownBy(() -> tracker.acceptHeading(1, "  "))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("HEADING_TEXT_REQUIRED");
        assertThatThrownBy(() -> tracker.acceptHeading(0, "Zero"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("HEADING_LEVEL_OUT_OF_RANGE");
        assertThatThrownBy(() -> tracker.acceptHeading(10, "Ten"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("HEADING_LEVEL_OUT_OF_RANGE");
        tracker.acceptHeading(2, "Source Starts At Level Two");
        assertThat(tracker.currentPath()).containsExactly("Source Starts At Level Two");
        tracker.acceptHeading(4, "Source Skips Level Three");
        assertThat(tracker.currentPath())
                .containsExactly("Source Starts At Level Two", "Source Skips Level Three");
    }
}
