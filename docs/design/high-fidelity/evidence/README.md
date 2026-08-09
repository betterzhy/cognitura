# Cognitura 高保真视觉证据

本目录只保存 `docs/` 下确定性非生产原型的视觉证据。截图不是 Canonical Knowledge
Source，不授权业务实现，也不能单独证明可用性或实现阶段 PASS。

## HV-D00 基础证据

```text
Artifact = visual-foundation-desktop.png
PrototypeURL = docs/design/high-fidelity/prototype/index.html?state=visual-foundation
Viewport = 1440x1100
CaptureKind = CHROME_HEADLESS_LOCAL_FILE
ArtifactStatus = CAPTURED_FOUNDATION_FIXTURE
EvidenceMeaning = VISUAL_TOKEN_AND_PROTOTYPE_GOVERNANCE_BASELINE_ONLY
FreshnessCheck = CHROME_RECAPTURE_1440x1100_BYTE_IDENTICAL
HighFidelityVisualDesign = NOT_RUN
HighFidelityUsabilityValidation = NOT_RUN
ImplementationValidation = NOT_RUN
```

验收时必须检查 PNG 实际尺寸和视觉内容，确认它显示 Reading First 连续文档、低权重
层级轨道、单一主要认知投影、行内 Relation、按需 SourceEvidence 入口、可见焦点合同，
且没有常驻治理侧栏、HTTP、持久化或生产依赖。

## 后续主证据与 RF Owner

```text
CanonicalPrimaryArtifact = HV-D03|docs/design/high-fidelity/evidence/module-recovery-desktop.png
CanonicalPrimaryArtifact = HV-D04|docs/design/high-fidelity/evidence/knowledge-landscape-theme-desktop.png
RFOwner = HV-D01|RF-AC-02,04,05,06,08,11,12
RFOwner = HV-D02|RF-AC-03,07,09,16
RFOwner = HV-D03|RF-AC-13,14,17,18
RFOwner = HV-D04|RF-AC-01,10,15,19
RFOwner = HV-D05|RF-AC-20
```

前四卡只能关闭各自 Owner 行；`HV-D04` 可捕获 `RF-AC-20` 的 supporting visual
evidence，但不得提前把该正式验收行从 `NOT_RUN` 改为 `PASS`。
